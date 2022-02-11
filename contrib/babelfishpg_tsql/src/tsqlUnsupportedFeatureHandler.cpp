#include <iostream>
#include <strstream>
#include <unordered_map>

#pragma GCC diagnostic ignored "-Wattributes"

#include "antlr4-runtime.h" // antlr4-cpp-runtime
#include "tree/ParseTreeWalker.h" // antlr4-cpp-runtime
#include "tree/ParseTreeProperty.h" // antlr4-cpp-runtime

#include "../antlr/antlr4cpp_generated_src/TSqlLexer/TSqlLexer.h"
#include "../antlr/antlr4cpp_generated_src/TSqlParser/TSqlParser.h"
#include "tsqlIface.hpp"

extern "C" {
#include "pltsql_instr.h"
#include "pltsql.h"
#include "guc.h"
}

extern bool pltsql_allow_antlr_to_unsupported_grammar_for_testing;

/* escape hatches */
typedef struct escape_hatch_t {
	const char *name;
	int *val;
} escape_hatch_t;

#define declare_escape_hatch(name) \
	extern int name; \
	struct escape_hatch_t st_##name = {	#name, &name };

declare_escape_hatch(escape_hatch_storage_options);
declare_escape_hatch(escape_hatch_storage_on_partition);
declare_escape_hatch(escape_hatch_database_misc_options);
declare_escape_hatch(escape_hatch_language_non_english);
declare_escape_hatch(escape_hatch_login_hashed_password);
declare_escape_hatch(escape_hatch_login_old_password);
declare_escape_hatch(escape_hatch_login_password_must_change);
declare_escape_hatch(escape_hatch_login_password_unlock);
declare_escape_hatch(escape_hatch_login_misc_options);
declare_escape_hatch(escape_hatch_compatibility_level);
declare_escape_hatch(escape_hatch_fulltext);
declare_escape_hatch(escape_hatch_schemabinding_function);
declare_escape_hatch(escape_hatch_schemabinding_trigger);
declare_escape_hatch(escape_hatch_schemabinding_procedure);
declare_escape_hatch(escape_hatch_schemabinding_view);
declare_escape_hatch(escape_hatch_index_clustering);
declare_escape_hatch(escape_hatch_index_columnstore);
declare_escape_hatch(escape_hatch_for_replication);
declare_escape_hatch(escape_hatch_rowguidcol_column);
declare_escape_hatch(escape_hatch_nocheck_add_constraint);
declare_escape_hatch(escape_hatch_nocheck_existing_constraint);
declare_escape_hatch(escape_hatch_constraint_name_for_default);
declare_escape_hatch(escape_hatch_table_hints);
declare_escape_hatch(escape_hatch_query_hints);
declare_escape_hatch(escape_hatch_join_hints);
declare_escape_hatch(escape_hatch_session_settings);

extern std::string getFullText(antlr4::ParserRuleContext *context);
extern std::string stripQuoteFromId(TSqlParser::IdContext *context);
extern TSqlParser::Query_specificationContext *get_query_specification(TSqlParser::Select_statementContext *ctx);

extern std::pair<int,int> getLineAndPos(antlr4::ParserRuleContext *ctx);
extern std::pair<int,int> getLineAndPos(antlr4::tree::TerminalNode *node);

using namespace std;
using namespace antlr4;
using namespace tree;

class TsqlUnsupportedFeatureHandlerImpl : public TsqlUnsupportedFeatureHandler
{
public:
		explicit TsqlUnsupportedFeatureHandlerImpl() = default;
		virtual ~TsqlUnsupportedFeatureHandlerImpl() = default;

		bool hasUnsupportedFeature() const override { return count > 0; }
		void setPublishInstr(bool b) override { publish_instr = b; }
		void setThrowError(bool b) override{ throw_error = b; }

protected:
		bool publish_instr = false;
		bool throw_error = false;
		int count = 0; /* record count to skip unnecessary visiting */

		/* handler */
		void handle(PgTsqlInstrMetricType tm_type, antlr4::tree::TerminalNode *node, escape_hatch_t* eh);
		void handle(PgTsqlInstrMetricType tm_type, const char *featureName, escape_hatch_t* eh, std::pair<int,int> line_and_pos);
		void handle(PgTsqlInstrMetricType tm_type, antlr4::tree::TerminalNode *node) { handle(tm_type, node, nullptr); }
		void handle(PgTsqlInstrMetricType tm_type, const char *featureName, std::pair<int,int> line_and_pos) { handle(tm_type, featureName, nullptr, line_and_pos); }

		/* listener interfaces */
		// Batch-level DDLs
		antlrcpp::Any visitCreate_or_alter_function(TSqlParser::Create_or_alter_functionContext *ctx) override;
		antlrcpp::Any visitCreate_or_alter_procedure(TSqlParser::Create_or_alter_procedureContext *ctx) override;
		antlrcpp::Any visitCreate_or_alter_trigger(TSqlParser::Create_or_alter_triggerContext *ctx) override;
		antlrcpp::Any visitCreate_or_alter_view(TSqlParser::Create_or_alter_viewContext *ctx) override;

		antlrcpp::Any visitProcedure_param(TSqlParser::Procedure_paramContext *ctx) override; // common for function/procedure/aggregate

		// DDL
		antlrcpp::Any visitCreate_table(TSqlParser::Create_tableContext *ctx) override;
		antlrcpp::Any visitAlter_table(TSqlParser::Alter_tableContext *ctx) override;
		antlrcpp::Any visitCreate_index(TSqlParser::Create_indexContext *ctx) override;
		antlrcpp::Any visitAlter_index(TSqlParser::Alter_indexContext *ctx) override;
		antlrcpp::Any visitCreate_database(TSqlParser::Create_databaseContext *ctx) override;
		antlrcpp::Any visitAlter_database(TSqlParser::Alter_databaseContext *ctx) override;
		antlrcpp::Any visitCreate_fulltext_index(TSqlParser::Create_fulltext_indexContext *ctx) override;
		antlrcpp::Any visitAlter_fulltext_index(TSqlParser::Alter_fulltext_indexContext *ctx) override;
		antlrcpp::Any visitDrop_fulltext_index(TSqlParser::Drop_fulltext_indexContext *ctx) override;
		antlrcpp::Any visitCreate_type(TSqlParser::Create_typeContext *ctx) override;
		antlrcpp::Any visitCreate_login(TSqlParser::Create_loginContext *ctx) override;
		antlrcpp::Any visitAlter_login(TSqlParser::Alter_loginContext *ctx) override;

		// for unsupported DDLs. we'll manage whitelist
		antlrcpp::Any visitDdl_statement(TSqlParser::Ddl_statementContext *ctx) override;

		// DML
		antlrcpp::Any visitSelect_statement(TSqlParser::Select_statementContext *ctx) override;
		antlrcpp::Any visitInsert_statement(TSqlParser::Insert_statementContext *ctx) override;
		antlrcpp::Any visitUpdate_statement(TSqlParser::Update_statementContext *ctx) override;
		antlrcpp::Any visitDelete_statement(TSqlParser::Delete_statementContext *ctx) override;
		antlrcpp::Any visitMerge_statement(TSqlParser::Merge_statementContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_MERGE, "MERGE", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitBulk_insert_statement(TSqlParser::Bulk_insert_statementContext *ctx) override;

		// CFL
		antlrcpp::Any visitWaitfor_statement(TSqlParser::Waitfor_statementContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_WAIT_FOR, "WAITFOR", getLineAndPos(ctx)); return visitChildren(ctx); }

