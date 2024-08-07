/*-------------------------------------------------------------------------
 *
 * pltsql_partition.c
 *	  This file contains definitions of functions used
 *	  for PL/tsql Partition.
 *
 * Portions Copyright (c) 2024, AWS
 * Portions Copyright (c) 1996-2024, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	contrib/babelfishpg_tsql/src/pltsql_partition.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"
#include "access/genam.h"
#include "access/relation.h"
#include "access/table.h"
#include "catalog/partition.h"
#include "catalog/pg_inherits.h"
#include "catalog/pg_type.h"
#include "common/md5.h"
#include "miscadmin.h"
#include "nodes/makefuncs.h"
#include "nodes/nodes.h"
#include "nodes/pg_list.h"
#include "nodes/plannodes.h"
#include "parser/parse_coerce.h"
#include "parser/parse_type.h"
#include "utils/builtins.h"
#include "utils/elog.h"
#include "utils/fmgroids.h"
#include "utils/partcache.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"

#include "catalog.h"
#include "hooks.h"
#include "pltsql.h"
#include "pltsql_partition.h"
#include "session.h"

#define MD5_HASH_LEN 32

static char *construct_unique_hash(char *relation_name);
static void set_partition_range_bounds(PartitionBoundSpec *partbound, Datum *range_values, int idx,
					int total_partitions, bool is_binary_datatype);
static void set_node_value_from_datum(A_Const *node, Datum val, bool is_binary_datatype);
static CreateStmt *create_partition_stmt(char *physical_schema_name, char *relname);
static void rename_table_update_bbf_partitions_name(RenameStmt *stmt, Oid parentrelid);


/*
 * bbf_create_partition_tables
 *	This function creates partitions of babelfish partitioned table
 *	using the partition scheme and partitioning column.
 */
