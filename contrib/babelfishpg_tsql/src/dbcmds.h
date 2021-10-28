#ifndef DBCMDS_H
#define DBCMDS_H

#include "nodes/parsenodes.h"
extern Oid create_bbf_db(ParseState *pstate, const CreatedbStmt *stmt);
extern void drop_bbf_db(const char *dbname, bool missing_ok, bool force_drop);

#endif
