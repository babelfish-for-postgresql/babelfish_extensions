#include "postgres.h"

#include "collation.h"
#include "fmgr.h"
#include "guc.h"
#include "utils/hsearch.h"
#include "utils/lsyscache.h"
#include "utils/syscache.h"
#include "utils/memutils.h"
#include "utils/builtins.h"
#include "catalog/pg_type.h"
#include "catalog/pg_collation.h"
#include "catalog/namespace.h"
#include "tsearch/ts_locale.h"
#include "parser/parser.h"
#include "parser/parse_type.h"
#include "parser/parse_oper.h"
#include "nodes/makefuncs.h"

#include "pltsql.h"
#include "src/collation.h"

#define NOT_FOUND -1
#define SORT_KEY_STR "\357\277\277\0"

Oid server_collation_oid = InvalidOid;
collation_callbacks *collation_callbacks_ptr = NULL;
extern bool babelfish_dump_restore;

static Node * pgtsql_expression_tree_mutator(Node *node, void* context);
static void init_and_check_collation_callbacks(void);

extern int pattern_fixed_prefix_wrapper(Const *patt,
										int ptype,
										Oid collation,
										Const **prefix,
										Selectivity *rest_selec);

/* pattern prefix status for pattern_fixed_prefix_wrapper
 * Pattern_Prefix_None: no prefix found, this means the first character is a wildcard character
 * Pattern_Prefix_Exact: the pattern doesn't include any wildcard character
 * Pattern_Prefix_Partial: the pattern has a constant prefix
 */ 
typedef enum
{
	Pattern_Prefix_None, Pattern_Prefix_Partial, Pattern_Prefix_Exact
} Pattern_Prefix_Status;

PG_FUNCTION_INFO_V1(init_collid_trans_tab);
PG_FUNCTION_INFO_V1(init_like_ilike_table);
PG_FUNCTION_INFO_V1(get_server_collation_oid); 
PG_FUNCTION_INFO_V1(is_collated_ci_as_internal);
 
/* this function is no longer needed and is only a placeholder for upgrade script */
PG_FUNCTION_INFO_V1(init_server_collation);
Datum init_server_collation(PG_FUNCTION_ARGS) 
{
	PG_RETURN_INT32(0);
}
/* this function is no longer needed and is only a placeholder for upgrade script */
PG_FUNCTION_INFO_V1(init_server_collation_oid);
Datum init_server_collation_oid(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(0);
}

/* init_collid_trans_tab - this function is no longer needed and is only a placeholder for upgrade script */
Datum
init_collid_trans_tab(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(0);
}

PG_FUNCTION_INFO_V1(collation_list);

Datum
collation_list(PG_FUNCTION_ARGS)
{
	PG_RETURN_DATUM(tsql_collation_list_internal(fcinfo));
}

Datum
get_server_collation_oid(PG_FUNCTION_ARGS)
{
	PG_RETURN_OID(tsql_get_server_collation_oid_internal(false));
}

Datum is_collated_ci_as_internal(PG_FUNCTION_ARGS)
{
	PG_RETURN_DATUM(tsql_is_collated_ci_as_internal(fcinfo));
}

/* init_like_ilike_table - this function is no longer needed and is only a placeholder for upgrade script */
Datum
init_like_ilike_table(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(0);
}

static Expr *
make_op_with_func(Oid opno, Oid opresulttype, bool opretset,
				  Expr *leftop, Expr *rightop,
				  Oid opcollid, Oid inputcollid, Oid oprfuncid)
{
	OpExpr  *expr = (OpExpr*)make_opclause(opno,
										   opresulttype,
										   opretset,
										   leftop,
										   rightop,
										   opcollid,
										   inputcollid);

	expr->opfuncid = oprfuncid;
	return (Expr *) expr;
}

/* helper fo make or qual, simialr to make_and_qual  */
static Node *
make_or_qual(Node *qual1, Node *qual2)
{
	if (qual1 == NULL)
		return qual2;
	if (qual2 == NULL)
		return qual1;
	return (Node *) make_orclause(list_make2(qual1, qual2));
}

