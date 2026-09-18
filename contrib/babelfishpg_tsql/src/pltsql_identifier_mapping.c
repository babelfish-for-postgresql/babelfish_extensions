/*-------------------------------------------------------------------------
 *
 * pltsql_identifier_mapping.c
 *	  CRUD helpers for the sys.babelfish_identifier_mapping catalog.
 *
 * SQL Server allows identifiers up to 128 bytes (sysname) while PostgreSQL
 * truncates at NAMEDATALEN (63 bytes). When a T-SQL identifier exceeds the PG
 * limit its physical name is rewritten (truncated with a hash suffix) or
 * downcased, which would otherwise surface to users through the sys.* catalog
 * views and sp_rename. sys.babelfish_identifier_mapping maps the physical
 * (truncated/downcased) name back to the original name the user typed, for
 * constraints, sequences, user-defined types and procedure/function
 * parameters.
 *
 * These are the catalog CRUD helpers (insert / lookup / delete / update /
 * clean-up); the DDL-time "store" logic that extracts the original name from
 * the statement text lives with the ProcessUtility hooks in pl_handler.c.
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "miscadmin.h"
#include "access/genam.h"
#include "access/heapam.h"
#include "access/htup_details.h"
#include "access/stratnum.h"
#include "access/table.h"
#include "catalog/index.h"
#include "catalog/indexing.h"
#include "catalog/namespace.h"
#include "catalog/pg_class.h"
#include "catalog/pg_constraint.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_type.h"
#include "commands/tablecmds.h"
#include "nodes/makefuncs.h"
#include "nodes/parsenodes.h"
#include "parser/analyze.h"
#include "parser/scansup.h"
#include "tcop/utility.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "utils/hsearch.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/rel.h"
#include "utils/syscache.h"

#include "catalog.h"
#include "pltsql.h"

extern bool babelfish_dump_restore;
extern int	sql_dialect;
extern void pltsql_post_expand_star(ParseState *pstate, ColumnRef *cref, List *l);

Oid
get_bbf_ident_mapping_oid(void)
{
	if (!OidIsValid(bbf_ident_mapping_oid))
		bbf_ident_mapping_oid = get_relname_relid(BBF_IDENT_MAPPING_TABLE_NAME,
												  get_namespace_oid("sys", false));
	return bbf_ident_mapping_oid;
}

Oid
get_bbf_ident_mapping_idx_oid(void)
{
	if (!OidIsValid(bbf_ident_mapping_idx_oid))
		bbf_ident_mapping_idx_oid = get_relname_relid(BBF_IDENT_MAPPING_IDX_NAME,
													  get_namespace_oid("sys", false));
	return bbf_ident_mapping_idx_oid;
}

/*
 * bbf_ident_mapping_catalog_oid - Map a BbfIdentMappingObjType to the
 * pg_catalog_type OID stored in the mapping catalog. Centralizes the
 * object-class -> catalog-OID mapping so callers pass the logical object type
 * and never repeat the OID selection.
 */
static Oid
bbf_ident_mapping_catalog_oid(BbfIdentMappingObjType objtype)
{
	switch (objtype)
	{
		case BBF_IDENT_CONSTRAINT:
			return ConstraintRelationId;
		case BBF_IDENT_SEQUENCE:
			return RelationRelationId;
		case BBF_IDENT_TYPE:
			return TypeRelationId;
		case BBF_IDENT_PARAMETER:
			return ProcedureRelationId;
	}
	/* Should be unreachable; keep the compiler happy. */
	elog(ERROR, "unexpected babelfish_identifier_mapping object type: %d",
		 (int) objtype);
	return InvalidOid;
}

/*
 * insert_bbf_ident_mapping - Insert an entry mapping truncated name
 * to its original name. Only inserts if original name differs from the
 * physical (truncated/downcased) name.
 */
void
insert_bbf_ident_mapping(const char *truncated_name,
								const char *original_name,
								const char *nspname,
								BbfIdentMappingObjType objtype,
								const char *parent_name)
{
	Relation	rel;
	HeapTuple	tuple;
	Oid			pg_catalog_type = bbf_ident_mapping_catalog_oid(objtype);
	Datum		values[BBF_IDENT_MAPPING_NUM_COLS];
	bool		nulls[BBF_IDENT_MAPPING_NUM_COLS];
	NameData	truncated_namedata;
	NameData	nspname_data;
	NameData	parent_namedata;

	/*
	 * This catalog only tracks identifiers that were physically truncated
	 * because they exceeded NAMEDATALEN; callers gate on the original name's
	 * length before calling. As a safety net, skip when original_name is NULL
	 * or already equal to the stored physical (truncated/downcased) name so we
	 * never insert a redundant self-mapping.
	 */
	if (original_name == NULL || strcmp(original_name, truncated_name) == 0)
		return;

	/*
	 * parent_name must be the PHYSICAL name (<= NAMEDATALEN-1 bytes). It is
	 * written and looked up via namestrcpy, which silently truncates without a
	 * hash suffix, and the DROP cleanup path keys on the physical name. If a
	 * caller ever passes a parse-tree name >= NAMEDATALEN, the insert and
	 * delete keys would diverge and leave a stale row. Asserts are compiled
	 * out in release builds, so enforce this with a real check + error.
	 */
	if (parent_name && strlen(parent_name) >= NAMEDATALEN)
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("parent name \"%s\" for babelfish_identifier_mapping exceeds the maximum identifier length",
						parent_name)));

	if (!OidIsValid(get_bbf_ident_mapping_oid()))
		return;

	/*
	 * If a row for this key already exists, decide between a no-op and an
	 * overwrite based on its stored original name.
	 *
	 * The primary key is (truncated_name, nspname, pg_catalog_type,
	 * parent_name). Two situations reach this point:
	 *
	 *  1. The exact same object is being (re)stored -- e.g. CREATE OR REPLACE
	 *     of a function/type, or a utility hook that fires more than once for
	 *     the same statement. The existing original name matches the new one,
	 *     so we simply skip (re-inserting would raise a spurious duplicate-key
	 *     error that aborts otherwise-valid DDL).
	 *
	 *  2. A stale row was left behind by a drop that bypassed the T-SQL DROP
	 *     cleanup. This can only happen through interoperability paths (a drop
	 *     issued in the PG dialect, a cascaded drop, DROP OWNED BY / REASSIGN
	 *     OWNED, or DROP EXTENSION) -- a pure T-SQL workload always cleans the
	 *     row on DROP. The catalog is also SELECT-only to users, so no user can
	 *     inject such a row. In that rare case a new object whose physical name
	 *     collides with the orphan is being created with a DIFFERENT original
	 *     name; we must not keep displaying the old object's name, so overwrite
	 *     the row with the new original name instead of skipping.
	 *
	 * Distinguish the two by comparing the stored original name: identical =>
	 * skip; different => overwrite (delete the stale row, then insert below).
	 */
	{
		char *existing = lookup_bbf_ident_mapping(truncated_name, nspname,
												  objtype, parent_name);
		if (existing)
		{
			bool identical = (strcmp(existing, original_name) == 0);

			pfree(existing);
			if (identical)
				return;

			/*
			 * Stale row masking a new object's name: remove it so the insert
			 * below records the correct current original name.
			 */
			delete_bbf_ident_mapping(truncated_name, nspname, objtype,
									 parent_name);
		}
	}

	rel = table_open(get_bbf_ident_mapping_oid(), RowExclusiveLock);

	MemSet(nulls, false, sizeof(nulls));

	namestrcpy(&nspname_data, nspname);
	namestrcpy(&truncated_namedata, truncated_name);
	namestrcpy(&parent_namedata, parent_name ? parent_name : "");

	values[Anum_bbf_ident_mapping_nspname - 1] = NameGetDatum(&nspname_data);
	values[Anum_bbf_ident_mapping_pg_catalog_type - 1] = ObjectIdGetDatum(pg_catalog_type);
	values[Anum_bbf_ident_mapping_truncated_name - 1] = NameGetDatum(&truncated_namedata);
	values[Anum_bbf_ident_mapping_original_name - 1] = CStringGetTextDatum(original_name);
	values[Anum_bbf_ident_mapping_parent_name - 1] = NameGetDatum(&parent_namedata);

	tuple = heap_form_tuple(RelationGetDescr(rel), values, nulls);
	CatalogTupleInsert(rel, tuple);

	heap_freetuple(tuple);
	table_close(rel, RowExclusiveLock);

	CommandCounterIncrement();
}

