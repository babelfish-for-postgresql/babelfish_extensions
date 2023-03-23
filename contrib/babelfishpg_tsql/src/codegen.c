#include "postgres.h"
#include "stmt_walker.h"
#include "iterative_exec.h"
#include "codegen.h"
#include "dynavec.h"
#include "dynastack.h"
#include "utils/elog.h"
#include "utils/lsyscache.h"

#define LOOP_BEGIN_LABEL_FORMAT  "$LOOP_BEGIN_%d_-0x%p"
#define LOOP_END_LABEL_FORMAT    "$LOOP_END_%d_-0x%p"
#define CATCH_BEGIN_LABEL_FORMAT "$CATCH_BEGIN_%d_-0x%p"
#define CATCH_END_LABEL_FORMAT   "$CATCH_END_%d_-0x%p"
#define ELSE_BEGIN_LABEL_FORMAT  "$ELSE_BEGIN_%d_-0x%p"
#define ELSE_END_LABEL_FORMAT    "$ELSE_END_%d_-0x%p"
#define END_OF_PROC_FORMAT       "$END_OF_PROC_%d_-0x%p"
#define LABEL_LEN NAMEDATALEN

/***********************************************************************************
 *                       VISITOR ACTIONS DEFINITIONS
 **********************************************************************************/

static bool stmt_default_act(Walker_context *ctx, PLtsql_stmt *stmt);
static bool stmt_block_act(Walker_context *ctx, PLtsql_stmt_block *stmt);
static bool stmt_if_act(Walker_context *ctx, PLtsql_stmt_if *stmt);
static bool stmt_label_act(Walker_context *ctx, PLtsql_stmt_label *stmt);
static bool stmt_try_catch_act(Walker_context *ctx, PLtsql_stmt_try_catch *stmt);
static bool stmt_while_act(Walker_context *ctx, PLtsql_stmt_while *stmt);
static bool stmt_exit_act(Walker_context *ctx, PLtsql_stmt_exit *stmt);
static bool stmt_return_act(Walker_context *ctx, PLtsql_stmt_return *stmt);
static bool stmt_goto_act(Walker_context *ctx, PLtsql_stmt_goto *stmt);

/***********************************************************************************
 *                          CODEGEN CONTEXT
 **********************************************************************************/

static Walker_context *make_codegen_context(CompileContext *cmpl_ctx);
static void destroy_codegen_context(void *ctx);

typedef struct
{
	char		label[LABEL_LEN];
	size_t		pc;
} LabelIndexEntry;

typedef struct
{
	PLtsql_stmt_while *stmt;
} LoopContext;

typedef struct
{
	ExecCodes  *exec_codes;
	HTAB	   *label_index;
	DynaStack  *loop_contexts;
	CompileContext *cmpl_ctx;
} CodegenContext;

static void add_stmt(CodegenContext *ctx, PLtsql_stmt *stmt);

static Walker_context *
make_codegen_context(CompileContext *cmpl_ctx)
{
	Walker_context *context = make_template_context();
	CodegenContext *generator;
	HASHCTL		hashCtl;

	/* Create Codegen Conext */
	generator = palloc(sizeof(CodegenContext));
	generator->exec_codes = palloc(sizeof(ExecCodes));
	generator->exec_codes->codes = create_vector(sizeof(PLtsql_stmt *));
	generator->exec_codes->proc_namespace = NULL;
	generator->exec_codes->proc_name = NULL;
	MemSet(&hashCtl, 0, sizeof(hashCtl));
	hashCtl.keysize = LABEL_LEN;
	hashCtl.entrysize = sizeof(LabelIndexEntry);
	hashCtl.hcxt = CurrentMemoryContext;
	generator->label_index = hash_create("Label to index mapping",
										 16,	/* initial label index hashmap
												 * size */
										 &hashCtl,
										 HASH_ELEM | HASH_STRINGS | HASH_CONTEXT);	/* string comp */

	generator->loop_contexts = create_stack2(sizeof(LoopContext *), 8);
	generator->cmpl_ctx = cmpl_ctx;

	/* Traverse actions */
	context->default_act = &stmt_default_act;
	context->block_act = &stmt_block_act;
	context->if_act = &stmt_if_act;
	context->label_act = &stmt_label_act;
	context->try_catch_act = &stmt_try_catch_act;
	context->while_act = &stmt_while_act;
	context->exit_act = &stmt_exit_act;
	context->return_act = &stmt_return_act;
	context->goto_act = &stmt_goto_act;

	/* Extra context */
	context->extra_ctx = (void *) generator;
	context->destroy_extra_ctx = &destroy_codegen_context;
	return context;
}