static Node*
transform_funcexpr(Node* node)
{
	if (node && IsA(node, FuncExpr))
	{
		FuncExpr *fe = (FuncExpr *) node;
		int	   collidx_of_cs_as;

		if (fe->funcid == 868  ||  // strpos - see pg_proc.dat
			// fe->funcid == 394  ||  // string_to_array, 3-arg form
			// fe->funcid == 376  ||  // string_to_array, 2-arg form
			fe->funcid == 2073 ||  // substring - 2-arg form, see pg_proc.dat
			fe->funcid == 2074 ||  // substring - 3-arg form, see pg_proc.dat

			fe->funcid == 2285 ||  // regexp_replace, flags in 4th arg
			fe->funcid == 3397 ||  // regexp_match (find first match), flags in 3rd arg
			fe->funcid == 2764)	// regexp_matches, flags in 4th arg
		{
			coll_info_t coll_info_of_inputcollid = tsql_lookup_collation_table_internal(fe->inputcollid);
			Node*	   leftop = (Node *) linitial(fe->args);
			Node*	   rightop = (Node *) lsecond(fe->args);

			if (OidIsValid(coll_info_of_inputcollid.oid) &&
				coll_info_of_inputcollid.collateflags == 0x000d /* CI_AS  */ )
			{
				Oid lower_funcid = 870; // lower
				Oid result_type = 25;   // text

				tsql_get_server_collation_oid_internal(true);

				if (!OidIsValid(server_collation_oid))
					return node;

				/* Find the CS_AS collation corresponding to the CI_AS collation
				 * Change the collation of the func op to the CS_AS collation 
				 */
				collidx_of_cs_as =
					tsql_find_cs_as_collation_internal(
						tsql_find_collation_internal(coll_info_of_inputcollid.collname));

				if (NOT_FOUND == collidx_of_cs_as)
					return node;

				if (fe->funcid == 2285 || fe->funcid == 3397 || fe->funcid == 2764)
				{
					Node* flags = (fe->funcid == 3397) ? lthird(fe->args) : lfourth(fe->args);

					if (!IsA(flags, Const))
						return node;
					else
					{
						char *patt = TextDatumGetCString(((Const *)flags)->constvalue);
						int f = 0;

						while (patt[f] != '\0')
						{
							if (patt[f] == 'i')
								break;

							f++;
						}

						/* If the 'i' flag was specified then the operation is case-insensitive
						 * and so the ci_as collation may be replaced with the corresponding
						 * deterministic cs_as collation. If not, return.
						 */
						if (patt[f] != 'i')
							return node;
					}
				}

				fe->inputcollid = tsql_get_oid_from_collidx(collidx_of_cs_as);

				if (fe->funcid >= 2285)
					return node;  // regexp operators have their own way to handle case-insensitivity

				if (!IsA(leftop, FuncExpr) || ((FuncExpr *)leftop)->funcid != lower_funcid)
					leftop = (Node *) makeFuncExpr(lower_funcid,
												   result_type,
												   list_make1(leftop),
												   fe->inputcollid,
												   fe->inputcollid,
												   COERCE_EXPLICIT_CALL);
				if (!IsA(rightop, FuncExpr) || ((FuncExpr *)rightop)->funcid != lower_funcid)
					rightop = (Node *) makeFuncExpr(lower_funcid,
													result_type,
													list_make1(rightop),
													fe->inputcollid,
													fe->inputcollid,
													COERCE_EXPLICIT_CALL);

				if (list_length(fe->args) == 3)
				{
					Node* thirdop = (Node *) makeFuncExpr(lower_funcid,
														  result_type,
														  list_make1(lthird(fe->args)),
														  fe->inputcollid,
														  fe->inputcollid,
														  COERCE_EXPLICIT_CALL);

					fe->args = list_make3(leftop, rightop, thirdop);
				}
				else if (list_length(fe->args) == 2)
				{
					fe->args = list_make2(leftop, rightop);
				}
			}
		}
	}

	return node;
}

/*
 * If the node is OpExpr and the colaltion is ci_as, then
 * transform the LIKE OpExpr to ILIKE OpExpr:
 *
 * Case 1: if the pattern is a constant stirng
 *		 col LIKE PATTERN -> col = PATTERN
 * Case 2: if the pattern have a constant prefix
 *		 col LIKE PATTERN -> 
 *		 col LIKE PATTERN BETWEEN prefix AND prefix||E'\uFFFF'
 * Case 3: if the pattern doesn't have a constant prefix
 *		 col LIKE PATTERN -> col ILIKE PATTERN
 */
