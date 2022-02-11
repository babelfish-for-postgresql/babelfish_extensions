/*
 * Please note that this file is appended to gram.y so that existing PG backend parser rule can be extended
 * because if there are multiple rules with the same name then they can be ORed into one rule.
 * i.e.
 *  ruleX: XXX {}
 *  ruleX: XXX_TSQL {}
 * <=>
 *  ruleX: XXX {}
 *       | XXX_TSQL {}
 */

/* Start of exsiting grammar rule in gram.y */

stmtblock:
			DIALECT_TSQL tsql_stmtmulti
				{
					pg_yyget_extra(yyscanner)->parsetree = $2;
				}
		;

tsql_CreateLoginStmt:
			CREATE TSQL_LOGIN RoleId FROM tsql_login_sources
				{
					CreateRoleStmt *n = makeNode(CreateRoleStmt);
					n->stmt_type = ROLESTMT_USER;
					n->role = $3;
					n->options = list_make1(makeDefElem("islogin",
											(Node *)makeInteger(true),
											@1)); /* Must be first */
					n->options = lappend(n->options,
										 makeDefElem("createdb",
													 (Node *)makeInteger(true),
													 @1));
					n->options = lappend(n->options,
										 makeDefElem("createrole",
													 (Node *)makeInteger(true),
													 @1));
					n->options = lappend(n->options,
										 makeDefElem("inherit",
													 (Node *)makeInteger(true),
													 @1));
					n->options = lappend(n->options,
										 makeDefElem("canlogin",
													 (Node *)makeInteger(true),
													 @1));
					$$ = (Node *)n;
				}
			| CREATE TSQL_LOGIN RoleId tsql_login_option_list1
				{
					CreateRoleStmt *n = makeNode(CreateRoleStmt);
					n->stmt_type = ROLESTMT_USER;
					n->role = $3;
					n->options = list_make1(makeDefElem("islogin",
											(Node *)makeInteger(true),
											@1)); /* Must be first */
					n->options = lappend(n->options,
										 makeDefElem("createdb",
													 (Node *)makeInteger(true),
													 @1));
					n->options = lappend(n->options,
										 makeDefElem("createrole",
													 (Node *)makeInteger(true),
													 @1));
					n->options = lappend(n->options,
										 makeDefElem("inherit",
													 (Node *)makeInteger(true),
													 @1));
					n->options = lappend(n->options,
										 makeDefElem("canlogin",
													 (Node *)makeInteger(true),
													 @1));
					n->options = list_concat(n->options, $4);
					$$ = (Node *)n;
				}
		;

tsql_login_option_list1:
			WITH PASSWORD '=' tsql_nchar opt_must_change
				{
					$$ = list_make1(makeDefElem("password", $4, @1));
				}
			| WITH PASSWORD '=' tsql_nchar opt_must_change tsql_login_option_list2
				{
					$$ = lcons(makeDefElem("password", $4, @1), $6);
				}
			| WITH PASSWORD '=' TSQL_XCONST TSQL_HASHED opt_must_change
				{
					$$ = list_make1(makeDefElem("password", NULL, @1));
				}
			| WITH PASSWORD '=' TSQL_XCONST TSQL_HASHED opt_must_change tsql_login_option_list2
				{
					$$ = lcons(makeDefElem("password", NULL, @1), $7);
				}
		;

tsql_login_option_list2:
			',' tsql_login_option_elem
				{
					if ($2 != NULL)
						$$ = list_make1($2);
					else
						$$ = NIL;
				}
			| tsql_login_option_list2 ',' tsql_login_option_elem
				{
					if ($3 != NULL)
						$$ = lappend($1, $3);
				}
		;

tsql_login_option_elem:
			TSQL_SID '=' TSQL_XCONST
				{
					$$ = NULL;
				}
			| TSQL_DEFAULT_DATABASE '=' NonReservedWord
				{
					$$ = makeDefElem("default_database",
									 (Node *)makeString($3),
									 @1);
				}
			| TSQL_DEFAULT_LANGUAGE '=' NonReservedWord
				{
					$$ = NULL;
				}
			| TSQL_CHECK_EXPIRATION '=' opt_boolean_or_string
				{
					$$ = NULL;
				}
			| TSQL_CHECK_POLICY '=' opt_boolean_or_string
				{
					$$ = NULL;
				}
			| TSQL_CREDENTIAL '=' NonReservedWord
				{
					$$ = NULL;
				}
		;

opt_must_change:
			TSQL_MUST_CHANGE
			| /*EMPTY*/
		;

tsql_login_sources:
			TSQL_WINDOWS
			| TSQL_WINDOWS WITH tsql_windows_options_list
			| TSQL_CERTIFICATE NonReservedWord
			| ASYMMETRIC KEY NonReservedWord
		;

tsql_windows_options_list:
			tsql_windows_options
			| tsql_windows_options_list ',' tsql_windows_options
		;

tsql_windows_options:
			TSQL_DEFAULT_DATABASE '=' NonReservedWord
			| TSQL_DEFAULT_LANGUAGE '=' NonReservedWord
		;

CreateUserStmt:
			CREATE USER RoleId tsql_without_login opt_with OptRoleList
				{
					CreateRoleStmt *n = makeNode(CreateRoleStmt);
					n->stmt_type = ROLESTMT_USER;
					n->role = $3;
					n->options = $6;
					if ($4)
					{
						if ($6)
						{
							n->options = lappend(n->options,
								list_make1(makeDefElem("canlogin", (Node *)makeInteger(false), @1)));
						}
						else
						{
							n->options = list_make1(makeDefElem("canlogin", (Node *)makeInteger(false), @1));
						}
					}
					$$ = (Node *)n;
				}
		;

tsql_AlterLoginStmt:
			ALTER TSQL_LOGIN RoleSpec tsql_enable_disable
				{
					AlterRoleStmt *n = makeNode(AlterRoleStmt);
					n->role = $3;
					n->action = +1;	/* add, if there are members */
					n->options = list_make1(makeDefElem("islogin",
											(Node *)makeInteger(true),
											@1)); /* Must be first */
					if ($4)
						n->options = lappend(n->options,
											 makeDefElem("canlogin",
														 (Node *)makeInteger(true),
														 @1));
					else
						n->options = lappend(n->options,
											 makeDefElem("canlogin",
														 (Node *)makeInteger(false),
														 @1));
					$$ = (Node *)n;
				}
			| ALTER TSQL_LOGIN RoleSpec WITH tsql_alter_login_option_list
				{
					AlterRoleStmt *n = makeNode(AlterRoleStmt);
					n->role = $3;
					n->action = +1;	/* add, if there are members */
					n->options = list_make1(makeDefElem("islogin",
											(Node *)makeInteger(true),
											@1)); /* Must be first */
					if ($5 != NIL)
						n->options = list_concat(n->options, $5);
					$$ = (Node *)n;
				}
			| ALTER TSQL_LOGIN RoleSpec add_drop TSQL_CREDENTIAL NonReservedWord
				{
					AlterRoleStmt *n = makeNode(AlterRoleStmt);
					n->role = $3;
					n->action = +1;	/* add, if there are members */
					n->options = list_make1(makeDefElem("islogin",
											(Node *)makeInteger(true),
											@1)); /* Must be first */
					$$ = (Node *)n;
				}
		;

tsql_enable_disable:
			ENABLE_P
				{
					$$ = true;
				}
			| DISABLE_P
				{
					$$ = false;
				}
		;

tsql_alter_login_option_list:
			tsql_alter_login_option_elem
				{
					if ($1 != NULL)
						$$ = list_make1($1);
					else
						$$ = NIL;
				}
			| tsql_alter_login_option_list ',' tsql_alter_login_option_elem
				{
					if ($3 != NULL)
						$$ = lappend($1, $3);
				}
		;

tsql_alter_login_option_elem:
			PASSWORD '=' tsql_nchar tsql_alter_login_password_option1
				{
					$$ = makeDefElem("password", $3, @1);
				}
			| PASSWORD '=' TSQL_XCONST TSQL_HASHED tsql_alter_login_password_option1
				{
					$$ = makeDefElem("password", NULL, @1);
				}
			| TSQL_DEFAULT_DATABASE '=' NonReservedWord
				{
					$$ = makeDefElem("default_database",
									 (Node *)makeString($3),
									 @1);;
				}
			| TSQL_DEFAULT_LANGUAGE '=' NonReservedWord
				{
					$$ = NULL;
				}
			| NAME_P '=' RoleSpec
				{
					$$ = NULL;
				}
			| TSQL_CHECK_EXPIRATION '=' opt_boolean_or_string
				{
					$$ = NULL;
				}
			| TSQL_CHECK_POLICY '=' opt_boolean_or_string
				{
					$$ = NULL;
				}
			| TSQL_CREDENTIAL '=' NonReservedWord
				{
					$$ = NULL;
				}
			| NO TSQL_CREDENTIAL
				{
					$$ = NULL;
				}
		;

tsql_alter_login_password_option1:
			TSQL_OLD_PASSWORD '=' tsql_nchar
			| tsql_alter_login_password_option2_list
			| /*EMPTY*/
		;

tsql_alter_login_password_option2_list:
			tsql_alter_login_password_option2
			| tsql_alter_login_password_option2_list tsql_alter_login_password_option2
		;

tsql_alter_login_password_option2:
			TSQL_MUST_CHANGE
			| TSQL_UNLOCK
		;

tsql_DropLoginStmt:
			DROP TSQL_LOGIN role_list
				{
					DropRoleStmt *n = makeNode(DropRoleStmt);
					n->missing_ok = false;
					n->roles = $3;
					$$ = (Node *)n;
				}
		;

tsql_nchar:
			TSQL_NVARCHAR Sconst { $$ = (Node *)makeString($2); }
			| Sconst { $$ = (Node *)makeString($1); }
		;

AlterOptRoleElem:
			PASSWORD '=' Sconst
				{
					if (sql_dialect != SQL_DIALECT_TSQL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
								 parser_errposition(@2)));
					$$ = makeDefElem("password",
									 (Node *)makeString($3), @1);
				}
		;

alter_table_cmds: /* extend it allow to consume nullable (tsql_alter_table_cmd)
			/* alter_table_cmd */
			/* | alter_table_cmds ',' alter_table_cmd */
			tsql_alter_table_cmd { $$ = (($1 != NULL) ? list_make1($1) : NIL); }
			| alter_table_cmds ',' tsql_alter_table_cmd { $$ = (($3 != NULL) ? lappend($1, $3) : $1); }
		;

opt_reloptions:
			WITH_paren reloptions { $$ = $2; }
		;

PartitionBoundSpec:
			/* a HASH partition */
			FOR TSQL_VALUES WITH_paren '(' hash_partbound ')'
				{
					ListCell   *lc;
					PartitionBoundSpec *n = makeNode(PartitionBoundSpec);

					n->strategy = PARTITION_STRATEGY_HASH;
					n->modulus = n->remainder = -1;

					foreach (lc, $5)
					{
						DefElem    *opt = lfirst_node(DefElem, lc);

						if (strcmp(opt->defname, "modulus") == 0)
						{
							if (n->modulus != -1)
								ereport(ERROR,
										(errcode(ERRCODE_DUPLICATE_OBJECT),
										 errmsg("modulus for hash partition provided more than once"),
										 parser_errposition(opt->location)));
							n->modulus = defGetInt32(opt);
						}
						else if (strcmp(opt->defname, "remainder") == 0)
						{
							if (n->remainder != -1)
								ereport(ERROR,
										(errcode(ERRCODE_DUPLICATE_OBJECT),
										 errmsg("remainder for hash partition provided more than once"),
										 parser_errposition(opt->location)));
							n->remainder = defGetInt32(opt);
						}
						else
							ereport(ERROR,
									(errcode(ERRCODE_SYNTAX_ERROR),
									 errmsg("unrecognized hash partition bound specification \"%s\"",
											opt->defname),
									 parser_errposition(opt->location)));
					}

					if (n->modulus == -1)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("modulus for hash partition must be specified")));
					if (n->remainder == -1)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("remainder for hash partition must be specified")));

					n->location = @3;

					$$ = n;
				}
		;

CopyStmt:	COPY opt_binary qualified_name opt_column_list
			copy_from opt_program copy_file_name copy_delimiter WITH_paren
			copy_options where_clause
				{
					CopyStmt *n = makeNode(CopyStmt);
					n->relation = $3;
					n->query = NULL;
					n->attlist = $4;
					n->is_from = $5;
					n->is_program = $6;
					n->filename = $7;
					n->whereClause = $11;

					if (n->is_program && n->filename == NULL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("STDIN/STDOUT not allowed with PROGRAM"),
								 parser_errposition(@8)));

					if (!n->is_from && n->whereClause != NULL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("WHERE clause not allowed with COPY TO"),
								 parser_errposition(@11)));

					n->options = NIL;
					/* Concatenate user-supplied flags */
					if ($2)
						n->options = lappend(n->options, $2);
					if ($8)
						n->options = lappend(n->options, $8);
					if ($10)
						n->options = list_concat(n->options, $10);
					$$ = (Node *)n;
				}
			| COPY '(' PreparableStmt ')' TO opt_program
				copy_file_name WITH_paren copy_options
				{
					CopyStmt *n = makeNode(CopyStmt);
					n->relation = NULL;
					n->query = $3;
					n->attlist = NIL;
					n->is_from = false;
					n->is_program = $6;
					n->filename = $7;
					n->options = $9;

					if (n->is_program && n->filename == NULL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("STDIN/STDOUT not allowed with PROGRAM"),
								 parser_errposition(@5)));

					$$ = (Node *)n;
				}
		;

OptTableElementList:
			TableElementList ',' { $$ = $1; } /* For TSQL compatibility */
		;

columnDef:
			ColId TSQL_computed_column ColQualList
				{
					ColumnDef *n = makeNode(ColumnDef);

					if (sql_dialect != SQL_DIALECT_TSQL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
								 parser_errposition(@2)));

					TSQLInstrumentation(INSTR_TSQL_COMPUTED_COLUMN);
					n->colname = $1;

					/*
					 * For computed columns, user doesn't provide a datatype.
					 * But, PG expects a datatype.  Hence, we just assign a
					 * valid datatype temporarily.  Later, we'll evaluate
					 * expression to detect the actual datatype.
					 */
					n->typeName = makeTypeName("varchar");
					n->inhcount = 0;
					n->is_local = true;
					n->is_not_null = false;
					n->is_from_type = false;
					n->storage = 0;
					n->raw_default = NULL;
					n->cooked_default = NULL;
					n->collOid = InvalidOid;
					n->fdwoptions = NULL;
					n->location = @1;

					$3 = lappend($3, $2);

					SplitColQualList($3, &n->constraints, &n->collClause,
									 yyscanner);

					$$ = (Node *)n;
				}
		;

ColQualList: /* extend it allow to consume nullable (tsql_ColConstraint) */
			/* ColQualList ColConstraint */
			/* | EMPTY */
			ColQualList tsql_ColConstraint { $$ = (($2 != NULL) ? lappend($1, $2) : $1); }
		;