/*
 * lookup_bbf_ident_mapping - Look up the original name for a truncated identifier.
 * Returns a palloc'd string, or NULL if not found.
 */
char *
lookup_bbf_ident_mapping(const char *truncated_name,
								const char *nspname,
								BbfIdentMappingObjType objtype,
								const char *parent_name)
{
	Relation	rel;
	SysScanDesc scan;
	ScanKeyData scanKey[4];
	HeapTuple	tuple;
	char	   *result = NULL;
	Oid			pg_catalog_type = bbf_ident_mapping_catalog_oid(objtype);
	NameData	truncated_namedata;
	NameData	nspname_data;
	NameData	parent_namedata;

	if (!OidIsValid(get_bbf_ident_mapping_oid()))
		return NULL;

	namestrcpy(&truncated_namedata, truncated_name);
	namestrcpy(&nspname_data, nspname);
	namestrcpy(&parent_namedata, parent_name ? parent_name : "");

	rel = table_open(get_bbf_ident_mapping_oid(), AccessShareLock);

	/*
	 * All four key columns are known here, so scan the primary-key index for
	 * an exact match. This is only reached on DDL paths (CREATE/ALTER of
	 * constraints, parameters, sequences and types), never on the DML or query
	 * hot path, so a direct catalog lookup is preferable to a dedicated
	 * syscache.
	 */
	ScanKeyInit(&scanKey[0],
				Anum_bbf_ident_mapping_nspname,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(&nspname_data));
	ScanKeyInit(&scanKey[1],
				Anum_bbf_ident_mapping_pg_catalog_type,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(pg_catalog_type));
	ScanKeyInit(&scanKey[2],
				Anum_bbf_ident_mapping_parent_name,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(&parent_namedata));
	ScanKeyInit(&scanKey[3],
				Anum_bbf_ident_mapping_truncated_name,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(&truncated_namedata));

	scan = systable_beginscan(rel, get_bbf_ident_mapping_idx_oid(), true,
							  NULL, 4, scanKey);

	tuple = systable_getnext(scan);
	if (HeapTupleIsValid(tuple))
	{
		bool		isNull;
		Datum		datum;

		datum = heap_getattr(tuple, Anum_bbf_ident_mapping_original_name,
							 RelationGetDescr(rel), &isNull);
		if (!isNull)
			result = TextDatumGetCString(datum);
	}

	systable_endscan(scan);
	table_close(rel, AccessShareLock);

	return result;
}

/*
 * delete_bbf_ident_mapping - Delete babelfish_identifier_mapping entries.
 *
 * Overloaded on truncated_name:
 *   - truncated_name != NULL: delete the single row matching the full primary
 *     key (truncated_name, nspname, pg_catalog_type, parent_name), using the PK
 *     index. Used when dropping/renaming a specific mapped object.
 *   - truncated_name == NULL: delete every row matching
 *     (nspname, pg_catalog_type, parent_name). Used when dropping a parent
 *     object (e.g. all constraints of a table, all parameters of a routine).
 */
void
delete_bbf_ident_mapping(const char *truncated_name,
								const char *nspname,
								BbfIdentMappingObjType objtype,
								const char *parent_name)
{
	Relation	rel;
	HeapTuple	tuple;
	NameData	truncated_namedata;
	NameData	nspname_data;
	NameData	parent_namedata;
	Oid			pg_catalog_type = bbf_ident_mapping_catalog_oid(objtype);
	bool		by_parent = (truncated_name == NULL);

	if (!OidIsValid(get_bbf_ident_mapping_oid()))
		return;

	namestrcpy(&nspname_data, nspname);
	namestrcpy(&parent_namedata, parent_name ? parent_name : "");

	rel = table_open(get_bbf_ident_mapping_oid(), RowExclusiveLock);

	if (!by_parent)
	{
		SysScanDesc scan;
		ScanKeyData scanKey[4];

		/*
		 * All four key columns are known, so use the primary-key index for an
		 * exact match. Only reached on DDL paths (DROP/rename of the mapped
		 * object), so a direct catalog lookup is preferable to a syscache.
		 */
		namestrcpy(&truncated_namedata, truncated_name);
		ScanKeyInit(&scanKey[0],
					Anum_bbf_ident_mapping_nspname,
					BTEqualStrategyNumber, F_NAMEEQ,
					NameGetDatum(&nspname_data));
		ScanKeyInit(&scanKey[1],
					Anum_bbf_ident_mapping_pg_catalog_type,
					BTEqualStrategyNumber, F_OIDEQ,
					ObjectIdGetDatum(pg_catalog_type));
		ScanKeyInit(&scanKey[2],
					Anum_bbf_ident_mapping_parent_name,
					BTEqualStrategyNumber, F_NAMEEQ,
					NameGetDatum(&parent_namedata));
		ScanKeyInit(&scanKey[3],
					Anum_bbf_ident_mapping_truncated_name,
					BTEqualStrategyNumber, F_NAMEEQ,
					NameGetDatum(&truncated_namedata));

		scan = systable_beginscan(rel, get_bbf_ident_mapping_idx_oid(), true,
								  NULL, 4, scanKey);

		tuple = systable_getnext(scan);
		if (HeapTupleIsValid(tuple))
			CatalogTupleDelete(rel, &tuple->t_self);

		systable_endscan(scan);
	}
	else
	{
		SysScanDesc scan;
		ScanKeyData scanKey[3];

		/*
		 * Key the scan on (nspname, pg_catalog_type, parent_name) so we don't
		 * walk the entire catalog on every DROP. These are the leading three
		 * columns of the primary key, so the PK index serves this prefix scan
		 * directly; truncated_identifier_name (the trailing PK column) is not
		 * known here and is simply left unconstrained.
		 */
		ScanKeyInit(&scanKey[0],
					Anum_bbf_ident_mapping_nspname,
					BTEqualStrategyNumber, F_NAMEEQ,
					NameGetDatum(&nspname_data));
		ScanKeyInit(&scanKey[1],
					Anum_bbf_ident_mapping_pg_catalog_type,
					BTEqualStrategyNumber, F_OIDEQ,
					ObjectIdGetDatum(pg_catalog_type));
		ScanKeyInit(&scanKey[2],
					Anum_bbf_ident_mapping_parent_name,
					BTEqualStrategyNumber, F_NAMEEQ,
					NameGetDatum(&parent_namedata));

		scan = systable_beginscan(rel, get_bbf_ident_mapping_idx_oid(), true,
								  NULL, 3, scanKey);

		while (HeapTupleIsValid(tuple = systable_getnext(scan)))
			CatalogTupleDelete(rel, &tuple->t_self);

		systable_endscan(scan);
	}

	table_close(rel, RowExclusiveLock);

	CommandCounterIncrement();
}