static void
destroy_codegen_context(void *ctx)
{
	CodegenContext *codegen_ctx = (CodegenContext *) ctx;

	/* exec_codes ownershipt tranfered to plan, not freed here */
	hash_destroy(codegen_ctx->label_index);
	destroy_stack(codegen_ctx->loop_contexts);
	pfree(codegen_ctx);
}

/*
 * for node added which is not part of tree_node,
 * shall have corresponging free function called through free_exec_codes
 */
static void
add_stmt(CodegenContext *ctx, PLtsql_stmt *stmt)
{
	vec_push_back(ctx->exec_codes->codes, &stmt);
}

/***********************************************************************************
 *                       HELPERS FUNCTIONS
 **********************************************************************************/

/* Node creation */
static PLtsql_stmt_goto *create_goto(int lineno);
static PLtsql_stmt_save_ctx *create_save_ctx(int lineno);
static PLtsql_stmt_restore_ctx_full *create_restore_ctx_full(int lineno);
static PLtsql_stmt_restore_ctx_partial *create_restore_ctx_partial(int lineno);

/* Label creation */
static void
			create_and_register_label(CodegenContext *codegen_ctx, const char *format, int lineno, void *stmt);

/* handle dangling exception contexts */
static void
			cleanup_exception_context(PLtsql_stmt *src, PLtsql_stmt *dst, CodegenContext *codegen_ctx);
static void
			cleanup_all_exception_context(PLtsql_stmt *src, CodegenContext *codegen_ctx);

static PLtsql_stmt_goto *
create_goto(int lineno)
{
	PLtsql_stmt_goto *stmt_goto;

	stmt_goto = palloc(sizeof(PLtsql_stmt_goto));
	stmt_goto->cmd_type = PLTSQL_STMT_GOTO;
	stmt_goto->lineno = lineno;
	stmt_goto->cond = NULL;		/* unconditional goto */
	stmt_goto->target_pc = -1;
	stmt_goto->target_label = palloc0(LABEL_LEN);
	return stmt_goto;
}

static PLtsql_stmt_save_ctx *
create_save_ctx(int lineno)
{
	PLtsql_stmt_save_ctx *save_ctx = palloc(sizeof(PLtsql_stmt_save_ctx));

	save_ctx->cmd_type = PLTSQL_STMT_SAVE_CTX;
	save_ctx->lineno = lineno;
	save_ctx->target_pc = -1;
	save_ctx->target_label = palloc0(LABEL_LEN);
	return save_ctx;
}

static PLtsql_stmt_restore_ctx_full *
create_restore_ctx_full(int lineno)
{
	PLtsql_stmt_restore_ctx_full *restore_ctx = palloc(sizeof(PLtsql_stmt_restore_ctx_full));

	restore_ctx->cmd_type = PLTSQL_STMT_RESTORE_CTX_FULL;
	restore_ctx->lineno = lineno;
	return restore_ctx;
}

static PLtsql_stmt_restore_ctx_partial *
create_restore_ctx_partial(int lineno)
{
	PLtsql_stmt_restore_ctx_partial *restore_ctx = palloc(sizeof(PLtsql_stmt_restore_ctx_partial));

	restore_ctx->cmd_type = PLTSQL_STMT_RESTORE_CTX_PARTIAL;
	restore_ctx->lineno = lineno;
	return restore_ctx;
}

