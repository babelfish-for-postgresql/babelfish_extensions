/*-------------------------------------------------------------------------
 *
 * gramparse.h
 *		Shared definitions for the "raw" parser (flex and bison phases only)
 *
 * NOTE: this file is only meant to be included in the core parsing files,
 * ie, parser.c, gram.y, scan.l, and src/common/keywords.c.
 * Definitions that are needed outside the core parser should be in parser.h.
 *
 *
 * Portions Copyright (c) 1996-2019, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/include/parser/gramparse.h
 *
 *-------------------------------------------------------------------------
 */

#ifndef PGTSQL_GRAMPARSE_H
#define PGTSQL_GRAMPARSE_H

#include "src/backend_parser/scanner.h"

/*
 * NB: include gram-backend.h only AFTER including scanner.h, because scanner.h
 * is what #defines YYLTYPE.
 */
#include "src/backend_parser/gram-backend.h"

/*
 * NB: include gramparser.h after including gram-backend.h so that pgtsql token number is used properly
 */
#include "parser/gramparse.h"

typedef struct base_yy_extra_type pgtsql_base_yy_extra_type;

#undef pg_yyget_extra
#define pg_yyget_extra(yyscanner) (*((base_yy_extra_type **) (yyscanner)))

/* from parser.c */
extern int	pgtsql_base_yylex(YYSTYPE *lvalp, YYLTYPE *llocp,
					   core_yyscan_t yyscanner);

/* from pgtsql_gram.y */
extern void pgtsql_parser_init(pgtsql_base_yy_extra_type *yyext);
extern int pgtsql_base_yyparse(core_yyscan_t yyscanner);
extern int pgtsql_base_yydebug;

#endif							/* PGTSQL_GRAMPARSE_H */
