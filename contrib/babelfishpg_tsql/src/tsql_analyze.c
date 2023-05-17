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
#include "parser/parse_coerce.h"
#include "parser/parsetree.h"
#include "utils/lsyscache.h"
#include "utils/rel.h"
#include "utils/syscache.h"

#include "pltsql.h"
#include "tsql_analyze.h"

static RangeVar *find_matching_table(RangeVar *target, Node *tblref);

List *sv_setop_exprs = NIL;
namespace_stack_t *set_op_ns_stack = NULL;

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
	ListCell   *lc;

	if (!orig_target || !fromClause || !IsA(orig_target, RangeVar) || orig_target->alias)
		return NULL;

	/*
	 * For each table reference in fromClause, check if the table name or
	 * table alias name matches the target table. If yes, we'll return the
	 * table reference.
	 */
	foreach(lc, fromClause)
	{
		Node	   *n = lfirst(lc);
		RangeVar   *rv = find_matching_table(orig_target, n);

		if (rv)
			return rv;
	}

	return NULL;
}

static RangeVar *
find_matching_table(RangeVar *target, Node *tblref)
{
	/*
	 * If the table refenrence is a JoinExpr, recursively check the join
	 * tree's left child and right child.
	 */
	if (IsA(tblref, JoinExpr))
	{
		JoinExpr   *je = (JoinExpr *) tblref;
		RangeVar   *rv = NULL;

		rv = find_matching_table(target, (Node *) je->larg);

		if (!rv)
			rv = find_matching_table(target, (Node *) je->rarg);

		return rv;
	}

	/*
	 * If the table reference is an actual table (RangeVar), check if the
	 * table name or table alias is the same as the target table name. Return
	 * the matching table if exists.
	 */
	else if (IsA(tblref, RangeVar))
	{
		RangeVar   *rv = (RangeVar *) tblref;

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
	 * Currently we only consider RangeVar and JoinExpr cases. In the future,
	 * if there are concrete use cases, we'll add support for more table
	 * reference types
	 */
	return NULL;
}

void
pltsql_update_query_result_relation(Query *qry, Relation target_rel, List *rtable)
{
	Oid			target_relid = RelationGetRelid(target_rel);

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
	Oid			relid;
	Relation	rel;
	TupleDesc	tupdesc;
	AttrNumber	attr_num;

	relid = RangeVarGetRelid(target_table, NoLock, false);
	rel = RelationIdGetRelation(relid);
	tupdesc = RelationGetDescr(rel);

	/*
	 * If target table contains a rowversion column, add a new ResTarget node
	 * with a SetToDefault expression into statement's targetList. This will
	 * ensure that the rows which are going to be updated will have new
	 * rowversion value.
	 */
	for (attr_num = 0; attr_num < tupdesc->natts; attr_num++)
	{
		Form_pg_attribute attr;

		attr = TupleDescAttr(tupdesc, attr_num);

		if (attr->attisdropped)
			continue;

		if ((*common_utility_plugin_ptr->is_tsql_rowversion_or_timestamp_datatype) (attr->atttypid))
		{
			SetToDefault *def = makeNode(SetToDefault);
			ResTarget  *res;

			def->typeId = attr->atttypid;
			def->typeMod = attr->atttypmod;
			def->collation = attr->attcollation;
			res = makeNode(ResTarget);
			res->name = pstrdup(NameStr(attr->attname));
			res->name_location = -1;
			res->indirection = NIL;
			res->val = (Node *) def;
			res->location = -1;
			stmt->targetList = lappend(stmt->targetList, res);
			break;
		}
	}

	RelationClose(rel);
}

static bool
search_join_recursive(Node *expr, RangeVar *target, bool outside_outer)
{
	JoinExpr   *join_expr;
	RangeVar   *arg;

	if (!expr)
		return false;
	else if (IsA(expr, RangeVar))
		/* Base condition */
	{
		arg = (RangeVar *) expr;
		return outside_outer && strcmp(arg->relname, target->relname) == 0;
	}
	else if (!IsA(expr, JoinExpr))
		return false;
	join_expr = (JoinExpr *) expr;

	/*
	 * Check if 'target' is on the 'outside' of a join, i.e. right on a left
	 * join or left on a right join
	 */
	switch (join_expr->jointype)
	{
		case JOIN_INNER:
			return search_join_recursive(join_expr->larg, target, outside_outer)
				|| search_join_recursive(join_expr->rarg, target, outside_outer);
		case JOIN_LEFT:
			return search_join_recursive(join_expr->larg, target, outside_outer)
				|| search_join_recursive(join_expr->rarg, target, true);
		case JOIN_RIGHT:
			return search_join_recursive(join_expr->larg, target, true)
				|| search_join_recursive(join_expr->rarg, target, outside_outer);
		case JOIN_FULL:
			return search_join_recursive(join_expr->larg, target, true)
				|| search_join_recursive(join_expr->rarg, target, true);
		default:
			return false;
	}
}

static bool
target_in_outer_join(List *fromClause, RangeVar *target)
{
	bool result = false;
	ListCell   *lc;

	foreach(lc, fromClause)
	{
		Node	   *node = lfirst(lc);
		result	  |=search_join_recursive(node, target, false);
	}

	return result;
}

static void
add_target_ctid_not_null_clause(Node **where_clause, RangeVar *target)
{
	NullTest   *new_clause;
	ColumnRef  *col_ref;
	char	   *rel_name = target->relname;

	new_clause = makeNode(NullTest);
	new_clause->nulltesttype = IS_NOT_NULL;
	new_clause->argisrow = false;
	new_clause->location = -1;

	if (target->alias && target->alias->aliasname)
		rel_name = target->alias->aliasname;
	col_ref = makeNode(ColumnRef);
	col_ref->location = -1;
	col_ref->fields = list_make2(makeString(rel_name), makeString("ctid"));
	new_clause->arg = (Expr *) col_ref;

	if (!*where_clause)
		*where_clause = (Node *) new_clause;
	else
	{
		BoolExpr   *bool_expr = makeNode(BoolExpr);;
		bool_expr->boolop = AND_EXPR;
		bool_expr->location = -1;
		bool_expr->args = list_make2(*where_clause, new_clause);
		*where_clause = (Node *) bool_expr;
	}

}

void
rewrite_update_outer_join(Node *stmt, CmdType command, RangeVar *target)
{
	switch (command)
	{
		case CMD_UPDATE:
			{
				UpdateStmt *update_stmt = (UpdateStmt *) stmt;
				List	   *fromClause = update_stmt->fromClause;

				if (fromClause && target_in_outer_join(fromClause, target))
					add_target_ctid_not_null_clause(&update_stmt->whereClause, target);
				break;
			}
		case CMD_DELETE:
			{
				DeleteStmt *delete_stmt = (DeleteStmt *) stmt;
				List	   *fromClause = delete_stmt->usingClause;

				if (fromClause && target_in_outer_join(fromClause, target))
					add_target_ctid_not_null_clause(&delete_stmt->whereClause, target);
				break;
			}
		default:
			return;
	}
}

/* 
 * Allocate an empty space to hold a parsing namespace
 * This space will be filled by post_transform_from_clause, to save the
 * leftmost select's namespace for processing UNION statements. This is needed 
 * to resolve table aliases in the top-level of a UNION and other set ops.
 */
void
push_namespace_stack(void)
{
	namespace_stack_t *ns_stack_item;

	if (sql_dialect != SQL_DIALECT_TSQL)
		return;

	ns_stack_item = palloc(sizeof(namespace_stack_t));
	ns_stack_item->prev = set_op_ns_stack;
	ns_stack_item->namespace = NIL;
	set_op_ns_stack = ns_stack_item;
}

/* 
 * After tranforming a from clause, if we've allocated space on the stack in
 * push_namespace_stack, save the namespace here for use in
 * pre_transform_sort_clause.
 */
void 
post_transform_from_clause(ParseState *pstate)
{
	namespace_stack_t *ns = set_op_ns_stack;
	if (sql_dialect == SQL_DIALECT_TSQL && ns && ns->namespace == NIL)
		ns->namespace = pstate->p_namespace;
}

static void
fix_setop_typmods(ParseState *pstate, Query *qry)
{
	List 		*setOpTreeStack = list_make1(qry->setOperations);
	List 		*tlist_list = NIL;
	List		*colTypes = ((SetOperationStmt*) qry->setOperations)->colTypes;
	ListCell	*tlistl;
	int32		*max_typmods;
	int			colindex;

	while (setOpTreeStack)
	{
		Node *setOp = llast(setOpTreeStack);
		setOpTreeStack = list_delete_last(setOpTreeStack);

		if (IsA(setOp, SetOperationStmt))
		{
			SetOperationStmt *op = (SetOperationStmt *) setOp;
			// TODO Do we need the same check as in prepunion::903?
			setOpTreeStack = lcons(op->rarg, setOpTreeStack);
			setOpTreeStack = lcons(op->larg, setOpTreeStack);
		} else if (IsA(setOp, RangeTblRef))
		{
			RangeTblEntry *rte = rt_fetch(((RangeTblRef*)setOp)->rtindex, pstate->p_rtable);
			tlist_list = lcons(rte->subquery->targetList, tlist_list);
		}
	}

	// Call select common type
	// Call select common typmod

	// Coerce all

	max_typmods = (int32 *) palloc(list_length((List *) linitial(tlist_list)) * sizeof(int32));
	
	foreach(tlistl, tlist_list)
	{
		List		*subtlist = (List *) lfirst(tlistl);
		ListCell	*subtlistl;
		colindex = 0;
		foreach(subtlistl, subtlist)
		{
			TargetEntry *subtle = (TargetEntry *) lfirst(subtlistl);
			Node		*expr = (Node*) subtle->expr;

			if (tlistl == list_head(tlist_list))
				max_typmods[colindex] = exprTypmod(expr);
			else
				max_typmods[colindex] = Max(max_typmods[colindex], exprTypmod(expr));

			colindex++;
		}
	}
	foreach(tlistl, tlist_list)
	{
		List		*subtlist = (List *) lfirst(tlistl);
		ListCell	*subtlistl, *coltypl, *qryTlistl;
		colindex = 0;
		forthree(subtlistl, subtlist, coltypl, colTypes, qryTlistl, qry->targetList)
		{
			TargetEntry *subtle = (TargetEntry *) lfirst(subtlistl);
			TargetEntry *subqrytle = (TargetEntry *) lfirst(qryTlistl);
			Node		*expr = (Node*) subtle->expr;
			Oid			expr_typ = exprType(expr);
			Oid			col_typ = lfirst_oid(coltypl);
			if (common_utility_plugin_ptr->is_tsql_bpchar_datatype(expr_typ) || 
				common_utility_plugin_ptr->is_tsql_nchar_datatype(expr_typ)  || 
				common_utility_plugin_ptr->is_tsql_binary_datatype(expr_typ))
			{
				subtle->expr = (Expr *) coerce_to_target_type(pstate, expr, expr_typ, 
									col_typ, max_typmods[colindex], COERCION_IMPLICIT, 
									COERCE_IMPLICIT_CAST, -1);
				subqrytle->expr = (Expr *) coerce_to_target_type(pstate, (Node*) subqrytle->expr, expr_typ, 
									col_typ, max_typmods[colindex], COERCION_IMPLICIT, 
									COERCE_IMPLICIT_CAST, -1);
				subqrytle->expr = subqrytle->expr;
			}
			colindex++;
		}
	}
	// Need to put this in a finally block?
	pfree(max_typmods);
	list_free(tlist_list);
}

/* 
 * Prior to handling a UNION or othe SetOp's ORDER BY clause, this hook:
 * 1. Modifies the query's top-level target list, so that we can match columns
 * 		with those in the sort clause
 * 2. Pop from the namespace stack and restore the leftmost select's namespace
 * 		for table alias resolution. The caller is expected to save and restore
 * 		the original top-level parse state
 */
void
pre_transform_sort_clause(ParseState *pstate, Query *qry, Query *leftmostQuery)
{
	/* Pop from namespace stack and set the current namespace prior to sort */
	namespace_stack_t *old_ns_stack_item = set_op_ns_stack;
	ListCell *lc, *lc_l;
	if (sql_dialect != SQL_DIALECT_TSQL)
		return;

	/* Fix target typmods for fixed-len tsql types */
	fix_setop_typmods(pstate, qry);

	sv_setop_exprs = NIL;
	forboth(lc, qry->targetList, lc_l, leftmostQuery->targetList)
	{
		TargetEntry *tle = (TargetEntry *) lfirst(lc);
		TargetEntry *lefttle = (TargetEntry *) lfirst(lc_l);

		Assert(!lefttle->resjunk);
		sv_setop_exprs = lappend(sv_setop_exprs, tle->expr);
		if (IsA(lefttle->expr, Var))
			tle->expr = (Expr*) lefttle->expr;
	}

	pstate->p_namespace = set_op_ns_stack->namespace;

	set_op_ns_stack = set_op_ns_stack->prev;
	pfree(old_ns_stack_item);
}

/* 
 * Reset the targetList back to it's original vars
 * This is necessary in some cases, like UNION ALL and when the targetlist
 * includes items from a joined table
 */
void 
post_transform_sort_clause(Query *qry)
{
	ListCell *lc_q, *lc_sv;
	if (sql_dialect != SQL_DIALECT_TSQL || sv_setop_exprs == NIL)
		return;
	forboth(lc_q, qry->targetList, lc_sv, sv_setop_exprs)
	{
		TargetEntry *tle_q = (TargetEntry *) lfirst(lc_q);
		Expr 		*expr_sv = (Expr *) lfirst(lc_sv);
		tle_q->expr = expr_sv;
	}
	sv_setop_exprs = NIL;
}