void
bbf_create_partition_tables(CreateStmt *stmt)
{
	Relation	rel;
	HeapTuple	tuple;
	SysScanDesc	scan;
	ScanKeyData	scanKey[2];
	char		*input_parameter_type;
	char		*partition_function_name;
	Datum		*range_values;
	Datum		*datum_values;
	bool		*nulls;
	int		nelems;
	Oid		sql_variant_type_oid;
	Oid		input_type_oid;
	ListCell	*elements;
	Oid		partition_column_typoid = InvalidOid;
	Oid		partition_column_basetypoid = InvalidOid;
	char		*partition_column_typname = NULL;
	bool		is_binary_datatype = false;
	int16		dbid = get_cur_db_id();
	char		*partition_scheme_name = stmt->partspec->tsql_partition_scheme;
	char		*relname = stmt->relation->relname;
	char		*partition_colname = linitial_node(PartitionElem, stmt->partspec->partParams)->name;
	CreateStmt	*partition_stmt;
	PlannedStmt	*wrapper;
	char		*unique_hash;
	char		*physical_schema_name;
	char		*logical_schema_name;
	ArrayType	*values;
	bool		isnull;
	int		i;
	char		*partition_name;

	/* Partitioning is not supported for tempopary tables. */
	if (stmt->relation->relpersistence == RELPERSISTENCE_TEMP)
		ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Creation of temporary partitioned tables is not supported in Babelfish.")));
	
	/*
	 * Get partition function name for the provided partition scheme,
	 * if provided partition scheme exists in current database.
	 */
	partition_function_name = get_partition_function_name(dbid, partition_scheme_name);
	
	/* Raise error if provided partition scheme doesn't exists in current database. */
	if (!partition_function_name)
	{
		ereport(ERROR, 
			(errcode(ERRCODE_UNDEFINED_OBJECT), 
				errmsg("Invalid partition scheme '%s' specifed.", partition_scheme_name)));
	}

	/* Extract the datatype of partitioning column from CREATE statement. */
	foreach (elements, stmt->tableElts)
	{
		Node		*element = lfirst(elements);
		ColumnDef	*coldef;

		if (nodeTag(element) != T_ColumnDef)
			continue;

		coldef = castNode(ColumnDef, element);

		if (pg_strcasecmp(coldef->colname, partition_colname) == 0)
		{
			HeapTuple ctype = LookupTypeName(NULL, coldef->typeName, NULL, true);
			Form_pg_type pg_type = (Form_pg_type) GETSTRUCT(ctype);

			partition_column_typoid = pg_type->oid;
			partition_column_basetypoid = pg_type->typbasetype;
			partition_column_typname = pstrdup(NameStr(pg_type->typname));
			ReleaseSysCache(ctype);
			break;
		}
	}

	/* Get OID of sql_variant type. */
	sql_variant_type_oid = (*common_utility_plugin_ptr->get_tsql_datatype_oid) ("sql_variant");

	/*
	 * Extract metadata of partition function like ranges and input parameter type by
	 * looking up in bbf_partition_function catalog using the partition function name and dbid.
	 */
	rel = table_open(get_bbf_partition_function_oid(), AccessShareLock);
	
	ScanKeyInit(&scanKey[0],
				Anum_bbf_partition_function_dbid,
				BTEqualStrategyNumber, F_INT2EQ,
				Int16GetDatum(dbid));

	ScanKeyEntryInitialize(&scanKey[1], 0,
				Anum_bbf_partition_function_name,
				BTEqualStrategyNumber, InvalidOid,
				tsql_get_server_collation_oid_internal(false),
				F_TEXTEQ, CStringGetTextDatum(partition_function_name));

	scan = systable_beginscan(rel, get_bbf_partition_function_pk_idx_oid(),
					false, NULL, 2, scanKey);

	tuple = systable_getnext(scan);

	if (!HeapTupleIsValid(tuple)) /* Sanity check. */
	{
		systable_endscan(scan);
		table_close(rel, AccessShareLock);
		ereport(ERROR,
			(errcode(ERRCODE_UNDEFINED_OBJECT),
				errmsg("Partition function '%s' used for the specifed partition scheme '%s' does not exist.", partition_function_name, partition_scheme_name)));
	}
	
	input_parameter_type = TextDatumGetCString(heap_getattr(tuple, Anum_bbf_partition_function_input_parameter_type, RelationGetDescr(rel), &isnull));
	values = DatumGetArrayTypeP(heap_getattr(tuple, Anum_bbf_partition_function_range_values, RelationGetDescr(rel), &isnull));
	deconstruct_array(values, sql_variant_type_oid, -1, false, 'i', &datum_values, &nulls, &nelems);

	systable_endscan(scan);
	table_close(rel, AccessShareLock);

	/*
	 * If the partition columns type is UDT type, then we need
	 * to use the base type of that type while comparing with
	 * input parameter type of partition function.
	 */
	if (OidIsValid(partition_column_basetypoid))
	{
		/* Get the TSQL typoid from partitioning column type name. */
		Oid tsql_typoid = (*common_utility_plugin_ptr->get_tsql_datatype_oid) (partition_column_typname);

		/* If the value of tsql_typname is NULL, it indicates that partitioning column is UDT type. */
		if (!OidIsValid(tsql_typoid))
		{
			/* Substitute typoid with the base type to facilitate comparison. */
			partition_column_typoid = partition_column_basetypoid;
		}
	}

	input_type_oid = (*common_utility_plugin_ptr->get_tsql_datatype_oid) (input_parameter_type);

	/*
	 * Validate that type of partitioning columns is same
	 * to input parameter type of partition function.
	 */
	if (partition_column_typoid != input_type_oid)
	{
		ereport(ERROR, 
			(errcode(ERRCODE_UNDEFINED_OBJECT), 
				errmsg("Partition column '%s' has data type '%s' which is different from the partition function '%s' parameter data type '%s'.",
				partition_colname, partition_column_typname, partition_function_name, input_parameter_type)));
	}

	/* Check if the input parameter type is (var)binary datatype. */
	input_type_oid = getBaseType(input_type_oid);
	if ((*common_utility_plugin_ptr->is_tsql_binary_datatype) (input_type_oid) ||
		(*common_utility_plugin_ptr->is_tsql_varbinary_datatype) (input_type_oid))
			is_binary_datatype = true;

	/* Convert each sql_variant values to CString. */
	range_values = palloc(nelems * sizeof(Datum));
	for (i = 0; i < nelems; i++)
	{
		range_values[i] = pltsql_exec_tsql_cast_value(datum_values[i], &isnull,
								sql_variant_type_oid, -1,
								CSTRINGOID, -1);
	}

	/*
	 * Find default schema for current user when schema
	 * is not explicitly specified with create statement.
	 */
	if (!stmt->relation->schemaname)
	{
		char		*db_name = get_cur_db_name();
		const char *user = get_user_for_database(db_name);
		logical_schema_name = get_authid_user_ext_schema_name(db_name, user);
		physical_schema_name = get_physical_schema_name(db_name, logical_schema_name);
		pfree(db_name);
	}
	else
	{
		physical_schema_name = pstrdup(stmt->relation->schemaname);
		logical_schema_name = (char *) get_logical_schema_name(physical_schema_name, false);
	}

	partition_stmt = create_partition_stmt(physical_schema_name, relname);

	if (!partition_stmt) /* Sanity Check. */
	{
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("Failed to construct partitions for relation \"%s\".", relname)));
	}

	/* Make a wrapper PlannedStmt. */
	wrapper = makeNode(PlannedStmt);
	wrapper->commandType = CMD_UTILITY;
	wrapper->canSetTag = false;
	wrapper->utilityStmt = (Node *) partition_stmt;
	wrapper->stmt_location = 0;
	wrapper->stmt_len = 0;

	/* Construct hash based on partitioned table name. */
	unique_hash = construct_unique_hash(relname);

	for (i = 0; i < nelems + 1; i++)
	{
		/*
		 * Construct partition name with unique hash based
		 * on partitioned table name and partition number.
		 * And Set the name in CREATE PARTITION statment.
		 */
		partition_name = psprintf("%s_partition_%d", unique_hash, i);
		partition_stmt->relation->relname = partition_name;

		/* Set the range boundaries in CREATE PARTITION statment. */
		set_partition_range_bounds(partition_stmt->partbound, range_values, i, nelems + 1, is_binary_datatype);

		/* Execute the CREATE PARTITION statment. */
		standard_ProcessUtility(wrapper,
					"(CREATE PARTITION)",
					false,
					PROCESS_UTILITY_SUBCOMMAND,
					NULL,
					NULL,
					None_Receiver,
					NULL);

		CommandCounterIncrement();
		pfree(partition_name);
	}

	/*
	 * Add an entry in sys.babelfish_partition_depend to track the
	 * dependency between partition scheme and partitioned table.
	 */
	add_entry_to_bbf_partition_depend(dbid, partition_scheme_name, logical_schema_name, relname);

	/* Free the allocated memory. */
	pfree(partition_column_typname);
	pfree(partition_function_name);
	pfree(physical_schema_name);
	pfree(logical_schema_name);
	pfree(unique_hash);
	pfree(datum_values);
	pfree(range_values);
}

