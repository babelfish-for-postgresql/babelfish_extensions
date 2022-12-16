#include "postgres.h"

#include "miscadmin.h"
#include "nodes/parsenodes.h"
#include "nodes/primnodes.h"
#include "nodes/value.h"
#include "nodes/nodeFuncs.h"
#include "parser/scansup.h"
#include "parser/parser.h"
#include "utils/acl.h"
#include "utils/builtins.h"
#include "utils/guc.h"

#include "catalog.h"
#include "guc.h"
#include "multidb.h"
#include "session.h"

/* rewrite function for data structures */
static void rewrite_rangevar(RangeVar *rv);
static void rewrite_objectwithargs(ObjectWithArgs *obj);
void rewrite_plain_name(List *name);  /* Value Strings */
static void rewrite_schema_name(String *schema);
static void rewrite_role_name(RoleSpec *role);

static void rewrite_rangevar_list(List *rvs);  /* list of RangeVars */
static void rewrite_objectwithargs_list(List *objs);  /* list of ObjectWithArgs */
static void rewrite_plain_name_list(List *names); /* list of plan names */
static void rewrite_schema_name_list(List *schemas); /* list of schema names */
static void rewrite_type_name_list(List *typenames); /* list of type names */
static void rewrite_role_list(List *rolespecs); /* list of RoleSpecs */

static bool rewrite_relation_walker(Node *node, void *context);


/* helper functions */
static void truncate_tsql_identifier(char *ident);


/*************************************************************
 * 					Toggle for Rewriting
 *************************************************************/

bool
enable_schema_mapping(void)
{
	if (!DbidIsValid(get_cur_db_id()))  /* TODO: remove it after cur_db_oid() is enforeced */
		return false;

	if (!get_cur_db_name())
		return false;

	return true;
}


/*************************************************************
 * 						Statement Traverse
 *************************************************************/

