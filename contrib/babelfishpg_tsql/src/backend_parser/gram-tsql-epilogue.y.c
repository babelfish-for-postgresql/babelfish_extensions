void
pgtsql_parser_init(base_yy_extra_type *yyext)
{
	parser_init(yyext);
}

static void
pgtsql_base_yyerror(YYLTYPE * yylloc, core_yyscan_t yyscanner, const char *msg)
{
	base_yyerror(yylloc, yyscanner, msg);
}

static Node *
makeTSQLHexStringConst(char *str, int location)
{
	A_Const    *n = makeNode(A_Const);

	n->val.sval.type = T_TSQL_HexString;
	n->val.hsval.hsval = str;
	n->location = location;

	return (Node *) n;
}

/* TsqlSystemFuncName()
 * Build a properly-qualified reference to a tsql built-in function.
 */
List *
TsqlSystemFuncName(char *name)
{
	return list_make2(makeString("sys"), makeString(name));
}

/* TsqlSystemFuncName2()
 * Build a properly-qualified reference to a tsql built-in function.
 */
List *
TsqlSystemFuncName2(char *name)
{
	return list_make2(makeString("sys"), makeString(name));
}

char *
construct_unique_index_name(char *index_name, char *relation_name)
{
	char		md5[MD5_HASH_LEN + 1];
	char		buf[2 * NAMEDATALEN + MD5_HASH_LEN + 1];
	char	   *name;
	bool		success;
	int			full_len;
	int			new_len;
	int			index_len;
	int			relation_len;
	const char *errstr = NULL;

	if (index_name == NULL || relation_name == NULL)
	{
		return index_name;
	}
	index_len = strlen(index_name);
	relation_len = strlen(relation_name);

	success = pg_md5_hash(index_name, index_len, md5, &errstr);
	if (unlikely(!success))
	{							/* OOM */
		ereport(
				ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg(
						"constructing unique index name failed: index = \"%s\", relation = \"%s\": %s",
						index_name,
						relation_name,
						errstr
						)
				 )
			);
	}

	memcpy(buf, index_name, index_len);
	memcpy(buf + index_len, relation_name, relation_len);
	memcpy(buf + index_len + relation_len, md5, MD5_HASH_LEN + 1);

	full_len = index_len + relation_len + MD5_HASH_LEN;
	buf[full_len] = '\0';

	truncate_identifier(buf, full_len, false);

	new_len = strlen(buf);
	Assert(new_len < NAMEDATALEN);	/* result new_len is below max */

	name = palloc(new_len + 1);
	memcpy(name, buf, new_len + 1);

	return name;
}

/*
 * Convert a list of (dotted) names for a table type to a RangeVar.
 * This differs from makeRangeVarFromAnyName in that it only allows 1 prefix,
 * instead of 2.
 */
static RangeVar *
makeRangeVarFromAnyNameForTableType(List *names, int position, core_yyscan_t yyscanner)
{
	RangeVar   *r = makeNode(RangeVar);

	switch (list_length(names))
	{
		case 1:
			r->catalogname = NULL;
			r->schemaname = NULL;
			r->relname = strVal(linitial(names));
			break;
		case 2:
			r->catalogname = NULL;
			r->schemaname = strVal(linitial(names));
			r->relname = strVal(lsecond(names));
			break;
		default:
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("The type name '%s' contains more than the maximum number of prefixes. The maximum is 1.",
							NameListToString(names)),
					 parser_errposition(position)));
			break;
	}

	r->relpersistence = RELPERSISTENCE_PERMANENT;
	r->location = position;

	return r;
}

Node
		   *
TsqlFunctionChoose(Node *int_expr, List *choosable, int location)
{
	CaseExpr   *c = makeNode(CaseExpr);
	ListCell   *lc;
	int			i = 1;

	TSQLInstrumentation(INSTR_TSQL_FUNCTION_CHOOSE);

	if (choosable == NIL)
		elog(ERROR,
			 "Function 'choose' requires at least 2 argument(s)");

	foreach(lc, choosable)
	{
		CaseWhen   *w = makeNode(CaseWhen);

		w->expr = (Expr *) makeIntConst(i, location);
		w->result = (Expr *) lfirst(lc);
		w->location = location;
		c->args = lappend(c->args, w);
		i++;
	}

	c->casetype = InvalidOid;
	c->arg = (Expr *) makeTypeCast(int_expr, SystemTypeName("int4"), -1);
	c->location = location;

	return (Node *) c;
}


/* TsqlFunctionConvert -- Implements the CONVERT and TRY_CONVERT functions.
 * Takes in target type, expression, style, try boolean, location.
 *
 * Converts any input type to any type with different styles.
 * Uses try boolean to determine returning an error or null if cast fails.
 */
Node *
TsqlFunctionConvert(TypeName *typename, Node *arg, Node *style, bool try, int location)
{
	Node	   *result;
	List	   *args;
	int32		typmod;
	Oid			type_oid;
	char	   *typename_string;

	/* For handling try boolean logic on babelfishpg_tsql side */
	Node	   *try_const = makeBoolAConst(try, location);

	if (style)
		args = list_make3(arg, try_const, style);
	else
		args = list_make2(arg, try_const);

	typenameTypeIdAndMod(NULL, typename, &type_oid, &typmod);
	typename_string = TypeNameToString(typename);

	TSQLInstrumentation(INSTR_TSQL_FUNCTION_CONVERT);

	if (type_oid == DATEOID)
		result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_conv_helper_to_date"), args, COERCE_EXPLICIT_CALL, location);

	else if (type_oid == TIMEOID)
		result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_conv_helper_to_time"), args, COERCE_EXPLICIT_CALL, location);

	else if (type_oid == typenameTypeId(NULL, makeTypeName("datetime")))
		result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_conv_helper_to_datetime"), args, COERCE_EXPLICIT_CALL, location);

	else if ((strcmp(typename_string, "varchar") == 0) || (strcmp(typename_string, "nvarchar") == 0) ||
				(strcmp(typename_string, "bpchar") == 0) || (strcmp(typename_string, "nchar") == 0))
	{
		Node	   *helperFuncCall;

		typename_string = format_type_extended(VARCHAROID, typmod, FORMAT_TYPE_TYPEMOD_GIVEN);
		args = lcons(makeStringConst(typename_string, typename->location), args);
		helperFuncCall = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_conv_helper_to_varchar"), args, COERCE_EXPLICIT_CALL, location);

		/*
		 * BABEL-1661, add a type cast on top of the CONVERT helper function
		 * so typmod can be applied
		 */
		result = makeTypeCast(helperFuncCall, typename, location);
	}

	else if (strcmp(typename_string, "binary") == 0 || strcmp(typename_string, "varbinary") == 0)
	{
			Node	   *helperFuncCall;
			helperFuncCall = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_conv_helper_to_varbinary"), args, COERCE_EXPLICIT_CALL, location);

			// add a type cast on top of the CONVERT helper function so typmod can be applied
			result = makeTypeCast(helperFuncCall, typename, location);
	}

	else
	{
		if (try)
		{
			result = TsqlFunctionTryCast(arg, typename, location);
		}
		else
		{
			result = makeTypeCast(arg, typename, location);
		}
	}

	return result;
}

Node *
TsqlFunctionIdentityInto(TypeName *typename, Node *seed, Node *increment, int location)
{
	Node *result;
	List *args;
	int32 typmod;
	Oid type_oid;
	Oid base_oid;
	typenameTypeIdAndMod(NULL, typename, &type_oid, &typmod);
	base_oid = getBaseType(type_oid);
	switch (base_oid)
	{
		case INT2OID:
		case INT4OID:
			args = list_make3((Node *)makeIntConst((int)type_oid, location), seed, increment);
			break;
		case INT8OID:
		case NUMERICOID:
			args = list_make3((Node *)makeIntConst((int)INT8OID, location), seed, increment); /* Used bigint internally for decimal and numeric as well*/
			break;
		default:
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					errmsg("Parameter or variable '' has an invalid data type.")));
			break;
	}
	result = (Node *)makeFuncCall(TsqlSystemFuncName("identity_into_bigint"), args, COERCE_EXPLICIT_CALL, location);
	return result;
}

/* TsqlFunctionParse -- Implements the PARSE and TRY_PARSE functions.
 * Takes in expression, target type, regional culture, try boolean, location.
 *
 * Parses text input to date/time and number types. Uses try boolean to determine returning
 * an error or null if cast fails.
 */
