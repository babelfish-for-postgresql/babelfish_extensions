/*-------------------------------------------------------------------------
 *
 * stable_func_persisted.c
 * POC to support deterministic STABLE functions in Computed Columns
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/relation.h"
#include "access/table.h"
#include "catalog/pg_proc.h"
#include "nodes/makefuncs.h"
#include "nodes/nodeFuncs.h"
#include "parser/parsetree.h"
#include "rewrite/rewriteHandler.h"
#include "rewrite/rewriteManip.h"
#include "utils/builtins.h"
#include "utils/lsyscache.h"
#include "utils/rel.h"
#include "utils/syscache.h"

#include "pltsql.h"
#include "stable_func_persisted.h"

extern bool babelfish_dump_restore;

/* GUC variables */
extern bool pltsql_quoted_identifier;
extern bool pltsql_concat_null_yields_null;
extern bool pltsql_ansi_nulls;
extern bool pltsql_ansi_padding;
extern bool pltsql_ansi_warnings;
extern bool pltsql_arithabort;
extern bool pltsql_numeric_roundabort;

typedef struct {
    const char *funcname;
    const char *nspname;
} FuncEntry;

/* Whitelist: deterministic STABLE functions we allow in PERSISTED columns */
static FuncEntry whitelist[] = {
    /* String concatenation */
    {"babelfish_concat_wrapper", "sys"},
    {"babelfish_concat_wrapper_outer", "sys"},
    {"concat", "sys"},
    {"concat_ws", "sys"},

    /* Conversion functions */
    {"babelfish_conv_date_to_string", "sys"},
    {"babelfish_conv_datetime_to_string", "sys"},
    {"babelfish_conv_helper_to_varchar", "sys"},
    {"babelfish_conv_to_varchar", "sys"},
    {"babelfish_conv_time_to_string", "sys"},
    {"babelfish_conv_money_to_string", "sys"},
    {"babelfish_conv_float_to_string", "sys"},

    /* Numeric casting/rounding */
    {"babelfish_cast_floor_int", "sys"},
    {"babelfish_cast_floor_bigint", "sys"},
    {"babelfish_cast_floor_smallint", "sys"},
    {"_round_fixeddecimal_to_int2", "sys"},
    {"_round_fixeddecimal_to_int4", "sys"},
    {"_round_fixeddecimal_to_int8", "sys"},
    {"_trunc_numeric_to_int2", "sys"},
    {"_trunc_numeric_to_int4", "sys"},
    {"_trunc_numeric_to_int8", "sys"},

    /* Date functions */
    {"eomonth", "sys"},
    {"datetrunc", "sys"},

    {NULL, NULL}
};

/* Check if (funcname, nspname) is in a FuncEntry array */
static bool
name_in_list(const char *funcname, const char *nspname, FuncEntry *list)
{
    for (int i = 0; list[i].funcname != NULL; i++)
        if (pg_strcasecmp(funcname, list[i].funcname) == 0 &&
            pg_strcasecmp(nspname, list[i].nspname) == 0)
            return true;
    return false;
}

/* Check required GUCs are at default values */
bool check_persisted_gucs(void)
{
    return pltsql_quoted_identifier &&
           pltsql_arithabort &&
           pltsql_concat_null_yields_null &&
           pltsql_ansi_nulls &&
           pltsql_ansi_padding &&
           pltsql_ansi_warnings &&
           !pltsql_numeric_roundabort;
}