/*
 * create_partition_stmt
 * 	Creates a CREATE PARTITION statement using the provided physical schema name and relation name.
 * 	Here, we need to change the dialect to postgres to parse the CREATE PARTITION Postgres statement.
 * 	After parsing, we reset the dialect back to original value.
 */
static CreateStmt*
create_partition_stmt(char *physical_schema_name, char *relname)
{
	CreateStmt	*partition_stmt = NULL;
	const char	*old_dialect = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);
	List		*res;
	StringInfoData	query;

	/*
	 * We prepare the following query to CREATE PARTITION of partitioned table.
	 * This will be executed using standard_ProcessUtility().
	 */
	initStringInfo(&query);
	appendStringInfo(&query, "CREATE TABLE \"%s\".dummy PARTITION OF \"%s\".\"%s\""
				" FOR VALUES FROM ('dummy') TO ('dummy');",
				physical_schema_name, physical_schema_name, relname);
	PG_TRY();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", "postgres", GUC_CONTEXT_CONFIG,
					PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		res = raw_parser(query.data, RAW_PARSE_DEFAULT);
		partition_stmt = (CreateStmt *) parsetree_nth_stmt(res, 0);
	}
	PG_FINALLY();
	{
		/* Reset dialect back to original value. */
		set_config_option("babelfishpg_tsql.sql_dialect", old_dialect, GUC_CONTEXT_CONFIG,
					PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		pfree(query.data);
	}
	PG_END_TRY();
	return partition_stmt;
}