/*
 * delete_bbf_ident_mapping_for_drop - Single entry point for DROP-time
 * cleanup of babelfish_identifier_mapping. Given the T-SQL object type being
 * dropped, it selects both the mapped object class and the correct delete form
 * internally, so the DROP handler has one call site instead of a per-type
 * branch that each open-codes the enum and by-name/by-parent choice:
 *
 *   - TABLE:              delete every constraint row owned by the table
 *                         (by-parent, parent_name = physical table name).
 *   - SEQUENCE / TYPE:    delete the single row for the object itself
 *                         (by-name, truncated_name = physical object name).
 *   - PROCEDURE/FUNCTION: delete every parameter row owned by the routine
 *                         (by-parent, parent_name = physical routine name).
 *
 * Object types with no mapped identifiers (e.g. VIEW) are a no-op.
 */
void
delete_bbf_ident_mapping_for_drop(ObjectType removeType,
								  const char *schema_name,
								  const char *major_name)
{
	if (schema_name == NULL || major_name == NULL)
		return;

	switch (removeType)
	{
		case OBJECT_TABLE:
			/* All constraints of the table, keyed on the table as parent. */
			delete_bbf_ident_mapping(NULL, schema_name,
									 BBF_IDENT_CONSTRAINT, major_name);
			break;
		case OBJECT_SEQUENCE:
			/* The sequence itself. */
			delete_bbf_ident_mapping(major_name, schema_name,
									 BBF_IDENT_SEQUENCE, NULL);
			break;
		case OBJECT_TYPE:
			/* The type itself. */
			delete_bbf_ident_mapping(major_name, schema_name,
									 BBF_IDENT_TYPE, NULL);
			break;
		case OBJECT_PROCEDURE:
		case OBJECT_FUNCTION:
			/* All parameters of the routine, keyed on the routine as parent. */
			delete_bbf_ident_mapping(NULL, schema_name,
									 BBF_IDENT_PARAMETER, major_name);
			break;
		default:
			/* No mapped identifiers for other object types (e.g. VIEW). */
			break;
	}
}

/*
 * update_bbf_ident_mapping_parent - Re-point all entries matching
 * nspname + pg_catalog_type + old_parent_name to new_parent_name. Used when a
 * parent object is renamed (e.g. sp_rename on a table), so that constraint
 * mapping rows continue to match the parent's new physical name at DROP time.
 * Without this, a rename orphans the rows (their parent_name still holds the
 * old physical name) and DROP-time cleanup misses them, leaking a stale row
 * that could later resolve to the wrong original name.
 */
void
update_bbf_ident_mapping_parent(const char *nspname,
								BbfIdentMappingObjType objtype,
								const char *old_parent_name,
								const char *new_parent_name)
{
	Relation	rel;
	SysScanDesc scan;
	ScanKeyData scanKey[3];
	HeapTuple	tuple;
	NameData	nspname_data;
	NameData	old_parent_data;
	NameData	new_parent_data;
	Oid			pg_catalog_type = bbf_ident_mapping_catalog_oid(objtype);
	Datum		values[BBF_IDENT_MAPPING_NUM_COLS];
	bool		nulls[BBF_IDENT_MAPPING_NUM_COLS];
	bool		replaces[BBF_IDENT_MAPPING_NUM_COLS];

	if (!OidIsValid(get_bbf_ident_mapping_oid()))
		return;

	/* Nothing to do if the physical parent name did not change. */
	if (old_parent_name && new_parent_name &&
		strcmp(old_parent_name, new_parent_name) == 0)
		return;

	namestrcpy(&nspname_data, nspname);
	namestrcpy(&old_parent_data, old_parent_name ? old_parent_name : "");
	namestrcpy(&new_parent_data, new_parent_name ? new_parent_name : "");

	rel = table_open(get_bbf_ident_mapping_oid(), RowExclusiveLock);

	ScanKeyInit(&scanKey[0],
				Anum_bbf_ident_mapping_nspname,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(&nspname_data));
	ScanKeyInit(&scanKey[1],
				Anum_bbf_ident_mapping_pg_catalog_type,
				BTEqualStrategyNumber, F_OIDEQ,
				ObjectIdGetDatum(pg_catalog_type));
	ScanKeyInit(&scanKey[2],
				Anum_bbf_ident_mapping_parent_name,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(&old_parent_data));

	scan = systable_beginscan(rel, get_bbf_ident_mapping_idx_oid(), true,
							  NULL, 3, scanKey);

	/*
	 * Every matching row gets the same single-column update (parent_name ->
	 * new_parent_data), so the values/nulls/replaces arrays are identical
	 * across iterations and can be set up once outside the loop.
	 */
	MemSet(values, 0, sizeof(values));
	MemSet(nulls, false, sizeof(nulls));
	MemSet(replaces, false, sizeof(replaces));

	values[Anum_bbf_ident_mapping_parent_name - 1] = NameGetDatum(&new_parent_data);
	replaces[Anum_bbf_ident_mapping_parent_name - 1] = true;

	while (HeapTupleIsValid(tuple = systable_getnext(scan)))
	{
		HeapTuple	newtuple;

		newtuple = heap_modify_tuple(tuple, RelationGetDescr(rel),
									 values, nulls, replaces);
		CatalogTupleUpdate(rel, &newtuple->t_self, newtuple);
		heap_freetuple(newtuple);
	}

	systable_endscan(scan);
	table_close(rel, RowExclusiveLock);

	CommandCounterIncrement();
}

/*
 * clean_up_bbf_ident_mapping - Remove all entries for a given nspname.
 * Used during DROP SCHEMA / DROP DATABASE.
 */
void
clean_up_bbf_ident_mapping(const char *nspname)
{
	Relation	rel;
	SysScanDesc scan;
	ScanKeyData scanKey[1];
	HeapTuple	tuple;
	NameData	nspname_data;

	if (!OidIsValid(get_bbf_ident_mapping_oid()))
		return;

	namestrcpy(&nspname_data, nspname);

	rel = table_open(get_bbf_ident_mapping_oid(), RowExclusiveLock);

	ScanKeyInit(&scanKey[0],
				Anum_bbf_ident_mapping_nspname,
				BTEqualStrategyNumber, F_NAMEEQ,
				NameGetDatum(&nspname_data));

	scan = systable_beginscan(rel, get_bbf_ident_mapping_idx_oid(), true,
							  NULL, 1, scanKey);

	while (HeapTupleIsValid(tuple = systable_getnext(scan)))
	{
		CatalogTupleDelete(rel, &tuple->t_self);
	}

	systable_endscan(scan);
	table_close(rel, RowExclusiveLock);

	CommandCounterIncrement();
}

/*
 * ------------------------------------------------------------------------
 * DDL-time helpers: extract the original identifier from the statement text
 * and store it in the mapping catalog. Invoked from the ProcessUtility hooks
 * in pl_handler.c.
 * ------------------------------------------------------------------------
 */

/*
 * Build an AlterTableCmd that sets a single reloption/attoption (name=value).
 * Centralizes the repeated command-construction pattern used when stashing
 * original (untruncated) identifiers.
 */
