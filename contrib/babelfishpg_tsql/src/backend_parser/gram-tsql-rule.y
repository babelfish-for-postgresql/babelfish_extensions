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

/* Start of existing grammar rule in gram.y */

parse_toplevel:
			DIALECT_TSQL tsql_stmtmulti
				{
					pg_yyget_extra(yyscanner)->parsetree = $2;
				}
			| MODE_TYPE_NAME DIALECT_TSQL Typename
				{
					pg_yyget_extra(yyscanner)->parsetree = list_make1($3);
				}
		;

tsql_CreateLoginStmt:
			CREATE TSQL_LOGIN RoleId FROM tsql_login_sources
				{
					CreateRoleStmt *n = makeNode(CreateRoleStmt);
					n->stmt_type = ROLESTMT_USER;
					n->role = $3;
					n->options = list_make1(makeDefElem("islogin",
											(Node *)makeBoolean(true),
											@1)); /* Must be first */
					n->options = lappend(n->options,
										 makeDefElem("createdb",
													 (Node *)makeBoolean(false),
													 @1));
					n->options = lappend(n->options,
										 makeDefElem("createrole",
													 (Node *)makeBoolean(false),
													 @1));
					n->options = lappend(n->options,
										 makeDefElem("inherit",
													 (Node *)makeBoolean(true),
													 @1));
					n->options = lappend(n->options,
										 makeDefElem("canlogin",
													 (Node *)makeBoolean(true),
													 @1));
					n->options = lappend(n->options,
										 makeDefElem("name_location",
													 (Node *)makeInteger(@3),
													 @3));
					n->options = list_concat(n->options, $5);
					$$ = (Node *)n;
				}
			| CREATE TSQL_LOGIN RoleId tsql_login_option_list1
				{
					CreateRoleStmt *n = makeNode(CreateRoleStmt);
					n->stmt_type = ROLESTMT_USER;
					n->role = $3;
					n->options = list_make1(makeDefElem("islogin",
											(Node *)makeBoolean(true),
											@1)); /* Must be first */
					n->options = lappend(n->options,
										 makeDefElem("createdb",
													 (Node *)makeBoolean(false),
													 @1));
					n->options = lappend(n->options,
										 makeDefElem("createrole",
													 (Node *)makeBoolean(false),
													 @1));
					n->options = lappend(n->options,
										 makeDefElem("inherit",
													 (Node *)makeBoolean(true),
													 @1));
					n->options = lappend(n->options,
										 makeDefElem("canlogin",
													 (Node *)makeBoolean(true),
													 @1));
					n->options = lappend(n->options,
										 makeDefElem("name_location",
													 (Node *)makeInteger(@3),
													 @3));
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
				{
					$$ = list_make1(makeDefElem("from_windows",
												(Node *)makeBoolean(true),
												@1));
				}
			| TSQL_WINDOWS WITH tsql_windows_options_list
				{
					DefElem *elem = makeDefElem("from_windows",
												(Node *)makeBoolean(true),
												@1);
					if ($2 != NULL)
					{
						$$ = lcons(elem, $3);
					}
					else
					{
						$$ = list_make1(elem);
					}
				}
			| TSQL_CERTIFICATE NonReservedWord
				{
					$$ = NIL;
				}
			| ASYMMETRIC KEY NonReservedWord
				{
					$$ = NIL;
				}
		;

tsql_windows_options_list:
			tsql_windows_options
				{
					$$ = list_make1($1);
				}
			| tsql_windows_options_list ',' tsql_windows_options
				{
					if ($3 != NULL)
					{
						$$ = lappend ($1, $3);
					}
				}
		;

tsql_windows_options:
			TSQL_DEFAULT_DATABASE '=' NonReservedWord
				{
					$$ = makeDefElem("default_database",
									 (Node *)makeString($3),
									 @1);
				}
			| TSQL_DEFAULT_LANGUAGE '=' NonReservedWord
				{
					$$ = NULL;
				}
		;

/*
 * CREATE ROLE statement needs to satisefy the following two use cases
 *
 * 1. TSQL syntax
 * 	This is the TSQL query that users would call in most cases. For example,
 * 		CREATE ROLE role_name [ AUTHORIZAION owner_name ]
 * 	would be mapped into PG syntax
 * 		CREATE ROLE <cur_db>_role_name INHERIT NOLOGIN ROLE '<cur_db>_db_owner'
 * 		[ ADMIN <cur_db>_owner_name ]
 *
 * 2. PSQL syntax
 * 	This is for specific role creating process during Babelfish initialization,
 * 	database creation, etc. For example,
 * 		CREATE ROLE sysadmin CREATEDB CREATEROLE INHERIT ROLE sa_name
 */
tsql_CreateRoleStmt:
			CREATE ROLE RoleId opt_with OptRoleList
				{
					CreateRoleStmt  *n = makeNode(CreateRoleStmt);
					n->stmt_type = ROLESTMT_ROLE;
					n->role = $3;

					/* If there are specified options, this is PSQL syntax */
					if ($5 != NIL)
						n->options = $5;
					/* Otherwise, this is TSQL syntax, do query mapping */
					else
					{
						n->options = list_make1(makeDefElem("isrole",
												(Node *)makeBoolean(true),
												@1)); /* Must be first */
						n->options = lappend(n->options,
											 makeDefElem("inherit",
														 (Node *)makeBoolean(true),
														 @1));
						n->options = lappend(n->options,
											 makeDefElem("canlogin",
														 (Node *)makeBoolean(false),
														 @1));
						/* 
						 * Prepare an empty rolemember option for ROLE 
						 * '<cur_db>_db_owner', we'll fill it in later.
						 */
						n->options = lappend(n->options,
						makeDefElem("rolemembers", NULL, @1));

						n->options = lappend(n->options,
											 makeDefElem("name_location",
														 (Node *)makeInteger(@3),
														 @3));
					}
					$$ = (Node *)n;
				}
			;

tsql_CreateUserStmt:
			CREATE USER RoleId tsql_create_user_login tsql_create_user_options
				{
					CreateRoleStmt	*n = makeNode(CreateRoleStmt);
					RoleSpec		*login;
					List			*rolelist;

					n->stmt_type = ROLESTMT_USER;
					n->role = $3;
					n->options = list_make1(makeDefElem("isuser",
											(Node *)makeBoolean(true),
											@1)); /* Must be first */
					n->options = lappend(n->options,
										 makeDefElem("inherit",
													 (Node *)makeBoolean(true),
													 @1));
					n->options = lappend(n->options,
										 makeDefElem("canlogin",
													 (Node *)makeBoolean(false),
													 @1));
					login = makeRoleSpec(ROLESPEC_CSTRING, @1);
					if ($4 != NULL)
						login->rolename = $4;
					else
						login->rolename = pstrdup($3);
					rolelist = list_make1(login); /* Login must be first */
					n->options = lappend(n->options,
										 makeDefElem("rolemembers",
													 (Node *)rolelist,
													 @1));
					if ($5 != NULL)
						n->options = lappend(n->options, $5);
					n->options = lappend(n->options,
										 makeDefElem("name_location",
													 (Node *)makeInteger(@3),
													 @3));
					$$ = (Node *) n;
				}
		;

tsql_create_user_login:
			FOR TSQL_LOGIN RoleId		{ $$ = $3; }
			| FROM TSQL_LOGIN RoleId	{ $$ = $3; }
			| /* EMPTY */				{ $$ = NULL; }
		;

tsql_create_user_options:
			WITH TSQL_DEFAULT_SCHEMA '=' ColId
				{
					$$ = makeDefElem("default_schema",
									 (Node *)makeString($4),
									 @1);
				}
			| /* EMPTY */	{ $$ = NULL; }
		;

/*
 * Similar to tsql_CreateRoleStmt, we need to satisefy the following two use
 * cases
 *
 * 1. TSQL syntax
 * 	This is the TSQL query that users would call in most cases. For example,
 * 		ALTER ROLE role_name
 * 		{
 * 			ADD MEMBER database_principal
 *			| DROP MEMBER database_principal
 *			| WITH NAME = new_name
 *		}
 *
 * 2. PSQL syntax
 *	This is for specific role altering process during Babelfish upgrade
 *	procedure. For example,
 *		ALTER ROLE dbo WITH createrole;
 */ 
AlterRoleStmt:
			ALTER ROLE ColId ADD_P TSQL_MEMBER RoleSpec
				{
					GrantRoleStmt *n = makeNode(GrantRoleStmt);
					AccessPriv *ap = makeNode(AccessPriv);

					ap->priv_name = $3;
					n->is_grant = true;
					n->granted_roles = list_make1(ap);
					n->grantee_roles = list_make1($6);
					n->opt = NIL;
					n->grantor = NULL;
					$$ = (Node *) n;
				}
			| ALTER ROLE ColId DROP TSQL_MEMBER RoleSpec
				{
					GrantRoleStmt *n = makeNode(GrantRoleStmt);
					AccessPriv *ap = makeNode(AccessPriv);

					ap->priv_name = $3;
					n->is_grant = false;
					n->granted_roles = list_make1(ap);
					n->grantee_roles = list_make1($6);
					n->opt = NIL;
					n->grantor = NULL;
					$$ = (Node *) n;
				}
			| ALTER ROLE RoleSpec WITH NAME_P '=' ColId
				{
					AlterRoleStmt *n = makeNode(AlterRoleStmt);
					n->role = $3;
					n->action = +1; /* add, if there are members */
					n->options = list_make1(makeDefElem("isrole",
											(Node *)makeBoolean(true),
											@1)); /* Must be first */
					n->options = lappend(n->options, 
										 makeDefElem("rename",
													 (Node *)makeString($7),
													 @1));
					$$ = (Node *) n;
				}
			;

tsql_AlterUserStmt:
			ALTER USER RoleSpec WITH tsql_alter_user_options
				{
					AlterRoleStmt *n = makeNode(AlterRoleStmt);
					n->role = $3;
					n->action = +1;	/* add, if there are members */
					n->options = list_make1(makeDefElem("isuser",
											(Node *)makeBoolean(true),
											@1)); /* Must be first */
					n->options = lappend(n->options, $5);
					$$ = (Node *) n;
				}

tsql_alter_user_options:
			TSQL_DEFAULT_SCHEMA '=' ColId
				{
					$$ = makeDefElem("default_schema",
									 (Node *)makeString($3),
									 @1);
				}
			| TSQL_DEFAULT_SCHEMA '=' NULL_P
				{
					$$ = makeDefElem("default_schema",
									 (Node *)makeString(""),
									 @1);
				}
			| NAME_P '=' ColId
				{
					$$ = makeDefElem("rename",
									 (Node *)makeString($3),
									 @1);
				}
			| TSQL_LOGIN '=' RoleId
				{
					RoleSpec	*login = makeRoleSpec(ROLESPEC_CSTRING, @1);
					List		*rolelist;

					login->rolename = pstrdup($3);
					rolelist = list_make1(login);
					$$ = makeDefElem("rolemembers",
									 (Node *)rolelist,
									 @1);
				}
		;

tsql_AlterLoginStmt:
			ALTER TSQL_LOGIN RoleSpec tsql_enable_disable
				{
					AlterRoleStmt *n = makeNode(AlterRoleStmt);
					n->role = $3;
					n->action = +1;	/* add, if there are members */
					n->options = list_make1(makeDefElem("islogin",
											(Node *)makeBoolean(true),
											@1)); /* Must be first */
					if ($4)
						n->options = lappend(n->options,
											 makeDefElem("canlogin",
														 (Node *)makeBoolean(true),
														 @1));
					else
						n->options = lappend(n->options,
											 makeDefElem("canlogin",
														 (Node *)makeBoolean(false),
														 @1));
					$$ = (Node *)n;
				}
			| ALTER TSQL_LOGIN RoleSpec WITH tsql_alter_login_option_list
				{
					AlterRoleStmt *n = makeNode(AlterRoleStmt);
					n->role = $3;
					n->action = +1;	/* add, if there are members */
					n->options = list_make1(makeDefElem("islogin",
											(Node *)makeBoolean(true),
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
											(Node *)makeBoolean(true),
											@1)); /* Must be first */
					$$ = (Node *)n;
				}
		;

tsql_enable_disable_trigger:
			tsql_enable_disable TRIGGER tsql_trigger_list ON relation_expr
				{
					AlterTableCmd *n1;
					AlterTableStmt *n2 = makeNode(AlterTableStmt);
					ListCell *lc;

					foreach(lc, $3)
					{
						List *lst = lfirst_node(List, lc);
						n1 = makeNode(AlterTableCmd);

						if ($1)
						{
							n1->subtype = AT_EnableTrig;
						}
						else
						{
							n1->subtype = AT_DisableTrig;
						}
						
						if (list_length(lst) > 1)
						{
							n1->schemaname = strVal(list_nth(lst,0));
							n1->name = strVal(list_nth(lst,1));
						}
						else
						{
							n1->name = strVal(list_nth(lst,0));
						}
						n2->cmds = list_concat(n2->cmds, list_make1((Node *) n1));
					}

					n2->relation = $5;
					
					n2->objtype = OBJECT_TRIGGER;
					n2->missing_ok = false;
					$$ = (Node *)n2;
				}
			| tsql_enable_disable TRIGGER ALL ON relation_expr
				{
					AlterTableCmd *n1 = makeNode(AlterTableCmd);
					AlterTableStmt *n2 = makeNode(AlterTableStmt);

					if ($1)
					{
						n1->subtype = AT_EnableTrigAll;
					}
					else
					{
						n1->subtype = AT_DisableTrigAll;
					}

					n2->relation = $5;
					n2->cmds = list_make1((Node *) n1);
					n2->objtype = OBJECT_TRIGGER;
					n2->missing_ok = false;
					$$ = (Node *)n2;
				}
		;

tsql_trigger_list:
			tsql_triggername								{ $$ = list_make1($1); }
			| tsql_trigger_list ',' tsql_triggername				{ $$ = lappend($1, $3); }
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

tsql_DropRoleStmt:
			DROP ROLE role_list
				{
					DropRoleStmt	*n = makeNode(DropRoleStmt);
					RoleSpec		*is_role;

					is_role = makeRoleSpec(ROLESPEC_CSTRING, @1);
					is_role->rolename = "is_role";
					n->missing_ok = false;
					n->roles = lcons(is_role, $3);
					$$ = (Node *)n;
				}
			| DROP ROLE IF_P EXISTS role_list
				{
					DropRoleStmt	*n = makeNode(DropRoleStmt);
					RoleSpec        *is_role;

					is_role = makeRoleSpec(ROLESPEC_CSTRING, @1);
					is_role->rolename = "is_role";
					n->missing_ok = true;
					n->roles = lcons(is_role, $5);
					$$ = (Node *)n;
				}
			| DROP USER role_list
				{
					DropRoleStmt	*n = makeNode(DropRoleStmt);
					RoleSpec		*is_user;

					is_user = makeRoleSpec(ROLESPEC_CSTRING, @1);
					is_user->rolename = "is_user";
					n->missing_ok = false;
					n->roles = lcons(is_user, $3);
					$$ = (Node *)n;
				}
			| DROP USER IF_P EXISTS role_list
				{
					DropRoleStmt *n = makeNode(DropRoleStmt);
					RoleSpec		*is_user;

					is_user = makeRoleSpec(ROLESPEC_CSTRING, @1);
					is_user->rolename = "is_user";
					n->missing_ok = true;
					n->roles = lcons(is_user, $5);
					$$ = (Node *)n;
				}

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
			UNIQUE opt_unique_null_treatment tsql_cluster '(' columnList ')' opt_c_include opt_definition OptConsTableSpace
				ConstraintAttributeSpec tsql_opt_on_filegroup
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_UNIQUE;
					n->location = @1;
					n->nulls_not_distinct = !$2;
					n->keys = $5;
					n->including = $7;
					n->options = $8;
					n->indexname = NULL;
					n->indexspace = $9;
					processCASbits($10, @10, "UNIQUE",
								   &n->deferrable, &n->initdeferred, NULL,
								   NULL, yyscanner);
					$$ = (Node *)n;
				}
			| UNIQUE opt_unique_null_treatment tsql_cluster '(' columnListWithOptAscDesc ')' opt_c_include opt_definition OptConsTableSpace
				ConstraintAttributeSpec tsql_opt_on_filegroup
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_UNIQUE;
					n->location = @1;
					n->nulls_not_distinct = !$2;
					n->keys = $5;
					n->including = $7;
					n->options = $8;
					n->indexname = NULL;
					n->indexspace = $9;
					processCASbits($10, @10, "UNIQUE",
								   &n->deferrable, &n->initdeferred, NULL,
								   NULL, yyscanner);
					$$ = (Node *)n;
				}
			| UNIQUE opt_unique_null_treatment '(' columnListWithOptAscDesc ')' opt_c_include opt_definition OptConsTableSpace
				ConstraintAttributeSpec tsql_opt_on_filegroup
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_UNIQUE;
					n->location = @1;
					n->nulls_not_distinct = !$2;
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
			| UNIQUE opt_unique_null_treatment '(' columnList ')' opt_c_include opt_definition OptConsTableSpace
				ConstraintAttributeSpec tsql_on_filegroup
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_UNIQUE;
					n->location = @1;
					n->nulls_not_distinct = !$2;
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
			| UNIQUE opt_unique_null_treatment tsql_cluster ExistingIndex ConstraintAttributeSpec
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_UNIQUE;
					n->location = @1;
					n->nulls_not_distinct = !$2;
					n->keys = NIL;
					n->including = NIL;
					n->options = NIL;
					n->indexname = $4;
					n->indexspace = NULL;
					processCASbits($5, @5, "UNIQUE",
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
			DROP object_type_name_on_any_name tsql_triggername
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
			| DROP object_type_name_on_any_name IF_P EXISTS tsql_triggername
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

tsql_DropIndexStmtSchema:
            SCHEMA name     { $$ = $2;  }
            | /* EMPTY */   { $$ = NULL; }
            ;
 
tsql_DropIndexStmt:
			DROP object_type_any_name name ON name_list tsql_DropIndexStmtSchema
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
					if ($6 != NULL)
					{
						/* SCHEMA clause present, use it to qualify the index name */
						n->objects = list_make1(list_make2(makeString($6), makeString(construct_unique_index_name($3, makeRangeVarFromAnyName($5, @5, yyscanner)->relname))));  
					}
					else 
					{
						/* SCHEMA clause not present */
						n->objects = list_make1(list_make1(makeString(construct_unique_index_name($3, makeRangeVarFromAnyName($5, @5, yyscanner)->relname))));   
					}
					n->behavior = DROP_CASCADE;
					n->concurrent = false;
					$$ = (Node *)n;
				}
			| DROP object_type_any_name IF_P EXISTS name ON name_list tsql_DropIndexStmtSchema
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
					if ($8 != NULL)
					{
						/* SCHEMA clause present, use it to qualify the index name */
						n->objects = list_make1(list_make2(makeString($8), makeString(construct_unique_index_name($5, makeRangeVarFromAnyName($7, @5, yyscanner)->relname))));  
					}
					else 
					{
						/* SCHEMA clause not present */
						n->objects = list_make1(list_make1(makeString(construct_unique_index_name($5, makeRangeVarFromAnyName($7, @5, yyscanner)->relname))));   
					}
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