Node *
TsqlFunctionParse(Node *arg, TypeName *typename, Node *culture, bool try, int location)
{
	Node	   *result;
	List	   *args;
	int32		typmod;
	Oid			type_oid;

	/*
	 * So far only date, time, and datetime need try_const and culture if not
	 * null since only they have specialized functions implemented in PG TSQL.
	 */
	Node	   *try_const = makeBoolAConst(try, location);

	if (culture)
		args = list_make3(arg, try_const, culture);
	else
		args = list_make2(arg, try_const);

	typenameTypeIdAndMod(NULL, typename, &type_oid, &typmod);

	TSQLInstrumentation(INSTR_TSQL_FUNCTION_PARSE);

	if (type_oid == DATEOID)
		result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_parse_helper_to_date"), args, COERCE_EXPLICIT_CALL, location);

	else if (type_oid == TIMEOID)
		result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_parse_helper_to_time"), args, COERCE_EXPLICIT_CALL, location);

	else if (type_oid == typenameTypeId(NULL, makeTypeName("datetime")))
		result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_parse_helper_to_datetime"), args, COERCE_EXPLICIT_CALL, location);

	else
	{
		if (try)
			result = TsqlFunctionTryCast(arg, typename, location);

		else
			result = makeTypeCast(arg, typename, location);
	}

	return result;
}

/* TsqlFunctionTryCast -- Implements the TRY_CAST function.
 * Takes in expression, target type, location.
 *
 * Behaves like CAST except return NULL instead of error in most cases.
 */
Node *
TsqlFunctionTryCast(Node *arg, TypeName *typename, int location)
{
	Node	   *result;
	int32		typmod;
	Oid			type_oid;

	typenameTypeIdAndMod(NULL, typename, &type_oid, &typmod);

	TSQLInstrumentation(INSTR_TSQL_FUNCTION_TRY_CAST);

	/*
	 * Going case-by-case since it seems we cannot define a wrapper try_cast
	 * function that takes in an arg of any type and returns any type. Can
	 * reduce cases to handle by having a generic cast at the end that casts
	 * the arg to TEXT then casts to the target type. Works for most cases but
	 * not all such as casting float to int.
	 */
	if (type_oid == INT2OID)
		result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_try_cast_floor_smallint"), list_make1(arg), COERCE_EXPLICIT_CALL, location);

	else if (type_oid == INT4OID)
		result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_try_cast_floor_int"), list_make1(arg), COERCE_EXPLICIT_CALL, location);

	else if (type_oid == INT8OID)
		result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_try_cast_floor_bigint"), list_make1(arg), COERCE_EXPLICIT_CALL, location);

	else if (type_oid == typenameTypeId(NULL, makeTypeName("datetime2")))
	{
		/*
		 * Handles null typmod case. typmod is set to 6 because that is the
		 * current max precision for datetime2 Update to 7 when BABEL-2934 is
		 * reolved
		 */
		if (typmod < 0)
			typmod = 6;

		result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_try_cast_to_datetime2"), list_make2(arg, makeIntConst(typmod, location)), COERCE_EXPLICIT_CALL, location);
	}
	else
	{
		Node	   *targetType = makeTypeCast(makeNullAConst(location), typename, location);
		List	   *args;

		switch (arg->type)
		{
			case T_A_Const:
			case T_TypeCast:
			case T_FuncCall:
			case T_A_Expr:
				args = list_make3(arg, targetType, makeIntConst(typmod, location));
				break;
			default:
				args = list_make3(makeTypeCast(arg, makeTypeName("text"), location), targetType, makeIntConst(typmod, location));
		}

		result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_try_cast_to_any"), args, COERCE_EXPLICIT_CALL, location);
	}

	return result;
}

Node *
TsqlFunctionIIF(Node *bool_expr, Node *arg1, Node *arg2, int location)
{
	CaseExpr   *c = makeNode(CaseExpr);
	CaseWhen   *w = makeNode(CaseWhen);

	TSQLInstrumentation(INSTR_TSQL_FUNCTION_IIF);

	w->expr = (Expr *) bool_expr;
	w->result = (Expr *) arg1;
	w->location = location;

	c->casetype = InvalidOid;
	c->arg = NULL;
	c->args = list_make1((Node *) w);
	c->defresult = (Expr *) arg2;
	c->location = location;

	return (Node *) c;
}

/* tsql_check_param_readonly --- check the usage of READONLY on parameter
 *
 * READONLY Indicates that the parameter cannot be updated or modified
 * within the definition of the function. READONLY is required for
 * user-defined table type parameters (TVPs), and cannot be used for
 * any other parameter type.
 *
 * It's easiest to do the check here, to avoid having to add a field
 * to the FunctionParameter struct.
 */
static void
tsql_check_param_readonly(const char *paramname, TypeName *typename, bool readonly)
{
	TypeName   *typeclone = copyObjectImpl(typename);

	/* work on the cloned object to avoid double rewriting */
	typeclone->names = rewrite_plain_name(typeclone->names);
	if (typeidTypeRelid(typenameTypeId(NULL, typeclone)) == InvalidOid)
	{
		/* Not table-valued parameter - must not be READONLY */
		if (readonly)
			elog(ERROR,
				 "The parameter \"%s\" can not be declared READONLY since it is not a table-valued parameter.",
				 paramname);
	}
	else
	{
		/* Table-valued parameter - must be READONLY */
		if (!readonly)
			elog(ERROR,
				 "The table-valued parameter \"%s\" must be declared with the READONLY option.",
				 paramname);
	}
}

/*
* This function takes a JsonExpression, and an optional path then
* calls the openjson_simple function
*/
Node *
TsqlOpenJSONSimpleMakeFuncCall(Node *jsonExpr, Node *path)
{
	FuncCall   *fc;

	if (path)
	{
		fc = makeFuncCall(TsqlSystemFuncName("openjson_simple"), list_make2(jsonExpr, path), COERCE_EXPLICIT_CALL, -1);
	}
	else
	{
		fc = makeFuncCall(TsqlSystemFuncName("openjson_simple"), list_make1(jsonExpr), COERCE_EXPLICIT_CALL, -1);
	}
	return (Node *) fc;
}

/*
* This function takes a JsonExpression, path, column list, and optional alias
* It acts as a bridge between the parser and the json_with function by correctly
* assembling the function arguments, column definitions list, and alias
*/
Node *
TsqlOpenJSONWithMakeFuncCall(Node *jsonExpr, Node *path, List *cols, Alias *alias)
{
	FuncCall   *fc;
	List	   *jsonWithParams = list_make2(jsonExpr, path);
	ListCell   *lc;
	RangeFunction *rf = makeNode(RangeFunction);
	Alias	   *a = makeNode(Alias);

	a->aliasname = alias != NULL ? alias->aliasname : "f";

	foreach(lc, cols)
	{
		OpenJson_Col_Def *cd = (OpenJson_Col_Def *) lfirst(lc);
		int			initialTmod = getElemTypMod(cd->elemType);
		char	   *typeNameString = TypeNameToString(cd->elemType);
		ColumnDef  *n = (ColumnDef *) createOpenJsonWithColDef(cd->elemName, cd->elemType);
		StringInfo	format_cols = makeStringInfo();

		if (strcmp(cd->elemPath, "") == 0)
		{
			/*
			 * If not path is provided with use the standard path
			 * [$.columnName]
			 */
			appendStringInfo(format_cols, "$.%s ", cd->elemName);
		}
		else
		{
			appendStringInfo(format_cols, "%s ", cd->elemPath);
		}

		/* character types need to have the typmod appended to them */
		if (isCharType(typeNameString))
		{
			int			newTypMod = getElemTypMod(n->typeName);

			appendStringInfo(format_cols, "%s(%d)", typeNameString, newTypMod);
		}
		else
		{
			appendStringInfoString(format_cols, typeNameString);
		}

		if (cd->asJson)
		{
			if (isNVarCharType(typeNameString) && initialTmod == TSQLMaxTypmod)
			{
				appendStringInfoString(format_cols, " AS JSON");
			}
			else
			{
				/* AS JSON can only be used with nvarchar(max) */
				ereport(ERROR, (errcode(ERRCODE_SYNTAX_ERROR),
								errmsg("AS JSON in WITH clause can only be specified for column of type nvarchar(max)")));
			}

		}

		jsonWithParams = lappend(jsonWithParams, makeStringConst(format_cols->data, -1));
		rf->coldeflist = lappend(rf->coldeflist, n);
	}

	fc = makeFuncCall(TsqlSystemFuncName("openjson_with"), jsonWithParams, COERCE_EXPLICIT_CALL, -1);
	rf->functions = list_make1(list_make2(fc, NULL));
	rf->alias = alias;
	return (Node *) rf;
}