/*
 * construct_unique_hash
 * 	Constructs a unique hash based on the relation name,
 * 	this is used to construct unique names for partitions.
 */
static char*
construct_unique_hash(char *relation_name)
{
	char		*md5;
	bool		success;
	const char	*errstr = NULL;

	md5 = (char *) palloc(MD5_HASH_LEN + 1);

	success = pg_md5_hash(relation_name, strlen(relation_name), md5, &errstr);
	
	if (unlikely(!success)) /* Out of memory. */
	{
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("Constructing unique partition name failed for relation \"%s\": %s.", relation_name, errstr)));
	}

	return md5;
}

/*
 * set_partition_range_bounds
 * 	This function sets the lower and upper bounds for a range partition based on its index
 * 	and the total number of partitions. It handles the following cases:
 * 	1. For the first partition, it sets the lower bound to DEFAULT to
 * 		accommodate NULL values along with other values.
 * 	2. For the last partition, it sets the upper bound to MAXVALUE.
 * 	3. For other partitions, it sets the bounds to the corresponding values in the range_values array.
 */
static void
set_partition_range_bounds(PartitionBoundSpec *partbound, Datum *range_values, int idx,
				int total_partitions, bool is_binary_datatype)
{
	
	/* Set lower bound of partition. */
	if (idx == 0) /* first partition */
	{
		partbound->is_default = true;
		partbound->location = -1;
		partbound->lowerdatums = NIL;
		partbound->upperdatums = NIL;
		return;
	}
	else
	{
		A_Const *node = makeNode(A_Const);
		set_node_value_from_datum(node, range_values[idx-1], is_binary_datatype);
		partbound->is_default = false;
		partbound->lowerdatums = list_make1(node);
	}

	/* Set upper bound of partition. */
	if (idx == total_partitions - 1) /* last partition */
	{
		ColumnRef *node = makeNode(ColumnRef);
		node->fields = list_make1(makeString("maxvalue"));
		partbound->is_default = false;
		partbound->upperdatums = list_make1(node);
	}
	else
	{
		A_Const *node = makeNode(A_Const);
		set_node_value_from_datum(node, range_values[idx], is_binary_datatype);
		partbound->is_default = false;
		partbound->upperdatums = list_make1(node);
	}
}

/*
 * set_node_value_from_datum
 * 	Set the value of an A_Const node based on the datatype.
 * 	If the data type is (var)binary, the value is set as a hexadecimal string.
 * 	Otherwise, the value is set as a regular string.
 */
static void
set_node_value_from_datum(A_Const *node, Datum val, bool is_binary_datatype)
{
	if (is_binary_datatype)
	{
		node->val.sval.type = T_TSQL_HexString;
		node->val.hsval.hsval = DatumGetCString(val);
	}
	else
	{
		node->val.sval.type = T_String;
		node->val.sval.sval = DatumGetCString(val);
	}
}

/*
 * bbf_drop_handle_partitioned_table
 * 	When the table is being dropped is:
 * 	1. babelfish partitioned table, then it removes the entry from bbf_partition_depend catalog.
 * 	2. partition of babelfish partitioned table, then it throws an error.
 * 	3. other than above, then it does nothing.
 */