ConstraintElem:
			UNIQUE tsql_cluster '(' columnList ')' opt_c_include opt_definition OptConsTableSpace
				ConstraintAttributeSpec tsql_opt_on_filegroup
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_UNIQUE;
					n->location = @1;
					n->keys = $4;
					n->including = $6;
					n->options = $7;
					n->indexname = NULL;
					n->indexspace = $8;
					processCASbits($9, @9, "UNIQUE",
								   &n->deferrable, &n->initdeferred, NULL,
								   NULL, yyscanner);
					$$ = (Node *)n;
				}
			| UNIQUE tsql_cluster '(' columnListWithOptAscDesc ')' opt_c_include opt_definition OptConsTableSpace
				ConstraintAttributeSpec tsql_opt_on_filegroup
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_UNIQUE;
					n->location = @1;
					n->keys = $4;
					n->including = $6;
					n->options = $7;
					n->indexname = NULL;
					n->indexspace = $8;
					processCASbits($9, @9, "UNIQUE",
								   &n->deferrable, &n->initdeferred, NULL,
								   NULL, yyscanner);
					$$ = (Node *)n;
				}
			| UNIQUE '(' columnListWithOptAscDesc ')' opt_c_include opt_definition OptConsTableSpace
				ConstraintAttributeSpec tsql_opt_on_filegroup
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_UNIQUE;
					n->location = @1;
					n->keys = $3;
					n->including = $5;
					n->options = $6;
					n->indexname = NULL;
					n->indexspace = $7;
					processCASbits($8, @8, "UNIQUE",
								   &n->deferrable, &n->initdeferred, NULL,
								   NULL, yyscanner);
					$$ = (Node *)n;
				}
			| UNIQUE '(' columnList ')' opt_c_include opt_definition OptConsTableSpace
				ConstraintAttributeSpec tsql_on_filegroup
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_UNIQUE;
					n->location = @1;
					n->keys = $3;
					n->including = $5;
					n->options = $6;
					n->indexname = NULL;
					n->indexspace = $7;
					processCASbits($8, @8, "UNIQUE",
								   &n->deferrable, &n->initdeferred, NULL,
								   NULL, yyscanner);
					$$ = (Node *)n;
				}
			| UNIQUE tsql_cluster ExistingIndex ConstraintAttributeSpec
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_UNIQUE;
					n->location = @1;
					n->keys = NIL;
					n->including = NIL;
					n->options = NIL;
					n->indexname = $3;
					n->indexspace = NULL;
					processCASbits($4, @4, "UNIQUE",
								   &n->deferrable, &n->initdeferred, NULL,
								   NULL, yyscanner);
					$$ = (Node *)n;
				}
			| PRIMARY KEY tsql_cluster '(' columnList ')' opt_c_include opt_definition OptConsTableSpace
				ConstraintAttributeSpec tsql_opt_on_filegroup
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_PRIMARY;
					n->location = @1;
					n->keys = $5;
					n->including = $7;
					n->options = $8;
					n->indexname = NULL;
					n->indexspace = $9;
					processCASbits($10, @10, "PRIMARY KEY",
								   &n->deferrable, &n->initdeferred, NULL,
								   NULL, yyscanner);
					$$ = (Node *)n;
				}
			| PRIMARY KEY tsql_cluster '(' columnListWithOptAscDesc ')' opt_c_include opt_definition OptConsTableSpace
				ConstraintAttributeSpec tsql_opt_on_filegroup
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_PRIMARY;
					n->location = @1;
					n->keys = $5;
					n->including = $7;
					n->options = $8;
					n->indexname = NULL;
					n->indexspace = $9;
					processCASbits($10, @10, "PRIMARY KEY",
								   &n->deferrable, &n->initdeferred, NULL,
								   NULL, yyscanner);
					$$ = (Node *)n;
				}
			| PRIMARY KEY '(' columnListWithOptAscDesc ')' opt_c_include opt_definition OptConsTableSpace
				ConstraintAttributeSpec tsql_opt_on_filegroup
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_PRIMARY;
					n->location = @1;
					n->keys = $4;
					n->including = $6;
					n->options = $7;
					n->indexname = NULL;
					n->indexspace = $8;
					processCASbits($9, @9, "PRIMARY KEY",
								   &n->deferrable, &n->initdeferred, NULL,
								   NULL, yyscanner);
					$$ = (Node *)n;
				}
			| PRIMARY KEY '(' columnList ')' opt_c_include opt_definition OptConsTableSpace
				ConstraintAttributeSpec tsql_on_filegroup
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_PRIMARY;
					n->location = @1;
					n->keys = $4;
					n->including = $6;
					n->options = $7;
					n->indexname = NULL;
					n->indexspace = $8;
					processCASbits($9, @9, "PRIMARY KEY",
								   &n->deferrable, &n->initdeferred, NULL,
								   NULL, yyscanner);
					$$ = (Node *)n;
				}
			| PRIMARY KEY tsql_cluster ExistingIndex ConstraintAttributeSpec
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_PRIMARY;
					n->location = @1;
					n->keys = NIL;
					n->including = NIL;
					n->options = NIL;
					n->indexname = $4;
					n->indexspace = NULL;
					processCASbits($5, @5, "PRIMARY KEY",
								   &n->deferrable, &n->initdeferred, NULL,
								   NULL, yyscanner);
					$$ = (Node *)n;
				}
		;

OptWith:
			WITH_paren reloptions { $$ = $2; }
		;

OnCommitOption:
			OptFileGroup					{ $$ = ONCOMMIT_NOOP; }
			| OptFileGroup OptFileGroup		{ $$ = ONCOMMIT_NOOP; }
		;

DefineStmt:
			/*
			 * TSQL supports table type, and we handle it by creating a template
			 * table so that later when variables of this type are created, they
			 * are created like the template table.
			 */
			CREATE TYPE_P any_name AS TABLE '(' OptTableElementList ')'
				{
					CreateStmt *n = makeNode(CreateStmt);
					if (sql_dialect != SQL_DIALECT_TSQL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
								 parser_errposition(@1)));
					TSQLInstrumentation(INSTR_TSQL_CREATE_TEMP_TABLE);
					n->relation = makeRangeVarFromAnyNameForTableType($3, @3, yyscanner);
					n->tableElts = $7;
					n->inhRelations = NIL;
					n->partspec = NULL;
					n->ofTypename = NULL;
					n->constraints = NIL;
					n->options = NIL;
					n->oncommit = ONCOMMIT_NOOP;
					n->tablespacename = NULL;
					n->if_not_exists = false;
					n->tsql_tabletype = true;
					$$ = (Node *)n;
				}
			| CREATE TYPE_P any_name FROM Typename
				{
					CreateDomainStmt *n = makeNode(CreateDomainStmt);
					n->domainname = $3;
					n->typeName = $5;
					n->constraints = NIL;

					$$ = (Node *)n;
				}
			| CREATE TYPE_P any_name FROM Typename NOT NULL_P
				{
					CreateDomainStmt *n = makeNode(CreateDomainStmt);
					Constraint *c = makeNode(Constraint);

					n->domainname = $3;
					n->typeName = $5;
					n->constraints = list_make1(c);

					c->contype = CONSTR_NOTNULL;
					c->location = @6;

					$$ = (Node *)n;

				}
			| CREATE TYPE_P any_name FROM Typename NULL_P
				{
					CreateDomainStmt *n = makeNode(CreateDomainStmt);
					Constraint *c = makeNode(Constraint);

					n->domainname = $3;
					n->typeName = $5;
					n->constraints = list_make1(c);

					c->contype = CONSTR_NULL;
					c->location = @6;

					$$ = (Node *)n;

				}
		;

func_arg:
			param_name func_type arg_class
				{
					FunctionParameter *n = makeNode(FunctionParameter);
					n->name = $1;
					n->argType = $2;
					n->mode = $3;
					n->defexpr = NULL;
					$$ = n;
				}
		;

arg_class:
			TSQL_OUT							{ $$ = FUNC_PARAM_OUT; }
			| TSQL_OUTPUT						{ $$ = FUNC_PARAM_INOUT; }
			| IN_P TSQL_OUT						{ $$ = FUNC_PARAM_INOUT; }
		;

/* Note: any simple identifier will be returned as a type name!
 * TSQL support for <table_option> and <index_option>:
 * CREATE TABLE... WITH (<table_option>)
 * CREATE INDEX... WITH (<index_option>)
 */
def_arg:	func_type tsql_on_ident_partitions_list			{ $$ = (Node *)$1; }
			| reserved_keyword tsql_paren_extra_relopt_list	{ $$ = (Node *)makeString(pstrdup($1)); }
			| NumericOnly tsql_ident			{ $$ = (Node *)$1; }
			| NONE tsql_on_ident_partitions_list		{ $$ = (Node *)makeString(pstrdup($1)); }
			| ROW tsql_opt_on_partitions_list		{ $$ = (Node *)makeString(pstrdup($1)); }
		;

DropStmt:
			DROP drop_type_name_on_any_name tsql_triggername
				{
					DropStmt *n = makeNode(DropStmt);

					if(sql_dialect != SQL_DIALECT_TSQL || $2 != OBJECT_TRIGGER)
					{
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL for DROP TRIGGER"),
								 parser_errposition(@1)));
					}
					n->removeType = OBJECT_TRIGGER;
					n->objects = list_make1($3);
					n->behavior = DROP_CASCADE;
					n->missing_ok = false;
					n->concurrent = false;
					$$ = (Node *) n;
				}
			| DROP drop_type_name_on_any_name IF_P EXISTS tsql_triggername
				{
					DropStmt *n = makeNode(DropStmt);

					if(sql_dialect != SQL_DIALECT_TSQL || $2 != OBJECT_TRIGGER)
					{
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL for DROP TRIGGER"),
								 parser_errposition(@1)));
					}
					n->removeType = OBJECT_TRIGGER;
					n->objects = list_make1($5);
					n->behavior = DROP_CASCADE;
					n->missing_ok = true;
					n->concurrent = false;
					$$ = (Node *) n;
				}
			;

tsql_DropIndexStmt:
			DROP drop_type_any_name index_name ON name_list
				{
					DropStmt *n = makeNode(DropStmt);
					if(sql_dialect != SQL_DIALECT_TSQL)
					{
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
								 parser_errposition(@1)));
					}
					if($2 != OBJECT_INDEX)
					{
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid for DROP INDEX ... on ..."),
								 parser_errposition(@2)));
					}
					n->removeType = $2;
					n->missing_ok = false;
					n->objects = list_make1(list_make1(makeString(construct_unique_index_name($3, makeRangeVarFromAnyName($5, @5, yyscanner)->relname))));
					n->behavior = DROP_CASCADE;
					n->concurrent = false;
					$$ = (Node *)n;
				}
			| DROP drop_type_any_name IF_P EXISTS index_name ON name_list
				{
					DropStmt *n = makeNode(DropStmt);
					if(sql_dialect != SQL_DIALECT_TSQL)
					{
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
								 parser_errposition(@1)));
					}
					if($2 != OBJECT_INDEX)
					{
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid for DROP INDEX ... on ..."),
								 parser_errposition(@2)));
					}
					n->removeType = $2;
					n->missing_ok = true;
					n->objects = list_make1(list_make1(makeString(construct_unique_index_name($5, makeRangeVarFromAnyName($7, @5, yyscanner)->relname))));
					n->behavior = DROP_CASCADE;
					n->concurrent = false;
					$$ = (Node *)n;
				}
			;

opt_definition:
			WITH_paren definition						{ $$ = $2; }
			| WITH IDENT '=' NumericOnly
				{
					if (sql_dialect != SQL_DIALECT_TSQL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
								 parser_errposition(@1)));
					$$ = NIL;
				}
		;

RemoveFuncStmt:
			DROP TSQL_PROC function_with_argtypes_list opt_drop_behavior
				{
					DropStmt *n = makeNode(DropStmt);
					n->removeType = OBJECT_PROCEDURE;
					n->objects = $3;
					n->behavior = $4;
					n->missing_ok = false;
					n->concurrent = false;
					$$ = (Node *)n;
				}
			| DROP TSQL_PROC IF_P EXISTS function_with_argtypes_list opt_drop_behavior
				{
					DropStmt *n = makeNode(DropStmt);
					n->removeType = OBJECT_PROCEDURE;
					n->objects = $5;
					n->behavior = $6;
					n->missing_ok = true;
					n->concurrent = false;
					$$ = (Node *)n;
				}
			;

DeleteStmt: opt_with_clause DELETE_P FROM relation_expr_opt_alias
			tsql_table_hint_expr using_clause where_or_current_clause
			returning_clause
				{
					DeleteStmt *n = makeNode(DeleteStmt);
					n->relation = $4;
					n->usingClause = $6;
					n->whereClause = $7;
					n->returningList = $8;
					n->withClause = $1;
					$$ = (Node *)n;
				}
		;

tsql_UpdateStmt: opt_with_clause UPDATE relation_expr_opt_alias
			SET set_clause_list
			from_clause
			where_or_current_clause
			returning_clause
				{
					UpdateStmt *n = makeNode(UpdateStmt);
					n->relation = $3;
					n->targetList = $5;
					if ($6 != NULL && IsA(linitial($6), JoinExpr))
					{
						n = (UpdateStmt*)tsql_update_delete_stmt_with_join(
											(Node*)n, $6, $7, NULL, $3,
											yyscanner);
					}
					else
					{
						n->fromClause = $6;
						n->whereClause = $7;
					}
					n->returningList = $8;
					n->withClause = $1;
					$$ = (Node *)n;
				}
			| opt_with_clause UPDATE relation_expr_opt_alias
			tsql_table_hint_expr
			SET set_clause_list
			from_clause
			where_or_current_clause
			returning_clause
				{
					UpdateStmt *n = makeNode(UpdateStmt);
					n->relation = $3;
					n->targetList = $6;
					n->fromClause = $7;
					n->whereClause = $8;
					n->returningList = $9;
					n->withClause = $1;
					$$ = (Node *)n;
				}
			| opt_with_clause UPDATE tsql_top_clause relation_expr_opt_alias
			tsql_opt_table_hint_expr
			SET set_clause_list
			from_clause
			where_or_current_clause
			returning_clause
				{
					UpdateStmt *n = makeNode(UpdateStmt);
					n->relation = $4;
					n->targetList = $7;
					if ($8 != NULL && IsA(linitial($8), JoinExpr))
					{
						n = (UpdateStmt*)tsql_update_delete_stmt_with_join(
											(Node*)n, $8, $9, $3, $4,
											yyscanner);
					}
					else
					{
						n->fromClause = $8;
						n->whereClause = tsql_update_delete_stmt_with_top($3,
											$4, $9, yyscanner);
					}
					n->returningList = $10;
					n->withClause = $1;
					$$ = (Node *)n;
				}
			/* OUTPUT syntax */
			| opt_with_clause UPDATE relation_expr_opt_alias
			SET set_clause_list
			tsql_output_clause
			from_clause
			where_or_current_clause
				{
					UpdateStmt *n = makeNode(UpdateStmt);
					n->relation = $3;
					n->targetList = $5;
					if ($7 != NULL && IsA(linitial($7), JoinExpr))
					{
						n = (UpdateStmt*)tsql_update_delete_stmt_with_join(
											(Node*)n, $7, $8, NULL, $3,
											yyscanner);
						
					}
					else
					{
						n->fromClause = $7;
						n->whereClause = $8;
					}
					tsql_check_update_output_transformation($6);
					n->returningList = $6;
					n->withClause = $1;
					$$ = (Node *)n;
				}
				| opt_with_clause UPDATE relation_expr_opt_alias
				tsql_table_hint_expr
				SET set_clause_list
				tsql_output_clause
				from_clause
				where_or_current_clause
					{
						UpdateStmt *n = makeNode(UpdateStmt);
						n->relation = $3;
						n->targetList = $6;
						n->fromClause = $8;
						n->whereClause = $9;
						tsql_check_update_output_transformation($7);
						n->returningList = $7;
						n->withClause = $1;
						$$ = (Node *)n;
					}
				| opt_with_clause UPDATE tsql_top_clause relation_expr_opt_alias
				tsql_opt_table_hint_expr
				SET set_clause_list
				tsql_output_clause
				from_clause
				where_or_current_clause
					{
						UpdateStmt *n = makeNode(UpdateStmt);
						n->relation = $4;
						n->targetList = $7;
						if ($8 != NULL && IsA(linitial($8), JoinExpr))
						{
							n = (UpdateStmt*)tsql_update_delete_stmt_with_join(
												(Node*)n, $9, $10, $3, $4,
												yyscanner);
						}
						else
						{
							n->fromClause = $8;
							n->whereClause = tsql_update_delete_stmt_with_top($3,
												$4, $10, yyscanner);
						}
						tsql_check_update_output_transformation($8);
						n->returningList = $8;
						n->withClause = $1;
						$$ = (Node *)n;
					}
				/* OUTPUT INTO syntax with OUTPUT target column list */
				| opt_with_clause UPDATE relation_expr_opt_alias
				SET set_clause_list
				tsql_output_clause INTO insert_target tsql_output_into_target_columns
				from_clause
				where_or_current_clause
					{
						$$ = tsql_update_output_into_cte_transformation($1, NULL, $3, $5, $6, $8, 
																		$9, $10, $11, yyscanner);
					}
				| opt_with_clause UPDATE relation_expr_opt_alias
				tsql_table_hint_expr
				SET set_clause_list
				tsql_output_clause INTO insert_target tsql_output_into_target_columns
				from_clause
				where_or_current_clause
					{
						$$ = tsql_update_output_into_cte_transformation($1, NULL, $3, $6, $7, $9, 
																	$10, $11, $12, yyscanner);
					}
				| opt_with_clause UPDATE tsql_top_clause relation_expr_opt_alias
				tsql_opt_table_hint_expr
				SET set_clause_list
				tsql_output_clause INTO insert_target tsql_output_into_target_columns
				from_clause
				where_or_current_clause
					{
						$$ = tsql_update_output_into_cte_transformation($1, $3, $4, $7, $8, $10, 
																	$11, $12, $13, yyscanner);
					}
				/* Without OUTPUT target column list */
				| opt_with_clause UPDATE relation_expr_opt_alias
				SET set_clause_list
				tsql_output_clause INTO insert_target
				from_clause
				where_or_current_clause
					{
						$$ = tsql_update_output_into_cte_transformation($1, NULL, $3, $5, $6, $8, 
																		NIL, $9, $10, yyscanner);
					}
				| opt_with_clause UPDATE relation_expr_opt_alias
				tsql_table_hint_expr
				SET set_clause_list
				tsql_output_clause INTO insert_target
				from_clause
				where_or_current_clause
					{
						$$ = tsql_update_output_into_cte_transformation($1, NULL, $3, $6, $7, $9, 
																	NIL, $10, $11, yyscanner);
					}
				| opt_with_clause UPDATE tsql_top_clause relation_expr_opt_alias
				tsql_opt_table_hint_expr
				SET set_clause_list
				tsql_output_clause INTO insert_target
				from_clause
				where_or_current_clause
					{
						$$ = tsql_update_output_into_cte_transformation($1, $3, $4, $7, $8, $10, 
																	NIL, $11, $12, yyscanner);
					}
		;