void
rewrite_object_refs(Node *stmt)
{
	/*
	 *  TODO: Add check for mutlidb mode
	 */

	if (sql_dialect != SQL_DIALECT_TSQL)
		return;

	switch (stmt->type)
	{
		case T_SelectStmt:
		case T_UpdateStmt:
		case T_DeleteStmt:
		case T_InsertStmt:
		{
			/* walker supported stmts */
		    raw_expression_tree_walker(stmt,
                                       rewrite_relation_walker,
                                       (void *) NULL);
			break;
		}
		case T_AlterTableStmt:
		{
			AlterTableStmt *alter_table = (AlterTableStmt *) stmt;
			ListCell *c;

			rewrite_rangevar(alter_table->relation);

			foreach(c, alter_table->cmds)
			{
				AlterTableCmd *cmd = lfirst(c);
				
				switch(cmd->subtype)
				{
				case AT_ColumnDefault:
				{
					ColumnDef *def = (ColumnDef *) cmd->def;

					rewrite_relation_walker((Node *) def, (void *) NULL);
					break;
				}
				case AT_AddColumn:
				case AT_AlterColumnType:
				{
					ColumnDef *def = (ColumnDef *) cmd->def;
					ListCell *clist;

					foreach(clist, def->constraints)
					{
						Constraint *constraint = lfirst_node(Constraint, clist);

						rewrite_relation_walker(constraint->raw_expr, (void *) NULL);

						if (constraint->contype == CONSTR_FOREIGN)
							rewrite_rangevar(constraint->pktable);
					}
					if (def->typeName)
					{
						TypeName *typename = (TypeName *) def->typeName;
						rewrite_plain_name(typename->names);
					}

					break;
				}
				case AT_AddConstraint:
				{
					Constraint *constraint = (Constraint *) cmd->def;

					rewrite_relation_walker(constraint->raw_expr, (void *) NULL);

					if (constraint->contype == CONSTR_FOREIGN)
						rewrite_rangevar(constraint->pktable);

					break;
				}
				default:
					break;
				}
			}
			break;
		}
		case T_GrantStmt:
		{
			/* Grant / Revoke stmt share same structure */
			GrantStmt 	*grant = (GrantStmt *) stmt;
			switch (grant->targtype)
			{
				case ACL_TARGET_OBJECT:
				{
					switch(grant->objtype)
					{
						case OBJECT_TABLE:
						case OBJECT_SEQUENCE:
						{
							rewrite_rangevar_list(grant->objects);
							break;
						}
						case OBJECT_FUNCTION:
						case OBJECT_PROCEDURE:
						{
							rewrite_objectwithargs_list(grant->objects);
							break;
						}
						case OBJECT_SCHEMA:
						{
							rewrite_schema_name_list(grant->objects);
							break;
						}
						case OBJECT_TYPE:
						{
							rewrite_plain_name_list(grant->objects);
							break;
						}
						default:
							break;
					}
					rewrite_role_list(grant->grantees);
					break;
				}
				case ACL_TARGET_ALL_IN_SCHEMA:
				{
					rewrite_schema_name_list(grant->objects);
					break;
				}
				default:
				break;
			}
			break;
		}
		case T_GrantRoleStmt:
		{
			GrantRoleStmt	*grant_role = (GrantRoleStmt *) stmt;
			AccessPriv		*granted;
			RoleSpec		*grantee;
			char			*role_name;
			char			*physical_role_name;
			char			*principal_name;
			char			*physical_principal_name;
			char			*db_name = get_cur_db_name();

			/* Check if this is ALTER ROLE statement */
			if (list_length(grant_role->granted_roles) != 1 || 
				list_length(grant_role->grantee_roles) != 1)
				break;

			granted = (AccessPriv *) linitial(grant_role->granted_roles);
			role_name = granted->priv_name;

			/* Forbidden ALTER ROLE db_owner ADD/DROP MEMBER */
			if (strcmp(role_name, "db_owner") == 0)
			{
				if (grant_role->is_grant)
					ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("Adding members to db_owner is not currently supported "
									"in Babelfish")));
				else
					ereport(ERROR,
							(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
							 errmsg("Dropping members to db_owner is not currently supported "
									"in Babelfish")));
			}

			/* Try to get physical granted role name, see if it's an existing db role */
			physical_role_name = get_physical_user_name(db_name, role_name);
			if (get_role_oid(physical_role_name, true) == InvalidOid)
				break;

			/* This is ALTER ROLE statement */
			grantee = (RoleSpec *) linitial(grant_role->grantee_roles);
			principal_name = grantee->rolename;

			/* Forbidden the use of some special principals */
			if (strcmp(principal_name, "dbo") == 0 ||
				strcmp(principal_name, "db_owner") == 0)
				ereport(ERROR,
						(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
						 errmsg("Cannot use the special principal '%s'", principal_name)));

			/* Rewrite granted and grantee roles */
			pfree(granted->priv_name);
			granted->priv_name = physical_role_name;

			physical_principal_name = get_physical_user_name(db_name, principal_name);
			pfree(grantee->rolename);
			grantee->rolename = physical_principal_name;

			break;
		}
		case T_CreateStmt:
		{
			CreateStmt *create = (CreateStmt *) stmt;
			ListCell   *elements;

			rewrite_rangevar(create->relation);

			foreach(elements, create->tableElts)
			{
				Node       *element = lfirst(elements);

				switch (nodeTag(element))
				{
					case T_ColumnDef:
					{
						ColumnDef *def = (ColumnDef *) element;
						ListCell  *clist;
						
						foreach(clist, def->constraints)
						{
							Constraint *constraint = lfirst_node(Constraint, clist);

							rewrite_relation_walker(constraint->raw_expr, (void *) NULL);

							if (constraint->contype == CONSTR_FOREIGN)
								rewrite_rangevar(constraint->pktable);
						}
						if (def->typeName)
						{
							TypeName *typename = (TypeName *) def->typeName;
							rewrite_plain_name(typename->names);
						}
						break;
					}
					case T_Constraint:
					{
						Constraint *constraint = (Constraint*) element;
						if (constraint->contype == CONSTR_FOREIGN)
							rewrite_rangevar(constraint->pktable);
						break;
					}
					default:
						break;
				}
			}
			break;
		}
		case T_CreateRoleStmt:
		{
			CreateRoleStmt *create_role = (CreateRoleStmt *) stmt;

			if (create_role->options != NIL)
			{
				DefElem *headel = (DefElem *) linitial(create_role->options);

				if (strcmp(headel->defname, "isuser") == 0 ||
					strcmp(headel->defname, "isrole") == 0)
				{
					ListCell	*option;
					char		*user_name;
					char		*db_name = get_cur_db_name();

					user_name = get_physical_user_name(db_name, create_role->role);
					pfree(create_role->role);
					create_role->role = user_name;

					foreach (option, create_role->options)
					{
						DefElem    *defel = (DefElem *) lfirst(option);

						if (strcmp(defel->defname, "rolemembers") == 0)
						{
							RoleSpec	*spec;

							spec = makeNode(RoleSpec);
							spec->roletype = ROLESPEC_CSTRING;
							spec->location = -1;
							spec->rolename = pstrdup(get_db_owner_name(db_name));

							if (defel->arg == NULL)
								defel->arg = (Node *) list_make1(spec);
							else
							{
								List *rolemembers = NIL;
								rolemembers = (List *) defel->arg;
								rolemembers = lappend(rolemembers, spec);
							}
						}
					}
				}
			}
			break;
		}
		case T_AlterRoleStmt:
		{
			AlterRoleStmt *alter_role = (AlterRoleStmt *) stmt;

			if (alter_role->options != NIL)
			{
				DefElem *headel = (DefElem *) linitial(alter_role->options);

				if (strcmp(headel->defname, "isuser") == 0 ||
					strcmp(headel->defname, "isrole") == 0)
				{
					char		*user_name;
					char		*physical_user_name;
					char		*db_name = get_cur_db_name();

					user_name = alter_role->role->rolename;
					/* TODO: allow ALTER ROLE db_owner */
					if (strcmp(user_name, "dbo") == 0 ||
						strcmp(user_name, "db_owner") == 0 ||
						strcmp(user_name, "guest") == 0)
						ereport(ERROR,
								(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
								 errmsg("Cannot alter the user %s", user_name)));

					physical_user_name = get_physical_user_name(db_name, user_name);
					pfree(alter_role->role->rolename);
					alter_role->role->rolename = physical_user_name;
				}
			}
			break;
		}
		case T_DropStmt:
		{
			DropStmt *drop = (DropStmt *) stmt;
			switch(drop->removeType)
			{
				case OBJECT_TABLE:
				case OBJECT_SEQUENCE:
				case OBJECT_VIEW:
				case OBJECT_MATVIEW:
				case OBJECT_INDEX:
				{
					rewrite_plain_name_list(drop->objects);
					break;
				}
				case OBJECT_TYPE:
				{
					rewrite_type_name_list(drop->objects);
					break;
				}
				case OBJECT_SCHEMA:
				{
					rewrite_schema_name_list(drop->objects);
					break;
				}
				case OBJECT_TRIGGER:
				{
					rewrite_plain_name((List *) lfirst(list_head(drop->objects)));
					break;
				}
				case OBJECT_FUNCTION:
				case OBJECT_PROCEDURE:
				{
					rewrite_objectwithargs_list(drop->objects);
					break;
				}
				default:
					break;
			}
			break;
		}
		case T_TruncateStmt:
		{
			TruncateStmt *truncate = (TruncateStmt *) stmt;
			rewrite_rangevar_list(truncate->relations);
			break;
		}
		case T_IndexStmt:
		{
			IndexStmt *index = (IndexStmt *) stmt;
			rewrite_rangevar(index->relation);
			break;
		}
		case T_CreateFunctionStmt:
		{
			CreateFunctionStmt *create_func = (CreateFunctionStmt *) stmt;
			ListCell   	*cell;

			/* handle arguments */
			foreach(cell, create_func->parameters)
			{
				FunctionParameter *p = (FunctionParameter *) lfirst(cell);
				TypeName *typename = p->argType;

				/* handle type */
				rewrite_plain_name(typename->names);

				/* default value */
				rewrite_relation_walker(p->defexpr, (void *) NULL);
			}

			rewrite_plain_name(create_func->funcname);
			if (list_length(create_func->options) >= 3)
			{
				DefElem *defElem = (DefElem *) lthird(create_func->options);
				if (strncmp(defElem->defname, "trigStmt", 8) == 0)
				{
					CreateTrigStmt *create_trigger = (CreateTrigStmt *) defElem->arg;
					rewrite_rangevar(create_trigger->relation);
				}
				else if (strncmp(defElem->defname, "tbltypStmt", 10) == 0)
				{
					CreateStmt *tbltypStmt = (CreateStmt *) defElem->arg;
					rewrite_rangevar(tbltypStmt->relation);
				}
			}
			break;
		}
		case T_AlterFunctionStmt:
		{
			AlterFunctionStmt *alter_func = (AlterFunctionStmt *) stmt;
			rewrite_objectwithargs(alter_func->func);
			break;
		}
		case T_RenameStmt:
		{
			RenameStmt *rename = (RenameStmt *) stmt;
			switch (rename->renameType)
			{
				case OBJECT_FUNCTION:
				case OBJECT_PROCEDURE:
				case OBJECT_TYPE:
				{
					rewrite_objectwithargs((ObjectWithArgs *) rename->object);
					break;
				}
				case OBJECT_SCHEMA:
				{
					char *cur_db = get_cur_db_name();
					rename->subname = get_physical_schema_name(cur_db, rename->subname);
					rename->newname = get_physical_schema_name(cur_db, rename->newname);
					break;
				}
				case OBJECT_TABLE:
				case OBJECT_SEQUENCE:
				case OBJECT_VIEW:
				case OBJECT_MATVIEW:
				case OBJECT_INDEX:
				case OBJECT_COLUMN:
				case OBJECT_TABCONSTRAINT:
				case OBJECT_TRIGGER:
					rewrite_rangevar(rename->relation);
					break;
				default:
					break;
			}
			break;
		}
		case T_ViewStmt:
		{
			ViewStmt *view = (ViewStmt *) stmt;
			rewrite_rangevar(view->view);
			break;
		}
		case T_CreateTableAsStmt:
		{
			CreateTableAsStmt *ctas = (CreateTableAsStmt *) stmt;
			rewrite_rangevar(ctas->into->rel);
			break;
		}
		case T_CreateSeqStmt:
		{
			CreateSeqStmt *create_seq = (CreateSeqStmt *) stmt;
			rewrite_rangevar(create_seq->sequence);
			break;
		}
		case T_AlterSeqStmt:
		{
			AlterSeqStmt *alter_seq = (AlterSeqStmt *) stmt;
			rewrite_rangevar(alter_seq->sequence);
			break;
		}
		case T_CreateTrigStmt:
		{
			CreateTrigStmt *create_trig = (CreateTrigStmt *) stmt;
			rewrite_rangevar(create_trig->relation);
			rewrite_plain_name(create_trig->funcname);
			break;
		}
		case T_CreateSchemaStmt:
		{
			CreateSchemaStmt *create_schema = (CreateSchemaStmt *) stmt;
			char *cur_db = get_cur_db_name();
			create_schema->schemaname = get_physical_schema_name(cur_db, create_schema->schemaname);
			if (create_schema->authrole)
				rewrite_role_name(create_schema->authrole);
			break;
		}
		case T_AlterOwnerStmt:
		{
			AlterOwnerStmt *alter_owner = (AlterOwnerStmt *) stmt;
			switch (alter_owner->objectType)
			{
				case OBJECT_AGGREGATE:
				case OBJECT_FUNCTION:
				case OBJECT_PROCEDURE:
					rewrite_objectwithargs((ObjectWithArgs *) alter_owner->object);
					break;
				case OBJECT_TABLE:
				case OBJECT_SEQUENCE:
				case OBJECT_VIEW:
				case OBJECT_MATVIEW:
				case OBJECT_INDEX:
				case OBJECT_COLUMN:
				case OBJECT_TABCONSTRAINT:
				case OBJECT_TRIGGER:
					rewrite_rangevar((RangeVar *) alter_owner->object);
					break;
				case OBJECT_SCHEMA:
				{
					rewrite_schema_name((String *) alter_owner->object);
					break;
				}
				case OBJECT_TYPE:
				{
					rewrite_plain_name((List *) alter_owner->object);
					break;
				}
				default:
					break;
			}
			break;
		}
		case T_CreateStatsStmt:
		{
			CreateStatsStmt *create_stats = (CreateStatsStmt *) stmt;
			rewrite_rangevar_list(create_stats->relations);
			break;
		}
		case T_CallStmt:
		{
			CallStmt *call = (CallStmt *) stmt;
			rewrite_plain_name(call->funccall->funcname);
			break;
		}
		case T_DefineStmt:
		{
			DefineStmt *define_stmt = (DefineStmt *) stmt;
			rewrite_plain_name(define_stmt->defnames);
			break;
		}
		case T_CompositeTypeStmt:
		{
			CompositeTypeStmt *comp_type_stmt = (CompositeTypeStmt *) stmt;
			rewrite_rangevar(comp_type_stmt->typevar);
			break;
		}
		case T_CreateEnumStmt:
		{
			CreateEnumStmt *enum_stmt = (CreateEnumStmt *) stmt;
			rewrite_plain_name(enum_stmt->typeName);
			break;
		}
		case T_CreateRangeStmt:
		{
			CreateRangeStmt *create_range = (CreateRangeStmt *) stmt;
			rewrite_plain_name(create_range->typeName);
			break;
		}
		case T_AlterEnumStmt:
		{
			AlterEnumStmt *alter_enum = (AlterEnumStmt *) stmt;
			rewrite_plain_name(alter_enum->typeName);
			break;
		}
		case T_AlterTypeStmt:
		{
			AlterTypeStmt *alter_type = (AlterTypeStmt *) stmt;
			rewrite_plain_name(alter_type->typeName);
			break;
		}
		case T_CreateDomainStmt:
		{
			CreateDomainStmt *create_domain = (CreateDomainStmt *) stmt;
			rewrite_plain_name(create_domain->domainname);
			rewrite_plain_name(create_domain->typeName->names);
			break;
		}
		default:
			break;
	}
}