static void
create_and_register_label(CodegenContext *codegen_ctx, const char *format, int lineno, void *stmt)
{
	LabelIndexEntry *label_entry;
	char		buf[LABEL_LEN];

	snprintf(buf, LABEL_LEN, format, lineno, stmt);
	label_entry =
		hash_search(codegen_ctx->label_index, buf, HASH_ENTER, NULL);
	label_entry->pc = vec_size(codegen_ctx->exec_codes->codes); /* NEXT SLOT */
}

static void
cleanup_exception_context(PLtsql_stmt *src, PLtsql_stmt *dst, CodegenContext *codegen_ctx)
{
	CompileContext *cmpl_ctx = codegen_ctx->cmpl_ctx;
	ScopeContext *scope_context;
	DynaVec    *src_trycatch_infos,
			   *dst_trycatch_infos;
	size_t		src_depth,
				dst_depth;

	scope_context =
		hash_search(cmpl_ctx->stmt_scope_context, &src, HASH_FIND, NULL);
	src_trycatch_infos = scope_context->nesting_trycatch_infos;

	scope_context =
		hash_search(cmpl_ctx->stmt_scope_context, &dst, HASH_FIND, NULL);
	dst_trycatch_infos = scope_context->nesting_trycatch_infos;

	src_depth = vec_size(src_trycatch_infos);
	dst_depth = vec_size(dst_trycatch_infos);

	/* cleanup context from deepest try catch block */
	if (src_depth > dst_depth)
	{
		size_t		i = src_depth;

		for (; i > dst_depth; i--)
		{
			TryCatchInfo *info = (TryCatchInfo *) vec_at(src_trycatch_infos, i - 1);
			PLtsql_stmt *restore;

			/* distinguish try block and catch block, same as try-catch stmt */
			if (info->in_try_block)
				restore = (PLtsql_stmt *) create_restore_ctx_full(src->lineno);
			else
				restore = (PLtsql_stmt *) create_restore_ctx_partial(src->lineno);
			add_stmt(codegen_ctx, restore);
		}
	}
}

static void
cleanup_all_exception_context(PLtsql_stmt *src, CodegenContext *codegen_ctx)
{
	CompileContext *cmpl_ctx = codegen_ctx->cmpl_ctx;
	ScopeContext *scope_context;
	DynaVec    *src_trycatch_infos;
	int			src_depth;

	scope_context =
		hash_search(cmpl_ctx->stmt_scope_context, &src, HASH_FIND, NULL);
	src_trycatch_infos = scope_context->nesting_trycatch_infos;

	src_depth = vec_size(src_trycatch_infos);
	for (; src_depth > 0; src_depth--)
	{
		TryCatchInfo *info = (TryCatchInfo *) vec_at(src_trycatch_infos, src_depth - 1);
		PLtsql_stmt *restore;

		/* distinguish try block and catch block, same as try-catch stmt */
		if (info->in_try_block)
			restore = (PLtsql_stmt *) create_restore_ctx_full(src->lineno);
		else
			restore = (PLtsql_stmt *) create_restore_ctx_partial(src->lineno);
		add_stmt(codegen_ctx, restore);
	}
}

/***********************************************************************************
 *                       VISITOR ACTIONS IMPLEMENTATION
 **********************************************************************************/
