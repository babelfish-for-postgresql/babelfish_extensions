void
pgtsql_parser_init(base_yy_extra_type *yyext)
{
	parser_init(yyext);
}

static void
pgtsql_base_yyerror(YYLTYPE *yylloc, core_yyscan_t yyscanner, const char *msg)
{
	base_yyerror(yylloc, yyscanner, msg);
}

static Node *
makeTSQLHexStringConst(char *str, int location)
{
	A_Const *n = makeNode(A_Const);

	n->val.type = T_TSQL_HexString;
	n->val.val.str = str;
	n->location = location;

	return (Node *)n;
}

/* tsql_completeDefaultValues
 * fill NULL as default value for any trailing params
 * following the first param with default value
 */
static void
tsql_completeDefaultValues(List *parameters)
{
	ListCell   *i;
	bool fill = false;
	foreach(i, parameters)
	{
		FunctionParameter *p = (FunctionParameter *) lfirst(i);
		if (p->defexpr)
			fill = true;

		if (fill && !p->defexpr)
			p->defexpr = makeNullAConst(0);  /* no location available */
	}
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
construct_unique_index_name(char *index_name, char *relation_name) {
    char md5[MD5_HASH_LEN + 1];
    char buf[2 * NAMEDATALEN + MD5_HASH_LEN + 1];
    char* name;
    bool success;
    int full_len;
    int new_len;
    int index_len;
    int relation_len;

    if (index_name == NULL || relation_name == NULL) {
        return index_name;
    }
    index_len = strlen(index_name);
    relation_len = strlen(relation_name);

    success = pg_md5_hash(index_name, index_len, md5);
    if (unlikely(!success)) { /* OOM */
        ereport(
                ERROR,
                (errcode(ERRCODE_INTERNAL_ERROR),
                        errmsg(
                                "constructing unique index name failed: index = \"%s\", relation = \"%s\", ",
                                index_name,
                                relation_name
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
    Assert(new_len < NAMEDATALEN); /* result new_len is below max */

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
	RangeVar *r = makeNode(RangeVar);

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
*TsqlFunctionChoose(Node *int_expr, List *choosable, int location)
{
	CaseExpr *c = makeNode(CaseExpr);
	ListCell *lc;
	int i = 1;

	TSQLInstrumentation(INSTR_TSQL_FUNCTION_CHOOSE);

	if (choosable == NIL)
		elog(ERROR,
				"Function 'choose' requires at least 2 argument(s)");

	foreach(lc, choosable)
	{
		CaseWhen *w = makeNode(CaseWhen);
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
	Node *result;
	List *args;
	int32 typmod;
	Oid type_oid;
	char *typename_string;

    /* For handling try boolean logic on babelfishpg_tsql side */
    Node *try_const = makeBoolAConst(try, location);
    if (style)
		args = list_make3(arg, try_const, style);
    else
	    args = list_make2(arg, try_const);

	typenameTypeIdAndMod(NULL, typename, &type_oid, &typmod);
	typename_string = TypeNameToString(typename);

	TSQLInstrumentation(INSTR_TSQL_FUNCTION_CONVERT);

	if (type_oid == DATEOID)
        result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_conv_helper_to_date"), args, location);
	else if (type_oid == TIMEOID)
	    result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_conv_helper_to_time"), args, location);
	else if (type_oid == typenameTypeId(NULL, makeTypeName("datetime")))
	    result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_conv_helper_to_datetime"), args, location);
	else if (strcmp(typename_string, "varchar") == 0)
	{
		Node *helperFuncCall;

        typename_string = format_type_extended(VARCHAROID, typmod, FORMAT_TYPE_TYPEMOD_GIVEN);
	    args = lcons(makeStringConst(typename_string, typename->location), args);
	    helperFuncCall = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_conv_helper_to_varchar"), args, location);
		/* BABEL-1661, add a type cast on top of the CONVERT helper function so typmod can be applied */
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

/* TsqlFunctionParse -- Implements the PARSE and TRY_PARSE functions.
 * Takes in expression, target type, regional culture, try boolean, location.
 *
 * Parses text input to date/time and number types. Uses try boolean to determine returning
 * an error or null if cast fails.
 */
Node *
TsqlFunctionParse(Node *arg, TypeName *typename, Node *culture, bool try, int location)
{
        Node *result;
        List *args;
        int32 typmod;
        Oid type_oid;

        /* So far only date, time, and datetime need try_const and culture if not null since
         * only they have specialized functions implemented in PG TSQL.
         */
        Node *try_const = makeBoolAConst(try, location);
        if (culture)
                args = list_make3(arg, try_const, culture);
        else
                args = list_make2(arg, try_const);

        typenameTypeIdAndMod(NULL, typename, &type_oid, &typmod);

        TSQLInstrumentation(INSTR_TSQL_FUNCTION_PARSE);

        if (type_oid == DATEOID)
                result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_parse_helper_to_date"), args, location);
        else if (type_oid == TIMEOID)
                result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_parse_helper_to_time"), args, location);
        else if (type_oid == typenameTypeId(NULL, makeTypeName("datetime")))
                result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_parse_helper_to_datetime"), args, location);
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
        Node *result;
        int32 typmod;
        Oid type_oid;

        typenameTypeIdAndMod(NULL, typename, &type_oid, &typmod);

        TSQLInstrumentation(INSTR_TSQL_FUNCTION_TRY_CAST);

        /* Going case-by-case since it seems we cannot define a wrapper try_cast function that takes in an
         * arg of any type and returns any type. Can reduce cases to handle by having a generic cast at the end
         * that casts the arg to TEXT then casts to the target type. Works for most cases but not all such as casting
         * float to int.
         */
        if (type_oid == INT2OID)
                result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_try_cast_floor_smallint"), list_make1(arg), location);
        else if (type_oid == INT4OID)
                result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_try_cast_floor_int"), list_make1(arg), location);
        else if (type_oid == INT8OID)
                result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_try_cast_floor_bigint"), list_make1(arg), location);
        else
        {
                Node *arg_const = makeTypeCast(arg, SystemTypeName("text"), location);

                /* Cast null to typename to take advantage of polymorphic types in Postgres. */
                Node *null_const = makeTypeCast(makeNullAConst(location), typename, location);

                List *args = list_make3(arg_const, null_const, makeIntConst(typmod, location));
                result = (Node *) makeFuncCall(TsqlSystemFuncName("babelfish_try_cast_to_any"), args, location);
        }

        return result;
}

Node *
TsqlFunctionIIF(Node *bool_expr, Node *arg1, Node *arg2, int location)
{
	CaseExpr *c = makeNode(CaseExpr);
	CaseWhen *w = makeNode(CaseWhen);

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
	TypeName *typeclone = copyObjectImpl(typename);

	/* work on the cloned object to avoid double rewriting */
	rewrite_plain_name(typeclone->names);
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
 * Make a function call to tsql_query_to_xml for FOR XML clause.
 * For example, it does the following transformation:
 * select a from t for xml path =>
 * select tsql_query_to_xml('select a from t', ... )
 * The first argument of the function is the query string without the for xml clause.
 * The rest of the arguments passe in options and directives allowed by tsql.
 *
 * If the for xml clause has TSQL variables/identifiers that needs to be binded
 * (e.g. @varName that's used as a procedure parameter) during parse analysis,
 * we transform the query to use PG's function FORMAT in order to support the
 * variable binding, for example:
 * select a from t where id = @pid for xml path =>
 * select tsql_query_toxml(FORMAT('select a from t where id = %s', @pid) ... )
 */
ResTarget *
TsqlForXMLMakeFuncCall(TSQL_ForClause* forclause, char* src_query, size_t start_location, core_yyscan_t yyscanner)
{
	ResTarget *rt = makeNode(ResTarget);
	FuncCall *fc;
	size_t len = (forclause)->location - start_location;
	char *query = palloc(len + 1);
	List *func_name;
	List *func_args;
	int begin_index;
	int end_index;
	char *begin_param;
	char *end_param;
	StringInfo format_query = makeStringInfo();
	List *params = NIL;
	bool binary_base64 = false;
	bool return_xml_type = false;
	char* root_name = NULL;
	Node* arg1;

	/* Resolve the XML common directive list if provided */
	if (forclause->commonDirectives != NIL)
	{
		ListCell *lc;
		foreach (lc, forclause->commonDirectives)
		{
			Node *myNode = lfirst(lc);
			A_Const *myConst;

			/* commonDirective is either integer const or string const */
			Assert(IsA(myNode, A_Const));
			myConst = (A_Const *)myNode;
			Assert(myConst->val.type == T_Integer || myConst->val.type == T_String);
			if (myConst->val.type == T_Integer)
			{
				if (myConst->val.val.ival == TSQL_XML_DIRECTIVE_BINARY_BASE64)
					binary_base64 = true;
				else if (myConst->val.val.ival == TSQL_XML_DIRECTIVE_TYPE)
					return_xml_type = true;
			}
			else if (myConst->val.type == T_String)
			{
				root_name = myConst->val.val.str;
			}
		}
	}

	query = memcpy(query,
				   src_query + start_location,
				   len);
	query[len] = '\0';

	/*
	 * Transform query with tsql identifiers (@pname) to PG's FORMAT function so
	 * variable binding still works.
	 * For example:
	 * select a from t where id = @pid for xml path =>
	 * select tsql_query_toxml(FORMAT('select a from t where id = %s', @pid) ... )
	 * Notice the tsql identifiers in the query string has already been
	 * processed by the babelfishpg_tsql parser at this point and is surrounded by quote
	 * such as in \"@pid"\.
	 *
	 * We achieve the above transformation by extacting all parameters starting
	 * with \"@ from the query string, and replace them with %s. The StringInfo
	 * variable format_query is used to assemble the new query in this process.
	 * end_param points the remaiming query string after the parameter, initially
	 * we set it to the query string. begin_param points to the begining of a
	 * parameter or tsql identifer, starting from left to right in the query string.
	 */
	end_param = query;
	while ((begin_param = strstr(end_param, "\"@")) != NULL)
	{
		char *before_param;

		begin_index = begin_param - end_param;
		before_param = palloc(begin_index + 1);
		before_param = memcpy(before_param, end_param, begin_index);
		before_param[begin_index] = '\0';
		if ((end_param = strstr(begin_param+2, "\"")) != NULL)
		{
			char *param;

			end_index = (end_param - begin_param) + begin_index;
			appendStringInfoString(format_query, before_param);
			appendStringInfoString(format_query, "%L");
			param = palloc(end_index - begin_index);
			param = memcpy(param, begin_param + 1, end_index - begin_index - 1);
			param[end_index - begin_index - 1] = '\0';
			params = lappend(params, makeColumnRef(param, NIL, -1, yyscanner));
			/* Move end_param pass the \", so it points to the rest of the query */
			end_param++;
		}
		else
		{
			/*
			 * Unmatched quote around the tsql identification, it shouldn't happen
			 * because proper quoting is done in babelfishpg_tsql parser.
			 * But just in case report an error.
			 */
			ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
					 errmsg("Unmatched quote around TSQL identifier")));
		}
	}

	/*
	 * Make a function call to Function FORMAT if format_query is built from the
	 * above process.
	 */
	if (format_query->len > 0)
	{
		FuncCall *format_fc;
		List *format_func_args;
		appendStringInfoString(format_query, end_param);
		format_func_args = list_concat(list_make1(makeStringConst(format_query->data, -1)),
									   params);
		format_fc = makeFuncCall(list_make1(makeString("format")), format_func_args, -1);
		arg1 = (Node *) format_fc;
	}
	else
		arg1 = makeStringConst(query, -1);

	/*
	 * Finally make funtion call to tsql_query_to_xml or tsql_query_to_xml_text
	 * depending on the return_xml_type flag (TYPE option in the FOR XML clause).
	 * The only difference of the two functions is the return type. tsql_query_to_xml
	 * returns XML type, tsql_query_to_xml_text returns text type.
	 */
	if (return_xml_type)
		func_name= list_make2(makeString("sys"), makeString("tsql_query_to_xml"));
	else
		func_name= list_make2(makeString("sys"), makeString("tsql_query_to_xml_text"));
	func_args = list_make4(arg1,
						   makeIntConst(forclause->mode, -1),
						   forclause->elementName ? makeStringConst(forclause->elementName, -1) :
						   makeStringConst("row", -1),
						   makeBoolAConst(binary_base64, -1));
	func_args = lappend(func_args, root_name ? makeStringConst(root_name, -1) : makeStringConst("", -1));
	fc = makeFuncCall(func_name, func_args, -1);

	rt->name = NULL;
	rt->indirection = NIL;
	rt->val = (Node *) fc;
	rt->location = -1;
	return rt;
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
tsql_update_delete_stmt_with_join(Node *n, List* from_clause, Node*
								  where_clause, Node *top_clause,
								  RangeVar *relation, core_yyscan_t yyscanner)
{
	DeleteStmt* n_d = NULL;
	UpdateStmt* n_u = NULL;
	RangeVar* target_table = NULL;
	RangeVar* larg = NULL;
	RangeVar* rarg = NULL;
	JoinExpr* jexpr = linitial(from_clause);
	SubLink * link;
	List* indirect;
	SelectStmt *selectstmt;
	ResTarget *resTarget;
	/* use queue to go over all join expr and find target table */
	List* queue = list_make1(jexpr);
	ListCell   *queue_item;
	if(IsA(n, DeleteStmt))
		n_d = (DeleteStmt*)n;
	else
		n_u = (UpdateStmt*)n;

	foreach(queue_item, queue)
	{
		jexpr = (JoinExpr*)lfirst(queue_item);
		if(IsA(jexpr->larg, JoinExpr))
		{
			queue = lappend(queue, jexpr->larg);
		}
		else if(IsA(jexpr->larg, RangeVar))
		{
			larg = (RangeVar*)(jexpr->larg);
		}
		if(IsA(jexpr->rarg, JoinExpr))
		{
			queue = lappend(queue, jexpr->rarg);
		}
		else if(IsA(jexpr->rarg, RangeVar))
		{
			rarg = (RangeVar*)(jexpr->rarg);
		}
		if(larg && (TSQL_COMP_REL_NAME(larg,n_d) || TSQL_COMP_REL_NAME(larg,n_u)))
		{
			target_table = larg;
			break;
		}
		if(rarg && (TSQL_COMP_REL_NAME(rarg,n_d) || TSQL_COMP_REL_NAME(rarg,n_u)))
		{
			target_table = rarg;
			break;
		}
		larg = NULL;
		rarg = NULL;
	}
	/* if target table doesn't show in JoinExpr,
	 * it indicates delete/update the whole table
	 * the original statement doesn't need to be changed
	 */
	if(!target_table)
	{
		/*
		 * if we don't end up creating a subquery for JOIN, deal with TOP clause
		 * separately as it might require a subquery.
		 */
		if(n_d)
		{
			n_d -> usingClause = from_clause;
			n_d -> whereClause = tsql_update_delete_stmt_with_top(top_clause,
									relation, where_clause, yyscanner);
			return (Node*)n_d;
		}
		else
		{
			n_u -> fromClause = from_clause;
			n_u -> whereClause = tsql_update_delete_stmt_with_top(top_clause,
									relation, where_clause, yyscanner);
			return (Node*)n_u;
		}
	}
	/* construct select statment->target */
	resTarget = makeNode(ResTarget);
	resTarget->name = NULL;
	resTarget->indirection = NIL;
	indirect = list_make1((Node *) makeString("ctid"));
	if(target_table->alias)
	{
		resTarget->val = makeColumnRef(target_table->alias->aliasname,
							indirect,-1,yyscanner);
	}
	else
	{
		resTarget->val = makeColumnRef(target_table->relname,
							indirect,-1,yyscanner);
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
	link->subselect = (Node*)selectstmt;
	link->subLinkType = ANY_SUBLINK;
	link->subLinkId = 0;
	link->testexpr = (Node*)makeColumnRef(pstrdup("ctid"),
						 NIL, -1, yyscanner);;
	link->operName = NIL;		/* show it's IN not = ANY */
	link->location = -1;
	if(n_d)
	{
		n_d->whereClause = (Node*)link;
		return (Node*)n_d;
	}
	else

	{
		n_u->whereClause = (Node*)link;
		return (Node*)n_u;
	}
}

/*
 * Similar to JOIN, we rewrite TOP clause into a subquery, while attaching the
 * TOP as a LIMIT in the subquery, for UPDATE/DELETE.
 *
 * original query:
 * UPDATE/DELETE <top_clause> <table>
 *
 * rewritten query:
 * UPDATE/DELETE <table> WHERE ctid IN (SELECT ctid FROM <table> <limit_count>)
 */
static Node *
tsql_update_delete_stmt_with_top(Node *top_clause, RangeVar *relation, Node
								 *where_clause, core_yyscan_t yyscanner)
{
	SubLink * link;
	List* indirect;
	SelectStmt *selectstmt;
	ResTarget *resTarget;

	if (top_clause == NULL)
		return where_clause;

	/* construct select statment->target */
	resTarget = makeNode(ResTarget);
	resTarget->name = NULL;
	resTarget->indirection = NIL;
	indirect = list_make1((Node *) makeString("ctid"));
	if(relation->alias)
	{
		resTarget->val = makeColumnRef(relation->alias->aliasname,
							indirect,-1,yyscanner);
	}
	else
	{
		resTarget->val = makeColumnRef(relation->relname,
							indirect,-1,yyscanner);
	}

	/* construct select statement */
	selectstmt = makeNode(SelectStmt);
	selectstmt->targetList = list_make1(resTarget);
	selectstmt->fromClause = list_make1(relation);
	selectstmt->whereClause = where_clause;
	selectstmt->limitCount = top_clause;

	/* construct where_clause(subLink) */
	link = makeNode(SubLink);
	link->subselect = (Node*)selectstmt;
	link->subLinkType = ANY_SUBLINK;
	link->subLinkId = 0;
	link->testexpr = (Node*)makeColumnRef(pstrdup("ctid"),
						 NIL, -1, yyscanner);;
	link->operName = NIL;		/* show it's IN not = ANY */
	link->location = -1;

	return (Node *)link;
}

static Node * 
tsql_insert_output_into_cte_transformation(WithClause *opt_with_clause, RangeVar *insert_target, 
	List *insert_column_list, List *tsql_output_clause, RangeVar *output_target, List *tsql_output_into_target_columns,
	InsertStmt *tsql_output_insert_rest, int select_location)
{
					
	CommonTableExpr *cte = makeNode(CommonTableExpr);
	WithClause *w = makeNode(WithClause);
	SelectStmt *n = makeNode(SelectStmt);
	InsertStmt *i = makeNode(InsertStmt);
	char* internal_ctename = NULL;
	char ctename[NAMEDATALEN];
	ListCell   		*expr;
	char 			col_alias_arr[NAMEDATALEN];
	char 			*col_alias = NULL;
	List			*output_list = NIL, *queue = NIL;
	ListCell 		*lc;
	Node	   		*field1;
	char	   		*qualifier = NULL;
	
	sprintf(ctename, "internal_output_cte##sys_gen##%p", (void*) i);
	internal_ctename = pstrdup(ctename);
	
	// PreparableStmt inside CTE
	i->cols = NIL;
	i->selectStmt = tsql_output_insert_rest->selectStmt;
	i->relation = insert_target;
	i->onConflictClause = NULL;
	i->returningList = get_transformed_output_list(tsql_output_clause);
	i->withClause = NULL;
	i->override = false;

	/* 
	* Make sure we do not pass inserted qualifier to the SELECT target list.
	* Instead, we add an alias for column names qualified by inserted, and remove
	* the inserted qualifier from *. We also make sure only one * is left in
	* the output list inside the CTE.  
	*/
	output_list = copyObject(tsql_output_clause);
	foreach(lc, output_list)
	{
		ResTarget  *res = (ResTarget *) lfirst(lc);
		queue = NIL;
		queue = list_make1(res->val);
 
		foreach(expr, queue)
		{
			Node *node = (Node *) lfirst(expr);
			if (IsA(node, ColumnRef))
			{
				ColumnRef  *cref = (ColumnRef *) node;
				if (list_length(cref->fields) >= 2)
				{
					field1 = (Node *) linitial(cref->fields);
					qualifier = strVal(field1);
				
					if (!strcmp(qualifier, "inserted"))
					{
						if (IsA((Node*) llast(cref->fields), String))
						{
							snprintf(col_alias_arr, NAMEDATALEN, "sys_gen##%pins_%s", (void*) tsql_output_clause, strVal(llast(cref->fields)));
							col_alias = pstrdup(col_alias_arr);
						}
						else
							cref->fields = list_delete_first(cref->fields);
					}
					if (col_alias)
						cref->fields = list_make1(makeString(col_alias));
				}
			}
			else if(IsA(node, A_Expr))
			{
				A_Expr  *a_expr = (A_Expr *) node;
				if (a_expr->lexpr)
					queue = lappend(queue, a_expr->lexpr);
				if (a_expr->rexpr)
					queue = lappend(queue, a_expr->rexpr);
			}
			else if(IsA(node, FuncCall))
			{
				FuncCall *func_call = (FuncCall*) node;
				if (func_call->args)
					queue = list_concat(queue, func_call->args);
			}
		}
	}
 
	// SelectStmt inside outer InsertStmt
	n->limitCount = NULL;
	n->targetList = output_list;
	n->intoClause = NULL;
	n->fromClause = list_make1(makeRangeVar(NULL, internal_ctename, select_location));

	// Outer InsertStmt
	tsql_output_insert_rest->selectStmt = (Node*) n;
	tsql_output_insert_rest->relation = output_target;
	tsql_output_insert_rest->onConflictClause = NULL;
	tsql_output_insert_rest->returningList = NULL;
	if (tsql_output_into_target_columns == NIL)
		tsql_output_insert_rest->cols = insert_column_list;
	else
		tsql_output_insert_rest->cols = tsql_output_into_target_columns;

	// CTE
	cte->ctename = internal_ctename;
	cte->aliascolnames = NULL;
	cte->ctematerialized = CTEMaterializeDefault;
	cte->ctequery = (Node *) i;
	cte->location = 1;

	if(opt_with_clause)
	{
		opt_with_clause->ctes = lappend(opt_with_clause->ctes, (Node*) cte);
		tsql_output_insert_rest->withClause = opt_with_clause; 
	}
	else
	{
		w->ctes = list_make1((Node *) cte);
		w->recursive = false;
		w->location = 1;
		tsql_output_insert_rest->withClause = w;
	}
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
	ListCell 		*lc;
	Node	   		*field1;
	char	   		*qualifier = NULL; 
	List			*output_list = NIL, *queue = NIL; 
	char 			*internal_ctename = NULL;
	char 			ctename[NAMEDATALEN];
	ListCell   		*expr;
	char 			col_alias_arr[NAMEDATALEN];
	char 			*col_alias = NULL;
 
	sprintf(ctename, "internal_output_cte##sys_gen##%p", (void*) i);
	internal_ctename = pstrdup(ctename);
		
	// PreparableStmt inside CTE
	d->relation = relation_expr_opt_alias;
	if (from_clause != NULL && IsA(linitial(from_clause), JoinExpr))
	{
		d = (DeleteStmt*)tsql_update_delete_stmt_with_join(
							(Node*)d, from_clause, where_or_current_clause, opt_top_clause,
							relation_expr_opt_alias, yyscanner);
		output_update_transformation = true;
	}
	else
	{
		d->usingClause = from_clause;
		d->whereClause = tsql_update_delete_stmt_with_top(opt_top_clause,
							relation_expr_opt_alias, where_or_current_clause, yyscanner);
		if (from_clause != NULL && (IsA(linitial(from_clause), RangeSubselect) || IsA(linitial(from_clause), RangeVar)))
			output_update_transformation = true;
	}
	d->returningList = get_transformed_output_list(tsql_output_clause);
	d->withClause = opt_with_clause;
 
	/* 
	* Make sure we do not pass deleted qualifier to the SELECT target list.
	* Instead, we add an alias for column names qualified bydeleted, and remove
	* the deleted qualifier from *.  
	*/
	output_list = copyObject(tsql_output_clause);
	foreach(lc, output_list)
	{
		ResTarget  *res = (ResTarget *) lfirst(lc);
		queue = NIL;
		queue = list_make1(res->val);

		foreach(expr, queue)
		{
			Node *node = (Node *) lfirst(expr);
			if (IsA(node, ColumnRef))
			{
				ColumnRef  *cref = (ColumnRef *) node;
				if (list_length(cref->fields) >= 2)
				{
					field1 = (Node *) linitial(cref->fields);
					qualifier = strVal(field1);

					if (!strcmp(qualifier, "deleted"))
					{
						if (IsA((Node*) llast(cref->fields), String))
						{
							snprintf(col_alias_arr, NAMEDATALEN, "sys_gen##%pdel_%s", (void*) tsql_output_clause, strVal(llast(cref->fields)));
							col_alias = pstrdup(col_alias_arr);
						}
						else
							cref->fields = list_delete_first(cref->fields);
					}
					if (col_alias)
						cref->fields = list_make1(makeString(col_alias));
				}
			}
			else if(IsA(node, A_Expr))
			{
				A_Expr  *a_expr = (A_Expr *) node;
				if (a_expr->lexpr)
					queue = lappend(queue, a_expr->lexpr);
				if (a_expr->rexpr)
					queue = lappend(queue, a_expr->rexpr);
			}
			else if(IsA(node, FuncCall))
			{
				FuncCall *func_call = (FuncCall*) node;
				if (func_call->args)
					queue = list_concat(queue, func_call->args);
			}
		}
	}
	
	// SelectStmt inside outer InsertStmt
	n->limitCount = NULL;
	n->targetList = output_list;
	n->intoClause = NULL;
	n->fromClause = list_make1(makeRangeVar(NULL, internal_ctename, 4));

	// Outer InsertStmt
	i->selectStmt = (Node*) n;
	i->relation = insert_target;
	i->onConflictClause = NULL;
	i->returningList = NULL;
	i->cols = tsql_output_into_target_columns;

	// CTE
	cte->ctename = internal_ctename;
	cte->aliascolnames = NULL;
	cte->ctematerialized = CTEMaterializeDefault;
	cte->ctequery = (Node *) d;
	cte->location = 1;

	if(opt_with_clause)
	{
		opt_with_clause->ctes = lappend(opt_with_clause->ctes, (Node*) cte);
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
	ListCell 	*lc;
	bool 		deleted = false;

	/*
	* Check for deleted qualifier in OUTPUT list. If there is no deleted qualifier,
	* there is no need for parse tree rewrite because PG already supports 
	* returning modified (inserted) values.
	*/
	foreach(lc, tsql_output_clause)
	{
		ResTarget  *res = (ResTarget *) lfirst(lc);
		if (IsA(res->val, ColumnRef))
		{
			ColumnRef  *cref = (ColumnRef *) res->val;			
			if(!strcmp(strVal((Node *) linitial(cref->fields)), "deleted"))
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
	ListCell 		*lc;
	Node	   		*field1;
	char	   		*qualifier = NULL; 
	List			*output_list = NIL, *queue = NIL; 
	char 			*internal_ctename = NULL;
	char 			ctename[NAMEDATALEN];
	ListCell   		*expr;
	char 			col_alias_arr[NAMEDATALEN];
	char 			*col_alias = NULL;
	
	sprintf(ctename, "internal_output_cte##sys_gen##%p", (void*) i);
	internal_ctename = pstrdup(ctename);
		
	// PreparableStmt inside CTE
	u->relation = relation_expr_opt_alias;
	u->targetList = set_clause_list;
	if (from_clause != NULL && IsA(linitial(from_clause), JoinExpr))
	{
		u = (UpdateStmt*)tsql_update_delete_stmt_with_join(
							(Node*)u, from_clause, where_or_current_clause, opt_top_clause, 
							relation_expr_opt_alias, yyscanner);
	}
	else
	{
		u->fromClause = from_clause;
		u->whereClause = where_or_current_clause;
	}
	u->returningList = get_transformed_output_list(tsql_output_clause);
	u->withClause = opt_with_clause;

	tsql_check_update_output_transformation(tsql_output_clause);
	
	/* 
	* Make sure we do not pass deleted or inserted qualifier to the SELECT target list.
	* Instead, we add an alias for column names qualified by inserted/deleted, and remove
	* the inserted/deleted qualifier from *. 
	*/
	output_list = copyObject(tsql_output_clause);
	foreach(lc, output_list)
	{
		ResTarget  *res = (ResTarget *) lfirst(lc);
		queue = NIL;
		queue = list_make1(res->val);

		foreach(expr, queue)
		{
			Node *node = (Node *) lfirst(expr);
			if (IsA(node, ColumnRef))
			{
				ColumnRef  *cref = (ColumnRef *) node;
				if (list_length(cref->fields) >= 2)
				{
					field1 = (Node *) linitial(cref->fields);
					qualifier = strVal(field1);
					
					if(!strcmp(qualifier, "deleted"))
					{
						if (IsA((Node*) llast(cref->fields), String))
						{
							snprintf(col_alias_arr, NAMEDATALEN, "sys_gen##%pdel_%s", (void*) tsql_output_clause, strVal(llast(cref->fields)));
							col_alias = pstrdup(col_alias_arr);
						}
						else
							cref->fields = list_delete_first(cref->fields);
					}
					else if (!strcmp(qualifier, "inserted"))
					{
						if (IsA((Node*) llast(cref->fields), String))
						{
							snprintf(col_alias_arr, NAMEDATALEN, "sys_gen##%pins_%s", (void*) tsql_output_clause, strVal(llast(cref->fields)));
							col_alias = pstrdup(col_alias_arr);
						}
						else
							cref->fields = list_delete_first(cref->fields);
					}
					if (col_alias)
						cref->fields = list_make1(makeString(col_alias));
				}
			}
			else if(IsA(node, A_Expr))
			{
				A_Expr  *a_expr = (A_Expr *) node;
				if (a_expr->lexpr)
					queue = lappend(queue, a_expr->lexpr);
				if (a_expr->rexpr)
					queue = lappend(queue, a_expr->rexpr);
			}
			else if(IsA(node, FuncCall))
			{
				FuncCall *func_call = (FuncCall*) node;
				if (func_call->args)
					queue = list_concat(queue, func_call->args);
			}
		}
	}
	
	// SelectStmt inside outer InsertStmt
	n->limitCount = NULL;
	n->targetList = output_list;
	n->intoClause = NULL;
	n->fromClause = list_make1(makeRangeVar(NULL, internal_ctename, -1));

	// Outer InsertStmt
	i->selectStmt = (Node*) n;
	i->relation = insert_target;
	i->onConflictClause = NULL;
	i->returningList = NULL;
	i->cols = tsql_output_into_target_columns;

	// CTE
	cte->ctename = internal_ctename;
	cte->aliascolnames = NULL;
	cte->ctematerialized = CTEMaterializeDefault;
	cte->ctequery = (Node *) u;
	cte->location = 1;

	if(opt_with_clause)
	{
		opt_with_clause->ctes = lappend(opt_with_clause->ctes, (Node*) cte);
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
	List 		*transformed_returning_list = NIL, *queue = NIL, *output_list = NIL;
	List		*ins_colnames = NIL, *del_colnames = NIL;
	ListCell 	*o_target, *expr;
	char 		col_alias_arr[NAMEDATALEN];
	char 		*col_alias = NULL;
	PLtsql_execstate *estate;
	int 		i = 0;
	bool 		local_variable = false, ins_star = false, del_star = false, is_duplicate = false;
	
	estate = get_current_tsql_estate();

	output_list = copyObject(tsql_output_clause);
	foreach(o_target, output_list)
	{
		ResTarget *res = (ResTarget *) lfirst(o_target);
		queue = NIL;
		queue = list_make1(res->val);

		foreach(expr, queue)
		{
			Node *node = (Node *) lfirst(expr);
			if (IsA(node, ColumnRef))
			{
				ResTarget *target = makeNode(ResTarget);
				ColumnRef  *cref = (ColumnRef *) node;
 
				if(!strcmp(strVal(linitial(cref->fields)), "deleted") && list_length(cref->fields) >= 2)
				{
					if (IsA((Node*) llast(cref->fields), String))
					{
						is_duplicate = returning_list_has_column_name(del_colnames, strVal(llast(cref->fields)));
						if (!is_duplicate)
						{
							snprintf(col_alias_arr, NAMEDATALEN, "sys_gen##%pdel_%s", (void*) tsql_output_clause, strVal(llast(cref->fields)));
							col_alias = pstrdup(col_alias_arr);
							target->name = col_alias;
							del_colnames = lappend(del_colnames, strVal(llast(cref->fields)));
						}
					}
					else if (IsA((Node*) llast(cref->fields), A_Star))
						ins_star = true;
				
				}
				else if(!strcmp(strVal(linitial(cref->fields)), "inserted") && list_length(cref->fields) >= 2)
				{
					if (IsA((Node*) llast(cref->fields), String))
					{
						is_duplicate = returning_list_has_column_name(ins_colnames, strVal(llast(cref->fields)));
						if (!is_duplicate)
						{
							snprintf(col_alias_arr, NAMEDATALEN, "sys_gen##%pins_%s", (void*) tsql_output_clause, strVal(llast(cref->fields)));
							col_alias = pstrdup(col_alias_arr);
							target->name = col_alias;
							ins_colnames = lappend(ins_colnames, strVal(llast(cref->fields)));
						}
					}
					else if (IsA((Node*) llast(cref->fields), A_Star))
						del_star = true;
				}
				else
				{
					local_variable = false;
					if(!strncmp(strVal(linitial(cref->fields)), "@", 1) && estate)
					{
						for (i = 0; i < estate->ndatums; i++)
						{
							PLtsql_datum *d = estate->datums[i];
							if (!strcmp(strVal(linitial(cref->fields)), ((PLtsql_variable*) d)->refname))
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
					target->val = (Node*) cref;
					transformed_returning_list = lappend(transformed_returning_list, target);
				}
			}
			else if(IsA(node, A_Expr))
			{
				A_Expr  *a_expr = (A_Expr *) node;

				if (a_expr->lexpr)
					queue = lappend(queue, a_expr->lexpr);
				if (a_expr->rexpr)
					queue = lappend(queue, a_expr->rexpr);
			}
			else if(IsA(node, FuncCall))
			{
				FuncCall *func_call = (FuncCall*) node;
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
	ListCell *name;
	bool is_duplicate = false;

	if (existing_colnames == NIL)
		return false;

	foreach(name, existing_colnames)
	{
		char *colname = (char*) lfirst(name);
		if (!strcmp(colname, current_colname))
		{
			is_duplicate = true;
			break;
		}
	}
	return is_duplicate;
}