AlterTableCmd *
build_set_option_cmd(AlterTableType subtype, const char *optname, const char *optval)
{
	AlterTableCmd *cmd = makeNode(AlterTableCmd);

	cmd->subtype = subtype;
	cmd->def = (Node *) list_make1(makeDefElem(pstrdup(optname),
											   (Node *) makeString(pstrdup(optval)), -1));
	cmd->behavior = DROP_RESTRICT;
	cmd->missing_ok = false;
	return cmd;
}

/*
 * Extract the original (untruncated) index name from the query source text.
 *
 * The grammar appends a TSQL_ORIGINAL_NAME_LOCATION option carrying the byte
 * offset of the identifier within queryString. This option is removed here so
 * that DefineIndex does not reject it as unrecognized. Returns a palloc'd
 * string, or NULL if the option is absent or invalid.
 */
char *
extract_index_original_name(IndexStmt *stmt, const char *queryString)
{
	ListCell   *opt_lc;
	char	   *original_name = NULL;

	/*
	 * Iterate all options and remove every tsql_original_name_location entry.
	 * The grammar appends exactly one such entry, distinguished by a DefElem
	 * location of -1 (see gram-tsql-rule.y); its Integer arg is the byte offset
	 * of the identifier in queryString. A user-supplied
	 * WITH (tsql_original_name_location = ...) arrives with location >= 0 - that
	 * is a tamper attempt on an internal-only option and is rejected, mirroring
	 * how the bbf_original_* reserved options are rejected. Any recognized
	 * (grammar) entry is stripped so DefineIndex does not see the internal
	 * option.
	 */
	foreach(opt_lc, stmt->options)
	{
		DefElem *defel = (DefElem *) lfirst(opt_lc);

		if (strcmp(defel->defname, TSQL_ORIGINAL_NAME_LOCATION) == 0)
		{
			/*
			 * Only the grammar-appended entry (location == -1) is trusted.
			 * A user-written option (location >= 0) must not be able to choose
			 * what gets stored as the internal original name.
			 */
			if (defel->location >= 0)
				ereport(ERROR,
						(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
						 errmsg("option \"%s\" is reserved for internal Babelfish use and cannot be set",
								TSQL_ORIGINAL_NAME_LOCATION)));

			if (!original_name && defel->arg && IsA(defel->arg, Integer))
			{
				int loc = intVal(defel->arg);

				if (loc >= 0 && queryString && (size_t) loc < strlen(queryString))
					original_name = extract_identifier(queryString + loc, NULL);
			}
			stmt->options = foreach_delete_current(stmt->options, opt_lc);
		}
	}
	return original_name;
}

/*
 * extract_and_strip_view_collist_loc
 *
 * The T-SQL CREATE [OR ALTER] VIEW grammar records the source-text location of
 * an explicit column list "(c1, c2, ...)" by appending an internal
 * bbf_view_collist_loc DefElem to ViewStmt->options. That option is only a
 * parse-time carrier and must not be persisted as a real reloption on the view.
 * Remove it from the options list here, BEFORE the view is created, so it never
 * lands in pg_class.reloptions (avoiding a follow-up AT_ResetRelOptions), and
 * return the recorded location for use in original-name storage.
 *
 * Returns the recorded location, or -1 if the option is absent/invalid.
 */
int
extract_and_strip_view_collist_loc(ViewStmt *stmt)
{
	int			collist_loc = -1;
	ListCell   *olc;

	if (stmt == NULL)
		return -1;

	foreach(olc, stmt->options)
	{
		DefElem    *defel = (DefElem *) lfirst(olc);

		if (defel->defname &&
			strcmp(defel->defname, BBF_VIEW_COLLIST_LOC_OPTION) == 0)
		{
			if (defel->arg && IsA(defel->arg, Integer))
				collist_loc = intVal(defel->arg);

			/* Delete the internal option so it is never stored on the view. */
			stmt->options = foreach_delete_current(stmt->options, olc);
			break;
		}
	}

	return collist_loc;
}

/*
 * Store original view/relation name in reloptions if it differs from the
 * internal (lowercased/truncated) name.
 */
void
store_view_original_name(ViewStmt *stmt, const char *queryString)
{
	char *original_name;

	if (stmt->view->location < 0 || !queryString || babelfish_dump_restore)
		return;

	/* Guard against a location beyond the query text before dereferencing. */
	if ((size_t) stmt->view->location >= strlen(queryString))
		return;

	original_name = extract_multipart_identifier_name(queryString + stmt->view->location);
	if (original_name &&
		(strcmp(stmt->view->relname, original_name) != 0))
	{
		Oid viewOid = RangeVarGetRelid(stmt->view, NoLock, true);

		if (OidIsValid(viewOid))
		{
			AlterTableCmd *cmd = build_set_option_cmd(AT_SetRelOptions,
													  ATTOPTION_BBF_ORIGINAL_TABLE_NAME,
													  original_name);
			AlterTableInternal(viewOid, list_make1(cmd), false);
			CommandCounterIncrement();
		}
	}

	if (original_name)
		pfree(original_name);
}

/*
 * Store original column names in pg_attribute.attoptions for view columns
 * that were truncated. Extracts full names from the query string.
 */

/*
 * Minimal parser setup callback for reparsing view queries.
 * Only sets p_post_expand_star_hook so that SELECT * expansion
 * populates resorigname from attoptions.
 */
static void
view_reparse_parser_setup(ParseState *pstate, void *arg)
{
	pstate->p_post_expand_star_hook = pltsql_post_expand_star;
}

/*
 * skip_collist_separators
 *
 * Advance past separators (commas, whitespace) and SQL comments (block and
 * line). Used between column identifiers in a source column list, and to
 * reach the constraint name after the CONSTRAINT keyword (valid SQL allows
 * whitespace/comments there; a comma never appears in that position so
 * skipping commas is a harmless no-op). Returns the pointer at the next
 * identifier, ')' or end of string.
 */
const char *
skip_collist_separators(const char *p)
{
	while (*p)
	{
		if (*p == ',' || scanner_isspace(*p))
			p++;
		else if (*p == '/' && *(p + 1) == '*')
		{
			/*
			 * T-SQL allows nested block comments, so track depth and only
			 * exit when the outermost comment is closed.
			 */
			int			depth = 1;

			p += 2;
			while (*p && depth > 0)
			{
				if (*p == '/' && *(p + 1) == '*')
				{
					depth++;
					p += 2;
				}
				else if (*p == '*' && *(p + 1) == '/')
				{
					depth--;
					p += 2;
				}
				else
					p++;
			}
		}
		else if (*p == '-' && *(p + 1) == '-')
		{
			while (*p && *p != '\n')
				p++;
		}
		else
			break;
	}
	return p;
}

/*
 * store_table_constraint_original_names
 *
 * For a CREATE TABLE statement, scan the table- and column-level constraints
 * and store the original (untruncated) constraint names in
 * sys.babelfish_identifier_mapping. The original name is recovered from the
 * source query text at each Constraint's location (which points at the
 * CONSTRAINT keyword). No-op unless the table's physical namespace can be
 * resolved. This runs after the table has been created so the namespace
 * lookup succeeds.
 */