static bool
rewrite_relation_walker(Node *node, void *context)
{
	if (!node)
		return false;

    if (IsA(node, RangeVar))
    {
	 	RangeVar	*rv = (RangeVar *) node;			
		rewrite_rangevar(rv);
		return false;
	}
	if (IsA(node, ColumnRef))
	{
		ColumnRef   *ref = (ColumnRef *) node;
		rewrite_column_refs(ref);
		return false;
	}
	if (IsA(node, FuncCall))
	{
		FuncCall 	*func = (FuncCall *) node;
		rewrite_plain_name(func->funcname);
		return raw_expression_tree_walker(node, rewrite_relation_walker, context);			
	}
	if (IsA(node, TypeName))
	{
		TypeName *typename = (TypeName *) node;
		rewrite_plain_name(typename->names);
		return false;
	}
	else
		return raw_expression_tree_walker(node, rewrite_relation_walker, context);			
}

/*************************************************************
 * 						Rewriting Functions
 *************************************************************/

void
rewrite_column_refs(ColumnRef *cref)
{   
	switch (list_length(cref->fields))
	{
		case 3:
		{
			Node       *schema = (Node *) linitial(cref->fields);
			char       *cur_db = get_cur_db_name();
			String     *new_schema;

			if (is_shared_schema(strVal(schema)))
				break;  /* do not thing for shared schemas */
			else
			{
				new_schema = makeString(get_physical_schema_name(cur_db, strVal(schema)));
				cref->fields = list_delete_first(cref->fields);
				cref->fields = lcons(new_schema, cref->fields);
			}
			break;
		}
		case 4:
		{
			Node       *db = (Node *) linitial(cref->fields);
			Node       *schema = (Node *) lsecond(cref->fields);
			String     *new_schema;

			if (is_shared_schema(strVal(schema)))
				cref->fields = list_delete_first(cref->fields);  /* redirect to shared schema */
			else
			{
				new_schema = makeString(get_physical_schema_name(strVal(db), strVal(schema)));
				cref->fields = list_delete_first(cref->fields);
				cref->fields = list_delete_first(cref->fields);
				cref->fields = lcons(new_schema, cref->fields);
			}
			break;
		}
		default:
			break;
	}
}