static Node*
transform_likenode(Node* node)
{
	ereport(LOG, (errmsg("Inside transform_likenode()")));
	if (node && IsA(node, OpExpr))
	{
		OpExpr	 *op = (OpExpr *) node;
		like_ilike_info_t like_entry = tsql_lookup_like_ilike_table_internal(op->opno);
		coll_info_t coll_info_of_inputcollid = tsql_lookup_collation_table_internal(op->inputcollid);
		/*
		 * We do not allow CREATE TABLE statements with CHECK constraint where the
		 * constraint has an ILIKE operator and the collation is ci_as. But during
		 * dump and restore, this kind of a table definition may be generated. At
		 * this point we know that any tables being restored that match this pattern
		 * are generated by pg_dump, and not created by a user. So, it is safe to go
		 * ahead with replacing the ci_as collation with a corresponding cs_as one
		 * if an ILIKE node is found during dump and restore. 
		 */
		init_and_check_collation_callbacks();
		if ((*collation_callbacks_ptr->has_valid_collation)(node, false)
				 && babelfish_dump_restore)
		{
			int		 collidx_of_cs_as;
			
			if (coll_info_of_inputcollid.collname)
			{
				collidx_of_cs_as =
					tsql_find_cs_as_collation_internal(
						tsql_find_collation_internal(coll_info_of_inputcollid.collname));
				if (NOT_FOUND == collidx_of_cs_as)
				{
					op->inputcollid = DEFAULT_COLLATION_OID;
					return node;
				}
				op->inputcollid = tsql_get_oid_from_collidx(collidx_of_cs_as);
			}
			else
			{
				/* If a collation is not specified, use the default one */
				op->inputcollid = DEFAULT_COLLATION_OID;
			}
		}

		/* check if this is LIKE expr, and collation is CI_AS */
		if (OidIsValid(like_entry.like_oid) &&
			OidIsValid(coll_info_of_inputcollid.oid) &&
			coll_info_of_inputcollid.collateflags == 0x000d /* CI_AS  */ )
		{
			Node*	   leftop = (Node *) linitial(op->args);
			Node*	   rightop = (Node *) lsecond(op->args);
			Oid		 ltypeId = exprType(leftop);
			Oid		 rtypeId = exprType(rightop);
			char*	   op_str;
			Node*	   ret;
			Const*	  patt;
			Const*	  prefix;
			Operator	optup;
			Pattern_Prefix_Status pstatus;
			int		 collidx_of_cs_as;

			tsql_get_server_collation_oid_internal(true);

			if (!OidIsValid(server_collation_oid))
				return node;

			/* Find the CS_AS collation corresponding to the CI_AS collation
			 * Change the collation of the ILIKE op to the CS_AS collation 
			 */
			collidx_of_cs_as =
				tsql_find_cs_as_collation_internal(
					tsql_find_collation_internal(coll_info_of_inputcollid.collname));
			

			/* A CS_AS collation should always exist unless a Babelfish
			 * CS_AS collation was dropped or the lookup tables were not
			 * defined in lexicographic order.  Program defensively here
			 * and just do no transformation in this case, which will
			 * generate a 'nondeterministic collation not supported' error.
			 */
			if (NOT_FOUND == collidx_of_cs_as)
				return node;
			/* Change the opno and oprfuncid to ILIKE */
			op->opno = like_entry.ilike_oid;
			op->opfuncid = like_entry.ilike_opfuncid;

			op->inputcollid = tsql_get_oid_from_collidx(collidx_of_cs_as);

			/* no constant prefix found in pattern, or pattern is not constant */
			if (IsA(leftop, Const) || !IsA(rightop, Const) ||
				((Const *) rightop)->constisnull)
			{
				return node;
			}

			patt = (Const *) rightop;

			/* extract pattern */
			pstatus = pattern_fixed_prefix_wrapper(patt, 1, server_collation_oid,
												   &prefix, NULL);

			/* If there is no constant prefix then there's nothing more to do */
			if (pstatus == Pattern_Prefix_None)
			{
				return node;
			}

			/*
			 * If we found an exact-match pattern, generate an "=" indexqual.
			 */
			if (pstatus == Pattern_Prefix_Exact)
			{
				op_str = like_entry.is_not_match ? "<>" : "=";
				optup = compatible_oper(NULL, list_make1(makeString(op_str)), ltypeId, ltypeId,
										true, -1);
				if (optup == (Operator) NULL)
					return node;

				ret = (Node*)(make_op_with_func(oprid(optup), BOOLOID, false,
												(Expr *) leftop, (Expr *) prefix,
												InvalidOid, server_collation_oid ,oprfuncid(optup)));

				ReleaseSysCache(optup);
				return ret;
			}
			else
			{
				Expr *greater_equal, *less_equal, *concat_expr;
				Node* constant_suffix;
				Const* highest_sort_key;
				/* construct leftop >= pattern */
				optup = compatible_oper(NULL, list_make1(makeString(">=")), ltypeId, ltypeId,
										true, -1);
				if (optup == (Operator) NULL)
					return node;
				greater_equal = make_op_with_func(oprid(optup), BOOLOID, false,
												  (Expr *) leftop, (Expr *) prefix,
												  InvalidOid, server_collation_oid ,oprfuncid(optup));
				ReleaseSysCache(optup);
				/* construct pattern||E'\uFFFF' */
				highest_sort_key = makeConst(TEXTOID,-1, server_collation_oid, -1,
											 PointerGetDatum(cstring_to_text(SORT_KEY_STR)), false, false);

				optup = compatible_oper(NULL, list_make1(makeString("||")), rtypeId, rtypeId,
										true, -1);
				if (optup == (Operator) NULL)
					return node;
				concat_expr = make_op_with_func(oprid(optup), rtypeId, false,
												(Expr *) prefix, (Expr *) highest_sort_key,
												InvalidOid, server_collation_oid, oprfuncid(optup));
				ReleaseSysCache(optup);
				/* construct leftop < pattern */
				optup = compatible_oper(NULL, list_make1(makeString("<")), ltypeId, ltypeId,
										true, -1);
				if (optup == (Operator) NULL)
					return node;

				less_equal = make_op_with_func(oprid(optup), BOOLOID, false,
											   (Expr *) leftop, (Expr *) concat_expr,
											   InvalidOid, server_collation_oid, oprfuncid(optup));
				constant_suffix = make_and_qual((Node*)greater_equal, (Node*)less_equal);
				if(like_entry.is_not_match)
				{
					constant_suffix = (Node*)make_notclause((Expr*)constant_suffix);
					ret = make_or_qual(node, constant_suffix);
				}
				else
				{
					constant_suffix = make_and_qual((Node*)greater_equal, (Node*)less_equal);
					ret = make_and_qual(node, constant_suffix);
				}
				ReleaseSysCache(optup);
				return ret;
			}
		}
	}
	return node;
}