void
bbf_drop_handle_partitioned_table(DropStmt *stmt)
{
	Relation		relation;
	ListCell		*cell;
	int16			dbid;
	char			*physical_schemaname;
	char			*logical_schemaname;
	char			*relname;
	Form_pg_class		form;

	foreach (cell, stmt->objects)
	{
		relation = NULL;
		get_object_address(stmt->removeType, lfirst(cell), &relation, AccessShareLock, true);
		if (!relation)
			continue;

		form = RelationGetForm(relation);
		relname = RelationGetRelationName(relation);

		/* Proceed further only for permanent and partition/partitioned table. */
		if (!(form->relkind == RELKIND_PARTITIONED_TABLE || form->relispartition)
			|| form->relpersistence != RELPERSISTENCE_PERMANENT)
		{
			relation_close(relation, AccessShareLock);
			continue;
		}

		physical_schemaname = get_namespace_name(form->relnamespace);

		/* Find logical schema name from physical schema name. */
		logical_schemaname = (char *) get_logical_schema_name(physical_schemaname, true);
		
		if (!logical_schemaname) /* not a TSQL schema */
		{
			pfree(physical_schemaname);
			relation_close(relation, AccessShareLock);
			continue;
		}

		/* Find dbid from physical schema name for a TSQL schema. */
		dbid = get_dbid_from_physical_schema_name(physical_schemaname, false);
		pfree(physical_schemaname);

		if (form->relispartition) /* relation is partition of table */
		{
			/* Prevent non-superusers from droping partitions of Babelfish partitioned tables. */
			if (!superuser() && is_bbf_partitioned_table(dbid, logical_schemaname, get_rel_name(get_partition_parent(form->oid, false))))
			{
				relation_close(relation, AccessShareLock);
				ereport(ERROR,
					(errcode(ERRCODE_UNDEFINED_OBJECT),
						errmsg("Cannot drop the babelfish partition table '%s'.", relname)));
			}
		}
		else if (form->relkind == RELKIND_PARTITIONED_TABLE) /* relation is partitioned table */
		{
			/* In case of babelfish partitioned table then remove the entry from bbf_partition_depend table. */
			if (is_bbf_partitioned_table(dbid, logical_schemaname, relname))
				remove_entry_from_bbf_partition_depend(dbid, logical_schemaname, relname);
		}
		relation_close(relation, AccessShareLock);
		pfree(logical_schemaname);
	}
}

/*
 * bbf_validate_partitioned_index_alignment
 *	Validates whether the index being created on a partitioned table is aligned
 *	with the table's partition scheme. It checks if the column specified for
 *	the index is part of the partitioning columns and if the partition scheme
 *	used for the index matches the partition scheme used for the table.
 */
bool
bbf_validate_partitioned_index_alignment(IndexStmt *stmt)
{
	char		*partition_scheme_name = strVal(linitial(stmt->excludeOpNames));
	char		*colname =  strVal(lsecond(stmt->excludeOpNames));
	char		*relname = stmt->relation->relname;
	char		*physical_schema_name;
	char		*logical_schema_name;
	char		*partition_scheme_used_for_table;
	int16		dbid = get_cur_db_id();
	char		*db_name = get_cur_db_name();
	Oid		relid;
	HeapTuple	tuple;
	int		attnum;
	Relation	rel;
	PartitionKey	key;
	int		partnatts;
	int		i;

	/*
	 * Find default schema for current user when schema
	 * is not explicitly specified for TDS client.
	 */
	if (!stmt->relation->schemaname)
	{
		const char *user = get_user_for_database(db_name);
		logical_schema_name = get_authid_user_ext_schema_name(db_name, user);
		physical_schema_name = get_physical_schema_name(db_name, logical_schema_name);
	}
	else
	{
		physical_schema_name = pstrdup(stmt->relation->schemaname);
		logical_schema_name = (char *) get_logical_schema_name(physical_schema_name, false);
	}

	relid = get_relname_relid(relname, get_namespace_oid(physical_schema_name, false));
	
	pfree(physical_schema_name);
	pfree(db_name);

	/* Search for the column specified with partition scheme in table's columns. */
	tuple = SearchSysCacheAttName(relid, colname);

	/* Raise an error if column specified with partition scheme doesn't exists in table. */
	if (!HeapTupleIsValid(tuple))
	{
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_COLUMN),
					errmsg("column '%s' does not exist", colname)));
	}

	attnum = ((Form_pg_attribute) GETSTRUCT(tuple))->attnum;
	ReleaseSysCache(tuple);

	/* Raise an error if provided partition scheme doesn't exists in the current database. */
	if (!partition_scheme_exists(dbid, partition_scheme_name))
	{
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					errmsg("Invalid object name '%s'.", partition_scheme_name)));
	}

	/* Find the partition scheme used to create partitioned table. */
	partition_scheme_used_for_table = get_partition_scheme_for_partitioned_table(dbid, logical_schema_name, relname);
	pfree(logical_schema_name);

	/* partition_scheme_used_for_table will be null for non-partitioned table */
	if (!partition_scheme_used_for_table ||
			pg_strcasecmp(partition_scheme_name, partition_scheme_used_for_table) != 0)
	{
		if (partition_scheme_used_for_table)
			pfree(partition_scheme_used_for_table);
		return false;
	}

	/*
	 * Column specified with partition scheme should be part of partitioning columns.
	 * Otherwise, the index is unaligned.
	 */
	rel = RelationIdGetRelation(relid);
	key = RelationGetPartitionKey(rel);
	partnatts = get_partition_natts(key);

	for (i = 0; i < partnatts; i++)
	{
		if (attnum == get_partition_col_attnum(key, i))
			break;
	}

	RelationClose(rel);

	if (partition_scheme_used_for_table)
		pfree(partition_scheme_used_for_table);

	if (i == partnatts) /* not part of partitioning columns */
		return false;
	return true;
}