tsql_UpdateStmt: opt_with_clause UPDATE opt_top_clause relation_expr_opt_alias
			tsql_opt_table_hint_expr
			SET set_clause_list
			from_clause
			where_or_current_clause
			returning_clause
				{
					UpdateStmt *n = makeNode(UpdateStmt);
					tsql_reset_update_delete_globals();
					n->withClause = $1;
					n->limitCount = $3;
					n->relation = $4;
					n->targetList = $7;
					n->fromClause = $8;
					n->whereClause = $9;
					n->returningList = $10;
					$$ = (Node *)n;
				}
			/* OUTPUT syntax */
				| opt_with_clause UPDATE opt_top_clause relation_expr_opt_alias
				tsql_opt_table_hint_expr
				SET set_clause_list
				tsql_output_clause
				from_clause
				where_or_current_clause
					{
						UpdateStmt *n = makeNode(UpdateStmt);
						tsql_reset_update_delete_globals();
						n->relation = $4;
						tsql_update_delete_stmt_from_clause_alias(n->relation, $9);
						n->targetList = $7;
						if ($9 != NULL && IsA(linitial($9), JoinExpr))
						{
							n = (UpdateStmt*)tsql_update_delete_stmt_with_join(
												(Node*)n, $9, $10, $3, $4,
												yyscanner);
						}
						else
						{
							n->limitCount = $3;
							n->fromClause = $9;
							n->whereClause = $10;
						}
						tsql_check_update_output_transformation($8);
						n->returningList = $8;
						n->withClause = $1;
						$$ = (Node *)n;
					}
				/* OUTPUT INTO syntax with OUTPUT target column list */
				| opt_with_clause UPDATE opt_top_clause relation_expr_opt_alias
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
				| opt_with_clause UPDATE opt_top_clause relation_expr_opt_alias
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
			select_clause tsql_for_xml_clause
				{
					/*
					 * rewrite the query as "SELECT tsql_select_for_xml_agg(rows, ...) FROM (select_clause) AS rows"
					 */
					SelectStmt *stmt = (SelectStmt *) makeNode(SelectStmt);
					stmt->targetList = list_make1(TsqlForXMLMakeFuncCall((TSQL_ForClause *) $2));
					stmt->fromClause = list_make1(TsqlForClauseSubselect($1));
					$$ = (Node *) stmt;
				}
			| select_clause sort_clause tsql_for_xml_clause
				{
					insertSelectOptions((SelectStmt *) $1, $2, NIL,
										NULL, NULL,
										yyscanner);
					if ($3 == NULL)
						$$ = $1;
					else
					{
						SelectStmt *stmt = (SelectStmt *) makeNode(SelectStmt);
						stmt->targetList = list_make1(TsqlForXMLMakeFuncCall((TSQL_ForClause *) $3));
						stmt->fromClause = list_make1(TsqlForClauseSubselect($1));
						$$ = (Node *) stmt;
					}
				}
			| with_clause select_clause tsql_for_xml_clause
				{
					insertSelectOptions((SelectStmt *) $2, NULL, NIL,
										NULL,
										$1,
										yyscanner);
					if ($3 == NULL)
						$$ = $2;
					else
					{
						SelectStmt *stmt = (SelectStmt *) makeNode(SelectStmt);
						stmt->targetList = list_make1(TsqlForXMLMakeFuncCall((TSQL_ForClause *) $3));
						stmt->fromClause = list_make1(TsqlForClauseSubselect($2));
						$$ = (Node *) stmt;
					}
				}
			| with_clause select_clause sort_clause tsql_for_xml_clause
				{
					insertSelectOptions((SelectStmt *) $2, $3, NIL,
										NULL,
										$1,
										yyscanner);
					if ($4 == NULL)
						$$ = $2;
					else
					{
						SelectStmt *stmt = (SelectStmt *) makeNode(SelectStmt);
						stmt->targetList = list_make1(TsqlForXMLMakeFuncCall((TSQL_ForClause *) $4));
						stmt->fromClause = list_make1(TsqlForClauseSubselect($2));
						$$ = (Node *) stmt;
					}
				}
			| select_clause tsql_for_json_clause
				{
					/*
					 * rewrite the query as "SELECT tsql_select_for_json_agg(rows, ...) FROM (select_clause) AS rows"
					 */
					SelectStmt *stmt = (SelectStmt *) makeNode(SelectStmt);
					stmt->targetList = list_make1(TsqlForJSONMakeFuncCall((TSQL_ForClause *) $2));
					stmt->fromClause = list_make1(TsqlForClauseSubselect($1));
					$$ = (Node *) stmt;
				}
			| select_clause sort_clause tsql_for_json_clause
				{
					insertSelectOptions((SelectStmt *) $1, $2, NIL,
										NULL, NULL,
										yyscanner);
					if ($3 == NULL)
						$$ = $1;
					else
					{
						SelectStmt *stmt = (SelectStmt *) makeNode(SelectStmt);
						stmt->targetList = list_make1(TsqlForJSONMakeFuncCall((TSQL_ForClause *) $3));
						stmt->fromClause = list_make1(TsqlForClauseSubselect($1));
						$$ = (Node *) stmt;
					}
				}
			| with_clause select_clause tsql_for_json_clause
				{
					insertSelectOptions((SelectStmt *) $2, NULL, NIL,
										NULL,
										$1,
										yyscanner);
					if ($3 == NULL)
						$$ = $2;
					else
					{
						SelectStmt *stmt = (SelectStmt *) makeNode(SelectStmt);
						stmt->targetList = list_make1(TsqlForJSONMakeFuncCall((TSQL_ForClause *) $3));
						stmt->fromClause = list_make1(TsqlForClauseSubselect($2));
						$$ = (Node *) stmt;
					}
				}
			| with_clause select_clause sort_clause tsql_for_json_clause
				{
					insertSelectOptions((SelectStmt *) $2, $3, NIL,
										NULL,
										$1,
										yyscanner);
					if ($4 == NULL)
						$$ = $2;
					else
					{
						SelectStmt *stmt = (SelectStmt *) makeNode(SelectStmt);
						stmt->targetList = list_make1(TsqlForJSONMakeFuncCall((TSQL_ForClause *) $4));
						stmt->fromClause = list_make1(TsqlForClauseSubselect($2));
						$$ = (Node *) stmt;
					}
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
					n->groupClause = ($8)->list;
					n->groupDistinct = ($8)->distinct;
					n->havingClause = $9;
					n->windowClause = $10;
					n->isPivot = false;
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
					n->groupClause = ($8)->list;
					n->groupDistinct = ($8)->distinct;
					n->havingClause = $9;
					n->windowClause = $10;
					n->isPivot = false;
					$$ = (Node *)n;
				}
			| SELECT opt_all_clause tsql_top_clause opt_target_list
			into_clause from_clause tsql_pivot_expr alias_clause where_clause
			group_clause having_clause window_clause 
				{
					SelectStmt *n = makeNode(SelectStmt);
					n->limitCount = $3;
					if ($3 != NULL && $4 == NULL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("Target list missing from TOP clause"),
								 errhint("For example, TOP n COLUMNS ..."),
								 parser_errposition(@3)));
					n->intoClause = $5;
					n->whereClause = $9;
					n->groupClause = ($10)->list;
					n->groupDistinct = ($10)->distinct;
					n->havingClause = $11;
					n->windowClause = $12;
					$$ = tsql_pivot_select_transformation($4, $6, (List *)$7, $8, n);
				}
			| SELECT distinct_clause tsql_top_clause target_list
			into_clause from_clause tsql_pivot_expr alias_clause where_clause
			group_clause having_clause window_clause 
				{
					SelectStmt *n = makeNode(SelectStmt);
					n->limitCount = $3;
					if ($3 != NULL && $4 == NULL)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("Target list missing from TOP clause"),
								 errhint("For example, TOP n COLUMNS ..."),
								 parser_errposition(@3)));
					n->intoClause = $5;
					n->whereClause = $9;
					n->groupClause = ($10)->list;
					n->groupDistinct = ($10)->distinct;
					n->havingClause = $11;
					n->windowClause = $12;
					$$ = tsql_pivot_select_transformation($4, $6, (List *)$7, $8, n);
				}	
			| SELECT opt_all_clause opt_target_list
			into_clause from_clause tsql_pivot_expr alias_clause where_clause
			group_clause having_clause window_clause 
				{
					SelectStmt *n = makeNode(SelectStmt);
					n->intoClause = $4;
					n->whereClause = $8;
					n->groupClause = ($9)->list;
					n->groupDistinct = ($9)->distinct;
					n->havingClause = $10;
					n->windowClause = $11;
					$$ = tsql_pivot_select_transformation($3, $5, (List *)$6, $7, n);
				}
			| SELECT distinct_clause target_list
			into_clause from_clause tsql_pivot_expr alias_clause where_clause
			group_clause having_clause window_clause
				{
					SelectStmt *n = makeNode(SelectStmt);
					n->intoClause = $4;
					n->whereClause = $8;
					n->groupClause = ($9)->list;
					n->groupDistinct = ($9)->distinct;
					n->havingClause = $10;
					n->windowClause = $11;
					$$ = tsql_pivot_select_transformation($3, $5, (List *)$6, $7, n);
				}
			| tsql_values_clause							{ $$ = $1; }
			;