/* Get comma-separated list of mismatched GUCs */
char * get_mismatched_persisted_gucs(void)
{
    StringInfoData buf;
    initStringInfo(&buf);
    
    if (!pltsql_quoted_identifier)
        appendStringInfoString(&buf, "QUOTED_IDENTIFIER, ");
    if (!pltsql_arithabort)
        appendStringInfoString(&buf, "ARITHABORT, ");
    if (!pltsql_concat_null_yields_null)
        appendStringInfoString(&buf, "CONCAT_NULL_YIELDS_NULL, ");
    if (!pltsql_ansi_nulls)
        appendStringInfoString(&buf, "ANSI_NULLS, ");
    if (!pltsql_ansi_padding)
        appendStringInfoString(&buf, "ANSI_PADDING, ");
    if (!pltsql_ansi_warnings)
        appendStringInfoString(&buf, "ANSI_WARNINGS, ");
    if (pltsql_numeric_roundabort)
        appendStringInfoString(&buf, "NUMERIC_ROUNDABORT, ");
    
    return buf.data;
}

/*
 * Unsafe function walker: returns true if any function is unsafe i.e not whitelisted on not immutable
 */
static bool
has_unsafe_func_walker(Node *node, void *context)
{
    bool *found_unsafe = (bool *) context;
    
    if (node == NULL)
        return false;
    
    if (IsA(node, FuncExpr))
    {
        FuncExpr *f = (FuncExpr *) node;
        HeapTuple tup = SearchSysCache1(PROCOID, ObjectIdGetDatum(f->funcid));
        
        if (HeapTupleIsValid(tup))
        {
            Form_pg_proc proc = (Form_pg_proc) GETSTRUCT(tup);
            
            if (proc->provolatile == PROVOLATILE_IMMUTABLE)
            {
                /* IMMUTABLE is always safe */
                ReleaseSysCache(tup);
                return expression_tree_walker(node, has_unsafe_func_walker, context);
            }
            
            if (proc->provolatile == PROVOLATILE_STABLE)
            {
                const char *funcname = NameStr(proc->proname);
                char *nspname = get_namespace_name(proc->pronamespace);
                
                if (nspname && name_in_list(funcname, nspname, whitelist))
                {
                    /*
                     * Whitelisted STABLE — but check CONVERT for explicit style.
                     * CONVERT without style is non-deterministic.
                     */
                    if (pg_strcasecmp(funcname, "babelfish_conv_helper_to_varchar") == 0 ||
                        pg_strcasecmp(funcname, "babelfish_conv_date_to_string") == 0 ||
                        pg_strcasecmp(funcname, "babelfish_conv_datetime_to_string") == 0)
                    {
                        /* Check p_style_specified (5th arg, index 4) */
                        if (list_length(f->args) >= 5)
                        {
                            Node *style_specified = (Node *) list_nth(f->args, 4);
                            if (!IsA(style_specified, Const) ||
                                !DatumGetBool(((Const *) style_specified)->constvalue))
                            {
                                /* Style not specified — non-deterministic */
                                pfree(nspname);
                                *found_unsafe = true;
                                ReleaseSysCache(tup);
                                return true;
                            }
                        }
                    }

                    pfree(nspname);
                    ReleaseSysCache(tup);
                    return expression_tree_walker(node, has_unsafe_func_walker, context);
                }
                
                if (nspname) pfree(nspname);
            }
            
            /* VOLATILE or non-whitelisted STABLE — unsafe */
            *found_unsafe = true;
            ReleaseSysCache(tup);
            return true;
        }
    }
    
    return expression_tree_walker(node, has_unsafe_func_walker, context);
}

/* Hook: returns NULL to skip immutability check, expr to let PG handle */
Node * stable_persisted_hook(Node *expr)
{
    bool found_unsafe = false;
    
    if (expr == NULL)
        return NULL;
    
    if (sql_dialect != SQL_DIALECT_TSQL && !babelfish_dump_restore)
        return expr;
    
    /* Enforce GUC settings at CREATE time (skip during dump/restore) */
    if (!babelfish_dump_restore && !check_persisted_gucs())
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_OBJECT_DEFINITION),
                 errmsg("CREATE TABLE failed because the following SET options have incorrect settings: '%s'",
                        get_mismatched_persisted_gucs())));
    
    /* Check if expression only has safe functions ie Immutable or stable(whitelisted) */
    has_unsafe_func_walker(expr, &found_unsafe);
    
    if (found_unsafe)
        return expr;
    
    return NULL; 
}