/*
 * bbf_rename_handle_partitioned_table
 * 	1. For a rename operation on a babelfish partitioned table, rename all of its partition and
 * 	   and update the table_name in sys.babelfish_partition_depend catalog.
 * 	2. For a rename operation on a babelfish partition table, raise error.
 */
void
bbf_rename_handle_partitioned_table(RenameStmt *stmt)
{
	char		*table_name = stmt->relation->relname;
	char		*physical_schema_name;
	char		*logical_schema_name;
	bool		is_partition_table, is_partitioned_table;
	Form_pg_class	form;
	HeapTuple	tuple;
	Oid		nsp_oid;
	int16		dbid;
	RangeVar	*new_rel = makeRangeVar(stmt->relation->schemaname, stmt->newname, -1);
	Oid		relid = RangeVarGetRelid(new_rel, NoLock, true);;

	/* Get the namespace OID and type of the table. */
	tuple = SearchSysCache1(RELOID, ObjectIdGetDatum(relid));

	if (!HeapTupleIsValid(tuple)) /* Sanity check. */
		return;

	form = (Form_pg_class) GETSTRUCT(tuple);
	is_partition_table = form->relispartition;
	is_partitioned_table = (form->relkind == RELKIND_PARTITIONED_TABLE);
	nsp_oid = form->relnamespace;
	ReleaseSysCache(tuple);

	/* Proceed further only if table is a partition or partitioned table. */
	if (!is_partition_table && !is_partitioned_table)
		return;

	/* Get the physical schema name from namespace OID. */
	physical_schema_name = get_namespace_name(nsp_oid);

	/* Find the logical schema name from physical schema name. */
	logical_schema_name = (char *) get_logical_schema_name(physical_schema_name, true);

	if (!logical_schema_name) /* not a TSQL schema */
	{
		pfree(physical_schema_name);
		return;
	}

	/* Find the dbid from the physical schema name. */
	dbid = get_dbid_from_physical_schema_name(physical_schema_name, false);

	/*
	 * For babelfish partition table, user should not
	 * be allowed to rename it.
	 */
	if (is_partition_table)
	{
		char	*parent_table_name = get_rel_name(get_partition_parent(relid, false));
		if (is_bbf_partitioned_table(dbid, logical_schema_name, parent_table_name))
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					errmsg("Cannot rename babelfish partition table '%s'.", stmt->relation->relname)));
		pfree(parent_table_name);
	}
	/*
	 * For babelfish partitioned table, rename all of its partition and
	 * update the table_name in sys.babelfish_partition_depend catalog.
	 */
	else if (is_bbf_partitioned_table(dbid, logical_schema_name, table_name))
	{
		rename_table_update_bbf_partitions_name(stmt, relid);
		rename_table_update_bbf_partition_depend_catalog(stmt, logical_schema_name, dbid);
	}

	pfree(physical_schema_name);
	pfree(logical_schema_name);
}

