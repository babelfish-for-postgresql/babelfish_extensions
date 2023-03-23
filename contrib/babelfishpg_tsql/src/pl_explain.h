#ifndef PL_EXPLAIN_H
#define PL_EXPLAIN_H

#include "executor/execdesc.h"

extern bool pltsql_explain_only;
extern bool pltsql_explain_analyze;
extern bool pltsql_explain_verbose;
extern bool pltsql_explain_costs;
extern bool pltsql_explain_settings;
extern bool pltsql_explain_buffers;
extern bool pltsql_explain_wal;
extern bool pltsql_explain_timing;
extern bool pltsql_explain_summary;
extern int	pltsql_explain_format;

extern bool is_explain_analyze_mode(void);
extern void increment_explain_indent(void);
extern void decrement_explain_indent(void);
extern void append_explain_info(QueryDesc *queryDesc, const char *queryString);
extern void set_explain_database(const char *db_name);
extern const char *get_explain_database(void);

/*
 * expr will be a PLtsql_expr * declared as void to avoid including the pltsql.h file
 * in this file
*/
extern const char *strip_select_from_expr(void *expr);


#endif							/* PL_EXPLAIN_H */