/*
* Create a column definition node for the given column name and type
* If the column type is a character type, we need to change the underlying typmod
*/
Node *
createOpenJsonWithColDef(char *elemName, TypeName *elemType)
{
	ColumnDef  *n = makeNode(ColumnDef);
	char	   *typeNameString = TypeNameToString(elemType);

	n->colname = elemName;
	if (isCharType(typeNameString))
	{
		n->typeName = setCharTypmodForOpenjson(elemType);
	}
	else
	{
		n->typeName = elemType;
	}
	n->inhcount = 0;
	n->is_local = true;
	n->is_not_null = false;
	n->is_from_type = false;
	n->storage = 0;
	n->raw_default = NULL;
	n->cooked_default = NULL;
	n->collOid = InvalidOid;
	n->constraints = NIL;
	n->location = -1;
	return (Node *) n;
}

TypeName *
setCharTypmodForOpenjson(TypeName *t)
{
	int			curTMod = getElemTypMod(t);
	List	   *tmods = (List *) t->typmods;

	if (tmods == NULL)
	{
		/* Default value when no typmod is provided is 1 */
		t->typmods = list_make1(makeIntConst(1, -1));
		return t;
	}
	else if (curTMod == TSQLMaxTypmod)
	{
		/* TSQLMaxTypmod is represented as -8000 so we need to change to */
		/* the actual max value of 4000 */
		t->typmods = list_make1(makeIntConst(4000, -1));
		return t;
	}
	else
	{
		return t;
	}
}

bool
isCharType(char *typenameStr)
{
	if (pg_strcasecmp(typenameStr, "char") == 0)
	{
		return true;
	}
	else if (pg_strcasecmp(typenameStr, "nchar") == 0)
	{
		return true;
	}
	else if (pg_strcasecmp(typenameStr, "varchar") == 0)
	{
		return true;
	}
	else if (pg_strcasecmp(typenameStr, "pg_catalog.char") == 0)
	{
		return true;
	}
	else if (pg_strcasecmp(typenameStr, "pg_catalog.varchar") == 0)
	{
		return true;
	}
	else if (pg_strcasecmp(typenameStr, "sys.char") == 0)
	{
		return true;
	}
	else if (pg_strcasecmp(typenameStr, "sys.nchar") == 0)
	{
		return true;
	}
	else if (pg_strcasecmp(typenameStr, "sys.varchar") == 0)
	{
		return true;
	}
	else if (isNVarCharType(typenameStr))
	{
		return true;
	}
	return false;
}

bool
isNVarCharType(char *typenameStr)
{
	if (pg_strcasecmp(typenameStr, "nvarchar") == 0)
	{
		return true;
	}
	else if (pg_strcasecmp(typenameStr, "sys.nvarchar") == 0)
	{
		return true;
	}
	return false;
}

int
getElemTypMod(TypeName *t)
{
	List	   *tmods = (List *) t->typmods;

	if (tmods == NULL)
	{
		return 1;
	}
	else
	{
		ListCell   *elems = (ListCell *) tmods->elements;
		A_Expr	   *expr = (A_Expr *) lfirst(elems);
		A_Const    *constVal = (A_Const *) expr;

		return constVal->val.ival.ival;
	}
}

/*
 * TsqlJsonModifyMakeFuncCall checks if the new value argument for json_modify is
 * a json_modify or json_query function call. If it is one of these two arguments it
 * sets the escape parameter to true
 */
Node *
TsqlJsonModifyMakeFuncCall(Node *expr, Node *path, Node *newValue)
{
	FuncCall   *fc;
	FuncCall   *fc_newval;
	List	   *func_args = list_make2(expr, path);
	bool		escape = false;

	switch (newValue->type)
	{
		case T_FuncCall:
			fc_newval = (FuncCall *) newValue;
			if (is_json_modify(fc_newval->funcname) || is_json_query(fc_newval->funcname))
			{
				escape = true;
			}
			func_args = lappend(func_args, newValue);
			break;
		case T_TypeCast:
		case T_A_Expr:
			func_args = lappend(func_args, newValue);
			break;
		default:
			func_args = lappend(func_args, makeTypeCast(newValue, makeTypeName("text"), -1));
	}
	func_args = lappend(func_args, makeBoolAConst(escape, -1));
	fc = makeFuncCall(TsqlSystemFuncName("json_modify"), func_args, COERCE_EXPLICIT_CALL, -1);
	return (Node *) fc;
}

bool
is_json_query(List *name)
{
	switch (list_length(name))
	{
		case 1:
			{
				Node	   *func = (Node *) linitial(name);

				if (strncmp("json_query", strVal(func), 10) == 0)
					return true;
				return false;
			}
		case 2:
			{
				Node	   *schema = (Node *) linitial(name);
				Node	   *func = (Node *) lsecond(name);

				if (strncmp("sys", strVal(schema), 3) == 0 &&
					strncmp("json_query", strVal(func), 10) == 0)
					return true;
				return false;
			}
		default:
			return false;
	}
}

/*
* Parse T-SQL CONTAINS predicate. Currently only supports 
* ... CONTAINS(column_name, '<contains_search_condition>') ...
* This function transform it into a Postgres AST that stands for
* to_tsvector(pgconfig, column_name) @@ to_tsquery(pgconfig, babelfish_fts_rewrite('<contains_search_condition>'))
* where pgconfig = babelfish_fts_contains_pgconfig('<contains_search_condition>')
*/
static Node *
TsqlExpressionContains(char *colId, Node *search_expr, core_yyscan_t yyscanner)
{
    A_Expr *fts;
    Node *to_tsvector_call, *to_tsquery_call;
    Node *result_pgconfig;
    List *args_pgconfig;

    args_pgconfig = list_make1(search_expr);
    result_pgconfig = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_fts_contains_pgconfig"), args_pgconfig, COERCE_EXPLICIT_CALL, -1);

    to_tsvector_call = makeToTSVectorFuncCall(colId, yyscanner, result_pgconfig);
    to_tsquery_call = makeToTSQueryFuncCall(search_expr, result_pgconfig);
    
    fts = makeA_Expr(AEXPR_OP, list_make1(makeString("@@")), to_tsvector_call, to_tsquery_call, -1);

    return (Node *)fts;
}

/* Transform column_name into to_tsvector(pgconfig, replace_special_chars_fts(column_name)) */
static Node *
makeToTSVectorFuncCall(char *colId, core_yyscan_t yyscanner, Node *pgconfig)
{
    Node	*col;
    List	*args;
    Node	*replaceSpecialCharsFunc;
    List	*replaceSpecialCharsArgs;
    char	*schemaName = NULL;
    char	*tableName = NULL;
    char	*columnName = NULL;
    char	*dot1, *dot2;
    
    /* Find the first and second dots in the column identifier */
    dot1 = strchr(colId, '.');
    dot2 = (dot1) ? strchr(dot1 + 1, '.') : NULL;
    
    if (dot1)
    {
        if (dot2)
        {
            /* If two dots are found, then the input is in the format "schema_name.table_name.column_name"
             * Parse the schema name, table name, and column name accordingly
             */
            *dot1 = '\0';
            *dot2 = '\0';
            schemaName = colId;
            tableName = dot1 + 1;
            columnName = dot2 + 1;
        } 
        else
        {
            /* If only one dot is found, then the input is in the format "table_name.column_name" or "alias_table.column_name"
             * Parse the table name and column name accordingly
             */
            *dot1 = '\0';
            tableName = colId;
            columnName = dot1 + 1;
        }
    }
    else
    {
        /* If no dots are found, then the input is just the column name
         * Set the column name directly
         */
        columnName = colId;
    }
    
    if (schemaName)
    {
        /* If a schema name is present, create column reference to the schema first then append the table name and column name */
        col = (Node *) makeColumnRef(schemaName, NIL, -1, yyscanner);
        ((ColumnRef *) col)->fields = lappend(((ColumnRef *) col)->fields, makeString(tableName));
        ((ColumnRef *) col)->fields = lappend(((ColumnRef *) col)->fields, makeString(columnName));
    }
    else if (tableName)
    {
        /* If a table name is present, create column reference to the table first then append the column name */
        col = (Node *) makeColumnRef(tableName, NIL, -1, yyscanner);
        ((ColumnRef *) col)->fields = lappend(((ColumnRef *) col)->fields, makeString(columnName));
    }
    else
    {
        /* Create a ColumnRef node for the column */
        col = (Node *) makeColumnRef(columnName, NIL, -1, yyscanner);
    }

    /* Create a function call for replace_special_chars_fts(column_name) */
    replaceSpecialCharsArgs = list_make1(col);
    replaceSpecialCharsFunc = (Node *) makeFuncCall(TsqlSystemFuncName("replace_special_chars_fts"), replaceSpecialCharsArgs, COERCE_EXPLICIT_CALL, -1);

    /* Create the final function call to_tsvector(pgconfig, replace_special_chars_fts(column_name)) */
    args = list_make2(pgconfig, replaceSpecialCharsFunc);

    return (Node *) makeFuncCall(list_make1(makeString("to_tsvector")), args, COERCE_EXPLICIT_CALL, -1);
}