static void
rewrite_rangevar(RangeVar *rv)
{
	if (rv->catalogname)
	{
		if (is_shared_schema(rv->schemaname))
			rv->catalogname = NULL;  /* redirect to shared schema */
		else
		{
			rv->schemaname = get_physical_schema_name(rv->catalogname, rv->schemaname);
			rv->catalogname = NULL;
		}
	}
	else if (rv->schemaname)
	{
		if (is_shared_schema(rv->schemaname))
			return;  /* do not thing for shared schemas */
		else
		{
			char *cur_db = get_cur_db_name();
			rv->schemaname = get_physical_schema_name(cur_db, rv->schemaname);
		}
	}
}

static void
rewrite_objectwithargs(ObjectWithArgs *obj)
{
	rewrite_plain_name(obj->objname);
}

void
rewrite_plain_name(List *name)
{
	switch (list_length(name))
	{
		case 2:
		{
			Node       *schema = (Node *) linitial(name);
			char       *cur_db = get_cur_db_name();
			String     *new_schema;

			if (is_shared_schema(strVal(schema)))
				break;  /* do not thing for shared schemas */

			new_schema = makeString(get_physical_schema_name(cur_db, strVal(schema)));
			/* ignoring the return value sinece list is valid and cannot be empty */
			name = list_delete_first(name);
			name = lcons(new_schema, name);
			break;
		}
		case 3:
		{
			Node       *db = (Node *) linitial(name);
			Node       *schema = (Node *) lsecond(name);
			String     *new_schema;


			/* do nothing for shared schemas */
			if (is_shared_schema(strVal(schema)))
				name = list_delete_first(name);  /* redirect to shared SYS schema */
			else
			{
				new_schema = makeString(get_physical_schema_name(strVal(db), strVal(schema)));
				/* ignoring the return value sinece list is valid and cannot be empty */
				name = list_delete_first(name);
				name = list_delete_first(name);
				name = lcons(new_schema, name);
			}
			break;
		}
		default:
			break;
	}
}