/*
 * rename_table_update_bbf_partitions_name
 *	For a rename operation on a babelfish partitioned table, it renames all partition
 *	of the table to the new name using hash based on the new name, so that
 *	name of partitions of any partitioned table doesn't conflict.
 */
static void
rename_table_update_bbf_partitions_name(RenameStmt *stmt, Oid parentrelid)
{
	char		*physical_schema_name = stmt->relation->schemaname;
	char		*table_name = stmt->relation->relname;
	List		*partition_names = NIL;
	char		*new_hash;
	PlannedStmt	*wrapper;
	RenameStmt	*rename_partition_stmt = NULL;
	List		*parsetree;
	Relation	relation;
	SysScanDesc	scan;
	ScanKeyData	key;
	Oid		inhrelid;
	HeapTuple	tuple;
	const char	*old_dialect;
	StringInfoData	query;
	char		*partition_name;
	char		*new_partition_name;

	relation = table_open(InheritsRelationId, AccessShareLock);

	ScanKeyInit(&key,
			Anum_pg_inherits_inhparent,
			BTEqualStrategyNumber, F_OIDEQ,
			ObjectIdGetDatum(parentrelid));

	scan = systable_beginscan(relation, InheritsParentIndexId, true,
					NULL, 1, &key);

	while ((tuple = systable_getnext(scan)) != NULL)
	{
		inhrelid = ((Form_pg_inherits) GETSTRUCT(tuple))->inhrelid;
		partition_names = lappend(partition_names, get_rel_name(inhrelid));
	}
	systable_endscan(scan);
	table_close(relation, AccessShareLock);

	/*
	 * We prepare the following query to rename the partitions of partitioned table.
	 * This will be executed using standard_ProcessUtility().
	 */
	initStringInfo(&query);
	appendStringInfo(&query, "ALTER TABLE \"%s\".dummy RENAME TO dummy;", physical_schema_name);

	old_dialect = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	/* We need to change the dialect to postgres to parse the RENAME statement. */
	PG_TRY();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", "postgres", GUC_CONTEXT_CONFIG,
					PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

		parsetree = raw_parser(query.data, RAW_PARSE_DEFAULT);
		rename_partition_stmt = (RenameStmt *) parsetree_nth_stmt(parsetree, 0);
	}
	PG_FINALLY();
	{
		/* Reset dialect back to original value. */
		set_config_option("babelfishpg_tsql.sql_dialect", old_dialect, GUC_CONTEXT_CONFIG,
					PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
	}
	PG_END_TRY();

	if (!rename_partition_stmt) /* Sanity Check. */
	{
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("Failed to rename partitions of relation \"%s\".", table_name)));
	}

	/* Need to make a wrapper PlannedStmt. */
	wrapper = makeNode(PlannedStmt);
	wrapper->commandType = CMD_UTILITY;
	wrapper->canSetTag = false;
	wrapper->utilityStmt = (Node *) rename_partition_stmt;
	wrapper->stmt_location = 0;
	wrapper->stmt_len = 0;

	/* Construct hash based on new name. */
	new_hash = construct_unique_hash(stmt->newname);
	
	for (int i = 0; i < list_length(partition_names); i++)
	{
		partition_name = list_nth(partition_names, i);

		/*
		 * Generate new partition name by replacing the hash portion
		 * of existing partition name with new hash value.
		 */
		new_partition_name = pstrdup(partition_name);
		memcpy(new_partition_name, new_hash, MD5_HASH_LEN);
		
		/* Set the names in RENAME statment. */
		rename_partition_stmt->relation->relname = partition_name;
		rename_partition_stmt->newname = new_partition_name;

		/* Execute the rename statment. */
		standard_ProcessUtility(wrapper,
					"(RENAME PARTITION)",
					false,
					PROCESS_UTILITY_SUBCOMMAND,
					NULL,
					NULL,
					None_Receiver,
					NULL);

		CommandCounterIncrement();

		pfree(partition_name);
		pfree(new_partition_name);
	}

	/* Free the allocated memory. */
	if (partition_names)
		list_free(partition_names);
	pfree(new_hash);
	pfree(query.data);
}