select_no_parens:
			select_clause tsql_for_clause
				{
					base_yy_extra_type *yyextra = pg_yyget_extra(yyscanner);
					char *src_query = yyextra->core_yy_extra.scanbuf;
					/*
					 * We can free the SelectStmt because we will process the transformed
					 * FOR XML query by calling function tsql_query_to_xml().
					 */
					pfree($1);
					$1 = (Node *) makeNode(SelectStmt);
					((SelectStmt *)$1)->targetList = list_make1(TsqlForXMLMakeFuncCall((TSQL_ForClause *) $2, src_query, @1, yyscanner));
					$$ = $1;
				}
			| select_clause sort_clause tsql_for_clause
				{
					if ($3 == NULL)
						insertSelectOptions((SelectStmt *) $1, $2, NIL,
											NULL, NULL,
											yyscanner);
					else
					{
						base_yy_extra_type *yyextra = pg_yyget_extra(yyscanner);
						char *src_query = yyextra->core_yy_extra.scanbuf;
						/*
						 * We can free the SelectStmt because we will process the transformed
						 * FOR XML query by calling function tsql_query_to_xml().
						 */
						pfree($1);
						$1 = (Node *) makeNode(SelectStmt);
						((SelectStmt *)$1)->targetList = list_make1(TsqlForXMLMakeFuncCall((TSQL_ForClause *) $3, src_query, @1, yyscanner));
					}
					$$ = $1;
				}
			| with_clause select_clause tsql_for_clause
				{
					if ($3 == NULL)
						insertSelectOptions((SelectStmt *) $2, NULL, NIL,
											NULL,
											$1,
											yyscanner);
					else
					{
						base_yy_extra_type *yyextra = pg_yyget_extra(yyscanner);
						char *src_query = yyextra->core_yy_extra.scanbuf;
						/*
						 * We can free the SelectStmt because we will process the transformed
						 * FOR XML query by calling function tsql_query_to_xml().
						 */
						pfree($2);
						$2 = (Node *) makeNode(SelectStmt);
						((SelectStmt *)$2)->targetList = list_make1(TsqlForXMLMakeFuncCall((TSQL_ForClause *) $3, src_query, @1, yyscanner));
					}
					$$ = $2;
				}
			| with_clause select_clause sort_clause tsql_for_clause
				{
					if ($4 == NULL)
						insertSelectOptions((SelectStmt *) $2, $3, NIL,
											NULL,
											$1,
											yyscanner);
					else
					{
						base_yy_extra_type *yyextra = pg_yyget_extra(yyscanner);
						char *src_query = yyextra->core_yy_extra.scanbuf;
						/*
						 * We can free the SelectStmt because we will process the transformed
						 * FOR XML query by calling function tsql_query_to_xml().
						 */
						pfree($2);
						$2 = (Node *) makeNode(SelectStmt);
						((SelectStmt *)$2)->targetList = list_make1(TsqlForXMLMakeFuncCall((TSQL_ForClause *) $4, src_query, @1, yyscanner));
					}
					$$ = $2;
				}
		;

simple_select:
			SELECT opt_all_clause tsql_top_clause opt_target_list
			into_clause from_clause where_clause
			group_clause having_clause window_clause
				{
					SelectStmt *n = makeNode(SelectStmt);

					n->limitCount = $3;
					n->targetList = $4;
					if ($3 != NULL && $4 == NULL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("Target list missing from TOP clause"),
								 errhint("For example, TOP n COLUMNS ..."),
								 parser_errposition(@3)));
					n->intoClause = $5;
					n->fromClause = $6;
					n->whereClause = $7;
					n->groupClause = $8;
					n->havingClause = $9;
					n->windowClause = $10;
					$$ = (Node *)n;
				}
			| SELECT distinct_clause tsql_top_clause target_list
			into_clause from_clause where_clause
			group_clause having_clause window_clause
				{
					SelectStmt *n = makeNode(SelectStmt);

					n->distinctClause = $2;
					n->limitCount = $3;
					n->targetList = $4;
					if ($3 != NULL && $4 == NULL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
									errmsg("Target list missing from TOP clause"),
									errhint("For example, TOP n COLUMNS ..."),
									parser_errposition(@3)));
					n->intoClause = $5;
					n->fromClause = $6;
					n->whereClause = $7;
					n->groupClause = $8;
					n->havingClause = $9;
					n->windowClause = $10;
					$$ = (Node *)n;
				}
			;

table_ref:	relation_expr tsql_table_hint_expr
				{
					$$ = (Node *) $1;
				}
			| relation_expr alias_clause tsql_table_hint_expr
				{
					$1->alias = $2;
					$$ = (Node *) $1;
				}
			| relation_expr tsql_table_hint_expr alias_clause
				{
					$1->alias = $3;
					$$ = (Node *) $1;
				}
			| relation_expr opt_alias_clause tablesample_clause tsql_table_hint_expr
				{
					RangeTableSample *n = (RangeTableSample *) $3;
					$1->alias = $2;
					/* relation_expr goes inside the RangeTableSample node */
					n->relation = (Node *) $1;
					$$ = (Node *) n;
				}
		;

func_expr_common_subexpr:
			TSQL_TRY_CAST '(' a_expr AS Typename ')'
				{
					$$ = TsqlFunctionTryCast($3, $5, @1);
				}
			| TSQL_CONVERT '(' Typename ',' a_expr ')'
				{
					$$ = TsqlFunctionConvert($3, $5, NULL, false, @1);
				}
			| TSQL_CHOOSE '(' a_expr ',' expr_list ')'
				{
					$$ = TsqlFunctionChoose($3, $5, @1);
				}
			| TSQL_CONVERT '(' Typename ',' a_expr ',' a_expr ')'
				{
					$$ = TsqlFunctionConvert($3, $5, $7, false, @1);
				}
			| TSQL_TRY_CONVERT '(' Typename ',' a_expr ')'
				{
					$$ = TsqlFunctionConvert($3, $5, NULL, true, @1);
				}
			| TSQL_TRY_CONVERT '(' Typename ',' a_expr ',' a_expr ')'
				{
					TSQLInstrumentation(INSTR_TSQL_TRY_CONVERT);
					$$ = TsqlFunctionConvert($3, $5, $7, true, @1);
				}
			| TSQL_DATEADD '(' dateadd_arg ',' a_expr ',' a_expr ')'
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("dateadd"),
											   list_make3(makeStringConst($3, @3),
														  $5, $7),
											   @1);
				}
			| TSQL_PARSE '(' a_expr AS Typename ')'
				{
					TSQLInstrumentation(INSTR_TSQL_PARSE);
					$$ = TsqlFunctionParse($3, $5, NULL, false, @1);
				}
			| TSQL_PARSE '(' a_expr AS Typename USING a_expr ')'
				{
					TSQLInstrumentation(INSTR_TSQL_PARSE);
					$$ = TsqlFunctionParse($3, $5, $7, false, @1);
				}
			| TSQL_TRY_PARSE '(' a_expr AS Typename ')'
				{
					$$ = TsqlFunctionParse($3, $5, NULL, true, @1);
				}
			| TSQL_TRY_PARSE '(' a_expr AS Typename USING a_expr ')'
				{
					$$ = TsqlFunctionParse($3, $5, $7, true, @1);
				}
			| TSQL_DATEDIFF '(' datediff_arg ',' a_expr ',' a_expr ')'
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("datediff"),
											   list_make3(makeStringConst($3, @3), $5, $7),
											   @1);
				}
			| TSQL_DATEPART '(' datepart_arg ',' a_expr ')'
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("datepart"),
											   list_make2(makeStringConst($3, @3), $5),
											   @1);
				}
			| TSQL_DATENAME '(' datepart_arg ',' a_expr ')'
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("datename"),
											   list_make2(makeStringConst($3, @3), $5),
											   @1);
				}
			| TSQL_ISNULL '(' a_expr ',' a_expr ')'
				{
					CoalesceExpr *c = makeNode(CoalesceExpr);
					c->args=list_make2($3, $5);
					c->location = @1;
					$$ = (Node *)c;
				}
			| TSQL_IIF '(' a_expr ',' a_expr ',' a_expr ')'
				{
					$$ = TsqlFunctionIIF($3, $5, $7, @1);
				}
			| TSQL_ATAT IDENT
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2($2), NIL, @1);
				}
			| TSQL_ATAT VERSION_P
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("version"),NIL, @1);
				}
			| TSQL_ATAT IDENTITY_P
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_get_last_identity_numeric"), NIL, @1);
				}
		;

target_el:
			a_expr AS Sconst
				{
					$$ = makeNode(ResTarget);
					if (strlen($3) >= NAMEDATALEN)
					{
						char *name = pstrdup($3);
						truncate_identifier(name, strlen(name), true);
						$$->name = downcaseIfTsqlAndCaseInsensitive(name);
					}
					else
						$$->name = downcaseIfTsqlAndCaseInsensitive($3);
					$$->name_location = @3;
					$$->indirection = NIL;
					$$->val = (Node *)$1;
					$$->location = @1;
				}
			| 	a_expr AS TSQL_NVARCHAR Sconst
				/*
				 * This rule is to support SELECT 1 AS N'col' query in Babelfish.
				 * For vanilla PG, the syntax is valid as well
				 */
				{
					$$ = makeNode(ResTarget);
					if (strlen($4) >= NAMEDATALEN)
					{
						char *name = pstrdup($4);
						truncate_identifier(name, strlen(name), true);
						$$->name = downcaseIfTsqlAndCaseInsensitive(name);
					}
					else
						$$->name = downcaseIfTsqlAndCaseInsensitive($4);
					$$->name_location = @4;
					$$->indirection = NIL;
					$$->val = (Node *)$1;
					$$->location = @1;
				}
		;

AexprConst:
			TSQL_XCONST
				{
					$$ = makeTSQLHexStringConst($1, @1);
				}
			| TSQL_NVARCHAR Sconst
				{
					/* This is to support N'str' in various locations */
					TypeName *t = makeTypeNameFromNameList(list_make2(makeString("sys"), makeString("nvarchar")));
					t->location = @1;
					t->typmods = list_make1(makeIntConst(TSQLMaxTypmod, -1));
					$$ = makeStringConstCast($2, @2, t);
				}
		;


/* Start of T-SQL specific grammar rule. */

tsql_stmtmulti:	tsql_stmtmulti ';' tsql_stmt
				{
					if ($1 != NIL)
					{
						/* update length of previous stmt */
						updateRawStmtEnd(llast_node(RawStmt, $1), @2);
					}
					if ($3 != NULL)
						$$ = lappend($1, makeRawStmt($3, @2 + 1));
					else
						$$ = $1;
				}
			| tsql_stmt
				{
					if ($1 != NULL)
						$$ = list_make1(makeRawStmt($1, 0));
					else
						$$ = NIL;
				}
		;

/* --------------------------------- */
/* Rules for OUTPUT clause support */
tsql_output_insert_rest:
            tsql_output_simple_select opt_sort_clause
                {
                    SelectStmt *s = makeNode(SelectStmt);
					$$ = makeNode(InsertStmt);
                    $$->cols = NIL;
                    s = (SelectStmt*) $1;
					s->sortClause = $2;
					$$->selectStmt = (Node*) s;
                }
			| '(' tsql_output_simple_select opt_sort_clause ')'
                {
                    SelectStmt *s = makeNode(SelectStmt);
                    $$ = makeNode(InsertStmt);
                    $$->cols = NIL;
					s = (SelectStmt*) $2;
					s->sortClause = $3;
					$$->selectStmt = (Node*) s;
                }
			| tsql_ExecStmt
                  {
                      $$ = makeNode(InsertStmt);
                      $$->cols = NIL;
                      $$->selectStmt = NULL;
                      $$->execStmt = $1;
                  }
        ;

tsql_output_insert_rest_no_paren:
            tsql_output_simple_select
                {
                    $$ = makeNode(InsertStmt);
                    $$->cols = NIL;
                    $$->selectStmt = $1;
                }
			| tsql_output_ExecStmt
                  {
                      $$ = makeNode(InsertStmt);
                      $$->cols = NIL;
                      $$->selectStmt = NULL;
                      $$->execStmt = $1;
                  }
		;

