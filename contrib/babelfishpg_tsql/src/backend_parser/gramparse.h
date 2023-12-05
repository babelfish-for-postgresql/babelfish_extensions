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
 * NB: include gramparse.h after including gram-backend.h so that pgtsql token number is used properly
 * Community has made gramparse.h hidden, so we manually copy its declarations below.
 */
/*
 * The YY_EXTRA data that a flex scanner allows us to pass around.  Private
 * state needed for raw parsing/lexing goes here.
 */
typedef struct base_yy_extra_type
{
	/*
	 * Fields used by the core scanner.
	 */
	core_yy_extra_type core_yy_extra;

	/*
	 * State variables for base_yylex().
	 */
	bool		have_lookahead; /* is lookahead info valid? */
	int			lookahead_token;	/* one-token lookahead */
	core_YYSTYPE lookahead_yylval;	/* yylval for lookahead token */
	YYLTYPE		lookahead_yylloc;	/* yylloc for lookahead token */
	char	   *lookahead_end;	/* end of current token */
	char		lookahead_hold_char;	/* to be put back at *lookahead_end */

	/*
	 * State variables that belong to the grammar.
	 */
	List	   *parsetree;		/* final parse result is delivered here */
} base_yy_extra_type;

/*
 * In principle we should use yyget_extra() to fetch the yyextra field
 * from a yyscanner struct.  However, flex always puts that field first,
 * and this is sufficiently performance-critical to make it seem worth
 * cheating a bit to use an inline macro.
 */
#define pg_yyget_extra(yyscanner) (*((base_yy_extra_type **) (yyscanner)))


/* from parser.c */
extern int	base_yylex(YYSTYPE *lvalp, YYLTYPE *llocp,
					   core_yyscan_t yyscanner);

/* from gram.y */
extern void parser_init(base_yy_extra_type *yyext);
extern int	base_yyparse(core_yyscan_t yyscanner);

typedef struct base_yy_extra_type pgtsql_base_yy_extra_type;

#undef pg_yyget_extra
#define pg_yyget_extra(yyscanner) (*((base_yy_extra_type **) (yyscanner)))

/* from parser.c */
extern int	pgtsql_base_yylex(YYSTYPE *lvalp, YYLTYPE * llocp,
							  core_yyscan_t yyscanner);

/* from pgtsql_gram.y */
extern void pgtsql_parser_init(pgtsql_base_yy_extra_type *yyext);
extern int	pgtsql_base_yyparse(core_yyscan_t yyscanner);
extern int	pgtsql_base_yydebug;

#endif							/* PGTSQL_GRAMPARSE_H */
