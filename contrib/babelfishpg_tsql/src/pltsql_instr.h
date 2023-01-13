/*-------------------------------------------------------------------------
 * pltsql_instr.h
 *
 * Copyright (c) 2017-2020, Amazon Web Services, Inc. or its affiliates. All Rights Reserved
 *-------------------------------------------------------------------------
 */

#include "postgres.h"
#include "port/atomics.h"
#include "pltsql.h"

#define METRIC_TYPE int

typedef enum PgTsqlInstrMetricType {

	INSTR_START = -1,
	INSTR_TSQL_ALTER_COLUMN,
	INSTR_TSQL_IDENTITY_COLUMN,
	INSTR_TSQL_COMPUTED_COLUMN,
	INSTR_TSQL_CREATE_TEMP_TABLE,
	INSTR_TSQL_CREATE_FUNCTION_RETURNS_TABLE,

	INSTR_UNSUPPORTED_TSQL_TOP_PERCENT_IN_STMT,
	INSTR_UNSUPPORTED_TSQL_XML_OPTION_AUTO,
	INSTR_UNSUPPORTED_TSQL_XML_OPTION_EXPLICIT,
	INSTR_UNSUPPORTED_TSQL_MERGE,
	INSTR_UNSUPPORTED_TSQL_BULK_INSERT,
	INSTR_UNSUPPORTED_TSQL_WAIT_FOR,
	INSTR_UNSUPPORTED_TSQL_WITH_XMLNAMESPACES,
	INSTR_UNSUPPORTED_TSQL_CREATE_CONTRACT,
	INSTR_UNSUPPORTED_TSQL_CREATE_QUEUE,
	INSTR_UNSUPPORTED_TSQL_ALTER_QUEUE,
	INSTR_UNSUPPORTED_TSQL_KILL,
	INSTR_UNSUPPORTED_TSQL_CREATE_MESSAGE,
	INSTR_UNSUPPORTED_TSQL_RECONFIGURE,
	INSTR_UNSUPPORTED_TSQL_SHUTDOWN,
	INSTR_UNSUPPORTED_TSQL_DBCC,
	INSTR_UNSUPPORTED_TSQL_BACKUP,
	INSTR_UNSUPPORTED_TSQL_RESTORE,
	INSTR_UNSUPPORTED_TSQL_CHECKPOINT,
	INSTR_UNSUPPORTED_TSQL_READTEXT,
	INSTR_UNSUPPORTED_TSQL_WRITETEXT,
	INSTR_UNSUPPORTED_TSQL_UPDATETEXT,
	INSTR_UNSUPPORTED_TSQL_FREETEXT,
	INSTR_UNSUPPORTED_TSQL_NEXT_VALUE_FOR,
	INSTR_UNSUPPORTED_TSQL_XML_NODES,
	INSTR_UNSUPPORTED_TSQL_XML_VALUE,
	INSTR_UNSUPPORTED_TSQL_XML_QUERY,
	INSTR_UNSUPPORTED_TSQL_XML_EXIST,
	INSTR_UNSUPPORTED_TSQL_XML_MODIFY,
	INSTR_UNSUPPORTED_TSQL_ALTER_FUNCTION,
	INSTR_UNSUPPORTED_TSQL_ALTER_FUNCTION_ENCRYPTION_OPTION,
	INSTR_UNSUPPORTED_TSQL_ALTER_FUNCTION_NATIVE_COMPILATION_OPTION,
	INSTR_UNSUPPORTED_TSQL_ALTER_FUNCTION_EXTERNAL_NAME_OPTION,
	INSTR_UNSUPPORTED_TSQL_ALTER_PROCEDURE,
	INSTR_UNSUPPORTED_TSQL_ALTER_PROCEDURE_ENCRYPTION_OPTION,
	INSTR_UNSUPPORTED_TSQL_ALTER_PROCEDURE_NATIVE_COMPILATION_OPTION,
	INSTR_UNSUPPORTED_TSQL_ALTER_PROCEDURE_RECOMPILE_OPTION,
	INSTR_UNSUPPORTED_TSQL_ALTER_PROCEDURE_ATOMIC_WITH_OPTION,
	INSTR_UNSUPPORTED_TSQL_ALTER_PROCEDURE_EXTERNAL_NAME_OPTION,
	INSTR_UNSUPPORTED_TSQL_DDL_TRIGGER,
	INSTR_UNSUPPORTED_TSQL_DML_ALTER_TRIGGER,
	INSTR_UNSUPPORTED_TSQL_DML_INSTEAD_OF_TRIGGER,
	INSTR_UNSUPPORTED_TSQL_DML_WITH_APPEND_TRIGGER,
	INSTR_UNSUPPORTED_TSQL_DML_TRIGGER_ENCRYPTION_OPTION,
	INSTR_UNSUPPORTED_TSQL_DML_TRIGGER_NATIVE_COMPILATION_OPTION,
	INSTR_UNSUPPORTED_TSQL_DML_TRIGGER_EXTERNAL_NAME_OPTION,
	INSTR_UNSUPPORTED_TSQL_DDL_TRIGGER_ENCRYPTION_OPTION,
	INSTR_UNSUPPORTED_TSQL_DDL_TRIGGER_NATIVE_COMPILATION_OPTION,
	INSTR_UNSUPPORTED_TSQL_DDL_TRIGGER_EXTERNAL_NAME_OPTION,
	INSTR_UNSUPPORTED_TSQL_ALTER_VIEW,
	INSTR_UNSUPPORTED_TSQL_ALTER_VIEW_ENCRYPTION_OPTION,
	INSTR_UNSUPPORTED_TSQL_ALTER_VIEW_VIEW_METADATA_OPTION,
	INSTR_UNSUPPORTED_TSQL_FILEGROUP,
	INSTR_UNSUPPORTED_TSQL_PARTITION_SCHEME,
	INSTR_UNSUPPORTED_TSQL_NOT_FOR_REPLICATION,
	INSTR_UNSUPPORTED_TSQL_FOR_REPLICATION,
	INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_CLUSTERED,
	INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_VALUES,
	INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_CONNECTION,
	INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_SPARSE,
	INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_FILESTREAM,
	INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_ROWGUIDCOL,
	INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_HIDDEN_RENAMED,
	INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_PERSISTED,
	INSTR_UNSUPPORTED_TSQL_COLUMN_OPTION_MASKED,
	INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_FILLFACTOR,
	INSTR_UNSUPPORTED_TSQL_CONSTRAINT_DEFAULT,
	INSTR_UNSUPPORTED_TSQL_GLOBAL_TEMPORARY_TABLE,
	INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_CONSTRAINT_NO_CHECK_ADD,
	INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_CONSTRAINT_NO_CHECK,
	INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_CHANGE_TRACKING_OPTION,
	INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_SWITCH_OPTION,
	INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_SYSTEM_VERSIONING_OPTION,
	INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_LOCK_ESCALATION_OPTION,
	INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_REBUILD_OPTION,
	INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_COLUMNSTORE,
	INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_MISC,
	INSTR_UNSUPPORTED_TSQL_INDEX_OPTION_UNKNOWN,
	INSTR_UNSUPPORTED_TSQL_UNIQUE_CONSTRAINT,
	INSTR_UNSUPPORTED_TSQL_ALTER_INDEX,
	INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_CONTAINMENT,
	INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_ON,
	INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_COLLATE,
	INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_FILESTREAM,
	INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_DEFAULT_LANGUAGE,
	INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_DEFAULT_FULLTEXT_LANGUAGE,
	INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_NESTED_TRIGGERS,
	INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_TRANSFORM_NOISE_WORDS,
	INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_TWO_DIGIT_YEAR_CUTOFF,
	INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_DB_CHAINING,
	INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_TRUSTWORTHY,
	INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_CATALOG_COLLATION,
	INSTR_UNSUPPORTED_TSQL_CREATE_DATABASE_WITH_PERSISTENT_LOG_BUFFER,
	INSTR_UNSUPPORTED_TSQL_LOGIN_HASHED_PASSWORD,
	INSTR_UNSUPPORTED_TSQL_LOGIN_OLD_PASSWORD,
	INSTR_UNSUPPORTED_TSQL_LOGIN_PASSWORD_MUST_CHANGE,
	INSTR_UNSUPPORTED_TSQL_LOGIN_PASSWORD_UNLOCK,
	INSTR_UNSUPPORTED_TSQL_CREATE_LOGIN_MISC_OPTIONS,
	INSTR_UNSUPPORTED_TSQL_ALTER_LOGIN_MISC_OPTIONS,
	INSTR_UNSUPPORTED_TSQL_CREATE_LOGIN_WITH_DEFAULT_LANGUAGE,
	INSTR_UNSUPPORTED_TSQL_ALTER_LOGIN_WITH_DEFAULT_LANGUAGE,
	INSTR_UNSUPPORTED_TSQL_CREATE_FULLTEXT_INDEX,
	INSTR_UNSUPPORTED_TSQL_ALTER_FULLTEXT_INDEX,
	INSTR_UNSUPPORTED_TSQL_DROP_FULLTEXT_INDEX,
	INSTR_UNSUPPORTED_TSQL_SELECT_DOLLAR_IDENTITY,
	INSTR_UNSUPPORTED_TSQL_SELECT_DOLLAR_ROWGUID,
	INSTR_UNSUPPORTED_TSQL_UPDATE_WHERE_CURRENT_OF,
	INSTR_UNSUPPORTED_TSQL_UPDATE_WITH_METHOD_NAME,
	INSTR_UNSUPPORTED_TSQL_DELETE_WHERE_CURRENT_OF,
	INSTR_UNSUPPORTED_TSQL_GLOBAL_CURSOR,
	INSTR_UNSUPPORTED_TSQL_KEYSET_CURSOR,
	INSTR_UNSUPPORTED_TSQL_DYNAMIC_CURSOR,
	INSTR_UNSUPPORTED_TSQL_CURSOR_SCROLL_LOCKS_OPTION,
	INSTR_UNSUPPORTED_TSQL_CURSOR_OPTIMISTIC_OPTION,
	INSTR_UNSUPPORTED_TSQL_CURSOR_TYPE_WARNING_OPTION,
	INSTR_UNSUPPORTED_TSQL_EXECUTE_AS_STMT,
	INSTR_UNSUPPORTED_TSQL_REVERT_STMT,
	INSTR_UNSUPPORTED_TSQL_DENY_STMT,
	INSTR_UNSUPPORTED_TSQL_OPEN_KEY,
	INSTR_UNSUPPORTED_TSQL_CLOSE_KEY,
	INSTR_UNSUPPORTED_TSQL_CREATE_KEY,
	INSTR_UNSUPPORTED_TSQL_CREATE_CERTIFICATE,
	INSTR_UNSUPPORTED_TSQL_APPLY,
	INSTR_UNSUPPORTED_TSQL_PIVOT,
	INSTR_UNSUPPORTED_TSQL_UNPIVOT,
	INSTR_UNSUPPORTED_TSQL_FOR_BROWSE_CLAUSE,
	INSTR_UNSUPPORTED_TSQL_XMLDATA,
	INSTR_UNSUPPORTED_TSQL_FOR_JSON_CLAUSE,
	INSTR_UNSUPPORTED_TSQL_TABLE_HINTS,
	INSTR_UNSUPPORTED_TSQL_QUERY_HINTS,
	INSTR_UNSUPPORTED_TSQL_JOIN_HINTS,
	INSTR_UNSUPPORTED_TSQL_WITH_DISTRIBUTED_AGG,
	INSTR_UNSUPPORTED_TSQL_STDEV_FUNCTION,
	INSTR_UNSUPPORTED_TSQL_STDEVP_FUNCTION,
	INSTR_UNSUPPORTED_TSQL_VAR_FUNCTION,
	INSTR_UNSUPPORTED_TSQL_VARP_FUNCTION,
	INSTR_UNSUPPORTED_TSQL_CHECKSUM_AGG_FUNCTION,
	INSTR_UNSUPPORTED_TSQL_GROUPING_FUNCTION,
	INSTR_UNSUPPORTED_TSQL_UPDATE_FUNC_IN_TRIGGER,
	INSTR_UNSUPPORTED_TSQL_CREATE_CONVERSATION_STMT,
	INSTR_UNSUPPORTED_TSQL_SET_USER,
	INSTR_UNSUPPORTED_TSQL_ROWSET_FUNCTION,
	INSTR_UNSUPPORTED_TSQL_ODBC_SCALAR_FUNCTION,
	INSTR_UNSUPPORTED_TSQL_PARTITION_FUNCTION,
	INSTR_UNSUPPORTED_TSQL_HIERARCHYID_METHOD,
	INSTR_UNSUPPORTED_TSQL_SPATIAL_METHOD,
	INSTR_UNSUPPORTED_TSQL_PROCEDURE_VARYING_CLAUSE,
	INSTR_UNSUPPORTED_TSQL_PERIOD_FOR_SYSTEM_TIME,
	INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_ALTER_COLUMN_COLLATE,
	INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_ALTER_COLUMN_NOT_NULL,
	INSTR_UNSUPPORTED_TSQL_ALTER_TABLE_ALTER_COLUMN_NULL,
	INSTR_UNSUPPORTED_TSQL_CREATE_TYPE_TABLE_OPTION,
	INSTR_UNSUPPORTED_TSQL_INSERT_STMT_DEFAULT_VALUE,
	INSTR_UNSUPPORTED_TSQL_EXPRESSION_DEFAULT,
	INSTR_UNSUPPORTED_TSQL_EXPRESSION_HIERARCHID,
	INSTR_UNSUPPORTED_TSQL_EXPRESSION_ODBC_LITERAL,
	INSTR_UNSUPPORTED_TSQL_EXPRESSION_DOLLAR_ACTION,
	INSTR_UNSUPPORTED_TSQL_EXECUTE_PARAMETER_DEFAULT,
	INSTR_UNSUPPORTED_TSQL_COLUMNS_UPDATED_FUNC,
	INSTR_UNSUPPORTED_TSQL_NATIONAL,
	INSTR_UNSUPPORTED_TSQL_VARYING,
	INSTR_UNSUPPORTED_TSQL_UNKNOWN_DDL,
	INSTR_UNSUPPORTED_TSQL_NOT_IMPLEMENTED_SYSTEM_PROCEDURE,
	INSTR_TSQL_TIMESTAMP_DATATYPE,
	INSTR_TSQL_ROWVERSION_DATATYPE,
	INSTR_TSQL_HIERARCHYID_DATATYPE,
	INSTR_TSQL_GEOGRAPHY_DATATYPE,
	INSTR_TSQL_GEOMETRY_DATATYPE,
	INSTR_TSQL_OPTION_CLUSTERED,
	INSTR_TSQL_OPTION_NON_CLUSTERED,
	INSTR_TSQL_DATEADD,
	INSTR_TSQL_DATEDIFF,
	INSTR_TSQL_DATEPART,
	INSTR_TSQL_DATENAME,
	INSTR_TSQL_DAY,
	INSTR_TSQL_MONTH,
	INSTR_TSQL_YEAR,
	INSTR_TSQL_DB_ID,
	INSTR_TSQL_DB_NAME,
	INSTR_TSQL_CHARINDEX,
	INSTR_TSQL_DATALENGTH,
	INSTR_TSQL_NCHAR,
	INSTR_TSQL_PATINDEX,
	INSTR_TSQL_QUOTENAME,
	INSTR_TSQL_REPLICATE,
	INSTR_TSQL_SPACE,
	INSTR_TSQL_STRING_ESCAPE,
	INSTR_TSQL_STRING_SPLIT,
	INSTR_TSQL_ISNUMERIC,
	INSTR_TSQL_CEILING,
	INSTR_TSQL_FLOOR,
	INSTR_TSQL_ROUND,
	INSTR_TSQL_STR,



	INSTR_TSQL_FUNCTION_IIF,
	INSTR_TSQL_FUNCTION_CHOOSE,
	INSTR_UNSUPPORTED_TSQL_TEXTIMAGE_ON,
	INSTR_TSQL_FUNCTION_TRY_CAST,
	INSTR_TSQL_TRY_CONVERT,
	INSTR_TSQL_PARSE,
	INSTR_TSQL_FUNCTION_PARSE,
	INSTR_TSQL_FUNCTION_CONVERT,

	INSTR_TSQL_SCHEMABINDING,
	INSTR_TSQL_OPTION_IDENTITY_INSERT,
	INSTR_TSQL_OPTION_LANGUAGE,
	INSTR_UNSUPPORTED_TSQL_OPTION_ANSI_NULL_DFLT,
	INSTR_UNSUPPORTED_TSQL_OPTION_ANSI_PADDING,
	INSTR_UNSUPPORTED_TSQL_OPTION_ANSI_WARNINGS,
	INSTR_UNSUPPORTED_TSQL_OPTION_ALLOW_SNAPSHOT_ISOLATION,
	INSTR_UNSUPPORTED_TSQL_OPTION_ARITHABORT,
	INSTR_UNSUPPORTED_TSQL_OPTION_ARITHIGNORE,
	INSTR_UNSUPPORTED_TSQL_OPTION_CURSOR_CLOSE_ON_COMMIT,
	INSTR_UNSUPPORTED_TSQL_OPTION_NUMERIC_ROUNDABORT,
	INSTR_UNSUPPORTED_TSQL_OPTION_NOEXEC,
	INSTR_UNSUPPORTED_TSQL_OPTION_FMTONLY,
	INSTR_UNSUPPORTED_TSQL_OPTION_SHOWPLAN_ALL,
	INSTR_UNSUPPORTED_TSQL_OPTION_SHOWPLAN_TEXT,
	INSTR_UNSUPPORTED_TSQL_OPTION_SHOWPLAN_XML,
	INSTR_UNSUPPORTED_TSQL_OPTION_FIPS_FLAGGER,
	INSTR_UNSUPPORTED_TSQL_OPTION_FORCEPLAN,
	INSTR_UNSUPPORTED_TSQL_OPTION_OFFSETS,
	INSTR_UNSUPPORTED_TSQL_OPTION_PARSEONLY,
	INSTR_UNSUPPORTED_TSQL_OPTION_REMOTE_PROC_TRANSACTIONS,
	INSTR_UNSUPPORTED_TSQL_OPTION_STATISTICS,
	INSTR_UNSUPPORTED_TSQL_OPTION_DATEFORMAT,
	INSTR_UNSUPPORTED_TSQL_OPTION_DEADLOCK_PRIORITY,
	INSTR_UNSUPPORTED_TSQL_OPTION_CONTEXT_INFO,
	INSTR_UNSUPPORTED_TSQL_OPTION_QUERY_GOVERNOR_COST_LIMIT,
	INSTR_UNSUPPORTED_TSQL_OPTION_XML_METHOD,

	INSTR_TSQL_INSERT_STMT,
	INSTR_TSQL_DELETE_STMT,
	INSTR_TSQL_UPDATE_STMT,
	INSTR_TSQL_SELECT_STMT,
	INSTR_TSQL_TRANS_STMT_START,
	INSTR_TSQL_TRANS_STMT_COMMIT,
	INSTR_TSQL_TRANS_STMT_ROLLBACK,
	INSTR_TSQL_TRANS_STMT_SAVEPOINT,
	INSTR_TSQL_TRANS_STMT_RELEASE,
	INSTR_TSQL_TRANS_STMT_PREPARE,
	INSTR_TSQL_TRANS_STMT_COMMIT_PREPARED,
	INSTR_TSQL_TRANS_STMT_ROLLBACK_PREPARED,
	INSTR_TSQL_TRANS_STMT_START_ISO_LEVEL_READ_UNCOMMITTED,
	INSTR_TSQL_TRANS_STMT_START_ISO_LEVEL_READ_COMMITTED,
	INSTR_TSQL_TRANS_STMT_START_ISO_LEVEL_REPEATABLE_READ,
	INSTR_TSQL_TRANS_STMT_START_ISO_LEVEL_LEVEL_SERIALIZABLE,
	INSTR_TSQL_DECLARE_CURSOR,
	INSTR_TSQL_CLOSE_CURSOR_ALL,
	INSTR_TSQL_CLOSE_CURSOR,
	INSTR_TSQL_MOVE_CURSOR,
	INSTR_TSQL_FETCH_CURSOR,
	INSTR_TSQL_CREATE_DOMAIN,
	INSTR_TSQL_CREATE_SCHEMA,
	INSTR_TSQL_CREATE_TABLE_IF_NOT_EXISTS,
	INSTR_TSQL_CREATE_TABLE,
	INSTR_TSQL_CREATE_TABLESPACE,
	INSTR_TSQL_DROP_TABLESPACE,
	INSTR_TSQL_ALTER_TABLESPACE,
	INSTR_TSQL_CREATE_EXTENSION,
	INSTR_TSQL_ALTER_EXTENSION,
	INSTR_TSQL_ALTER_EXTENSION_CONTENTS_STMT,
	INSTR_TSQL_CREATE_FOREIGN_DATA_WRAPPER,
	INSTR_TSQL_ALTER_FOREIGN_DATA_WRAPPER,
	INSTR_TSQL_CREATE_SERVER,
	INSTR_TSQL_ALTER_SERVER,
	INSTR_TSQL_CREATE_USER_MAPPING,
	INSTR_TSQL_ALTER_USER_MAPPING,
	INSTR_TSQL_DROP_USER_MAPPING,
	INSTR_TSQL_CREATE_FOREIGN_TABLE,
	INSTR_TSQL_IMPORT_FOREIGN_SCHEMA,
	INSTR_TSQL_DROP_TABLE,
	INSTR_TSQL_DROP_SEQUENCE,
	INSTR_TSQL_DROP_VIEW,
	INSTR_TSQL_DROP_MATERIALIZED_VIEW,
	INSTR_TSQL_DROP_INDEX,
	INSTR_TSQL_DROP_TYPE,
	INSTR_TSQL_DROP_DOMAIN,
	INSTR_TSQL_DROP_COLLATION,
	INSTR_TSQL_DROP_CONVERSION,
	INSTR_TSQL_DROP_SCHEMA,
	INSTR_TSQL_DROP_TEXT_SEARCH_PARSER,
	INSTR_TSQL_DROP_TEXT_SEARCH_DICTIONARY,
	INSTR_TSQL_DROP_TEXT_SEARCH_TEMPLATE,
	INSTR_TSQL_DROP_TEXT_SEARCH_CONFIGURATION,
	INSTR_TSQL_DROP_FOREIGN_TABLE,
	INSTR_TSQL_DROP_EXTENSION,
	INSTR_TSQL_DROP_FUNCTION,
	INSTR_TSQL_DROP_PROCEDURE,
	INSTR_TSQL_DROP_ROUTINE,
	INSTR_TSQL_DROP_AGGREGATE,
	INSTR_TSQL_DROP_OPERATOR,
	INSTR_TSQL_DROP_LANGUAGE,
	INSTR_TSQL_DROP_CAST,
	INSTR_TSQL_DROP_TRIGGER,
	INSTR_TSQL_DROP_EVENT_TRIGGER,
	INSTR_TSQL_DROP_RULE,
	INSTR_TSQL_DROP_FOREIGN_DATA_WRAPPER,
	INSTR_TSQL_DROP_SERVER,
	INSTR_TSQL_DROP_OPERATOR_CLASS,
	INSTR_TSQL_DROP_OPERATOR_FAMILY,
	INSTR_TSQL_DROP_POLICY,
	INSTR_TSQL_DROP_TRANSFORM,
	INSTR_TSQL_DROP_ACCESS_METHOD,
	INSTR_TSQL_DROP_PUBLICATION,
	INSTR_TSQL_DROP_STATISTICS,
	INSTR_TSQL_TRUNCATE_TABLE,
	INSTR_TSQL_COMMENT_STMT,
	INSTR_TSQL_SECURITY_LABEL,
	INSTR_TSQL_COPY_STMT,
	INSTR_TSQL_RENAME_STMT,
	INSTR_TSQL_ALTER_OBJECT_DEPENDS_STMT,
	INSTR_TSQL_ALTER_OBJECT_SCHEMA_STMT,
	INSTR_TSQL_ALTER_OWNER_STMT,
	INSTR_TSQL_ALTER_TABLE_MOVE_ALL_STMT,
	INSTR_TSQL_ALTER_TABLE_STMT,
	INSTR_TSQL_ALTER_DOMAIN,
	INSTR_TSQL_ALTER_FUNCTION,
	INSTR_TSQL_ALTER_PROCEDURE,
	INSTR_TSQL_ALTER_ROUTINE,
	INSTR_UNSUPPORTED_TSQL_GRANT_STMT,
	INSTR_UNSUPPORTED_TSQL_REVOKE_STMT,
	INSTR_UNSUPPORTED_TSQL_GRANT_ROLE,
	INSTR_UNSUPPORTED_TSQL_REVOKE_ROLE,
	INSTR_TSQL_ALTER_DEFAULT_PRIVILEGES,
	INSTR_TSQL_CREATE_AGGREGATE,
	INSTR_TSQL_CREATE_OPERATOR,
	INSTR_TSQL_CREATE_TYPE,
	INSTR_TSQL_CREATE_TEXT_SEARCH_PARSER,
	INSTR_TSQL_CREATE_TEXT_SEARCH_DICTIONARY,
	INSTR_TSQL_CREATE_TEXT_SEARCH_TEMPLATE,
	INSTR_TSQL_CREATE_TEXT_SEARCH_CONFIGURATION,
	INSTR_TSQL_CREATE_COLLATION,
	INSTR_TSQL_CREATE_ACCESS_METHOD,
	INSTR_TSQL_CREATE_COMPOSITE_TYPE,
	INSTR_TSQL_CREATE_ENUM_STMT,
	INSTR_TSQL_CREATE_RANGE_STMT,
	INSTR_TSQL_ALTER_ENUM,
	INSTR_TSQL_CREATE_VIEW,
	INSTR_TSQL_CREATE_PROCEDURE,
	INSTR_TSQL_CREATE_FUNCTION,
	INSTR_TSQL_CREATE_INDEX,
	INSTR_TSQL_CREATE_RULE,
	INSTR_TSQL_CREATE_SEQUENCE,
	INSTR_TSQL_ALTER_SEQUENCE,
	INSTR_TSQL_DO_STMT,
	INSTR_TSQL_CREATE_DATABASE,
	INSTR_UNSUPPORTED_TSQL_ALTER_DATABASE,
	INSTR_TSQL_DROP_DATABASE,
	INSTR_TSQL_NOTIFY_STMT,
	INSTR_TSQL_LISTEN_STMT,
	INSTR_TSQL_UNLISTEN_STMT,
	INSTR_TSQL_LOAD_STMT,
	INSTR_TSQL_CALL_STMT,
	INSTR_TSQL_CLUSTER_STMT,
	INSTR_TSQL_VACUUM_STMT,
	INSTR_TSQL_ANALYZE_STMT,
	INSTR_TSQL_EXPLAIN_STMT,
	INSTR_TSQL_SELECT_INTO,
	INSTR_TSQL_CREATE_TABLE_AS,
	INSTR_TSQL_CREATE_MATERIALIZED_VIEW,
	INSTR_TSQL_REFRESH_MATERIALIZED_VIEW,
	INSTR_TSQL_ALTER_SYSTEM,
	INSTR_TSQL_SET,
	INSTR_TSQL_RESET,
	INSTR_TSQL_VARIABLE_SHOW_STMT,
	INSTR_TSQL_DISCARD_ALL,
	INSTR_TSQL_DISCARD_PLANS,
	INSTR_TSQL_DISCARD_TEMP,
	INSTR_TSQL_DISCARD_SEQUENCES,
	INSTR_TSQL_CREATE_TRANSFORM,
	INSTR_TSQL_CREATE_TRIGGER,
	INSTR_TSQL_CREATE_EVENT_TRIGGER,
	INSTR_TSQL_ALTER_EVENT_TRIGGER,
	INSTR_TSQL_CREATE_LANGUAGE,
	INSTR_TSQL_CREATE_ROLE,
	INSTR_TSQL_ALTER_ROLE,
	INSTR_TSQL_DROP_ROLE,
	INSTR_TSQL_DROP_OWNED,
	INSTR_TSQL_REASSIGN_OWNED,
	INSTR_TSQL_LOCK_TABLE,
	INSTR_TSQL_SET_CONSTRAINTS,
	INSTR_TSQL_CHECKPOINT,
	INSTR_TSQL_REINDEX,
	INSTR_TSQL_CREATE_CONVERSION,
	INSTR_TSQL_CREATE_CAST,
	INSTR_TSQL_CREATE_OPERATOR_CLASS,
	INSTR_TSQL_CREATE_OPERATOR_FAMILY,
	INSTR_TSQL_ALTER_OPERATOR_FAMILY,
	INSTR_TSQL_ALTER_OPERATOR,
	INSTR_TSQL_ALTER_TEXT_SEARCH_DICTIONARY,
	INSTR_TSQL_ALTER_TEXT_SEARCH_CONFIGURATION,
	INSTR_TSQL_CREATE_POLICY,
	INSTR_TSQL_ALTER_POLICY,
	INSTR_TSQL_CREATE_PUBLICATION,
	INSTR_TSQL_ALTER_PUBLICATION,
	INSTR_TSQL_CREATE_SUBSCRIPTION,
	INSTR_TSQL_ALTER_SUBSCRIPTION,
	INSTR_TSQL_DROP_SUBSCRIPTION,
	INSTR_TSQL_ALTER_COLLATION,
	INSTR_TSQL_PREPARE,
	INSTR_TSQL_EXECUTE,
	INSTR_TSQL_CREATE_STATISTICS,
	INSTR_TSQL_DEALLOCATE_ALL,
	INSTR_TSQL_DEALLOCATE,
	INSTR_TSQL_SELECT_FOR_KEY_SHARE,
	INSTR_TSQL_SELECT_FOR_SHARE,
	INSTR_TSQL_SELECT_FOR_NO_KEY_UPDATE,
	INSTR_TSQL_SELECT_FOR_UPDATE,

	INSTR_TSQL_BITIN,
	INSTR_TSQL_BIT_RECV,
	INSTR_TSQL_BITOUT,
	INSTR_TSQL_BIT_SEND,
	INSTR_TSQL_INT2BIT,
	INSTR_TSQL_INT4BIT,
	INSTR_TSQL_INT8BIT,
	INSTR_TSQL_FTOBIT,
	INSTR_TSQL_DTOBIT,
	INSTR_TSQL_NUMERIC_BIT,
	INSTR_TSQL_BITNEG,
	INSTR_TSQL_BITEQ,
	INSTR_TSQL_BITNE,
	INSTR_TSQL_BITLT,
	INSTR_TSQL_BITGT,
	INSTR_TSQL_BITLE,
	INSTR_TSQL_BITGE,
	INSTR_TSQL_BIT_CMP,
	INSTR_TSQL_INT4BITEQ,
	INSTR_TSQL_INT4BITNE,
	INSTR_TSQL_INT4BITLT,
	INSTR_TSQL_INT4BITLE,
	INSTR_TSQL_INT4BITGT,
	INSTR_TSQL_INT4BITGE,
	INSTR_TSQL_BITINT4EQ,
	INSTR_TSQL_BITINT4NE,
	INSTR_TSQL_BITINT4LT,
	INSTR_TSQL_BITINT4LE,
	INSTR_TSQL_BITINT4GT,
	INSTR_TSQL_BITINT4GE,
	INSTR_TSQL_BIT2INT2,
	INSTR_TSQL_BIT2INT4,
	INSTR_TSQL_BIT2INT8,
	INSTR_TSQL_BIT2NUMERIC,
	INSTR_TSQL_BIT2FIXEDDEC,

	INSTR_TSQL_VARBINARYIN,
	INSTR_TSQL_VARBINARYOUT,
	INSTR_TSQL_VARBINARY_RECV,
	INSTR_TSQL_VARBINARY_SEND,
	INSTR_TSQL_VARCHARVARBINARY,
	INSTR_TSQL_BPCHARVARBINARY,
	INSTR_TSQL_VARBINARYVARCHAR,
	INSTR_TSQL_VARCHARBINARY,
	INSTR_TSQL_BPCHARBINARY,
	INSTR_TSQL_INT2VARBINARY,
	INSTR_TSQL_INT4VARBINARY,
	INSTR_TSQL_INT8VARBINARY,
	INSTR_TSQL_VARBINARYINT2,
	INSTR_TSQL_VARBINARYINT4,
	INSTR_TSQL_VARBINARYINT8,
	INSTR_TSQL_FLOAT4VARBINARY,
	INSTR_TSQL_FLOAT8VARBINARY,
	INSTR_TSQL_VARBINARYFLOAT4,
	INSTR_TSQL_VARBINARYFLOAT8,
	INSTR_TSQL_INT2BINARY,
	INSTR_TSQL_INT4BINARY,
	INSTR_TSQL_INT8BINARY,
	INSTR_TSQL_BINARYINT2,
	INSTR_TSQL_BINARYINT4,
	INSTR_TSQL_BINARYINT8,
	INSTR_TSQL_FLOAT4BINARY,
	INSTR_TSQL_FLOAT8BINARY,
	INSTR_TSQL_BINARYFLOAT4,
	INSTR_TSQL_BINARYFLOAT8,
	INSTR_TSQL_VARBINARY_COMPARE,
	
	INSTR_TSQL_SMALLDATETIMEIN,
	INSTR_TSQL_TIME2SMALLDATETIME,
	INSTR_TSQL_DATE2SMALLDATETIME,
	INSTR_TSQL_TIMESTAMP2SMALLDATETIME,
	INSTR_TSQL_TIMESTAMPTZ2SMALLDATETIME,
	INSTR_TSQL_SMALLDATETIME2VARCHAR,
	INSTR_TSQL_CONVERT_VARCHAR_SMALLDATETIME,
	INSTR_TSQL_CONVERT_SMALLDATETIME_CHAR,
	INSTR_TSQL_CONVERT_CHAR_SMALLDATETIME,

	INSTR_TSQL_DATETIMEIN,
	INSTR_TSQL_DATETIMEOUT,
	INSTR_TSQL_DATE2DATETIME,
	INSTR_TSQL_TIME2DATETIME,
	INSTR_TSQL_TIMESTAMP2DATETIME,
	INSTR_TSQL_TIMESTAMPTZ2DATETIME,
	INSTR_TSQL_DATETIME2VARCHAR,
	INSTR_TSQL_VARCHAR2DATETIME,
	INSTR_TSQL_DATETIME2CHAR,
	INSTR_TSQL_CHAR2DATETIME,

	INSTR_TSQL_DATETIME22VARCHAR,
	INSTR_TSQL_VARCHAR2DATETIME2,
	INSTR_TSQL_DATETIME22CHAR,
	INSTR_TSQL_CHAR2DATETIME2,

	INSTR_TSQL_SQLVARIANTIN,
	INSTR_TSQL_SQLVARIANTOUT,
	INSTR_TSQL_SQLVARIANT_RECV,
	INSTR_TSQL_SQLVARIANT_SEND,
	INSTR_TSQL_DATETIME_SQLVARIANT,
	INSTR_TSQL_DATETIME2_SQLVARIANT,
	INSTR_TSQL_SMALLDATETIME_SQLVARIANT,
	INSTR_TSQL_DATETIMEOFFSET_SQLVARIANT,
	INSTR_TSQL_DATE_SQLVARIANT,
	INSTR_TSQL_TIME_SQLVARIANT,
	INSTR_TSQL_FLOAT4_SQLVARIANT,
	INSTR_TSQL_FLOAT8_SQLVARIANT,
	INSTR_TSQL_NUMERIC_SQLVARIANT,
	INSTR_TSQL_MONEY_SQLVARIANT,
	INSTR_TSQL_SMALLMONEY_SQLVARIANT,
	INSTR_TSQL_BIGINT_SQLVARIANT,
	INSTR_TSQL_INT_SQLVARIANT,
	INSTR_TSQL_SMALLINT_SQLVARIANT,
	INSTR_TSQL_TINYINT_SQLVARIANT,
	INSTR_TSQL_BIT_SQLVARIANT,
	INSTR_TSQL_VARCHAR_SQLVARIANT,
	INSTR_TSQL_NVARCHAR_SQLVARIANT,
	INSTR_TSQL_CHAR_SQLVARIANT,
	INSTR_TSQL_NCHAR_SQLVARIANT,
	INSTR_TSQL_APGVARBINARY_SQLVARIANT,
	INSTR_TSQL_APGBINARY_SQLVARIANT,
	INSTR_TSQL_UNIQUEIDENTIFIER_SQLVARIANT,
	INSTR_TSQL_SQLVARIANT_TIMESTAMP,
	INSTR_TSQL_SQLVARIANT_DATETIMEOFFSET,
	INSTR_TSQL_SQLVARIANT_DATE,
	INSTR_TSQL_SQLVARIANT_TIME,
	INSTR_TSQL_SQLVARIANT_FLOAT4,
	INSTR_TSQL_SQLVARIANT_FLOAT8,
	INSTR_TSQL_SQLVARIANT_NUMERIC,
	INSTR_TSQL_SQLVARIANT_FIXEDDEC,
	INSTR_TSQL_SQLVARIANT_BIGINT,
	INSTR_TSQL_SQLVARIANT_INT,
	INSTR_TSQL_SQLVARIANT_SMALLINT,
	INSTR_TSQL_SQLVARIANT_BIT,
	INSTR_TSQL_SQLVARIANT_VARCHAR,
	INSTR_TSQL_SQLVARIANT_CHAR,
	INSTR_TSQL_SQLVARIANT_APGVARBINARY,
	INSTR_TSQL_SQLVARIANT_APGBINARY,
	INSTR_TSQL_SQLVARIANT_UNIQUEINDETIFIER,
	INSTR_TSQL_SQLVARIANTLT,
	INSTR_TSQL_SQLVARIANTLE,
	INSTR_TSQL_SQLVARIANTEQ,
	INSTR_TSQL_SQLVARIANTGE,
	INSTR_TSQL_SQLVARIANTGT,
	INSTR_TSQL_SQLVARIANTNE,

	INSTR_TSQL_SERVERPROPERTY_BUILDCLRVERSION,
	INSTR_TSQL_SERVERPROPERTY_COLLATION,
	INSTR_TSQL_SERVERPROPERTY_COLLATIONID,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_COMPARISON_STYLE,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_COMPUTERNAME_PHYSICAL_NETBIOS,
	INSTR_TSQL_SERVERPROPERTY_EDITION,
	INSTR_TSQL_SERVERPROPERTY_EDITIONID,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_ENGINE_EDITION,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_HADR_MANAGER_STATUS,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_INSTANCE_DEFAULT_PATH,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_INSTANCE_DEFAULT_LOG_PATH,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_INSTANCE_NAME,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_ADVANCED_ANALYTICS_INSTALLED,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_BIG_DATA_CLUSTER,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_CLUSTERED,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_FULL_TEXT_INSTALLED,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_HADR_ENABLED,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_INTEGRATED_SECURITY,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_LOCAL_DB,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_POLYBASE_INSTALLED,
	INSTR_TSQL_SERVERPROPERTY_IS_SINGLE_USER,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_IS_XTP_SUPPORTED,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_LCID,
	INSTR_UNSUPPORTED_TSQL_SERVERPROPERTY_LICENSE_TYPE,
	INSTR_TSQL_XACT_STATE,

	INSTR_TSQL_TRANCOUNT,
	INSTR_TSQL_ERROR,
	INSTR_UNSUPPORTED_TSQL_PROCID,
	INSTR_TSQL_VERSION,
	INSTR_TSQL_SERVERNAME,
	
	INSTR_UNSUPPORTED_TSQL_OPTION_ROWCOUNT,
	INSTR_TSQL_FETCH_STATUS,

	INSTR_TSQL_TRY_CATCH_BLOCK,
	INSTR_TSQL_TRY_BLOCK,
	INSTR_TSQL_CATCH_BLOCK,
	INSTR_TSQL_GOTO_STMT,

	INSTR_TSQL_INIT_TSQL_COERCE_HASH_TAB,
	INSTR_TSQL_INIT_TSQL_DATATYPE_PRECEDENCE_HASH_TAB,
	INSTR_TSQL_DTRUNCI8,
	INSTR_TSQL_DTRUNCI4,
	INSTR_TSQL_DTRUNCI2,
	INSTR_TSQL_FTRUNCI8,
	INSTR_TSQL_FTRUNCI4,
	INSTR_TSQL_FTRUNCI2,

	INSTR_TSQL_SP_EXECUTESQL,
	INSTR_TSQL_SP_PREPARE,
	INSTR_TSQL_SP_UNPREPARE,
	INSTR_TSQL_SP_GETAPPLOCK,
	INSTR_TSQL_SP_RELEASEAPPLOCK,
	INSTR_TSQL_SP_REMOVEAPPLOCKCACHE,

	INSTR_TSQL_ISOLATION_LEVEL_READ_UNCOMMITTED,
	INSTR_TSQL_ISOLATION_LEVEL_READ_COMMITTED,
	INSTR_UNSUPPORTED_TSQL_ISOLATION_LEVEL_REPEATABLE_READ,
	INSTR_TSQL_ISOLATION_LEVEL_SNAPSHOT,
	INSTR_UNSUPPORTED_TSQL_ISOLATION_LEVEL_SERIALIZABLE,

	INSTR_UNSUPPORTED_TSQL_SELECT_COL_ALIAS,
	INSTR_UNSUPPORTED_TSQL_SERVERNAME_IN_NAME,
	INSTR_UNSUPPORTED_TSQL_OPTION_NO_BROWSETABLE,
	
	INSTR_TSQL_COUNT
} PgTsqlInstrMetricType;