tsql_output_simple_select:
			SELECT opt_all_clause opt_target_list
			into_clause from_clause where_clause
			group_clause having_clause window_clause
				{
					SelectStmt *n = makeNode(SelectStmt);
					n->targetList = $3;
					n->intoClause = $4;
					n->fromClause = $5;
					n->whereClause = $6;
					n->groupClause = $7;
					n->havingClause = $8;
					n->windowClause = $9;
					$$ = (Node *)n;
				}
			| SELECT distinct_clause target_list
			into_clause from_clause where_clause
			group_clause having_clause window_clause
				{
					SelectStmt *n = makeNode(SelectStmt);
					n->distinctClause = $2;
					n->targetList = $3;
					n->intoClause = $4;
					n->fromClause = $5;
					n->whereClause = $6;
					n->groupClause = $7;
					n->havingClause = $8;
					n->windowClause = $9;
					$$ = (Node *)n;
				}
			| tsql_values_clause							{ $$ = $1; }
			| tsql_output_simple_select UNION all_or_distinct tsql_output_simple_select
				{
					$$ = makeSetOp(SETOP_UNION, $3, $1, $4);
				}
			| tsql_output_simple_select INTERSECT all_or_distinct tsql_output_simple_select
				{
					$$ = makeSetOp(SETOP_INTERSECT, $3, $1, $4);
				}
			| tsql_output_simple_select EXCEPT all_or_distinct tsql_output_simple_select
				{
					$$ = makeSetOp(SETOP_EXCEPT, $3, $1, $4);
				}
			
		;

tsql_values_clause:
			TSQL_VALUES '(' expr_list ')'
				{
					SelectStmt *n = makeNode(SelectStmt);
					n->valuesLists = list_make1($3);
					$$ = (Node *) n;
				}
			| tsql_values_clause ',' '(' expr_list ')'
				{
					SelectStmt *n = (SelectStmt *) $1;
					n->valuesLists = lappend(n->valuesLists, $4);
					$$ = (Node *) n;
				}
		;

tsql_output_clause:
					TSQL_OUTPUT target_list	{ $$ = $2; }
		;

tsql_output_into_target_columns:
					'(' insert_column_list ')'						{ $$ = $2; }
		;

tsql_output_ExecStmt:
			TSQL_EXEC tsql_opt_return tsql_func_name tsql_actual_args
				{
					List *name = $3;
					List *args = $4;
					CallStmt *n;
					ListCell *lc;

					foreach(lc, args)
					{
						Node *node = lfirst(lc);
						if (node->type == T_RowExpr)
						{
							RowExpr *row_expr = (RowExpr *) node;
							ereport(ERROR,
									(errcode(ERRCODE_SYNTAX_ERROR),
									 errmsg("Row Expression argument not supported"),
									 parser_errposition(row_expr->location)));
						}
					}

					n = makeNode(CallStmt);
					n->funccall = makeFuncCall(name, args, @1);

					$$ = (Node *) n;
				}
		;

/* END rules for OUTPUT clause support */
/* --------------------------------- */

tsql_stmt :
			AlterEventTrigStmt
			| AlterCollationStmt
			| AlterDatabaseStmt
			| AlterDatabaseSetStmt
			| AlterDefaultPrivilegesStmt
			| AlterDomainStmt
			| AlterEnumStmt
			| AlterExtensionStmt
			| AlterExtensionContentsStmt
			| AlterFdwStmt
			| AlterForeignTableStmt
			| AlterFunctionStmt
			| AlterGroupStmt
			| tsql_AlterLoginStmt
			| AlterObjectDependsStmt
			| AlterObjectSchemaStmt
			| AlterOwnerStmt
			| AlterOperatorStmt
			| AlterPolicyStmt
			| AlterSeqStmt
			| AlterSystemStmt
			| AlterTableStmt
			| AlterTblSpcStmt
			| AlterCompositeTypeStmt
			| AlterPublicationStmt
			| AlterRoleSetStmt
			| AlterRoleStmt
			| AlterSubscriptionStmt
			| AlterTSConfigurationStmt
			| AlterTSDictionaryStmt
			| AlterUserMappingStmt
			| AnalyzeStmt
			| CallStmt
			| CheckPointStmt
			| ClosePortalStmt
			| ClusterStmt
			| CommentStmt
			| ConstraintsSetStmt
			| CopyStmt
			| CreateAmStmt
			| CreateAsStmt
			| CreateCastStmt
			| CreateConversionStmt
			| CreateDomainStmt
			| CreateExtensionStmt
			| CreateFdwStmt
			| CreateForeignServerStmt
			| CreateForeignTableStmt
			| tsql_CreateFunctionStmt
			| CreateGroupStmt
			| tsql_CreateLoginStmt
			| CreateMatViewStmt
			| CreateOpClassStmt
			| CreateOpFamilyStmt
			| CreatePublicationStmt
			| AlterOpFamilyStmt
			| CreatePolicyStmt
			| CreatePLangStmt
			| CreateSchemaStmt
			| CreateSeqStmt
			| CreateStmt
			| CreateSubscriptionStmt
			| CreateStatsStmt
			| CreateTableSpaceStmt
			| CreateTransformStmt
			| tsql_CreateTrigStmt
			| CreateEventTrigStmt
			| CreateRoleStmt
			| CreateUserStmt
			| CreateUserMappingStmt
			| CreatedbStmt
			| DeallocateStmt
			| DeclareCursorStmt
			| DefineStmt
			| tsql_DeleteStmt
			| DiscardStmt
			| DoStmt
			| DropCastStmt
			| tsql_DropLoginStmt
			| DropOpClassStmt
			| DropOpFamilyStmt
			| DropOwnedStmt
			| DropPLangStmt
			| tsql_DropIndexStmt
			| DropStmt
			| DropSubscriptionStmt
			| DropTableSpaceStmt
			| DropTransformStmt
			| DropRoleStmt
			| DropUserMappingStmt
			| DropdbStmt
			| tsql_ExecStmt
			| ExplainStmt
			| FetchStmt
			| GrantStmt
			| GrantRoleStmt
			| ImportForeignSchemaStmt
			| tsql_IndexStmt
			| tsql_InsertStmt
			| ListenStmt
			| RefreshMatViewStmt
			| LoadStmt
			| LockStmt
			| NotifyStmt
			| PrepareStmt
			| ReassignOwnedStmt
			| ReindexStmt
			| RemoveAggrStmt
			| RemoveFuncStmt
			| RemoveOperStmt
			| RenameStmt
			| RevokeStmt
			| RevokeRoleStmt
			| RuleStmt
			| SecLabelStmt
			| SelectStmt
			| tsql_TransactionStmt
			| TruncateStmt
			| UnlistenStmt
			| tsql_UpdateStmt
			| VacuumStmt
			| VariableResetStmt
			| tsql_VariableSetStmt
			| VariableShowStmt
			| ViewStmt
			| tsql_alter_server_role
			| /*EMPTY*/
				{ $$ = NULL; }
		;

tsql_opt_INTO:
			INTO
			| /* empty */
		;

tsql_InsertStmt:
			opt_with_clause INSERT tsql_opt_INTO insert_target tsql_opt_table_hint_expr '(' insert_column_list ')'
			tsql_output_insert_rest
				{
					$9->relation = $4;
					$9->onConflictClause = NULL;
					$9->returningList = NULL;
					$9->withClause = $1;
					$9->cols = $7;
					$$ = (Node *) $9;
				}
			| opt_with_clause INSERT tsql_opt_INTO insert_target tsql_opt_table_hint_expr tsql_output_insert_rest
				{
					$6->relation = $4;
					$6->onConflictClause = NULL;
					$6->returningList = NULL;
					$6->withClause = $1;
					$6->cols = NIL;
					$$ = (Node *) $6;
				}
			| opt_with_clause INSERT tsql_opt_INTO insert_target tsql_opt_table_hint_expr DEFAULT TSQL_VALUES
				{
					InsertStmt *i = makeNode(InsertStmt);
					i->relation = $4;
					i->onConflictClause = NULL;
					i->returningList = NULL;
					i->withClause = $1;
					i->cols = NIL;
					i->selectStmt = NULL;
					i->execStmt = NULL;
					$$ = (Node *) i;
				}
			/* OUTPUT syntax */
			| opt_with_clause INSERT tsql_opt_INTO insert_target tsql_opt_table_hint_expr '(' insert_column_list ')'
			 tsql_output_clause tsql_output_insert_rest_no_paren 
				{
					if ($10->execStmt)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("The OUTPUT clause cannot be used in an INSERT...EXEC statement."),
								 parser_errposition(@10)));
					$10->relation = $4;
					$10->onConflictClause = NULL;
					$10->returningList = $9;
					$10->withClause = $1;
					$10->cols = $7;
					$$ = (Node *) $10;
				}
			| opt_with_clause INSERT tsql_opt_INTO insert_target tsql_opt_table_hint_expr tsql_output_clause tsql_output_insert_rest_no_paren 
				{
					if ($7->execStmt)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("The OUTPUT clause cannot be used in an INSERT...EXEC statement."),
								 parser_errposition(@7)));
					$7->relation = $4;
					$7->onConflictClause = NULL;
					$7->returningList = $6;
					$7->withClause = $1;
					$7->cols = NIL;
					$$ = (Node *) $7;
				}
			/* conflict on DEFAULT (DEFAULT is allowed as a_expr in tsql_output_clause
			| opt_with_clause INSERT tsql_opt_INTO insert_target tsql_opt_table_hint_expr tsql_output_clause DEFAULT VALUES
				{
					InsertStmt *i = makeNode(InsertStmt);
					i->relation = $4;
					i->onConflictClause = NULL;
					i->returningList = $6;
					i->withClause = $1;
					i->cols = NIL;
					i->selectStmt = NULL;
					i->execStmt = NULL;
					$$ = (Node *) i;
				}
			*/
			/* OUTPUT INTO syntax with OUTPUT target column list */
			| opt_with_clause INSERT tsql_opt_INTO insert_target tsql_opt_table_hint_expr '(' insert_column_list ')'
			tsql_output_clause INTO insert_target tsql_output_into_target_columns tsql_output_insert_rest
				{
					if ($13->execStmt)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("The OUTPUT clause cannot be used in an INSERT...EXEC statement."),
								 parser_errposition(@13)));
					$$ = tsql_insert_output_into_cte_transformation($1, $4, $7, $9, $11, $12, $13, 4);
				}
			| opt_with_clause INSERT tsql_opt_INTO insert_target tsql_opt_table_hint_expr tsql_output_clause 
			INTO insert_target tsql_output_into_target_columns tsql_output_insert_rest
				{
					if ($10->execStmt)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("The OUTPUT clause cannot be used in an INSERT...EXEC statement."),
								 parser_errposition(@10)));
					$$ = tsql_insert_output_into_cte_transformation($1, $4, NULL, $6, $8, $9, $10, 4);
				}
			| opt_with_clause INSERT tsql_opt_INTO insert_target tsql_opt_table_hint_expr tsql_output_clause 
			INTO insert_target tsql_output_into_target_columns DEFAULT VALUES
				{
					InsertStmt *i = makeNode(InsertStmt);
					i->relation = NULL;
					i->onConflictClause = NULL;
					i->returningList = NULL;
					i->withClause = NULL;
					i->cols = NIL;
					i->selectStmt = NULL;
					i->execStmt = NULL;
					$$ = tsql_insert_output_into_cte_transformation($1, $4, NULL, $6, $8, $9, i, 4);
				}
			/* Without OUTPUT target column list */
			| opt_with_clause INSERT tsql_opt_INTO insert_target tsql_opt_table_hint_expr '(' insert_column_list ')'
			tsql_output_clause INTO insert_target tsql_output_insert_rest_no_paren
				{
					if ($12->execStmt)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("The OUTPUT clause cannot be used in an INSERT...EXEC statement."),
								 parser_errposition(@12)));
					$$ = tsql_insert_output_into_cte_transformation($1, $4, $7, $9, $11, NIL, $12, 4);
				}
			| opt_with_clause INSERT tsql_opt_INTO insert_target tsql_opt_table_hint_expr tsql_output_clause 
			INTO insert_target tsql_output_insert_rest_no_paren
				{
					if ($9->execStmt)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("The OUTPUT clause cannot be used in an INSERT...EXEC statement."),
								 parser_errposition(@9)));
					$$ = tsql_insert_output_into_cte_transformation($1, $4, NULL, $6, $8, NIL, $9, 4);
				}
			/*
			| opt_with_clause INSERT tsql_opt_INTO insert_target tsql_opt_table_hint_expr tsql_output_clause 
			INTO insert_target DEFAULT VALUES
				{
					InsertStmt *i = makeNode(InsertStmt);
					i->relation = NULL;
					i->onConflictClause = NULL;
					i->returningList = NULL;
					i->withClause = NULL;
					i->cols = NIL;
					i->selectStmt = NULL;
					i->execStmt = NULL;
					$$ = tsql_insert_output_into_cte_transformation($1, $4, NULL, $6, $8, NIL, i, 4);
				}
			*/
		;

tsql_ExecStmt:
			TSQL_EXEC tsql_opt_return tsql_func_name tsql_actual_args
				{
					List *name = $3;
					List *args = $4;
					CallStmt *n;
					ListCell *lc;

					foreach(lc, args)
					{
						Node *node = lfirst(lc);
						if (node->type == T_RowExpr)
						{
							RowExpr *row_expr = (RowExpr *) node;
							ereport(ERROR,
									(errcode(ERRCODE_SYNTAX_ERROR),
									 errmsg("Row Expression argument not supported"),
									 parser_errposition(row_expr->location)));
						}
					}

					n = makeNode(CallStmt);
					n->funccall = makeFuncCall(name, args, @1);

					$$ = (Node *) n;
				}
			| EXECUTE tsql_opt_return tsql_func_name tsql_actual_args
				{
					List *name = $3;
					List *args = $4;
					CallStmt *n;
					ListCell *lc;

					foreach(lc, args)
					{
						Node *node = lfirst(lc);
						if (node->type == T_RowExpr)
						{
							RowExpr *row_expr = (RowExpr *) node;
							ereport(ERROR,
									(errcode(ERRCODE_SYNTAX_ERROR),
									 errmsg("Row Expression argument not supported"),
									 parser_errposition(row_expr->location)));
						}
					}

					n = makeNode(CallStmt);
					n->funccall = makeFuncCall(name, args, @1);

					$$ = (Node *) n;
				}
			| TSQL_EXEC '(' Sconst ')'
				{
					DoStmt *n = makeNode(DoStmt);
					n->args = list_make1(makeDefElem("as",
													 (Node *)makeString($3),
													 @3));
					$$ = (Node *) n;
				}
			| EXECUTE '(' Sconst ')'
				{
					DoStmt *n = makeNode(DoStmt);
					n->args = list_make1(makeDefElem("as",
													 (Node *)makeString($3),
													 @3));
					$$ = (Node *) n;
				}
		;

tsql_opt_return:
			PARAM '='
			| /* EMPTY */
		;

tsql_actual_args: tsql_actual_arg
					{
						$$ = list_make1($1);
					}
				| tsql_actual_args ',' tsql_actual_arg
					{
						$$ = lappend($1, $3);
					}
					| /* EMPTY */
					{
						$$ = NIL;
					}
		;

tsql_opt_output:
				  TSQL_OUTPUT  { $$ = true; }
				| TSQL_OUT     { $$ = true; }
				| /* EMPTY */  { $$ = false; }
		;

tsql_opt_readonly:  TSQL_READONLY    { $$ = true; }
					| /* EMPTY */  { $$ = false; }
		;