static bool
stmt_default_act(Walker_context *ctx, PLtsql_stmt *stmt)
{
	switch (stmt->cmd_type)
	{
		case PLTSQL_STMT_ASSIGN:
		case PLTSQL_STMT_RETURN_QUERY:
		case PLTSQL_STMT_EXECSQL:
		case PLTSQL_STMT_OPEN:
		case PLTSQL_STMT_FETCH:
		case PLTSQL_STMT_CLOSE:
		case PLTSQL_STMT_COMMIT:
		case PLTSQL_STMT_ROLLBACK:
			/* TSQL-only statement types follow */
		case PLTSQL_STMT_PRINT:
		case PLTSQL_STMT_QUERY_SET:
		case PLTSQL_STMT_PUSH_RESULT:
		case PLTSQL_STMT_EXEC:
		case PLTSQL_STMT_EXEC_BATCH:
		case PLTSQL_STMT_EXEC_SP:
		case PLTSQL_STMT_DECL_TABLE:
		case PLTSQL_STMT_RETURN_TABLE:
		case PLTSQL_STMT_DEALLOCATE:
		case PLTSQL_STMT_DECL_CURSOR:
		case PLTSQL_STMT_RAISERROR:
		case PLTSQL_STMT_THROW:
		case PLTSQL_STMT_USEDB:
		case PLTSQL_STMT_GRANTDB:
		case PLTSQL_STMT_INSERT_BULK:
		case PLTSQL_STMT_SET_EXPLAIN_MODE:
			/* TSQL-only executable node */
		case PLTSQL_STMT_SAVE_CTX:
		case PLTSQL_STMT_RESTORE_CTX_FULL:
		case PLTSQL_STMT_RESTORE_CTX_PARTIAL:
			{
				CodegenContext *codegen_ctx = (CodegenContext *) ctx->extra_ctx;

				add_stmt(codegen_ctx, stmt);
				break;
			}
		case PLTSQL_STMT_INIT:
			{
				break;			/* It holds list of assignments, DO nothing */
			}
		default:
			ereport(ERROR,
					(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					 errmsg("Unsupported statment type %d in codegen", stmt->cmd_type)));
	}
	return stmt_walker((PLtsql_stmt *) stmt, &general_walker_func, ctx);	/* continue traversal */
}

static bool
stmt_block_act(Walker_context *ctx, PLtsql_stmt_block *stmt)
{
	return stmt_walker((PLtsql_stmt *) stmt, general_walker_func, ctx);
}

/*
 *  Translate If statment into GOTOs
 *  IF cond1:               1. IF !cond1, GOTO(1) to ELSE_BEGIN_LABEL
 *     STMT1                2. STMT1
 *  ELSE          --------> 4. GOTO(2) to ELSE_END_LABLE
 *     STMT2                5. ELSE_BEGIN_LABEL
 *                          6. STMT3
 *                          7. ELSE_END_LABLE
 */

static bool
stmt_if_act(Walker_context *ctx, PLtsql_stmt_if *stmt)
{
	CodegenContext *codegen_ctx = (CodegenContext *) ctx->extra_ctx;

	/* create and add GOTO 1 */
	PLtsql_stmt_goto *goto1 = create_goto(stmt->lineno);

	goto1->cond = stmt->cond;

	if (stmt->else_body)
		snprintf(goto1->target_label, LABEL_LEN,
				 ELSE_BEGIN_LABEL_FORMAT, stmt->lineno, stmt);
	else
		snprintf(goto1->target_label, LABEL_LEN,
				 ELSE_END_LABEL_FORMAT, stmt->lineno, stmt);

	add_stmt(codegen_ctx, (PLtsql_stmt *) goto1);

	general_walker_func(stmt->then_body, ctx);

	if (stmt->else_body)
	{
		PLtsql_stmt_goto *goto2 = create_goto(stmt->lineno);

		snprintf(goto2->target_label, LABEL_LEN,
				 ELSE_END_LABEL_FORMAT, stmt->lineno, stmt);
		add_stmt(codegen_ctx, (PLtsql_stmt *) goto2);

		/* register begin of catch block */
		create_and_register_label(codegen_ctx,
								  ELSE_BEGIN_LABEL_FORMAT, stmt->lineno, stmt);

		general_walker_func(stmt->else_body, ctx);
	}

	/* register end of catch block */
	create_and_register_label(codegen_ctx,
							  ELSE_END_LABEL_FORMAT, stmt->lineno, stmt);
	return false;
}

