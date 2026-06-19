/*-------------------------------------------------------------------------
 *
 * stable_func_persisted.c
 * Support deterministic STABLE functions in PERSISTED computed columns.
 *
 * Enables whitelisted STABLE functions to be used in PERSISTED generated
 * columns by bypassing PG's IMMUTABLE-only restriction. Enforces GUC
 * settings at DDL and DML time, and re-evaluates the expression at SELECT
 * time when session GUCs differ from defaults.
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "access/relation.h"
#include "access/table.h"
#include "catalog/heap.h"
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
extern persisted_col_hook_type prev_persisted_col_hook;

/* GUC variables */
extern bool pltsql_quoted_identifier;
extern bool pltsql_concat_null_yields_null;
extern bool pltsql_ansi_nulls;
extern bool pltsql_ansi_padding;
extern bool pltsql_ansi_warnings;
extern bool pltsql_arithabort;
extern bool pltsql_numeric_roundabort;

/* Whitelist: deterministic STABLE functions allowed in PERSISTED columns */
static FuncEntry whitelist[] = {
    /* String concatenation */
    {"babelfish_concat_wrapper",       "sys", -1},
    {"babelfish_concat_wrapper_outer", "sys", -1},
    {"concat",                         "sys", -1},
    {"concat_ws",                      "sys", -1},

    /* Conversion functions — safe only when style_specified arg is true */
    {"babelfish_conv_helper_to_varchar", "sys", 4},

    /* Numeric casting/rounding */
    {"babelfish_cast_floor_int",       "sys", -1},
    {"babelfish_cast_floor_bigint",    "sys", -1},
    {"babelfish_cast_floor_smallint",  "sys", -1},
    {"_round_fixeddecimal_to_int2",    "sys", -1},
    {"_round_fixeddecimal_to_int4",    "sys", -1},
    {"_round_fixeddecimal_to_int8",    "sys", -1},
    {"_trunc_numeric_to_int2",         "sys", -1},
    {"_trunc_numeric_to_int4",         "sys", -1},
    {"_trunc_numeric_to_int8",         "sys", -1},

    /* Date functions */
    {"eomonth",                        "sys", -1},
    {"datetrunc",                      "sys", -1},

    {NULL, NULL, -1}
};

/* Find matching entry in whitelist, or return NULL */
static FuncEntry *
find_in_whitelist(const char *funcname, const char *nspname)
{
    for (int i = 0; whitelist[i].funcname != NULL; i++)
        if (pg_strcasecmp(funcname, whitelist[i].funcname) == 0 &&
            pg_strcasecmp(nspname, whitelist[i].nspname) == 0)
            return &whitelist[i];
    return NULL;
}

/*
 * Validate a whitelisted function's arguments.
 * If style_arg_pos >= 0, the argument at that position must be a boolean
 * with value true (meaning an explicit style was specified).
 */
static bool
validate_whitelist_entry(FuncEntry *entry, FuncExpr *f)
{
    Node  *arg;
    Const *c;

    if (entry->style_arg_pos < 0)
        return true;

    if (list_length(f->args) <= entry->style_arg_pos)
        return false;

    arg = (Node *) list_nth(f->args, entry->style_arg_pos);
    if (!IsA(arg, Const))
        return false;

    c = (Const *) arg;
    return !c->constisnull && DatumGetBool(c->constvalue);
}

/* Check required GUCs are at default values */
bool 
check_persisted_gucs(void)
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
char * 
get_mismatched_persisted_gucs(void)
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
    
    if (buf.len >= 2)
        buf.data[buf.len - 2] = '\0';
    
    return buf.data;
}

/*
 * Non deterministic function walker: returns true if any function is unsafe i.e not whitelisted on not immutable
 */
static bool
contain_non_deterministic_func_walker(Node *node, void *context)
{
    bool *found_unsafe = (bool *) context;
    
    if (node == NULL)
        return false;
    
    if (IsA(node, FuncExpr))
    {
        FuncExpr *f = (FuncExpr *) node;
        HeapTuple tup = SearchSysCache1(PROCOID, ObjectIdGetDatum(f->funcid));
        
        if (!HeapTupleIsValid(tup))
        {
            /* Cache lookup failed — fail closed */
            *found_unsafe = true;
            return true;
        }

        Form_pg_proc proc = (Form_pg_proc) GETSTRUCT(tup);

        if (proc->provolatile == PROVOLATILE_IMMUTABLE)
        {
            /* IMMUTABLE is always safe */
            ReleaseSysCache(tup);
            return expression_tree_walker(node, contain_non_deterministic_func_walker, context);
        }

        if (proc->provolatile == PROVOLATILE_STABLE)
        {
            const char *funcname = NameStr(proc->proname);
            char *nspname = get_namespace_name(proc->pronamespace);
            FuncEntry *entry = nspname ? find_in_whitelist(funcname, nspname) : NULL;

            if (nspname)
                pfree(nspname);

            if (entry && validate_whitelist_entry(entry, f))
            {
                ReleaseSysCache(tup);
                return expression_tree_walker(node, contain_non_deterministic_func_walker, context);
            }
        }

        /* VOLATILE or non-whitelisted STABLE — unsafe */
        *found_unsafe = true;
        ReleaseSysCache(tup);
        return true;
    }
    
    return expression_tree_walker(node, contain_non_deterministic_func_walker, context);
}