void
store_table_constraint_original_names(CreateStmt *create_stmt, RangeVar *rel,
									  const char *queryString)
{
	ListCell   *lc;
	const char *nspname;
	const char *phys_relname;
	Oid			relOid = RangeVarGetRelid(rel, NoLock, true);
	size_t		qlen;

	/*
	 * Always resolve the PHYSICAL namespace and relation name from the created
	 * table's OID. DROP TABLE cleanup keys the mapping on the physical relation
	 * name (RelationGetRelationName), so the constraint rows must be filed
	 * under the same physical parent name -- otherwise, for a table name >=
	 * NAMEDATALEN bytes (where the physical name is MD5-truncated and differs
	 * from the parse-tree name), the drop-time delete matches nothing and the
	 * row leaks. get_namespace_name / get_rel_name return palloc'd strings that
	 * we free before returning.
	 */
	if (!OidIsValid(relOid))
		return;

	nspname = get_namespace_name(get_rel_namespace(relOid));
	phys_relname = get_rel_name(relOid);

	if (!nspname || !phys_relname)
	{
		if (nspname)
			pfree((char *) nspname);
		if (phys_relname)
			pfree((char *) phys_relname);
		return;
	}

	qlen = strlen(queryString);

	foreach(lc, create_stmt->tableElts)
	{
		Node *elt = (Node *) lfirst(lc);

		if (IsA(elt, Constraint))
		{
			Constraint *con = (Constraint *) elt;

			if (con->conname && con->location >= 0 &&
				(size_t) con->location + CONSTRAINT_KEYWORD_LEN < qlen &&
				pg_strncasecmp(queryString + con->location, "CONSTRAINT",
							   CONSTRAINT_KEYWORD_LEN) == 0)
			{
				const char *start = skip_collist_separators(queryString + con->location + CONSTRAINT_KEYWORD_LEN);
				char *original_name;

				original_name = extract_identifier(start, NULL);

				/* Only store when the name is long enough to be truncated. */
				if (original_name && strlen(original_name) >= NAMEDATALEN)
				{
					insert_bbf_ident_mapping(con->conname,
											 original_name, nspname,
											 BBF_IDENT_CONSTRAINT, phys_relname);
				}
				if (original_name)
					pfree(original_name);
			}
		}
		else if (IsA(elt, ColumnDef))
		{
			ColumnDef *coldef = (ColumnDef *) elt;
			ListCell *clc;

			foreach(clc, coldef->constraints)
			{
				Constraint *con = (Constraint *) lfirst(clc);

				if (IsA(con, Constraint) && con->conname && con->location >= 0 &&
					(size_t) con->location + CONSTRAINT_KEYWORD_LEN < qlen &&
					pg_strncasecmp(queryString + con->location, "CONSTRAINT",
								   CONSTRAINT_KEYWORD_LEN) == 0)
				{
					const char *start = skip_collist_separators(queryString + con->location + CONSTRAINT_KEYWORD_LEN);
					char *original_name;

					original_name = extract_identifier(start, NULL);

					/* Only store when the name is long enough to be truncated. */
					if (original_name && strlen(original_name) >= NAMEDATALEN)
					{
						insert_bbf_ident_mapping(con->conname,
												 original_name, nspname,
												 BBF_IDENT_CONSTRAINT, phys_relname);
					}
					if (original_name)
						pfree(original_name);
				}
			}
		}
	}

	pfree((char *) nspname);
	pfree((char *) phys_relname);
}

/*
 * store_sequence_original_name
 *
 * Store the original (untruncated) name of a CREATE SEQUENCE in
 * sys.babelfish_identifier_mapping. The original name is recovered from the
 * source query text at the sequence's location. Runs after the sequence has
 * been created so its physical namespace can be resolved. No-op during
 * dump/restore or when the namespace cannot be resolved.
 */
void
store_sequence_original_name(CreateSeqStmt *seq_stmt, const char *queryString)
{
	char	   *original_name;

	if (seq_stmt->sequence->location < 0 || !queryString ||
		(size_t) seq_stmt->sequence->location >= strlen(queryString) ||
		babelfish_dump_restore)
		return;

	original_name = extract_multipart_identifier_name(queryString + seq_stmt->sequence->location);

	if (original_name)
	{
		Oid			seqOid = RangeVarGetRelid(seq_stmt->sequence, NoLock, true);
		char	   *nspname = NULL;

		/*
		 * Always key the mapping on the PHYSICAL namespace of the created
		 * sequence, resolved from its OID. The sys.objects / sys.all_objects
		 * sequence rows resolve the original name via the physical namespace
		 * (relnamespace::regnamespace::name), so keying on the logical
		 * schemaname from the parse tree (e.g. "dbo") when the user
		 * schema-qualifies the object would file the row under the wrong
		 * schema and the view lookup would miss, leaking the truncated name.
		 */
		if (OidIsValid(seqOid))
			nspname = get_namespace_name(get_rel_namespace(seqOid));

		if (nspname)
		{
			insert_bbf_ident_mapping(seq_stmt->sequence->relname,
									 original_name, nspname,
									 BBF_IDENT_SEQUENCE, NULL);
			pfree(nspname);
		}
		pfree(original_name);
	}
}

/*
 * store_view_explicit_column_names
 *
 * Handle CREATE VIEW v (c1, c2, ...) explicit column alias lists. The grammar
 * recorded the source location of the column list '(' (passed here as
 * collist_loc, already stripped from the statement's options). Walk the list
 * with extract_identifier and store bbf_original_name attoptions for columns
 * whose original differs from their (truncated/lowercased) physical attname.
 */
static void
store_view_explicit_column_names(const char *queryString,
								 Oid viewOid, TupleDesc tupdesc, int collist_loc)
{
	const char *p;
	int			col = 0;
	List	   *cmds = NIL;

	if (collist_loc >= 0 && (size_t) collist_loc < strlen(queryString))
	{
		p = queryString + collist_loc;		/* points at '(' */
		if (*p == '(')
			p++;

		while (col < tupdesc->natts)
		{
			char	   *original_name;
			int			last_pos = 0;
			Form_pg_attribute attr;

			p = skip_collist_separators(p);
			if (*p == '\0' || *p == ')')
				break;

			original_name = extract_identifier(p, &last_pos);
			if (!original_name || last_pos <= 0)
				break;
			p += last_pos;

			attr = TupleDescAttr(tupdesc, col++);
			/*
			 * A freshly created/altered view has no dropped columns, so this
			 * branch is not expected to be hit; guard against it defensively.
			 */
			if (attr->attisdropped)
			{
				pfree(original_name);
				continue;
			}

			if (strcmp(NameStr(attr->attname), original_name) != 0)
			{
				AlterTableCmd *cmd = build_set_option_cmd(AT_SetOptions,
														  ATTOPTION_BBF_ORIGINAL_NAME,
														  original_name);
				cmd->name = pstrdup(NameStr(attr->attname));
				cmds = lappend(cmds, cmd);
			}
			pfree(original_name);
		}
	}

	if (cmds != NIL)
	{
		AlterTableInternal(viewOid, cmds, false);
		CommandCounterIncrement();
	}
}