static bool
stmt_label_act(Walker_context *ctx, PLtsql_stmt_label *stmt)
{
	/* register label */
	CodegenContext *codegen_ctx = (CodegenContext *) ctx->extra_ctx;
	LabelIndexEntry *label_entry =
	hash_search(codegen_ctx->label_index, stmt->label, HASH_ENTER, NULL);

	label_entry->pc = vec_size(codegen_ctx->exec_codes->codes); /* NEXT SLOT */
	return stmt_walker((PLtsql_stmt *) stmt, &general_walker_func, ctx);
}

/*
 * Code generation:
 *
 * TRY            SAVE_ERR_CTX, GOTO CATCH_BEGIN_LABEL
 *   STMT1        STMT1
 * CATCH    --->  RESTORE_FULL
 *   STMT2        GOTO CATCH_END_LABEL
 * END            CATCH_BEGIN_LABEL
 *                STMT2
 *                RESTORE_PARTIAL
 *                CATCH_END_LABEL
 *
 * Traverse order:
 *                        |||
 *         [1st visit] TRY_CATCH  [3nd visit]
 *                    //   |   \\
 *                STMT1    |    STMT2
 *                         |
 *                     [2nd visit]
 */

static bool
stmt_try_catch_act(Walker_context *ctx, PLtsql_stmt_try_catch *stmt)
{
	CodegenContext *codegen_ctx = (CodegenContext *) ctx->extra_ctx;
	PLtsql_stmt_save_ctx *save = create_save_ctx(stmt->lineno);
	PLtsql_stmt_goto *stmt_goto = create_goto(stmt->lineno);
	PLtsql_stmt_restore_ctx_full *restore_full =
	create_restore_ctx_full(stmt->lineno);
	PLtsql_stmt_restore_ctx_partial *restore_partial =
	create_restore_ctx_partial(stmt->lineno);


	snprintf(save->target_label, LABEL_LEN,
			 CATCH_BEGIN_LABEL_FORMAT, stmt->lineno, stmt);
	add_stmt(codegen_ctx, (PLtsql_stmt *) save);

	general_walker_func(stmt->body, ctx);

	snprintf(stmt_goto->target_label, LABEL_LEN,
			 CATCH_END_LABEL_FORMAT, stmt->lineno, stmt);

	/* complete try block */
	add_stmt(codegen_ctx, (PLtsql_stmt *) restore_full);
	add_stmt(codegen_ctx, (PLtsql_stmt *) stmt_goto);

	/* register begin of catch block */
	create_and_register_label(codegen_ctx,
							  CATCH_BEGIN_LABEL_FORMAT, stmt->lineno, stmt);

	general_walker_func(stmt->handler, ctx);

	/* complete catch block */
	add_stmt(codegen_ctx, (PLtsql_stmt *) restore_partial);

	/* register end of catch block */
	create_and_register_label(codegen_ctx,
							  CATCH_END_LABEL_FORMAT, stmt->lineno, stmt);

	return false;
}

/*
 *  WHILE COND       WHILE_BEGIN
 *    STMT1          GOTO COND to WHILE_END
 *    STMT2          STM1
 *    CONTINUE       STMT2
 *    STMT3   ->     GOTO WHILE_BEGIN
 *    BREAK          STMT3
 *    STMT4          GOTO WHILE_END
 *    STMT4          STMT4
 *                   GOTO WHILE_BEGIN
 *                   WHILE_END
 */