/* Transfrom '<contains_search_condition>' into to_tsquery(pgconfig, babelfish_fts_rewrite('<contains_search_condition>')) */
static Node *
makeToTSQueryFuncCall(Node *search_expr, Node *pgconfig)
{
    List		*args;
    Node		*result_rewrite;
    List		*args_rewrite;

    args_rewrite = list_make1(search_expr);
    result_rewrite = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_fts_rewrite"), args_rewrite, COERCE_EXPLICIT_CALL, -1);

    args = list_make2(pgconfig, result_rewrite);
    return (Node *) makeFuncCall(list_make1(makeString("to_tsquery")), args, COERCE_EXPLICIT_CALL, -1);
}


/*
 * helper macro to compare relname in
 * function tsql_update_delete_stmt_with_join
 */
#define TSQL_COMP_REL_NAME(l, r) \
	(r != NULL && strcmp(l->relname, r->relation->relname) == 0 \
		&& ( (!r->relation->schemaname && !l->schemaname) \
			|| (l->schemaname && r->relation->schemaname && \
			strcmp(l->schemaname, r->relation->schemaname) == 0))\
		&& ( (!r->relation->catalogname && !l->catalogname)\
			|| (l->catalogname && r->relation->catalogname && \
			strcmp(l->catalogname, r->relation->catalogname) == 0)))

static Node *
tsql_update_delete_stmt_with_join(Node *n, List *from_clause, Node *where_clause, Node *top_clause,
								  RangeVar *relation, core_yyscan_t yyscanner)
{
	DeleteStmt *n_d = NULL;
	UpdateStmt *n_u = NULL;
	RangeVar   *target_table = NULL;
	RangeVar   *larg = NULL;
	RangeVar   *rarg = NULL;
	JoinExpr   *jexpr = linitial(from_clause);
	SubLink    *link;
	List	   *indirect;
	SelectStmt *selectstmt;
	ResTarget  *resTarget;

	/* use queue to go over all join expr and find target table */
	List	   *queue = list_make1(jexpr);
	ListCell   *queue_item;

	if (IsA(n, DeleteStmt))
		n_d = (DeleteStmt *) n;
	else
		n_u = (UpdateStmt *) n;

	foreach(queue_item, queue)
	{
		jexpr = (JoinExpr *) lfirst(queue_item);
		if (IsA(jexpr->larg, JoinExpr))
		{
			queue = lappend(queue, jexpr->larg);
		}
		else if (IsA(jexpr->larg, RangeVar))
		{
			larg = (RangeVar *) (jexpr->larg);
		}
		if (IsA(jexpr->rarg, JoinExpr))
		{
			queue = lappend(queue, jexpr->rarg);
		}
		else if (IsA(jexpr->rarg, RangeVar))
		{
			rarg = (RangeVar *) (jexpr->rarg);
		}
		if (larg && (TSQL_COMP_REL_NAME(larg, n_d) || TSQL_COMP_REL_NAME(larg, n_u)))
		{
			target_table = larg;
			break;
		}
		if (rarg && (TSQL_COMP_REL_NAME(rarg, n_d) || TSQL_COMP_REL_NAME(rarg, n_u)))
		{
			target_table = rarg;
			break;
		}
		larg = NULL;
		rarg = NULL;
	}

	/*
	 * if target table doesn't show in JoinExpr, it indicates delete/update
	 * the whole table the original statement doesn't need to be changed
	 */
	if (!target_table)
	{
		/*
		 * if we don't end up creating a subquery for JOIN, deal with TOP
		 * clause separately as it might require a subquery.
		 */
		if (n_d)
		{
			n_d->usingClause = from_clause;
			n_d->whereClause = where_clause;
			n_d->limitCount = top_clause;
			return (Node *) n_d;
		}
		else
		{
			n_u->fromClause = from_clause;
			n_u->whereClause = where_clause;
			n_u->limitCount = top_clause;
			return (Node *) n_u;
		}
	}
	/* construct select statment->target */
	resTarget = makeNode(ResTarget);
	resTarget->name = NULL;
	resTarget->indirection = NIL;
	indirect = list_make1((Node *) makeString("ctid"));
	if (target_table->alias)
	{
		resTarget->val = makeColumnRef(target_table->alias->aliasname,
									   indirect, -1, yyscanner);
	}
	else
	{
		resTarget->val = makeColumnRef(target_table->relname,
									   indirect, -1, yyscanner);
	}

	selectstmt = makeNode(SelectStmt);
	selectstmt->targetList = list_make1(resTarget);
	/* assign fromClause and whereClause from JoinExpr */
	selectstmt->fromClause = from_clause;
	selectstmt->whereClause = where_clause;
	/* if we end up createing a subquery for JOIN, attach TOP clause to it */
	selectstmt->limitCount = top_clause;
	/* construct where_clause(subLink) */
	link = makeNode(SubLink);
	link->subselect = (Node *) selectstmt;
	link->subLinkType = ANY_SUBLINK;
	link->subLinkId = 0;
	link->testexpr = (Node *) makeColumnRef(pstrdup("ctid"),
											NIL, -1, yyscanner);;
	link->operName = NIL;		/* show it's IN not = ANY */
	link->location = -1;
	if (n_d)
	{
		n_d->whereClause = (Node *) link;
		return (Node *) n_d;
	}
	else

	{
		n_u->whereClause = (Node *) link;
		return (Node *) n_u;
	}
}

/*
 * helper function to update relation info in
 * tsql_update_delete_stmt_from_clause_alias
 */
static void
tsql_update_delete_stmt_from_clause_alias_helper(RangeVar *relation, RangeVar *rv)
{
	if (rv->alias && rv->alias->aliasname &&
		strcmp(rv->alias->aliasname, relation->relname) == 0)
	{
		if (relation->schemaname)
		{
			ereport(ERROR,
					(errcode(ERRCODE_SYNTAX_ERROR),
					 errmsg("The correlation name \'%s\' has the same exposed name as table \'%s.%s\'.",
							rv->alias->aliasname, relation->schemaname,
							relation->relname)));
		}

		/*
		 * Save the original alias name so that "inserted" and "deleted"
		 * tables in OUTPUT clause can be linked to it
		 */
		update_delete_target_alias = relation->relname;

		/*
		 * Update the relation to have the real table name as relname, and the
		 * original alias name as an alias
		 */
		relation->catalogname = rv->catalogname;
		relation->schemaname = rv->schemaname;
		relation->relname = rv->relname;
		relation->inh = rv->inh;
		relation->relpersistence = rv->relpersistence;
		relation->alias = rv->alias;

		/*
		 * To avoid alias collision, remove the alias of the table in the FROM
		 * clause, because it will already be an alias of the target relation
		 */
		rv->alias = NULL;
	}
}

/*
 * Resets the state of two global vars used for UPDATE and DELETE queries
 * 
 * In some cases, an erroring UPDATE query can exit without resetting these
 * globals. This function is called before UPDATE and DELETE statements that
 * use these globals to ensure that they are cleared.
 */
static void
tsql_reset_update_delete_globals()
{
	output_update_transformation = false;
	update_delete_target_alias = NULL;
}

static void
tsql_update_delete_stmt_from_clause_alias(RangeVar *relation, List *from_clause)
{
	ListCell   *lc;

	foreach(lc, from_clause)
	{
		Node	   *n = lfirst(lc);

		if (IsA(n, RangeVar))
		{
			RangeVar   *rv = (RangeVar *) n;

			tsql_update_delete_stmt_from_clause_alias_helper(relation, rv);
		}
		else if (IsA(n, JoinExpr))
		{
			JoinExpr   *jexpr = (JoinExpr *) n;

			if (IsA(jexpr->larg, RangeVar))
			{
				tsql_update_delete_stmt_from_clause_alias_helper(relation, (RangeVar *) (jexpr->larg));
			}
			if (IsA(jexpr->rarg, RangeVar))
			{
				tsql_update_delete_stmt_from_clause_alias_helper(relation, (RangeVar *) (jexpr->rarg));
			}
		}
	}
}