static void
rewrite_schema_name(String *schema)
{
	char       *cur_db = get_cur_db_name();

	/* do nothing for shared schemas */
	if (is_shared_schema(strVal(schema)))
		return;
	schema->sval = get_physical_schema_name(cur_db, strVal(schema));
}

static void
rewrite_role_name(RoleSpec *role)
{
	char       *cur_db = get_cur_db_name();
	role->rolename = get_physical_user_name(cur_db, role->rolename);
}

bool
is_shared_schema(const char *name)
{
	if ((strcmp("sys", name ) == 0)
			|| (strcmp("information_schema_tsql", name) == 0))
		return true;  /* babelfish shared schema */
	else if ((strcmp("public", name) == 0)
			|| (strcmp("pg_catalog", name) == 0)
			|| (strcmp("pg_toast", name) == 0)
			|| (strcmp("information_schema", name) == 0))
		return true;  /* PG shared schemas */
	else if ((strcmp("aws_commons", name) == 0)
			|| (strcmp("aws_s3", name) == 0)
			|| (strcmp("aws_lambda", name) == 0)
			|| (strcmp("pglogical", name) == 0))
		return true; /* extension schemas */
	else
		return false;
}

static void
rewrite_rangevar_list(List *rvs)
{
	ListCell   	*cell;

	foreach(cell, rvs)
	{
		RangeVar   *rv = (RangeVar *) lfirst(cell);
		rewrite_rangevar(rv);
	}
}

