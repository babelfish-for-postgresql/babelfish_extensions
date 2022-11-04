/*-------------------------------------------------------------------------
 *
 * parser.c
 *		Main entry point/driver for PostgreSQL grammar
 *
 * Note that the grammar is not allowed to perform any table access
 * (since we need to be able to do basic parsing even while inside an
 * aborted transaction).  Therefore, the data structures returned by
 * the grammar are "raw" parsetrees that still need to be analyzed by
 * analyze.c and related files.
 *
 *
 * Portions Copyright (c) 1996-2019, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * IDENTIFICATION
 *	  src/backend/parser/parser.c
 *
 *-------------------------------------------------------------------------
 */

#include "postgres.h"

#include "parser/parser.h"

#include "src/backend_parser/gramparse.h"

#include "src/backend_parser/kwlist_d.h"
#include "src/pltsql.h"
#include "tcop/tcopprot.h"

int pgtsql_base_yydebug;

List *babelfishpg_tsql_raw_parser(const char *str, RawParseMode mode);

/*
 * raw_parser
 *		Given a query in string form, do lexical and grammatical analysis.
 *
 * Returns a list of raw (un-analyzed) parse trees.  The immediate elements
 * of the list are always RawStmt nodes.
 */
List *
babelfishpg_tsql_raw_parser(const char *str, RawParseMode mode)
{
	core_yyscan_t yyscanner;
	pgtsql_base_yy_extra_type yyextra;
	int			yyresult;
	List	*raw_parsetree_list;
	/* 
	 * parse identifiers case-insensitively if the database collation is CI_AS
	 */
	pltsql_case_insensitive_identifiers = tsql_is_server_collation_CI_AS();
	
	/* initialize the flex scanner */
	yyscanner = pgtsql_scanner_init(str, &yyextra.core_yy_extra,
							 &pgtsql_ScanKeywords, pgtsql_ScanKeywordTokens);

	/* base_yylex() only needs us to initialize the lookahead token, if any */
	if (mode == RAW_PARSE_DEFAULT)
		yyextra.have_lookahead = false;
	else
	{
		/* this array is indexed by RawParseMode enum */
		static const int mode_token[] = {
			0,					/* RAW_PARSE_DEFAULT */
			MODE_TYPE_NAME,		/* RAW_PARSE_TYPE_NAME */
			MODE_PLPGSQL_EXPR,	/* RAW_PARSE_PLPGSQL_EXPR */
			MODE_PLPGSQL_ASSIGN1,	/* RAW_PARSE_PLPGSQL_ASSIGN1 */
			MODE_PLPGSQL_ASSIGN2,	/* RAW_PARSE_PLPGSQL_ASSIGN2 */
			MODE_PLPGSQL_ASSIGN3	/* RAW_PARSE_PLPGSQL_ASSIGN3 */
		};

		yyextra.have_lookahead = true;
		yyextra.lookahead_token = mode_token[mode];
		yyextra.lookahead_yylloc = 0;
		yyextra.lookahead_end = NULL;
	}

	/* initialize the bison parser */
	pgtsql_parser_init(&yyextra);

	/* Parse! */
	yyresult = pgtsql_base_yyparse(yyscanner);

	/* Clean up (release memory) */
	pgtsql_scanner_finish(yyscanner);

	if (yyresult)				/* error */
		return NIL;

	raw_parsetree_list = yyextra.parsetree;
	/* check if query string needs to be logged */
	if (raw_parsetree_list && check_log_statement(raw_parsetree_list) &&
	    pltsql_protocol_plugin_ptr && (*pltsql_protocol_plugin_ptr))
		(*pltsql_protocol_plugin_ptr)->stmt_needs_logging = true;

	return raw_parsetree_list;
}


/*
 * Intermediate filter between parser and core lexer (core_yylex in scan.l).
 *
 * This filter is needed because in some cases the standard SQL grammar
 * requires more than one token lookahead.  We reduce these cases to one-token
 * lookahead by replacing tokens here, in order to keep the grammar LALR(1).
 *
 * Using a filter is simpler than trying to recognize multiword tokens
 * directly in scan.l, because we'd have to allow for comments between the
 * words.  Furthermore it's not clear how to do that without re-introducing
 * scanner backtrack, which would cost more performance than this filter
 * layer does.
 *
 * The filter also provides a convenient place to translate between
 * the core_YYSTYPE and YYSTYPE representations (which are really the
 * same thing anyway, but notationally they're different).
 */