static Node *
tsql_insert_output_into_cte_transformation(WithClause *opt_with_clause, Node *opt_top_clause, RangeVar *insert_target,
										   List *insert_column_list, List *tsql_output_clause, RangeVar *output_target, List *tsql_output_into_target_columns,
										   InsertStmt *tsql_output_insert_rest, int select_location)
{

	CommonTableExpr *cte = makeNode(CommonTableExpr);
	WithClause *w = makeNode(WithClause);
	SelectStmt *n = makeNode(SelectStmt);
	InsertStmt *i = makeNode(InsertStmt);
	char	   *internal_ctename = NULL;
	char		ctename[NAMEDATALEN];
	ListCell   *expr;
	char		col_alias_arr[NAMEDATALEN];
	char	   *col_alias = NULL;
	List	   *output_list = NIL,
			   *queue = NIL;
	ListCell   *lc;
	Node	   *field1;
	char	   *qualifier = NULL;

	snprintf(ctename, NAMEDATALEN, "internal_output_cte##sys_gen##%p", (void *) i);
	internal_ctename = pstrdup(ctename);

	/* PreparableStmt inside CTE */
	i->cols = insert_column_list;
	i->selectStmt = tsql_output_insert_rest->selectStmt;
	i->limitCount = opt_top_clause;
	i->relation = insert_target;
	i->onConflictClause = NULL;
	i->returningList = get_transformed_output_list(tsql_output_clause);
	i->withClause = NULL;
	i->override = false;

	/*
	 * Make sure we do not pass inserted qualifier to the SELECT target list.
	 * Instead, we add an alias for column names qualified by inserted, and
	 * remove the inserted qualifier from *. We also make sure only one * is
	 * left in the output list inside the CTE.
	 */
	output_list = copyObject(tsql_output_clause);
	foreach(lc, output_list)
	{
		ResTarget  *res = (ResTarget *) lfirst(lc);

		queue = NIL;
		queue = list_make1(res->val);

		foreach(expr, queue)
		{
			Node	   *node = (Node *) lfirst(expr);

			if (IsA(node, ColumnRef))
			{
				ColumnRef  *cref = (ColumnRef *) node;

				if (list_length(cref->fields) >= 2)
				{
					field1 = (Node *) linitial(cref->fields);
					qualifier = strVal(field1);

					if (!strcmp(qualifier, "inserted"))
					{
						if (IsA((Node *) llast(cref->fields), String))
						{
							snprintf(col_alias_arr, NAMEDATALEN, "sys_gen##%pins_%s", (void *) tsql_output_clause, strVal(llast(cref->fields)));
							col_alias = pstrdup(col_alias_arr);
						}
						else
							cref->fields = list_delete_first(cref->fields);
					}
					if (col_alias)
						cref->fields = list_make1(makeString(col_alias));
				}
			}
			else if (IsA(node, A_Expr))
			{
				A_Expr	   *a_expr = (A_Expr *) node;

				if (a_expr->lexpr)
					queue = lappend(queue, a_expr->lexpr);
				if (a_expr->rexpr)
					queue = lappend(queue, a_expr->rexpr);
			}
			else if (IsA(node, FuncCall))
			{
				FuncCall   *func_call = (FuncCall *) node;

				if (func_call->args)
					queue = list_concat(queue, func_call->args);
			}
		}
	}

	/* SelectStmt inside outer InsertStmt */
	n->limitCount = NULL;
	n->targetList = output_list;
	n->intoClause = NULL;
	n->fromClause = list_make1(makeRangeVar(NULL, internal_ctename, select_location));

	/* Outer InsertStmt */
	tsql_output_insert_rest->selectStmt = (Node *) n;
	tsql_output_insert_rest->relation = output_target;
	tsql_output_insert_rest->onConflictClause = NULL;
	tsql_output_insert_rest->returningList = NULL;
	if (tsql_output_into_target_columns == NIL)
		tsql_output_insert_rest->cols = NIL;
	else
		tsql_output_insert_rest->cols = tsql_output_into_target_columns;

	/* CTE */
	cte->ctename = internal_ctename;
	cte->aliascolnames = NULL;
	cte->ctematerialized = CTEMaterializeDefault;
	cte->ctequery = (Node *) i;
	cte->location = 1;

	if (opt_with_clause)
	{
		opt_with_clause->ctes = lappend(opt_with_clause->ctes, (Node *) cte);
		tsql_output_insert_rest->withClause = opt_with_clause;
	}
	else
	{
		w->ctes = list_make1((Node *) cte);
		w->recursive = false;
		w->location = 1;
		tsql_output_insert_rest->withClause = w;
	}

	output_into_insert_transformation = true;

	return (Node *) tsql_output_insert_rest;
}

static Node *
tsql_delete_output_into_cte_transformation(WithClause *opt_with_clause, Node *opt_top_clause,
										   RangeVar *relation_expr_opt_alias, List *tsql_output_clause, RangeVar *insert_target,
										   List *tsql_output_into_target_columns, List *from_clause, Node *where_or_current_clause,
										   core_yyscan_t yyscanner)
{
	CommonTableExpr *cte = makeNode(CommonTableExpr);
	WithClause *w = makeNode(WithClause);
	SelectStmt *n = makeNode(SelectStmt);
	DeleteStmt *d = makeNode(DeleteStmt);
	InsertStmt *i = makeNode(InsertStmt);
	ListCell   *lc;
	Node	   *field1;
	char	   *qualifier = NULL;
	List	   *output_list = NIL,
			   *queue = NIL;
	char	   *internal_ctename = NULL;
	char		ctename[NAMEDATALEN];
	ListCell   *expr;
	char		col_alias_arr[NAMEDATALEN];
	char	   *col_alias = NULL;

	snprintf(ctename, NAMEDATALEN, "internal_output_cte##sys_gen##%p", (void *) i);
	internal_ctename = pstrdup(ctename);

	tsql_reset_update_delete_globals();

	/* PreparableStmt inside CTE */
	d->relation = relation_expr_opt_alias;
	tsql_update_delete_stmt_from_clause_alias(d->relation, from_clause);
	if (from_clause != NULL && IsA(linitial(from_clause), JoinExpr))
	{
		d = (DeleteStmt *) tsql_update_delete_stmt_with_join(
															 (Node *) d, from_clause, where_or_current_clause, opt_top_clause,
															 relation_expr_opt_alias, yyscanner);
	}
	else
	{
		d->usingClause = from_clause;
		d->whereClause = where_or_current_clause;
		d->limitCount = opt_top_clause;
	}
	d->returningList = get_transformed_output_list(tsql_output_clause);
	d->withClause = opt_with_clause;

	/*
	 * Make sure we do not pass deleted qualifier to the SELECT target list.
	 * Instead, we add an alias for column names qualified bydeleted, and
	 * remove the deleted qualifier from *.
	 */
	output_list = copyObject(tsql_output_clause);
	foreach(lc, output_list)
	{
		ResTarget  *res = (ResTarget *) lfirst(lc);

		queue = NIL;
		queue = list_make1(res->val);

		foreach(expr, queue)
		{
			Node	   *node = (Node *) lfirst(expr);

			if (IsA(node, ColumnRef))
			{
				ColumnRef  *cref = (ColumnRef *) node;

				if (list_length(cref->fields) >= 2)
				{
					field1 = (Node *) linitial(cref->fields);
					qualifier = strVal(field1);

					if (!strcmp(qualifier, "deleted"))
					{
						if (IsA((Node *) llast(cref->fields), String))
						{
							snprintf(col_alias_arr, NAMEDATALEN, "sys_gen##%pdel_%s", (void *) tsql_output_clause, strVal(llast(cref->fields)));
							col_alias = pstrdup(col_alias_arr);
						}
						else
							cref->fields = list_delete_first(cref->fields);
					}
					if (col_alias)
						cref->fields = list_make1(makeString(col_alias));
				}
			}
			else if (IsA(node, A_Expr))
			{
				A_Expr	   *a_expr = (A_Expr *) node;

				if (a_expr->lexpr)
					queue = lappend(queue, a_expr->lexpr);
				if (a_expr->rexpr)
					queue = lappend(queue, a_expr->rexpr);
			}
			else if (IsA(node, FuncCall))
			{
				FuncCall   *func_call = (FuncCall *) node;

				if (func_call->args)
					queue = list_concat(queue, func_call->args);
			}
		}
	}

	/* SelectStmt inside outer InsertStmt */
	n->limitCount = NULL;
	n->targetList = output_list;
	n->intoClause = NULL;
	n->fromClause = list_make1(makeRangeVar(NULL, internal_ctename, 4));

	/* Outer InsertStmt */
	i->selectStmt = (Node *) n;
	i->relation = insert_target;
	i->onConflictClause = NULL;
	i->returningList = NULL;
	i->cols = tsql_output_into_target_columns;

	/* CTE */
	cte->ctename = internal_ctename;
	cte->aliascolnames = NULL;
	cte->ctematerialized = CTEMaterializeDefault;
	cte->ctequery = (Node *) d;
	cte->location = 1;

	if (opt_with_clause)
	{
		opt_with_clause->ctes = lappend(opt_with_clause->ctes, (Node *) cte);
		i->withClause = opt_with_clause;
	}
	else
	{
		w->ctes = list_make1((Node *) cte);
		w->recursive = false;
		w->location = 1;
		i->withClause = w;
	}
	return (Node *) i;
}

