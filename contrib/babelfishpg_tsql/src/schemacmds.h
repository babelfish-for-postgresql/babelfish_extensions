#ifndef PGTSQL_SCHEMACMDS_H
#define PGTSQL_SCHEMACMDS_H

#include "nodes/parsenodes.h"

extern void add_ns_ext_info(CreateSchemaStmt *stmt, const char *queryString, const char *orig_name);
extern void del_ns_ext_info(const char *schemaname);
extern void check_extra_schema_restrictions(Node *stmt);

#endif