/*
 * For Babelfish partitioned tables, non-superusers should not be permitted
 * to attach or detach partitions from the partitioned table, and they
 * should also be restricted from modifying the partitions from both
 * TSQL as well as PG endpoint.
 * 
 * NOTE: We are only blocking operation on Babelfish partitioned tables i.e.
 * partitioned tables created from the TSQL endpoint. Existing users who have
 * created partitioned tables from the PostgreSQL endpoint can continue to modify, 
 * attach, and detach partitions as usual.
 */
void
bbf_alter_handle_partitioned_table(AlterTableStmt *stmt)
{
	AlterTableCmd		*cmd = (AlterTableCmd *) linitial(stmt->cmds);
	int16			dbid;
	char			*physical_schemaname;
	char			*logical_schemaname;
	Form_pg_class		form;
	Oid			nsp_oid;
	HeapTuple		tuple;
	bool			is_partition_table, is_partitioned_table;
	Oid			relid = RangeVarGetRelid(stmt->relation, NoLock, true);

	if (!OidIsValid(relid))
		return;

	/* Get the namespace OID and rekind type of the table. */
	tuple = SearchSysCache1(RELOID, ObjectIdGetDatum(relid));

	if (!HeapTupleIsValid(tuple)) /* Sanity check. */
		return;

	form = (Form_pg_class) GETSTRUCT(tuple);
	is_partition_table = form->relispartition;
	is_partitioned_table = (form->relkind == 'p');
	nsp_oid = form->relnamespace;
	ReleaseSysCache(tuple);

	/* Proceed further only if table is a partition or partitioned table. */
	if (!is_partition_table && !is_partitioned_table)
		return;

	/* Get the schema name from namespace OID. */
	physical_schemaname = get_namespace_name(nsp_oid);

	/* Find dbid logical schema name physical schema name. */
	logical_schemaname = (char *) get_logical_schema_name(physical_schemaname, true);
	if (!logical_schemaname) /* not a TSQL schema */
	{
		pfree(physical_schemaname);
		return;
	}

	/* Find dbid from physical schema name for a TSQL schema. */
	dbid = get_dbid_from_physical_schema_name(physical_schemaname, false);

	/*
	 * For babelfish partitioned table, user should not be
	 * allowed to attach/detach to table directly.
	 * These commands can be executed only from PG endpoint.
	 */
	if (is_partitioned_table && (cmd->subtype == AT_AttachPartition || 
		cmd->subtype == AT_DetachPartition || cmd->subtype == AT_DetachPartitionFinalize))
	{
		if (is_bbf_partitioned_table(dbid, logical_schemaname, stmt->relation->relname))
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED), 
					errmsg("Cannot %s babelfish partitioned table '%s'.",
							cmd->subtype == AT_AttachPartition ? "attach partition to" : "detach partition from",
							stmt->relation->relname)));
	}
	/*
	 * For babelfish partition table, user should not
	 * be allowed to modify it.
	 * This will blocked from both TSQL and PG endpoint.
	 */
	else if (is_partition_table)
	{
		char	*parent_table_name = get_rel_name(get_partition_parent(relid, false));
		if (is_bbf_partitioned_table(dbid, logical_schemaname, parent_table_name))
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED), 
					errmsg("Modifying partitions directly is not supported. You can modify the partitions by modifying the parent table.")));
		pfree(parent_table_name);
	}

	pfree(physical_schemaname);
	pfree(logical_schemaname);
}
