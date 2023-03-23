#include "postgres.h"
#include "compile_context.h"

CompileContext *
create_compile_context(void)
{
	CompileContext *cmpl_ctx = palloc(sizeof(CompileContext));
	HASHCTL		hashCtl;

	/* stmt scope map */
	MemSet(&hashCtl, 0, sizeof(hashCtl));
	hashCtl.keysize = sizeof(PLtsql_stmt *);
	hashCtl.entrysize = sizeof(ScopeContext);
	hashCtl.hcxt = CurrentMemoryContext;
	cmpl_ctx->stmt_scope_context = hash_create("Stmt to scope context mapping",
											   16,	/* initial hashmap size */
											   &hashCtl,
											   HASH_ELEM | HASH_CONTEXT | HASH_BLOBS);

	/* label stmt map */
	MemSet(&hashCtl, 0, sizeof(hashCtl));
	hashCtl.keysize = NAMEDATALEN;
	hashCtl.entrysize = sizeof(LabelStmtEntry);
	hashCtl.hcxt = CurrentMemoryContext;
	cmpl_ctx->label_stmt_map = hash_create("Label to stmt mapping",
										   16,	/* initial hashmap size */
										   &hashCtl,
										   HASH_ELEM | HASH_STRINGS | HASH_CONTEXT);	/* string comp */

	return cmpl_ctx;
}

void
destroy_compile_context(CompileContext *cmpl_ctx)
{
	HASH_SEQ_STATUS status;
	ScopeContext *scope;

	/* destroy scope context */
	hash_seq_init(&status, cmpl_ctx->stmt_scope_context);
	while ((scope = (ScopeContext *) hash_seq_search(&status)) != NULL)
	{
		destroy_vector(scope->nesting_trycatch_infos);
		destroy_vector(scope->nesting_loops);
	}
	hash_destroy(cmpl_ctx->stmt_scope_context);
	hash_destroy(cmpl_ctx->label_stmt_map);
	pfree(cmpl_ctx);
}