Node* pltsql_predicate_transformer(Node *expr)
{
	if(expr == NULL)
		return expr;

	if(IsA(expr, OpExpr))
	{
		/* Singleton predicate */
		return transform_likenode(expr);
	}
	else
	{
		/* Nonsingleton predicate, which could either a BoolExpr
		 * with a list of predicates or a simple List of
		 * predicates.
		 */
		BoolExpr   *boolexpr = (BoolExpr *) expr;
		ListCell   *lc;
		List	   *new_predicates = NIL;
		List	   *predicates;

		if (IsA(expr, List))
		{
			predicates = (List *) expr;
		}
		else if (IsA(expr, BoolExpr))
		{
			if (boolexpr->boolop != AND_EXPR &&
				boolexpr->boolop != OR_EXPR)
				return expression_tree_mutator(
						expr,
						pgtsql_expression_tree_mutator,
						NULL);

			predicates = boolexpr->args;
		}
		else if (IsA(expr, FuncExpr))
		{
			/*
			 * This is performed even in the postgres dialect to handle babelfish CI_AS
			 * collations so that regexp operators can work inside plpgsql functions
			 */
			expr = expression_tree_mutator(expr, pgtsql_expression_tree_mutator, NULL);
			return transform_funcexpr(expr);
		}
		else
			return expr;

		/* Process each predicate, and recursively process
		* any nested predicate clauses of a toplevel predicate
		*/
		foreach(lc, predicates)
		{
			Node *qual = (Node *) lfirst(lc);
			if (is_andclause(qual) || is_orclause(qual))
			{
				new_predicates = lappend(new_predicates,
									pltsql_predicate_transformer(qual));
			}
			else if (IsA(qual, OpExpr))
			{
				new_predicates = lappend(new_predicates,
									transform_likenode(qual));
			}
			else
				new_predicates = lappend(new_predicates, qual);
		}

		if (IsA(expr, BoolExpr))
		{
			boolexpr->args = new_predicates;
			return expr;
		}
		else
		{
			return (Node *) new_predicates;
		}
	}
}