int
pgtsql_base_yylex(YYSTYPE *lvalp, YYLTYPE *llocp, core_yyscan_t yyscanner)
{
	pgtsql_base_yy_extra_type *yyextra = pg_yyget_extra(yyscanner);
	int			cur_token;
	int			next_token;
	int			cur_token_length;
	YYLTYPE		cur_yylloc;

	/* Get next token --- we might already have it */
	if (yyextra->have_lookahead)
	{
		cur_token = yyextra->lookahead_token;
		lvalp->core_yystype = yyextra->lookahead_yylval;
		*llocp = yyextra->lookahead_yylloc;
		if (yyextra->lookahead_end)
			*(yyextra->lookahead_end) = yyextra->lookahead_hold_char;
		yyextra->have_lookahead = false;
	}
	else
		cur_token = pgtsql_core_yylex(&(lvalp->core_yystype), llocp, yyscanner);

	/*
	 * If this token isn't one that requires lookahead, just return it.  If it
	 * does, determine the token length.  (We could get that via strlen(), but
	 * since we have such a small set of possibilities, hardwiring seems
	 * feasible and more efficient.)
	 */
	switch (cur_token)
	{
		case NOT:
			cur_token_length = 3;
			break;
		case NULLS_P:
			cur_token_length = 5;
			break;
		case WITH:
			cur_token_length = 4;
			break;
		case UPDATE:
			cur_token_length = 6;
			break;
		case FOR:
			cur_token_length = 3;
			break;
		case '(':
			cur_token_length = 1;
			break;
		case SERVER:
			cur_token_length = 6;
			break;
		case CROSS:
			cur_token_length = 5;
			break;
		case OUTER_P:
			cur_token_length = 5;
			break;
		default:
			return cur_token;
	}

	/*
	 * Identify end+1 of current token.  core_yylex() has temporarily stored a
	 * '\0' here, and will undo that when we call it again.  We need to redo
	 * it to fully revert the lookahead call for error reporting purposes.
	 */
	yyextra->lookahead_end = yyextra->core_yy_extra.scanbuf +
		*llocp + cur_token_length;
	Assert(*(yyextra->lookahead_end) == '\0');

	/*
	 * Save and restore *llocp around the call.  It might look like we could
	 * avoid this by just passing &lookahead_yylloc to core_yylex(), but that
	 * does not work because flex actually holds onto the last-passed pointer
	 * internally, and will use that for error reporting.  We need any error
	 * reports to point to the current token, not the next one.
	 */
	cur_yylloc = *llocp;

	/* Get next token, saving outputs into lookahead variables */
	next_token = pgtsql_core_yylex(&(yyextra->lookahead_yylval), llocp, yyscanner);
	yyextra->lookahead_token = next_token;
	yyextra->lookahead_yylloc = *llocp;

	*llocp = cur_yylloc;

	/* Now revert the un-truncation of the current token */
	yyextra->lookahead_hold_char = *(yyextra->lookahead_end);
	*(yyextra->lookahead_end) = '\0';

	yyextra->have_lookahead = true;

	/* Replace cur_token if needed, based on lookahead */
	switch (cur_token)
	{
		case NOT:
			/* Replace NOT by NOT_LA if it's followed by BETWEEN, IN, etc */
			switch (next_token)
			{
				case BETWEEN:
				case IN_P:
				case LIKE:
				case ILIKE:
				case SIMILAR:
					cur_token = NOT_LA;
					break;
			}
			break;

		case NULLS_P:
			/* Replace NULLS_P by NULLS_LA if it's followed by FIRST or LAST */
			switch (next_token)
			{
				case FIRST_P:
				case LAST_P:
					cur_token = NULLS_LA;
					break;
			}
			break;
		case UPDATE:
			switch (next_token)
			{
				case '(':
					cur_token = UPDATE_paren;
				break;
			}
			break;
		case WITH:
			/*
			 * Replace WITH by WITH_LA if it's followed by TIME or ORDINALITY
			 * Replace WITH by WITH_paren if it's followed by '('
			 */
			switch (next_token)
			{
				case TIME:
				case ORDINALITY:
					cur_token = WITH_LA;
					break;
				case '(':
					cur_token = WITH_paren;
					break;
			}
			break;
		case '(':
			switch (next_token)
			{
				case TSQL_NOLOCK:
				case TSQL_READUNCOMMITTED:
				case TSQL_UPDLOCK:
				case TSQL_REPEATABLEREAD:
				case SERIALIZABLE:
				case TSQL_READCOMMITTED:
				case TSQL_TABLOCK:
				case TSQL_TABLOCKX:
				case TSQL_PAGLOCK:
				case TSQL_ROWLOCK:
				case NOWAIT:
				case TSQL_READPAST:
				case TSQL_XLOCK:
				case SNAPSHOT:
				case TSQL_NOEXPAND:
					cur_token = TSQL_HINT_START_BRACKET;
				default:
					break;
			}
			break;
		case FOR:
			switch (next_token)
				{
				case XML_P:
					cur_token = TSQL_FOR;
					break;
				
				case TSQL_JSON:
					cur_token = TSQL_FOR;
					break;
			}
			break;
		case SERVER:
			if (next_token == ROLE)
				cur_token = TSQL_SERVER;
			break;
		case CROSS:
			if (next_token == TSQL_APPLY)
				cur_token = TSQL_CROSS;
			break;
		case OUTER_P:
			if (next_token == TSQL_APPLY)
				cur_token = TSQL_OUTER;
			break;
		default:
			break;
	}

	return cur_token;
}