/* Check if table has any persisted computed columns */
bool table_has_persisted_computed_cols(Oid relid)
{
    Relation  rel = relation_open(relid, AccessShareLock);
    TupleDesc tupdesc = RelationGetDescr(rel);
    bool      found = false;
    
    for (int i = 0; i < tupdesc->natts; i++)
    {
        Form_pg_attribute attr = TupleDescAttr(tupdesc, i);
        if (!attr->attisdropped && attr->attgenerated == ATTRIBUTE_GENERATED_STORED)
        {
            found = true;
            break;
        }
    }
    
    relation_close(rel, AccessShareLock);
    return found;
}

/* Check GUCs for INSERT/UPDATE into tables */
void guc_check_insert_update(Query *parse)
{
    RangeTblEntry *rte;

    if (parse->resultRelation == 0)
        return;

    rte = rt_fetch(parse->resultRelation, parse->rtable);

    if (rte->rtekind == RTE_RELATION &&
        table_has_persisted_computed_cols(rte->relid) &&
        !check_persisted_gucs())
    {
        char *mismatched = get_mismatched_persisted_gucs();
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_OBJECT_DEFINITION),
                 errmsg("INSERT/UPDATE failed because the following SET options have incorrect settings: '%s'", mismatched),
                 errhint("Verify that SET options are correct for use with indexed views and/or indexes on computed columns.")));
    }
}

typedef struct
{
    int   varno;
    int   varattno;
    Node *expr;
} RewriteCtx;

static Node *
query_rewrite_helper(Node *node, void *context)
{
    RewriteCtx *ctx = (RewriteCtx *) context;

    if (node == NULL)
        return NULL;

    if (IsA(node, Query))
        return (Node *) query_tree_mutator((Query *) node, query_rewrite_helper, context, QTW_DONT_COPY_QUERY);

    if (IsA(node, Var))
    {
        Var *v = (Var *) node;
        if (v->varno == ctx->varno && v->varattno == ctx->varattno)
            return copyObject(ctx->expr);
        return node;
    }

    return expression_tree_mutator(node, query_rewrite_helper, context);
}

void query_rewrite_persisted(Query *parse)
{
    ListCell *lc;
    int rindex = 0;

    foreach(lc, parse->rtable)
    {
        RangeTblEntry *rte = (RangeTblEntry *) lfirst(lc);
        Relation  rel;
        TupleDesc tupdesc;

        rindex++;

        if (rte->rtekind == RTE_SUBQUERY && rte->subquery)
            query_rewrite_persisted(rte->subquery);

        if (rte->rtekind != RTE_RELATION)
            continue;

        rel = relation_open(rte->relid, AccessShareLock);
        tupdesc = RelationGetDescr(rel);

        for (int i = 0; i < tupdesc->natts; i++)
        {
            Form_pg_attribute attr = TupleDescAttr(tupdesc, i);
            Node *expr_generated;
            RewriteCtx ctx;

            if (attr->attisdropped || attr->attgenerated != ATTRIBUTE_GENERATED_STORED)
                continue;

            expr_generated = build_column_default(rel, attr->attnum);
            if (expr_generated == NULL)
                continue;

            ctx.varno = rindex;
            ctx.varattno = attr->attnum;
            ctx.expr = expr_generated;

            query_tree_mutator(parse, query_rewrite_helper, &ctx, QTW_DONT_COPY_QUERY);
        }
        relation_close(rel, AccessShareLock);
    }

    /* Recurse into CTEs */
    foreach(lc, parse->cteList)
    {
        CommonTableExpr *cte = lfirst_node(CommonTableExpr, lc);
        if (cte->ctequery)
            query_rewrite_persisted(castNode(Query, cte->ctequery));
    }
}
