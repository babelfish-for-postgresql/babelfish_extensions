#ifndef ITERATIVE_EXEC_H
#define ITERATIVE_EXEC_H
#include "dynavec.h"

/*
 *  Execution Code
 *  exec_codes : sequence of executable nodes
 *      filled by codegen, mostly copy leaves nodes from parse tree
 *      life cycle of these copied nodes are identical to parse tree
 *      memory will be deallocated by tree free functions
 *      exec_codes only reclaim space for the vector
 */

typedef struct ExecCodes
{
    DynaVec *codes;

    char * proc_namespace;
    char * proc_name;
} ExecCodes;

#define TRACE_EXEC_CODES   0x0001
#define TRACE_EXEC_COUNTS  0x0003  /* Must combine trace codes with hit counts */
#define TRACE_EXEC_TIME    0x0005  /* Must combine trace codes with exec time */

typedef struct ExecConfig
{
    uint64_t trace_mode;
} ExecConfig_t;

extern int exec_stmt_iterative(PLtsql_execstate *estate, ExecCodes *exec_codes,
                               ExecConfig_t *config);
extern void free_exec_codes(ExecCodes *exec_codes);

extern bool is_recursive_trigger(PLtsql_execstate *estate);

#endif  /* EXECUTOR_H */