static void
rewrite_objectwithargs_list(List *objs)
{
	ListCell   	*cell;

	foreach(cell, objs)
	{
		ObjectWithArgs *obj = (ObjectWithArgs *) lfirst(cell);
		rewrite_objectwithargs(obj);
	}
}

static void
rewrite_plain_name_list(List *names)
{
	ListCell   	*cell;

	foreach(cell, names)
	{
		rewrite_plain_name((List *) lfirst(cell));
	}
}

static void
rewrite_schema_name_list(List *schemas)
{
	ListCell   	*cell;

	foreach(cell, schemas)
	{
		String *schema = (String *) lfirst(cell);
		rewrite_schema_name(schema);
	}
}

static void
rewrite_type_name_list(List *typenames)
{
	ListCell   	*cell;

	foreach(cell, typenames)
	{
		TypeName *typename = (TypeName *) lfirst(cell);
		rewrite_plain_name(typename->names);
	}
}

static void 
rewrite_role_list(List *rolespecs)
{
	ListCell   	*cell;

	foreach(cell, rolespecs)
	{
		RoleSpec *role = (RoleSpec *) lfirst(cell);
		/* skip current user, session user, public */
		if (role->roletype == ROLESPEC_CSTRING)
			rewrite_role_name(role);
	}
}

