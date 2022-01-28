%{
	if (sql_dialect == SQL_DIALECT_TSQL)
		BEGIN(tsql);
	else
		BEGIN(INITIAL);
%}

<xc>{xcstop}	{
					if (yyextra->xcdepth <= 0)
						if (sql_dialect == SQL_DIALECT_TSQL)
							BEGIN(tsql);
						else
							BEGIN(INITIAL);
					else
						(yyextra->xcdepth)--;
				}

{xnstart}	{
					/* National character.
					 * We will pass this along as a normal character string,
					 * but preceded with an internally-generated "NCHAR".
					 */
					int		kwnum;

					SET_YYLLOC();
					yyless(1);	/* eat only 'n' this time */

					/* Cast national character to nvarchar for BABEL */
					if (sql_dialect == SQL_DIALECT_TSQL)
					{
						kwnum = ScanKeywordLookup("nvarchar",
												yyextra->keywordlist);
					}
					else
					{
						kwnum = ScanKeywordLookup("nchar",
												yyextra->keywordlist);
					}

					if (kwnum >= 0)
					{
						yylval->keyword = GetScanKeyword(kwnum,
														 yyextra->keywordlist);
						return yyextra->keyword_tokens[kwnum];
					}
					else
					{
						/* If nchar/varchar isn't a keyword, just return "n" */
						yylval->str = pstrdup("n");
						return IDENT;
					}
				}

{xbrstart}	{
					if (sql_dialect == SQL_DIALECT_PG)
					{
						SET_YYLLOC();
						return yytext[0];
					}
					else
					{
						SET_YYLLOC();
						BEGIN(xbr);
						startlit();
					}
				}

<xbr>{xbrinside}	{
					addlit(yytext, yyleng, yyscanner);
				}

<xbr>{xbrstop}	{
					char *ident;

					BEGIN(INITIAL);
					if (yyextra->literallen == 0)
						yyerror("zero-length delimited identifier");
					ident = litbufdup(yyscanner);
					if (yyextra->literallen >= NAMEDATALEN)
						truncate_identifier(ident, yyextra->literallen, true);
					yylval->str = ident;
					/* BABEL-1802 We removed definition of sys.smallint in order
					 * to support Dotnet client, but it also breaks [smallint] which
					 * used to be the identifier/domain sys.smallint. Workaround it
					 * here by checking for smallint inside a bracket and directly
					 * return the token */
					if (strcmp(yylval->str, "smallint") == 0)
						return SMALLINT;
					else
						return IDENT;
				}

<xbr>{xddouble}	{
					addlitchar('"', yyscanner);
				}

<xbr><<EOF>>		{ yyerror("unterminated quoted identifier"); }

<tsql>{tsql_atat}	{
					SET_YYLLOC();
					return TSQL_ATAT;
				}

<tsql>{tsql_money}	{
					SET_YYLLOC();
					yylval->str = pstrdup(yytext+1); /* stripping currency symbol */
					return FCONST;
				}

<tsql>{tsql_hex}	{
					SET_YYLLOC();
					yylval->str = pstrdup(yytext);
					return TSQL_XCONST;
				}

<tsql>{tsql_ident}	{
					int kwnum;
					char *ident;

					SET_YYLLOC();

					/* Is it a keyword? */
					kwnum = ScanKeywordLookup(yytext,
											  yyextra->keywordlist);
					if (kwnum >= 0)
					{
						yylval->keyword = GetScanKeyword(kwnum,
											yyextra->keywordlist);
						return yyextra->keyword_tokens[kwnum];
					}

					/*
					 * No.  Convert the identifier to lower case, and truncate
					 * if necessary.
					 */
					ident = downcase_truncate_identifier(yytext, yyleng, true);
					yylval->str = ident;
					return IDENT;
				}

<tsql>{tsql_ttname}	{
					SET_YYLLOC();
					yylval->str = pstrdup(yytext);
					return IDENT;
				}

<tsql>{tsql_pg_cast} {
					int kwnum;
					char *ident;

					yyless(yyleng -2);
					SET_YYLLOC();

					/* Is it a keyword? */
					kwnum = ScanKeywordLookup(yytext,
											  yyextra->keywordlist);
					if (kwnum >= 0)
					{
						yylval->keyword = GetScanKeyword(kwnum,
											yyextra->keywordlist);
						return yyextra->keyword_tokens[kwnum];
					}

					/*
					 * No.  Convert the identifier to lower case, and truncate
					 * if necessary.
					 */
					ident = downcase_truncate_identifier(yytext, yyleng, true);
					yylval->str = ident;
					return IDENT;
				}

<tsql>{tsql_label}	{
					char *ident;
					SET_YYLLOC();
					yylval->str = pstrdup(yytext);
					ident = downcase_truncate_identifier(yytext, yyleng, true);
					yylval->str = ident;
					return TSQL_LABEL;
				}