static void
tsql_check_update_output_transformation(List *tsql_output_clause)
{
	ListCell   *lc;
	bool		deleted = false;

	/*
	 * Check for deleted qualifier in OUTPUT list. If there is no deleted
	 * qualifier, there is no need for parse tree rewrite because PG already
	 * supports returning modified (inserted) values.
	 */
	foreach(lc, tsql_output_clause)
	{
		ResTarget  *res = (ResTarget *) lfirst(lc);

		if (IsA(res->val, ColumnRef))
		{
			ColumnRef  *cref = (ColumnRef *) res->val;

			if (!strcmp(strVal((Node *) linitial(cref->fields)), "deleted"))
			{
				deleted = true;
				break;
			}
		}
	}
	if (deleted)
		output_update_transformation = true;
}

static Node *
tsql_update_output_into_cte_transformation(WithClause *opt_with_clause, Node *opt_top_clause,
										   RangeVar *relation_expr_opt_alias, List *set_clause_list,
										   List *tsql_output_clause, RangeVar *insert_target, List *tsql_output_into_target_columns,
										   List *from_clause, Node *where_or_current_clause, core_yyscan_t yyscanner)
{
	CommonTableExpr *cte = makeNode(CommonTableExpr);
	WithClause *w = makeNode(WithClause);
	SelectStmt *n = makeNode(SelectStmt);
	UpdateStmt *u = makeNode(UpdateStmt);
	InsertStmt *i = makeNode(InsertStmt);
	ListCell   *lc;
	Node	   *field1;
	char	   *qualifier = NULL;
	List	   *output_list = NIL,
			   *queue = NIL;
	char	   *internal_ctename = NULL;
	char		ctename[NAMEDATALEN];
	ListCell   *expr;
	char		col_alias_arr[NAMEDATALEN];
	char	   *col_alias = NULL;

	snprintf(ctename, NAMEDATALEN, "internal_output_cte##sys_gen##%p", (void *) i);
	internal_ctename = pstrdup(ctename);

	tsql_reset_update_delete_globals();

	/* PreparableStmt inside CTE */
	u->relation = relation_expr_opt_alias;
	tsql_update_delete_stmt_from_clause_alias(u->relation, from_clause);
	u->targetList = set_clause_list;
	if (from_clause != NULL && IsA(linitial(from_clause), JoinExpr))
	{
		u = (UpdateStmt *) tsql_update_delete_stmt_with_join(
															 (Node *) u, from_clause, where_or_current_clause, opt_top_clause,
															 relation_expr_opt_alias, yyscanner);
	}
	else
	{
		u->fromClause = from_clause;
		u->whereClause = where_or_current_clause;
		u->limitCount = opt_top_clause;
	}
	u->returningList = get_transformed_output_list(tsql_output_clause);
	u->withClause = opt_with_clause;

	tsql_check_update_output_transformation(tsql_output_clause);

	/*
	 * Make sure we do not pass deleted or inserted qualifier to the SELECT
	 * target list. Instead, we add an alias for column names qualified by
	 * inserted/deleted, and remove the inserted/deleted qualifier from *.
	 */
	output_list = copyObject(tsql_output_clause);
	foreach(lc, output_list)
	{
		ResTarget  *res = (ResTarget *) lfirst(lc);

		queue = NIL;
		queue = list_make1(res->val);

		foreach(expr, queue)
		{
			Node	   *node = (Node *) lfirst(expr);

			if (IsA(node, ColumnRef))
			{
				ColumnRef  *cref = (ColumnRef *) node;

				if (list_length(cref->fields) >= 2)
				{
					field1 = (Node *) linitial(cref->fields);
					qualifier = strVal(field1);

					if (!strcmp(qualifier, "deleted"))
					{
						if (IsA((Node *) llast(cref->fields), String))
						{
							snprintf(col_alias_arr, NAMEDATALEN, "sys_gen##%pdel_%s", (void *) tsql_output_clause, strVal(llast(cref->fields)));
							col_alias = pstrdup(col_alias_arr);
						}
						else
							cref->fields = list_delete_first(cref->fields);
					}
					else if (!strcmp(qualifier, "inserted"))
					{
						if (IsA((Node *) llast(cref->fields), String))
						{
							snprintf(col_alias_arr, NAMEDATALEN, "sys_gen##%pins_%s", (void *) tsql_output_clause, strVal(llast(cref->fields)));
							col_alias = pstrdup(col_alias_arr);
						}
						else
							cref->fields = list_delete_first(cref->fields);
					}
					if (col_alias)
						cref->fields = list_make1(makeString(col_alias));
				}
			}
			else if (IsA(node, A_Expr))
			{
				A_Expr	   *a_expr = (A_Expr *) node;

				if (a_expr->lexpr)
					queue = lappend(queue, a_expr->lexpr);
				if (a_expr->rexpr)
					queue = lappend(queue, a_expr->rexpr);
			}
			else if (IsA(node, FuncCall))
			{
				FuncCall   *func_call = (FuncCall *) node;

				if (func_call->args)
					queue = list_concat(queue, func_call->args);
			}
		}
	}

	/* SelectStmt inside outer InsertStmt */
	n->limitCount = NULL;
	n->targetList = output_list;
	n->intoClause = NULL;
	n->fromClause = list_make1(makeRangeVar(NULL, internal_ctename, -1));

	/* Outer InsertStmt */
	i->selectStmt = (Node *) n;
	i->relation = insert_target;
	i->onConflictClause = NULL;
	i->returningList = NULL;
	i->cols = tsql_output_into_target_columns;

	/* CTE */
	cte->ctename = internal_ctename;
	cte->aliascolnames = NULL;
	cte->ctematerialized = CTEMaterializeDefault;
	cte->ctequery = (Node *) u;
	cte->location = 1;

	if (opt_with_clause)
	{
		opt_with_clause->ctes = lappend(opt_with_clause->ctes, (Node *) cte);
		i->withClause = opt_with_clause;
	}
	else
	{
		w->ctes = list_make1((Node *) cte);
		w->recursive = false;
		w->location = 1;
		i->withClause = w;
	}
	return (Node *) i;
}

/*
* get_transformed_output_list() extracts the ColumnRefs from functions and
* expressions so that the returning list in the rewritten CTE for OUTPUT INTO
* transformation does not contain functions and expressions. It also adds an
* alias to columns qualified by inserted or deleted.
*/
static List *
get_transformed_output_list(List *tsql_output_clause)
{
	List	   *transformed_returning_list = NIL,
			   *queue = NIL,
			   *output_list = NIL;
	List	   *ins_colnames = NIL,
			   *del_colnames = NIL;
	ListCell   *o_target,
			   *expr;
	char		col_alias_arr[NAMEDATALEN];
	char	   *col_alias = NULL;
	PLtsql_execstate *estate;
	int			i = 0;
	bool		local_variable = false,
				ins_star = false,
				del_star = false,
				is_duplicate = false;

	estate = get_current_tsql_estate();

	output_list = copyObject(tsql_output_clause);
	foreach(o_target, output_list)
	{
		ResTarget  *res = (ResTarget *) lfirst(o_target);

		queue = NIL;
		queue = list_make1(res->val);

		foreach(expr, queue)
		{
			Node	   *node = (Node *) lfirst(expr);

			if (IsA(node, ColumnRef))
			{
				ResTarget  *target = makeNode(ResTarget);
				ColumnRef  *cref = (ColumnRef *) node;

				local_variable = false;

				if (!strcmp(strVal(linitial(cref->fields)), "deleted") && list_length(cref->fields) >= 2)
				{
					if (IsA((Node *) llast(cref->fields), String))
					{
						is_duplicate = returning_list_has_column_name(del_colnames, strVal(llast(cref->fields)));
						if (!is_duplicate)
						{
							snprintf(col_alias_arr, NAMEDATALEN, "sys_gen##%pdel_%s", (void *) tsql_output_clause, strVal(llast(cref->fields)));
							col_alias = pstrdup(col_alias_arr);
							target->name = col_alias;
							del_colnames = lappend(del_colnames, strVal(llast(cref->fields)));
						}
					}
					else if (IsA((Node *) llast(cref->fields), A_Star))
						ins_star = true;

				}
				else if (!strcmp(strVal(linitial(cref->fields)), "inserted") && list_length(cref->fields) >= 2)
				{
					if (IsA((Node *) llast(cref->fields), String))
					{
						is_duplicate = returning_list_has_column_name(ins_colnames, strVal(llast(cref->fields)));
						if (!is_duplicate)
						{
							snprintf(col_alias_arr, NAMEDATALEN, "sys_gen##%pins_%s", (void *) tsql_output_clause, strVal(llast(cref->fields)));
							col_alias = pstrdup(col_alias_arr);
							target->name = col_alias;
							ins_colnames = lappend(ins_colnames, strVal(llast(cref->fields)));
						}
					}
					else if (IsA((Node *) llast(cref->fields), A_Star))
						del_star = true;
				}
				else
				{
					if (!strncmp(strVal(linitial(cref->fields)), "@", 1) && estate)
					{
						for (i = 0; i < estate->ndatums; i++)
						{
							PLtsql_datum *d = estate->datums[i];

							if (!strcmp(strVal(linitial(cref->fields)), ((PLtsql_variable *) d)->refname))
							{
								local_variable = true;
								break;
							}
						}
					}
				}
				if (ins_star && del_star)
					ereport(
							ERROR,
							(errcode(ERRCODE_SYNTAX_ERROR),
							 errmsg("OUTPUT INTO does not support both inserted.* and deleted.* in target list")
							 )
						);
				if (!local_variable)
				{
					target->val = (Node *) cref;
					transformed_returning_list = lappend(transformed_returning_list, target);
				}
			}
			else if (IsA(node, A_Expr))
			{
				A_Expr	   *a_expr = (A_Expr *) node;

				if (a_expr->lexpr)
					queue = lappend(queue, a_expr->lexpr);
				if (a_expr->rexpr)
					queue = lappend(queue, a_expr->rexpr);
			}
			else if (IsA(node, FuncCall))
			{
				FuncCall   *func_call = (FuncCall *) node;

				if (func_call->args)
					queue = list_concat(queue, func_call->args);
			}
		}
	}
	return transformed_returning_list;
}