void
store_view_column_original_names(ViewStmt *stmt, const char *queryString, int collist_loc)
{
	Oid			viewOid;
	Relation	rel;
	TupleDesc	tupdesc;
	Query	   *reparsed;
	RawStmt    *rawstmt;
	ListCell   *lc;
	List	   *cmds = NIL;
	int			attnum = 0;

	if (!queryString)
		return;

	viewOid = RangeVarGetRelid(stmt->view, NoLock, true);
	if (!OidIsValid(viewOid))
		return;

	rel = relation_open(viewOid, AccessShareLock);
	tupdesc = RelationGetDescr(rel);

	/*
	 * Case A: View has an explicit column alias list (CREATE VIEW v (c1, c2)
	 * AS ...). Handle it separately using the recorded column-list location.
	 */
	if (stmt->aliases != NIL)
	{
		store_view_explicit_column_names(queryString, viewOid, tupdesc, collist_loc);
		relation_close(rel, AccessShareLock);
		return;
	}

	/*
	 * Reparse the view's SELECT query with p_post_expand_star_hook set,
	 * so that all TargetEntries (including those from SELECT *) get
	 * resorigname populated from attoptions.
	 */
	rawstmt = makeNode(RawStmt);
	rawstmt->stmt = (Node *) copyObject(stmt->query);
	rawstmt->stmt_location = 0;
	rawstmt->stmt_len = strlen(queryString);

	reparsed = parse_analyze_withcb(rawstmt, queryString,
									(ParserSetupHook) view_reparse_parser_setup,
									NULL, NULL);

	if (!reparsed || reparsed->commandType != CMD_SELECT)
	{
		relation_close(rel, AccessShareLock);
		return;
	}

	foreach(lc, reparsed->targetList)
	{
		TargetEntry *tle = (TargetEntry *) lfirst(lc);
		Form_pg_attribute attr;

		if (tle->resjunk)
			continue;

		attnum++;
		if (attnum > tupdesc->natts)
			break;

		attr = TupleDescAttr(tupdesc, attnum - 1);

		if (tle->resorigname && strcmp(NameStr(attr->attname), tle->resorigname) != 0)
		{
			AlterTableCmd *cmd = build_set_option_cmd(AT_SetOptions,
													  ATTOPTION_BBF_ORIGINAL_NAME,
													  tle->resorigname);
			cmd->name = pstrdup(NameStr(attr->attname));
			cmds = lappend(cmds, cmd);
		}
	}

	relation_close(rel, AccessShareLock);

	if (cmds != NIL)
	{
		AlterTableInternal(viewOid, cmds, false);
		CommandCounterIncrement();
	}
}

/*
 * block_bbf_original_name_reloption
 *
 * The bbf_original_rel_name and bbf_original_name reloptions/attoptions are
 * reserved for Babelfish's internal storage of original (long/mixed-case)
 * identifiers. Block any attempt to set them from the PG dialect, on either
 * the CREATE paths (CREATE TABLE / VIEW / INDEX / SELECT INTO) or ALTER TABLE.
 * Called unconditionally (not gated by enable_create_alter_view_from_pg) so it
 * cannot be bypassed by enabling that GUC.
 */
static void
reject_reserved_bbf_original_name_options(List *options)
{
	ListCell   *lopt;

	foreach(lopt, options)
	{
		DefElem    *defel = (DefElem *) lfirst(lopt);

		/*
		 * Compare case-insensitively: a quoted option name (e.g.
		 * "BBF_ORIGINAL_REL_NAME") keeps its case in defname, but the
		 * underlying reloption handler matches it case-insensitively and
		 * would apply the value, so strcmp() would let it slip through.
		 */
		if (defel->defname &&
			(pg_strcasecmp(defel->defname, ATTOPTION_BBF_ORIGINAL_TABLE_NAME) == 0 ||
			 pg_strcasecmp(defel->defname, ATTOPTION_BBF_ORIGINAL_NAME) == 0 ||
			 pg_strcasecmp(defel->defname, ATTOPTION_BBF_TABLE_CREATE_DATE) == 0))
			ereport(ERROR,
					(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
					 errmsg("relation option \"%s\" is reserved for internal Babelfish use and cannot be set",
							defel->defname)));
	}
}

void
block_bbf_original_name_reloption(Node *parsetree)
{
	ListCell   *lc;

	/*
	 * The bypass for restore must NOT be gated on babelfish_dump_restore
	 * alone: that GUC is PGC_USERSET, so any authenticated user could set it
	 * and then forge the stored original identifiers. Legitimate dump/restore
	 * always runs as superuser, so require superuser() in addition. This
	 * matches the established babelfish_dump_restore && superuser() pattern
	 * used elsewhere in this file for restore-only privileged paths.
	 */
	if (sql_dialect != SQL_DIALECT_PG || (babelfish_dump_restore && superuser()))
		return;

	switch (nodeTag(parsetree))
	{
		case T_AlterTableStmt:
			{
				AlterTableStmt *atstmt = (AlterTableStmt *) parsetree;

				foreach(lc, atstmt->cmds)
				{
					AlterTableCmd *cmd = (AlterTableCmd *) lfirst(lc);

					if (cmd->subtype == AT_SetRelOptions || cmd->subtype == AT_ResetRelOptions ||
						cmd->subtype == AT_ReplaceRelOptions ||
						cmd->subtype == AT_SetOptions || cmd->subtype == AT_ResetOptions)
						reject_reserved_bbf_original_name_options((List *) cmd->def);
				}
				break;
			}
		case T_CreateStmt:
			reject_reserved_bbf_original_name_options(((CreateStmt *) parsetree)->options);
			break;
		case T_ViewStmt:
			reject_reserved_bbf_original_name_options(((ViewStmt *) parsetree)->options);
			break;
		case T_IndexStmt:
			reject_reserved_bbf_original_name_options(((IndexStmt *) parsetree)->options);
			break;
		case T_CreateTableAsStmt:
			{
				CreateTableAsStmt *ctas = (CreateTableAsStmt *) parsetree;

				if (ctas->into != NULL)
					reject_reserved_bbf_original_name_options(ctas->into->options);
				break;
			}
		default:
			break;
	}
}

/*-------------------------------------------------------------------------
 *		SESSION IDENTIFIER CACHE + ERROR-MESSAGE NAME RESOLUTION
 *
 * A per-session cache maps a truncated/mangled physical identifier back to the
 * original user-supplied name so that error messages can display the original.
 * The TDS layer calls bbf_rewrite_truncated_identifiers() on outgoing error
 * text; the engine error hooks call bbf_get_original_ident_name(). Both are
 * co-located here with the babelfish_identifier_mapping catalog helpers they
 * delegate to (lookup_bbf_ident_mapping).
 *-------------------------------------------------------------------------
 */
/* Session cache for error message rewriting - type defined in catalog.h */

static HTAB *ident_name_cache = NULL;

static void
ensure_ident_name_cache(void)
{
	if (ident_name_cache == NULL)
	{
		HASHCTL		ctl;

		MemSet(&ctl, 0, sizeof(ctl));
		ctl.keysize = NAMEDATALEN;
		ctl.entrysize = sizeof(IdentNameCacheEntry);
		ctl.hcxt = TopMemoryContext;
		ident_name_cache = hash_create("Babelfish truncated identifier cache", 64, &ctl,
									   HASH_ELEM | HASH_STRINGS | HASH_CONTEXT);
	}
}

void
bbf_reset_ident_name_cache(void)
{
	if (ident_name_cache)
	{
		hash_destroy(ident_name_cache);
		ident_name_cache = NULL;
	}
}

/*
 * Snapshot current cache entries into a caller-provided array.
 * Returns number of entries copied. Used by pl_comp to save
 * mappings onto PLtsql_function during compilation.
 */