<tsql>{tsql_identifier}	{
					int			kwnum;
					char	   *ident;

					SET_YYLLOC();

					/* Is it a keyword? */
					kwnum = ScanKeywordLookup(yytext,
											  yyextra->keywordlist);
					if (kwnum >= 0)
					{
						yylval->keyword = GetScanKeyword(kwnum,
														 yyextra->keywordlist);
						switch(yyextra->keyword_tokens[kwnum])
						{
							case TSQL_CERTIFICATE:
							case TSQL_CHECK_EXPIRATION:
							case TSQL_CHECK_POLICY:
							case TSQL_CHOOSE:
							case TSQL_CLUSTERED:
							case TSQL_COLUMNSTORE:
							case TSQL_DATEADD:
							case TSQL_DATEDIFF:
							case TSQL_DATENAME:
							case TSQL_DATEPART:
							case TSQL_D:
							case TSQL_DAYOFYEAR:
							case TSQL_DD:
							case TSQL_DEFAULT_DATABASE:
							case TSQL_DEFAULT_LANGUAGE:
							case TSQL_DW:
							case TSQL_DY:
							case TSQL_HASHED:
							case TSQL_HH:
							case TSQL_ISO_WEEK:
							case TSQL_ISOWK:
							case TSQL_ISOWW:
							case TSQL_LOGIN:
							case TSQL_M:
							case TSQL_MCS:
							case TSQL_MICROSECOND:
							case TSQL_MILLISECOND:
							case TSQL_MM:
							case TSQL_MS:
							case TSQL_MUST_CHANGE:
							case TSQL_N:
							case TSQL_NONCLUSTERED:
							case TSQL_NANOSECOND:
							case TSQL_NS:
							case TSQL_OLD_PASSWORD:
							case TSQL_PERSISTED:
							case TSQL_Q:
							case TSQL_QQ:
							case TSQL_QUARTER:
							case TSQL_READONLY:
							case TSQL_REPLICATION:
							case TSQL_ROWGUIDCOL:
							case TSQL_S:
							case TSQL_SAVE:
							case TSQL_SS:
							case TSQL_SUBSTRING:
							case TSQL_TRAN:
							case TSQL_TZ:
							case TSQL_TEXTIMAGE_ON:
							case TSQL_TZOFFSET:
							case TSQL_WEEK:
							case TSQL_WEEKDAY:
							case TSQL_WK:
							case TSQL_WW:
							case TSQL_YY:
							case TSQL_YYYY:
							case TSQL_TRY_CAST:
							case TSQL_CONVERT:
							case TSQL_TRY_CONVERT:
							case TSQL_PARSE:
							case TSQL_TRY_PARSE:
							case TSQL_TOP:
							case TSQL_PERCENT:
							case TSQL_CALLER:
							case TSQL_OUTPUT:
							case TSQL_SCHEMABINDING:
							case TSQL_EXEC:
							case TSQL_RAW:
							case TSQL_AUTO:
							case TSQL_EXPLICIT:
							case TSQL_PATH:
							case TSQL_BASE64:
							case TSQL_ROOT:
							case TSQL_PROC:
							case TSQL_IIF:
							case TSQL_NOCHECK:
							case TSQL_NOLOCK:
							case TSQL_READUNCOMMITTED:
							case TSQL_UPDLOCK:
							case TSQL_REPEATABLEREAD:
							case TSQL_READCOMMITTED:
							case TSQL_TABLOCK:
							case TSQL_TABLOCKX:
							case TSQL_PAGLOCK:
							case TSQL_ROWLOCK:
							case TSQL_READPAST:
							case TSQL_XLOCK:
							case TSQL_NOEXPAND:
							case TSQL_SID:
							case TSQL_WINDOWS:
								/* Only a keyword in tsql */
								if (sql_dialect == SQL_DIALECT_TSQL)
									return yyextra->keyword_tokens[kwnum];
								break;

							case BIT:
							case VARCHAR:
							case NCHAR:
							case OPTIONS:
								/* Only a keyword in postgres */
								if (sql_dialect == SQL_DIALECT_PG)
									return yyextra->keyword_tokens[kwnum];
								break;
							case OUT_P:
								if (sql_dialect == SQL_DIALECT_TSQL)
									return TSQL_OUT;
								else
									return OUT_P;
							case ISNULL:
								if (sql_dialect == SQL_DIALECT_TSQL)
									return TSQL_ISNULL;
								else
									return ISNULL;
							case VALUES:
								if (sql_dialect == SQL_DIALECT_TSQL)
									return TSQL_VALUES;
								else
									return VALUES;
							case CHARACTER:
							case CHAR_P:
								if (sql_dialect == SQL_DIALECT_TSQL)
								{
									/*
									 * Without this, gram.y puts 'pg_catalog.bpchar' explicitly,
									 * so there will be no chance to lookup the search path
									 */
									yylval->str = pstrdup("bpchar");
									return IDENT;
								}
								else
								{
									return yyextra->keyword_tokens[kwnum];
								}
							case TSQL_NVARCHAR:
								if (sql_dialect == SQL_DIALECT_TSQL)
								{
									yylval->str = pstrdup("nvarchar");
									return IDENT;
								}
								break;
							default:
								return yyextra->keyword_tokens[kwnum];
						}
					}

					/*
					 * No.  Convert the identifier to lower case, and truncate
					 * if necessary.
					 */
					ident = downcase_truncate_identifier(yytext, yyleng, true);
					yylval->str = ident;
					return IDENT;
				}
