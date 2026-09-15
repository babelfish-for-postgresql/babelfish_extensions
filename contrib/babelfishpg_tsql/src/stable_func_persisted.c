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
#include "funcapi.h"
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
#include "guc.h"
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

/* Validators referenced by the whitelist below */
static bool require_true_flag(HeapTuple procTup, FuncExpr *f, const char *argname);

/* Whitelist: deterministic STABLE functions allowed in PERSISTED columns */
static FuncEntry whitelist[] = {
    /* String concatenation */
    {"babelfish_concat_wrapper",       "sys", NULL, NULL},
    {"babelfish_concat_wrapper_outer", "sys", NULL, NULL},
    {"concat",                         "sys", NULL, NULL},
    {"concat_ws",                      "sys", NULL, NULL},

    /* Conversion functions — deterministic only with an explicit style */
    {"babelfish_conv_helper_to_varchar", "sys", require_true_flag, "p_style_specified"},

    /* Numeric casting/rounding */
    {"babelfish_cast_floor_int",       "sys", NULL, NULL},
    {"babelfish_cast_floor_bigint",    "sys", NULL, NULL},
    {"babelfish_cast_floor_smallint",  "sys", NULL, NULL},
    {"_round_fixeddecimal_to_int2",    "sys", NULL, NULL},
    {"_round_fixeddecimal_to_int4",    "sys", NULL, NULL},
    {"_round_fixeddecimal_to_int8",    "sys", NULL, NULL},
    {"_trunc_numeric_to_int2",         "sys", NULL, NULL},
    {"_trunc_numeric_to_int4",         "sys", NULL, NULL},
    {"_trunc_numeric_to_int8",         "sys", NULL, NULL},

    /* Date functions */
    {"eomonth",                        "sys", NULL, NULL},
    {"datetrunc",                      "sys", NULL, NULL},

    {NULL, NULL, NULL, NULL}
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
 * Position of the named parameter, or -1 if not found.  Also -1 for variadic
 * functions, where proargnames is not positional against FuncExpr->args.
 */
static int
find_arg_position(HeapTuple procTup, const char *argname)
{
    Form_pg_proc  proc = (Form_pg_proc) GETSTRUCT(procTup);
    Oid          *argtypes;
    char        **argnames;
    char         *argmodes;
    int           nargs;

    if (OidIsValid(proc->provariadic))
        return -1;

    nargs = get_func_arg_info(procTup, &argtypes, &argnames, &argmodes);
    if (argnames == NULL)
        return -1;

    for (int i = 0; i < nargs; i++)
        if (argnames[i] != NULL && strcmp(argnames[i], argname) == 0)
            return i;

    return -1;
}

/* Named argument if it was passed as a literal, else NULL so callers fail closed. */
static Const *
get_literal_arg(HeapTuple procTup, FuncExpr *f, const char *argname)
{
    int    pos;
    Node  *arg;

    if (f == NULL || argname == NULL)
        return NULL;

    pos = find_arg_position(procTup, argname);
    if (pos < 0 || list_length(f->args) <= pos)
        return NULL;

    arg = (Node *) list_nth(f->args, pos);
    return IsA(arg, Const) ? (Const *) arg : NULL;
}

/*
 * Deterministic only when the named boolean parameter is a literal true.
 * Used by CONVERT, where the grammar sets p_style_specified when an explicit
 * style was given, but reusable by any function with such a flag.
 */
static bool
require_true_flag(HeapTuple procTup, FuncExpr *f, const char *argname)
{
    Const *c = get_literal_arg(procTup, f, argname);

    return c != NULL && !c->constisnull && DatumGetBool(c->constvalue);
}

/*
 * Does the session differ from the SET options required for PERSISTED computed
 * columns?  Returns true when at least one of them is not at its required
 * value, i.e. when the stored values cannot be trusted to match what the
 * session would compute now.
 */
bool 
has_mismatched_set_options(void)
{
    return !(pltsql_quoted_identifier &&
             pltsql_arithabort &&
             pltsql_concat_null_yields_null &&
             pltsql_ansi_nulls &&
             pltsql_ansi_padding &&
             pltsql_ansi_warnings &&
             !pltsql_numeric_roundabort);
}

/*
 * Append one option name to a comma-separated list.  The separator goes before
 * every entry except the first, so there is never a trailing one to trim; an
 * empty buffer means nothing has been appended yet.
 */
static void
append_mismatched_option(StringInfo buf, const char *name)
{
    if (buf->len > 0)
        appendStringInfoString(buf, ", ");
    appendStringInfoString(buf, name);
}

/* Get comma-separated list of mismatched GUCs */
char * 
get_mismatched_persisted_gucs(void)
{
    StringInfoData buf;

    initStringInfo(&buf);

    if (!pltsql_quoted_identifier)
        append_mismatched_option(&buf, "QUOTED_IDENTIFIER");
    if (!pltsql_arithabort)
        append_mismatched_option(&buf, "ARITHABORT");
    if (!pltsql_concat_null_yields_null)
        append_mismatched_option(&buf, "CONCAT_NULL_YIELDS_NULL");
    if (!pltsql_ansi_nulls)
        append_mismatched_option(&buf, "ANSI_NULLS");
    if (!pltsql_ansi_padding)
        append_mismatched_option(&buf, "ANSI_PADDING");
    if (!pltsql_ansi_warnings)
        append_mismatched_option(&buf, "ANSI_WARNINGS");
    if (pltsql_numeric_roundabort)
        append_mismatched_option(&buf, "NUMERIC_ROUNDABORT");

    return buf.data;
}

/*
 * Is this function safe to persist?  IMMUTABLE always is; STABLE only if
 * whitelisted and its validator agrees.  f is the call site, NULL when the
 * function came from a node with no argument list (validators then fail closed).
 */
static bool
funcid_is_safe(Oid funcid, FuncExpr *f)
{
    HeapTuple    tup;
    Form_pg_proc proc;
    bool         safe = false;

    tup = SearchSysCache1(PROCOID, ObjectIdGetDatum(funcid));
    if (!HeapTupleIsValid(tup))
    {
        /*
         * Should not happen: the OID was resolved from the catalog during parse
         * analysis in this transaction.  Defer to PG's own immutability check
         * rather than vouch for a function we cannot inspect.
         */
        return false;
    }

    proc = (Form_pg_proc) GETSTRUCT(tup);

    if (proc->provolatile == PROVOLATILE_IMMUTABLE)
        safe = true;
    else if (proc->provolatile == PROVOLATILE_STABLE)
    {
        const char *funcname = NameStr(proc->proname);
        char       *nspname = get_namespace_name(proc->pronamespace);
        FuncEntry  *entry = nspname ? find_in_whitelist(funcname, nspname) : NULL;

        if (nspname)
            pfree(nspname);

        if (entry != NULL)
            safe = (entry->validate == NULL) ||
                   entry->validate(tup, f, entry->validate_arg);
    }

    ReleaseSysCache(tup);
    return safe;
}

/*
 * Callback for check_functions_in_node().  Returns true to stop the scan, so
 * true means "unsafe".  Used for node types that carry a function OID but no
 * argument list we could hand to a validator.
 */
static bool
persisted_funcid_checker(Oid funcid, void *context)
{
    return !funcid_is_safe(funcid, NULL);
}

/*
 * Returns true if the expression contains a function that is unsafe to persist,
 * i.e. neither IMMUTABLE nor whitelisted.
 *
 * Operators and type I/O coercions carry a function OID too, not just FuncExpr,
 * so use check_functions_in_node() for the same node coverage PG's
 * contain_mutable_functions_walker() has.
 */
static bool
contain_non_deterministic_func_walker(Node *node, void *context)
{
    bool *found_unsafe = (bool *) context;

    if (node == NULL)
        return false;

    /*
     * FuncExpr is handled separately so that argument-sensitive whitelist
     * entries (e.g. CONVERT with an explicit style) can inspect the call site.
     */
    if (IsA(node, FuncExpr))
    {
        if (!funcid_is_safe(((FuncExpr *) node)->funcid, (FuncExpr *) node))
        {
            *found_unsafe = true;
            return true;
        }
    }
    else if (check_functions_in_node(node, persisted_funcid_checker, NULL))
    {
        *found_unsafe = true;
        return true;
    }

    /* Stable or volatile by definition, with no function OID to inspect */
    if (IsA(node, SQLValueFunction) || IsA(node, NextValueExpr))
    {
        *found_unsafe = true;
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
    
    /* Enforce GUC settings at CREATE time (skip during dump/restore or when escape hatch is 'ignore') */
    if (!babelfish_dump_restore &&
        escape_hatch_persisted_col_guc_check != EH_IGNORE &&
        has_mismatched_set_options())
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_OBJECT_DEFINITION),
                 errmsg("CREATE/ALTER TABLE failed because the following SET options have incorrect settings: '%s'",
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

/* Raise the SET-options error for a DML command */
pg_noreturn static void
guc_check_dml_error(const char *cmd)
{
    ereport(ERROR,
            (errcode(ERRCODE_INVALID_OBJECT_DEFINITION),
             errmsg("%s failed because the following SET options have incorrect settings: '%s'",
                    cmd, get_mismatched_persisted_gucs()),
             errhint("Verify that SET options are correct for use with indexed views and/or indexes on computed columns.")));
}

/*
 * Raise an error if the target relation, or any table it references by foreign
 * key, has PERSISTED computed columns.  Callers have already established that
 * the session GUCs do not match the required settings.
 */
static void
check_dml_target(Oid relid, const char *cmd)
{
    Relation    rel;
    List       *fk_list;
    ListCell   *lc;

    /* Check if the target table itself has persisted computed columns */
    if (table_has_persisted_computed_cols(relid))
        guc_check_dml_error(cmd);

    /* Check if any FK-referenced parent table has persisted computed columns */
    rel = relation_open(relid, AccessShareLock);
    fk_list = RelationGetFKeyList(rel);

    foreach(lc, fk_list)
    {
        ForeignKeyCacheInfo *fk = (ForeignKeyCacheInfo *) lfirst(lc);

        if (table_has_persisted_computed_cols(fk->confrelid))
        {
            relation_close(rel, AccessShareLock);
            guc_check_dml_error(cmd);
        }
    }

    relation_close(rel, AccessShareLock);
}

/*
 * Check GUCs for DML into tables with PERSISTED computed columns.
 *
 * This runs from ExecutorStart rather than from the planner so that it is
 * reached on every execution.  A cached plan (stored procedure, prepared
 * statement, PL/tsql function or trigger) skips planning entirely, so a
 * planner-time check is silently bypassed once the plan has been built, and
 * a wrong value gets persisted with no error.
 */
void 
guc_check_dml(PlannedStmt *pstmt)
{
    const char *cmd;
    ListCell   *lc;

    if (pstmt == NULL || pstmt->resultRelations == NIL)
        return;

    /* Skip if escape hatch is 'ignore' */
    if (escape_hatch_persisted_col_guc_check == EH_IGNORE)
        return;

    switch (pstmt->commandType)
    {
        case CMD_INSERT: 
            cmd = "INSERT"; break;
        case CMD_UPDATE: 
            cmd = "UPDATE"; break;
        case CMD_DELETE: 
            cmd = "DELETE"; break;
        default: 
            return;     /* not DML, nothing to check */
    }

    if (!has_mismatched_set_options())
        return;

    /*
     * More than one result relation is possible for an inherited or
     * partitioned target; every one of them needs to be checked.
     */
    foreach(lc, pstmt->resultRelations)
    {
        Index          rti = lfirst_int(lc);
        RangeTblEntry *rte = rt_fetch(rti, pstmt->rtable);

        if (rte->rtekind == RTE_RELATION)
            check_dml_target(rte->relid, cmd);
    }
}

/*
 * Replace references to one stored generated column with its generation
 * expression, so the value is recomputed instead of read from the heap.
 *
 * Only reached when the session's SET options differ from the ones the stored
 * value was computed under; see persisted_col_planner_rewrite().  Matches only
 * Vars at the current query level - nested Query nodes are left alone, since
 * subquery_planner() invokes the hook again for each of them.
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