int
bbf_snapshot_ident_cache(IdentNameCacheEntry **entries, MemoryContext cxt)
{
	HASH_SEQ_STATUS status;
	IdentNameCacheEntry *entry;
	int			n;
	int			i = 0;

	if (!ident_name_cache)
	{
		*entries = NULL;
		return 0;
	}

	n = hash_get_num_entries(ident_name_cache);
	if (n == 0)
	{
		*entries = NULL;
		return 0;
	}

	*entries = (IdentNameCacheEntry *) MemoryContextAlloc(cxt, n * sizeof(IdentNameCacheEntry));
	hash_seq_init(&status, ident_name_cache);
	while ((entry = (IdentNameCacheEntry *) hash_seq_search(&status)) != NULL)
	{
		memcpy(&(*entries)[i], entry, sizeof(IdentNameCacheEntry));
		i++;
	}
	return i;
}

/*
 * Restore cached entries from a snapshot. Used by pl_exec
 * at EXEC entry to repopulate the batch cache.
 */
void
bbf_restore_ident_cache(IdentNameCacheEntry *entries, int n)
{
	int i;

	if (!entries || n == 0)
		return;

	ensure_ident_name_cache();
	for (i = 0; i < n; i++)
	{
		IdentNameCacheEntry *e;
		bool found;

		e = (IdentNameCacheEntry *) hash_search(ident_name_cache,
												entries[i].truncated_name,
												HASH_ENTER, &found);
		if (!found)
			strlcpy(e->original_name, entries[i].original_name, sizeof(e->original_name));
	}
}

void
bbf_cache_ident_name(const char *truncated_name, const char *original_name)
{
	IdentNameCacheEntry *entry;
	bool		found;

	if (!truncated_name || truncated_name[0] == '\0')
		return;

	if (!original_name || strlen(original_name) < NAMEDATALEN - 1)
		return;

	ensure_ident_name_cache();
	entry = (IdentNameCacheEntry *) hash_search(ident_name_cache, truncated_name, HASH_ENTER, &found);
	strlcpy(entry->original_name, original_name, sizeof(entry->original_name));
}

/*
 * Cache index internal name → original index name unconditionally.
 * Used by construct_unique_index_name so error messages always show
 * the user-supplied index name even for short identifiers.
 */
void
bbf_cache_index_name(const char *internal_name, const char *index_name)
{
	IdentNameCacheEntry *entry;
	bool		found;

	if (!internal_name || internal_name[0] == '\0' ||
		!index_name || strcmp(internal_name, index_name) == 0)
		return;

	ensure_ident_name_cache();

	entry = (IdentNameCacheEntry *) hash_search(ident_name_cache, internal_name, HASH_ENTER, &found);
	strlcpy(entry->original_name, index_name, sizeof(entry->original_name));
}

PGDLLEXPORT const char *
bbf_lookup_ident_name(const char *truncated_name)
{
	IdentNameCacheEntry *entry;

	if (!ident_name_cache)
		return NULL;

	entry = (IdentNameCacheEntry *) hash_search(ident_name_cache, truncated_name, HASH_FIND, NULL);
	return entry ? entry->original_name : NULL;
}

/*
 * Scan an error message for any cached truncated identifier and replace it with
 * the original name. Returns a new message (allocated in TopMemoryContext) or
 * NULL if no replacement was made. Called by the TDS layer on outgoing errors.
 */
PGDLLEXPORT char *
bbf_rewrite_truncated_identifiers(const char *msg)
{
	HASH_SEQ_STATUS		status;
	IdentNameCacheEntry *entry;
	char			   *result = NULL;

	if (!msg)
		return NULL;

	ensure_ident_name_cache();

	/* Session cache pass: replace truncated identifiers with lowercased originals */
	if (hash_get_num_entries(ident_name_cache) > 0)
	{
		hash_seq_init(&status, ident_name_cache);
		while ((entry = (IdentNameCacheEntry *) hash_seq_search(&status)) != NULL)
		{
			const char *key = entry->truncated_name;
			int			key_len = strlen(key);
			const char *found;
			const char *search_msg = result ? result : msg;

			/* Skip empty keys - strstr("anything","") never returns NULL */
			if (key_len == 0)
				continue;

			/* Replace all occurrences of this key in the message */
			found = strstr(search_msg, key);
			while (found)
			{
				char	before;
				char	after;
				int		prefix_len;
				int		orig_len;
				int		suffix_len;
				char   *newmsg;
				char   *oldmsg;

				/*
				 * Word-boundary check: ensure the match is not part of a
				 * larger identifier, and does not start/end in the middle of a
				 * multi-byte (UTF-8) character.
				 *
				 * A UTF-8 continuation byte matches (b & 0xC0) == 0x80. If the
				 * byte immediately before the match is a continuation byte, the
				 * match started inside a codepoint; if the first byte after the
				 * match is a continuation byte, the match ended inside a
				 * codepoint. Either way a replacement would corrupt UTF-8, so
				 * skip. (A lead byte neighbour is fine - that is a complete,
				 * separate character.) For single-byte (ASCII) neighbours we
				 * additionally reject alphanumeric / underscore so we do not
				 * rewrite a substring of a larger identifier.
				 */
				before = (found > search_msg) ? *(found - 1) : '\0';
				after = *(found + key_len);

				if (((unsigned char) before & 0xC0) == 0x80 ||
					((unsigned char) after & 0xC0) == 0x80)
				{
					/* Match edge falls inside a multi-byte char - skip */
					found = strstr(found + key_len, key);
					continue;
				}

				/*
				 * Reject a match that abuts a larger ASCII identifier. Only
				 * apply the alnum/underscore test to genuine ASCII bytes
				 * (< 0x80); a multibyte lead byte here is a complete, separate
				 * character and thus a valid boundary.
				 */
				if ((!IS_HIGHBIT_SET(before) && before != '\0' &&
					 (isalnum((unsigned char) before) || before == '_')) ||
					(!IS_HIGHBIT_SET(after) && after != '\0' &&
					 (isalnum((unsigned char) after) || after == '_')))
				{
					/* Not a word boundary - skip to next occurrence */
					found = strstr(found + key_len, key);
					continue;
				}

				prefix_len = found - search_msg;
				orig_len = strlen(entry->original_name);
				suffix_len = strlen(found + key_len);
				/*
				 * Allocate in ErrorContext: this runs on the error-emission
				 * path, and ErrorContext is reset once the error has been
				 * processed, so the rewritten message is reclaimed automatically
				 * and never leaks even if the send throws. (Intermediate
				 * allocations are still freed explicitly below.)
				 */
				newmsg = MemoryContextAlloc(ErrorContext,
										    prefix_len + orig_len + suffix_len + 1);
				oldmsg = result;

				memcpy(newmsg, search_msg, prefix_len);
				memcpy(newmsg + prefix_len, entry->original_name, orig_len);
				memcpy(newmsg + prefix_len + orig_len, found + key_len, suffix_len + 1);

				/* Free intermediate allocation */
				if (oldmsg)
					pfree(oldmsg);

				search_msg = newmsg;
				result = newmsg;
				found = strstr(search_msg + prefix_len + orig_len, key);
			}
		}
	}

	return result;
}

/*
 * bbf_get_original_index_name - resolve the original (pre-truncation) name of
 * an index for error-message display.
 *
 * PRIMARY KEY / UNIQUE indexes store their original name in the backing index
 * relation's bbf_original_name reloption (present even for short physical
 * names). We resolve the bare name to its relation Oid and delegate to the
 * canonical get_original_relname(), which reads the reloption for index
 * relkinds. Returns the original name (downcased, palloc'd) if one is stored,
 * else the input idxname unchanged.
 */
