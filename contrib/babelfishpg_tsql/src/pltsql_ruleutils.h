/*
 *
 * pltsql_ruleutils.h
 *	  Declarations for pltsql_ruleutils.h
 *
 */

#ifndef PLTSQL_RULEUTILS_H
#define PLTSQL_RULEUTILS_H

#include "nodes/nodes.h"
#include "nodes/parsenodes.h"
#include "nodes/pg_list.h"

struct Plan;					/* avoid including plannodes.h here */
struct PlannedStmt;

extern char *tsql_get_constraintdef_command(Oid constraintId);

#endif							/* PLTSQL_RULEUTILS_H */