static Node *
pgtsql_expression_tree_mutator(Node *node, void* context)
{
	if (NULL == node)
		return node;
	if(IsA(node, CaseExpr))
	{
		CaseExpr *caseexpr = (CaseExpr *) node;
		if (caseexpr->arg != NULL)  // CASE expression WHEN ...
		{
			pltsql_predicate_transformer((Node*)caseexpr->arg);
		}
	}
	else if (IsA(node, CaseWhen)) //CASE WHEN expr
	{
		CaseWhen *casewhen = (CaseWhen *) node;
		pltsql_predicate_transformer((Node*)casewhen->expr);
	}

	/* Recurse through the operands of node */
	node = expression_tree_mutator(node, pgtsql_expression_tree_mutator, NULL);

	if (IsA(node, FuncExpr))
	{
		/*
		 * This is performed even in the postgres dialect to handle babelfish CI_AS
		 * collations so that regexp operators can work inside plpgsql functions
		 */
		node = transform_funcexpr(node);
	}
	else if (IsA(node, OpExpr))
	{
		/* 
		 * Possibly a singleton LIKE predicate:  SELECT 'abc' LIKE 'ABC'; 
		 * This is done even in the postgres dialect.
		 */
		node = transform_likenode(node);
	}

	return node;
}

Node* pltsql_planner_node_transformer(PlannerInfo *root,
									  Node *expr,
									  int kind)
{
	/*
	* Fall out quickly if expression is empty.
	*/
	if (expr == NULL)
		return NULL;

	if (EXPRKIND_TARGET == kind)
	{
		/* If expr is NOT a Boolean expression then recurse through
		* its expresion tree
		*/
		return expression_tree_mutator(
			expr,
			pgtsql_expression_tree_mutator,
			NULL);
	}
	return pltsql_predicate_transformer(expr);
}

static void
init_and_check_collation_callbacks(void)
{
	if (!collation_callbacks_ptr)
	{
		collation_callbacks **callbacks_ptr;
		callbacks_ptr = (collation_callbacks **) find_rendezvous_variable("collation_callbacks"); 
		collation_callbacks_ptr = *callbacks_ptr;

		/* collation_callbacks_ptr is still not initialised */
		if (!collation_callbacks_ptr)
			ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("collation callbacks pointer is not initialised properly.")));
	}
}

Oid
tsql_get_server_collation_oid_internal(bool missingOk)
{
	if (OidIsValid(server_collation_oid))
		return server_collation_oid;

	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	server_collation_oid = (*collation_callbacks_ptr->get_server_collation_oid_internal)(missingOk);
	return server_collation_oid;
}

Datum
tsql_collation_list_internal(PG_FUNCTION_ARGS)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->collation_list_internal)(fcinfo);
}

Datum
tsql_is_collated_ci_as_internal(PG_FUNCTION_ARGS)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->is_collated_ci_as_internal)(fcinfo);
}

bytea*
tsql_tdscollationproperty_helper(const char *collationaname, const char *property)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->tdscollationproperty_helper)(collationaname, property);
}

int
tsql_collationproperty_helper(const char *collationaname, const char *property)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->collationproperty_helper)(collationaname, property);
}

bool
tsql_is_server_collation_CI_AS(void)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->is_server_collation_CI_AS)();
}

bool
tsql_is_valid_server_collation_name(const char *collationname)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->is_valid_server_collation_name)(collationname);
}

int
tsql_find_locale(const char *locale)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->find_locale)(locale);
}

Oid
tsql_get_oid_from_collidx(int collidx)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->get_oid_from_collidx_internal)(collidx);
}

coll_info_t
tsql_lookup_collation_table_internal(Oid oid)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->lookup_collation_table_callback)(oid);
}

like_ilike_info_t 
tsql_lookup_like_ilike_table_internal(Oid opno)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->lookup_like_ilike_table)(opno);
}

int
tsql_find_cs_as_collation_internal(int collidx)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->find_cs_as_collation_internal)(collidx);
}

int
tsql_find_collation_internal(const char *collation_name)
{
	/* Initialise collation callbacks */
	init_and_check_collation_callbacks();

	return (*collation_callbacks_ptr->find_collation_internal)(collation_name);
}

bool
has_valid_coll_wrapper(Node *expr)
{
	List 		*queue;
	ListCell 	*lc = NULL;
	
	if(expr == NULL)
		return false;
	
	queue = list_make1(expr);

	while(list_length(queue) > 0)
	{
		Node *predicate = (Node *) linitial(queue);
		queue = list_delete_first(queue);
		
		if(IsA(predicate, OpExpr))
		{
			/* Initialize collation callbacks */
			init_and_check_collation_callbacks();
			if ((*collation_callbacks_ptr->has_valid_collation)(predicate, true))
				return true;				
		}
		else if (IsA(predicate, BoolExpr))
		{
			BoolExpr   *boolexpr = (BoolExpr *) predicate;			
			queue = list_concat(queue, boolexpr->args);
		}
	}
	return false;
}