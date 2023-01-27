/*-------------------------------------------------------------------------
 *
 * tsql_analyze.c
 * 	 functions for query parse analyzing
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "catalog/namespace.h"
#include "nodes/nodes.h"
#include "nodes/parsenodes.h"
#include "nodes/pg_list.h"
#include "nodes/primnodes.h"
#include "parser/parse_clause.h"
#include "utils/lsyscache.h"
#include "utils/rel.h"
#include "utils/syscache.h"

#include "pltsql.h"
#include "tsql_analyze.h"

static RangeVar *find_matching_table(RangeVar *target, Node *tblref);

/*
 * Recursively go through all CTEs, if any of them is UPDATE/DELETE statement, we
 * need to do special handling to the target table.
 */
/*
void
pltsql_cte_update_target_table(WithClause *withClause)
{
	ListCell *lc;

	if (!withClause || !withClause->ctes)
		return;
	
	foreach(lc, withClause->ctes)
	{
		CommonTableExpr *cte = (CommonTableExpr *) lfirst(lc);
		Node *qry = cte->ctequery;
		
		if (!qry)
			continue;

		if (IsA(qry, DeleteStmt))
		{
			DeleteStmt *stmt = (DeleteStmt *) qry;

			pltsql_update_target_table(&(stmt->relation), stmt->usingClause);
			if (stmt->withClause)
				pltsql_cte_update_target_table(stmt->withClause);
		}
		else if (IsA(qry, InsertStmt))
		{
			InsertStmt *stmt = (InsertStmt *) qry;
			
			if (stmt->withClause)
				pltsql_cte_update_target_table(stmt->withClause);
		}
		else if (IsA(qry, SelectStmt))
		{
			SelectStmt *stmt = (SelectStmt *) qry;
	
			if (stmt->withClause)
				pltsql_cte_update_target_table(stmt->withClause);
		}
		else if (IsA(qry, UpdateStmt))
		{
			UpdateStmt *stmt = (UpdateStmt *) qry;

			pltsql_update_target_table(&(stmt->relation), stmt->fromClause);
			if (stmt->withClause)
				pltsql_cte_update_target_table(stmt->withClause);
		}
	}	
}
*/
/*
 * If a table alias is used when specifying the target table, we need to refer to the
 * FROM clause for table reference.
 * Example:
 * UPDATE tt SET tt.a = 1 FROM t AS tt WHERE tt.b = 2
 *
 * We also need to refer to the FROM clause for schema info.
 * Example:
 * UPDATE t SET t.a = 1 FROM sch.t WHERE t.b = 2
 */
RangeVar *
pltsql_get_target_table(RangeVar *orig_target, List *fromClause)
{
	ListCell *lc;

	if (!orig_target || !fromClause || !IsA(orig_target, RangeVar) || orig_target->alias)
		return NULL;
	
	/*
	 * For each table reference in fromClause, check if the table name or table alias
	 * name matches the target table.
	 * If yes, we'll return the table reference.
	 */
	foreach(lc, fromClause)
	{
		Node *n = lfirst(lc);
		RangeVar *rv = find_matching_table(orig_target, n);

		if (rv)
			return rv;
	}
	
	return NULL;
}

static RangeVar *
find_matching_table(RangeVar *target, Node *tblref)
{
	/* 
 	 * If the table refenrence is a JoinExpr, recursively check the 
 	 * join tree's left child and right child.
 	 */
	if (IsA(tblref, JoinExpr))
	{
		JoinExpr *je = (JoinExpr *) tblref;
		RangeVar *rv = NULL;

		rv = find_matching_table(target, (Node *) je->larg);

		if (!rv)
			rv = find_matching_table(target, (Node *) je->rarg);

		return rv;
	}
	/*
	 * If the table reference is an actual table (RangeVar), check if
	 * the table name or table alias is the same as the target table name.
	 * Return the matching table if exists.
	 */
	else if (IsA(tblref, RangeVar))
	{
		RangeVar *rv = (RangeVar *) tblref;
		if (pg_strcasecmp(target->relname, rv->relname) == 0)
		{
			if (target->schemaname && 
				(!rv->schemaname || pg_strcasecmp(target->schemaname, rv->schemaname) != 0))
			{
				ereport(ERROR,
						(errcode(ERRCODE_SYNTAX_ERROR),
						 errmsg("The objects \"%s.%s\" and \"%s\" in the FROM clause have the same exposed names. " \
								"Use correlation names to distinguish them.", 
								target->schemaname, target->relname, rv->relname)));
			}
			return rv;
		}
		else if (rv->alias && pg_strcasecmp(target->relname, rv->alias->aliasname) == 0)
		{
			if (target->schemaname)
				ereport(ERROR,
						(errcode(ERRCODE_SYNTAX_ERROR),
						 errmsg("The correlation name \'%s\' has the same exposed name as table \'%s.%s\'.", 
								rv->alias->aliasname, target->schemaname, target->relname)));
			return rv;
		}
	}
	/* 
 	 * Currently we only consider RangeVar and JoinExpr cases. In the
 	 * future, if there are concrete use cases, we'll add support for 
 	 * more table reference types
 	 */
	return NULL;
}

void
pltsql_update_query_result_relation(Query *qry, Relation target_rel, List *rtable)
{
	Oid target_relid = RelationGetRelid(target_rel);

	for (int i = 0; i < list_length(rtable); i++)
	{
		RangeTblEntry *rte = (RangeTblEntry *) list_nth(rtable, i);
		if (rte->relid == target_relid)
		{
			qry->resultRelation = i + 1;
			return;
		}
	}
}

void
handle_rowversion_target_in_update_stmt(RangeVar *target_table, UpdateStmt *stmt)
{
	Oid relid;
	Relation rel;
	TupleDesc tupdesc;
	AttrNumber attr_num;

	relid = RangeVarGetRelid(target_table, NoLock, false);
	rel = RelationIdGetRelation(relid);
	tupdesc = RelationGetDescr(rel);

	/*
	* If target table contains a rowversion column, add a new ResTarget node
	* with a SetToDefault expression into statement's targetList. This will
	* ensure that the rows which are going to be updated will have new rowversion
	* value.
	*/
	for (attr_num = 0; attr_num < tupdesc->natts; attr_num++)
	{
		Form_pg_attribute attr;

		attr = TupleDescAttr(tupdesc, attr_num);

		if (attr->attisdropped)
			continue;

		if ((*common_utility_plugin_ptr->is_tsql_rowversion_or_timestamp_datatype)(attr->atttypid))
		{
			SetToDefault *def = makeNode(SetToDefault);
			ResTarget *res;

			def->typeId = attr->atttypid;
			def->typeMod = attr->atttypmod;
			def->collation = attr->attcollation;
			res = makeNode(ResTarget);
			res->name = pstrdup(NameStr(attr->attname));
			res->name_location = -1;
			res->indirection = NIL;
			res->val = (Node *)def;
			res->location = -1;
			stmt->targetList = lappend(stmt->targetList, res);
			break;
		}
	}

	RelationClose(rel);
}
