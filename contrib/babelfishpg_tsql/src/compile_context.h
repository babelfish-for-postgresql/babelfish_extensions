#ifndef STMT_PROPERTIES_H
#define STMT_PROPERTIES_H

#include "dynavec.h"
#include "pltsql.h"
#include "pltsql-2.h"
#include "utils/hsearch.h"

/*
 *   Compilation Context
 *
 *   Note:
 *   Each sub-component should be able to independently manage its own runtiem information.
 *   E.g AnalyzerContext for analyzer, CodegenContext for codegen
 *   Compilation context provides a mechansim to pass information across components.
 *   It has longer life-cycle than component-wise context.
 */

typedef struct
{
	PLtsql_stmt *stmt;			/* stmt_try_catch */
	bool		in_try_block;	/* false if in catch block */
} TryCatchInfo;

typedef struct
{
	PLtsql_stmt *stmt;
	DynaVec    *nesting_trycatch_infos;
	DynaVec    *nesting_loops;
} ScopeContext;

typedef struct
{
	char		label[NAMEDATALEN];
	PLtsql_stmt_label *stmt;
} LabelStmtEntry;

typedef struct
{
	/* stmt wise scope info, stmt -> ScopeContext */
	HTAB	   *stmt_scope_context;

	/* label to stmt_label */
	HTAB	   *label_stmt_map;
} CompileContext;

CompileContext *create_compile_context(void);
void		destroy_compile_context(CompileContext *context);

#endif
