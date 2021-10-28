#include "postgres.h"
#include "analyzer.h"
#include "dynastack.h"
#include "stmt_walker.h"

#define ANALYZER_INITIAL_STACK_SIZE 8

/***********************************************************************************
 *                       VISITOR ACTIONS DEFINITIONS
 **********************************************************************************/
static bool analyzer_try_catch_act(Walker_context *ctx, PLtsql_stmt_try_catch *stmt);
static bool analyzer_goto_act(Walker_context *ctx, PLtsql_stmt_goto *stmt);
static bool analyzer_label_act(Walker_context *ctx, PLtsql_stmt_label *stmt);
static bool analyzer_while_act(Walker_context *ctx, PLtsql_stmt_while *stmt);
static bool analyzer_exit_act(Walker_context *ctx, PLtsql_stmt_exit *stmt);
static bool analyzer_return_act(Walker_context *ctx, PLtsql_stmt_return *stmt);

/***********************************************************************************
 *                          ANALYZER CONTEXT
 **********************************************************************************/
static Walker_context *make_analyzer_context(CompileContext *cmpl_ctx);
static void destroy_analyzer_context(void *ctx);

/* all items MUST be destoryed in destroy_template_context */
typedef struct 
{
    /* for invalid GOTO check */
	DynaVec  *trycatch_info_stack; /* current nesting stmt_try_catch */
	DynaVec  *loop_stack;          /* current nesting loops */
    DynaVec  *gotos;               /* store all user input goto stmts */

    /* compile context */
    CompileContext *cmpl_ctx;
} AnalyzerContext;

static Walker_context *make_analyzer_context(CompileContext *cmpl_ctx)
{
    Walker_context   *walker = make_template_context();
    AnalyzerContext  *analyzer = palloc(sizeof(AnalyzerContext));

    analyzer->trycatch_info_stack = create_stack2(sizeof(TryCatchInfo), ANALYZER_INITIAL_STACK_SIZE);
    analyzer->loop_stack = create_stack2(sizeof(PLtsql_stmt_while *), ANALYZER_INITIAL_STACK_SIZE);
    analyzer->gotos = create_stack2(sizeof(PLtsql_stmt_goto *), ANALYZER_INITIAL_STACK_SIZE);

    /* compile context */
    analyzer->cmpl_ctx = cmpl_ctx;

    /* Regster actions */
    walker->try_catch_act = &analyzer_try_catch_act;
    walker->goto_act = &analyzer_goto_act;
    walker->label_act = &analyzer_label_act;
    walker->while_act = &analyzer_while_act;
    walker->exit_act = &analyzer_exit_act;
    walker->return_act = &analyzer_return_act;

    /* Extra context */
    walker->extra_ctx = (void *) analyzer;
    walker->destroy_extra_ctx = &destroy_analyzer_context;
    return walker;
}

static void destroy_analyzer_context(void *ctx)
{
    AnalyzerContext *analyzer_ctx = (AnalyzerContext *) ctx;

	destroy_vector(analyzer_ctx->trycatch_info_stack);
	destroy_vector(analyzer_ctx->loop_stack);
    destroy_vector(analyzer_ctx->gotos);

    pfree(analyzer_ctx);
}

/***********************************************************************************
 *                       VISITOR ACTIONS IMPLEMENTATION
 **********************************************************************************/
static void save_scope(PLtsql_stmt *stmt, AnalyzerContext *analyzer_ctx)
{
    CompileContext *cmpl_ctx = analyzer_ctx->cmpl_ctx;
    ScopeContext *scope_context =
        hash_search(cmpl_ctx->stmt_scope_context, &stmt, HASH_ENTER, NULL);

    scope_context->nesting_trycatch_infos = 
                        create_vector_copy(analyzer_ctx->trycatch_info_stack);
    scope_context->nesting_loops = 
                        create_vector_copy(analyzer_ctx->loop_stack);
}