/*************************************************************
 * 						Helper Functions
 *************************************************************/

PG_FUNCTION_INFO_V1(get_current_physical_schema_name);
Datum
get_current_physical_schema_name(PG_FUNCTION_ARGS)
{
	char		*schema_name;
	char		*cur_db_name;
	char		*ret;

	schema_name = text_to_cstring(PG_GETARG_TEXT_PP(0));
	cur_db_name = get_cur_db_name();

	if (strcmp(schema_name, "") == 0)
		PG_RETURN_NULL();

	if (cur_db_name)
		ret = get_physical_schema_name(cur_db_name, schema_name);
	else
		PG_RETURN_TEXT_P(CStringGetTextDatum(schema_name));

	PG_RETURN_TEXT_P(CStringGetTextDatum(ret));
}

/* db_name is the logical db that user want to query against
 * retrieve the physical mapped schema for the query
 */
char *
get_physical_schema_name(char *db_name, const char *schema_name)
{
	char *name;
	char *result;
	int		len;

	if (!schema_name)
		return NULL;

	len = strlen(schema_name);
	if (len == 0)
		return NULL;

	/* always return a new copy */
	name = palloc0(len > MAX_BBF_NAMEDATALEND ? len : MAX_BBF_NAMEDATALEND);
	strncpy(name, schema_name, strlen(schema_name));

	if (is_shared_schema(name))
		return name;

	/* Parser guarantees identifier will alsways be truncated to 64B.
	 * Schema name that comes from other source (e.g scheam_id function)
	 * needs one more truncate function call
	 */
	truncate_tsql_identifier(name);

	if (SINGLE_DB == get_migration_mode())
	{
		if ((strlen(db_name) == 6 && (strncmp(db_name, "master", 6) == 0)) ||
			(strlen(db_name) == 6 && (strncmp(db_name, "tempdb", 6) == 0)) ||
			(strlen(db_name) == 4 && (strncmp(db_name, "msdb", 4) == 0)))
		{
			result = palloc0(MAX_BBF_NAMEDATALEND);
			snprintf(result, (MAX_BBF_NAMEDATALEND), "%s_%s", db_name, name);
		}
		else if (!DbidIsValid(get_db_id(db_name)))
		{
			ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_DATABASE),
					errmsg("database \"%s\" does not exist. Make sure that the name is entered correctly.", db_name)));
		}
		else 
		{
			/* db_name is valid. 
			 * under SINGLE_DB this is only possible 
			 * when target db is the customer db.
			 * in such case we only return the schema_name name */
			return name;
		}
	}
	else
	{
		result = palloc0(MAX_BBF_NAMEDATALEND);
		snprintf(result, (MAX_BBF_NAMEDATALEND), "%s_%s", db_name, name);
	}

	truncate_tsql_identifier(result);

	return result;
}

/*
 * db_name is the logical database name to rewrite to
 * user_name is the logical user name
 *
 * Map the logical user name to its physical name in the database.
 */
char *
get_physical_user_name(char *db_name, char *user_name)
{
	char	*new_user_name;
	char	*result;
	int		len;

	if (!user_name)
		return NULL;

	len = strlen(user_name);
	if (len == 0)
		return NULL;

	if (!DbidIsValid(get_db_id(db_name)))
		ereport(ERROR,
				(errcode(ERRCODE_UNDEFINED_DATABASE),
				 errmsg("database \"%s\" does not exist.", db_name)));

	/* Get a new copy */
	new_user_name = palloc0(len > MAX_BBF_NAMEDATALEND ? len : MAX_BBF_NAMEDATALEND);
	strncpy(new_user_name, user_name, len);

	/* Truncate to 64 bytes */
	truncate_tsql_identifier(new_user_name);

	/* All the role and user names are prefixed.
	 * Historically, dbo and db_owner in single-db mode were unprefixed
	 * These are two exceptions to the naming convention
	 */
	if (SINGLE_DB == get_migration_mode())
	{
		// check that db_name is not "master", "tempdb", or "msdb"
		if ((strlen(db_name) != 6 || (strncmp(db_name, "master", 6) != 0)) &&
			(strlen(db_name) != 6 || (strncmp(db_name, "tempdb", 6) != 0)) &&
			(strlen(db_name) != 4 || (strncmp(db_name, "msdb", 4) != 0)))
		{
			if ((strlen(user_name) == 3 && strncmp(user_name, "dbo", 3) == 0) ||
				(strlen(user_name) == 8 && strncmp(user_name, "db_owner", 8) == 0))
			{
				return new_user_name;
			}
		}
	}

	result = palloc0(MAX_BBF_NAMEDATALEND);
	snprintf(result, (MAX_BBF_NAMEDATALEND), "%s_%s", db_name, new_user_name);

	/* Truncate final result to 64 bytes */
	truncate_tsql_identifier(result);

	return result;
}