tsql_actual_arg: ColId '=' a_expr tsql_opt_output
					{
						NamedArgExpr *na = makeNode(NamedArgExpr);

						na->name = $1;   /* FIXME: record $4 somewhere - probably need a new Node type */
						na->arg = (Expr *) $3;
						na->argnumber = -1;		/* until determined */
						na->location = @1;
						$$ = (Node *) na;
					}
				| a_expr tsql_opt_output
					{
						$$ = $1; /* FIXME: record $2 somewhere - probably need a new Node type */
					}
		;

tsql_without_login: WITHOUT TSQL_LOGIN					{ $$ = true; }
		;

tsql_constraint_check:
			CHECK
			| TSQL_NOCHECK
		;

tsql_opt_constraint_name:
			CONSTRAINT name
			| /* EMPTY */
		;

/*
 * Computed columns uses b_expr not a_expr to avoid conflict with general NOT
 * (used in constraints).  Besides, it seems TSQL doesn't allow AND, NOT, IS
 * IN clauses in the computed column expression.  So, there shouldn't be
 * any issues.
 */
TSQL_computed_column:
				AS b_expr
				{
					Constraint *n = makeNode(Constraint);

					n->contype = CONSTR_GENERATED;
					n->generated_when = ATTRIBUTE_IDENTITY_ALWAYS;
					n->raw_expr = $2;
					n->cooked_expr = NULL;
					n->location = @1;

					$$ = (Node *)n;
				}
				| AS b_expr TSQL_PERSISTED
				{
					Constraint *n = makeNode(Constraint);

					n->contype = CONSTR_GENERATED;
					n->generated_when = ATTRIBUTE_IDENTITY_ALWAYS;
					n->raw_expr = $2;
					n->cooked_expr = NULL;
					n->location = @1;

					$$ = (Node *)n;
				}
		;

columnElemWithOptAscDesc:
			columnElem ASC
				{
					IndexElem * n = makeNode(IndexElem);

					if (sql_dialect != SQL_DIALECT_TSQL)
						ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR),
								errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"), parser_errposition(@1)));

					n->name = strVal($1);
					n->expr = NULL;
					n->indexcolname = NULL;
					n->collation = NULL;
					n->opclass = NULL;
					n->ordering = SORTBY_ASC;
					n->nulls_ordering = SORTBY_NULLS_DEFAULT;
					
					$$ = (Node *)n;
				}
			| columnElem DESC
				{
					IndexElem * n = makeNode(IndexElem);

					if (sql_dialect != SQL_DIALECT_TSQL)
						ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR),
								errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"), parser_errposition(@1)));

					n->name = strVal($1);
					n->expr = NULL;
					n->indexcolname = NULL;
					n->collation = NULL;
					n->opclass = NULL;
					n->ordering = SORTBY_DESC;
					n->nulls_ordering = SORTBY_NULLS_DEFAULT;
					
					$$ = (Node *)n;
				}
		;

columnListWithOptAscDesc:
			columnElemWithOptAscDesc
				{
					$$ = list_make1($1);
				}
			| columnListWithOptAscDesc ',' columnElem
				{
					$$ = lappend($1, $3);
				}
			| columnListWithOptAscDesc ',' columnElemWithOptAscDesc
				{
					$$ = lappend($1, $3);
				}
			| columnList ',' columnElemWithOptAscDesc
				{
					$$ = lappend($1, $3);
				}
		;

/*
 * NOTE: the OptFileGroup production doesn't really belong here. We accept OptFileGroup
 *       for TSQL compatibility, but that syntax is used to place a table on
 *       a filegroup (analogous to a tablespace).  For now, we just accept the
 *       filegroup specification and ignore it. This makes it impossible to
 *       write an ON COMMIT option and an ON filegroup clause in the same
 *       statement, but that would be illegal syntax anyway.
 */

OptFileGroup: 	ON name 					{}
			|	TSQL_TEXTIMAGE_ON  name
				{
					TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_TEXTIMAGE_ON);
				}
		;

tsql_OptParenthesizedIdentList:
			'(' tsql_IdentList ')' { $$ = $2; }
			| /*EMPTY*/ { $$ = NIL; }
		;

tsql_IdentList:
			NumericOnly ',' opt_plus Iconst
				{
					$$ = list_make3(makeDefElem("start", (Node *)$1, @1),
					                makeDefElem("increment", (Node *)makeInteger($4), @1),
					                makeDefElem("minvalue", (Node *)$1, @1));
				}
			| NumericOnly ',' '-' Iconst
				{
					$$ = list_make3(makeDefElem("start", (Node *)$1, @1),
					                makeDefElem("increment", (Node *)makeInteger(- $4), @1),
					                makeDefElem("maxvalue", (Node *)$1, @1));
				}
			;

opt_plus:
			'+' {}
			| /* empty */ {}
		;

/*
 * FOR XML clause can have 4 modes: RAW, AUTO, PATH and EXPLICIT.
 * Map the mode to the corresponding ENUM.
 */
tsql_for_clause:
			TSQL_FOR XML_P TSQL_RAW '(' Sconst ')' tsql_xml_common_directives
			{
				TSQL_ForClause *n = (TSQL_ForClause *) palloc(sizeof(TSQL_ForClause));
				n->location = @1;
				n->mode = TSQL_FORXML_RAW;
				n->elementName = $5;
				n->commonDirectives = $7;
				$$ = (Node *) n;
			}
			| TSQL_FOR XML_P TSQL_RAW tsql_xml_common_directives
			{
				TSQL_ForClause *n = (TSQL_ForClause *) palloc(sizeof(TSQL_ForClause));
				n->mode = TSQL_FORXML_RAW;
				n->elementName = NULL;
				n->commonDirectives = $4;
				n->location = @1;
				$$ = (Node *) n;
			}
			| TSQL_FOR XML_P TSQL_AUTO tsql_xml_common_directives
			{
				TSQL_ForClause *n = (TSQL_ForClause *) palloc(sizeof(TSQL_ForClause));
				TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_XML_OPTION_AUTO);
				n->mode = TSQL_FORXML_AUTO;
				n->elementName = NULL;
				n->commonDirectives = $4;
				n->location = @1;
				$$ = (Node *) n;
			}
			| TSQL_FOR XML_P TSQL_PATH '(' Sconst ')' tsql_xml_common_directives
			{
				TSQL_ForClause *n = (TSQL_ForClause *) palloc(sizeof(TSQL_ForClause));
				n->mode = TSQL_FORXML_PATH;
				n->elementName = $5;
				n->commonDirectives = $7;
				n->location = @1;
				$$ = (Node *) n;
			}
			| TSQL_FOR XML_P TSQL_PATH tsql_xml_common_directives
			{
				TSQL_ForClause *n = (TSQL_ForClause *) palloc(sizeof(TSQL_ForClause));
				n->mode = TSQL_FORXML_PATH;
				n->elementName = NULL;
				n->commonDirectives = $4;
				n->location = @1;
				$$ = (Node *) n;
			}
			| TSQL_FOR XML_P TSQL_EXPLICIT tsql_xml_common_directives
			{
				TSQL_ForClause *n = (TSQL_ForClause *) palloc(sizeof(TSQL_ForClause));
				TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_XML_OPTION_EXPLICIT);
				n->mode = TSQL_FORXML_EXPLICIT;
				n->elementName = NULL;
				n->commonDirectives = $4;
				n->location = @1;
				$$ = (Node *) n;
			}
		;

tsql_alter_server_role:
		  ALTER TSQL_SERVER ROLE ColId ADD_P TSQL_MEMBER RoleSpec
		{
			GrantRoleStmt *n = makeNode(GrantRoleStmt);
			AccessPriv *ap = makeNode(AccessPriv);

			if (0 != strcmp($4, "sysadmin"))
				ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                               errmsg("only sysadmin role is supported in ALTER SERVER ROLE statement"),
                               parser_errposition(@4)));
			
			ap->priv_name = $4;
			n->is_grant = true;
			n->granted_roles = list_make1(ap);
			n->grantee_roles = list_make1($7);
			n->admin_opt = false;
			n->grantor = NULL;
			$$ = (Node *) n;
		}
		| ALTER TSQL_SERVER ROLE ColId DROP TSQL_MEMBER RoleSpec
		{
			GrantRoleStmt *n = makeNode(GrantRoleStmt);
			AccessPriv *ap = makeNode(AccessPriv);

			if (0 != strcmp($4, "sysadmin"))
				ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                               errmsg("only sysadmin role is supported in ALTER SERVER ROLE statement"),
                               parser_errposition(@4)));

			ap->priv_name = $4;
			n->is_grant = false;
			n->granted_roles = list_make1(ap);
			n->grantee_roles = list_make1($7);
			n->admin_opt = false;
			n->grantor = NULL;
			$$ = (Node *) n;
		}

tsql_xml_common_directives:
			tsql_xml_common_directives ',' tsql_xml_common_directive
			{
				$$ = lappend($1, $3);
			}
			| /*EMPTY*/													{ $$ = NIL; }
		;

/*
 * FOR XML clause can have 3 directives: BINARY BASE64, TYPE and ROOT.
 * Map them to ENUM TSQLXMLDirective and String of the ROOT name respectively.
 */
tsql_xml_common_directive:
			BINARY TSQL_BASE64							{ $$ = makeIntConst(TSQL_XML_DIRECTIVE_BINARY_BASE64, -1); }
			| TYPE_P									{ $$ = makeIntConst(TSQL_XML_DIRECTIVE_TYPE, -1); }
			| TSQL_ROOT									{ $$ = makeStringConst("root", -1); }
			| TSQL_ROOT '(' Sconst ')'					{ $$ = makeStringConst($3, -1); }
		;


/* Create Function and Create Trigger in one statement */
tsql_CreateTrigStmt:
			CREATE TRIGGER tsql_triggername ON qualified_name
			tsql_TriggerActionTime tsql_TriggerEvents tsql_opt_not_for_replication
			AS tokens_remaining
				{
					CreateTrigStmt *n1 = makeNode(CreateTrigStmt);
					CreateFunctionStmt *n2 = makeNode(CreateFunctionStmt);
					TriggerTransition *nt_inserted = NULL;
					TriggerTransition *nt_deleted = NULL;
					DefElem *lang = makeDefElem("language", (Node *) makeString("pltsql"), @1);
					DefElem *body = makeDefElem("as", (Node *) list_make1(makeString($10)), @10);
					DefElem *trigStmt = makeDefElem("trigStmt", (Node *) n1, @1);

 					n1->trigname = ((Value *)list_nth($3,0))->val.str;
					n1->relation = $5;
					/*
					 * Function with the same name as the
					 * trigger will be created as part of
					 * this create trigger command.
					 */
					n1->funcname = list_make1(makeString(n1->trigname));
 					if (list_length($3) > 1){
	 					n1->trigname = ((Value *)list_nth($3,1))->val.str;
						/*
						* Used a hack way to pass the schema name from args, in CR-58614287
						* Args will be set back to NIL in pl_handler pltsql_pre_parse_analyze()
						* before calling backend functios
						*/
	 					n1->args = list_make1(makeString(((Value *)list_nth($3,0))->val.str));
	 				}else{
						n1->args = NIL;
					}
					/* TSQL only support statement level triggers as part of the
					 * syntax, n1->row is false for AFTER, BEFORE and INSTEAD OF
					 * triggers.
					 */
					n1->row = false;
					n1->timing = $6;
					n1->events = intVal(linitial($7));
					n1->columns = NIL;
					n1->whenClause = NULL;
					n1->isconstraint = false;
					n1->deferrable = false;
					n1->initdeferred  = false;
					n1->constrrel = NULL;
					n1->transitionRels = NIL;

					if((n1->events & TRIGGER_TYPE_INSERT) == TRIGGER_TYPE_INSERT ||
					   (n1->events & TRIGGER_TYPE_UPDATE) == TRIGGER_TYPE_UPDATE)
					{
						nt_inserted = makeNode(TriggerTransition);
						nt_inserted->name = "inserted";
						nt_inserted->isNew = true;
						nt_inserted->isTable = true;
						n1->transitionRels = lappend(n1->transitionRels, nt_inserted);
					}
					if((n1->events & TRIGGER_TYPE_DELETE) == TRIGGER_TYPE_DELETE ||
					   (n1->events & TRIGGER_TYPE_UPDATE) == TRIGGER_TYPE_UPDATE)
					{
						nt_deleted = makeNode(TriggerTransition);
						nt_deleted->name = "deleted";
						nt_deleted->isNew = false;
						nt_deleted->isTable = true;
						n1->transitionRels = lappend(n1->transitionRels, nt_deleted);
					}

					n2->is_procedure = false;
					n2->replace = true;
					n2->funcname = list_make1(makeString(n1->trigname));;
					n2->parameters = NIL;
					n2->returnType = makeTypeName("trigger");
					n2->options = list_make3(lang, body, trigStmt);

					$$ = (Node *) n2;
				}
	   ;

 tsql_triggername: 
	 		ColId									{ $$ = list_make1(makeString($1)); };
	 		| ColId '.' ColId						{ $$ = list_make2(makeString($1),makeString($3)); };					

tsql_TriggerActionTime:
			TriggerActionTime
			| FOR								{ $$ = TRIGGER_TYPE_AFTER; }
		;

/*
 * Support ',' separator in tsql_TriggerEvents
 */
tsql_TriggerEvents:
			tsql_TriggerOneEvent
				{ $$ = $1; }
			| tsql_TriggerEvents ',' tsql_TriggerOneEvent
				{
					int		events1 = intVal(linitial($1));
					int		events2 = intVal(linitial($3));
					List   *columns1 = (List *) lsecond($1);
					List   *columns2 = (List *) lsecond($3);

					if (events1 & events2)
						parser_yyerror("duplicate trigger events specified");
					/*
					 * concat'ing the columns lists loses information about
					 * which columns went with which event, but so long as
					 * only UPDATE carries columns and we disallow multiple
					 * UPDATE items, it doesn't matter.  Command execution
					 * should just ignore the columns for non-UPDATE events.
					 */
					$$ = list_make2(makeInteger(events1 | events2),
									list_concat(columns1, columns2));
				}
		;

tsql_TriggerOneEvent:
			INSERT
				{ $$ = list_make2(makeInteger(TRIGGER_TYPE_INSERT), NIL); }
			| DELETE_P
				{ $$ = list_make2(makeInteger(TRIGGER_TYPE_DELETE), NIL); }
			| UPDATE
				{ $$ = list_make2(makeInteger(TRIGGER_TYPE_UPDATE), NIL); }
			| TRUNCATE
				{ $$ = list_make2(makeInteger(TRIGGER_TYPE_TRUNCATE), NIL); }
		;

/*
 * NOTE: Only supporting the syntax for now
 */
tsql_opt_not_for_replication:
			NOT FOR TSQL_REPLICATION				{}
			| /*EMPTY*/								{}
		;

opt_from:	FROM									{}
			| /* EMPTY */							{}
		;

tsql_IndexStmt:
			CREATE opt_unique tsql_opt_cluster tsql_opt_columnstore
			INDEX opt_concurrently opt_index_name
			ON relation_expr access_method_clause '(' index_params ')'
			opt_include where_clause opt_reloptions
			tsql_opt_on_filegroup
				{
					IndexStmt *n = makeNode(IndexStmt);
					n->unique = $2;
					n->concurrent = $6;
					n->idxname = $7;
					n->relation = $9;
					n->accessMethod = $10;
					n->indexParams = $12;
					n->indexIncludingParams = $14;
					n->whereClause = $15;
					n->options = $16;
					n->excludeOpNames = NIL;
					n->idxcomment = NULL;
					n->indexOid = InvalidOid;
					n->oldNode = InvalidOid;
					n->primary = false;
					n->isconstraint = false;
					n->deferrable = false;
					n->initdeferred = false;
					n->transformed = false;
					n->if_not_exists = false;
					$$ = (Node *)n;
				}
		;