static bool analyzer_try_catch_act(Walker_context *ctx, PLtsql_stmt_try_catch *stmt)
{
    AnalyzerContext *analyzer_ctx = (AnalyzerContext*) ctx->extra_ctx; 
    TryCatchInfo try_catch_info;
    TryCatchInfo *try_catch_info_ptr;

    try_catch_info.stmt = (PLtsql_stmt *) stmt;
    try_catch_info.in_try_block = true;
    vec_push_back(analyzer_ctx->trycatch_info_stack, &try_catch_info);

    general_walker_func(stmt->body, ctx);  /* visit try block */

    try_catch_info_ptr = (TryCatchInfo *) vec_back(analyzer_ctx->trycatch_info_stack);
    try_catch_info_ptr->in_try_block = false;  

    general_walker_func(stmt->handler, ctx);  /* visit right chid */

    vec_pop_back(analyzer_ctx->trycatch_info_stack);

    return false;
}

static bool analyzer_goto_act(Walker_context *ctx, PLtsql_stmt_goto *stmt)
{
    AnalyzerContext *analyzer_ctx = (AnalyzerContext*) ctx->extra_ctx; 

    save_scope((PLtsql_stmt*) stmt, analyzer_ctx);
    vec_push_back(analyzer_ctx->gotos, &stmt);
    return stmt_walker((PLtsql_stmt*)stmt, &general_walker_func, ctx);
}

static bool analyzer_label_act(Walker_context *ctx, PLtsql_stmt_label *stmt)
{
    AnalyzerContext *analyzer_ctx = (AnalyzerContext*) ctx->extra_ctx; 
    CompileContext *cmpl_ctx = analyzer_ctx->cmpl_ctx;
    bool found = false;
    LabelStmtEntry *label_entry =
        hash_search(cmpl_ctx->label_stmt_map, stmt->label, HASH_ENTER, &found);
    
    if (found)
    {
        /* label not unique within one procedure */
        PLtsql_stmt_label *label = label_entry->stmt;
        ereport(ERROR,
                (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                 errmsg("Label %s not unique wihtin one procedure in line %d, previous defined in line %d",
                        stmt->label, stmt->lineno, label->lineno)));
    }
    label_entry->stmt = stmt;

    save_scope((PLtsql_stmt*) stmt, analyzer_ctx);

    return stmt_walker((PLtsql_stmt*)stmt, &general_walker_func, ctx);
}

static bool analyzer_while_act(Walker_context *ctx, PLtsql_stmt_while *stmt)
{
    AnalyzerContext *analyzer_ctx = (AnalyzerContext*) ctx->extra_ctx; 
    ListCell *s;

    vec_push_back(analyzer_ctx->loop_stack, &stmt);
    save_scope((PLtsql_stmt*) stmt, analyzer_ctx);

    /* visit all children */
    foreach(s, stmt->body)
        general_walker_func((PLtsql_stmt *) lfirst(s), ctx);

    vec_pop_back(analyzer_ctx->loop_stack);
    return false;
}

static bool analyzer_exit_act(Walker_context *ctx, PLtsql_stmt_exit *stmt)
{
    AnalyzerContext *analyzer_ctx = (AnalyzerContext*) ctx->extra_ctx; 

    if (vec_size(analyzer_ctx->loop_stack) == 0)
    {
        if (stmt->is_exit) /* break */
            ereport(ERROR,
                    (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                     errmsg("Do not support BREAK outside of a WHILE loop, line %d", stmt->lineno)));
        else
            ereport(ERROR,
                    (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                     errmsg("Do not support CONTINUE outside of a WHILE loop, line %d", stmt->lineno)));
    }
    save_scope((PLtsql_stmt*) stmt, analyzer_ctx);

    return stmt_walker((PLtsql_stmt*)stmt, &general_walker_func, ctx);
}

static bool analyzer_return_act(Walker_context *ctx, PLtsql_stmt_return *stmt)
{
    AnalyzerContext *analyzer_ctx = (AnalyzerContext*) ctx->extra_ctx; 

    save_scope((PLtsql_stmt*) stmt, analyzer_ctx);
    return stmt_walker((PLtsql_stmt*)stmt, &general_walker_func, ctx);
}

/***********************************************************************************
 *                          CHECKING FUNCTIONS 
 **********************************************************************************/

static bool check_goto_try_catch(DynaVec *src_stack, DynaVec *dest_stack);
static bool check_goto_loop(DynaVec *src_stack, DynaVec *dest_stack);