static bool
stmt_while_act(Walker_context *ctx, PLtsql_stmt_while *stmt)
{
	CodegenContext *codegen_ctx = (CodegenContext *) ctx->extra_ctx;
	PLtsql_stmt_goto *stmt_goto = create_goto(stmt->lineno);
	LoopContext cur_loop_ctx;
	ListCell   *s;

	/* initialize and save loop context */
	cur_loop_ctx.stmt = stmt;
	stack_push(codegen_ctx->loop_contexts, &cur_loop_ctx);

	/* register loop begin label */
	create_and_register_label(codegen_ctx,
							  LOOP_BEGIN_LABEL_FORMAT, stmt->lineno, stmt);

	/* add conditional goto */
	stmt_goto->cond = stmt->cond;
	snprintf(stmt_goto->target_label, LABEL_LEN,
			 LOOP_END_LABEL_FORMAT, stmt->lineno, stmt);	/* goto loop begin */
	add_stmt(codegen_ctx, (PLtsql_stmt *) stmt_goto);

	/* visit all children */
	foreach(s, stmt->body)
		general_walker_func((PLtsql_stmt *) lfirst(s), ctx);

	/* add goto to begin */
	stmt_goto = create_goto(stmt->lineno);
	snprintf(stmt_goto->target_label, LABEL_LEN,
			 LOOP_BEGIN_LABEL_FORMAT, stmt->lineno, stmt);	/* goto loop begin */
	add_stmt(codegen_ctx, (PLtsql_stmt *) stmt_goto);

	/* register loop end label */
	create_and_register_label(codegen_ctx,
							  LOOP_END_LABEL_FORMAT, stmt->lineno, stmt);

	/* pop loop context */
	stack_pop(codegen_ctx->loop_contexts);

	return false;				/* continue */
}

static bool
stmt_exit_act(Walker_context *ctx, PLtsql_stmt_exit *stmt)
{
	CodegenContext *codegen_ctx = (CodegenContext *) ctx->extra_ctx;
	LoopContext *cur_loop_ctx;
	PLtsql_stmt_goto *stmt_goto;
	PLtsql_stmt_while *stmt_while;

	cur_loop_ctx = (LoopContext *) stack_top(codegen_ctx->loop_contexts);
	stmt_while = cur_loop_ctx->stmt;

	stmt_goto = create_goto(stmt->lineno);
	if (stmt->is_exit)			/* break, goto to loop end */
		snprintf(stmt_goto->target_label, LABEL_LEN,
				 LOOP_END_LABEL_FORMAT, stmt_while->lineno, stmt_while);	/* goto loop end */
	else						/* continue, goto to loop begin */
		snprintf(stmt_goto->target_label, LABEL_LEN,
				 LOOP_BEGIN_LABEL_FORMAT, stmt_while->lineno, stmt_while);	/* goto loop begin */

	/* same as goto */
	cleanup_exception_context((PLtsql_stmt *) stmt,
							  (PLtsql_stmt *) stmt_while,
							  codegen_ctx);

	add_stmt(codegen_ctx, (PLtsql_stmt *) stmt_goto);

	return stmt_walker((PLtsql_stmt *) stmt, &general_walker_func, ctx);
}

static bool
stmt_return_act(Walker_context *ctx, PLtsql_stmt_return *stmt)
{
	CodegenContext *codegen_ctx = (CodegenContext *) ctx->extra_ctx;
	PLtsql_stmt_goto *stmt_goto = create_goto(stmt->lineno);

	snprintf(stmt_goto->target_label, LABEL_LEN, END_OF_PROC_FORMAT, 0, ctx);

	add_stmt(codegen_ctx, (PLtsql_stmt *) stmt);

	/* same as goto */
	cleanup_all_exception_context((PLtsql_stmt *) stmt, codegen_ctx);
	add_stmt(codegen_ctx, (PLtsql_stmt *) stmt_goto);	/* end control flow */

	return stmt_walker((PLtsql_stmt *) stmt, &general_walker_func, ctx);
}