/*
* returning_list_has_column_name() checks whether a particular column name already
* exists in the transformed returning list for OUTPUT clause. Such a scenario is
* possible because get_transformed_output_list() removes functions and expressions
* and only retains the column names.
*/
static bool
returning_list_has_column_name(List *existing_colnames, char *current_colname)
{
	ListCell   *name;
	bool		is_duplicate = false;

	if (existing_colnames == NIL)
		return false;

	foreach(name, existing_colnames)
	{
		char	   *colname = (char *) lfirst(name);

		if (!strcmp(colname, current_colname))
		{
			is_duplicate = true;
			break;
		}
	}
	return is_duplicate;
}

/*
 * Make a function call to tsql_select_for_xml_agg() for FOR JSON clause.
 */
ResTarget *
TsqlForXMLMakeFuncCall(TSQL_ForClause *forclause)
{
	ResTarget  *rt = makeNode(ResTarget);
	FuncCall   *fc;
	List	   *func_name;
	List	   *func_args;
	bool		binary_base64 = false;
	bool		return_xml_type = false;
	char	   *root_name = NULL;

	/* Resolve the XML common directive list if provided */
	if (forclause->commonDirectives != NIL)
	{
		ListCell   *lc;

		foreach(lc, forclause->commonDirectives)
		{
			Node	   *myNode = lfirst(lc);
			A_Const    *myConst;

			/* commonDirective is either integer const or string const */
			Assert(IsA(myNode, A_Const));
			myConst = (A_Const *) myNode;
			Assert(IsA(&myConst->val, Integer) || IsA(&myConst->val, String));
			if (IsA(&myConst->val, Integer))
			{
				if (myConst->val.ival.ival == TSQL_XML_DIRECTIVE_BINARY_BASE64)
					binary_base64 = true;
				else if (myConst->val.ival.ival == TSQL_XML_DIRECTIVE_TYPE)
					return_xml_type = true;
			}
			else if (IsA(&myConst->val, String))
			{
				root_name = myConst->val.sval.sval;
			}
		}
	}

	/*
	 * Finally make function call to tsql_select_for_xml_agg or
	 * tsql_select_for_xml_text_agg depending on the return_xml_type flag
	 * (TYPE option in the FOR XML clause). The only difference of the two
	 * functions is the return type. tsql_select_for_xml_agg returns XML type,
	 * tsql_select_for_xml_text_agg returns text type.
	 */
	if (return_xml_type)
		func_name = list_make2(makeString("sys"), makeString("tsql_select_for_xml_agg"));
	else
		func_name = list_make2(makeString("sys"), makeString("tsql_select_for_xml_text_agg"));
	func_args = list_make5(makeColumnRef(construct_unique_index_name("rows", "tsql_for"), NIL, -1, NULL),
						   makeIntConst(forclause->mode, -1),
						   forclause->elementName ? makeStringConst(forclause->elementName, -1) : makeStringConst("row", -1),
						   makeBoolAConst(binary_base64, -1),
						   root_name ? makeStringConst(root_name, -1) : makeStringConst("", -1));
	fc = makeFuncCall(func_name, func_args, COERCE_EXPLICIT_CALL, -1);

	/*
	 * In SQL Server if the result is empty then 0 rows are returned.
	 * Unfortunately it is not possible to mimic this behavior solely using an
	 * aggregate, so we use an additional SRF and pass the result to that
	 * function so that returning 0 rows is possible.
	 */
	func_name = list_make2(makeString("sys"),
						   makeString(return_xml_type ?
									  "tsql_select_for_xml_result" :
									  "tsql_select_for_xml_text_result"));
	func_args = list_make1(fc);
	fc = makeFuncCall(func_name, func_args, COERCE_EXPLICIT_CALL, -1);

	rt->name = palloc0(4);
	strncpy(rt->name, "xml", 3);
	rt->indirection = NIL;
	rt->val = (Node *) fc;
	rt->location = -1;
	rt->name_location = -1;
	return rt;
}

/*
 * Make a function call to tsql_select_for_json_agg() for FOR JSON clause.
 */
static ResTarget *
TsqlForJSONMakeFuncCall(TSQL_ForClause *forclause)
{
	ResTarget  *rt = makeNode(ResTarget);
	FuncCall   *fc;
	List	   *func_name;
	List	   *func_args;
	bool		include_null_values = false;
	bool		without_array_wrapper = false;
	char	   *root_name = NULL;

	/* Resolve the JSON common directive list if provided */
	if (forclause->commonDirectives != NIL)
	{
		ListCell   *lc;

		foreach(lc, forclause->commonDirectives)
		{
			Node	   *myNode = lfirst(lc);
			A_Const    *myConst;

			/* commonDirective is either integer const or string const */
			Assert(IsA(myNode, A_Const));
			myConst = (A_Const *) myNode;
			Assert(IsA(&myConst->val, Integer) || IsA(&myConst->val, String));
			if (IsA(&myConst->val, Integer))
			{
				if (myConst->val.ival.ival == TSQL_JSON_DIRECTIVE_INCLUDE_NULL_VALUES)
					include_null_values = true;
				if (myConst->val.ival.ival == TSQL_JSON_DIRECTIVE_WITHOUT_ARRAY_WRAPPER)
					without_array_wrapper = true;
			}
			else if (IsA(&myConst->val, String))
			{
				root_name = myConst->val.sval.sval;
			}
		}
	}

	/*
	 * ROOT option and WITHOUT_ARRAY_WRAPPER option cannot be used together in
	 * FOR JSON
	 */
	if (root_name && without_array_wrapper)
	{
		ereport(ERROR,
				(errcode(ERRCODE_INTERNAL_ERROR),
				 errmsg("ROOT option and WITHOUT_ARRAY_WRAPPER option cannot be used together in FOR JSON. Remove one of these options")));
	}

	/*
	 * Make function call to tsql_select_for_json_agg
	 */
	func_name = list_make2(makeString("sys"), makeString("tsql_select_for_json_agg"));
	func_args = list_make5(makeColumnRef(construct_unique_index_name("rows", "tsql_for"), NIL, -1, NULL),
						   makeIntConst(forclause->mode, -1),
						   makeBoolAConst(include_null_values, -1),
						   makeBoolAConst(without_array_wrapper, -1),
						   root_name ? makeStringConst(root_name, -1) : makeNullAConst(-1));
	fc = makeFuncCall(func_name, func_args, COERCE_EXPLICIT_CALL, -1);

	/*
	 * In SQL Server if the result is empty then 0 rows are returned.
	 * Unfortunately it is not possible to mimic this behavior solely using an
	 * aggregate, so we use an additional SRF and pass the result to that
	 * function so that returning 0 rows is possible.
	 */
	func_name = list_make2(makeString("sys"), makeString("tsql_select_for_json_result"));
	func_args = list_make1(fc);
	fc = makeFuncCall(func_name, func_args, COERCE_EXPLICIT_CALL, -1);

	rt->name = palloc0(5);
	strncpy(rt->name, "json", 4);
	rt->indirection = NIL;
	rt->val = (Node *) fc;
	rt->location = -1;
	rt->name_location = -1;
	return rt;
}

/*
 * Create an aliased sub-select clause for use in FOR XML/JSON
 * rule resolution. We re-use construct_unique_index_name to
 * generate a unique row name to reference - this makes it virtually
 * impossible for any query to accidentally use the same alias name.
 * construct_unique_index_name should only fail in case of OOM, which
 * is highly unlikely.
 */