static void check_unsupported_goto(AnalyzerContext *analyzer_ctx)
{
    CompileContext *cmpl_ctx = analyzer_ctx->cmpl_ctx;
    size_t size = vec_size(analyzer_ctx->gotos);
    PLtsql_stmt_label *label;
    DynaVec *src_nesting_trycatch_infos, *dest_nesting_trycatch_infos;
    DynaVec *src_nesting_loops, *dest_nesting_loops;
    LabelStmtEntry *label_entry;
    ScopeContext *scope_context;
    size_t i;

    for (i = 0; i < size; i++)
    {
        PLtsql_stmt_goto *stmt_goto =
                    *(PLtsql_stmt_goto **) vec_at(analyzer_ctx->gotos, i);

        label_entry =
            hash_search(cmpl_ctx->label_stmt_map, stmt_goto->target_label,
                        HASH_FIND, NULL);

        /* check existence of target label */
        if (!label_entry)
            ereport(ERROR,
                    (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                     errmsg("GOTO target Label %s not defined",
                     stmt_goto->target_label)));
         
        /* source context */
        scope_context = 
            hash_search(cmpl_ctx->stmt_scope_context, &stmt_goto, HASH_FIND, NULL);
        src_nesting_trycatch_infos = scope_context->nesting_trycatch_infos;
        src_nesting_loops = scope_context->nesting_loops;

        /* destination context */
        label = label_entry->stmt;
        scope_context = 
            hash_search(cmpl_ctx->stmt_scope_context, &label, HASH_FIND, NULL);
        dest_nesting_trycatch_infos = scope_context->nesting_trycatch_infos;
        dest_nesting_loops = scope_context->nesting_loops;

        /* check if goto a loop or try catch block */
        if (!check_goto_try_catch(src_nesting_trycatch_infos, dest_nesting_trycatch_infos))
            ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                            errmsg("GOTO into an try catch block not supported, label %s",
                            stmt_goto->target_label)));

        if (!check_goto_loop(src_nesting_loops, dest_nesting_loops))
            ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                            errmsg("GOTO into an while loop not supported, label %s",
                            stmt_goto->target_label)));
    }
}

static bool check_goto_try_catch(DynaVec *src_stack, DynaVec *dest_stack)
{
    if (vec_size(src_stack) < vec_size(dest_stack))
        return false;  /* goto deeper try-catch block */
    else
    {
        size_t goto_stack_size = vec_size(src_stack);
        size_t label_stack_size = vec_size(dest_stack);
        size_t i;
        for (i = 0; i < goto_stack_size && i < label_stack_size; i++)
        {
            TryCatchInfo *info1 = (TryCatchInfo *) vec_at(src_stack, i);
            TryCatchInfo *info2 = (TryCatchInfo *) vec_at(dest_stack, i);
            if (info1->stmt != info2->stmt || info1->in_try_block != info2->in_try_block)
                return false;  /* goto differen upper / sibling try-catch block */
        }
    }
    return true;
}

static bool check_goto_loop(DynaVec *src_stack, DynaVec *dest_stack)
{
    if (vec_size(src_stack) < vec_size(dest_stack))
        return false;  /* goto deeper loop */
    else
    {
        size_t goto_stack_size = vec_size(src_stack);
        size_t label_stack_size = vec_size(dest_stack);
        size_t i;
        for (i = 0; i < goto_stack_size && i < label_stack_size; i++)
        {
            PLtsql_stmt *stmt1 = *(PLtsql_stmt **) vec_at(src_stack, i);
            PLtsql_stmt *stmt2 = *(PLtsql_stmt **) vec_at(dest_stack, i);
            if (stmt1 != stmt2)
                return false;  /* goto different upper / sibling loop block */
        }
    }
    return true;
}

/***********************************************************************************
 *                              PLTSQL ANALYZER
 **********************************************************************************/

void analyze(PLtsql_function *func, CompileContext *cmpl_ctx)
{
    Walker_context *walker;
    AnalyzerContext *analyzer_ctx;

    if ((!func) || func->exec_codes)  /* cached plan */
        return;

    walker = make_analyzer_context(cmpl_ctx);
    analyzer_ctx = (AnalyzerContext *) walker->extra_ctx;

    PG_TRY();
    {
        /* general checks through traversal */
        stmt_walker((PLtsql_stmt *) func->action, general_walker_func, walker);

        /* extra checks */
        check_unsupported_goto(analyzer_ctx);
    }
    PG_CATCH();
    {
        destroy_template_context(walker);
        PG_RE_THROW();
    }
    PG_END_TRY();

    destroy_template_context(walker);
}