tsql_cluster:
			TSQL_CLUSTERED
				{
					TSQLInstrumentation(INSTR_TSQL_OPTION_CLUSTERED);
					$$ = true;
				}
			| TSQL_NONCLUSTERED
				{
					TSQLInstrumentation(INSTR_TSQL_OPTION_NON_CLUSTERED);
					$$ = false;
				}
		;

tsql_opt_cluster:
			  tsql_cluster { $$ = $1; }
			| /*EMPTY*/ { $$ = false; }
		;

tsql_opt_columnstore:
			TSQL_COLUMNSTORE
			{
				ereport(NOTICE,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("The COLUMNSTORE option is currently ignored")));
			}
			| /*EMPTY*/
		;

/*
 * NOTE: Only supporting the syntax for now
 */
tsql_on_filegroup: ON name {}
		;

tsql_opt_on_filegroup:
			tsql_on_filegroup					    {}
			| /*EMPTY*/				    {}
		;

/*
 * TSQL support for DATA_COMPRESSION in <table_option> and <index_option>:
 * DATA_COMPRESSION = {NONE | ROW | PAGE} [ON PARTITIONS (<range> [,...n])]
 * eg. ON PARTITIONS (2), ON PARTITIONS (1, 5), ON PARTITIONS (2, 4, 6 TO 8)
 */
tsql_on_ident_partitions_list:
			ON IDENT '(' tsql_on_partitions_list ')'
				{
					if (sql_dialect != SQL_DIALECT_TSQL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
								 parser_errposition(@1)));
				}
		;

tsql_opt_on_partitions_list:
			tsql_on_ident_partitions_list {}
			| /*EMPTY*/						{}
		;

tsql_on_partitions_list:
			tsql_on_partitions					{}
			| tsql_on_partitions_list ',' tsql_on_partitions	{}
		;

tsql_on_partitions:
			Iconst							{}
			| Iconst TO Iconst					{}
		;

/*
 * TSQL support for options in <table_option>:
 * SYSTEM_VERSIONING, REMOTE_DATA_ARCHIVE, DATA_DELETION
 */
tsql_paren_extra_relopt_list:
			'(' tsql_extra_relopt_list ')'
				{
					if (sql_dialect != SQL_DIALECT_TSQL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
								 parser_errposition(@1)));
				}
		;

tsql_extra_relopt_list:
			tsql_extra_relopt					{}
			| tsql_extra_relopt_list ',' tsql_extra_relopt		{}
		;

tsql_extra_relopt:
			IDENT '=' tsql_extra_def_arg				{}
		;

tsql_extra_def_arg:
			ColId							{}
			| ON							{}
			| NULL_P						{}
			| NumericOnly datepart_arg				{}
			| IDENT '.' IDENT					{}
		;

/*
 * TSQL support for MAX_DURATION option in <index_option>:
 * MAX_DURATION = <time> [MINUTES]
 */
tsql_ident:
			IDENT
				{
					if (sql_dialect != SQL_DIALECT_TSQL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
								 parser_errposition(@1)));
				}
		;

tsql_DeleteStmt: opt_with_clause DELETE_P opt_top_clause opt_from relation_expr_opt_alias
			tsql_opt_table_hint_expr from_clause where_or_current_clause
				{
					DeleteStmt *n = makeNode(DeleteStmt);
					n->relation = $5;
					if ($7 != NULL && IsA(linitial($7), JoinExpr))
					{
						n = (DeleteStmt*)tsql_update_delete_stmt_with_join(
											(Node*)n, $7, $8, $3, $5,
											yyscanner);
					}
					else
					{
						n->usingClause = $7;
						n->whereClause = tsql_update_delete_stmt_with_top($3,
											$5, $8, yyscanner);
					}
					n->returningList = NULL;
					n->withClause = $1;
					$$ = (Node *)n;
				}
			/* OUTPUT syntax */
			| opt_with_clause DELETE_P opt_top_clause opt_from relation_expr_opt_alias
			tsql_opt_table_hint_expr tsql_output_clause from_clause where_or_current_clause
				{
					DeleteStmt *n = makeNode(DeleteStmt);
					n->relation = $5;
					if ($8 != NULL && IsA(linitial($8), JoinExpr))
					{
						n = (DeleteStmt*)tsql_update_delete_stmt_with_join(
											(Node*)n, $8, $9, $3, $5,
											yyscanner);
					}
					else
					{
						n->usingClause = $8;
						n->whereClause = tsql_update_delete_stmt_with_top($3,
											$5, $9, yyscanner);
					}
					n->returningList = $7;
					n->withClause = $1;
					$$ = (Node *)n;
				}
			/* OUTPUT INTO syntax with OUTPUT target column list */
			| opt_with_clause DELETE_P opt_top_clause opt_from relation_expr_opt_alias
			tsql_opt_table_hint_expr tsql_output_clause INTO insert_target tsql_output_into_target_columns from_clause
			where_or_current_clause
				{
					$$ = tsql_delete_output_into_cte_transformation($1, $3, $5, $7, $9, $10, $11, $12, yyscanner);
				}
			/* Without OUTPUT target column list */
			| opt_with_clause DELETE_P opt_top_clause opt_from relation_expr_opt_alias
			tsql_opt_table_hint_expr tsql_output_clause INTO insert_target from_clause where_or_current_clause
				{
					$$ = tsql_delete_output_into_cte_transformation($1, $3, $5, $7, $9, NIL, $10, $11, yyscanner);
				}
			;

tsql_top_clause:
			TSQL_TOP '(' a_expr ')'						{ $$ = $3; }
			| TSQL_TOP I_or_F_const						{ $$ = $2; }
			| TSQL_TOP select_with_parens
				{
					/*
					 * We need a speical grammar for scalar subquery here
					 * because c_expr (in a_expr) has a rule select_with_parens but we defined the first rule as '(' a_expr ')'.
					 * In other words, the first rule will be hit only when double parenthesis is used like `SELECT TOP ((select 1)) ...`
					 */
					SubLink *n = makeNode(SubLink);
					n->subLinkType = EXPR_SUBLINK;
					n->subLinkId = 0;
					n->testexpr = NULL;
					n->operName = NIL;
					n->subselect = $2;
					n->location = @1;
					$$ = (Node *)n;
				}
			| TSQL_TOP '(' a_expr ')' TSQL_PERCENT
				{
					if (IsA($3, A_Const))
					{
						A_Const* n = (A_Const *)$3;
						if(n->val.type == T_Integer && n->val.val.ival == 100)
						{
								$$ = makeNullAConst(@1);
						}
						else if(n->val.type == T_Float && atof(n->val.val.str) == 100.0)
						{
								$$ = makeNullAConst(@1);
						}
						else
						{
							TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_TOP_PERCENT_IN_STMT);
							ereport(ERROR,
									(errcode(ERRCODE_SYNTAX_ERROR),
									errmsg("TOP # PERCENT is not yet supported"),
									parser_errposition(@1)));
						}
					}
					else
					{
						TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_TOP_PERCENT_IN_STMT);
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								errmsg("TOP # PERCENT is not yet supported"),
								parser_errposition(@1)));
					}
				}
			| TSQL_TOP I_or_F_const TSQL_PERCENT
				{
					A_Const* n = (A_Const *)$2;
					if(n->val.type == T_Integer && n->val.val.ival == 100)
					{
							$$ = makeNullAConst(@1);
					}
					else if(n->val.type == T_Float && atof(n->val.val.str) == 100.0)
					{
							$$ = makeNullAConst(@1);
					}
					else
					{
						TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_TOP_PERCENT_IN_STMT);
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								errmsg("TOP # PERCENT is not yet supported"),
								parser_errposition(@1)));
					}
				}
		;

opt_top_clause:
				tsql_top_clause { $$ = $1; }
			| /*EMPTY*/ { $$ = NULL; }
		;

/*
 * SQL table hints apply to DELETE, INSERT, SELECT and UPDATE statements.
 * In SELECT statement, it's specified in the FROM clause.
 * Table hint can start without WITH keyword. To avoid s/r conflict, we handle
 * such cases by looking up an additional token and check if it's a valid hint,
 * and re-assign the token '(' to TSQL_HINT_START_BRACKET.
 * NB: when used without "WITH", the table hint can only be specified alone.
 */

tsql_opt_table_hint_expr:
			tsql_table_hint_expr                       { $$ = $1; }
			| /*EMPTY*/                                { $$ = NIL; }
		;

tsql_table_hint_expr:
			WITH_paren '(' tsql_table_hint_list ')'          { $$ = $3; }
			| WITH_paren TSQL_HINT_START_BRACKET tsql_table_hint_list ')'       { $$ = $3; }
			| TSQL_HINT_START_BRACKET tsql_table_hint_kw_no_with ')' { $$ = list_make1($2); }
		;

tsql_table_hint_list:
			tsql_table_hint
				{
					$$ = list_make1($1);
				}
			| tsql_table_hint_list ',' tsql_table_hint
				{
					$$ = lappend($1, $3);
				}
			| tsql_table_hint_list tsql_table_hint
				{
					$$ = lappend($1, $2);
				}
		;

/*
 * NOTE: T-SQL Table hint is ignored now.
 * To be simple, just using plain string and list here instead of pretty hint strcuture.
 */
tsql_table_hint:
			IDENT
				{
					$$ = (Node* ) makeString($1);
				}
			| tsql_table_hint_kw_no_with
				{
					$$ = (Node* ) $1;
				}
			| INDEX '(' columnList ')'
				{
					List* l = list_make1(makeString("INDEX"));
					$$ = (Node *) lappend(l, $3);
				}
			| INDEX '=' columnElem
				{
					List* l = list_make1(makeString("INDEX"));
					$$ = (Node *) lappend(l, $3);
				}
		;

/*
 * Table hints that can be used without "WITH" keyword.
 * We explicitly add these keywords only to allow us to detect
 * TSQL_HINT_START_BRACKET to avoid s/r conflicts. It seems unnecessary to
 * add all the hints since we do not need to do anything with them yet.
 * It is up to the designer of table hint later to decide whether we should
 * add all hints as keywords or just do some checking inside the code block.
 */
tsql_table_hint_kw_no_with:
			TSQL_NOLOCK    /* EMPTY */                        {$$ = pstrdup($1);}
			| TSQL_READUNCOMMITTED    /* EMPTY */            {$$ = pstrdup($1);}
			| TSQL_UPDLOCK    /* EMPTY */                    {$$ = pstrdup($1);}
			| TSQL_REPEATABLEREAD    /* EMPTY */            {$$ = pstrdup($1);}
			| SERIALIZABLE    /* EMPTY */                    {$$ = pstrdup($1);}
			| TSQL_READCOMMITTED    /* EMPTY */            {$$ = pstrdup($1);}
			| TSQL_TABLOCK    /* EMPTY */                    {$$ = pstrdup($1);}
			| TSQL_TABLOCKX    /* EMPTY */                    {$$ = pstrdup($1);}
			| TSQL_PAGLOCK    /* EMPTY */                    {$$ = pstrdup($1);}
			| TSQL_ROWLOCK    /* EMPTY */                    {$$ = pstrdup($1);}
			| NOWAIT    /* EMPTY */                        {$$ = pstrdup($1);}
			| TSQL_READPAST    /* EMPTY */                    {$$ = pstrdup($1);}
			| TSQL_XLOCK    /* EMPTY */                    {$$ = pstrdup($1);}
			| SNAPSHOT    /* EMPTY */                        {$$ = pstrdup($1);}
			| TSQL_NOEXPAND    /* EMPTY */                    {$$ = pstrdup($1);}
		;

TSQL_Typename:	TSQL_SimpleTypename opt_array_bounds
				{
					$$ = $1;
					$$->arrayBounds = $2;
				}
			| SETOF TSQL_SimpleTypename opt_array_bounds
				{
					$$ = $2;
					$$->arrayBounds = $3;
					$$->setof = true;
				}
			/* SQL standard syntax, currently only one-dimensional */
			| TSQL_SimpleTypename ARRAY '[' Iconst ']'
				{
					$$ = $1;
					$$->arrayBounds = list_make1(makeInteger($4));
				}
			| SETOF TSQL_SimpleTypename ARRAY '[' Iconst ']'
				{
					$$ = $2;
					$$->arrayBounds = list_make1(makeInteger($5));
					$$->setof = true;
				}
			| TSQL_SimpleTypename ARRAY
				{
					$$ = $1;
					$$->arrayBounds = list_make1(makeInteger(-1));
				}
			| SETOF TSQL_SimpleTypename ARRAY
				{
					$$ = $2;
					$$->arrayBounds = list_make1(makeInteger(-1));
					$$->setof = true;
				}
		;

TSQL_SimpleTypename:
			TSQL_GenericType						{ $$ = $1; }
			| Numeric								{ $$ = $1; }
			| Bit									{ $$ = $1; }
			| Character								{ $$ = $1; }
			| ConstDatetime							{ $$ = $1; }
			| ConstInterval opt_interval
				{
					$$ = $1;
					$$->typmods = $2;
				}
			| ConstInterval '(' Iconst ')'
				{
					$$ = $1;
					$$->typmods = list_make2(makeIntConst(INTERVAL_FULL_RANGE, -1),
											 makeIntConst($3, @3));
				}
		;

TSQL_GenericType:
			tsql_type_function_name opt_type_modifiers
				{
					$$ = makeTypeName($1);
					$$->typmods = $2;
					$$->location = @1;
				}
			| tsql_type_function_name attrs opt_type_modifiers
				{
					$$ = makeTypeNameFromNameList(lcons(makeString($1), $2));
					$$->typmods = $3;
					$$->location = @1;
				}
		;

/* DATEPART() arguments
 */
datepart_arg:
			IDENT									{ $$ = $1; }
			| YEAR_P								{ $$ = "year"; }
			| TSQL_YYYY								{ $$ = "year"; }
			| TSQL_YY								{ $$ = "year"; }
			| TSQL_QUARTER							{ $$ = "quarter"; }
			| TSQL_QQ								{ $$ = "quarter"; }
			| TSQL_Q								{ $$ = "quarter"; }
			| MONTH_P								{ $$ = "month"; }
			| TSQL_MM								{ $$ = "month"; }
			| TSQL_M								{ $$ = "month"; }
			| TSQL_DAYOFYEAR						{ $$ = "doy"; }
			| TSQL_DY								{ $$ = "doy"; }
			| DAY_P									{ $$ = "day"; }
			| TSQL_DD								{ $$ = "day"; }
			| TSQL_D								{ $$ = "day"; }
			| TSQL_WEEK								{ $$ = "tsql_week"; }
			| TSQL_WK								{ $$ = "tsql_week"; }
			| TSQL_WW								{ $$ = "tsql_week"; }
			| TSQL_WEEKDAY							{ $$ = "dow"; }
			| TSQL_DW								{ $$ = "dow"; }
			| HOUR_P								{ $$ = "hour"; }
			| TSQL_HH								{ $$ = "hour"; }
			| MINUTE_P								{ $$ = "minute"; }
			| TSQL_N								{ $$ = "minute"; }
			| SECOND_P								{ $$ = "second"; }
			| TSQL_SS								{ $$ = "second"; }
			| TSQL_S								{ $$ = "second"; }
			| TSQL_MILLISECOND						{ $$ = "millisecond"; }
			| TSQL_MS								{ $$ = "millisecond"; }
			| TSQL_MICROSECOND						{ $$ = "microsecond"; }
			| TSQL_MCS								{ $$ = "microsecond"; }
			| TSQL_NANOSECOND						{ $$ = "nanosecond"; }
			| TSQL_NS								{ $$ = "nanosecond"; }
			| TSQL_TZOFFSET							{ $$ = "tzoffset"; }
			| TSQL_TZ								{ $$ = "tzoffset"; }
			| TSQL_ISO_WEEK							{ $$ = "week"; }
			| TSQL_ISOWK							{ $$ = "week"; }
			| TSQL_ISOWW							{ $$ = "week"; }
			| Sconst								{ $$ = $1; }
		;