const char *
get_dbo_schema_name(const char *dbname)
{
	if (0 == strcmp(dbname , "master"))
		return "master_dbo";
	if (0 == strcmp(dbname , "tempdb"))
		return "tempdb_dbo";
	if (0 == strcmp(dbname , "msdb"))
		return "msdb_dbo";
	if (SINGLE_DB == get_migration_mode())
		return "dbo";
	else
	{
		char *name = palloc0(MAX_BBF_NAMEDATALEND);
		snprintf(name, MAX_BBF_NAMEDATALEND, "%s_dbo", dbname);
    	truncate_identifier(name, strlen(name), false);
		return name;
	}
}

const char *
get_dbo_role_name(const char *dbname)
{
	if (0 == strcmp(dbname , "master"))
		return "master_dbo";
	if (0 == strcmp(dbname , "tempdb"))
		return "tempdb_dbo";
	if (0 == strcmp(dbname , "msdb"))
		return "msdb_dbo";
	if (SINGLE_DB == get_migration_mode())
		return "dbo";
	else
	{
		char *name = palloc0(MAX_BBF_NAMEDATALEND);
		snprintf(name, MAX_BBF_NAMEDATALEND, "%s_dbo", dbname);
    	truncate_identifier(name, strlen(name), false);
		return name;
	}
}

const char *
get_db_owner_name(const char *dbname)
{
	if (0 == strcmp(dbname , "master"))
		return "master_db_owner";
	if (0 == strcmp(dbname , "tempdb"))
		return "tempdb_db_owner";
	if (0 == strcmp(dbname , "msdb"))
		return "msdb_db_owner";
	if (SINGLE_DB == get_migration_mode())
		return "db_owner";
	else
	{
		char *name = palloc0(MAX_BBF_NAMEDATALEND);
		snprintf(name, MAX_BBF_NAMEDATALEND, "%s_db_owner", dbname);
    	truncate_identifier(name, strlen(name), false);
		return name;
	}
}

const char *get_guest_role_name(const char *dbname)
{
	if (0 == strcmp(dbname , "master"))
		return "master_guest";
	if (0 == strcmp(dbname , "tempdb"))
		return "tempdb_guest";
	if (0 == strcmp(dbname , "msdb"))
		return "msdb_guest";
	else
	{
		char *name = palloc0(MAX_BBF_NAMEDATALEND);
		snprintf(name, MAX_BBF_NAMEDATALEND, "%s_guest", dbname);
		truncate_identifier(name, strlen(name), false);
		return name;
	}
}

/*************************************************************
 * 					Helper Functions	
 *************************************************************/

/* in-place truncate identifiers if needded */
static void
truncate_tsql_identifier(char *ident)
{
	const char *saved_dialect;

	if (!ident || (strlen(ident) < NAMEDATALEN))
		return;

	saved_dialect = GetConfigOption("babelfishpg_tsql.sql_dialect", true, true);

	PG_TRY();
	{
		/* this is BBF help function. use BBF truncation logic */
		set_config_option("babelfishpg_tsql.sql_dialect", "tsql",
					(superuser() ? PGC_SUSET : PGC_USERSET),
					PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		truncate_identifier(ident, strlen(ident), false);
	}
	PG_CATCH();
	{
		set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
					(superuser() ? PGC_SUSET : PGC_USERSET),
					PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);
		PG_RE_THROW();
	}
	PG_END_TRY();
	set_config_option("babelfishpg_tsql.sql_dialect", saved_dialect,
				(superuser() ? PGC_SUSET : PGC_USERSET),
				PGC_S_SESSION, GUC_ACTION_SAVE, true, 0, false);

}