static RangeSubselect *
TsqlForClauseSubselect(Node *selectstmt)
{
	RangeSubselect *rss = makeNode(RangeSubselect);

	rss->subquery = selectstmt;
	rss->alias = makeAlias(construct_unique_index_name("rows", "tsql_for"), NIL);
	return rss;
}

static Node *
buildTsqlMultiLineTvfNode(int create_loc, bool replace, List *func_name, int func_name_loc, List *tsql_createfunc_args,
							char *param_name, int table_loc, List *table_elts, char *tokens_remaining, int tokens_loc, bool alter, core_yyscan_t yyscanner)
{
	if (sql_dialect == SQL_DIALECT_TSQL)
	{
		CreateStmt *n1 = makeNode(CreateStmt);
		CreateFunctionStmt *n2;
		ObjectWithArgs *owa;
		AlterFunctionStmt *n;
		char *tbltyp_name = psprintf("%s_%s", param_name, strVal(llast(func_name)));
		List *tbltyp = list_copy(func_name);
		FunctionParameter *out_param = makeNode(FunctionParameter);

		DefElem *lang = makeDefElem("language", (Node *) makeString("pltsql"), create_loc);
		DefElem *body = makeDefElem("as", (Node *) list_make1(makeString(tokens_remaining)), tokens_loc);
		DefElem *tbltypStmt = makeDefElem("tbltypStmt", (Node *) n1, create_loc);
		DefElem *location = makeDefElem("location", (Node *) makeInteger(func_name_loc), func_name_loc);
		DefElem *ret;
		TypeName *returnType;

		tbltyp = list_truncate(tbltyp, list_length(tbltyp) - 1);
		tbltyp = lappend(tbltyp, makeString(downcase_truncate_identifier(tbltyp_name, strlen(tbltyp_name), true)));
		n1->relation = makeRangeVarFromAnyName(tbltyp, func_name_loc, yyscanner);
		n1->tableElts = table_elts;
		n1->inhRelations = NIL;
		n1->partspec = NULL;
		n1->ofTypename = NULL;
		n1->constraints = NIL;
		n1->options = NIL;
		n1->oncommit = ONCOMMIT_NOOP;
		n1->tablespacename = NULL;
		n1->if_not_exists = false;
		n1->tsql_tabletype = true;

		out_param->name = param_name;
		out_param->argType = makeTypeNameFromNameList(tbltyp);
		out_param->mode = FUNC_PARAM_TABLE;
		out_param->defexpr = NULL;

		if(alter)
		{
			returnType = out_param->argType;
			returnType->setof = true;
			returnType->location = table_loc;
			ret = makeDefElem("return", (Node *) returnType, table_loc);

			owa = makeNode(ObjectWithArgs);
			owa->objname = func_name;
			owa->objargs = lappend(extractArgTypes(tsql_createfunc_args), out_param->argType);
			owa->objfuncargs = lappend(tsql_createfunc_args, out_param);

			n = makeNode(AlterFunctionStmt);
			n->objtype = OBJECT_PROCEDURE; /* Set as proc to avoid psql alter func impl */
			n->func = owa;
			n->actions = list_make5(lang, body, location, tbltypStmt, ret);

			return (Node *) n;
		} 

		TSQLInstrumentation(INSTR_TSQL_CREATE_FUNCTION_RETURNS_TABLE);
		n2 = makeNode(CreateFunctionStmt);
		n2->is_procedure = false;
		n2->replace = replace;
		n2->funcname = func_name;
		n2->parameters = lappend(tsql_createfunc_args, out_param);
		n2->returnType = makeTypeNameFromNameList(tbltyp);
		n2->returnType->setof = true;
		n2->returnType->location = table_loc;
		n2->options = list_make4(lang, body, tbltypStmt, location);
		return (Node *) n2;
	}
	else
	{
		ereport(ERROR,
				(errcode(ERRCODE_SYNTAX_ERROR),
					errmsg("This syntax is only valid when babelfishpg_tsql.sql_dialect is TSQL"),
					parser_errposition(create_loc)));
	}
}

/* pivot select transformation*/
static Node *
tsql_pivot_select_transformation(List *target_list, List *from_clause, List *pivot_clause, Alias *alias_clause, SelectStmt *pivot_sl)
{
	FuncCall   	*pivotCall;
	ColumnRef  		*a_star;
	ResTarget		*a_star_restarget;
	RangeFunction	*funCallNode;
	SelectStmt 	*src_sql;
	SortBy 		*s;

	Node 		*aggFunc = (Node *) list_nth(pivot_clause, 1);
	
	/* prepare SortBy node for source sql */
	s = makeNode(SortBy);
	s->node = makeIntConst(1, -1);
	s->sortby_dir = 0;
	s->sortby_nulls = 0;     
	s->useOp = NIL;
	s->location = -1;

	/* transform to select * from funcCall as newtable(a type1, b type2 ...) */
	a_star = makeNode(ColumnRef);
	a_star->fields = list_make1(makeNode(A_Star));
	a_star->location = -1;
	a_star_restarget = makeNode(ResTarget);
	a_star_restarget->name = NULL;
	a_star_restarget->name_location = -1;
	a_star_restarget->indirection = NIL;
	a_star_restarget->val = (Node *) a_star;
	a_star_restarget->location = -1;

	/* prepare source sql for babelfish_pivot function */
	src_sql = makeNode(SelectStmt);
	src_sql->targetList = list_make1(a_star_restarget);
	src_sql->fromClause = from_clause;
	src_sql->sortClause = list_make1(s);

	/* create a function call node for the fromClause */
	pivotCall = makeFuncCall(TsqlSystemFuncName2("bbf_pivot"),NIL, COERCE_EXPLICIT_CALL, -1);
	funCallNode = makeNode(RangeFunction);
	funCallNode->lateral = false;
	funCallNode->is_rowsfrom = false;
	funCallNode->functions = list_make1(list_make2((Node *) pivotCall, NIL));
	funCallNode->alias = alias_clause;
	
	pivot_sl->targetList = target_list;
	pivot_sl->fromClause = list_make1(funCallNode);
	pivot_sl->isPivot = true;
	pivot_sl->srcSql = src_sql;
	pivot_sl->catSql = list_nth(pivot_clause, 2);
	pivot_sl->pivotCol = list_nth(pivot_clause, 0);;
	pivot_sl->aggFunc = aggFunc;
	pivot_sl->value_col_strlist = (List *) list_nth(pivot_clause, 3);

	return (Node *)pivot_sl;
}

/* 
 * Adjust index nulls order to match SQL Server behavior.
 * For ASC (or unspecified) index, default should be NULLS FIRST;
 * for DESC index, default should be NULLS LAST.
 */
static void 
tsql_index_nulls_order(List *indexParams, const char *accessMethod)
{
	ListCell *lc;

	foreach(lc, indexParams)
	{
		Node *n = lfirst(lc);
		IndexElem *indexElem;

		if (!IsA(n, IndexElem))
			continue;

		indexElem = (IndexElem *) n;

		/* No need to adjust if user already specified the nulls order */
		if (indexElem->nulls_ordering != SORTBY_NULLS_DEFAULT)
			continue;

		/* GIN, HNSW and IVFFLAT indexes don't support NULLS FIRST/LAST options */
		if (strcmp(accessMethod, "gin") == 0 || strcmp(accessMethod, "hnsw") == 0 || strcmp(accessMethod, "ivfflat") == 0)
			return;

		switch (indexElem->ordering)
		{
			case SORTBY_ASC:
			case SORTBY_DEFAULT:
				indexElem->nulls_ordering = SORTBY_NULLS_FIRST;
				break;
			case SORTBY_DESC:
				indexElem->nulls_ordering = SORTBY_NULLS_LAST;
				break;
			default:
				break;
		}
	}
}

static void
check_server_role_and_throw_if_unsupported (const char *serverrole, int position, core_yyscan_t yyscanner)
{
	if (strcmp(serverrole, "serveradmin") == 0
		|| strcmp(serverrole, "setupadmin") == 0
		|| strcmp(serverrole, "processadmin") == 0
		|| strcmp(serverrole, "diskadmin") == 0
		|| strcmp(serverrole, "bulkadmin") == 0) 
	{
			ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
					errmsg("Fixed server role '%s' is currently not supported in Babelfish", serverrole),
										parser_errposition(position)));
	}
	else if (!IS_ROLENAME_SYSADMIN(serverrole) && !IS_ROLENAME_SECURITYADMIN(serverrole))
	{
		ereport(ERROR, (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				errmsg("Only fixed server role is supported in ALTER SERVER ROLE statement"),
							parser_errposition(position)));
	}
}