/* DATEDIFF() arguments
 */
datediff_arg:
			IDENT									{ $$ = $1; }
			| YEAR_P								{ $$ = "year"; }
			| TSQL_YYYY								{ $$ = "year"; }
			| TSQL_YY								{ $$ = "year"; }
			| TSQL_QUARTER							{ $$ = "quarter"; }
			| TSQL_QQ								{ $$ = "quarter"; }
			| TSQL_Q								{ $$ = "quarter"; }
			| MONTH_P								{ $$ = "month"; }
			| TSQL_MM								{ $$ = "month"; }
			| TSQL_M								{ $$ = "month"; }
			| TSQL_DAYOFYEAR						{ $$ = "doy"; }
			| TSQL_DY								{ $$ = "doy"; }
			| DAY_P									{ $$ = "day"; }
			| TSQL_DD								{ $$ = "day"; }
			| TSQL_D								{ $$ = "day"; }
			| TSQL_WEEK								{ $$ = "week"; }
			| TSQL_WK								{ $$ = "week"; }
			| TSQL_WW								{ $$ = "week"; }
			| HOUR_P								{ $$ = "hour"; }
			| TSQL_HH								{ $$ = "hour"; }
			| MINUTE_P								{ $$ = "minute"; }
			| TSQL_N								{ $$ = "minute"; }
			| SECOND_P								{ $$ = "second"; }
			| TSQL_SS								{ $$ = "second"; }
			| TSQL_S								{ $$ = "second"; }
			| TSQL_MILLISECOND						{ $$ = "millisecond"; }
			| TSQL_MS								{ $$ = "millisecond"; }
			| TSQL_MICROSECOND						{ $$ = "microsecond"; }
			| TSQL_MCS								{ $$ = "microsecond"; }
			| TSQL_NANOSECOND						{ $$ = "nanosecond"; }
			| TSQL_NS								{ $$ = "nanosecond"; }
			| Sconst								{ $$ = $1; }
		;

/* DATEADD() arguments
 */
dateadd_arg:
			IDENT									{ $$ = $1; }
			| YEAR_P								{ $$ = "year"; }
			| TSQL_YYYY								{ $$ = "year"; }
			| TSQL_YY								{ $$ = "year"; }
			| TSQL_QUARTER							{ $$ = "quarter"; }
			| TSQL_QQ								{ $$ = "quarter"; }
			| TSQL_Q								{ $$ = "quarter"; }
			| MONTH_P								{ $$ = "month"; }
			| TSQL_MM								{ $$ = "month"; }
			| TSQL_M								{ $$ = "month"; }
			| TSQL_DAYOFYEAR						{ $$ = "dayofyear"; }
			| TSQL_DY								{ $$ = "dayofyear"; }
			| DAY_P									{ $$ = "day"; }
			| TSQL_DD								{ $$ = "day"; }
			| TSQL_D								{ $$ = "day"; }
			| TSQL_WEEK								{ $$ = "week"; }
			| TSQL_WK								{ $$ = "week"; }
			| TSQL_WW								{ $$ = "week"; }
			| TSQL_WEEKDAY							{ $$ = "weekday"; }
			| TSQL_DW								{ $$ = "weekday"; }
			| HOUR_P								{ $$ = "hour"; }
			| TSQL_HH								{ $$ = "hour"; }
			| MINUTE_P								{ $$ = "minute"; }
			| TSQL_N								{ $$ = "minute"; }
			| SECOND_P								{ $$ = "second"; }
			| TSQL_SS								{ $$ = "second"; }
			| TSQL_S								{ $$ = "second"; }
			| TSQL_MILLISECOND						{ $$ = "millisecond"; }
			| TSQL_MS								{ $$ = "millisecond"; }
			| TSQL_MICROSECOND						{ $$ = "microsecond"; }
			| TSQL_MCS								{ $$ = "microsecond"; }
			| TSQL_NANOSECOND						{ $$ = "nanosecond"; }
			| TSQL_NS								{ $$ = "nanosecond"; }
			| Sconst								{ $$ = $1; }
		;

tsql_type_function_name: IDENT						{ $$ = $1; }
//			| unreserved_keyword					{ $$ = pstrdup($1); }
			| type_func_name_keyword				{ $$ = pstrdup($1); }
		;

tokens_remaining:
					{
						/*
						 * Find the "extra" information that we've attached to 
						 * the scanner; we'll need that to access the input 
						 * string (the string that we are parsing)
						 *
						 * Also, record the offset of the scanner (within that
						 * string) - later we will copy everything from start
						 * to the end of the string.
						 */
						base_yy_extra_type *yyextra = pg_yyget_extra(yyscanner);
						int start = -1;

						/* If there's a lookahead token, start there. */
						if (yychar != YYEMPTY && yychar > YYEOF)
							start = yylloc;

						/*
						 * Now advance the lexer (scanner) past all of the 
						 * tokens remaining in the input string. If we don't
						 * do this, the parser won't know that we have consumed
						 * all of those tokens.
						 */
						while (pgtsql_base_yylex(&yylval, &yylloc, yyscanner) != 0)
						{
							if (start == -1)
								start = yylloc;
						}

						/*
						 * Clear any read-ahead token since we really want to
						 * consume all remaining tokens.
						 */
						yyclearin;

						/*
						 * And make a copy of the string, starting with the start
						 * position (start) and ending with the current position
						 * (yylloc)
						 */
						$$ = pstrdup(yyextra->core_yy_extra.scanbuf + start);
					}
		;

/*
 * TSQL-compatible CREATE PROCEDURE and CREATE FUNCTION rules follow.
 *
 * These rules differ from PostgreSQL in that TSQL does not require
 * the body of the function/procedure to be specified as a string
 * literal - instead, the body is a sequence of tokens.
 *
 * Also, the formal argument list may or may not be encloded in parens.
 * in a CREATE PROCEDURE statement (the parens are required in CREATE
 * FUNCTION).
 */
tsql_CreateFunctionStmt:
				  CREATE opt_or_replace FUNCTION func_name tsql_createfunc_args
				  RETURNS func_return tsql_createfunc_options opt_as tokens_remaining
					{
						CreateFunctionStmt *n = makeNode(CreateFunctionStmt);
						DefElem *lang = makeDefElem("language", (Node *) makeString("pltsql"), @1);
						DefElem *body = makeDefElem("as", (Node *) list_make1(makeString($10)), @10);
						n->is_procedure = false;
						n->replace = $2;
						n->funcname = $4;
						n->parameters = $5;
						tsql_completeDefaultValues(n->parameters);
						n->returnType = $7;
						n->options = list_concat(list_make2(lang, body), $8);
						$$ = (Node *)n;
					}
			| CREATE opt_or_replace proc_keyword tsql_func_name tsql_createproc_args
			  tsql_createfunc_options AS tokens_remaining
				{
					CreateFunctionStmt *n = makeNode(CreateFunctionStmt);
					DefElem *lang = makeDefElem("language", (Node *) makeString("pltsql"), @1);
					DefElem *body = makeDefElem("as", (Node *) list_make1(makeString($8)), @8);

					n->is_procedure = true;
					n->replace = $2;
					n->funcname = $4;
					n->parameters = $5;
					tsql_completeDefaultValues(n->parameters);
					n->returnType = NULL;
					n->options = list_concat(list_make2(lang, body), $6);
					$$ = (Node *)n;
				}
			/*
			 * TSQL multi-statement table-valued function:
			 * Create the function and a table type for its output table definition
			 * in one statement
			 */
			| CREATE opt_or_replace FUNCTION func_name tsql_createfunc_args
			  RETURNS param_name TABLE '(' OptTableElementList ')' opt_as tokens_remaining
				{
					CreateStmt *n1 = makeNode(CreateStmt);
					CreateFunctionStmt *n2 = makeNode(CreateFunctionStmt);
					char *tbltyp_name = psprintf("%s_%s", $7, strVal(llast($4)));
					List *tbltyp = list_copy($4);
					FunctionParameter *out_param;

					DefElem *lang = makeDefElem("language", (Node *) makeString("pltsql"), @1);
					DefElem *body = makeDefElem("as", (Node *) list_make1(makeString($13)), @13);
					DefElem *tbltypStmt = makeDefElem("tbltypStmt", (Node *) n1, @1);
					TSQLInstrumentation(INSTR_TSQL_CREATE_FUNCTION_RETURNS_TABLE);
					if (sql_dialect != SQL_DIALECT_TSQL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
								 parser_errposition(@1)));

					tbltyp = list_truncate(tbltyp, list_length(tbltyp) - 1);
					tbltyp = lappend(tbltyp, makeString(tbltyp_name));
					n1->relation = makeRangeVarFromAnyName(tbltyp, @4, yyscanner);
					n1->tableElts = $10;
					n1->inhRelations = NIL;
					n1->partspec = NULL;
					n1->ofTypename = NULL;
					n1->constraints = NIL;
					n1->options = NIL;
					n1->oncommit = ONCOMMIT_NOOP;
					n1->tablespacename = NULL;
					n1->if_not_exists = false;
					n1->tsql_tabletype = true;

					/* Add a param for the output table variable */
					out_param = makeNode(FunctionParameter);
					out_param->name = $7;
					out_param->argType = makeTypeNameFromNameList(tbltyp);
					out_param->mode = FUNC_PARAM_TABLE;
					out_param->defexpr = NULL;

					n2->is_procedure = false;
					n2->replace = $2;
					n2->funcname = $4;
					tsql_completeDefaultValues($5);
					n2->parameters = lappend($5, out_param);
					n2->returnType = makeTypeNameFromNameList(tbltyp);
					n2->returnType->setof = true;
					n2->returnType->location = @8;
					n2->options = list_make3(lang, body, tbltypStmt);

					$$ = (Node *)n2;
				}
			/* TSQL inline table-valued function */
			| CREATE opt_or_replace FUNCTION func_name tsql_createfunc_args
			  RETURNS TABLE opt_as tokens_remaining
				{
					CreateFunctionStmt *n = makeNode(CreateFunctionStmt);
					DefElem *lang = makeDefElem("language", (Node *) makeString("pltsql"), @1);
					DefElem *body = makeDefElem("as", (Node *) list_make1(makeString($9)), @9);

					TSQLInstrumentation(INSTR_TSQL_CREATE_FUNCTION_RETURNS_TABLE);
					n->is_procedure = false;
					n->replace = $2;
					n->funcname = $4;
					/*
					 * Do not include table parameters here, will be added in
					 * pltsql_validator()
					 */
					n->parameters = $5;
					tsql_completeDefaultValues(n->parameters);
					/*
					 * Use RECORD type here. In case of single result column,
					 * will be changed to that column's type in
					 * pltsql_validator()
					 */
					n->returnType = SystemTypeName("record");
					n->returnType->setof = true;
					n->returnType->location = @7;
					n->options = list_make2(lang, body);

					$$ = (Node *)n;
				}
		;

/*
 * These rules define the WITH clause in a CREATE PROCEDURE
 * or CREATE FUNCTION statement.  This is very similar to
 * the PostgreSQL common_func_opt_item except for the
 * spelling of the SECURITY DEFINER/SECURITY INVOKER
 * options.
 */

tsql_createfunc_options:
			WITH tsql_createfunc_opt_list
				{ $$ = $2; }
			| /* EMPTY */
				{ $$ = NIL; }
		;

tsql_createfunc_opt_list:
			tsql_createfunc_opt_list ',' tsql_func_opt_item
				{ $$ = lappend($1, $3); }
			| tsql_func_opt_item
				{ $$ = list_make1($1); }
		;

tsql_func_opt_item:
			CALLED ON NULL_P INPUT_P
				{
					$$ = makeDefElem("strict", (Node *)makeInteger(false), @1);
				}
			| RETURNS NULL_P ON NULL_P INPUT_P
				{
					$$ = makeDefElem("strict", (Node *)makeInteger(true), @1);
				}
			| EXECUTE AS OWNER
				{
					/* Equivalent to SECURITY DEFINR */
					$$ = makeDefElem("security", (Node *)makeInteger(true), @1);
				}
			| EXECUTE AS TSQL_CALLER
				{
					/* Equivalent to SECURITY INVOKER */
					$$ = makeDefElem("security", (Node *)makeInteger(false), @1);
				}
            | TSQL_SCHEMABINDING
				{
					TSQLInstrumentation(INSTR_TSQL_SCHEMABINDING);
					/*
					 * We permit the SCHEMABINDING specification but currently
					 * ignore it. SCHEMABINDING should create pg_depend records
					 * between an object (procedure, function, view) and objects
					 * referenced within that procedure/function/view.
					 *
					 * If we ignore this specification, it won't change the way
					 * an application behave. We *will* permit you to drop a
					 * table referenced by a procedure (for example), but that's
					 * not a change in application behavior.  Although it is possible
					 * that we may encounter a an application that programmatically
					 * tries to drop (or alter) an object referenced by a schema-bound
					 * procedure/function/view, the possibility seems remote
					 */
					$$ = makeDefElem("schemabinding", (Node *)makeInteger(false), @1);
				}
		;

/*
 * The following rules define the structure of the formal argument list
 * in a TSQL-style CREATE PROCEDURE command.
 */
tsql_createproc_args:
			'(' tsql_proc_args_list ')'    { $$ = $2; }
			| tsql_proc_args_list          { $$ = $1; }
			| /* EMPTY */                  { $$ = NIL; }
		;

tsql_proc_args_list:
			tsql_proc_arg
				{
					$$ = list_make1($1);
				}
			| tsql_proc_args_list ',' tsql_proc_arg
				{
					$$ = lappend($1, $3);
				}
		;

tsql_opt_arg_dflt:
			'=' a_expr    { $$ = $2; }
			| /* EMPTY */ { $$ = NULL; }
		;
tsql_opt_null_keyword:
			NULL_P			{ $$ = NULL; }
			| /* EMPTY */	{ $$ = NULL; }
		;
tsql_proc_arg:
			param_name opt_as func_type tsql_opt_null_keyword tsql_opt_arg_dflt tsql_opt_output tsql_opt_readonly
				{
					FunctionParameter *n = makeNode(FunctionParameter);

					n->name = $1;
					n->argType = $3;
					n->mode = $6 ? FUNC_PARAM_INOUT : FUNC_PARAM_IN;
					n->defexpr = $5;
					tsql_check_param_readonly($1, $3, $7);

					 $$ = n;
				}
		;

/*
 * The following rules define the structure of the formal argument list
 * in a TSQL-style CREATE FUNCTION command.
 */
tsql_createfunc_args:
				'(' tsql_func_args_list ')'				{ $$ = $2; }
				| '(' ')'								{ $$ = NIL; }
		;

tsql_func_args_list:
			tsql_func_arg
				{
					$$ = list_make1($1);
				}
			| tsql_func_args_list ',' tsql_func_arg
				{
					$$ = lappend($1, $3);
				}
		;