/* Hook: returns NULL to skip immutability check, expr to let PG handle */
Node * 
stable_persisted_hook(Node *expr)
{
    bool found_unsafe = false;
    
    if (expr == NULL)
        return NULL;

    /* 
     * If not TSQL dialect and not dump restore we pass to the previous hook.
     * During dump/restore the sql_dialect may not be set to TSQL yet, but we still need to
     * bypass the immutability check for tables being restored that have
     * whitelisted STABLE functions in their persisted columns.
     */
    if (sql_dialect != SQL_DIALECT_TSQL && !babelfish_dump_restore)
    {
        if (prev_persisted_col_hook)
            return prev_persisted_col_hook(expr);
        return expr;
    }
    
    /* Enforce GUC settings at CREATE time (skip during dump/restore) */
    if (!babelfish_dump_restore && !check_persisted_gucs())
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_OBJECT_DEFINITION),
                 errmsg("CREATE TABLE failed because the following SET options have incorrect settings: '%s'",
                        get_mismatched_persisted_gucs())));
    
    /* Check if expression only has safe functions ie Immutable or stable(whitelisted) */
    contain_non_deterministic_func_walker(expr, &found_unsafe);
    
    if (found_unsafe)
        return expr;
    
    return NULL; 
}

/* Check if table has any persisted computed columns */
bool 
table_has_persisted_computed_cols(Oid relid)
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

/* Check GUCs for DML into tables with PERSISTED computed columns */
void 
guc_check_dml(Query *parse)
{
    RangeTblEntry *rte;
    const char *cmd;

    if (parse->resultRelation == 0)
        return;

    rte = rt_fetch(parse->resultRelation, parse->rtable);

    if (rte->rtekind != RTE_RELATION)
        return;

    if (check_persisted_gucs())
        return;

    switch (parse->commandType)
    {
        case CMD_INSERT: 
            cmd = "INSERT"; break;
        case CMD_UPDATE: 
            cmd = "UPDATE"; break;
        case CMD_DELETE: 
            cmd = "DELETE"; break;
        default: 
            cmd = "DML"; break;
    }

    /* Check if the target table itself has persisted computed columns */
    if (table_has_persisted_computed_cols(rte->relid))
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_OBJECT_DEFINITION),
                 errmsg("%s failed because the following SET options have incorrect settings: '%s'",
                        cmd, get_mismatched_persisted_gucs()),
                 errhint("Verify that SET options are correct for use with indexed views and/or indexes on computed columns.")));
    }

    /* Check if any FK-referenced parent table has persisted computed columns */
    {
        Relation    rel;
        List       *fk_list;
        ListCell   *lc;

        rel = relation_open(rte->relid, AccessShareLock);
        fk_list = RelationGetFKeyList(rel);

        foreach(lc, fk_list)
        {
            ForeignKeyCacheInfo *fk = (ForeignKeyCacheInfo *) lfirst(lc);

            if (table_has_persisted_computed_cols(fk->confrelid))
            {
                relation_close(rel, AccessShareLock);
                ereport(ERROR,
                        (errcode(ERRCODE_INVALID_OBJECT_DEFINITION),
                         errmsg("%s failed because the following SET options have incorrect settings: '%s'",
                                cmd, get_mismatched_persisted_gucs()),
                         errhint("Verify that SET options are correct for use with indexed views and/or indexes on computed columns.")));
            }
        }

        relation_close(rel, AccessShareLock);
    }
}

/*
 * Query rewriter helper function to replace the Var node with the actual expression
 */
static Node *
query_rewrite_helper(Node *node, void *context)
{
    RewriteCtx *ctx = (RewriteCtx *) context;

    if (node == NULL)
        return NULL;

    if (IsA(node, Query))
        return node;

    if (IsA(node, Var))
    {
        Var *v = (Var *) node;
        if (v->varno == ctx->varno && v->varattno == ctx->varattno && v->varlevelsup == 0)
            return copyObject(ctx->expr);
        return node;
    }

    return expression_tree_mutator(node, query_rewrite_helper, context);
}

void 
query_rewrite_persisted(Query *parse)
{
    ListCell *lc;
    int rindex = 0;

    foreach(lc, parse->rtable)
    {
        RangeTblEntry *rte = (RangeTblEntry *) lfirst(lc);
        Relation  rel;
        TupleDesc tupdesc;

        rindex++;

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

            ChangeVarNodes(expr_generated, 1, rindex, 0);

            ctx.varno = rindex;
            ctx.varattno = attr->attnum;
            ctx.expr = expr_generated;

            query_tree_mutator(parse, query_rewrite_helper, &ctx, QTW_DONT_COPY_QUERY);
        }
        relation_close(rel, AccessShareLock);
    }
}
