#ifndef STMT_WALKER_H
#define STMT_WALKER_H
#include "pltsql.h"
#include "pltsql-2.h"
#include "utils/hsearch.h"
#include "dynavec.h"

/***********************************************************************************
 *                     PLtsql parse tree walking support
 **********************************************************************************/

/* Walker Function */
typedef bool (*WalkerFunc) (PLtsql_stmt *stmt, void *context);

/* Walker */
bool stmt_walker(PLtsql_stmt *stmt, WalkerFunc walker, void *context);


/***********************************************************************************
 *                 General Walker Function and Template Context 
 **********************************************************************************/

/*
 *  Simple algorithms handling only a few types of nodes could rely on above APIs.
 *  Algorithms handling more types could consider using following general walker function
 *  and template context to further simplify the implementation
 *  
 *  Walker_context *mycontext = make_context_template();
 *
 *  // 1. define actions 
 *  mycontext->if_act      = &my_if_action;
 *  .....
 *  mycontext->label_act   = &mylabel_action;
 *  mycontext->default_act = &my_default_action;  // optional, do nothing if unspecified
 *
 *  // 2. add extra context
 *  ExtraContext *extra_context = create_extra_context();
 *  mycontext->extra_ctx = extra_context;
 *  mycontext->destroy_extra_ctx = &destroy_extra_context;  // will be called when destorying the template
 *
 *  // 3. go
 *  general_walker_func(stmt, mycontext);
 */

/* actions associated with each stmt */
typedef struct Walker_context Walker_context;

typedef bool (*Stmt_default_act) 
    (Walker_context *ctx, PLtsql_stmt *stmt);

#define ACTION_SIGNITURE(type) \
    (Walker_context *ctx, PLtsql_stmt_##type *stmt)

typedef bool (*Stmt_block_act) ACTION_SIGNITURE(block);
typedef bool (*Stmt_assign_act) ACTION_SIGNITURE(assign);
typedef bool (*Stmt_if_act) ACTION_SIGNITURE(if);
typedef bool (*Stmt_while_act) ACTION_SIGNITURE(while);
typedef bool (*Stmt_exit_act) ACTION_SIGNITURE(exit);
typedef bool (*Stmt_return_act) ACTION_SIGNITURE(return);
typedef bool (*Stmt_return_query_act) ACTION_SIGNITURE(return_query);
typedef bool (*Stmt_execsql_act) ACTION_SIGNITURE(execsql);
typedef bool (*Stmt_open_act) ACTION_SIGNITURE(open);
typedef bool (*Stmt_fetch_act) ACTION_SIGNITURE(fetch);
typedef bool (*Stmt_close_act) ACTION_SIGNITURE(close);
typedef bool (*Stmt_commit_act) ACTION_SIGNITURE(commit);
typedef bool (*Stmt_rollback_act) ACTION_SIGNITURE(rollback);

	/* TSQL-only statement types follow */
typedef bool (*Stmt_goto_act) ACTION_SIGNITURE(goto);
typedef bool (*Stmt_print_act) ACTION_SIGNITURE(print);
typedef bool (*Stmt_init_act) ACTION_SIGNITURE(init);
typedef bool (*Stmt_query_set_act) ACTION_SIGNITURE(query_set);
typedef bool (*Stmt_try_catch_act) ACTION_SIGNITURE(try_catch);
typedef bool (*Stmt_push_result_act) ACTION_SIGNITURE(push_result);
typedef bool (*Stmt_exec_act) ACTION_SIGNITURE(exec);
typedef bool (*Stmt_exec_batch_act) ACTION_SIGNITURE(exec_batch);
typedef bool (*Stmt_exec_sp_act) ACTION_SIGNITURE(exec_sp);
typedef bool (*Stmt_decl_table_act) ACTION_SIGNITURE(decl_table);
typedef bool (*Stmt_return_table_act) ACTION_SIGNITURE(return_query);
typedef bool (*Stmt_deallocate_act) ACTION_SIGNITURE(deallocate);
typedef bool (*Stmt_decl_cursor_act) ACTION_SIGNITURE(decl_cursor);
typedef bool (*Stmt_label_act) ACTION_SIGNITURE(label);
typedef bool (*Stmt_raiserror_act) ACTION_SIGNITURE(raiserror);
typedef bool (*Stmt_throw_act) ACTION_SIGNITURE(throw);
typedef bool (*Stmt_usedb_act) ACTION_SIGNITURE(usedb);
typedef bool (*Stmt_insert_bulk_act) ACTION_SIGNITURE(insert_bulk);

    /* TSQL-only executable node */
typedef bool (*Stmt_init_vars) ACTION_SIGNITURE(init_vars);
typedef bool (*Stmt_save_ctx) ACTION_SIGNITURE(save_ctx);
typedef bool (*Stmt_restore_ctx_full) ACTION_SIGNITURE(restore_ctx_full);
typedef bool (*Stmt_restore_ctx_partial) ACTION_SIGNITURE(restore_ctx_partial);

/* actions associated with each stmt */
typedef void (*Context_destroyer) (void *extra_ctx);

typedef struct Walker_context
{
    /* Action associated to each stmt */
    Stmt_default_act          default_act;
    
    Stmt_block_act            block_act;
    Stmt_assign_act           assign_act;
    Stmt_if_act               if_act;
    Stmt_while_act            while_act;
    Stmt_exit_act             exit_act;
    Stmt_return_act           return_act;
    Stmt_return_query_act     return_query_act;
    Stmt_execsql_act          execsql_act;
    Stmt_open_act             open_act;
    Stmt_fetch_act            fetch_act;
    Stmt_close_act            close_act;
	Stmt_commit_act			  commit_act;
	Stmt_rollback_act		  rollback_act;

	/* TSQL-only statement types follow */
    Stmt_goto_act             goto_act;
    Stmt_print_act            print_act;
    Stmt_init_act             init_act;
    Stmt_query_set_act       query_set_act;
    Stmt_try_catch_act        try_catch_act;
    Stmt_push_result_act      push_result_act;
    Stmt_exec_act             exec_act;
    Stmt_exec_batch_act       exec_batch_act;
    Stmt_exec_sp_act          exec_sp_act;
    Stmt_decl_table_act       decl_table_act;
    Stmt_return_table_act     return_table_act;
    Stmt_deallocate_act       deallocate_act;
    Stmt_decl_cursor_act      decl_cursor_act;
    Stmt_label_act            label_act;
	Stmt_raiserror_act		  raiserror_act;
	Stmt_throw_act			  throw_act;
	Stmt_usedb_act            usedb_act;
    Stmt_insert_bulk_act      insert_bulk_act;

    /* TSQL-only executable node */
    Stmt_init_vars            init_vars_act;
    Stmt_save_ctx             save_ctx_act;
    Stmt_restore_ctx_full     restore_ctx_full_act;
    Stmt_restore_ctx_partial  restore_ctx_partial_act;

    /* external pointer for extensions */
    void                      *extra_ctx;
    Context_destroyer         destroy_extra_ctx;

} Walker_context;

/*
 *  General walker function
 */
bool general_walker_func(PLtsql_stmt *stmt, void *context);

/*
 *  Get a template context
 *  Property storage is initialized
 */
Walker_context *make_template_context(void);

/*
 *  Destory template context and extra context if any
 */
void destroy_template_context(Walker_context *ctx);

#endif  /* STMT_WALKER_H */