tsql_pivot_expr: TSQL_PIVOT '(' func_name '(' columnref ')' FOR columnref IN_P '(' columnList ')' ')'
				{						
					ColumnRef 		*a_star;
					ColumnRef		*agg_col;
					ResTarget 		*a_star_restarget;
					RangeSubselect 	*range_sub_select;
					Alias 			*temptable_alias;
					String 			*pivot_colstr;
					String 			*agg_colstr;
					List    		*ret;
					List 			*column_list;
					List			*column_const_list;
					ListCell 		*lc;
					
					SelectStmt 	*category_sql = makeNode(SelectStmt);
					SelectStmt 	*valuelists_sql = makeNode(SelectStmt);
					ResTarget	*restarget_aggfunc = makeNode(ResTarget);

					a_star = makeNode(ColumnRef);
					a_star->fields = list_make1(makeNode(A_Star));
					a_star->location = -1;
					a_star_restarget = makeNode(ResTarget);
					a_star_restarget->name = NULL;
					a_star_restarget->name_location = -1;
					a_star_restarget->indirection = NIL;
					a_star_restarget->val = (Node *) a_star;
					a_star_restarget->location = -1;

					/* prepare aggregation function for pivot source sql */
					agg_col = (ColumnRef *)$5;
					restarget_aggfunc->name = NULL;
					restarget_aggfunc->name_location = -1;
					restarget_aggfunc->indirection = NIL;
					restarget_aggfunc->val = (Node *) makeFuncCall($3, list_make1(agg_col),
																   COERCE_EXPLICIT_CALL,
																   @3);
					restarget_aggfunc->location = -1;

					agg_colstr = list_nth_node(String, agg_col->fields, ((List *)agg_col->fields)->length - 1);
					column_list = (List *)$11;
					column_const_list = NIL;

					foreach(lc ,column_list)
					{
						Node 	*column_const;
						String 	*column_str;

						column_str = (String *)lfirst(lc);

						if (column_str != NULL && strcmp(column_str->sval, agg_colstr->sval) == 0)
							ereport(ERROR,
									(errcode(ERRCODE_SYNTAX_ERROR),
										errmsg("The column name \"%s\" specified in the PIVOT operator conflicts with the existing column name in the PIVOT argument.", agg_colstr->sval),
										parser_errposition(@5)));

						column_const = makeStringConst(pstrdup(column_str->sval), -1);
						column_const_list = lappend(column_const_list, list_make1(column_const));
					}

					temptable_alias = makeNode(Alias);
					temptable_alias->aliasname = "pivotTempTable";
					/* get the column name from the columnref*/
					pivot_colstr = llast(((ColumnRef *)$8)->fields);
					temptable_alias->colnames = list_make1(copyObject(pivot_colstr));
					
					valuelists_sql->valuesLists = column_const_list;

					range_sub_select = makeNode(RangeSubselect);
					range_sub_select->subquery = (Node *) valuelists_sql;
					range_sub_select->alias = temptable_alias;

					category_sql->targetList = list_make1(a_star_restarget);
					category_sql->fromClause = list_make1(range_sub_select);

					ret = list_make4($8, restarget_aggfunc, category_sql, column_list);
					$$ = (Node*) ret; 
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
			| TSQL_APPLY func_table func_alias_clause
				{
					RangeFunction *n = (RangeFunction *) $2;
					n->lateral = true;
					n->alias = linitial($3);
					n->coldeflist = lsecond($3);
					$$ = (Node *) n;
				}
			| TSQL_APPLY select_with_parens opt_alias_clause
				{
					RangeSubselect *n = makeNode(RangeSubselect);
					n->lateral = true;
					n->subquery = $2;
					n->alias = $3;
					/*
					 * The SQL spec does not permit a subselect
					 * (<derived_table>) without an alias clause,
					 * so we don't either.  This avoids the problem
					 * of needing to invent a unique refname for it.
					 * That could be surmounted if there's sufficient
					 * popular demand, but for now let's just implement
					 * the spec and see if anyone complains.
					 * However, it does seem like a good idea to emit
					 * an error message that's better than "syntax error".
					 */
					if ($3 == NULL)
					{
						if (IsA($2, SelectStmt) &&
							((SelectStmt *) $2)->valuesLists)
							ereport(ERROR,
									(errcode(ERRCODE_SYNTAX_ERROR),
										errmsg("VALUES in APPLY must have an alias"),
										errhint("For example, FROM (VALUES ...) [AS] foo."),
										parser_errposition(@2)));
						else
							ereport(ERROR,
									(errcode(ERRCODE_SYNTAX_ERROR),
										errmsg("subquery in APPLY must have an alias"),
										errhint("For example, FROM (SELECT ...) [AS] foo."),
										parser_errposition(@2)));
					}
					$$ = (Node *) n;
				}
			| TSQL_APPLY relation_expr opt_alias_clause
				{
					$2->alias = $3;
					$$ = (Node *) $2;
				}
			| TSQL_APPLY openjson_expr
				{
					/*
					 * This case handles openjson cross/outer apply
					 */
					$$ = (Node *) $2;
				}
			| openjson_expr
				{
					/*
					 * Standard openjson case
					 */
					$$ = (Node *) $1;
				}
		;

openjson_expr: OPENJSON '(' a_expr  ')' opt_alias_clause
				{
					RangeFunction *n = makeNode(RangeFunction);
					n->alias = $5;
					n->lateral = false;
					n->ordinality = false;
					n->is_rowsfrom = false;
					n->functions = list_make1(list_make2(TsqlOpenJSONSimpleMakeFuncCall($3, NULL), NIL));
					/* map to OPENJSON_SIMPLE */
					$$ = (Node*) n;
				}
			| OPENJSON '(' a_expr ',' a_expr ')' opt_alias_clause
				{
					RangeFunction *n = makeNode(RangeFunction);
					n->alias = $7;
					n->lateral = false;
					n->ordinality = false;
					n->is_rowsfrom = false;
					n->functions = list_make1(list_make2(TsqlOpenJSONSimpleMakeFuncCall($3, $5), NIL));
					/* map to OPENJSON_SIMPLE */
					$$ = (Node*) n;
				}
			| OPENJSON '(' a_expr ')' WITH_paren '(' openjson_col_defs ')' opt_alias_clause
				{
					/* map to OPENJSON_WITH */

					RangeFunction *n = (RangeFunction *) TsqlOpenJSONWithMakeFuncCall($3, (Node*) makeStringConst("$", -1), $7, $9);
					n->lateral = false;
					n->ordinality = false;
					n->is_rowsfrom = false;
					$$ = (Node*) n;
				}
			| OPENJSON '(' a_expr ',' a_expr ')' WITH_paren '(' openjson_col_defs ')' opt_alias_clause
				{
					/* map to OPENJSON_WITH */

					RangeFunction *n = (RangeFunction *) TsqlOpenJSONWithMakeFuncCall($3, $5, $9, $11);
					n->lateral = false;
					n->ordinality = false;
					n->is_rowsfrom = false;
					$$ = (Node*) n;
				}
		;


openjson_col_defs: openjson_col_def
				{
					$$ = list_make1($1);
				}
			| openjson_col_defs ',' openjson_col_def
				{
					$$ = lappend($1, $3);
				}
		;

openjson_col_def: ColId Typename optional_path optional_asJson
				{
					/* create col_def_struct */
					OpenJson_Col_Def *n = (OpenJson_Col_Def *) palloc(sizeof(OpenJson_Col_Def));
					n->elemName = $1;
					n->elemType = $2;
					n->elemPath = $3;
					n->asJson = $4;
					$$ = (Node*) n;
				}
		;

optional_path:
			Sconst
				{
					$$ = $1;
				}
			| /* EMPTY */
				{
					$$ = "";
				}
		;

optional_asJson:
			AS TSQL_JSON
				{
					$$ = true;
				}
			| /* EMPTY */
				{
					$$ = false;
				}
		;

joined_table:
			table_ref TSQL_CROSS table_ref
				{
					/* CROSS APPLY is the same as CROSS JOIN LATERAL */
					JoinExpr *n = makeNode(JoinExpr);
					n->jointype = JOIN_INNER;
					n->isNatural = false;
					n->larg = $1;
					n->rarg = $3;
					n->usingClause = NIL;
					n->join_using_alias = NULL;
					n->quals = NULL;
					$$ = n;
				}
			| table_ref TSQL_OUTER table_ref
				{
					/* OUTER APPLY is the same as LEFT JOIN LATERAL */
					JoinExpr *n = makeNode(JoinExpr);
					n->jointype = JOIN_LEFT;
					n->isNatural = false;
					n->larg = $1;
					n->rarg = $3;
					n->usingClause = NIL;
					n->join_using_alias = NULL;
					n->quals = NULL;
					$$ = n;
				}
		;

func_expr_common_subexpr:
			UPDATE_paren '(' NonReservedWord_or_Sconst ')'
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("update"),
											   list_make1(makeStringConst($3,@3)),
											   COERCE_EXPLICIT_CALL,
											   @1);
				}
			| TSQL_TRY_CAST '(' a_expr AS Typename ')'
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
											   COERCE_EXPLICIT_CALL,
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
											   COERCE_EXPLICIT_CALL,
											   @1);
				}
			| TSQL_DATEDIFF_BIG '(' datediff_arg ',' a_expr ',' a_expr ')'
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("datediff_big"),
											   list_make3(makeStringConst($3, @3), $5, $7),
											   COERCE_EXPLICIT_CALL,
											   @1);
				}
			| TSQL_DATE_BUCKET '(' datediff_arg ',' a_expr ',' a_expr ')'
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("date_bucket"),
												list_make3(makeStringConst($3, @3), $5, $7),
												COERCE_EXPLICIT_CALL,
												@1);
				}
			| TSQL_DATE_BUCKET '(' datediff_arg ',' a_expr ',' a_expr ',' a_expr ')'
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("date_bucket"),
												list_make4(makeStringConst($3, @3), $5, $7, $9),
												COERCE_EXPLICIT_CALL,
												@1);
				}
			| TSQL_DATEPART '(' datepart_arg ',' a_expr ')'
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("datepart"),
											   list_make2(makeStringConst($3, @3), $5),
											   COERCE_EXPLICIT_CALL,
											   @1);
				}
			| TSQL_DATETRUNC '(' datepart_arg ',' a_expr ')'
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("datetrunc"),
												list_make2(makeStringConst($3, @3), $5),
												COERCE_EXPLICIT_CALL,
												@1);
				}
			| TSQL_DATENAME '(' datepart_arg ',' a_expr ')'
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("datename"),
											   list_make2(makeStringConst($3, @3), $5),
											   COERCE_EXPLICIT_CALL,
											   @1);
				}
			| TSQL_ISNULL '(' a_expr ',' a_expr ')'
				{
					CoalesceExpr *c = makeNode(CoalesceExpr);
					c->args=list_make2($3, $5);
					c->location = @1;
					c->tsql_is_null = true;
					$$ = (Node *)c;
				}
			| TSQL_IIF '(' a_expr ',' a_expr ',' a_expr ')'
				{
					$$ = TsqlFunctionIIF($3, $5, $7, @1);
				}
			| TSQL_ATAT IDENT
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2($2), NIL, COERCE_EXPLICIT_CALL, @1);
				}
			| TSQL_ATAT VERSION_P
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("version"),NIL, COERCE_EXPLICIT_CALL, @1);
				}
			| TSQL_ATAT IDENTITY_P
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_get_last_identity_numeric"), NIL, COERCE_EXPLICIT_CALL, @1);
				}
			| TSQL_ATAT LANGUAGE
	 			{
	 				$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("language"),NIL, COERCE_EXPLICIT_CALL, @1);
				}
			| JSON_MODIFY '(' a_expr ',' a_expr ',' a_expr ')'
				{
					$$ = (Node *) TsqlJsonModifyMakeFuncCall($3, $5, $7);
				}
			| IDENTITY_P '(' Typename ',' a_expr ',' a_expr ')'
				{
					if (escape_hatch_identity_function)
					{
						$$ = TsqlFunctionIdentityInto($3, $5, $7, @1);	
					}
					else
					{
						ereport(ERROR,
							(errcode(ERRCODE_SYNTAX_ERROR),
							errmsg("To use IDENTITY(), set \'babelfishpg_tsql.escape_hatch_identity_function\' to \'ignore\'"),
							parser_errposition(@1)));
					}
				}
			| IDENTITY_P '(' Typename ',' a_expr ')'
				{ 
					if (escape_hatch_identity_function)
					{
						$$ = TsqlFunctionIdentityInto($3, $5, (Node *)makeIntConst(1, -1), @1);
					}
					else
					{
						ereport(ERROR,
							(errcode(ERRCODE_SYNTAX_ERROR),
							errmsg("To use IDENTITY(), set \'babelfishpg_tsql.escape_hatch_identity_function\' to \'ignore\'"),
							parser_errposition(@1)));
					}
					
				}
			| IDENTITY_P '(' Typename ')'
				{
					if (escape_hatch_identity_function)
					{
						$$ = TsqlFunctionIdentityInto($3, (Node *)makeIntConst(1, -1), (Node *)makeIntConst(1, -1), @1);
					}
					else
					{
						ereport(ERROR,
							(errcode(ERRCODE_SYNTAX_ERROR),
							errmsg("To use IDENTITY(), set \'babelfishpg_tsql.escape_hatch_identity_function\' to \'ignore\'"),
							parser_errposition(@1)));
					}
				}
			| TSQL_CONTAINS '(' var_name ',' tsql_contains_search_condition ')'
				{
					$$ = TsqlExpressionContains($3, $5, yyscanner);
				}
			| TSQL_LOG '(' a_expr ')'
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("bbf_log"),
											   list_make1($3),
											   COERCE_EXPLICIT_CALL,
											   @1);
				}
			| TSQL_LOG '(' a_expr ',' a_expr ')'
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("bbf_log"),
											   list_make2($3, $5),
											   COERCE_EXPLICIT_CALL,
											   @1);
				}
			| TSQL_LOG10 '(' a_expr ')'
				{
					$$ = (Node *) makeFuncCall(TsqlSystemFuncName2("bbf_log10"),
											   list_make1($3),
											   COERCE_EXPLICIT_CALL,
											   @1);
				}
		;