static const char *
bbf_get_original_index_name(const char *idxname, Oid idxoid)
{
	char	   *orig;

	/*
	 * Prefer the Oid the caller passed (the index relation Oid at the error
	 * site); only fall back to resolving the name through the search path when
	 * no Oid is available.
	 */
	if (!OidIsValid(idxoid))
		idxoid = RelnameGetRelid(idxname);
	if (!OidIsValid(idxoid))
		return idxname;

	orig = get_original_relname(idxoid, false);
	if (orig)
	{
		const char *result = idxname;

		/* get_original_relname falls back to the physical relname. */
		if (strcmp(orig, idxname) != 0)
			result = downcase_identifier(orig, strlen(orig), false, false);
		pfree(orig);
		return result;
	}

	return idxname;
}

/*
 * bbf_get_original_constraint_name_by_relid - resolve the original name of a
 * CHECK / FOREIGN KEY constraint from its OWNING relation's Oid.
 *
 * Constraint original names are stored in babelfish_identifier_mapping keyed by
 * (truncated_name, physical nspname, BBF_IDENT_CONSTRAINT, physical parent
 * relation name), where the parent is the constraint's owning relation
 * (pg_constraint.conrelid). Both error sites already have that relation's Oid
 * in hand - the check-violation site the target table, the FK-violation site
 * riinfo->fk_relid (a FK's conrelid is its referencing table) - so we derive
 * nspname/parent directly from the relation and issue a single mapping lookup,
 * with no pg_constraint scan or CONSTROID syscache access. Returns the original
 * name (downcased, palloc'd) if a mapping exists, else NULL.
 */
static const char *
bbf_get_original_constraint_name_by_relid(const char *conname, Oid relid)
{
	char	   *nspname;
	char	   *parent_name;
	char	   *orig = NULL;
	const char *result = NULL;

	if (!OidIsValid(relid))
		return NULL;

	nspname = get_namespace_name(get_rel_namespace(relid));
	parent_name = get_rel_name(relid);
	if (nspname && parent_name)
		orig = lookup_bbf_ident_mapping(conname, nspname,
										BBF_IDENT_CONSTRAINT, parent_name);
	if (nspname)
		pfree(nspname);
	if (parent_name)
		pfree(parent_name);

	if (orig)
	{
		result = downcase_identifier(orig, strlen(orig), false, false);
		pfree(orig);
	}
	return result;
}

/*
 * bbf_get_original_parameter_name - resolve the original (pre-truncation) name
 * of a procedure/function parameter for "parameter was not supplied" errors.
 *
 * Parameters are stored in babelfish_identifier_mapping under BBF_IDENT_PARAMETER
 * keyed by (truncated_name, physical schema, parent = procedure name), which is
 * a different key space than constraints. We recover the owning procedure's
 * physical namespace and name from its Oid (via the PROCOID syscache), then
 * delegate to lookup_bbf_ident_mapping(). Returns the original name (downcased,
 * palloc'd) if a mapping exists, else the input param_name unchanged.
 */
const char *
bbf_get_original_parameter_name(const char *param_name, Oid proc_oid)
{
	HeapTuple	tuple;
	Form_pg_proc proc;
	char	   *nspname;
	char	   *orig = NULL;

	if (!param_name || strlen(param_name) < BBF_ORIGINAL_NAME_LOOKUP_THRESHOLD)
		return param_name;

	if (!IsTransactionState() || !OidIsValid(proc_oid) ||
		!OidIsValid(get_bbf_ident_mapping_oid()))
		return param_name;

	tuple = SearchSysCache1(PROCOID, ObjectIdGetDatum(proc_oid));
	if (!HeapTupleIsValid(tuple))
		return param_name;

	proc = (Form_pg_proc) GETSTRUCT(tuple);
	nspname = get_namespace_name(proc->pronamespace);
	if (nspname)
	{
		orig = lookup_bbf_ident_mapping(param_name, nspname,
										BBF_IDENT_PARAMETER, NameStr(proc->proname));
		pfree(nspname);
	}
	ReleaseSysCache(tuple);

	if (orig)
	{
		const char *result = downcase_identifier(orig, strlen(orig), false, false);

		pfree(orig);
		return result;
	}

	return param_name;
}


/*
 * bbf_get_original_ident_name - registered as bbf_get_original_ident_name_hook.
 *
 * object_id is the index/constraint Oid when the caller has it (InvalidOid
 * otherwise); is_index selects the lookup:
 *   - is_index = true: unique-violation reporting a PK/UNIQUE index name.
 *     A standalone CREATE [UNIQUE] INDEX stores the true original name in the
 *     backing index's bbf_original_name reloption, so the index lookup resolves
 *     it. A UNIQUE/PRIMARY KEY *constraint*, however, stores the MD5-mangled
 *     physical name in that reloption, so when the index lookup does not rewrite
 *     the name we fall back to the constraint mapping (keyed by the constraint
 *     name in babelfish_identifier_mapping). This fallback is required for the
 *     cross-session case, where the session cache is empty and the TDS message
 *     rewrite cannot help.
 *   - is_index = false: CHECK/FK violation. object_id is the constraint's
 *     owning relation; the constraint mapping is resolved directly from it. No
 *     index relation lookup is performed. With no usable Oid, the name is
 *     returned unchanged.
 *
 * Returns the original name (palloc'd) when resolved, else ident_name unchanged.
 */
const char *
bbf_get_original_ident_name(const char *ident_name, Oid object_id, bool is_index)
{
	Oid			table_oid;			/* owning relation of the constraint */

	if (!ident_name || !IsTransactionState() ||
		!OidIsValid(get_bbf_ident_mapping_oid()))
		return ident_name;

	if (is_index)
	{
		/*
		 * Index path always runs regardless of name length: a PK/UNIQUE index's
		 * physical name is mangled (name+table+md5) and its bbf_original_name
		 * reloption is present even when the user's index name is short, so
		 * get_original_relname() can resolve short names too.
		 */
		const char *resolved = bbf_get_original_index_name(ident_name, object_id);

		if (resolved != ident_name)
			return resolved;

		/*
		 * Not resolved from the reloption: it is a PK/UNIQUE *constraint* whose
		 * backing-index reloption holds the mangled name. The constraint is
		 * owned by the index's TABLE (conrelid), so resolve the index Oid to
		 * its table for the constraint-mapping fallback below.
		 */
		table_oid = OidIsValid(object_id) ?
			IndexGetRelation(object_id, true /* missing_ok */) : InvalidOid;
	}
	else
	{
		/*
		 * CHECK / FK violation: the caller already passes the constraint's
		 * owning relation Oid (target table / fk_relid).
		 */
		table_oid = object_id;
	}

	/*
	 * Constraint-mapping fallback (shared by both paths). Constraint mappings
	 * exist only for long originals, so short names are skipped. Use
	 * BBF_ORIGINAL_NAME_LOOKUP_THRESHOLD (not NAMEDATALEN - 1) because multibyte
	 * names can truncate to fewer than NAMEDATALEN - 1 bytes. Resolves directly
	 * from the relation - no pg_constraint scan.
	 */
	if (OidIsValid(table_oid) &&
		strlen(ident_name) >= BBF_ORIGINAL_NAME_LOOKUP_THRESHOLD)
	{
		const char *resolved = bbf_get_original_constraint_name_by_relid(ident_name, table_oid);

		if (resolved)
			return resolved;
	}

	/* Nothing more we can resolve. */
	return ident_name;
}