static bool
stmt_goto_act(Walker_context *ctx, PLtsql_stmt_goto *stmt)
{
	CodegenContext *codegen_ctx = (CodegenContext *) ctx->extra_ctx;
	CompileContext *cmpl_ctx = codegen_ctx->cmpl_ctx;
	PLtsql_stmt *dest_stmt;

	LabelStmtEntry *label_entry =
	hash_search(cmpl_ctx->label_stmt_map, stmt->target_label, HASH_FIND, NULL);

	dest_stmt = (PLtsql_stmt *) label_entry->stmt;

	/*
	 * handle dangling exception contexs if any if target label is outside of
	 * current try-catch block" goto inner try-catch block was blocked in
	 * analyzer
	 */
	cleanup_exception_context((PLtsql_stmt *) stmt, dest_stmt, codegen_ctx);

	/* add current goto */
	add_stmt(codegen_ctx, (PLtsql_stmt *) stmt);

	return stmt_walker((PLtsql_stmt *) stmt, &general_walker_func, ctx);
}

/***********************************************************************************
 *                          CODE GENERATION
 **********************************************************************************/

static int	get_label_index(Walker_context *ctx, const char *label);
void		resolve_labels(Walker_context *ctx);

static int
get_label_index(Walker_context *ctx, const char *label)
{
	CodegenContext *codegen_ctx = (CodegenContext *) ctx->extra_ctx;
	LabelIndexEntry *entry =
	hash_search(codegen_ctx->label_index, label, HASH_FIND, NULL);

	if (!entry)
		ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						errmsg("Label NOT found  %s", label)));
	return entry->pc;
}

void
resolve_labels(Walker_context *ctx)
{
	CodegenContext *codegen_ctx = (CodegenContext *) ctx->extra_ctx;
	ExecCodes  *exec_codes = codegen_ctx->exec_codes;
	size_t		size = vec_size(exec_codes->codes);
	size_t		i;

	/*
	 * Fill missing goto targets targe_pc could be only filled partially
	 * during tree traversal when label is defined after GOTO
	 */
	for (i = 0; i < size; i++)
	{
		PLtsql_stmt *stmt = *(PLtsql_stmt **) vec_at(exec_codes->codes, i);

		if (stmt->cmd_type == PLTSQL_STMT_GOTO)
		{
			PLtsql_stmt_goto *stmt_goto = (PLtsql_stmt_goto *) stmt;

			stmt_goto->target_pc = get_label_index(ctx, stmt_goto->target_label);
		}
		else if (stmt->cmd_type == PLTSQL_STMT_SAVE_CTX)
		{
			PLtsql_stmt_save_ctx *save_err = (PLtsql_stmt_save_ctx *) stmt;

			save_err->target_pc = get_label_index(ctx, save_err->target_label);
		}
	}
}

void
gen_exec_code(PLtsql_function *func, CompileContext *cmpl_ctx)
{
	Walker_context *walker;
	CodegenContext *codegen_ctx;
	MemoryContext oldcontext;

	if ((!func) || func->exec_codes)	/* cached plan */
		return;

	oldcontext = MemoryContextSwitchTo(func->fn_cxt);
	walker = make_codegen_context(cmpl_ctx);
	codegen_ctx = (CodegenContext *) walker->extra_ctx;

	PG_TRY();
	{
		ExecCodes  *exec_codes;
		Oid			namespace;

		/* general generations */
		stmt_walker((PLtsql_stmt *) func->action, general_walker_func, walker);
		create_and_register_label(codegen_ctx, END_OF_PROC_FORMAT, 0, walker);

		/* post generations */
		resolve_labels(walker);

		/* additional infos */
		namespace = get_func_namespace(func->fn_oid);
		exec_codes = codegen_ctx->exec_codes;
		exec_codes->proc_name = get_func_name(func->fn_oid);
		exec_codes->proc_namespace = get_namespace_name(namespace);
		func->exec_codes_valid = true;
		func->exec_codes = exec_codes;	/* ownership transfered */
	}
	PG_CATCH();
	{
		func->exec_codes_valid = false;
		free_exec_codes(codegen_ctx->exec_codes);
		codegen_ctx->exec_codes = NULL;
		destroy_template_context(walker);
		MemoryContextSwitchTo(oldcontext);
		PG_RE_THROW();
	}
	PG_END_TRY();

	destroy_template_context(walker);
	MemoryContextSwitchTo(oldcontext);
}