		// Another
		antlrcpp::Any visitSet_statement(TSqlParser::Set_statementContext *ctx) override;
		antlrcpp::Any visitCursor_statement(TSqlParser::Cursor_statementContext *ctx) override;
		antlrcpp::Any visitTransaction_statement(TSqlParser::Transaction_statementContext *ctx) override;
		antlrcpp::Any visitDeclare_xmlnamespaces_statement(TSqlParser::Declare_xmlnamespaces_statementContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_WITH_XMLNAMESPACES, "WITH XMLNAMESPACES", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitConversation_statement(TSqlParser::Conversation_statementContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_CREATE_CONVERSATION_STMT, "conversation statements", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitCreate_contract(TSqlParser::Create_contractContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_CREATE_CONTRACT, "CREATE CONTRACT", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitCreate_queue(TSqlParser::Create_queueContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_CREATE_QUEUE, "CREATE QUEUE", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitAlter_queue(TSqlParser::Alter_queueContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_ALTER_QUEUE, "ALTER QUEUE", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitKill_statement(TSqlParser::Kill_statementContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_KILL, "KILL", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitMessage_statement(TSqlParser::Message_statementContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_CREATE_MESSAGE, "CREATE MESSAGE", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitSecurity_statement(TSqlParser::Security_statementContext *ctx) override;
		antlrcpp::Any visitSetuser_statement(TSqlParser::Setuser_statementContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_SET_USER, "SET USER", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitReconfigure_statement(TSqlParser::Reconfigure_statementContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_RECONFIGURE, "RECONFIGURE", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitShutdown_statement(TSqlParser::Shutdown_statementContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_SHUTDOWN, "SHUTDOWN", getLineAndPos(ctx)); return visitChildren(ctx); }

		antlrcpp::Any visitDbcc_statement(TSqlParser::Dbcc_statementContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_DBCC, "DBCC", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitBackup_statement(TSqlParser::Backup_statementContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_BACKUP, "BACKUP", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitRestore_statement(TSqlParser::Restore_statementContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_RESTORE, "RESTORE", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitCheckpoint_statement(TSqlParser::Checkpoint_statementContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_CHECKPOINT, "CHECKPOINT", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitReadtext_statement(TSqlParser::Readtext_statementContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_READTEXT, "READTEXT", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitWritetext_statement(TSqlParser::Writetext_statementContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_WRITETEXT, "WRITETEXT", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitUpdatetext_statement(TSqlParser::Updatetext_statementContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_UPDATETEXT, "UPDATETEXT", getLineAndPos(ctx)); return visitChildren(ctx); }

		// common clauses used in CREATE/ALTER TABLE/INDEX
		antlrcpp::Any visitColumn_constraint(TSqlParser::Column_constraintContext *ctx) override;
		antlrcpp::Any visitColumn_inline_index(TSqlParser::Column_inline_indexContext *ctx) override;
		antlrcpp::Any visitSpecial_column_option(TSqlParser::Special_column_optionContext *ctx) override;
		antlrcpp::Any visitColumn_definition(TSqlParser::Column_definitionContext *ctx) override;
		antlrcpp::Any visitIndex_option(TSqlParser::Index_optionContext *ctx) override;
		antlrcpp::Any visitTable_constraint(TSqlParser::Table_constraintContext *ctx) override;
		antlrcpp::Any visitColumn_def_table_constraint(TSqlParser::Column_def_table_constraintContext *ctx) override;
		antlrcpp::Any visitTable_name(TSqlParser::Table_nameContext *ctx) override;

		// common clause in SELECT (and some DML)
		antlrcpp::Any visitTable_source_item(TSqlParser::Table_source_itemContext *ctx) override;
		antlrcpp::Any visitFor_clause(TSqlParser::For_clauseContext *ctx) override; // FOR XML, ...
		antlrcpp::Any visitWith_table_hints(TSqlParser::With_table_hintsContext *ctx) override;
		antlrcpp::Any visitOption_clause(TSqlParser::Option_clauseContext *ctx) override; // query hints
		antlrcpp::Any visitJoin_hint(TSqlParser::Join_hintContext *ctx) override;
		antlrcpp::Any visitGroup_by_item(TSqlParser::Group_by_itemContext *ctx) override;

		// functions and expression
		antlrcpp::Any visitAggregate_windowed_function(TSqlParser::Aggregate_windowed_functionContext *ctx) override;
		antlrcpp::Any visitRowset_function(TSqlParser::Rowset_functionContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_ROWSET_FUNCTION, "rowset function", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitTrigger_column_updated(TSqlParser::Trigger_column_updatedContext *ctx) override; // UPDATE() in trigger
		antlrcpp::Any visitFREE_TEXT(TSqlParser::FREE_TEXTContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_FREETEXT, "FREETEXT", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitNextvaluefor(TSqlParser::NextvalueforContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_NEXT_VALUE_FOR, "NEXT VALUE FOR", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitOdbcscalar(TSqlParser::OdbcscalarContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_ODBC_SCALAR_FUNCTION, "ODBC scalar functions", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitPartition_function_call(TSqlParser::Partition_function_callContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_PARTITION_FUNCTION, "partition function", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitExpression(TSqlParser::ExpressionContext *ctx) override;
		antlrcpp::Any visitExecute_parameter(TSqlParser::Execute_parameterContext *ctx) override;

		antlrcpp::Any visitFunc_proc_name_schema(TSqlParser::Func_proc_name_schemaContext *ctx) override;
		antlrcpp::Any visitFunc_proc_name_database_schema(TSqlParser::Func_proc_name_database_schemaContext *ctx) override;
		antlrcpp::Any visitFunc_proc_name_server_database_schema(TSqlParser::Func_proc_name_server_database_schemaContext *ctx) override;
		antlrcpp::Any visitFull_object_name(TSqlParser::Full_object_nameContext *ctx) override;

		// methods call (XML, hierachy, spatial)
		antlrcpp::Any visitXml_nodes_method(TSqlParser::Xml_nodes_methodContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_XML_NODES, "XML NODES", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitXml_value_method(TSqlParser::Xml_value_methodContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_XML_VALUE, "XML VALUE", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitXml_query_method(TSqlParser::Xml_query_methodContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_XML_QUERY, "XML QUERY", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitXml_exist_method(TSqlParser::Xml_exist_methodContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_XML_EXIST, "XML EXIST", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitXml_modify_method(TSqlParser::Xml_modify_methodContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_XML_MODIFY, "XML MODIFY", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitXml_value_call(TSqlParser::Xml_value_callContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_XML_VALUE, "XML VALUE", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitXml_query_call(TSqlParser::Xml_query_callContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_XML_QUERY, "XML QUERY", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitXml_exist_call(TSqlParser::Xml_exist_callContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_XML_EXIST, "XML EXIST", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitXml_modify_call(TSqlParser::Xml_modify_callContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_XML_MODIFY, "XML MODIFY", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitHierarchyid_methods(TSqlParser::Hierarchyid_methodsContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_HIERARCHYID_METHOD, "HIERARCHYID methods", getLineAndPos(ctx)); return visitChildren(ctx); }
		antlrcpp::Any visitSpatial_methods(TSqlParser::Spatial_methodsContext *ctx) override { handle(INSTR_UNSUPPORTED_TSQL_SPATIAL_METHOD, "spatial methods", getLineAndPos(ctx)); return visitChildren(ctx); }

		// built-in functions
		antlrcpp::Any visitBif_cast_parse(TSqlParser::Bif_cast_parseContext *ctx) override;
		antlrcpp::Any visitBif_convert(TSqlParser::Bif_convertContext *ctx) override;
		antlrcpp::Any visitSql_option(TSqlParser::Sql_optionContext *ctx) override;

		// datatype
		antlrcpp::Any visitData_type(TSqlParser::Data_typeContext *ctx) override;

		antlrcpp::Any visitSnapshot_option(TSqlParser::Snapshot_optionContext *ctx) override;
		antlrcpp::Any visitKeyword(TSqlParser::KeywordContext *ctx) override;

	/* helpers */
	void handle_storage_partition(TSqlParser::Storage_partition_clauseContext *ctx);
	void handle_for_replication(TSqlParser::For_replicationContext *ctx);

	bool isDefaultLanguage(TSqlParser::IdContext *ctx);
	void checkUnsupportedSystemProcedure(TSqlParser::IdContext *ctx);
};

std::unique_ptr<TsqlUnsupportedFeatureHandler> TsqlUnsupportedFeatureHandler::create()
{
	return std::make_unique<TsqlUnsupportedFeatureHandlerImpl>();
}

void TsqlUnsupportedFeatureHandlerImpl::handle(PgTsqlInstrMetricType tm_type, antlr4::tree::TerminalNode *node, escape_hatch_t* eh)
{
	handle(tm_type, (node ? node->getText().c_str() : ""), eh, getLineAndPos(node));
}

void TsqlUnsupportedFeatureHandlerImpl::handle(PgTsqlInstrMetricType tm_type, const char *featureName, escape_hatch_t* eh, std::pair<int,int> line_and_pos)
{
	++count;

	if (publish_instr)
	{
		TSQLInstrumentation(tm_type);
	}

	if (throw_error && (!eh || (*eh->val) != EH_IGNORE)) // if escape hatch is given, check the current value is 'ignore'
	{
		if (eh)
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, format_errmsg("\'%s\' is not currently supported in Babelfish. please use babelfishpg_tsql.%s to ignore", featureName, eh->name), line_and_pos);
		else
			throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, format_errmsg("\'%s\' is not currently supported in Babelfish", featureName), line_and_pos);
	}
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitCreate_or_alter_function(TSqlParser::Create_or_alter_functionContext *ctx)
{
	if (ctx->ALTER())
		handle(INSTR_UNSUPPORTED_TSQL_ALTER_FUNCTION, "ALTER FUNCTION", getLineAndPos(ctx->ALTER()));

	std::vector<TSqlParser::Function_optionContext *> options;
	if (ctx->func_body_returns_select())
		options = ctx->func_body_returns_select()->function_option();
	else if (ctx->func_body_returns_table())
		options = ctx->func_body_returns_table()->function_option();
	else if (ctx->func_body_returns_scalar())
		options = ctx->func_body_returns_scalar()->function_option();
	else if (ctx->func_body_returns_table_clr())
		options = ctx->func_body_returns_table_clr()->function_option();

	/* escape hatch of SCHEMABINDING option*/
	if (escape_hatch_schemabinding_function != EH_IGNORE)
	{
		bool found = false;
		for (auto option : options)
			if (option->SCHEMABINDING())
				found = true;

		if (!found)
		{
			/* SCHEMABINDING is different from other case because it should throw an error when it is *NOT* given. handle an error manually */
			if (throw_error)
				throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, format_errmsg("\'SCHEMABINDING\' option should be given to create a %s in Babelfish", "function"), getLineAndPos(ctx));
			else
				++count;
		}
	}

	for (auto option : options)
	{
		if (option->ENCRYPTION())
			handle(INSTR_UNSUPPORTED_TSQL_ALTER_FUNCTION_ENCRYPTION_OPTION, option->ENCRYPTION());
		else if (option->NATIVE_COMPILATION())
			handle(INSTR_UNSUPPORTED_TSQL_ALTER_FUNCTION_NATIVE_COMPILATION_OPTION, option->NATIVE_COMPILATION());
		else if (option->execute_as_clause())
			handle(INSTR_UNSUPPORTED_TSQL_EXECUTE_AS_STMT, "EXECUTE AS", getLineAndPos(option->execute_as_clause()));
	}

	if (ctx->func_body_returns_scalar() && ctx->func_body_returns_scalar()->external_name())
		handle(INSTR_UNSUPPORTED_TSQL_ALTER_FUNCTION_EXTERNAL_NAME_OPTION, "EXTERNAL NAME", getLineAndPos(ctx->func_body_returns_scalar()->external_name()));
	if (ctx->func_body_returns_table_clr() && ctx->func_body_returns_table_clr()->external_name())
		handle(INSTR_UNSUPPORTED_TSQL_ALTER_FUNCTION_EXTERNAL_NAME_OPTION, "EXTERNAL NAME", getLineAndPos(ctx->func_body_returns_table_clr()->external_name()));

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitCreate_or_alter_procedure(TSqlParser::Create_or_alter_procedureContext *ctx)
{
	if (ctx->ALTER())
		handle(INSTR_UNSUPPORTED_TSQL_ALTER_PROCEDURE, "ALTER PROCEDURE", getLineAndPos(ctx->ALTER()));

	/* escape hatch of SCHEMABINDING option*/
	if (escape_hatch_schemabinding_procedure != EH_IGNORE)
	{
		bool found = false;
		for (auto option : ctx->procedure_option())
			if (option->SCHEMABINDING())
				found = true;

		if (!found)
		{
			/* SCHEMABINDING is different from other case because it should throw an error when it is *NOT* given. handle an error manually */
			if (throw_error)
				throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, format_errmsg("\'SCHEMABINDING\' option should be given to create a %s in Babelfish", "procedure"), getLineAndPos(ctx));
			else
				++count;
		}
	}

	if (ctx->for_replication())
		handle_for_replication(ctx->for_replication());

	for (auto option : ctx->procedure_option())
	{
		if (option->ENCRYPTION())
			handle(INSTR_UNSUPPORTED_TSQL_ALTER_PROCEDURE_ENCRYPTION_OPTION, option->ENCRYPTION());
		else if (option->NATIVE_COMPILATION())
			handle(INSTR_UNSUPPORTED_TSQL_ALTER_PROCEDURE_NATIVE_COMPILATION_OPTION, option->NATIVE_COMPILATION());
		else if (option->RECOMPILE())
			handle(INSTR_UNSUPPORTED_TSQL_ALTER_PROCEDURE_RECOMPILE_OPTION, option->RECOMPILE());
		else if (option->execute_as_clause())
			handle(INSTR_UNSUPPORTED_TSQL_EXECUTE_AS_STMT, "EXECUTE AS", getLineAndPos(option->execute_as_clause()));
	}

	if (ctx->atomic_proc_body())
		handle(INSTR_UNSUPPORTED_TSQL_ALTER_PROCEDURE_ATOMIC_WITH_OPTION, "ATOMIC WITH", getLineAndPos(ctx->atomic_proc_body()));

	if (ctx->external_name())
		handle(INSTR_UNSUPPORTED_TSQL_ALTER_PROCEDURE_EXTERNAL_NAME_OPTION, "EXTERNAL NAME", getLineAndPos(ctx->external_name()));

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitCreate_or_alter_trigger(TSqlParser::Create_or_alter_triggerContext *ctx)
{
	if (ctx->create_or_alter_ddl_trigger())
		handle(INSTR_UNSUPPORTED_TSQL_DDL_TRIGGER, "DDL trigger", getLineAndPos(ctx->create_or_alter_ddl_trigger()));

	/* escape hatch of SCHEMABINDING option*/
	if (escape_hatch_schemabinding_trigger != EH_IGNORE)
	{
		bool found = false;
		if (ctx->create_or_alter_dml_trigger())
		{
			for (auto option : ctx->create_or_alter_dml_trigger()->trigger_option())
				if (option->SCHEMABINDING())
					found = true;
		}
		else if (ctx->create_or_alter_ddl_trigger())
		{
			for (auto option : ctx->create_or_alter_ddl_trigger()->trigger_option())
				if (option->SCHEMABINDING())
					found = true;
		}

		if (!found)
		{
			/* SCHEMABINDING is different from other case because it should throw an error when it is *NOT* given. handle an error manually */
			if (throw_error)
				throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, format_errmsg("\'SCHEMABINDING\' option should be given to create a %s in Babelfish", "trigger"), getLineAndPos(ctx));
			else
				++count;
		}
	}

	if (ctx->create_or_alter_dml_trigger()) /* DML trigger */
	{
		auto dctx = ctx->create_or_alter_dml_trigger();

		if (dctx->ALTER())
			handle(INSTR_UNSUPPORTED_TSQL_DML_ALTER_TRIGGER, "ALTER TRIGGER", getLineAndPos(dctx->ALTER()));

		if (dctx->INSTEAD())
			handle(INSTR_UNSUPPORTED_TSQL_DML_INSTEAD_OF_TRIGGER, "Instead of Trigger", getLineAndPos(dctx->INSTEAD()));

		if (dctx->APPEND()) // WITH APPEND
			handle(INSTR_UNSUPPORTED_TSQL_DML_WITH_APPEND_TRIGGER, "WITH APPEND", getLineAndPos(dctx->APPEND()));

		if (dctx->for_replication())
			handle_for_replication(dctx->for_replication());

		for (auto option : dctx->trigger_option())
		{
			if (option->ENCRYPTION())
				handle(INSTR_UNSUPPORTED_TSQL_DML_TRIGGER_ENCRYPTION_OPTION, option->ENCRYPTION());
			else if (option->NATIVE_COMPILATION())
				handle(INSTR_UNSUPPORTED_TSQL_DML_TRIGGER_NATIVE_COMPILATION_OPTION, option->NATIVE_COMPILATION());
		}

		if (dctx->external_name())
			handle(INSTR_UNSUPPORTED_TSQL_DML_TRIGGER_EXTERNAL_NAME_OPTION, "EXERNAL NAME", getLineAndPos(dctx->external_name()));
	}
	else /* DDL trigger */
	{
		auto dctx = ctx->create_or_alter_ddl_trigger();

		for (auto option : dctx->trigger_option())
		{
			if (option->ENCRYPTION())
				handle(INSTR_UNSUPPORTED_TSQL_DDL_TRIGGER_ENCRYPTION_OPTION, option->ENCRYPTION());
			else if (option->NATIVE_COMPILATION())
				handle(INSTR_UNSUPPORTED_TSQL_DDL_TRIGGER_NATIVE_COMPILATION_OPTION, option->NATIVE_COMPILATION());
		}

		if (dctx->external_name())
			handle(INSTR_UNSUPPORTED_TSQL_DDL_TRIGGER_EXTERNAL_NAME_OPTION, "EXERNAL NAME", getLineAndPos(dctx->external_name()));
	}

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitCreate_or_alter_view(TSqlParser::Create_or_alter_viewContext *ctx)
{
	if (ctx->ALTER())
		handle(INSTR_UNSUPPORTED_TSQL_ALTER_VIEW, "ALTER VIEW", getLineAndPos(ctx->ALTER()));

	/* escape hatch of SCHEMABINDING option*/
	if (escape_hatch_schemabinding_view != EH_IGNORE)
	{
		bool found = false;
		for (auto option : ctx->view_attribute())
			if (option->SCHEMABINDING())
				found = true;

		if (!found)
		{
			/* SCHEMABINDING is different from other case because it should throw an error when it is *NOT* given. handle an error manually */
			if (throw_error)
				throw PGErrorWrapperException(ERROR, ERRCODE_FEATURE_NOT_SUPPORTED, format_errmsg("\'SCHEMABINDING\' option should be given to create a %s in Babelfish", "view"), getLineAndPos(ctx));
			else
				++count;
		}
	}

	for (auto option : ctx->view_attribute())
	{
		if (option->ENCRYPTION())
			handle(INSTR_UNSUPPORTED_TSQL_ALTER_VIEW_ENCRYPTION_OPTION, option->ENCRYPTION());
		else if (option->VIEW_METADATA())
			handle(INSTR_UNSUPPORTED_TSQL_ALTER_VIEW_VIEW_METADATA_OPTION, option->VIEW_METADATA());
	}

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitProcedure_param(TSqlParser::Procedure_paramContext *ctx)
{
	return visitChildren(ctx);
}

void TsqlUnsupportedFeatureHandlerImpl::handle_storage_partition(TSqlParser::Storage_partition_clauseContext *ctx)
{
	if (!ctx)
		return;

	if (ctx->id().size() < 2) // filegroup
		handle(INSTR_UNSUPPORTED_TSQL_FILEGROUP, "filegroup", &st_escape_hatch_storage_options, getLineAndPos(ctx));
	else if (ctx->id().size() == 2) // partitioning
		handle(INSTR_UNSUPPORTED_TSQL_PARTITION_SCHEME, "partition scheme", &st_escape_hatch_storage_on_partition, getLineAndPos(ctx));
}

void TsqlUnsupportedFeatureHandlerImpl::handle_for_replication(TSqlParser::For_replicationContext *ctx)
{
	if (!ctx)
		return;

	if (ctx->NOT())
		handle(INSTR_UNSUPPORTED_TSQL_NOT_FOR_REPLICATION, "NOT FOR REPLICATION", &st_escape_hatch_for_replication, getLineAndPos(ctx));
	else
		handle(INSTR_UNSUPPORTED_TSQL_FOR_REPLICATION, "FOR REPLICATION", &st_escape_hatch_for_replication, getLineAndPos(ctx));
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitColumn_constraint(TSqlParser::Column_constraintContext *ctx)
{
	if (ctx->clustered() && ctx->clustered()->CLUSTERED())
		handle(INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_CLUSTERED, ctx->clustered()->CLUSTERED(), &st_escape_hatch_index_clustering);

	if (ctx->for_replication())
		handle_for_replication(ctx->for_replication());

	// unsupported generally
	if (ctx->VALUES())
		handle(INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_VALUES, ctx->VALUES());
	if (ctx->CONNECTION())
		handle(INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_CONNECTION, ctx->CONNECTION());

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitColumn_inline_index(TSqlParser::Column_inline_indexContext *ctx)
{
	if (ctx->ON())
		handle_storage_partition(ctx->storage_partition_clause()[0]);

	if (ctx->FILESTREAM_ON())
	{
		size_t idx = ctx->ON() ? 1 : 0; // if ON() exists, the second storage_partition_clause belongs to filestream
		handle_storage_partition(ctx->storage_partition_clause()[idx]);
	}

	if (ctx->CLUSTERED())
		handle(INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_CLUSTERED, ctx->CLUSTERED(), &st_escape_hatch_index_clustering);

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitSpecial_column_option(TSqlParser::Special_column_optionContext *ctx)
{
	if (ctx->for_replication())
		handle_for_replication(ctx->for_replication());

	if (ctx->SPARSE())
		handle(INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_SPARSE, ctx->SPARSE(), &st_escape_hatch_storage_options);
	if (ctx->FILESTREAM())
		handle(INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_FILESTREAM, ctx->FILESTREAM(), &st_escape_hatch_storage_options);
	if (ctx->ROWGUIDCOL())
		handle(INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_ROWGUIDCOL, ctx->ROWGUIDCOL(), &st_escape_hatch_rowguidcol_column);

	// unsupported generally
	if (ctx->HIDDEN_RENAMED())
		handle(INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_HIDDEN_RENAMED, ctx->HIDDEN_RENAMED());
	if (ctx->PERSISTED())
		handle(INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_PERSISTED, ctx->PERSISTED());
	if (ctx->MASKED())
		handle(INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_MASKED, ctx->MASKED());

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitColumn_definition(TSqlParser::Column_definitionContext *ctx)
{
	// ctx->column_inline_index() will be handled by visitColumn_inline_index(). do nothing here.

	// ctx->column_constraint() will be handled by visitColumn_constraint(). do nothing here.

	// ctx->special_column_option() will be handled by visitSpecial_column_option(). do nothing here.

	if (ctx->for_replication())
		handle_for_replication(ctx->for_replication());

	if (ctx->ROWGUIDCOL())
		handle(INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_ROWGUIDCOL, ctx->ROWGUIDCOL(), &st_escape_hatch_rowguidcol_column);

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitIndex_option(TSqlParser::Index_optionContext *ctx)
{
	if (!ctx->id().empty())
	{
		std::string id_str = getFullText(ctx->id()[0]);

		if (pg_strcasecmp(id_str.c_str(), "pad_index") == 0)
			handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_MISC, "PAD_INDEX", &st_escape_hatch_storage_options, getLineAndPos(ctx->id()[0]));
		else if (pg_strcasecmp(id_str.c_str(), "fillfactor") == 0)
			handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_FILLFACTOR, "FILLFACTOR", &st_escape_hatch_storage_options, getLineAndPos(ctx->id()[0]));
		else if (pg_strcasecmp(id_str.c_str(), "sort_in_tempdb") == 0)
			handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_MISC, "SORT_IN_TEMPDB", getLineAndPos(ctx->id()[0])); /* seems like it will affect functionality. do not use escape hatch */
		else if (pg_strcasecmp(id_str.c_str(), "ignore_dup_key") == 0)
			handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_MISC, "IGNORE_DUP_KEY", &st_escape_hatch_storage_options, getLineAndPos(ctx->id()[0]));
		else if (pg_strcasecmp(id_str.c_str(), "statistics_norecompute") == 0)
			handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_MISC, "STATISTICS_NORECOMPUTE", &st_escape_hatch_storage_options, getLineAndPos(ctx->id()[0]));
		else if (pg_strcasecmp(id_str.c_str(), "statistics_incremental") == 0)
			handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_MISC, "STATISTICS_INCREMENTAL", &st_escape_hatch_storage_options, getLineAndPos(ctx->id()[0]));
		else if (pg_strcasecmp(id_str.c_str(), "drop_existing") == 0)
			handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_MISC, "DROP_EXISTING", getLineAndPos(ctx->id()[0])); /* seems like it will affect functionality. do not use escape hatch */
		else if (pg_strcasecmp(id_str.c_str(), "online") == 0)
			handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_MISC, "ONLINE", getLineAndPos(ctx->id()[0])); /* seems like it will affect functionality. do not use escape hatch */
		else if (pg_strcasecmp(id_str.c_str(), "resumable") == 0)
			handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_MISC, "RESUMABLE", getLineAndPos(ctx->id()[0])); /* online index option */
		else if (pg_strcasecmp(id_str.c_str(), "max_duration") == 0)
			handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_MISC, "MAX_DURATION", getLineAndPos(ctx->id()[0])); /* online index option */
		else if (pg_strcasecmp(id_str.c_str(), "allow_row_locks") == 0)
			handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_MISC, "ALLOW_ROW_LOCKS", &st_escape_hatch_storage_options, getLineAndPos(ctx->id()[0]));
		else if (pg_strcasecmp(id_str.c_str(), "allow_page_locks") == 0)
			handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_MISC, "ALLOW_PAGE_LOCKS", &st_escape_hatch_storage_options, getLineAndPos(ctx->id()[0]));
		else if (pg_strcasecmp(id_str.c_str(), "optimize_for_sequential_key") == 0)
			handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_MISC, "OPTIMIZE_FOR_SEQUENTIAL_KEY", &st_escape_hatch_storage_options, getLineAndPos(ctx->id()[0]));
		else if (pg_strcasecmp(id_str.c_str(), "maxdop") == 0)
			handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_MISC, "MAXDOP", &st_escape_hatch_storage_options, getLineAndPos(ctx->id()[0]));
		else if (pg_strcasecmp(id_str.c_str(), "data_compression") == 0)
			handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_MISC, "DATA_COMPRESSION", &st_escape_hatch_storage_options, getLineAndPos(ctx->id()[0]));
		else
		{
			if (throw_error)
				throw PGErrorWrapperException(ERROR, ERRCODE_SYNTAX_ERROR, format_errmsg("unknown index option: %s", id_str.c_str()), getLineAndPos(ctx->id()[0]));
		}
	}

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitTable_constraint(TSqlParser::Table_constraintContext *ctx)
{
	if (ctx->clustered() && ctx->clustered()->CLUSTERED())
		handle(INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_CLUSTERED, ctx->clustered()->CLUSTERED(), &st_escape_hatch_index_clustering);

	for (auto frctx : ctx->for_replication())
		handle_for_replication(frctx);

	// please note that, in 'ingore' mode, we will not rewrite a query in ANTLR. The corresponding logic is implemented in backend parser.
	if (ctx->DEFAULT())
		handle(INSTR_UNSUPPORTED_TSQL_CONSTRAINT_DEFAULT, "CONSTRAINT DEFAULT", &st_escape_hatch_constraint_name_for_default, getLineAndPos(ctx->DEFAULT()));

	// ctx->with_index_options() will be handled by visitIndex_option(). do nothing here.

	if (ctx->storage_partition_clause())
		handle_storage_partition(ctx->storage_partition_clause());

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitColumn_def_table_constraint(TSqlParser::Column_def_table_constraintContext *ctx)
{
	// ctx->column_definition() will be handled by visitColumn_definition(). do nothing here.
	// ctx->table_constraint() will he handled by visitTable_constraint(). do nothing here.

	if (ctx->period_for_system_time())
		handle(INSTR_UNSUPPORTED_TSQL_PERIOD_FOR_SYSTEM_TIME, "PERIOD FOR SYSTEM_TIME", getLineAndPos(ctx->period_for_system_time()));
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitTable_name(TSqlParser::Table_nameContext *ctx)
{
	std::string val = stripQuoteFromId(ctx->id().back());
	if ((pg_strncasecmp("##", val.c_str(), 2) == 0))
		handle(INSTR_UNSUPPORTED_TSQL_GLOBAL_TEMPORARY_TABLE, "GLOBAL TEMPORARY TABLE", getLineAndPos(ctx));

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitCreate_table(TSqlParser::Create_tableContext *ctx)
{
	// ctx->column_def_table_constraints() will be handled by visitColumn_def_table_constraint. do nothing here.

	for (auto cctx : ctx->create_table_options())
	{
		if (cctx->ON() || cctx->TEXTIMAGE_ON() || cctx->FILESTREAM_ON())
			handle_storage_partition(cctx->storage_partition_clause());
	}

	// ctx->column_definition() will be handled by visitColumn_definition(). do nothing here.

	for (auto ictx : ctx->table_indices())
	{
		if (ictx->ON())
			handle_storage_partition(ictx->storage_partition_clause());

		if (ictx->CLUSTERED())
			handle(INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_CLUSTERED, ictx->CLUSTERED(), &st_escape_hatch_index_clustering);
	}

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitAlter_table(TSqlParser::Alter_tableContext *ctx)
{
	// ctx->column_def_table_constraints() will be handled by visitColumn_def_table_constraint. do nothing here.

	// ctx->column_definition() will be handled by visitColumn_definition(). do nothing here.

	// ctx->special_column_option() will be handled by visitSpecial_column_option(). do nothing here.

	if (ctx->FILESTREAM_ON())
		handle_storage_partition(ctx->storage_partition_clause());

	if (ctx->COLUMN()) // ALTER TABLE ... ALTER COLUMN
	{
		Assert(ctx->column_definition());
		auto cdctx = ctx->column_definition();
		if (!cdctx->COLLATE().empty())
			handle(INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_ALTER_COLUMN_COLLATE, "COLLATE in ALTER TABLE ALTER COLUMN", getLineAndPos(cdctx));
		if (!cdctx->null_notnull().empty())
		{
			if (cdctx->null_notnull()[0]->NOT())
				handle(INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_ALTER_COLUMN_NOT_NULL, "NOT NULL in ALTER TABLE ALTER COLUMN", getLineAndPos(cdctx));
			else
				handle(INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_ALTER_COLUMN_NULL, "NULL in ALTER TABLE ALTER COLUMN", getLineAndPos(cdctx));
		}
	}

	if (ctx->ADD() && ctx->WITH())
		handle(INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_CONSTRAINT_NO_CHECK_ADD, "ALTER TABLE WITH [NO]CHECK ADD", &st_escape_hatch_nocheck_add_constraint, getLineAndPos(ctx->ADD()));

	if (ctx->CONSTRAINT())
		handle(INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_CONSTRAINT_NO_CHECK, "ALTER TABLE [NO]CHECK", &st_escape_hatch_nocheck_existing_constraint, getLineAndPos(ctx->CONSTRAINT()));

	// unsupported generally
	if (ctx->CHANGE_TRACKING())
		handle(INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_CHANGE_TRACKING_OPTION, ctx->CHANGE_TRACKING());
	if (ctx->SWITCH())
		handle(INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_SWITCH_OPTION, ctx->SWITCH());
	if (ctx->SYSTEM_VERSIONING())
		handle(INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_SYSTEM_VERSIONING_OPTION, ctx->SYSTEM_VERSIONING());
	if (ctx->LOCK_ESCALATION())
		handle(INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_LOCK_ESCALATION_OPTION, ctx->LOCK_ESCALATION());
	if (ctx->REBUILD())
		handle(INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_REBUILD_OPTION, ctx->REBUILD());

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitCreate_index(TSqlParser::Create_indexContext *ctx)
{
	handle_storage_partition(ctx->storage_partition_clause());

	if (ctx->clustered() && ctx->clustered()->CLUSTERED())
		handle(INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_CLUSTERED, ctx->clustered()->CLUSTERED(), &st_escape_hatch_index_clustering);

	if (ctx->COLUMNSTORE())
		handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_COLUMNSTORE, ctx->COLUMNSTORE(), &st_escape_hatch_index_columnstore);

	if (ctx->with_index_options() && ctx->with_index_options()->index_option_list())
	{
		for (auto option : ctx->with_index_options()->index_option_list()->index_option())
		{
			if (!option->EQUAL()) // backend only supports index option formed like <storage_parameter>=<value>
			{
				std::string option_name = (!option->id().empty() ? getFullText(option->id()[0]) : std::string("unknown index option"));
				handle(INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_UNKNOWN, option_name.c_str(), getLineAndPos(option));
			}
		}
	}

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitAlter_index(TSqlParser::Alter_indexContext *ctx)
{
	handle(INSTR_UNSUPPORTED_TSQL_ALTER_INDEX, "ALTER INDEX", getLineAndPos(ctx));
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitCreate_database(TSqlParser::Create_databaseContext *ctx)
{
	if (ctx->CONTAINMENT())
		handle(INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_CONTAINMENT, ctx->CONTAINMENT(), &st_escape_hatch_database_misc_options);

	if (!ctx->ON().empty())
		handle(INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_ON, "CREATE DATABASE ON <database-file-spec>", getLineAndPos(ctx->ON()[0]));

	if (ctx->COLLATE())
		handle(INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_COLLATE, ctx->COLLATE());

	if (ctx->WITH())
	{
		for (auto cdoctx : ctx->create_database_option())
		{
			if (cdoctx->FILESTREAM())
				handle(INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_FILESTREAM, cdoctx->FILESTREAM(), &st_escape_hatch_storage_options);
			if (cdoctx->DEFAULT_LANGUAGE())
			{
				if (cdoctx->id())
				{
					if (!isDefaultLanguage(cdoctx->id()))
						handle(INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_DEFAULT_LANGUAGE, ::getFullText(cdoctx->id()).c_str(), &st_escape_hatch_language_non_english, getLineAndPos(cdoctx));
				}
				else // lcid
					handle(INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_DEFAULT_LANGUAGE, "DEFAULT LANGUAGE with lcid", getLineAndPos(cdoctx));
			}
			if (cdoctx->DEFAULT_FULLTEXT_LANGUAGE())
				handle(INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_DEFAULT_FULLTEXT_LANGUAGE, cdoctx->DEFAULT_FULLTEXT_LANGUAGE(), &st_escape_hatch_fulltext);
			if (cdoctx->NESTED_TRIGGERS())
				handle(INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_NESTED_TRIGGERS, cdoctx->NESTED_TRIGGERS());
			if (cdoctx->TRANSFORM_NOISE_WORDS())
				handle(INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_TRANSFORM_NOISE_WORDS, cdoctx->TRANSFORM_NOISE_WORDS());
			if (cdoctx->TWO_DIGIT_YEAR_CUTOFF())
				handle(INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_TWO_DIGIT_YEAR_CUTOFF, cdoctx->TWO_DIGIT_YEAR_CUTOFF());
			if (cdoctx->DB_CHAINING())
				handle(INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_DB_CHAINING, cdoctx->DB_CHAINING(), &st_escape_hatch_database_misc_options);
			if (cdoctx->TRUSTWORTHY())
				handle(INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_TRUSTWORTHY, cdoctx->TRUSTWORTHY(), &st_escape_hatch_database_misc_options);
			if (cdoctx->CATALOG_COLLATION())
				handle(INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_CATALOG_COLLATION, cdoctx->CATALOG_COLLATION());
			if (cdoctx->PERSISTENT_LOG_BUFFER())
				handle(INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_PERSISTENT_LOG_BUFFER, cdoctx->PERSISTENT_LOG_BUFFER(), &st_escape_hatch_database_misc_options);
		}
	}

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitAlter_database(TSqlParser::Alter_databaseContext *ctx)
{
	handle(INSTR_UNSUPPORTED_TSQL_ALTER_DATABASE, "ALTER DATABASE", getLineAndPos(ctx));
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitCreate_fulltext_index(TSqlParser::Create_fulltext_indexContext *ctx)
{
	handle(INSTR_UNSUPPORTED_TSQL_CREATE_FULLTEXT_INDEX, "CREATE FULLTEXT INDEX", &st_escape_hatch_fulltext, getLineAndPos(ctx));
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitAlter_fulltext_index(TSqlParser::Alter_fulltext_indexContext *ctx)
{
	handle(INSTR_UNSUPPORTED_TSQL_ALTER_FULLTEXT_INDEX, "ALTER FULLTEXT INDEX", &st_escape_hatch_fulltext, getLineAndPos(ctx));
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitDrop_fulltext_index(TSqlParser::Drop_fulltext_indexContext *ctx)
{
	handle(INSTR_UNSUPPORTED_TSQL_DROP_FULLTEXT_INDEX, "DROP FULLTEXT INDEX", &st_escape_hatch_fulltext, getLineAndPos(ctx));
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitCreate_type(TSqlParser::Create_typeContext *ctx)
{
	if (ctx->table_options() && ctx->table_options()->WITH())
		handle(INSTR_UNSUPPORTED_TSQL_CREATE_TYPE_TABLE_OPTION, "table option in CREATE TYPE", getLineAndPos(ctx->table_options()->WITH()));
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitCreate_login(TSqlParser::Create_loginContext *ctx)
{
	if (ctx->password_hash)
		handle(INSTR_UNSUPPORTED_TSQL_LOGIN_HASHED_PASSWORD, "hashed password", &st_escape_hatch_login_hashed_password, getLineAndPos(ctx));

	if (ctx->MUST_CHANGE())
		handle(INSTR_UNSUPPORTED_TSQL_LOGIN_PASSWORD_MUST_CHANGE, ctx->MUST_CHANGE(), &st_escape_hatch_login_password_must_change);

	if (ctx->WINDOWS())
		handle(INSTR_UNSUPPORTED_TSQL_CREATE_LOGIN_MISC_OPTIONS, ctx->WINDOWS(), &st_escape_hatch_login_misc_options);

	if (ctx->CERTIFICATE())
		handle(INSTR_UNSUPPORTED_TSQL_CREATE_LOGIN_MISC_OPTIONS, ctx->CERTIFICATE(), &st_escape_hatch_login_misc_options);

	if (ctx->ASYMMETRIC())
		handle(INSTR_UNSUPPORTED_TSQL_CREATE_LOGIN_MISC_OPTIONS, ctx->ASYMMETRIC(), &st_escape_hatch_login_misc_options);

	for (auto option : ctx->create_login_option_list())
	{
		if (option->DEFAULT_LANGUAGE())
		{
			if (option->id())
			{
				if (!isDefaultLanguage(option->id()))
					handle(INSTR_UNSUPPORTED_TSQL_CREATE_LOGIN_WITH_DEFAULT_LANGUAGE, ::getFullText(option->id()).c_str(), &st_escape_hatch_language_non_english, getLineAndPos(option));
			}
			else // lcid (we can't assure lcid is default or not. to be safe, throw unsupported-feature error)
				handle(INSTR_UNSUPPORTED_TSQL_CREATE_LOGIN_WITH_DEFAULT_LANGUAGE, "DEFAULT LANGUAGE with lcid", getLineAndPos(option));
		}
		else if (option->SID())
			handle(INSTR_UNSUPPORTED_TSQL_CREATE_LOGIN_MISC_OPTIONS, option->SID(), &st_escape_hatch_login_misc_options);
		else if (option->CHECK_EXPIRATION())
			handle(INSTR_UNSUPPORTED_TSQL_CREATE_LOGIN_MISC_OPTIONS, option->CHECK_EXPIRATION(), &st_escape_hatch_login_misc_options);
		else if (option->CHECK_POLICY())
			handle(INSTR_UNSUPPORTED_TSQL_CREATE_LOGIN_MISC_OPTIONS, option->CHECK_POLICY(), &st_escape_hatch_login_misc_options);
		else if (option->CREDENTIAL())
			handle(INSTR_UNSUPPORTED_TSQL_CREATE_LOGIN_MISC_OPTIONS, option->CREDENTIAL(), &st_escape_hatch_login_misc_options);
	}

	for (auto option : ctx->create_login_windows_options())
	{
		if (option->DEFAULT_LANGUAGE())
		{
			if (option->id())
			{
				if (!isDefaultLanguage(option->id()))
					handle(INSTR_UNSUPPORTED_TSQL_CREATE_LOGIN_WITH_DEFAULT_LANGUAGE, ::getFullText(option->id()).c_str(), &st_escape_hatch_language_non_english, getLineAndPos(option));
			}
			else // lcid (we can't assure lcid is default or not. to be safe, throw unsupported-feature error)
				handle(INSTR_UNSUPPORTED_TSQL_CREATE_LOGIN_WITH_DEFAULT_LANGUAGE, "DEFAULT LANGUAGE with lcid", getLineAndPos(option));
		}
	}
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitAlter_login(TSqlParser::Alter_loginContext *ctx)
{
	for (auto option : ctx->alter_login_set_option())
	{
		if (option->password_hash)
			handle(INSTR_UNSUPPORTED_TSQL_LOGIN_HASHED_PASSWORD, "hashed password", &st_escape_hatch_login_hashed_password, getLineAndPos(option));
		else if (option->OLD_PASSWORD())
			handle(INSTR_UNSUPPORTED_TSQL_LOGIN_OLD_PASSWORD, option->OLD_PASSWORD(), &st_escape_hatch_login_old_password);
		else if (option->MUST_CHANGE(0))
			handle(INSTR_UNSUPPORTED_TSQL_LOGIN_PASSWORD_MUST_CHANGE, option->MUST_CHANGE(0), &st_escape_hatch_login_password_must_change);
		else if (option->UNLOCK(0))
			handle(INSTR_UNSUPPORTED_TSQL_LOGIN_PASSWORD_UNLOCK, option->UNLOCK(0), &st_escape_hatch_login_password_unlock);
		else if (option->NAME())
			handle(INSTR_UNSUPPORTED_TSQL_ALTER_LOGIN_MISC_OPTIONS, option->NAME(), &st_escape_hatch_login_misc_options);
		else if (option->CHECK_POLICY())
			handle(INSTR_UNSUPPORTED_TSQL_ALTER_LOGIN_MISC_OPTIONS, option->CHECK_POLICY(), &st_escape_hatch_login_misc_options);
		else if (option->CHECK_EXPIRATION())
			handle(INSTR_UNSUPPORTED_TSQL_ALTER_LOGIN_MISC_OPTIONS, option->CHECK_EXPIRATION(), &st_escape_hatch_login_misc_options);
		else if (option->CREDENTIAL())
			handle(INSTR_UNSUPPORTED_TSQL_ALTER_LOGIN_MISC_OPTIONS, option->CREDENTIAL(), &st_escape_hatch_login_misc_options);
		else if (option->DEFAULT_LANGUAGE())
		{
			if (option->id())
			{
				if (!isDefaultLanguage(option->id()))
					handle(INSTR_UNSUPPORTED_TSQL_ALTER_LOGIN_WITH_DEFAULT_LANGUAGE, ::getFullText(option->id()).c_str(), &st_escape_hatch_language_non_english, getLineAndPos(option));
			}
			else // lcid (we can't assure lcid is default or not. to be safe, throw unsupported-feature error)
				handle(INSTR_UNSUPPORTED_TSQL_ALTER_LOGIN_WITH_DEFAULT_LANGUAGE, "DEFAULT LANGUAGE with lcid", getLineAndPos(option));
		}
	}

	if (ctx->CREDENTIAL())
		handle(INSTR_UNSUPPORTED_TSQL_ALTER_LOGIN_MISC_OPTIONS, ctx->CREDENTIAL(), &st_escape_hatch_login_misc_options);

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitDdl_statement(TSqlParser::Ddl_statementContext *ctx)
{
	/*
	 * We have more than 100 DDLs but support a few of them.
	 * manage the whitelist here.
	 * Please keep the order in grammar file.
	 */
	if (ctx->alter_database()
	 || ctx->alter_fulltext_index()
	 || ctx->alter_index()
	 || ctx->alter_login()
	 || ctx->alter_sequence()
	 || (ctx->alter_server_role())
	 || ctx->alter_table()
	 || (ctx->alter_user() && pltsql_allow_antlr_to_unsupported_grammar_for_testing)
	 || ctx->create_aggregate()
	 || ctx->create_database()
	 || ctx->create_fulltext_index()
	 || ctx->create_index()
	 || ctx->create_login()
	 || ctx->create_schema()
	 || ctx->create_sequence()
	 || (ctx->create_server_role() && pltsql_allow_antlr_to_unsupported_grammar_for_testing)
	 || ctx->create_table()
	 || ctx->create_type()
	 || (ctx->create_user() && pltsql_allow_antlr_to_unsupported_grammar_for_testing)
	 || ctx->drop_aggregate()
	 || ctx->drop_database()
	 || ctx->drop_fulltext_index()
	 || ctx->drop_function()
	 || ctx->drop_index()
	 || ctx->drop_login()
	 || ctx->drop_procedure()
	 || ctx->drop_schema()
	 || ctx->drop_sequence()
	 || (ctx->drop_server_role() && pltsql_allow_antlr_to_unsupported_grammar_for_testing)
	 || ctx->drop_table()
	 || ctx->drop_trigger()
	 || ctx->drop_type()
	 || (ctx->drop_user() && pltsql_allow_antlr_to_unsupported_grammar_for_testing)
	 || ctx->drop_view()
	 || ctx->truncate_table()
	 )
	{
		// supported DDL or DDL which need special handling
		return visitChildren(ctx);
	}

	// generate feature name
	std::string featureName;
	if (ctx->children.size() > 0)
	{
		for (auto t : ctx->children[0]->children) // stripping first child (which is usually sub-grammar rule like create-table)
		{
			// we can assume the first few keyword would indicate feature name
			antlr4::tree::TerminalNode *node = dynamic_cast<antlr4::tree::TerminalNode *>(t);
			if (node == nullptr)
				break;

			if (featureName.length() != 0)
				featureName += " ";
			featureName += node->getText();
		}
	}

	if (featureName.length() == 0)
		featureName = "unknown DDL";
	else
		std::transform(featureName.begin(), featureName.end(), featureName.begin(), ::toupper);

	handle(INSTR_UNSUPPORTED_TSQL_UNKNOWN_DDL, featureName.c_str(), getLineAndPos(ctx));

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitSelect_statement(TSqlParser::Select_statementContext *ctx)
{
	auto qctx = get_query_specification(ctx);
	if (qctx && qctx->select_list())
	{
		for (auto elem : qctx->select_list()->select_list_elem())
		{
			if (elem->column_elem() && elem->column_elem()->DOLLAR_IDENTITY())
				handle(INSTR_UNSUPPORTED_TSQL_SELECT_DOLLAR_IDENTITY, "$IDENTITY", getLineAndPos(elem));
			if (elem->column_elem() && elem->column_elem()->DOLLAR_ROWGUID())
				handle(INSTR_UNSUPPORTED_TSQL_SELECT_DOLLAR_ROWGUID, "$ROWGUID", getLineAndPos(elem));
		}
	}

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitInsert_statement(TSqlParser::Insert_statementContext *ctx)
{
	if (ctx->insert_statement_value() && ctx->insert_statement_value()->DEFAULT() && ctx->output_clause())
		handle(INSTR_UNSUPPORTED_TSQL_INSERT_STMT_DEFAULT_VALUE, "DEFAULT VALUES with OUTPUT clause", getLineAndPos(ctx->output_clause())); /* backend parser can't handle DEFAULT VALUES with output clause yet */
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitUpdate_statement(TSqlParser::Update_statementContext *ctx)
{
	if (ctx->CURRENT()) // CURRENT OF
		handle(INSTR_UNSUPPORTED_TSQL_UPDATE_WHERE_CURRENT_OF, "CURRENT OF", getLineAndPos(ctx->CURRENT()));

	for (auto elem : ctx->update_elem())
	{
		if (elem->DOT())
			handle(INSTR_UNSUPPORTED_TSQL_UPDATE_WITH_METHOD_NAME, "UPDATE with method name", getLineAndPos(elem));
	}

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitDelete_statement(TSqlParser::Delete_statementContext *ctx)
{
	if (ctx->CURRENT()) // CURRENT OF
		handle(INSTR_UNSUPPORTED_TSQL_DELETE_WHERE_CURRENT_OF, "CURRENT OF", getLineAndPos(ctx->CURRENT()));
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitBulk_insert_statement(TSqlParser::Bulk_insert_statementContext *ctx)
{
    return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitSet_statement(TSqlParser::Set_statementContext *ctx)
{
	if (ctx->set_special())
	{
		auto sctx = ctx->set_special();

		/* ON/OFF settings */
		for (auto option : sctx->set_on_off_option())
		{
			if (option->FIPS_FLAGGER())
				handle(INSTR_UNSUPPORTED_TSQL_OPTION_FIPS_FLAGGER, option->FIPS_FLAGGER(), &st_escape_hatch_session_settings);
			if (option->FORCEPLAN())
				handle(INSTR_UNSUPPORTED_TSQL_OPTION_FORCEPLAN, option->FORCEPLAN(), &st_escape_hatch_session_settings);
			if (option->OFFSETS())
				handle(INSTR_UNSUPPORTED_TSQL_OPTION_OFFSETS, option->OFFSETS(), &st_escape_hatch_session_settings);
			if (option->PARSEONLY())
				handle(INSTR_UNSUPPORTED_TSQL_OPTION_PARSEONLY, option->PARSEONLY(), &st_escape_hatch_session_settings);
			if (option->REMOTE_PROC_TRANSACTIONS())
				handle(INSTR_UNSUPPORTED_TSQL_OPTION_REMOTE_PROC_TRANSACTIONS, option->REMOTE_PROC_TRANSACTIONS(), &st_escape_hatch_session_settings);
			if (option->SHOWPLAN_ALL())
				handle(INSTR_UNSUPPORTED_TSQL_OPTION_SHOWPLAN_ALL, option->SHOWPLAN_ALL(), &st_escape_hatch_session_settings);
			if (option->SHOWPLAN_TEXT())
				handle(INSTR_UNSUPPORTED_TSQL_OPTION_SHOWPLAN_TEXT, option->SHOWPLAN_TEXT(), &st_escape_hatch_session_settings);
			if (option->SHOWPLAN_XML())
				handle(INSTR_UNSUPPORTED_TSQL_OPTION_SHOWPLAN_XML, option->SHOWPLAN_XML(), &st_escape_hatch_session_settings);
			if (option->STATISTICS())
				handle(INSTR_UNSUPPORTED_TSQL_OPTION_STATISTICS, option->STATISTICS(), &st_escape_hatch_session_settings);
		}

		if (!sctx->id().empty())
		{
			/* don't strip id here. let them throw an "unrecognized SET option" error in tsqlIface */
			std::string val = getFullText(sctx->id().front());
			if (pg_strcasecmp("DATEFORMAT", val.c_str()) == 0)
				handle(INSTR_UNSUPPORTED_TSQL_OPTION_DATEFORMAT, "DATEFORMAT", &st_escape_hatch_session_settings, getLineAndPos(sctx));
			if (pg_strcasecmp("DEADLOCK_PRIORITY", val.c_str()) == 0)
				handle(INSTR_UNSUPPORTED_TSQL_OPTION_DEADLOCK_PRIORITY, "DEADLOCK_PRIORITY", &st_escape_hatch_session_settings, getLineAndPos(sctx));
			if (pg_strcasecmp("LOCK_TIMEOUT", val.c_str()) == 0)
				handle(INSTR_UNSUPPORTED_TSQL_OPTION_LOCK_TIMEOUT, "LOCK_TIMEOUT", &st_escape_hatch_session_settings, getLineAndPos(sctx));
			if (pg_strcasecmp("CONTEXT_INFO", val.c_str()) == 0)
				handle(INSTR_UNSUPPORTED_TSQL_OPTION_CONTEXT_INFO, "CONTEXT_INFO", &st_escape_hatch_session_settings, getLineAndPos(sctx));
			if (pg_strcasecmp("QUERY_GOVERNOR_COST_LIMIT", val.c_str()) == 0)
				handle(INSTR_UNSUPPORTED_TSQL_OPTION_QUERY_GOVERNOR_COST_LIMIT, "QUERY_GOVERNOR_COST_LIMIT", &st_escape_hatch_session_settings, getLineAndPos(sctx));

			/* let invalid SET-option be handled by tsqlIface */
		}

		if (sctx->STATISTICS())
			handle(INSTR_UNSUPPORTED_TSQL_OPTION_STATISTICS, sctx->STATISTICS(), &st_escape_hatch_session_settings);

		if (sctx->xml_modify_method())
			handle(INSTR_UNSUPPORTED_TSQL_OPTION_XML_METHOD, "xml modify method", getLineAndPos(sctx));
	}

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitCursor_statement(TSqlParser::Cursor_statementContext *ctx)
{
	if (ctx->GLOBAL())
		handle(INSTR_UNSUPPORTED_TSQL_GLOBAL_CURSOR, "GLOBAL CURSOR", getLineAndPos(ctx->GLOBAL()));

	if (ctx->declare_cursor())
	{
		for (auto option : ctx->declare_cursor()->declare_cursor_options())
		{
			if (option->GLOBAL())
				handle(INSTR_UNSUPPORTED_TSQL_GLOBAL_CURSOR, "GLOBAL CURSOR", getLineAndPos(option->GLOBAL()));
			if (option->KEYSET())
				handle(INSTR_UNSUPPORTED_TSQL_KEYSET_CURSOR, "KEYSET CURSOR", getLineAndPos(option->KEYSET()));
			if (option->DYNAMIC())
				handle(INSTR_UNSUPPORTED_TSQL_DYNAMIC_CURSOR, "DYNAMIC CURSOR", getLineAndPos(option->DYNAMIC()));
			if (option->SCROLL_LOCKS())
				handle(INSTR_UNSUPPORTED_TSQL_CURSOR_SCROLL_LOCKS_OPTION, option->SCROLL_LOCKS());
			if (option->OPTIMISTIC())
				handle(INSTR_UNSUPPORTED_TSQL_CURSOR_OPTIMISTIC_OPTION, option->OPTIMISTIC());
			if (option->TYPE_WARNING())
				handle(INSTR_UNSUPPORTED_TSQL_CURSOR_TYPE_WARNING_OPTION, option->TYPE_WARNING());
		}
	}

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitTransaction_statement(TSqlParser::Transaction_statementContext *ctx)
{
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitSecurity_statement(TSqlParser::Security_statementContext *ctx)
{
	if (ctx->execute_as_statement())
		handle(INSTR_UNSUPPORTED_TSQL_EXECUTE_AS_STMT, "EXECUTE AS", getLineAndPos(ctx));
	else if (ctx->revert_statement())
		handle(INSTR_UNSUPPORTED_TSQL_REVERT_STMT, "REVERT", getLineAndPos(ctx));
	else if (ctx->grant_statement())
	{
		if (!pltsql_allow_antlr_to_unsupported_grammar_for_testing)
			handle(INSTR_UNSUPPORTED_TSQL_GRANT_STMT, "GRANT", getLineAndPos(ctx));
	}
	else if (ctx->revoke_statement())
		handle(INSTR_UNSUPPORTED_TSQL_REVOKE_STMT, "REVOKE", getLineAndPos(ctx));
	else if (ctx->deny_statement())
		handle(INSTR_UNSUPPORTED_TSQL_DENY_STMT, "DENY", getLineAndPos(ctx));
	else if (ctx->open_key())
		handle(INSTR_UNSUPPORTED_TSQL_OPEN_KEY, "OPEN KEY", getLineAndPos(ctx));
	else if (ctx->close_key())
		handle(INSTR_UNSUPPORTED_TSQL_CLOSE_KEY, "CLOSE KEY", getLineAndPos(ctx));
	else if (ctx->create_key())
		handle(INSTR_UNSUPPORTED_TSQL_CREATE_KEY, "CREATE KEY", getLineAndPos(ctx));
	else if (ctx->create_certificate())
		handle(INSTR_UNSUPPORTED_TSQL_CREATE_CERTIFICATE, "CREATE CERTIFICATE", getLineAndPos(ctx));

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitTable_source_item(TSqlParser::Table_source_itemContext *ctx)
{
	if (ctx->APPLY())
		handle(INSTR_UNSUPPORTED_TSQL_APPLY, ctx->APPLY());
	if (ctx->PIVOT())
		handle(INSTR_UNSUPPORTED_TSQL_PIVOT, ctx->PIVOT());
	if (ctx->UNPIVOT())
		handle(INSTR_UNSUPPORTED_TSQL_UNPIVOT, ctx->UNPIVOT());

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitFor_clause(TSqlParser::For_clauseContext *ctx)
{
	if (ctx->BROWSE())
		handle(INSTR_UNSUPPORTED_TSQL_FOR_BROWSE_CLAUSE, "FOR BROWSE", getLineAndPos(ctx->BROWSE()));
	if (ctx->XML())
	{
		// RAW and PATH is supported
		if (ctx->AUTO())
			handle(INSTR_UNSUPPORTED_TSQL_XML_OPTION_AUTO, "FOR XML AUTO mode", getLineAndPos(ctx->AUTO()));
		if (ctx->EXPLICIT())
			handle(INSTR_UNSUPPORTED_TSQL_XML_OPTION_EXPLICIT, "FOR XML EXPLICIT mode", getLineAndPos(ctx->EXPLICIT()));
		if (!ctx->XMLDATA().empty())
			handle(INSTR_UNSUPPORTED_TSQL_XMLDATA, "XMLDATA", getLineAndPos(ctx->XMLDATA()[0]));
	}
	else if (ctx->JSON())
		handle(INSTR_UNSUPPORTED_TSQL_FOR_JSON_CLAUSE, "FOR JSON", getLineAndPos(ctx->JSON()));
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitWith_table_hints(TSqlParser::With_table_hintsContext *ctx)
{
	handle(INSTR_UNSUPPORTED_TSQL_TABLE_HINTS, "table hint", &st_escape_hatch_table_hints, getLineAndPos(ctx));
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitOption_clause(TSqlParser::Option_clauseContext *ctx)
{
	handle(INSTR_UNSUPPORTED_TSQL_QUERY_HINTS, "query hint", &st_escape_hatch_query_hints, getLineAndPos(ctx));
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitJoin_hint(TSqlParser::Join_hintContext *ctx)
{
	handle(INSTR_UNSUPPORTED_TSQL_JOIN_HINTS, "join hint", &st_escape_hatch_join_hints, getLineAndPos(ctx));
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitGroup_by_item(TSqlParser::Group_by_itemContext *ctx)
{
	if (ctx->with_distributed_agg())
		handle(INSTR_UNSUPPORTED_TSQL_WITH_DISTRIBUTED_AGG, "WITH DISTRIBUTED AGG", getLineAndPos(ctx->with_distributed_agg()));
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitAggregate_windowed_function(TSqlParser::Aggregate_windowed_functionContext *ctx)
{
	if (ctx->STDEV())
		handle(INSTR_UNSUPPORTED_TSQL_STDEV_FUNCTION, ctx->STDEV());
	if (ctx->STDEVP())
		handle(INSTR_UNSUPPORTED_TSQL_STDEVP_FUNCTION, ctx->STDEVP());
	if (ctx->VAR())
		handle(INSTR_UNSUPPORTED_TSQL_VAR_FUNCTION, ctx->VAR());
	if (ctx->VARP())
		handle(INSTR_UNSUPPORTED_TSQL_VARP_FUNCTION, ctx->VARP());
	if (ctx->CHECKSUM_AGG())
		handle(INSTR_UNSUPPORTED_TSQL_CHECKSUM_AGG_FUNCTION, ctx->CHECKSUM_AGG());
	if (ctx->GROUPING_ID())
		handle(INSTR_UNSUPPORTED_TSQL_GROUPING_FUNCTION, ctx->GROUPING());

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitExpression(TSqlParser::ExpressionContext *ctx)
{
	if (ctx->DEFAULT())
	{
		TSqlParser::Expression_listContext *pctx = dynamic_cast<TSqlParser::Expression_listContext *>(ctx->parent);
		if (!pctx || dynamic_cast<TSqlParser::Table_value_constructorContext *>(pctx->parent) == nullptr) /* if DEFAULT expression is used for VALUES ..., accept it */
			handle(INSTR_UNSUPPORTED_TSQL_EXPRESSION_DEFAULT, ctx->DEFAULT());
	}
	if (ctx->hierarchyid_coloncolon_methods())
		handle(INSTR_UNSUPPORTED_TSQL_EXPRESSION_HIERARCHID, "hierarchid", getLineAndPos(ctx->hierarchyid_coloncolon_methods()));
	if (ctx->odbc_literal())
		handle(INSTR_UNSUPPORTED_TSQL_EXPRESSION_ODBC_LITERAL, "odbc literal", getLineAndPos(ctx->odbc_literal()));
	if (ctx->DOLLAR_ACTION())
		handle(INSTR_UNSUPPORTED_TSQL_EXPRESSION_DOLLAR_ACTION, "$ACTION", getLineAndPos(ctx->DOLLAR_ACTION()));
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitExecute_parameter(TSqlParser::Execute_parameterContext *ctx)
{
	if (ctx->DEFAULT())
		handle(INSTR_UNSUPPORTED_TSQL_EXECUTE_PARAMETER_DEFAULT, ctx->DEFAULT());
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitTrigger_column_updated(TSqlParser::Trigger_column_updatedContext *ctx)
{
	handle(INSTR_UNSUPPORTED_TSQL_UPDATE_FUNC_IN_TRIGGER, "UPDATE() function in  trigger", getLineAndPos(ctx));
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitFunc_proc_name_schema(TSqlParser::Func_proc_name_schemaContext *ctx)
{
	if (ctx->DOT().empty())
	{
		// check some built-in functions/procedures
		checkUnsupportedSystemProcedure(ctx->procedure);
	}

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitFunc_proc_name_database_schema(TSqlParser::Func_proc_name_database_schemaContext *ctx)
{
	if (ctx->DOT().empty())
	{
		// check some built-in functions/procedures
		checkUnsupportedSystemProcedure(ctx->procedure);
	}

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitFunc_proc_name_server_database_schema(TSqlParser::Func_proc_name_server_database_schemaContext *ctx)
{
	if (ctx->DOT().size() >= 3 && ctx->server) /* server.db.schema.funcname */
		handle(INSTR_UNSUPPORTED_TSQL_SERVERNAME_IN_NAME, "servername", getLineAndPos(ctx));

	if (ctx->DOT().empty())
	{
		// check some built-in functions/procedures
		checkUnsupportedSystemProcedure(ctx->procedure);

		if (pg_strcasecmp("COLUMNS_UPDATED", getFullText(ctx->procedure).c_str()) == 0)
	 		handle(INSTR_UNSUPPORTED_TSQL_COLUMNS_UPDATED_FUNC, "COLUMNS_UPDATED FUNC IN TRIGGER", getLineAndPos(ctx));
	}

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitFull_object_name(TSqlParser::Full_object_nameContext *ctx)
{
	if (ctx->DOT().size() >= 3 && ctx->server) /* server.db.schema.funcname */
		handle(INSTR_UNSUPPORTED_TSQL_SERVERNAME_IN_NAME, "servername", getLineAndPos(ctx));

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitBif_cast_parse(TSqlParser::Bif_cast_parseContext *ctx)
{
	if (ctx->PARSE())
		handle(INSTR_TSQL_PARSE, ctx->PARSE());
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitBif_convert(TSqlParser::Bif_convertContext *ctx)
{
	if (ctx->TRY_CONVERT())
		handle(INSTR_TSQL_TRY_CONVERT, ctx->TRY_CONVERT());
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitData_type(TSqlParser::Data_typeContext *ctx)
{
	if (ctx->simple_name() && ctx->simple_name()->DOT().empty()) /* datatype with no schema */
	{
		std::string val = stripQuoteFromId(ctx->simple_name()->id().back());
		if (pg_strcasecmp("timestamp", val.c_str()) == 0)
			handle(INSTR_TSQL_TIMESTAMP_DATATYPE, "TIMESTAMP datatype", getLineAndPos(ctx));
		else if (pg_strcasecmp("rowversion", val.c_str()) == 0)
			handle(INSTR_TSQL_ROWVERSION_DATATYPE, "ROWVERSION datatype", getLineAndPos(ctx));
	}

	if (ctx->NATIONAL())
		handle(INSTR_UNSUPPORTED_TSQL_NATIONAL, ctx->NATIONAL());
	if (ctx->VARYING())
		handle(INSTR_UNSUPPORTED_TSQL_VARYING, ctx->VARYING());

	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitSql_option(TSqlParser::Sql_optionContext *ctx)
{
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitSnapshot_option(TSqlParser::Snapshot_optionContext *ctx)
{
	if (ctx->ALLOW_SNAPSHOT_ISOLATION())
		handle(INSTR_UNSUPPORTED_TSQL_OPTION_ALLOW_SNAPSHOT_ISOLATION, ctx->ALLOW_SNAPSHOT_ISOLATION());
	return visitChildren(ctx);
}

antlrcpp::Any TsqlUnsupportedFeatureHandlerImpl::visitKeyword(TSqlParser::KeywordContext *ctx)
{
	if (ctx->ALLOW_SNAPSHOT_ISOLATION())
	{
		handle(INSTR_UNSUPPORTED_TSQL_OPTION_ALLOW_SNAPSHOT_ISOLATION, ctx->ALLOW_SNAPSHOT_ISOLATION());
	}
	return visitChildren(ctx);
}

bool TsqlUnsupportedFeatureHandlerImpl::isDefaultLanguage(TSqlParser::IdContext *ctx)
{
	std::string val = stripQuoteFromId(ctx);
	return (pg_strcasecmp("english", val.c_str()) == 0) || (pg_strcasecmp("us_english", val.c_str()) == 0);
}

// This is a list for generating better error message. It may not be a complete list.
// If unsupported feature is missing here, it will not cause a critical problem because it will just throw an error "procedure does not exist" in backend parser.
const char *unsupported_sp_procedures[] = {
	/* Catalog */
	"sp_column_privileges",
	"sp_fkeys",
	"sp_server_info",
	"sp_special_columns",
	"sp_sproc_columns",
	"sp_stored_procedures",
	"sp_table_privileges",

	/* Cursor */
	"sp_describe_cursor_columns",
	"sp_describe_cursor_tables",

	/* Database Engine */
	"sp_add_data_file_recover_suspect_db",
	"sp_add_log_file_recover_suspect_db",
	"sp_addextendedproc",
	"sp_addextendedproperty",
	"sp_addmessage",
	"sp_addtype",
	"sp_addumpdevice",
	"sp_altermessage",
	"sp_attach_db",
	"sp_attach_single_file_db",
	"sp_autostats",
	"sp_bindefault",
	"sp_bindrule",
	"sp_bindsession",
	"sp_certify_removable",
	"sp_clean_db_file_free_space",
	"sp_clean_db_free_space",
	"sp_configure",
	"sp_control_plan_guide",
	"sp_create_plan_guide",
	"sp_create_plan_guide_from_handle",
	"sp_create_removable",
	"sp_createstats",
	"sp_cycle_errorlog",
	"sp_db_increased_partitions",
	"sp_dbcmptlevel",
	"sp_dbmmonitoraddmonitoring",
	"sp_dbmmonitorchangealert",
	"sp_dbmmonitorchangemonitoring",
	"sp_dbmmonitordropalert",
	"sp_dbmmonitordropmonitoring",
	"sp_dbmmonitorhelpalert",
	"sp_dbmmonitorhelpmonitoring",
	"sp_dbmmonitorresults",
	"sp_delete_backuphistory",
	"sp_depends",
	"sp_detach_db",
	"sp_dropdevice",
	"sp_dropextendedproc",
	"sp_dropextendedproperty",
	"sp_dropmessage",
	"sp_droptype",
	"sp_getbindtoken",
	"sp_help",
	"sp_helpconstraint",
	"sp_helpdevice",
	"sp_helpextendedproc",
	"sp_helpfile",
	"sp_helpfilegroup",
	"sp_helpindex",
	"sp_helplanguage"
	"sp_helpserver",
	"sp_helpsort",
	"sp_helpstats",
	"sp_helptext",
	"sp_helptrigger",
	"sp_indexoption",
	"sp_invalidate_textptr"
	"sp_lock",
	"sp_monitor",
	"sp_prepexecrpc",
	"sp_procoption",
	"sp_recompile",
	"sp_refreshview",
	"sp_rename",
	"sp_renamedb",
	"sp_resetstatus",
	"sp_sequence_get_range",
	"sp_serveroption",
	"sp_set_session_context",
	"sp_setnetname",
	"sp_settriggerorder",
	"sp_spaceused",
	"sp_tableoption",
	"sp_unbindefault",
	"sp_unbindrule",
	"sp_updateextendedproperty",
	"sp_validname",
	"sp_who",

	/* Security */
	"sp_add_trusted_assembly",
	"sp_addapprole",
	"sp_addlinkedserver",
	"sp_addlinkedsrvlogin",
	"sp_addlogin",
	"sp_addremotelogin",
	"sp_addrole",
	"sp_addrolemember",
	"sp_addserver",
	"sp_addsrvrolemember",
	"sp_adduser",
	"sp_approlepassword",
	"sp_audit_write",
	"sp_change_users_login",
	"sp_changedbowner",
	"sp_changeobjectowner",
	"sp_control_dbmasterkey_password",
	"sp_dbfixedrolepermission",
	"sp_defaultdb",
	"sp_defaultlanguage",
	"sp_denylogin",
	"sp_describe_parameter_encryption",
	"sp_dropalias",
	"sp_drop_trusted_assembly",
	"sp_dropapprole",
	"sp_droplinkedsrvlogin",
	"sp_droplogin",
	"sp_dropremotelogin",
	"sp_droprole",
	"sp_droprolemember",
	"sp_dropserver",
	"sp_dropsrvrolemember",
	"sp_dropuser",
	"sp_generate_database_ledger_digest",
	"sp_grantdbaccess",
	"sp_grantlogin",
	"sp_helpdbfixedrole",
	"sp_helplinkedsrvlogin",
	"sp_helplogins",
	"sp_helpntgroup",
	"sp_helpremotelogin",
	"sp_helprole",
	"sp_helprolemember",
	"sp_helprotect",
	"sp_helpsrvrole",
	"sp_helpsrvrolemember",
	"sp_helpuser",
	"sp_migrate_user_to_contained",
	"sp_MShasdbaccess",
	"sp_password",
	"sp_refresh_parameter_encryption",
	"sp_remoteoption",
	"sp_revokedbaccess",
	"sp_revokelogin",
	"sp_setapprole",
	"sp_srvrolepermission",
	"sp_testlinkedserver",
	"sp_unsetapprole",
	"sp_validatelogins",
	"sp_verify_database_ledger",
	"sp_verify_database_ledger_from_digest_storage",
	"sp_xp_cmdshell_proxy_account"
};

#define NUM_UNSUPPORTED_PROCEDURES (sizeof(unsupported_sp_procedures)/sizeof(unsupported_sp_procedures[0]))

void TsqlUnsupportedFeatureHandlerImpl::checkUnsupportedSystemProcedure(TSqlParser::IdContext *ctx)
{
	std::string val = stripQuoteFromId(ctx);
	for (size_t i=0; i<NUM_UNSUPPORTED_PROCEDURES; ++i)
		if (pg_strcasecmp(unsupported_sp_procedures[i], val.c_str()) == 0)
			handle(INSTR_UNSUPPORTED_TSQL_NOT_IMPLEMENTED_SYSTEM_PROCEDURE, val.c_str(), getLineAndPos(ctx));
}
