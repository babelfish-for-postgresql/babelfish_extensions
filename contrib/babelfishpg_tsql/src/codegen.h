#ifndef CODEGEN_H
#define CODEGEN_H
#include "pltsql.h"
#include "compile_context.h"

void		gen_exec_code(PLtsql_function *func, CompileContext *cmpl_ctx);

#endif							/* CODEGEN_H */