tsql_contains_search_condition:
			a_expr
				{
					$$ = $1;
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
					/* Include a typmod based on the length of the literal */
					int32 typmod = strlen($2);
					if (typmod == 0)
						typmod = 2; /* typmod can't be 0 */
					else if (typmod > 4000)
						typmod = TSQLMaxTypmod;
					t->location = @1;
					t->typmods = list_make1(makeIntConst(typmod, -1));
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
			SELECT opt_all_clause opt_top_clause opt_target_list
			into_clause from_clause where_clause
			group_clause having_clause window_clause
				{
					SelectStmt *n = makeNode(SelectStmt);
					n->limitCount = $3;
					n->targetList = $4;
					n->intoClause = $5;
					n->fromClause = $6;
					n->whereClause = $7;
					n->groupClause = ($8)->list;
					n->groupDistinct = ($8)->distinct;
					n->havingClause = $9;
					n->windowClause = $10;
					n->isPivot = false;
					$$ = (Node *)n;
				}
			| SELECT distinct_clause opt_top_clause target_list
			into_clause from_clause where_clause
			group_clause having_clause window_clause
				{
					SelectStmt *n = makeNode(SelectStmt);
					n->distinctClause = $2;
					n->limitCount = $3;
					n->targetList = $4;
					n->intoClause = $5;
					n->fromClause = $6;
					n->whereClause = $7;
					n->groupClause = ($8)->list;
					n->groupDistinct = ($8)->distinct;
					n->havingClause = $9;
					n->windowClause = $10;
					n->isPivot = false;
					$$ = (Node *)n;
				}
			| SELECT opt_all_clause opt_top_clause opt_target_list
			into_clause from_clause tsql_pivot_expr alias_clause where_clause
			group_clause having_clause window_clause
				{
					SelectStmt *n = makeNode(SelectStmt);
					n->limitCount = $3;
					n->intoClause = $5;
					n->whereClause = $9;
					n->groupClause = ($10)->list;
					n->groupDistinct = ($10)->distinct;
					n->havingClause = $11;
					n->windowClause = $12;
					$$ = tsql_pivot_select_transformation($4, $6, (List *)$7, $8, n);
				}
			| SELECT distinct_clause opt_top_clause target_list
			into_clause from_clause tsql_pivot_expr alias_clause where_clause
			group_clause having_clause window_clause
				{
					SelectStmt *n = makeNode(SelectStmt);
					n->distinctClause = $2;
					n->limitCount = $3;
					n->intoClause = $5;
					n->whereClause = $9;
					n->groupClause = ($10)->list;
					n->groupDistinct = ($10)->distinct;
					n->havingClause = $11;
					n->windowClause = $12;
					$$ = tsql_pivot_select_transformation($4, $6, (List *)$7, $8, n);
				}
			| tsql_values_clause							{ $$ = $1; }
			| tsql_output_simple_select UNION set_quantifier tsql_output_simple_select
				{
					$$ = makeSetOp(SETOP_UNION, $3 == SET_QUANTIFIER_ALL, $1, $4);
				}
			| tsql_output_simple_select INTERSECT set_quantifier tsql_output_simple_select
				{
					$$ = makeSetOp(SETOP_INTERSECT, $3 == SET_QUANTIFIER_ALL, $1, $4);
				}
			| tsql_output_simple_select EXCEPT set_quantifier tsql_output_simple_select
				{
					$$ = makeSetOp(SETOP_EXCEPT, $3 == SET_QUANTIFIER_ALL, $1, $4);
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
					TSQL_OUTPUT tsql_output_target_list	{ $$ = $2; }
		;

tsql_output_target_list:
			tsql_output_target_el								{ $$ = list_make1($1); }
			| tsql_output_target_list ',' tsql_output_target_el				{ $$ = lappend($1, $3); }
		;


tsql_output_target_el: /* same as target_el but BareColLabel is not allowed. keep a_expr IDENT instead */
				a_expr AS AS_ColLabel
				{
					$$ = makeNode(ResTarget);
					$$->name = $3;
					$$->name_location = @3;
					$$->indirection = NIL;
					$$->val = (Node *)$1;
					$$->location = @1;
				}
			/*
			 * We support omitting AS only for column labels that aren't
			 * any known keyword.  There is an ambiguity against postfix
			 * operators: is "a ! b" an infix expression, or a postfix
			 * expression and a column label?  We prefer to resolve this
			 * as an infix expression, which we accomplish by assigning
			 * IDENT a precedence higher than POSTFIXOP.
			 */
			| a_expr IDENT
				{
					$$ = makeNode(ResTarget);

					/* In TSQL we need to preserve the case of the AS clause in the outermost
					 * query block, at least.  Target list references must be resolved case-
					 * insensitively when the database collation is case-insensitive.
					 */
					$$->name = $2;
					$$->name_location = @2;
					$$->indirection = NIL;
					$$->val = (Node *)$1;
					$$->location = @1;
				}
			| a_expr
				{
					$$ = makeNode(ResTarget);
					$$->name = NULL;
					$$->name_location = -1;
					$$->indirection = NIL;
					$$->val = (Node *)$1;
					$$->location = @1;
				}
			| '*'
				{
					ColumnRef *n = makeNode(ColumnRef);
					n->fields = list_make1(makeNode(A_Star));
					n->location = @1;

					$$ = makeNode(ResTarget);
					$$->name = NULL;
					$$->name_location = -1;
					$$->indirection = NIL;
					$$->val = (Node *)n;
					$$->location = @1;
				}
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
					n->funccall = makeFuncCall(name, args, COERCE_EXPLICIT_CALL, @1);

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
			| AlterFunctionStmt
			| tsql_AlterFunctionStmt
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
			| tsql_AlterUserStmt
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
			| tsql_CreatePartitionStmt
			| CreateStmt
			| CreateSubscriptionStmt
			| CreateStatsStmt
			| CreateTableSpaceStmt
			| CreateTransformStmt
			| tsql_CreateTrigStmt
			| CreateEventTrigStmt
			| tsql_CreateRoleStmt
			| tsql_CreateUserStmt
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
			| tsql_DropIndexStmt
			| DropStmt
			| DropSubscriptionStmt
			| DropTableSpaceStmt
			| DropTransformStmt
			| DropUserMappingStmt
			| tsql_DropRoleStmt
			| DropdbStmt
			| tsql_enable_disable_trigger
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

/*
 * The Opt clauses are included in the tsql_CreatePartitionStmt rule
 * to resolve a shift-reduce conflict with the CreateStmt rule.
 * Although semantically it is not required for TSQL partitioned table creation,
 * its inclusion ensures that the parser can unambiguously distinguish
 * between regular table creation and TSQL partitioned table creation statements.
 */
tsql_CreatePartitionStmt:
			CREATE OptTemp TABLE qualified_name '(' OptTableElementList ')'
			OptInherit OptPartitionSpec table_access_method_clause OptWith
			tsql_PartitionSpec
				{
					CreateStmt *n = makeNode(CreateStmt);
					n->relation = $4;
					n->tableElts = $6;
					n->inhRelations = NIL;
					n->partspec = $12;
					n->ofTypename = NULL;
					n->constraints = NIL;
					n->accessMethod = NULL;
					n->options = NIL;
					n->oncommit = ONCOMMIT_NOOP;
					n->tablespacename = NULL;
					n->if_not_exists = false;
					$$ = (Node *) n;
				}
		;

tsql_PartitionSpec:
			ON tsql_untruncated_IDENT '(' part_params ')'
				{
					PartitionSpec *n = makeNode(PartitionSpec);
					n->tsql_partition_scheme = $2;
					n->strategy = PARTITION_STRATEGY_RANGE;
					n->partParams = $4;
					n->location = @1;
					$$ = n;
				}
		;


 /*
  * TSQL untruncated identfiers:
  *	This rule handles the parsing of untruncated identifiers in TSQL.
  *	Unlike PostgreSQL, which truncates identifier when they exceeds the
  *	maximum allowed length (NAMEDATALEN), while in TSQL, for certain cases we
  *	want to parse identifiers with lengths exceeding such limit.
  *	
  *	This rule extract the entire identifier string from the input buffer,
  *	regardless of its length.
  */
tsql_untruncated_IDENT:
			IDENT
				{
					/*
					 * Retrieve the "extra" information attached to the scanner
					 * to access the input string (the string being parsed).
					 */
					base_yy_extra_type *yyextra = pg_yyget_extra(yyscanner);

					/*
					 * Extract the original, untruncated identifier from the input buffer.
					 * Here, @1 represents the start location of the identifier token.
					 */
					$$ = extract_identifier(yyextra->core_yy_extra.scanbuf + @1, NULL);
					
				}
		;

tsql_opt_INTO:
			INTO
			| /* empty */
		;

tsql_InsertStmt:
			opt_with_clause INSERT opt_top_clause tsql_opt_INTO insert_target tsql_opt_table_hint_expr '(' insert_column_list ')'
			tsql_output_insert_rest
				{
					$10->limitCount = $3;
					$10->relation = $5;
					$10->onConflictClause = NULL;
					$10->returningList = NULL;
					$10->withClause = $1;
					$10->cols = $8;
					$$ = (Node *) $10;
				}
			| opt_with_clause INSERT opt_top_clause tsql_opt_INTO insert_target tsql_opt_table_hint_expr tsql_output_insert_rest
				{
					$7->limitCount = $3;
					$7->relation = $5;
					$7->onConflictClause = NULL;
					$7->returningList = NULL;
					$7->withClause = $1;
					$7->cols = NIL;
					$$ = (Node *) $7;
				}
			| opt_with_clause INSERT opt_top_clause tsql_opt_INTO insert_target tsql_opt_table_hint_expr DEFAULT TSQL_VALUES
				{
					InsertStmt *i = makeNode(InsertStmt);
					i->limitCount = $3;
					i->relation = $5;
					i->onConflictClause = NULL;
					i->returningList = NULL;
					i->withClause = $1;
					i->cols = NIL;
					i->selectStmt = NULL;
					i->execStmt = NULL;
					$$ = (Node *) i;
				}
			/* OUTPUT syntax */
			| opt_with_clause INSERT opt_top_clause tsql_opt_INTO insert_target tsql_opt_table_hint_expr '(' insert_column_list ')'
			 tsql_output_clause tsql_output_insert_rest_no_paren 
				{
					if ($11->execStmt)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("The OUTPUT clause cannot be used in an INSERT...EXEC statement."),
								 parser_errposition(@10)));
					$11->limitCount = $3;
					$11->relation = $5;
					$11->onConflictClause = NULL;
					$11->returningList = $10;
					$11->withClause = $1;
					$11->cols = $8;
					$$ = (Node *) $11;
				}
			| opt_with_clause INSERT opt_top_clause tsql_opt_INTO insert_target tsql_opt_table_hint_expr tsql_output_clause tsql_output_insert_rest_no_paren 
				{
					if ($8->execStmt)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("The OUTPUT clause cannot be used in an INSERT...EXEC statement."),
								 parser_errposition(@7)));
					$8->limitCount = $3;
					$8->relation = $5;
					$8->onConflictClause = NULL;
					$8->returningList = $7;
					$8->withClause = $1;
					$8->cols = NIL;
					$$ = (Node *) $8;
				}
			/* conflict on DEFAULT (DEFAULT is allowed as a_expr in tsql_output_clause
			| opt_with_clause INSERT opt_top_clause tsql_opt_INTO insert_target tsql_opt_table_hint_expr tsql_output_clause DEFAULT VALUES
				{
					InsertStmt *i = makeNode(InsertStmt);
					i->limitCount = $3;
					i->relation = $5;
					i->onConflictClause = NULL;
					i->returningList = $7;
					i->withClause = $1;
					i->cols = NIL;
					i->selectStmt = NULL;
					i->execStmt = NULL;
					$$ = (Node *) i;
				}
			*/
			/* OUTPUT INTO syntax with OUTPUT target column list */
			| opt_with_clause INSERT opt_top_clause tsql_opt_INTO insert_target tsql_opt_table_hint_expr '(' insert_column_list ')'
			tsql_output_clause INTO insert_target tsql_output_into_target_columns tsql_output_insert_rest
				{
					if ($14->execStmt)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("The OUTPUT clause cannot be used in an INSERT...EXEC statement."),
								 parser_errposition(@14)));
					$$ = tsql_insert_output_into_cte_transformation($1, $3, $5, $8, $10, $12, $13, $14, 5);
				}
			| opt_with_clause INSERT opt_top_clause tsql_opt_INTO insert_target tsql_opt_table_hint_expr tsql_output_clause 
			INTO insert_target tsql_output_into_target_columns tsql_output_insert_rest
				{
					if ($11->execStmt)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("The OUTPUT clause cannot be used in an INSERT...EXEC statement."),
								 parser_errposition(@10)));
					$$ = tsql_insert_output_into_cte_transformation($1, $3, $5, NULL, $7, $9, $10, $11, 5);
				}
			| opt_with_clause INSERT opt_top_clause tsql_opt_INTO insert_target tsql_opt_table_hint_expr tsql_output_clause 
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
					$$ = tsql_insert_output_into_cte_transformation($1, $3, $5, NULL, $7, $9, $10, i, 5);
				}
			/* Without OUTPUT target column list */
			| opt_with_clause INSERT opt_top_clause tsql_opt_INTO insert_target tsql_opt_table_hint_expr '(' insert_column_list ')'
			tsql_output_clause INTO insert_target tsql_output_insert_rest_no_paren
				{
					if ($13->execStmt)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("The OUTPUT clause cannot be used in an INSERT...EXEC statement."),
								 parser_errposition(@13)));
					$$ = tsql_insert_output_into_cte_transformation($1, $3, $5, $8, $10, $12, NIL, $13, 5);
				}
			| opt_with_clause INSERT opt_top_clause tsql_opt_INTO insert_target tsql_opt_table_hint_expr tsql_output_clause 
			INTO insert_target tsql_output_insert_rest_no_paren
				{
					if ($10->execStmt)
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("The OUTPUT clause cannot be used in an INSERT...EXEC statement."),
								 parser_errposition(@9)));
					$$ = tsql_insert_output_into_cte_transformation($1, $3, $5, NULL, $7, $9, NIL, $10, 5);
				}
			/*
			| opt_with_clause INSERT opt_top_clause tsql_opt_INTO insert_target tsql_opt_table_hint_expr tsql_output_clause 
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
					$$ = tsql_insert_output_into_cte_transformation($1, $3, $5, NULL, $7, $9, NIL, i, 5);
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
					n->funccall = makeFuncCall(name, args, COERCE_EXPLICIT_CALL, @1);

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
					n->funccall = makeFuncCall(name, args, COERCE_EXPLICIT_CALL, @1);

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
tsql_for_xml_clause:
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
			
			check_server_role_and_throw_if_unsupported($4, @4, yyscanner);

			ap->priv_name = $4;
			n->is_grant = true;
			n->granted_roles = list_make1(ap);
			n->grantee_roles = list_make1($7);
			n->opt = NIL;
			n->grantor = NULL;
			$$ = (Node *) n;
		}
		| ALTER TSQL_SERVER ROLE ColId DROP TSQL_MEMBER RoleSpec
		{
			GrantRoleStmt *n = makeNode(GrantRoleStmt);
			AccessPriv *ap = makeNode(AccessPriv);
			
			check_server_role_and_throw_if_unsupported($4, @4, yyscanner);

			ap->priv_name = $4;
			n->is_grant = false;
			n->granted_roles = list_make1(ap);
			n->grantee_roles = list_make1($7);
			n->opt = NIL;
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

 					n1->trigname = ((String *)list_nth($3,0))->sval;
					n1->relation = $5;
					/*
					 * Function with the same name as the
					 * trigger will be created as part of
					 * this create trigger command.
					 */
					n1->funcname = $3;
 					if (list_length($3) > 1){
	 					n1->trigname = ((String *)list_nth($3,1))->sval;
						/*
						* Used a hack way to pass the schema name from args, in CR-58614287
						* Args will be set back to NIL in pl_handler pltsql_pre_parse_analyze()
						* before calling backend functios
						*/
	 					n1->args = list_make1(makeString(((String *)list_nth($3,0))->sval));
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

					nt_inserted = makeNode(TriggerTransition);
					nt_inserted->name = "inserted";
					nt_inserted->isNew = true;
					nt_inserted->isTable = true;
					n1->transitionRels = lappend(n1->transitionRels, nt_inserted);

					nt_deleted = makeNode(TriggerTransition);
					nt_deleted->name = "deleted";
					nt_deleted->isNew = false;
					nt_deleted->isTable = true;
					n1->transitionRels = lappend(n1->transitionRels, nt_deleted);

					n2->is_procedure = false;
					n2->replace = true;
					n2->funcname = $3;
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
			INDEX opt_concurrently opt_single_name
			ON relation_expr access_method_clause '(' index_params ')'
			opt_include where_clause opt_reloptions
			tsql_opt_partition_scheme_or_filegroup
				{
					IndexStmt *n = makeNode(IndexStmt);
					n->unique = $2;
					n->concurrent = $6;
					n->idxname = $7;
					n->relation = $9;
					n->accessMethod = $10;
					n->indexParams = $12;
					n->indexIncludingParams = $14;
					n->nulls_not_distinct = $2;
					n->whereClause = $15;
					n->options = $16;
					n->excludeOpNames = $17;
					n->idxcomment = NULL;
					n->indexOid = InvalidOid;
					n->oldNumber = InvalidOid;
					n->primary = false;
					n->isconstraint = false;
					n->deferrable = false;
					n->initdeferred = false;
					n->transformed = false;
					n->if_not_exists = false;

					tsql_index_nulls_order(n->indexParams, n->accessMethod);
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
 * TSQL support for partition scheme and filegroup
 */

tsql_opt_partition_scheme_or_filegroup:
			ON tsql_untruncated_IDENT '(' ColId ')'
				{
					$$ =  list_make2(makeString($2), makeString($4));
				}
			| tsql_on_filegroup
				{
					$$ = NIL;
				}
			| /*EMPTY*/
				{
					$$ = NIL;
				}
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
					n->limitCount = $3;
					n->relation = $5;
					n->usingClause = $7;
					n->whereClause = $8;
					n->returningList = NULL;
					n->withClause = $1;
					$$ = (Node *)n;
				}
			/* OUTPUT syntax */
			| opt_with_clause DELETE_P opt_top_clause opt_from relation_expr_opt_alias
			tsql_opt_table_hint_expr tsql_output_clause from_clause where_or_current_clause
				{
					DeleteStmt *n = makeNode(DeleteStmt);
					tsql_reset_update_delete_globals();
					n->relation = $5;
					n->limitCount = $3;
					n->usingClause = $8;
					n->whereClause = $9;
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
						if(IsA(&n->val, Integer) && n->val.ival.ival == 100)
						{
								$$ = NULL;
						}
						else if(IsA(&n->val, Float) && atof(n->val.fval.fval) == 100.0)
						{
								$$ = NULL;
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
					if(IsA(&n->val, Integer) && n->val.ival.ival == 100)
					{
							$$ = NULL;
					}
					else if(IsA(&n->val, Float) && atof(n->val.fval.fval) == 100.0)
					{
							$$ = NULL;
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
			| TSQL_Y								{ $$ = "doy"; }
			| DAY_P									{ $$ = "day"; }
			| TSQL_DD								{ $$ = "day"; }
			| TSQL_D								{ $$ = "day"; }
			| TSQL_WEEK								{ $$ = "tsql_week"; }
			| TSQL_WK								{ $$ = "tsql_week"; }
			| TSQL_WW								{ $$ = "tsql_week"; }
			| TSQL_W								{ $$ = "dow"; }
			| TSQL_WEEKDAY							{ $$ = "dow"; }
			| TSQL_DW								{ $$ = "dow"; }
			| HOUR_P								{ $$ = "hour"; }
			| TSQL_HH								{ $$ = "hour"; }
			| TSQL_MI								{ $$ = "minute"; }
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
			| TSQL_Y								{ $$ = "doy"; }
			| DAY_P									{ $$ = "day"; }
			| TSQL_DD								{ $$ = "day"; }
			| TSQL_D								{ $$ = "day"; }
			| TSQL_W								{ $$ = "day"; }
			| TSQL_WEEK								{ $$ = "week"; }
			| TSQL_WK								{ $$ = "week"; }
			| TSQL_WW								{ $$ = "week"; }
			| HOUR_P								{ $$ = "hour"; }
			| TSQL_HH								{ $$ = "hour"; }
			| TSQL_MI								{ $$ = "minute"; }
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
			| TSQL_Y								{ $$ = "dayofyear"; }
			| DAY_P									{ $$ = "day"; }
			| TSQL_DD								{ $$ = "day"; }
			| TSQL_D								{ $$ = "day"; }
			| TSQL_WEEK								{ $$ = "week"; }
			| TSQL_WK								{ $$ = "week"; }
			| TSQL_WW								{ $$ = "week"; }
			| TSQL_W								{ $$ = "weekday"; }
			| TSQL_WEEKDAY							{ $$ = "weekday"; }
			| TSQL_DW								{ $$ = "weekday"; }
			| HOUR_P								{ $$ = "hour"; }
			| TSQL_HH								{ $$ = "hour"; }
			| TSQL_MI								{ $$ = "minute"; }
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
						DefElem *location = makeDefElem("location", (Node *) makeInteger(@4), @4);
						/* 
						 *	Adding a option for volatility with value STABLE. 
						 *	Function created from tsql dialect will be created as STABLE
						 *	by default
						 */
						DefElem *vol = makeDefElem("volatility", (Node *) makeString("stable"), @1);
						n->is_procedure = false;
						n->replace = $2;
						n->funcname = $4;
						n->parameters = $5;
						n->returnType = $7;
						n->options = list_concat(list_make4(lang, body, location, vol), $8);
						$$ = (Node *)n;
					}
			| CREATE opt_or_replace proc_keyword tsql_func_name tsql_createproc_args
			  tsql_createfunc_options AS tokens_remaining
				{
					CreateFunctionStmt *n = makeNode(CreateFunctionStmt);
					DefElem *lang = makeDefElem("language", (Node *) makeString("pltsql"), @1);
					DefElem *body = makeDefElem("as", (Node *) list_make1(makeString($8)), @8);
					DefElem *location = makeDefElem("location", (Node *) makeInteger(@4), @4);

					n->is_procedure = true;
					n->replace = $2;
					n->funcname = $4;
					n->parameters = $5;
					n->returnType = NULL;
					n->options = list_concat(list_make3(lang, body, location), $6);
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
					$$ = buildTsqlMultiLineTvfNode(@1, $2, $4, @4, $5, $7, @8, $10, $13, @13, false, yyscanner);
				}
			/* TSQL inline table-valued function */
			| CREATE opt_or_replace FUNCTION func_name tsql_createfunc_args
			  RETURNS TABLE opt_as tokens_remaining
				{
					CreateFunctionStmt *n = makeNode(CreateFunctionStmt);
					DefElem *lang = makeDefElem("language", (Node *) makeString("pltsql"), @1);
					DefElem *body = makeDefElem("as", (Node *) list_make1(makeString($9)), @9);
					DefElem *location = makeDefElem("location", (Node *) makeInteger(@4), @4);

					TSQLInstrumentation(INSTR_TSQL_CREATE_FUNCTION_RETURNS_TABLE);
					n->is_procedure = false;
					n->replace = $2;
					n->funcname = $4;
					/*
					 * Do not include table parameters here, will be added in
					 * pltsql_validator()
					 */
					n->parameters = $5;
					/*
					 * Use RECORD type here. In case of single result column,
					 * will be changed to that column's type in
					 * pltsql_validator()
					 */
					n->returnType = SystemTypeName("record");
					n->returnType->setof = true;
					n->returnType->location = @7;
					n->options = list_make3(lang, body, location);

					$$ = (Node *)n;
				}
		;

tsql_AlterFunctionStmt:
			TSQL_ALTER proc_keyword tsql_func_name tsql_createproc_args
			tsql_createfunc_options AS tokens_remaining
				{
					ObjectWithArgs *owa = makeNode(ObjectWithArgs);
					AlterFunctionStmt *n = makeNode(AlterFunctionStmt);
					DefElem *lang = makeDefElem("language", (Node *) makeString("pltsql"), @1);
					DefElem *body = makeDefElem("as", (Node *) list_make1(makeString($7)), @7);
					DefElem *location = makeDefElem("location", (Node *) makeInteger(@3), @3);

					/* Fill in the ObjectWithArgs node */
					owa->objname = $3;
					owa->objargs = extractArgTypes($4);
					owa->objfuncargs = $4;

					/* now fill in the AlterFunctionStmt node */
					n->objtype = OBJECT_PROCEDURE;
					n->func = owa;
					n->actions = list_concat(list_make3(lang, body, location), $5); // piggy-back on actions to just put the new proc body instead
					$$ = (Node *) n;
				}
			| TSQL_ALTER FUNCTION func_name tsql_createfunc_args
			  RETURNS func_return tsql_createfunc_options opt_as tokens_remaining
				{
					ObjectWithArgs *owa = makeNode(ObjectWithArgs);
					AlterFunctionStmt *n = makeNode(AlterFunctionStmt);
					DefElem *lang = makeDefElem("language", (Node *) makeString("pltsql"), @1);
					DefElem *body = makeDefElem("as", (Node *) list_make1(makeString($9)), @9);
					DefElem *location = makeDefElem("location", (Node *) makeInteger(@3), @3);
					/* 
					 *	Adding a option for volatility with value STABLE. 
					 *	Function created from tsql dialect will be created as STABLE
					 *	by default
					 */
					DefElem *vol = makeDefElem("volatility", (Node *) makeString("stable"), @1);
					
					/* Remove return defelem from list after extracting in pl_handler*/
					DefElem *ret = makeDefElem("return", (Node *) $6, @6);

					/* Fill in the ObjectWithArgs node */
					owa->objname = $3;
					owa->objargs = extractArgTypes($4);
					owa->objfuncargs = $4;

					n->objtype = OBJECT_PROCEDURE; /* Set as proc to avoid psql alter func impl */
					n->func = owa;
					n->actions = list_concat(list_make5(lang, body, location, vol, ret), $7); // piggy-back on actions to just put the new proc body instead
					$$ = (Node *) n;
				}
			| TSQL_ALTER FUNCTION func_name tsql_createfunc_args
			  RETURNS TABLE opt_as tokens_remaining
				{
					ObjectWithArgs *owa = makeNode(ObjectWithArgs);
					AlterFunctionStmt *n = makeNode(AlterFunctionStmt);
					DefElem *lang = makeDefElem("language", (Node *) makeString("pltsql"), @1);
					DefElem *body = makeDefElem("as", (Node *) list_make1(makeString($8)), @8);
					DefElem *location = makeDefElem("location", (Node *) makeInteger(@3), @3);
					TypeName *returnType = SystemTypeName("record");
					DefElem *ret;
					
					/*
					 * Do not include table parameters here, will be added in
					 * pltsql_validator()
					 */
					
					owa->objname = $3;
					owa->objargs = extractArgTypes($4);
					owa->objfuncargs = $4;

					/*
					 * Use RECORD type here. In case of single result column,
					 * will be changed to that column's type in
					 * pltsql_validator()
					 */
					
					returnType = SystemTypeName("record");
					returnType->setof = true;
					returnType->location = @6;
					ret = makeDefElem("return", (Node *) returnType, @6);

					n->objtype = OBJECT_PROCEDURE; /* Set as proc to avoid psql alter func impl */
					n->func = owa;
					n->actions = list_make4(lang, body, location, ret); // piggy-back on actions to just put the new proc body instead
					$$ = (Node *)n;
				}
			| TSQL_ALTER FUNCTION func_name tsql_createfunc_args
              RETURNS param_name TABLE '(' OptTableElementList ')' opt_as tokens_remaining
                {
					$$ = buildTsqlMultiLineTvfNode(@1, false, $3, @3, $4, $6, @7, $9, $12, @12, true, yyscanner);
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
					$$ = makeDefElem("strict", (Node *)makeBoolean(false), @1);
				}
			| RETURNS NULL_P ON NULL_P INPUT_P
				{
					$$ = makeDefElem("strict", (Node *)makeBoolean(true), @1);
				}
			| EXECUTE AS OWNER
				{
					/* Equivalent to SECURITY DEFINR */
					$$ = makeDefElem("security", (Node *)makeBoolean(true), @1);
				}
			| EXECUTE AS TSQL_CALLER
				{
					/* Equivalent to SECURITY INVOKER */
					$$ = makeDefElem("security", (Node *)makeBoolean(false), @1);
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
					$$ = makeDefElem("schemabinding", (Node *)makeBoolean(false), @1);
				}
				| TSQL_RECOMPILE
				{
					/* Only applies to procedures, the ANTLR parser has already processed this clause */
					$$ = makeDefElem("recompile", (Node *) makeBoolean(true), @1);
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
			| SET tsql_TranKeyword tsql_IsolationLevel
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
			  UNIQUE opt_unique_null_treatment tsql_cluster opt_definition OptConsTableSpace
				{
					Constraint *n = makeNode(Constraint);
					n->contype = CONSTR_UNIQUE;
					n->location = @1;
					n->nulls_not_distinct = !$2;
					n->keys = NULL;
					n->options = $4;
					n->indexname = NULL;
					n->indexspace = $5;
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
					if (pltsql_isolation_level_repeatable_read)
					{
						TSQLInstrumentation(INSTR_TSQL_ISOLATION_LEVEL_REPEATABLE_READ);
						$$ = "repeatable read";	
					}
					else
					{
						TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_ISOLATION_LEVEL_REPEATABLE_READ);
						ereport(ERROR,
							(errcode(ERRCODE_SYNTAX_ERROR),
							errmsg("Isolation level 'REPEATABLE READ' is not currently supported in Babelfish. Set 'babelfishpg_tsql.isolation_level_repeatable_read' config option to 'pg_isolation' to get PG repeatable read isolation level."),
							parser_errposition(@1)));
					}

				}
			| SNAPSHOT
				{
					TSQLInstrumentation(INSTR_TSQL_ISOLATION_LEVEL_SNAPSHOT);
					$$ = "repeatable read";
				}
			| SERIALIZABLE
				{
					if (pltsql_isolation_level_serializable)
					{
						TSQLInstrumentation(INSTR_TSQL_ISOLATION_LEVEL_SERIALIZABLE);
						$$ = "serializable";
					}
					else
					{
						TSQLInstrumentation(INSTR_UNSUPPORTED_TSQL_ISOLATION_LEVEL_SERIALIZABLE);
						ereport(ERROR,
							(errcode(ERRCODE_SYNTAX_ERROR),
							errmsg("Isolation level 'SERIALIZABLE' is not currently supported in Babelfish. Set 'babelfishpg_tsql.isolation_level_serializable' config option to 'pg_isolation' to get PG serializable isolation level."),
							parser_errposition(@1)));
					}
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
			| OPENJSON
			| JSON_MODIFY
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
			| TSQL_DEFAULT_SCHEMA
			| TSQL_DW
			| TSQL_DY
			| TSQL_EXPLICIT
			| TSQL_HASHED
			| TSQL_HH
			| TSQL_IDENTITY_INSERT
			| TSQL_INCLUDE_NULL_VALUES
			| TSQL_ISOWK
			| TSQL_ISOWW
			| TSQL_ISO_WEEK
			| TSQL_JSON
			| TSQL_LOGIN
			| TSQL_M
			| TSQL_MCS
			| TSQL_MEMBER
			| TSQL_MI
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
			| TSQL_RECOMPILE
			| TSQL_REPEATABLEREAD
			| TSQL_REPLICATION
			| TSQL_ROOT
			| TSQL_ROWGUIDCOL
			| TSQL_ROWLOCK
			| TSQL_S
			| TSQL_SAVE
			| TSQL_SCHEMABINDING
			| TSQL_SERVER
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
			| TSQL_W
			| TSQL_WEEK
			| TSQL_WEEKDAY
			| TSQL_WINDOWS
			| TSQL_WITHOUT_ARRAY_WRAPPER
			| TSQL_WK
			| TSQL_WW
			| TSQL_XLOCK
			| TSQL_Y
			| TSQL_YY
			| TSQL_YYYY
		;

reserved_keyword:
			  TSQL_APPLY
			| TSQL_CHOOSE
			| TSQL_CONVERT
			| TSQL_CROSS
			| TSQL_DATEADD
			| TSQL_DATEDIFF
			| TSQL_DATEDIFF_BIG
			| TSQL_DATE_BUCKET
			| TSQL_DATENAME
			| TSQL_DATEPART
			| TSQL_DATETRUNC
			| TSQL_LOG
			| TSQL_LOG10
			| TSQL_IIF
			| TSQL_OUT
			| TSQL_OUTER
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

bare_label_keyword:
			  TSQL_CONTAINS
		;

privilege:
			UPDATE_paren '(' columnList ')'
			{
				AccessPriv *n = makeNode(AccessPriv);
				n->priv_name = "update";
				n->cols = $3;
				$$ = n;
			}
		;

privilege_target:
			OBJECT_P TYPECAST qualified_name_list
			{
				PrivTarget *n = (PrivTarget *) palloc(sizeof(PrivTarget));
				n->targtype = ACL_TARGET_OBJECT;
				n->objtype = OBJECT_TABLE;
				n->objs = $3;
				$$ = n;
			}
		;

GrantStmt:
			GRANT privileges ON qualified_name_list '(' columnList ')' 
			TO grantee_list opt_grant_grant_option
				{
					GrantStmt *n = makeNode(GrantStmt);
					ListCell *lc;

					foreach(lc, $2)
					{
						AccessPriv *ap = (AccessPriv *) lfirst(lc);
						ap->cols = $6;
					}

					n->is_grant = true;
					n->privileges = $2;
					n->targtype = ACL_TARGET_OBJECT;
					n->objtype = OBJECT_TABLE;
					n->objects = $4;
					n->grantees = $9;
					n->grant_option = $10;
					$$ = (Node*)n;
				}
		;
	
RevokeStmt:
            REVOKE privileges ON privilege_target
            TO grantee_list opt_drop_behavior
                {
                    GrantStmt *n = makeNode(GrantStmt);
                    n->is_grant = false;
                    n->grant_option = false;
                    n->privileges = $2;
                    n->targtype = ($4)->targtype;
                    n->objtype = ($4)->objtype;
                    n->objects = ($4)->objs;
                    n->grantees = $6;
                    n->behavior = $7;
                    $$ = (Node *)n;
                }
            | REVOKE GRANT OPTION FOR privileges ON privilege_target
            TO grantee_list opt_drop_behavior
                {
                    GrantStmt *n = makeNode(GrantStmt);
                    n->is_grant = false;
                    n->grant_option = true;
                    n->privileges = $5;
                    n->targtype = ($7)->targtype;
                    n->objtype = ($7)->objtype;
                    n->objects = ($7)->objs;
                    n->grantees = $9;
                    n->behavior = $10;
                    $$ = (Node *)n;
                }
			| REVOKE privileges ON qualified_name_list '(' columnList ')'
			FROM grantee_list opt_drop_behavior
				{
					GrantStmt *n = makeNode(GrantStmt);
					ListCell *lc;

					foreach(lc, $2)
					{
						AccessPriv *ap = (AccessPriv *) lfirst(lc);
						ap->cols = $6;
					}

					n->is_grant = false;
					n->grant_option = false;
					n->privileges = $2;
					n->targtype = ACL_TARGET_OBJECT;
					n->objtype = OBJECT_TABLE;
					n->objects = $4;
					n->grantees = $9;
					n->behavior = $10;
					$$ = (Node *)n;
				}
			| REVOKE GRANT OPTION FOR privileges ON qualified_name_list
			'(' columnList ')' FROM grantee_list opt_drop_behavior
				{
					GrantStmt *n = makeNode(GrantStmt);
					ListCell *lc;

					foreach(lc, $5)
					{
						AccessPriv *ap = (AccessPriv *) lfirst(lc);
						ap->cols = $9;
					}

					n->is_grant = false;
					n->grant_option = true;
					n->privileges = $5;
					n->targtype = ACL_TARGET_OBJECT;
					n->objtype = OBJECT_TABLE;
					n->objects = $7;
					n->grantees = $12;
					n->behavior = $13;
					$$ = (Node *)n;
				}
			| REVOKE privileges ON qualified_name_list '(' columnList ')'
			TO grantee_list opt_drop_behavior
				{
                    GrantStmt *n = makeNode(GrantStmt);
					ListCell *lc;

					foreach(lc, $2)
					{
						AccessPriv *ap = (AccessPriv *) lfirst(lc);
						ap->cols = $6;
					}

                    n->is_grant = false;
                    n->grant_option = false;
                    n->privileges = $2;
                    n->targtype = ACL_TARGET_OBJECT;
                    n->objtype = OBJECT_TABLE;
                    n->objects = $4;
                    n->grantees = $9;
                    n->behavior = $10;
                    $$ = (Node *)n;
                }
			| REVOKE GRANT OPTION FOR privileges ON qualified_name_list
			'(' columnList ')' TO grantee_list opt_drop_behavior
	            {
                    GrantStmt *n = makeNode(GrantStmt);
					ListCell *lc;

					foreach(lc, $5)
					{
						AccessPriv *ap = (AccessPriv *) lfirst(lc);
						ap->cols = $9;
					}

                    n->is_grant = false;
                    n->grant_option = true;
                    n->privileges = $5;
                    n->targtype = ACL_TARGET_OBJECT;
                    n->objtype = OBJECT_TABLE;
                    n->objects = $7;
                    n->grantees = $12;
                    n->behavior = $13;
                    $$ = (Node *)n;
                }			
        ;

/*
 * FOR JSON clause can have 2 modes: AUTO and PATH.
 * Map the mode to the corresponding ENUM.
 */
tsql_for_json_clause:
			TSQL_FOR TSQL_JSON TSQL_AUTO tsql_for_json_common_directives
			{
				TSQL_ForClause *n = (TSQL_ForClause *) palloc(sizeof(TSQL_ForClause));
				n->mode = TSQL_FORJSON_AUTO;
				n->commonDirectives = $4;
				n->location = @1;
				$$ = (Node *) n;
			}
			| TSQL_FOR TSQL_JSON TSQL_PATH tsql_for_json_common_directives
			{
				TSQL_ForClause *n = (TSQL_ForClause *) palloc(sizeof(TSQL_ForClause));
				n->mode = TSQL_FORJSON_PATH;
				n->commonDirectives = $4;
				n->location = @1;
				$$ = (Node *) n;
			}
		;


tsql_for_json_common_directives:
			tsql_for_json_common_directives ',' tsql_for_json_common_directive
			{
				$$ = lappend($1, $3);
			}
			| /*EMPTY*/													{ $$ = NIL; }
		;

/*
 * FOR JSON clause can have 3 directives: ROOT, INCLUDE_NULL_VALUES and WITHOUT_ARRAY_WRAPPER.
 * Map them to ENUM TSQLJSONDirective and String of the ROOT name respectively.
 */
tsql_for_json_common_directive:
			TSQL_ROOT									{ $$ = makeStringConst("root", -1); }
			| TSQL_ROOT '(' Sconst ')'					{ $$ = makeStringConst($3, -1); }
			| TSQL_INCLUDE_NULL_VALUES					{ $$ = makeIntConst(TSQL_JSON_DIRECTIVE_INCLUDE_NULL_VALUES, -1); }
			| TSQL_WITHOUT_ARRAY_WRAPPER				{ $$ = makeIntConst(TSQL_JSON_DIRECTIVE_WITHOUT_ARRAY_WRAPPER, -1); }
		;