tsql_func_arg:
			param_name opt_as func_type tsql_opt_arg_dflt tsql_opt_readonly
				{
					FunctionParameter *n = makeNode(FunctionParameter);

					n->name = $1;
					n->argType = $3;
					n->mode = FUNC_PARAM_IN;
					n->defexpr = $4;
					tsql_check_param_readonly($1, $3, $5);

					$$ = n;
				}
		;

tsql_func_name:
			type_func_name_keyword
				{
					$$ = list_make1(makeString(pstrdup($1)));
				}
			| ColId
				{
					$$ = list_make1(makeString($1));
				}
			| ColId indirection
				{
					$$ = check_func_name(lcons(makeString($1), $2),
												  yyscanner);
				}
			| tsql_qualified_func_name
				{
					$$ = check_func_name($1, yyscanner);
				}
		;

tsql_qualified_func_name:
		ColId DOT_DOT attr_name
			{
				$$ = list_make3(makeString($1), makeString("dbo"), (Node *)makeString($3));
			}
		| DOT_DOT attr_name
			{
				// We should assemble a list of all procedures that should default to sys schema if more are needed
				if (strcmp($2, "sp_tablecollations_100") == 0)
				{
					$$ = list_make2(makeString("sys"), (Node *)makeString($2));
				}
				else
				{
					$$ = list_make3(makeString("master"), makeString("dbo"), (Node *)makeString($2));
				}
			}
		| '.' attr_name '.' attr_name
			{
				$$ = list_make3(makeString("master"), makeString($2), (Node *)makeString($4));
			}

/*
 * In TSQL dialect, PROC and PROCEDURE are syntactically interchangeable
 */
proc_keyword:
			PROCEDURE									{}
			| TSQL_PROC									{}
		;

tsql_VariableSetStmt:
			SET IDENT var_value
				{
					VariableSetStmt *n = makeNode(VariableSetStmt);
					n->name = psprintf("babelfishpg_tsql.%s", $2);
					n->args = list_make1($3);
					n->is_local = false;
					$$ = (Node *) n;
				}
			| SET LANGUAGE var_value
				{
					VariableSetStmt *n = makeNode(VariableSetStmt);
					TSQLInstrumentation(INSTR_TSQL_OPTION_LANGUAGE);

					n->name = psprintf("babelfishpg_tsql.%s", $2);

					n->args = list_make1($3);
					n->is_local = false;
					$$ = (Node *) n;
				}
			| SET TRANSACTION tsql_IsolationLevel
				{
					VariableSetStmt *n = makeNode(VariableSetStmt);
					n->kind = VAR_SET_MULTI;
					n->name = "SESSION CHARACTERISTICS";
					n->args = $3;
					$$ = (Node *) n;
				}
			| SET TSQL_IDENTITY_INSERT qualified_name opt_boolean_or_string
				{
					VariableSetStmt *n = makeNode(VariableSetStmt);
					TSQLInstrumentation(INSTR_TSQL_OPTION_IDENTITY_INSERT);

					n->name = "babelfishpg_tsql.identity_insert";

					if (strcmp($4, "on") == 0 || strcmp($4, "off") == 0)
					{
						/* Pass in user input with namepath in reverse for simpler assignment */
						if ($3->catalogname != NULL)
						{
							char *input_string = palloc(strlen($4) +
							                            strlen($3->catalogname) +
							                            strlen($3->schemaname) +
							                            strlen($3->relname) +
							                            4);
							input_string = psprintf("%s.%s.%s.%s",
							                        $4,
							                        $3->relname,
							                        $3->schemaname,
							                        $3->catalogname);
							n->args = list_make1(makeStringConst(input_string, @1));
						}
						else if ($3->schemaname != NULL)
						{
							char *input_string = palloc(strlen($4) +
							                            strlen($3->schemaname) +
							                            strlen($3->relname) +
							                            3);
							input_string = psprintf("%s.%s.%s", $4, $3->relname, $3->schemaname);
							n->args = list_make1(makeStringConst(input_string, @1));
						}
						else
						{
							char *input_string = palloc(strlen($4) + strlen($3->relname) + 2);
							input_string = psprintf("%s.%s", $4, $3->relname);
							n->args = list_make1(makeStringConst(input_string, @1));
						}
					}
					else
						ereport(ERROR,
							(errcode(ERRCODE_SYNTAX_ERROR),
							errmsg("improper option"),
							parser_errposition(@4)));

                                        n->is_local = false;
					$$ = (Node *) n;
				}
			| SET TSQL_ALLOW_SNAPSHOT_ISOLATION opt_boolean_or_string
				{
						TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_OPTION_ALLOW_SNAPSHOT_ISOLATION);
						ereport(NOTICE,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							errmsg("ALLOW_SNAPSHOT_ISOLATION option is currently ignored internally. Its default value is true")));
						$$ = NULL;
				}
		;

tsql_alter_table_cmd:
			/* ALTER TABLE <name> ADD [CONSTRAINT <conname>] DEFAULT <expr> FOR <colname> */
			ADD_P tsql_opt_constraint_name DEFAULT a_expr FOR ColId
				{
					AlterTableCmd *n = makeNode(AlterTableCmd);

					if (sql_dialect != SQL_DIALECT_TSQL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
								 parser_errposition(@1)));
					else
						ereport(NOTICE,
								errmsg("DEFAULT added. To drop the default, use ALTER TABLE...ALTER COLUMN..."
									"DROP DEFAULT; it cannot be dropped by name"));

					n->subtype = AT_ColumnDefault;
					n->name = $6;
					n->def = $4;
					$$ = (Node *)n;
				}
			/*
			 * ALTER TABLE <name> ALTER [COLUMN] <colname> [SET DATA] <tsql_typename>
			 *		[ USING <expression> ]
			 */
			| ALTER opt_column ColId opt_set_data TSQL_Typename opt_collate_clause alter_using
				{
					AlterTableCmd *n = makeNode(AlterTableCmd);
					ColumnDef *def = makeNode(ColumnDef);

					TSQLInstrumentation(INSTR_TSQL_ALTER_COLUMN);
					if (sql_dialect != SQL_DIALECT_TSQL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
								 parser_errposition(@1)));
					n->subtype = AT_AlterColumnType;
					n->name = $3;
					n->def = (Node *) def;
					/* We only use these fields of the ColumnDef node */
					def->typeName = $5;
					def->collClause = (CollateClause *) $6;
					def->raw_default = $7;
					def->location = @3;
					$$ = (Node *)n;
				}
			/* ALTER TABLE <name> WITH [NO]CHECK ADD CONSTRAINT ... */
			| WITH tsql_constraint_check ADD_P TableConstraint
				{
					AlterTableCmd *n = makeNode(AlterTableCmd);

					if (sql_dialect != SQL_DIALECT_TSQL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
								 parser_errposition(@1)));
					else
						ereport(NOTICE,
								(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
								 errmsg("The WITH CHECK/NOCHECK option is currently ignored")));

					n->subtype = AT_AddConstraint;
					n->def = $4;
					$$ = (Node *)n;
				}
			/* ALTER TABLE <name> [NO]CHECK CONSTRAINT <conname> */
			| tsql_constraint_check CONSTRAINT name
				{
					if (sql_dialect != SQL_DIALECT_TSQL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
								 parser_errposition(@1)));
					else
						ereport(NOTICE,
								(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
								 errmsg("The CHECK/NOCHECK option is currently ignored")));

					$$ = NULL;
				}
		;

tsql_ColConstraint:
			tsql_ColConstraintElem { $$ = $1; }
		;

tsql_ColConstraintElem: /* nullable */
			  UNIQUE tsql_cluster opt_definition OptConsTableSpace
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_UNIQUE;
					n->location = @1;
					n->keys = NULL;
					n->options = $3;
					n->indexname = NULL;
					n->indexspace = $4;
					$$ = (Node *)n;
				}
			| PRIMARY KEY tsql_cluster opt_definition OptConsTableSpace
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_PRIMARY;
					n->location = @1;
					n->keys = NULL;
					n->options = $4;
					n->indexname = NULL;
					n->indexspace = $5;
					$$ = (Node *)n;
				}
			| IDENTITY_P tsql_OptParenthesizedIdentList
				{
					Constraint *n = makeNode(Constraint);
					if (sql_dialect != SQL_DIALECT_TSQL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
								 parser_errposition(@1)));

					TSQLInstrumentation(INSTR_TSQL_IDENTITY_COLUMN);
					n->contype = CONSTR_IDENTITY;
					n->generated_when = ATTRIBUTE_IDENTITY_ALWAYS;
					n->options = $2;
					n->location = @1;
					$$ = (Node *)n;
				}
			| TSQL_ROWGUIDCOL
				{
					if (sql_dialect != SQL_DIALECT_TSQL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
								 parser_errposition(@1)));
					$$ = NULL;
				}
			| NOT FOR TSQL_REPLICATION
				{
					$$ = NULL;
				}
		;

tsql_TransactionStmt:
			BEGIN_P tsql_TranKeyword tsql_OptTranName
				{
					TransactionStmt *n = makeNode(TransactionStmt);
					n->kind = TRANS_STMT_BEGIN;
					n->savepoint_name = $3;
					n->options = NIL;
					$$ = (Node *)n;
				}
			| COMMIT tsql_TranKeyword tsql_OptTranName
				{
					TransactionStmt *n = makeNode(TransactionStmt);
					n->kind = TRANS_STMT_COMMIT;
					n->options = NIL;
					$$ = (Node *)n;
				}
			| COMMIT tsql_OptWorkKeyword
				{
					TransactionStmt *n = makeNode(TransactionStmt);
					n->kind = TRANS_STMT_COMMIT;
					n->options = NIL;
					$$ = (Node *)n;
				}
			| ROLLBACK tsql_TranKeyword tsql_OptTranName
				{
					TransactionStmt *n = makeNode(TransactionStmt);
					n->kind = TRANS_STMT_ROLLBACK;
					n->savepoint_name = $3;
					n->options = NIL;
					$$ = (Node *)n;
				}
			| ROLLBACK tsql_OptWorkKeyword
				{
					TransactionStmt *n = makeNode(TransactionStmt);
					n->kind = TRANS_STMT_ROLLBACK;
					n->options = NIL;
					$$ = (Node *)n;
				}
			| TSQL_SAVE tsql_TranKeyword ColId
				{
					TransactionStmt *n = makeNode(TransactionStmt);
					n->kind = TRANS_STMT_SAVEPOINT;
					n->savepoint_name = $3;
					$$ = (Node *)n;
				}
			;


tsql_TranKeyword:
			TRANSACTION							{}
			| TSQL_TRAN							{}
		;

tsql_OptWorkKeyword:
			WORK								{}
			| /* Empty */						{}
		;

tsql_OptTranName:
			ColId								{ $$ = $1; }
			| /* Empty */						{ $$ = NULL; }
		;

tsql_IsolationLevel:
			ISOLATION LEVEL tsql_IsolationLevelStr
				{
					$$ = list_make1(makeDefElem("transaction_isolation",
									makeStringConst($3, @3), @1));
				}
		;

tsql_IsolationLevelStr:
			READ UNCOMMITTED
				{
					TSQLInstrumentation(INSTR_TSQL_ISOLATION_LEVEL_READ_UNCOMMITTED);
					$$ = "read uncommitted";
				}
			| READ COMMITTED
				{
					TSQLInstrumentation(INSTR_TSQL_ISOLATION_LEVEL_READ_COMMITTED);
					$$ = "read committed";
				}
			| REPEATABLE READ
				{
					TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_ISOLATION_LEVEL_REPEATABLE_READ);
					ereport(ERROR,
							(errcode(ERRCODE_SYNTAX_ERROR),
							errmsg("REPEATABLE READ isolation level is not supported"),
							parser_errposition(@1)));
				}
			| SNAPSHOT
				{
					TSQLInstrumentation(INSTR_TSQL_ISOLATION_LEVEL_SNAPSHOT);
					$$ = "repeatable read";
				}
			| SERIALIZABLE
				{
					TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_ISOLATION_LEVEL_SERIALIZABLE);
					ereport(ERROR,
							(errcode(ERRCODE_SYNTAX_ERROR),
							errmsg("SERIALIZABLE isolation level is not supported"),
							parser_errposition(@1)));
				}
		;

createdb_opt_item:
			COLLATE ColId
			{
				$$ = makeDefElem("collate", (Node *) makeString($2), @1);
			}
			;
col_name_keyword:
			  TSQL_NVARCHAR
			;

unreserved_keyword:
			  TSQL_ALLOW_SNAPSHOT_ISOLATION
			| TSQL_AUTO
			| TSQL_BASE64
			| TSQL_CALLER
			| TSQL_CERTIFICATE
			| TSQL_CHECK_EXPIRATION
			| TSQL_CHECK_POLICY
			| TSQL_CREDENTIAL
			| TSQL_CLUSTERED
			| TSQL_COLUMNSTORE
			| TSQL_D
			| TSQL_DAYOFYEAR
			| TSQL_DD
			| TSQL_DEFAULT_DATABASE
			| TSQL_DEFAULT_LANGUAGE
			| TSQL_DW
			| TSQL_DY
			| TSQL_EXPLICIT
			| TSQL_HASHED
			| TSQL_HH
			| TSQL_IDENTITY_INSERT
			| TSQL_ISOWK
			| TSQL_ISOWW
			| TSQL_ISO_WEEK
			| TSQL_LOGIN
			| TSQL_M
			| TSQL_MCS
			| TSQL_MICROSECOND
			| TSQL_MILLISECOND
			| TSQL_MM
			| TSQL_MS
			| TSQL_MUST_CHANGE
			| TSQL_N
			| TSQL_NANOSECOND
			| TSQL_NOCHECK
			| TSQL_NOEXPAND
			| TSQL_NOLOCK
			| TSQL_NONCLUSTERED
			| TSQL_NS
			| TSQL_OLD_PASSWORD
			| TSQL_PAGLOCK
			| TSQL_PATH
			| TSQL_PERSISTED
			| TSQL_PROC
			| TSQL_Q
			| TSQL_QQ
			| TSQL_QUARTER
			| TSQL_RAW
			| TSQL_READCOMMITTED
			| TSQL_READPAST
			| TSQL_READUNCOMMITTED
			| TSQL_REPEATABLEREAD
			| TSQL_REPLICATION
			| TSQL_ROOT
			| TSQL_ROWGUIDCOL
			| TSQL_ROWLOCK
			| TSQL_S
			| TSQL_SAVE
			| TSQL_SCHEMABINDING
			| TSQL_SID
			| TSQL_SS
			| TSQL_SUBSTRING
			| TSQL_TABLOCK
			| TSQL_TABLOCKX
			| TSQL_TEXTIMAGE_ON
			| TSQL_TRAN
			| TSQL_TZ
			| TSQL_TZOFFSET
			| TSQL_UNLOCK
			| TSQL_UPDLOCK
			| TSQL_WEEK
			| TSQL_WEEKDAY
			| TSQL_WINDOWS
			| TSQL_WK
			| TSQL_WW
			| TSQL_XLOCK
			| TSQL_YY
			| TSQL_YYYY
		;

reserved_keyword:
			  TSQL_CHOOSE
			| TSQL_CONVERT
			| TSQL_DATEADD
			| TSQL_DATEDIFF
			| TSQL_DATENAME
			| TSQL_DATEPART
			| TSQL_IIF
			| TSQL_OUTPUT
			| TSQL_PARSE
			| TSQL_PERCENT
			| TSQL_READONLY
			| TSQL_TOP
			| TSQL_TRY_CAST
			| TSQL_TRY_CONVERT
			| TSQL_TRY_PARSE
			| TSQL_EXEC
		;
