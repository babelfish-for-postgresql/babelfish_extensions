/*
T-SQL (Transact-SQL, MSSQL) grammar.
The MIT License (MIT).
Copyright (c) 2017, Mark Adams (madams51703@gmail.com)
Copyright (c) 2015-2017, Ivan Kochurkin (kvanttt@gmail.com), Positive Technologies.
Copyright (c) 2016, Scott Ure (scott@redstormsoftware.com).
Copyright (c) 2016, Rui Zhang (ruizhang.ccs@gmail.com).
Copyright (c) 2016, Marcus Henriksson (kuseman80@gmail.com).
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
/*
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: Apache-2.0
*/

parser grammar TSqlParser;

options {
    tokenVocab = TSqlLexer;
}

tsql_file
    : batch_level_statement SEMI? EOF
    // some sql_cluases may start with non-reserved keyword (i.e. THROW)
    // so we should try sql_clauses first and then execute_body_batch if sql_clauses fails.
    | sql_clauses* EOF
    | execute_body_batch sql_clauses* EOF
    ;

batch_level_statement
    : create_or_alter_function
    | create_or_alter_procedure
    | create_or_alter_trigger
    | create_or_alter_view
    | SEMI
    ;

sql_clauses
    : ( dml_statement
    | cfl_statement
    | another_statement
    | ddl_statement
    | dbcc_statement
    | backup_statement
    | restore_statement
    | checkpoint_statement
    | readtext_statement
    | writetext_statement
    | updatetext_statement ) SEMI?
    | SEMI
    ;
    
// Data Manipulation Language: https://msdn.microsoft.com/en-us/library/ff848766(v=sql.120).aspx
dml_statement
    : merge_statement
    | delete_statement
    | insert_statement
//    | insert_bulk_statement
    | bulk_insert_statement
    | select_statement_standalone
    | update_statement
    ;

// Data Definition Language: https://msdn.microsoft.com/en-us/library/ff848799.aspx)
ddl_statement
    : add_signature_statement
    | alter_application_role
    | alter_assembly
    | alter_asymmetric_key
    | alter_authorization
    | alter_availability_group
    | alter_certificate
    | alter_column_encryption_key
    | alter_credential
    | alter_cryptographic_provider
    | alter_database
    | alter_database_scoped_configuration
    | alter_db_role
    | alter_external_data_source
    | alter_external_library
    | alter_external_resource_pool
    | alter_fulltext_catalog
    | alter_fulltext_index
    | alter_fulltext_stoplist
    | alter_index
    | alter_login
    | alter_materialized_view    
    | alter_master_key
    | alter_message_type
    | alter_partition_function
    | alter_partition_scheme
    | alter_queue    
    | alter_remote_service_binding
    | alter_resource_governor
    | alter_schema
    | alter_sequence
    | alter_server_audit
    | alter_server_audit_specification
    | alter_server_configuration
    | alter_server_role
    | alter_service
    | alter_service_master_key
    | alter_symmetric_key
    | alter_table
    | alter_user
    | alter_workload_group
    | alter_xml_schema_collection
    | create_aggregate
    | create_application_role
    | create_assembly
    | create_asymmetric_key
    | create_availability_group
    | create_column_encryption_key
    | create_column_master_key
    | create_contract    
    | create_credential
    | create_cryptographic_provider
    | create_database
    | create_default
    | create_db_role
    | create_diagnostic_session
    | create_event_notification
    | create_external_data_source
    | create_external_file_format
    | create_external_library
    | create_external_resource_pool
    | create_external_table    
    | create_fulltext_catalog
    | create_fulltext_index
    | create_fulltext_stoplist
    | create_index
    | create_login
    | create_materialized_view
    | create_master_key
    | create_or_alter_broker_priority
    | create_or_alter_database_audit_specification    
    | create_or_alter_endpoint
    | create_or_alter_event_session    
    | create_partition_function
    | create_partition_scheme
    | create_queue    
    | create_remote_service_binding
    | create_resource_pool
    | create_route
    | create_rule
    | create_schema
    | create_search_property_list
    | create_security_policy
    | create_sequence
    | create_server_audit
    | create_server_audit_specification
    | create_server_role
    | create_service
    | create_spatial_index    
    | create_statistics
    | create_symmetric_key
    | create_synonym
    | create_table
    | create_type
    | create_user
    | create_user_azure_sql_dw
    | create_workload_classifier
    | create_workload_group
    | create_xml_index
    | create_selective_xml_index
    | create_xml_schema_collection
    | drop_aggregate
    | drop_application_role
    | drop_assembly
    | drop_asymmetric_key
    | drop_availability_group
    | drop_broker_priority
    | drop_certificate
    | drop_column_encryption_key
    | drop_column_master_key
    | drop_contract
    | drop_credential
    | drop_cryptographic_provider
    | drop_database
    | drop_database_audit_specification
    | drop_database_encryption_key
    | drop_database_scoped_credential
    | drop_db_role
    | drop_default
    | drop_diagnostic_session    
    | drop_endpoint
    | drop_event_notification
    | drop_event_session
    | drop_external_data_source
    | drop_external_file_format
    | drop_external_library
    | drop_external_resource_pool
    | drop_external_table
    | drop_fulltext_catalog
    | drop_fulltext_index
    | drop_fulltext_stoplist
    | drop_function
    | drop_index
    | drop_login
    | drop_master_key
    | drop_message_type
    | drop_partition_function
    | drop_partition_scheme
    | drop_procedure
    | drop_queue
    | drop_remote_service_binding
    | drop_resource_pool
    | drop_route
    | drop_rule
    | drop_schema
    | drop_search_property_list
    | drop_security_policy
    | drop_sequence
    | drop_server_audit
    | drop_server_audit_specification
    | drop_server_role
    | drop_service
    | drop_signature_statement    
    | drop_statistics
    | drop_symmetric_key        
    | drop_synonym
    | drop_table
    | drop_trigger
    | drop_type
    | drop_user
    | drop_view
    | drop_workload_classifier
    | drop_workload_group
    | drop_xml_schema_collection
    | disable_trigger
    | enable_trigger
    | truncate_table
    | update_statistics
    ;

backup_statement
    : backup_database
    | backup_log
    | backup_certificate
    | backup_master_key
    | backup_service_master_key
    ;

restore_statement
    : restore_database
    ;

// Control-of-Flow Language: https://docs.microsoft.com/en-us/sql/t-sql/language-elements/control-of-flow
cfl_statement
    : block_statement
    | break_statement
    | continue_statement
    | goto_statement
    | if_statement
    | return_statement
    | throw_statement
    | try_catch_statement
    | waitfor_statement
    | while_statement
    | print_statement
    | raiseerror_statement
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/begin-end-transact-sql
block_statement
    : BEGIN SEMI? sql_clauses* END SEMI?
    ;       

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/break-transact-sql
break_statement
    : BREAK SEMI?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/continue-transact-sql
continue_statement
    : CONTINUE SEMI?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/goto-transact-sql
goto_statement
    : GOTO id SEMI?
    | id COLON SEMI?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/return-transact-sql
return_statement
    : RETURN expression? SEMI?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/if-else-transact-sql
if_statement
    : IF search_condition sql_clauses (ELSE sql_clauses)? SEMI?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/throw-transact-sql
throw_statement
    : THROW (throw_error_number COMMA throw_message COMMA throw_state)? SEMI?
    ;

throw_error_number
    : DECIMAL | LOCAL_ID
    ;

throw_message
    : char_string | LOCAL_ID
    ;

throw_state
    : DECIMAL | LOCAL_ID
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/try-catch-transact-sql
try_catch_statement
    : try_block catch_block SEMI?
    ;

try_block
	: BEGIN TRY SEMI? try_clauses=sql_clauses+ END TRY
	;

catch_block
	: BEGIN CATCH SEMI? catch_clauses=sql_clauses* END CATCH
	;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/waitfor-transact-sql
waitfor_statement
    : WAITFOR (DELAY | TIME) expression SEMI?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/while-transact-sql
while_statement
    : WHILE search_condition (sql_clauses | BREAK SEMI? | CONTINUE SEMI?)
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/print-transact-sql
print_statement
    : PRINT (expression | DOUBLE_QUOTE_ID) (COMMA LOCAL_ID)* SEMI?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/raiserror-transact-sql
raiseerror_statement
    : RAISERROR LR_BRACKET msg=raiseerror_msg COMMA severity=constant_LOCAL_ID COMMA
    state=constant_LOCAL_ID (COMMA argument+=constant_LOCAL_ID)* RR_BRACKET (WITH raiseerror_option (COMMA raiseerror_option)* )? SEMI?
    ;
	
raiseerror_msg
    : DECIMAL | char_string | local_id
    ;		
    
raiseerror_option
    : (LOG | SETERROR | NOWAIT)
    ;

another_statement
    : declare_statement
    | declare_xmlnamespaces_statement
    | execute_statement
    | cursor_statement
    | conversation_statement
    | kill_statement
    | create_message_type
    | security_statement
    | set_statement
    | transaction_statement
    | use_statement
    | setuser_statement
    | reconfigure_statement
    | shutdown_statement
    ;
    
// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-application-role-transact-sql
alter_application_role
    : ALTER APPLICATION ROLE appliction_role=id WITH  (COMMA? NAME EQUAL new_application_role_name=id)? (COMMA? PASSWORD EQUAL application_role_password=char_string)? (COMMA? DEFAULT_SCHEMA EQUAL app_role_default_schema=id)?
    ;

create_application_role
    : CREATE APPLICATION ROLE appliction_role=id WITH   (COMMA? PASSWORD EQUAL application_role_password=char_string)? (COMMA? DEFAULT_SCHEMA EQUAL app_role_default_schema=id)?
    ;

create_aggregate
    : CREATE AGGREGATE func_proc_name_schema LR_BRACKET procedure_param (COMMA procedure_param)* RR_BRACKET
      RETURNS data_type external_name SEMI?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-aggregate-transact-sql
drop_aggregate
    : DROP AGGREGATE if_exists? ( schema_name=id DOT )? aggregate_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-application-role-transact-sql
drop_application_role
    : DROP APPLICATION ROLE rolename=id
    ;

alter_assembly
    : ALTER ASSEMBLY assembly_name=id alter_assembly_clause
    ;

alter_assembly_clause
    : (FROM expression)? (WITH assembly_option (COMMA assembly_option)*)? alter_assembly_drop_clause? alter_assembly_add_clause?
    ;

alter_assembly_drop_clause
    : DROP FILE ((char_string|id) (COMMA (char_string|id))* | ALL)
    ;

alter_assembly_add_clause
    : ADD FILE FROM alter_assembly_client_file_clause (COMMA alter_assembly_client_file_clause)*
    ;

alter_assembly_client_file_clause
    :  (expression|id) (AS (id|char_string))?
    ;

assembly_option
    : PERMISSION_SET EQUAL (SAFE|EXTERNAL_ACCESS|UNSAFE)
    | VISIBILITY EQUAL (ON | OFF)
    | UNCHECKED DATA
    ;

network_file_share
    : DOUBLE_BACK_SLASH computer_name=id file_path
    ;

file_path
    : BACKSLASH file_path
    | id
    ;

local_file
    : local_drive file_path
    ;

local_drive
    : DISK_DRIVE
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-assembly-transact-sql
create_assembly
    : CREATE ASSEMBLY assembly_name=id (AUTHORIZATION owner_name=id)?
       FROM (COMMA? (char_string|hex_string) (AS id)? )+
       (WITH PERMISSION_SET EQUAL (SAFE|EXTERNAL_ACCESS|UNSAFE) )?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-assembly-transact-sql
drop_assembly
    : DROP ASSEMBLY if_exists? (COMMA? assembly_name=id)+
       ( WITH NO DEPENDENTS )?
    ;
    
// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-asymmetric-key-transact-sql
alter_asymmetric_key
    : ALTER ASYMMETRIC KEY Asym_Key_Name=id (asymmetric_key_option | REMOVE PRIVATE KEY )
    ;
    
asymmetric_key_option
    : WITH PRIVATE KEY LR_BRACKET asymmetric_key_password_change_option ( COMMA asymmetric_key_password_change_option)? RR_BRACKET
    ;

asymmetric_key_password_change_option
    : (ENCRYPTION|DECRYPTION) BY PASSWORD EQUAL char_string
    ;

//https://docs.microsoft.com/en-us/sql/t-sql/statements/create-asymmetric-key-transact-sql
create_asymmetric_key
    : CREATE ASYMMETRIC KEY Asym_Key_Nam=id
       (AUTHORIZATION database_principal_name=id)?
       ( FROM (FILE EQUAL char_string |EXECUTABLE_FILE EQUAL char_string|ASSEMBLY Assembly_Name=id | PROVIDER Provider_Name=id) )?
       (WITH (ALGORITHM EQUAL ( RSA_4096 | RSA_3072 | RSA_2048 | RSA_1024 | RSA_512)  |PROVIDER_KEY_NAME EQUAL provider_key_name=char_string | CREATION_DISPOSITION EQUAL (CREATE_NEW|OPEN_EXISTING)  )   )?
       (ENCRYPTION BY PASSWORD EQUAL asymmetric_key_password=char_string )?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-asymmetric-key-transact-sql
drop_asymmetric_key
    : DROP ASYMMETRIC KEY key_name=id ( REMOVE PROVIDER KEY )?
    ;

create_materialized_view   //Azure
    : CREATE MATERIALIZED VIEW simple_name WITH LR_BRACKET DISTRIBUTION EQUAL (ROUND_ROBIN | HASH LR_BRACKET id RR_BRACKET) (COMMA FOR_APPEND)? RR_BRACKET AS select_statement_standalone
    ;
    
alter_materialized_view
    : ALTER MATERIALIZED VIEW simple_name (REBUILD | DISABLE)
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-authorization-transact-sql
alter_authorization
    : ALTER AUTHORIZATION ON (object_type colon_colon)? entity=entity_name TO authorization_grantee
    ;

authorization_grantee
    : principal_name=id
    | SCHEMA OWNER
    ;

colon_colon
    : COLON COLON
    ;

create_availability_group
    : CREATE AVAILABILITY GROUP group_name=id WITH .+? EOF   // quick & dirty, good enough for now
    ;
    
// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-availability-group-transact-sql
drop_availability_group
    : DROP AVAILABILITY GROUP group_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-availability-group-transact-sql
alter_availability_group
    : ALTER AVAILABILITY GROUP group_name=id alter_availability_group_options
    ;

alter_availability_group_options
    : SET LR_BRACKET ( ( AUTOMATED_BACKUP_PREFERENCE EQUAL ( PRIMARY | SECONDARY_ONLY| SECONDARY | NONE )  | FAILURE_CONDITION_LEVEL  EQUAL DECIMAL   | HEALTH_CHECK_TIMEOUT EQUAL milliseconds=DECIMAL  | DB_FAILOVER  EQUAL ( ON | OFF )   | REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT EQUAL DECIMAL ) RR_BRACKET )
    | ADD DATABASE database_name=id
    | REMOVE DATABASE database_name=id
    | ADD REPLICA ON server_instance=char_string (WITH LR_BRACKET ( (ENDPOINT_URL EQUAL char_string)?   (COMMA? AVAILABILITY_MODE EQUAL (SYNCHRONOUS_COMMIT| ASYNCHRONOUS_COMMIT))?    (COMMA? FAILOVER_MODE EQUAL (AUTOMATIC|MANUAL) )?  (COMMA?   SEEDING_MODE EQUAL (AUTOMATIC|MANUAL) )?  (COMMA?  BACKUP_PRIORITY EQUAL DECIMAL)?  ( COMMA? PRIMARY_ROLE LR_BRACKET ALLOW_CONNECTIONS EQUAL ( READ_WRITE | ALL ) RR_BRACKET)?   ( COMMA? SECONDARY_ROLE LR_BRACKET ALLOW_CONNECTIONS EQUAL ( READ_ONLY  ) RR_BRACKET )? )
) RR_BRACKET
        |SECONDARY_ROLE LR_BRACKET (ALLOW_CONNECTIONS EQUAL (NO|READ_ONLY|ALL) | READ_ONLY_ROUTING_LIST EQUAL ( LR_BRACKET ( ( char_string) ) RR_BRACKET ) )
        |PRIMARY_ROLE LR_BRACKET (ALLOW_CONNECTIONS EQUAL (NO|READ_ONLY|ALL) | READ_ONLY_ROUTING_LIST EQUAL ( LR_BRACKET ( (COMMA? char_string)*|NONE ) RR_BRACKET )
        | SESSION_TIMEOUT EQUAL session_timeout=DECIMAL
)
    | MODIFY REPLICA ON server_instance=char_string (WITH LR_BRACKET (ENDPOINT_URL EQUAL char_string|  AVAILABILITY_MODE EQUAL (SYNCHRONOUS_COMMIT| ASYNCHRONOUS_COMMIT)  | FAILOVER_MODE EQUAL (AUTOMATIC|MANUAL) |   SEEDING_MODE EQUAL (AUTOMATIC|MANUAL)  |  BACKUP_PRIORITY EQUAL DECIMAL  )
        |SECONDARY_ROLE LR_BRACKET (ALLOW_CONNECTIONS EQUAL (NO|READ_ONLY|ALL) | READ_ONLY_ROUTING_LIST EQUAL ( LR_BRACKET ( ( char_string) ) RR_BRACKET ) )
        |PRIMARY_ROLE LR_BRACKET (ALLOW_CONNECTIONS EQUAL (NO|READ_ONLY|ALL) | READ_ONLY_ROUTING_LIST EQUAL ( LR_BRACKET ( (COMMA? char_string)*|NONE ) RR_BRACKET )
         | SESSION_TIMEOUT EQUAL session_timeout=DECIMAL
)   ) RR_BRACKET
    | REMOVE REPLICA ON char_string
    | JOIN
    | JOIN AVAILABILITY GROUP ON (COMMA? ag_name=char_string WITH LR_BRACKET ( LISTENER_URL EQUAL char_string COMMA AVAILABILITY_MODE EQUAL (SYNCHRONOUS_COMMIT|ASYNCHRONOUS_COMMIT) COMMA FAILOVER_MODE EQUAL MANUAL COMMA SEEDING_MODE EQUAL (AUTOMATIC|MANUAL) RR_BRACKET ) )+
     | MODIFY AVAILABILITY GROUP ON (COMMA? ag_name_modified=char_string WITH LR_BRACKET (LISTENER_URL EQUAL char_string  (COMMA? AVAILABILITY_MODE EQUAL (SYNCHRONOUS_COMMIT|ASYNCHRONOUS_COMMIT) )? (COMMA? FAILOVER_MODE EQUAL MANUAL )? (COMMA? SEEDING_MODE EQUAL (AUTOMATIC|MANUAL))? RR_BRACKET ) )+
    |GRANT CREATE ANY DATABASE
    | DENY CREATE ANY DATABASE
    | FAILOVER
    | FORCE_FAILOVER_ALLOW_DATA_LOSS
    | ADD LISTENER listener_name=char_string LR_BRACKET ( WITH DHCP (ON LR_BRACKET ip_v4_failover ip_v4_failover RR_BRACKET ) | WITH IP LR_BRACKET (    (COMMA? LR_BRACKET ( ip_v4_failover COMMA  ip_v4_failover | ip_v6_failover ) RR_BRACKET)+ RR_BRACKET (COMMA PORT EQUAL DECIMAL)? ) ) RR_BRACKET
    | MODIFY LISTENER (ADD IP LR_BRACKET (ip_v4_failover ip_v4_failover | ip_v6_failover) RR_BRACKET | PORT EQUAL DECIMAL )
    |RESTART LISTENER char_string
    |REMOVE LISTENER char_string
    |OFFLINE
    | WITH LR_BRACKET DTC_SUPPORT EQUAL PER_DB RR_BRACKET
    ;

ip_v4_failover
    : char_string
    ;

ip_v6_failover
    : char_string
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-broker-priority-transact-sql
// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-broker-priority-transact-sql
create_or_alter_broker_priority
    : (CREATE | ALTER) BROKER PRIORITY ConversationPriorityName=id FOR CONVERSATION
      SET LR_BRACKET
     ( CONTRACT_NAME EQUAL ( ( id) | ANY )  COMMA?  )?
     ( LOCAL_SERVICE_NAME EQUAL (DOUBLE_FORWARD_SLASH? id | ANY ) COMMA? )?
     ( REMOTE_SERVICE_NAME  EQUAL (RemoteServiceName=char_string | ANY ) COMMA? )?
     ( PRIORITY_LEVEL EQUAL ( PriorityValue=DECIMAL | DEFAULT ) )?
 RR_BRACKET
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-broker-priority-transact-sql
drop_broker_priority
    : DROP BROKER PRIORITY ConversationPriorityName=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-certificate-transact-sql
alter_certificate
    : ALTER CERTIFICATE certificate_name=id (REMOVE PRIVATE_KEY | WITH PRIVATE KEY LR_BRACKET ( FILE EQUAL char_string COMMA? | DECRYPTION BY PASSWORD EQUAL char_string COMMA?| ENCRYPTION BY PASSWORD EQUAL char_string  COMMA?)+ RR_BRACKET | WITH ACTIVE FOR BEGIN_DIALOG EQUAL ( ON | OFF ) )
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-column-encryption-key-transact-sql
alter_column_encryption_key
    : ALTER COLUMN ENCRYPTION KEY column_encryption_key=id (ADD | DROP) VALUE LR_BRACKET COLUMN_MASTER_KEY EQUAL column_master_key_name=id ( COMMA ALGORITHM EQUAL algorithm_name=char_string  COMMA ENCRYPTED_VALUE EQUAL hex_string)? RR_BRACKET
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-column-encryption-key-transact-sql
create_column_encryption_key
    :   CREATE COLUMN ENCRYPTION KEY column_encryption_key=id
         WITH VALUES
           (LR_BRACKET COMMA? COLUMN_MASTER_KEY EQUAL column_master_key_name=id COMMA
           ALGORITHM EQUAL algorithm_name=char_string  COMMA
           ENCRYPTED_VALUE EQUAL encrypted_value=hex_string RR_BRACKET COMMA?)+
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-certificate-transact-sql
drop_certificate
    : DROP CERTIFICATE certificate_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-column-encryption-key-transact-sql
drop_column_encryption_key
    : DROP COLUMN ENCRYPTION KEY key_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-column-master-key-transact-sql
drop_column_master_key
    : DROP COLUMN MASTER KEY key_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-contract-transact-sql
drop_contract
    : DROP CONTRACT dropped_contract_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-credential-transact-sql
drop_credential
    : DROP CREDENTIAL credential_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-cryptographic-provider-transact-sql
drop_cryptographic_provider
    : DROP CRYPTOGRAPHIC PROVIDER provider_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-database-transact-sql
drop_database
    : DROP DATABASE if_exists? id (COMMA id)*
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-database-audit-specification-transact-sql
drop_database_audit_specification
    : DROP DATABASE AUDIT SPECIFICATION audit_specification_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-database-encryption-key-transact-sql?view=sql-server-ver15
drop_database_encryption_key
    : DROP DATABASE ENCRYPTION KEY
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-database-scoped-credential-transact-sql
drop_database_scoped_credential
   : DROP DATABASE SCOPED CREDENTIAL credential_name=id
   ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-default-transact-sql
drop_default
    : DROP DEFAULT if_exists? simple_name (COMMA simple_name)*
    ;

drop_diagnostic_session
    : DROP DIAGNOSTICS SESSION session_name=ID SEMI
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-endpoint-transact-sql
drop_endpoint
    : DROP ENDPOINT endPointName=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-external-data-source-transact-sql
drop_external_data_source
    : DROP EXTERNAL DATA SOURCE external_data_source_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-external-file-format-transact-sql
drop_external_file_format
    : DROP EXTERNAL FILE FORMAT external_file_format_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-external-library-transact-sql
drop_external_library
    : DROP EXTERNAL LIBRARY library_name=id
( AUTHORIZATION owner_name=id )?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-external-resource-pool-transact-sql
drop_external_resource_pool
    : DROP EXTERNAL RESOURCE POOL pool_name=id
    ;

create_external_table
    : CREATE EXTERNAL TABLE table_name LR_BRACKET column_definition (COMMA column_definition)* COMMA? RR_BRACKET 
      WITH LR_BRACKET external_table_option (COMMA external_table_option)* RR_BRACKET 
      SEMI?
    ;

external_table_option
    : id EQUAL expression
    ;               

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-external-table-transact-sql
drop_external_table
    : DROP EXTERNAL TABLE table_name SEMI?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-event-notification-transact-sql
drop_event_notification
    : DROP EVENT NOTIFICATION (COMMA? notification_name=id)+
        ON (SERVER|DATABASE|QUEUE queue_name=id)
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-event-session-transact-sql
drop_event_session
    : DROP EVENT SESSION event_session_name=id
        ON SERVER
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-fulltext-catalog-transact-sql
drop_fulltext_catalog
    : DROP FULLTEXT CATALOG catalog_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-fulltext-index-transact-sql
drop_fulltext_index
    : DROP FULLTEXT INDEX ON table_name
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-fulltext-stoplist-transact-sql
drop_fulltext_stoplist
    : DROP FULLTEXT STOPLIST stoplist_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-login-transact-sql
drop_login
    : DROP LOGIN login_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-master-key-transact-sql
drop_master_key
    : DROP MASTER KEY
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-message-type-transact-sql
drop_message_type
    : DROP MESSAGE TYPE message_type_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-partition-function-transact-sql
drop_partition_function
    : DROP PARTITION FUNCTION partition_function_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-partition-scheme-transact-sql
drop_partition_scheme
    : DROP PARTITION SCHEME partition_scheme_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-queue-transact-sql
drop_queue
    : DROP QUEUE (database_name=id DOT)? (schema_name=id DOT)? queue_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-remote-service-binding-transact-sql
drop_remote_service_binding
    : DROP REMOTE SERVICE BINDING binding_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-resource-pool-transact-sql
drop_resource_pool
    : DROP RESOURCE POOL pool_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-role-transact-sql
drop_db_role
    : DROP ROLE if_exists? role_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-route-transact-sql
drop_route
    : DROP ROUTE route_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-rule-transact-sql
drop_rule
    : DROP RULE if_exists? simple_name (COMMA simple_name)*
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-schema-transact-sql
drop_schema
    :  DROP SCHEMA if_exists? schema_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-search-property-list-transact-sql
drop_search_property_list
    : DROP SEARCH PROPERTY LIST property_list_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-security-policy-transact-sql
drop_security_policy
    : DROP SECURITY POLICY if_exists? (schema_name=id DOT )? security_policy_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-sequence-transact-sql
drop_sequence
    : DROP SEQUENCE if_exists? full_object_name (COMMA full_object_name)*
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-server-audit-transact-sql
drop_server_audit
    : DROP SERVER AUDIT audit_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-server-audit-specification-transact-sql
drop_server_audit_specification
    : DROP SERVER AUDIT SPECIFICATION audit_specification_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-server-role-transact-sql
drop_server_role
    : DROP SERVER ROLE role_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-service-transact-sql
drop_service
    : DROP SERVICE dropped_service_name=id
    ;

add_signature_statement
    : ADD COUNTER? SIGNATURE TO (object_type colon_colon)? full_object_name BY signature_item (COMMA signature_item)* SEMI?
    ;

signature_item
    : (CERTIFICATE|ASYMMETRIC KEY) name=id (WITH PASSWORD EQUAL char_string | WITH SIGNATURE EQUAL hex_string)?
    ;                          
    
// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-signature-transact-sql
drop_signature_statement
    : DROP COUNTER? SIGNATURE FROM (schema_name=id DOT)? module_name=id
        BY (COMMA?  CERTIFICATE cert_name=id
           | COMMA? ASYMMETRIC KEY Asym_key_name=id
           )+
      SEMI?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-symmetric-key-transact-sql
drop_symmetric_key
    : DROP SYMMETRIC KEY symmetric_key_name=id (REMOVE PROVIDER KEY)?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-synonym-transact-sql
drop_synonym
    : DROP SYNONYM if_exists? simple_name
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-user-transact-sql
drop_user
    : DROP USER if_exists? user_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-workload-group-transact-sql
drop_workload_group
    : DROP WORKLOAD GROUP group_name=id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-xml-schema-collection-transact-sql
drop_xml_schema_collection
    : DROP XML SCHEMA COLLECTION simple_name
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/disable-trigger-transact-sql
disable_trigger
    : DISABLE TRIGGER ( ( COMMA? schema_trigger_name )+ | ALL)         ON (tabname=table_name|DATABASE|ALL SERVER)
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/enable-trigger-transact-sql
enable_trigger
    : ENABLE TRIGGER ( ( COMMA? schema_trigger_name )+ | ALL)         ON (tabname=table_name|DATABASE|ALL SERVER)
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/truncate-table-transact-sql
truncate_table
    : TRUNCATE TABLE table_name
          ( WITH LR_BRACKET
              PARTITIONS LR_BRACKET
                                (COMMA? ((DECIMAL|LOCAL_ID)|(DECIMAL|LOCAL_ID) TO (DECIMAL|LOCAL_ID)) )+
                         RR_BRACKET
                 RR_BRACKET
          )?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-column-master-key-transact-sql
create_column_master_key
    : CREATE COLUMN MASTER KEY key_name=id
         WITH LR_BRACKET
            KEY_STORE_PROVIDER_NAME EQUAL  key_store_provider_name=char_string COMMA
            KEY_PATH EQUAL key_path=char_string
 RR_BRACKET
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-credential-transact-sql
alter_credential
    : ALTER CREDENTIAL credential_name=id
        WITH IDENTITY EQUAL identity_name=char_string
         ( COMMA SECRET EQUAL secret=char_string )?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-credential-transact-sql
create_credential
    : CREATE CREDENTIAL credential_name=id
        WITH IDENTITY EQUAL identity_name=char_string
         ( COMMA SECRET EQUAL secret=char_string )?
         (  FOR CRYPTOGRAPHIC PROVIDER cryptographic_provider_name=id )?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-cryptographic-provider-transact-sql
alter_cryptographic_provider
    : ALTER CRYPTOGRAPHIC PROVIDER provider_name=id (FROM FILE EQUAL crypto_provider_ddl_file=char_string)? (ENABLE | DISABLE)?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-cryptographic-provider-transact-sql
create_cryptographic_provider
    : CREATE CRYPTOGRAPHIC PROVIDER provider_name=id
      FROM FILE EQUAL path_of_DLL=char_string
    ;
    
// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-event-notification-transact-sql
create_event_notification
    : CREATE EVENT NOTIFICATION event_notification_name=id
      ON (SERVER|DATABASE|QUEUE queue_name=id)
        (WITH FAN_IN)?
        FOR (COMMA? event_type_or_group=id)+
          TO SERVICE  broker_service=char_string  COMMA
             broker_service_specifier_or_current_database=char_string
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-event-session-transact-sql
// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-event-session-transact-sql
create_or_alter_event_session
    : (CREATE | ALTER) EVENT SESSION event_session_name=id ON SERVER
       (COMMA? ADD EVENT ( (event_module_guid=id DOT)? event_package_name=id DOT event_name=id)
        (LR_BRACKET
          (SET ( COMMA? event_customizable_attributue=id EQUAL expression )* )?
          ( ACTION LR_BRACKET (COMMA? (event_module_guid=id DOT)? event_package_name=id DOT action_name=id)+ RR_BRACKET)+
          (WHERE event_session_predicate_expression)?
 RR_BRACKET )*
      )*
      (COMMA? DROP EVENT (event_module_guid=id DOT)? event_package_name=id DOT event_name=id )*

      ( (ADD TARGET (event_module_guid=id DOT)? event_package_name=id DOT target_name=id ) ( LR_BRACKET SET (COMMA? target_parameter_name=id EQUAL (LR_BRACKET? DECIMAL RR_BRACKET? |char_string) )+ RR_BRACKET )* )*
       (DROP TARGET (event_module_guid=id DOT)? event_package_name=id DOT target_name=id )*


     (WITH
 LR_BRACKET
           (COMMA? MAX_MEMORY EQUAL max_memory=DECIMAL (KB|MB) )?
           (COMMA? EVENT_RETENTION_MODE EQUAL (ALLOW_SINGLE_EVENT_LOSS | ALLOW_MULTIPLE_EVENT_LOSS | NO_EVENT_LOSS ) )?
           (COMMA? MAX_DISPATCH_LATENCY EQUAL (max_dispatch_latency_seconds=DECIMAL SECONDS | INFINITE) )?
           (COMMA?  MAX_EVENT_SIZE EQUAL max_event_size=DECIMAL (KB|MB) )?
           (COMMA? MEMORY_PARTITION_MODE EQUAL (NONE | PER_NODE | PER_CPU) )?
           (COMMA? TRACK_CAUSALITY EQUAL (ON|OFF) )?
           (COMMA? STARTUP_STATE EQUAL (ON|OFF) )?
 RR_BRACKET
     )?
     (STATE EQUAL (START|STOP) )?
    ;

event_session_predicate_expression
    : ( COMMA? (AND|OR)? NOT? ( event_session_predicate_factor | LR_BRACKET event_session_predicate_expression RR_BRACKET) )+
    ;

event_session_predicate_factor
    : event_session_predicate_leaf
    | LR_BRACKET event_session_predicate_expression RR_BRACKET
    ;

event_session_predicate_leaf
    : (event_field_name=id | (event_field_name=id |( ((event_module_guid=id DOT)?  event_package_name=id DOT)? predicate_source_name=id ) ) (EQUAL |(LESS GREATER) | (EXCLAMATION EQUAL) | GREATER  | (GREATER EQUAL)| LESS | LESS EQUAL) expression )
    | (event_module_guid=id DOT)?  event_package_name=id DOT predicate_compare_name=id LR_BRACKET (event_field_name=id |( ((event_module_guid=id DOT)?  event_package_name=id DOT)? predicate_source_name=id ) COMMA  expression ) RR_BRACKET
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-external-data-source-transact-sql
alter_external_data_source
    : ALTER EXTERNAL DATA SOURCE data_source_name=id  SET
    ( external_data_source_attribute |  CREDENTIAL EQUAL credential_name=id )+
    | ALTER EXTERNAL DATA SOURCE data_source_name=id WITH LR_BRACKET TYPE EQUAL BLOB_STORAGE COMMA LOCATION EQUAL location=char_string (COMMA CREDENTIAL EQUAL credential_name=id )? RR_BRACKET
    ;

create_external_data_source
    : CREATE EXTERNAL DATA SOURCE data_source_name=id WITH LR_BRACKET external_data_source_attribute* RR_BRACKET
    ;
 
external_data_source_attribute
    : LOCATION EQUAL location=char_string COMMA?
    | RESOURCE_MANAGER_LOCATION EQUAL resource_manager_location=char_string COMMA?
    | TYPE EQUAL ID COMMA?
    ;
    
create_external_file_format
    : CREATE EXTERNAL FILE FORMAT external_file_format_name=id WITH LR_BRACKET 
          FORMAT_TYPE EQUAL id 
          (COMMA FORMAT_OPTIONS LR_BRACKET external_file_format_option (COMMA external_file_format_option)* RR_BRACKET)?
          (COMMA DATA_COMPRESSION EQUAL char_string)?
      RR_BRACKET SEMI
    ;
 
external_file_format_option
    : FIELD_TERMINATOR EQUAL char_string
    | STRING_DELIMITER EQUAL char_string
    | FIRST_ROW EQUAL DECIMAL
    | DATE_FORMAT EQUAL char_string
    | USE_TYPE_DEFAULT EQUAL (TRUE | FALSE)
    | ENCODING EQUAL char_string
    ;
    
// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-external-library-transact-sql
alter_external_library
    : ALTER EXTERNAL LIBRARY library_name=id (AUTHORIZATION owner_name=id)?
       (SET|ADD) ( LR_BRACKET CONTENT EQUAL (client_library=char_string | hex_string | NONE) (COMMA PLATFORM EQUAL (WINDOWS|LINUX)? RR_BRACKET) WITH (COMMA? LANGUAGE EQUAL (R|PYTHON) | DATA_SOURCE EQUAL external_data_source_name=id )+ RR_BRACKET )
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-external-library-transact-sql
create_external_library
    : CREATE EXTERNAL LIBRARY library_name=id (AUTHORIZATION owner_name=id)?
       FROM (COMMA? LR_BRACKET?  (CONTENT EQUAL)? (client_library=char_string | hex_string | NONE) (COMMA PLATFORM EQUAL (WINDOWS|LINUX)? RR_BRACKET)? ) ( WITH (COMMA? LANGUAGE EQUAL (R|PYTHON) | DATA_SOURCE EQUAL external_data_source_name=id )+ RR_BRACKET )?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-external-resource-pool-transact-sql
alter_external_resource_pool
    : ALTER EXTERNAL RESOURCE POOL (pool_name=id | DEFAULT_DOUBLE_QUOTE) WITH LR_BRACKET MAX_CPU_PERCENT EQUAL max_cpu_percent=DECIMAL ( COMMA? AFFINITY CPU EQUAL (AUTO|(COMMA? DECIMAL TO DECIMAL |COMMA DECIMAL )+ ) | NUMANODE EQUAL (COMMA? DECIMAL TO DECIMAL| COMMA? DECIMAL )+  ) (COMMA? MAX_MEMORY_PERCENT EQUAL max_memory_percent=DECIMAL)? (COMMA? MAX_PROCESSES EQUAL max_processes=DECIMAL)? RR_BRACKET
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-external-resource-pool-transact-sql
create_external_resource_pool
    : CREATE EXTERNAL RESOURCE POOL pool_name=id  WITH LR_BRACKET MAX_CPU_PERCENT EQUAL max_cpu_percent=DECIMAL ( COMMA? AFFINITY CPU EQUAL (AUTO|(COMMA? DECIMAL TO DECIMAL |COMMA DECIMAL )+ ) | NUMANODE EQUAL (COMMA? DECIMAL TO DECIMAL| COMMA? DECIMAL )+  ) (COMMA? MAX_MEMORY_PERCENT EQUAL max_memory_percent=DECIMAL)? (COMMA? MAX_PROCESSES EQUAL max_processes=DECIMAL)? RR_BRACKET
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-fulltext-catalog-transact-sql
alter_fulltext_catalog
    : ALTER FULLTEXT CATALOG catalog_name=id (REBUILD (WITH ACCENT_SENSITIVITY EQUAL (ON|OFF) )? | REORGANIZE | AS DEFAULT )
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-fulltext-catalog-transact-sql
create_fulltext_catalog
    : CREATE FULLTEXT CATALOG catalog_name=id
        (ON FILEGROUP filegroup=id)?
        (IN PATH rootpath=char_string)?
        (WITH ACCENT_SENSITIVITY EQUAL (ON|OFF) )?
        (AS DEFAULT)?
        (AUTHORIZATION owner_name=id)?
    ;

create_fulltext_index
    : CREATE FULLTEXT INDEX ON table_name (LR_BRACKET fulltext_index_column (COMMA fulltext_index_column)* RR_BRACKET)? KEY INDEX id (ON catalog_filegroup_option)? (WITH fulltext_with_option (COMMA fulltext_with_option)* )?
    ;

fulltext_index_column
    : full_column_name (TYPE COLUMN full_column_name)? (LANGUAGE (char_string|DECIMAL|hex_string))? STATISTICAL_SEMANTICS?
    ;

catalog_filegroup_option
    : LR_BRACKET catalog_filegroup_option RR_BRACKET 
    | catalog_name=id (COMMA FILEGROUP filegroup_name=id)?
    | FILEGROUP filegroup_name=id (COMMA catalog_name=id)?
    ;

fulltext_with_option
    : LR_BRACKET fulltext_with_option (COMMA fulltext_with_option)* RR_BRACKET
    | CHANGE_TRACKING EQUAL? ( MANUAL | AUTO | OFF (COMMA NO POPULATION)? )
    | STOPLIST EQUAL? ( OFF | SYSTEM | stoplist_name=id )
    | SEARCH PROPERTY LIST EQUAL? property_list_name=id
    ;

alter_fulltext_index
    : ALTER FULLTEXT INDEX ON table_name alter_fulltext_index_option
    ;

alter_fulltext_index_option
    : ( ENABLE | DISABLE )
    |  CHANGE_TRACKING EQUAL? ( MANUAL | AUTO | OFF )
    | ADD LR_BRACKET fulltext_index_column (COMMA fulltext_index_column)* RR_BRACKET alter_fulltext_index_no_population?
    | ALTER COLUMN full_column_name ( ADD | DROP ) STATISTICAL_SEMANTICS  alter_fulltext_index_no_population?
    | DROP LR_BRACKET full_column_name (COMMA full_column_name)* RR_BRACKET alter_fulltext_index_no_population?
    | START ( FULL | INCREMENTAL | UPDATE ) POPULATION
    | ( STOP | PAUSE | RESUME ) POPULATION
    | SET STOPLIST EQUAL? ( OFF | SYSTEM | stoplist_name=id ) alter_fulltext_index_no_population?
    | SEARCH PROPERTY LIST EQUAL? ( OFF | property_list_name=id ) alter_fulltext_index_no_population?
    ;

alter_fulltext_index_no_population
    : WITH NO POPULATION
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-fulltext-stoplist-transact-sql
alter_fulltext_stoplist
    : ALTER FULLTEXT STOPLIST stoplist_name=id (ADD stopword=char_string LANGUAGE (char_string|DECIMAL|hex_string) | DROP ( stopword=char_string LANGUAGE (char_string|DECIMAL|hex_string) |ALL (char_string|DECIMAL|hex_string) | ALL ) )
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-fulltext-stoplist-transact-sql
create_fulltext_stoplist
    :   CREATE FULLTEXT STOPLIST stoplist_name=id
          (FROM ( (database_name=id DOT)? source_stoplist_name=id |SYSTEM STOPLIST ) )?
          (AUTHORIZATION owner_name=id)?
    ;

alter_login
    : ALTER LOGIN login_name=id
       ( (ENABLE|DISABLE)  
         | WITH alter_login_set_option (COMMA alter_login_set_option)*
         | (ADD|DROP) CREDENTIAL credential_name=id )
    ;

alter_login_set_option
    : PASSWORD EQUAL ( password=char_string | password_hash=hex_string HASHED ) 
        ( (MUST_CHANGE|UNLOCK)+ 
          | OLD_PASSWORD EQUAL old_password=char_string )?
    | DEFAULT_DATABASE EQUAL default_database=id
    | DEFAULT_LANGUAGE EQUAL (id | char_string | DECIMAL)
    | NAME EQUAL login_name=id
    | CHECK_POLICY EQUAL (ON|OFF)
    | CHECK_EXPIRATION EQUAL (ON|OFF)
    | CREDENTIAL EQUAL credential_name=id
    | NO CREDENTIAL
    ;

create_login
    : CREATE LOGIN login_name=id 
        ( WITH PASSWORD EQUAL ( password=char_string | password_hash=hex_string HASHED ) MUST_CHANGE? (COMMA create_login_option_list)* 
          | FROM 
            ( WINDOWS (WITH create_login_windows_options (COMMA create_login_windows_options)* )?
              | CERTIFICATE certname=id
              | ASYMMETRIC KEY asym_key_name=id ) )
    ;

create_login_option_list
    : SID EQUAL sid=hex_string
    | DEFAULT_DATABASE EQUAL default_database=id
    | DEFAULT_LANGUAGE EQUAL (id | char_string | DECIMAL)
    | CHECK_EXPIRATION EQUAL (ON|OFF)
    | CHECK_POLICY EQUAL (ON|OFF)
    | CREDENTIAL EQUAL credential_name=id
    ;

create_login_windows_options
    : DEFAULT_DATABASE EQUAL default_database=id
    | DEFAULT_LANGUAGE EQUAL (id | char_string | DECIMAL)
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-master-key-transact-sql
alter_master_key
    : ALTER MASTER KEY ( (FORCE)? REGENERATE WITH ENCRYPTION BY PASSWORD EQUAL password=char_string |(ADD|DROP) ENCRYPTION BY (SERVICE MASTER KEY | PASSWORD EQUAL encryption_password=char_string) )
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-master-key-transact-sql
create_master_key
    : CREATE MASTER KEY ENCRYPTION BY PASSWORD EQUAL password=char_string
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-message-type-transact-sql
alter_message_type
    : ALTER MESSAGE TYPE message_type_name=id VALIDATION EQUAL (NONE | EMPTY | WELL_FORMED_XML | VALID_XML WITH SCHEMA COLLECTION schema_collection_name=id)
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-partition-function-transact-sql
alter_partition_function
    : ALTER PARTITION FUNCTION partition_function_name=id LR_BRACKET RR_BRACKET (SPLIT|MERGE) RANGE LR_BRACKET expression RR_BRACKET
    ;

create_partition_function
    : CREATE PARTITION FUNCTION partition_function_name=id LR_BRACKET data_type RR_BRACKET AS RANGE (LEFT | RIGHT)? FOR VALUES LR_BRACKET expression_list? RR_BRACKET
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-partition-scheme-transact-sql
alter_partition_scheme
    : ALTER PARTITION SCHEME partition_scheme_name=id NEXT USED (file_group_name=id)?
    ;

create_partition_scheme
    : CREATE PARTITION SCHEME partition_scheme_name=id AS PARTITION partition_function_name=id ALL? TO LR_BRACKET filegroup_type (COMMA filegroup_type)* RR_BRACKET
    ;

filegroup_type
    : PRIMARY_SQBRACKET // [PRIMARY] filegroup
    | char_string       // can be 'PRIMARY'
    | id                // user filegroup
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-remote-service-binding-transact-sql
alter_remote_service_binding
    : ALTER REMOTE SERVICE BINDING binding_name=id
        WITH (USER EQUAL user_name=id)?
             (COMMA ANONYMOUS EQUAL (ON|OFF) )?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-remote-service-binding-transact-sql
create_remote_service_binding
    : CREATE REMOTE SERVICE BINDING binding_name=id
         (AUTHORIZATION owner_name=id)?
         TO SERVICE remote_service_name=char_string
         WITH (USER EQUAL user_name=id)?
              (COMMA ANONYMOUS EQUAL (ON|OFF) )?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-resource-pool-transact-sql
create_resource_pool
    : CREATE RESOURCE POOL pool_name=id
        (WITH
 LR_BRACKET
               (COMMA? MIN_CPU_PERCENT EQUAL DECIMAL)?
               (COMMA? MAX_CPU_PERCENT EQUAL DECIMAL)?
               (COMMA? CAP_CPU_PERCENT EQUAL DECIMAL)?
               (COMMA? AFFINITY SCHEDULER EQUAL
                                  (AUTO
                                   | LR_BRACKET (COMMA? (DECIMAL|DECIMAL TO DECIMAL) )+ RR_BRACKET
                                   | NUMANODE EQUAL LR_BRACKET (COMMA? (DECIMAL|DECIMAL TO DECIMAL) )+ RR_BRACKET
                                   )
               )?
               (COMMA? MIN_MEMORY_PERCENT EQUAL DECIMAL)?
               (COMMA? MAX_MEMORY_PERCENT EQUAL DECIMAL)?
               (COMMA? MIN_IOPS_PER_VOLUME EQUAL DECIMAL)?
               (COMMA? MAX_IOPS_PER_VOLUME EQUAL DECIMAL)?
 RR_BRACKET
         )?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-resource-governor-transact-sql
alter_resource_governor
    : ALTER RESOURCE GOVERNOR ( (DISABLE | RECONFIGURE) | WITH LR_BRACKET CLASSIFIER_FUNCTION EQUAL ( schema_name=id DOT function_name=id | NULL_P ) RR_BRACKET | RESET STATISTICS | WITH LR_BRACKET MAX_OUTSTANDING_IO_PER_VOLUME EQUAL max_outstanding_io_per_volume=DECIMAL RR_BRACKET )
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-role-transact-sql
alter_db_role
    : ALTER ROLE role_name=id
        ( (ADD|DROP) MEMBER database_principal=id
        | WITH NAME EQUAL new_role_name=id )
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-role-transact-sql
create_db_role
    : CREATE ROLE role_name=id (AUTHORIZATION owner_name = id)?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-route-transact-sql
create_route
    : CREATE ROUTE route_name=id
        (AUTHORIZATION owner_name=id)?
        WITH (COMMA? (ADDRESS EQUAL char_string | MIRROR_ADDRESS EQUAL char_string | SERVICE_NAME EQUAL route_service_name=char_string | BROKER_INSTANCE EQUAL broker_instance_identifier=char_string | LIFETIME EQUAL expression))+
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-rule-transact-sql
create_rule
    : CREATE RULE (schema_name=id DOT)? rule_name=id
        AS search_condition
    ;

create_default
    : CREATE DEFAULT (schema_name=id DOT)? default_name=id
        AS expression
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-schema-transact-sql
alter_schema
    : ALTER SCHEMA schema_name=id TRANSFER ((OBJECT|TYPE|XML SCHEMA COLLECTION) colon_colon )? id (DOT id)?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-schema-transact-sql
create_schema
    : CREATE SCHEMA
	(schema_name=id
        |AUTHORIZATION owner_name=id
        | schema_name=id AUTHORIZATION owner_name=id
        )
        (create_table
         |create_or_alter_view
         | grant_statement 
         | revoke_statement
         | deny_statement
        )*
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-search-property-list-transact-sql
create_search_property_list
    : CREATE SEARCH PROPERTY LIST new_list_name=id
        (FROM (database_name=id DOT)? source_list_name=id )?
        (AUTHORIZATION owner_name=id)?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-security-policy-transact-sql
create_security_policy
   : CREATE SECURITY POLICY (schema_name=id DOT)? security_policy_name=id
        (COMMA? ADD (FILTER|BLOCK)? PREDICATE tvf_schema_name=id DOT security_predicate_function_name=id
 LR_BRACKET (COMMA? column_name_or_arguments=id)+ RR_BRACKET
              ON table_schema_name=id DOT name=id
                (COMMA? AFTER (INSERT|UPDATE)
                | COMMA? BEFORE (UPDATE|DELETE)
                )*
         )+
            (WITH LR_BRACKET
                     STATE EQUAL (ON|OFF)
		     (SCHEMABINDING (ON|OFF) )?
 RR_BRACKET
             )?
             for_replication?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-sequence-transact-sql
alter_sequence
    : ALTER SEQUENCE (schema_name=id DOT)? sequence_name=id 
      (RESTART (WITH sign? DECIMAL)? )? 
      (INCREMENT BY sign? DECIMAL )? 
      (MINVALUE sign? DECIMAL| NO MINVALUE)? 
      (MAXVALUE sign? DECIMAL| NO MAXVALUE)? 
      (CYCLE|NO CYCLE)? 
      (cache_kwd=CACHE cache_value=DECIMAL? | no_cache=NO no_cache_kwd=CACHE)?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-sequence-transact-sql
create_sequence
    : CREATE SEQUENCE (schema_name=id DOT)? sequence_name=id
        (AS data_type  )?
        (START WITH sign? DECIMAL)?
        (INCREMENT BY sign? DECIMAL)?
        (MINVALUE sign? DECIMAL? | NO MINVALUE)?
        (MAXVALUE sign? DECIMAL? | NO MAXVALUE)?
        (CYCLE|NO CYCLE)?
        (cache_kwd=CACHE cache_value=DECIMAL? | no_cache=NO no_cache_kwd=CACHE)?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-server-audit-transact-sql
alter_server_audit
    : ALTER SERVER AUDIT audit_name=id
        ( ( TO
              (FILE
                ( LR_BRACKET
                   ( COMMA? FILEPATH EQUAL filepath=char_string
                    | COMMA? MAXSIZE EQUAL ( DECIMAL (MB|GB|TB)
                    |  UNLIMITED
                   )
                   | COMMA? MAX_ROLLOVER_FILES EQUAL max_rollover_files=(DECIMAL|UNLIMITED)
                   | COMMA? MAX_FILES EQUAL max_files=DECIMAL
                   | COMMA? RESERVE_DISK_SPACE EQUAL (ON|OFF)  )*
 RR_BRACKET )
                | APPLICATION_LOG
                | SECURITY_LOG
            ) )?
            ( WITH LR_BRACKET
              (COMMA? QUEUE_DELAY EQUAL queue_delay=DECIMAL
              | COMMA? ON_FAILURE EQUAL (CONTINUE | SHUTDOWN|FAIL_OPERATION)
              |COMMA?  STATE EQUAL (ON|OFF) )*
 RR_BRACKET
            )?
            ( WHERE ( COMMA? (NOT?) event_field_name=id
                                    (EQUAL
                                    |(LESS GREATER)
                                    | (EXCLAMATION EQUAL)
                                    | GREATER
                                    | (GREATER EQUAL)
                                    | LESS
                                    | LESS EQUAL
                                    )
                                      (DECIMAL | char_string)
                    | COMMA? (AND|OR) NOT? (EQUAL
                                           |(LESS GREATER)
                                           | (EXCLAMATION EQUAL)
                                           | GREATER
                                           | (GREATER EQUAL)
                                           | LESS
                                           | LESS EQUAL)
                                             (DECIMAL | char_string) ) )?
        |REMOVE WHERE
        | MODIFY NAME EQUAL new_audit_name=id
       )
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-server-audit-transact-sql
create_server_audit
    : CREATE SERVER AUDIT audit_name=id
        ( ( TO
              (FILE
                ( LR_BRACKET
                   ( COMMA? FILEPATH EQUAL filepath=char_string
                    | COMMA? MAXSIZE EQUAL ( DECIMAL (MB|GB|TB)
                    |  UNLIMITED
                   )
                   | COMMA? MAX_ROLLOVER_FILES EQUAL max_rollover_files=(DECIMAL|UNLIMITED)
                   | COMMA? MAX_FILES EQUAL max_files=DECIMAL
                   | COMMA? RESERVE_DISK_SPACE EQUAL (ON|OFF)  )*
 RR_BRACKET )
                | APPLICATION_LOG
                | SECURITY_LOG
            ) )?
            ( WITH LR_BRACKET
              (COMMA? QUEUE_DELAY EQUAL queue_delay=DECIMAL
              | COMMA? ON_FAILURE EQUAL (CONTINUE | SHUTDOWN|FAIL_OPERATION)
              |COMMA?  STATE EQUAL (ON|OFF)
              |COMMA? AUDIT_GUID EQUAL audit_guid=id
            )*

 RR_BRACKET
            )?
            ( WHERE ( COMMA? (NOT?) event_field_name=id
                                    (EQUAL
                                    |(LESS GREATER)
                                    | (EXCLAMATION EQUAL)
                                    | GREATER
                                    | (GREATER EQUAL)
                                    | LESS
                                    | LESS EQUAL
                                    )
                                      (DECIMAL | char_string)
                    | COMMA? (AND|OR) NOT? (EQUAL
                                           |(LESS GREATER)
                                           | (EXCLAMATION EQUAL)
                                           | GREATER
                                           | (GREATER EQUAL)
                                           | LESS
                                           | LESS EQUAL)
                                             (DECIMAL | char_string) ) )?
        |REMOVE WHERE
        | MODIFY NAME EQUAL new_audit_name=id
       )
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-server-audit-specification-transact-sql
alter_server_audit_specification
    : ALTER SERVER AUDIT SPECIFICATION audit_specification_name=id
       (FOR SERVER AUDIT audit_name=id)?
       ( (ADD|DROP) LR_BRACKET audit_action_group_name=id RR_BRACKET )*
         (WITH LR_BRACKET STATE EQUAL (ON|OFF) RR_BRACKET )?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-server-audit-specification-transact-sql
create_server_audit_specification
    : CREATE SERVER AUDIT SPECIFICATION audit_specification_name=id
       (FOR SERVER AUDIT audit_name=id)?
       ( ADD LR_BRACKET audit_action_group_name=id RR_BRACKET )*
         (WITH LR_BRACKET STATE EQUAL (ON|OFF) RR_BRACKET )?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-server-configuration-transact-sql
alter_server_configuration
    : ALTER SERVER CONFIGURATION
      SET ( (PROCESS AFFINITY (CPU EQUAL (AUTO | (COMMA? DECIMAL | COMMA? DECIMAL TO DECIMAL)+ ) | NUMANODE EQUAL ( COMMA? DECIMAL |COMMA?  DECIMAL TO DECIMAL)+ ) | DIAGNOSTICS LOG (ON|OFF|PATH EQUAL (char_string | DEFAULT) |MAX_SIZE EQUAL (DECIMAL MB |DEFAULT)|MAX_FILES EQUAL (DECIMAL|DEFAULT) ) | FAILOVER CLUSTER PROPERTY (VERBOSELOGGING EQUAL (char_string|DEFAULT) |SQLDUMPERFLAGS EQUAL (char_string|DEFAULT) | SQLDUMPERPATH EQUAL (char_string|DEFAULT) | SQLDUMPERTIMEOUT (char_string|DEFAULT) | FAILURECONDITIONLEVEL EQUAL (char_string|DEFAULT) | HEALTHCHECKTIMEOUT EQUAL (DECIMAL|DEFAULT) ) | HADR CLUSTER CONTEXT EQUAL (char_string|LOCAL) | BUFFER POOL EXTENSION (ON LR_BRACKET FILENAME EQUAL char_string COMMA SIZE EQUAL DECIMAL (KB|MB|GB) RR_BRACKET | OFF ) | SET SOFTNUMA (ON|OFF) ) )
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-server-role-transact-sql
alter_server_role
    : ALTER SERVER ROLE server_role_name=id
      ( (ADD|DROP) MEMBER server_principal=id
      | WITH NAME EQUAL new_server_role_name=id
      )
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-server-role-transact-sql
create_server_role
    : CREATE SERVER ROLE server_role_name=id (AUTHORIZATION server_principal=id)?
    ;    

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-service-transact-sql
alter_service
    : ALTER SERVICE modified_service_name=id (ON QUEUE (schema_name=id DOT) queue_name=id)? (COMMA? (ADD|DROP) modified_contract_name=id)*
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-service-transact-sql
create_service
    : CREATE SERVICE create_service_name=id
        (AUTHORIZATION owner_name=id)?
        ON QUEUE (schema_name=id DOT)? queue_name=id
          ( LR_BRACKET (COMMA? (id|DEFAULT) )+ RR_BRACKET )?
    ;


// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-service-master-key-transact-sql

alter_service_master_key
    : ALTER SERVICE MASTER KEY ( FORCE? REGENERATE | (WITH (OLD_ACCOUNT EQUAL acold_account_name=char_string COMMA OLD_PASSWORD EQUAL old_password=char_string | NEW_ACCOUNT EQUAL new_account_name=char_string COMMA NEW_PASSWORD EQUAL new_password=char_string)?  ) )
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-symmetric-key-transact-sql

alter_symmetric_key
    : ALTER SYMMETRIC KEY key_name=id ( (ADD|DROP) ENCRYPTION BY (CERTIFICATE certificate_name=id | PASSWORD EQUAL password=char_string | SYMMETRIC KEY symmetric_key_name=id | ASYMMETRIC KEY Asym_key_name=id  ) )
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-symmetric-key-transact-sql
create_symmetric_key
    : CREATE SYMMETRIC KEY key_name=id
      (AUTHORIZATION user_name=id)?
      (FROM PROVIDER provider_name=id)?
      WITH ((key_options | ENCRYPTION BY encryption_mechanism)COMMA?)+
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-synonym-transact-sql
create_synonym
    : CREATE SYNONYM (schema_name_1=id DOT )? synonym_name=id FOR full_object_name     
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-user-transact-sql
alter_user
    : ALTER USER username=id WITH (COMMA? NAME EQUAL newusername=id | COMMA? DEFAULT_SCHEMA EQUAL ( schema_name=id |NULL_P ) | COMMA? LOGIN EQUAL loginame=id | COMMA? PASSWORD EQUAL char_string (OLD_PASSWORD EQUAL char_string)+ | COMMA? DEFAULT_LANGUAGE EQUAL (NONE| lcid=DECIMAL| language_name_or_alias=id) | COMMA? ALLOW_ENCRYPTED_VALUE_MODIFICATIONS EQUAL (ON|OFF) )+
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-user-transact-sql
create_user
    : CREATE USER user_name=id
         (  (FOR|FROM) LOGIN login_name=id )?
         ( WITH (COMMA? DEFAULT_SCHEMA EQUAL schema_name=id
                |COMMA? ALLOW_ENCRYPTED_VALUE_MODIFICATIONS EQUAL (ON|OFF)
                )*
         )?
    | CREATE USER   ( windows_principal=id
                      (WITH
                        (COMMA? DEFAULT_SCHEMA EQUAL schema_name=id
                        |COMMA? DEFAULT_LANGUAGE EQUAL (NONE
                                                |DECIMAL
                                                |language_name_or_alias=id                                                      )
                        |COMMA? SID EQUAL hex_string
                        |COMMA? ALLOW_ENCRYPTED_VALUE_MODIFICATIONS EQUAL (ON|OFF)
                        )*
                      )?
                   | user_name=id WITH PASSWORD EQUAL password=char_string
                            (COMMA? DEFAULT_SCHEMA EQUAL schema_name=id
                            |COMMA? DEFAULT_LANGUAGE EQUAL (NONE
                                                |DECIMAL
                                                |language_name_or_alias=id                                                      )
                            |COMMA? SID EQUAL hex_string
                           |COMMA? ALLOW_ENCRYPTED_VALUE_MODIFICATIONS EQUAL (ON|OFF)
                          )*
                   | Azure_Active_Directory_principal=id FROM EXTERNAL PROVIDER
                   )
    | CREATE USER user_name=id
                 ( WITHOUT LOGIN
                   (COMMA? DEFAULT_SCHEMA EQUAL schema_name=id
                   |COMMA? ALLOW_ENCRYPTED_VALUE_MODIFICATIONS EQUAL (ON|OFF)
                   )*
                 | (FOR|FROM) CERTIFICATE cert_name=id
                 | (FOR|FROM) ASYMMETRIC KEY asym_key_name=id
                 )
    | CREATE USER user_name=id
    ;

create_user_azure_sql_dw
    : CREATE USER user_name=id
        ( (FOR|FROM) LOGIN login_name=id
        | WITHOUT LOGIN
        )?

        ( WITH DEFAULT_SCHEMA EQUAL schema_name=id)?
    | CREATE USER Azure_Active_Directory_principal=id
        FROM EXTERNAL PROVIDER
        ( WITH DEFAULT_SCHEMA EQUAL schema_name=id)?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-workload-group-transact-sql
alter_workload_group
    : ALTER WORKLOAD GROUP
         (workload_group_group_name=id
         |DEFAULT_DOUBLE_QUOTE
         )
         (WITH LR_BRACKET
           (IMPORTANCE EQUAL (LOW|MEDIUM|HIGH)
           | COMMA? REQUEST_MAX_MEMORY_GRANT_PERCENT EQUAL request_max_memory_grant=DECIMAL
           | COMMA? REQUEST_MAX_CPU_TIME_SEC EQUAL request_max_cpu_time_sec=DECIMAL
           | REQUEST_MEMORY_GRANT_TIMEOUT_SEC EQUAL request_memory_grant_timeout_sec=DECIMAL
           | MAX_DOP EQUAL max_dop=DECIMAL
           | GROUP_MAX_REQUESTS EQUAL group_max_requests=DECIMAL)+
 RR_BRACKET )?
     (USING (workload_group_pool_name=id | DEFAULT_DOUBLE_QUOTE) )?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-workload-group-transact-sql
create_workload_group
    : CREATE WORKLOAD GROUP workload_group_group_name=id
         (WITH LR_BRACKET
           (IMPORTANCE EQUAL (LOW|MEDIUM|HIGH)
           | COMMA? REQUEST_MAX_MEMORY_GRANT_PERCENT EQUAL request_max_memory_grant=DECIMAL
           | COMMA? REQUEST_MAX_CPU_TIME_SEC EQUAL request_max_cpu_time_sec=DECIMAL
           | REQUEST_MEMORY_GRANT_TIMEOUT_SEC EQUAL request_memory_grant_timeout_sec=DECIMAL
           | MAX_DOP EQUAL max_dop=DECIMAL
           | GROUP_MAX_REQUESTS EQUAL group_max_requests=DECIMAL)+
 RR_BRACKET )?
     (USING (workload_group_pool_name=id | DEFAULT_DOUBLE_QUOTE)?
            (COMMA? EXTERNAL external_pool_name=id | DEFAULT_DOUBLE_QUOTE)?
      )?
    ;

create_workload_classifier
    : CREATE WORKLOAD CLASSIFIER id WITH LR_BRACKET?.+? RR_BRACKET EOF   // quick & dirty, good enough for now
    ;
    
drop_workload_classifier
    : DROP WORKLOAD CLASSIFIER id 
    ;
    
// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-xml-schema-collection-transact-sql
create_xml_schema_collection
    : CREATE XML SCHEMA COLLECTION simple_name AS  (char_string|id|LOCAL_ID)
    ;

alter_xml_schema_collection
    : ALTER XML SCHEMA COLLECTION simple_name ADD char_string
    ;

create_queue
    : CREATE QUEUE (full_object_name | queue_name=id) queue_settings?
      (ON filegroup=id | DEFAULT)?
    ;

queue_settings
    : WITH 
       (
         (STATUS EQUAL on_off COMMA?)
       | (RETENTION EQUAL on_off COMMA?)
       | (ACTIVATION LR_BRACKET
           (
             (
                (STATUS EQUAL on_off COMMA? )
              | (PROCEDURE_NAME EQUAL func_proc_name_database_schema COMMA?)
              | (MAX_QUEUE_READERS EQUAL max_readers=DECIMAL COMMA?)
              | ((EXECUTE|EXEC) AS (SELF | user_name=char_string | OWNER) COMMA?)
             )*
             | DROP
           ) RR_BRACKET COMMA?
         )
      | (POISON_MESSAGE_HANDLING LR_BRACKET STATUS EQUAL on_off RR_BRACKET) COMMA?
      )+
    ;

alter_queue
    : ALTER QUEUE (full_object_name | queue_name=id)
      (queue_settings | queue_action)
    ;

queue_action
    : REBUILD ( WITH LR_BRACKET queue_rebuild_options RR_BRACKET)?
    | REORGANIZE (WITH LOB_COMPACTION EQUAL on_off )?
    | MOVE TO (id | DEFAULT)
    ;

queue_rebuild_options
    : maxdop_option
    ;

create_contract
    : CREATE CONTRACT contract_name
      (AUTHORIZATION owner_name=id)?
 LR_BRACKET ((message_type_name=id | DEFAULT)
          SENT BY (INITIATOR | TARGET | ANY ) COMMA?)+
 RR_BRACKET
    ;

conversation_statement
    : begin_conversation_timer
    | begin_conversation_dialog
    | end_conversation
    | get_conversation
    | send_conversation
    | waitfor_conversation
    | waitfor_receive_statement
    | receive_statement    
    ;

create_message_type
    : CREATE MESSAGE TYPE message_type_name=id
      (AUTHORIZATION owner_name=id)?
      (VALIDATION EQUAL (NONE
      | EMPTY
      | WELL_FORMED_XML
      | VALID_XML WITH SCHEMA COLLECTION schema_collection_name=id))
    ;

// DML

// https://docs.microsoft.com/en-us/sql/t-sql/statements/merge-transact-sql
// note that there is a limit on number of when_matches but it has to be done runtime due to different ordering of statements allowed
merge_statement
    : with_expression?
      MERGE (TOP LR_BRACKET expression RR_BRACKET PERCENT?)?
      INTO? ddl_object with_table_hints? as_table_alias?
      USING table_sources
      ON search_condition
      when_matches+
      output_clause?
      option_clause? 
      final_char=(SEMI | RR_BRACKET)  /// semicolon is required for stand-alone statement, but not inside INSERT-SELECT FROM (MERGE), where we expect a bracket instead
    ;

when_matches
    : (WHEN MATCHED (AND search_condition)?
          THEN merge_matched)
    | (WHEN NOT MATCHED (BY TARGET)? (AND search_condition)?
          THEN merge_not_matched)
    | (WHEN NOT MATCHED BY SOURCE (AND search_condition)?
          THEN merge_matched)
    ;

merge_matched
    : UPDATE SET update_elem_merge (COMMA update_elem_merge)*
    | DELETE
    ;

merge_not_matched
    : INSERT ( LR_BRACKET column_name_list RR_BRACKET )?
      (table_value_constructor | DEFAULT VALUES)
    ;

// https://msdn.microsoft.com/en-us/library/ms189835.aspx
delete_statement
    : with_expression?
      DELETE (TOP LR_BRACKET expression RR_BRACKET PERCENT?)?
      FROM? delete_statement_from
      with_table_hints?
      output_clause?
      (FROM table_sources)?
      (WHERE (search_condition | CURRENT OF (GLOBAL? cursor_name | cursor_var=LOCAL_ID)))?
      option_clause? SEMI?
    ;

delete_statement_from
    : ddl_object
    | table_alias
    | rowset_function
    | table_var=LOCAL_ID
    ;

// https://msdn.microsoft.com/en-us/library/ms174335.aspx
insert_statement
    : with_expression?
      INSERT (TOP LR_BRACKET expression RR_BRACKET PERCENT?)?
      INTO? (ddl_object | rowset_function)
      with_table_hints?
      ( LR_BRACKET insert_column_name_list RR_BRACKET )?
      output_clause?
      insert_statement_value
      option_clause? SEMI?
    ;

insert_statement_value
    : derived_table
    | execute_statement
    | DEFAULT VALUES
    ;

insert_bulk_statement
    : INSERT BULK table_name LR_BRACKET schema_declaration RR_BRACKET ( WITH LR_BRACKET insert_bulk_option (COMMA? insert_bulk_option)* RR_BRACKET )? SEMI?
    ;

insert_bulk_option
    : id
    | bulk_insert_option
    ;    

bulk_insert_statement
    : BULK INSERT ddl_object FROM char_string ( WITH LR_BRACKET bulk_insert_option (COMMA? bulk_insert_option)* RR_BRACKET )? SEMI?
    | INSERT BULK ddl_object (LR_BRACKET (insert_bulk_column_definition (COMMA insert_bulk_column_definition)*)? column_constraint* COMMA? RR_BRACKET) ( WITH LR_BRACKET bulk_insert_option (COMMA? bulk_insert_option)* RR_BRACKET )?
    ;

bulk_insert_option
    : id (EQUAL expression)?
    | ORDER LR_BRACKET order_by_expression (COMMA order_by_expression)* RR_BRACKET
    ;

// https://msdn.microsoft.com/en-us/library/ms189499.aspx
select_statement_standalone
    : with_expression?
      select_statement
    ;

select_statement
    : query_expression order_by_clause? option_clause? for_clause? option_clause?
    ;

time
    : (LOCAL_ID | constant)
    ;

// https://msdn.microsoft.com/en-us/library/ms177523.aspx
update_statement
    : with_expression?
      UPDATE (TOP LR_BRACKET expression RR_BRACKET PERCENT?)?
      (ddl_object | rowset_function)
      with_table_hints?
      SET update_elem (COMMA update_elem)*
      output_clause?
      (FROM table_sources)?
      (WHERE (search_condition | CURRENT OF (GLOBAL? cursor_name | cursor_var=LOCAL_ID)))?
      option_clause? SEMI?
    ;

// https://msdn.microsoft.com/en-us/library/ms177564.aspx
output_clause
    : OUTPUT output_dml_list_elem (COMMA output_dml_list_elem)*
      (INTO (LOCAL_ID | table_name) ( LR_BRACKET column_name_list RR_BRACKET )? )?
      output_clause?
    ;

output_dml_list_elem
    : (output_column_name | expression) as_column_alias?  // TODO: scalar_expression
    ;

output_column_name
    : (DELETED | INSERTED | table_name) DOT ( STAR  | id)
    | DOLLAR_ACTION
    ;

readtext_statement
    : READTEXT col=full_column_name (text_ptr=LOCAL_ID|text_ptr_hex=hex_string) offset=(LOCAL_ID|DECIMAL) size=(LOCAL_ID|DECIMAL) HOLDLOCK?
    ;

writetext_statement
    : WRITETEXT BULK? col=full_column_name (text_ptr=LOCAL_ID|text_ptr_hex=hex_string) (WITH LOG)? (LOCAL_ID|char_string)
    ;

updatetext_statement
    : UPDATETEXT BULK? col=full_column_name (text_ptr=LOCAL_ID|text_ptr_hex=hex_string) (NULL_P|DECIMAL|LOCAL_ID) (NULL_P|DECIMAL|LOCAL_ID) (WITH LOG)? ((LOCAL_ID|char_string) | full_column_name (text_ptr=LOCAL_ID|text_ptr_hex=hex_string) )?
    ;

// https://msdn.microsoft.com/en-ie/library/ms176061.aspx
create_database
    : CREATE DATABASE (database=id)
    ( CONTAINMENT  EQUAL  containment=( NONE | PARTIAL ) )?
    ( ON PRIMARY? database_file_spec ( COMMA database_file_spec )* )?
    ( LOG ON database_file_spec ( COMMA database_file_spec )* )?
    collation?
    ( WITH  create_database_option ( COMMA create_database_option )* )?
    ;

// https://msdn.microsoft.com/en-us/library/ms188783.aspx
create_index
    : CREATE UNIQUE? clustered? COLUMNSTORE? INDEX id ON table_name (LR_BRACKET column_name_list_with_order RR_BRACKET)?
    (INCLUDE LR_BRACKET column_name_list RR_BRACKET )?
    (WHERE where=search_condition)?
    with_index_options?
    (ON storage_partition_clause)?
 SEMI?
    |CREATE UNIQUE? clustered? COLUMNSTORE? INDEX id ON table_name (USING vector_index_method)? (LR_BRACKET column_name_list_with_order_for_vector RR_BRACKET)?
    (INCLUDE LR_BRACKET column_name_list RR_BRACKET )?
    (WHERE where=search_condition)?
    with_index_options?
    (ON storage_partition_clause)?
 SEMI?
    ;

/* We introduce specific index methods so as to avoid PG syntax leaks. */
vector_index_method
    : HNSW
    | IVFFLAT
    ;

alter_index
    : ALTER INDEX (id | ALL) ON table_name alter_index_options
 SEMI?
    ;

alter_index_options
    : REBUILD ( PARTITION EQUAL (ALL | (DECIMAL|LOCAL_ID)) )? (WITH LR_BRACKET index_option (COMMA index_option)* RR_BRACKET )?
    | DISABLE
    | REORGANIZE
    | SET LR_BRACKET index_option (COMMA index_option)* RR_BRACKET
    | RESUME (WITH LR_BRACKET index_option (COMMA index_option)* RR_BRACKET)?
    | PAUSE
    | ABORT
    ;

create_xml_index
    : CREATE PRIMARY? XML INDEX id ON table_name LR_BRACKET id RR_BRACKET
    (USING XML INDEX id (FOR (VALUE | PATH | PROPERTY)?)?)?
    with_index_options?
    SEMI?
    ;

create_selective_xml_index
    : CREATE SELECTIVE XML INDEX id ON table_name LR_BRACKET id RR_BRACKET
    (WITH XMLNAMESPACES LR_BRACKET char_string AS id (COMMA char_string AS id)* RR_BRACKET)?
    FOR LR_BRACKET promoted_node_path (COMMA promoted_node_path)* RR_BRACKET
    with_index_options?
    SEMI?
    ;

promoted_node_path
    : pathname=ID EQUAL char_string (AS (XQUERY char_string | SQL) data_type? SINGLETON?)?
    ;   

create_spatial_index
    : CREATE SPATIAL INDEX id ON table_name LR_BRACKET id RR_BRACKET
      spatial_grid_clause?
      spatial_grid_option_clause?
      (ON storage_partition_clause)?
      SEMI?
    ;
 
spatial_grid_clause   
    : USING (GEOMETRY_AUTO_GRID | GEOMETRY_GRID | GEOGRAPHY_AUTO_GRID | GEOGRAPHY_GRID)
    ;
 
spatial_grid_option_clause       
    : WITH LR_BRACKET spatial_grid_option (COMMA spatial_grid_option)* RR_BRACKET
    ;
    
spatial_grid_option
    : bounding_box 
    | tessellation_cells_per_object
    | tessellation_grid
    | spatial_index_option (COMMA spatial_index_option)*
    ;

bounding_box
    : BOUNDING_BOX EQUAL LR_BRACKET (XMIN EQUAL)? expression COMMA (YMIN EQUAL)? expression COMMA (XMAX EQUAL)? expression COMMA (YMAX EQUAL)? expression RR_BRACKET
    ;
 
tessellation_cells_per_object         
    : CELLS_PER_OBJECT EQUAL (DECIMAL|LOCAL_ID)
    ;
  
tessellation_grid
    : GRIDS EQUAL LR_BRACKET grid_level_or_size (COMMA grid_level_or_size)* RR_BRACKET
    ;
        
grid_level_or_size
    : (id EQUAL)? (LOW | MEDIUM | HIGH)
    ;
    
spatial_index_option
    : index_option
    ;
     
// https://msdn.microsoft.com/en-us/library/ms187926(v=sql.120).aspx
create_or_alter_procedure
    : ((CREATE (OR ALTER)?) | ALTER) proc=(PROC | PROCEDURE) procName=func_proc_name_schema (SEMI proc_version=DECIMAL)?
      ( LR_BRACKET? procedure_param (COMMA procedure_param)* RR_BRACKET?)?
      (WITH procedure_option (COMMA procedure_option)*)?
      for_replication? AS
      ( atomic_proc_body | sql_clauses* | external_name  )
    ;

atomic_proc_body
    : BEGIN atomic WITH LR_BRACKET atomic_body_options RR_BRACKET sql_clauses* END SEMI?    
    ;         
       
atomic
    : ATOMIC
    ;
    
atomic_body_options
    : atomic_body_option (COMMA atomic_body_option)*
    ;
    
atomic_body_option
    : LANGUAGE EQUAL char_string
    | TRANSACTION ISOLATION LEVEL EQUAL (SNAPSHOT | REPEATABLE READ | SERIALIZABLE)
    | DATEFIRST EQUAL DECIMAL
    | DATEFORMAT EQUAL id
    | DELAYED_DURABILITY EQUAL on_off
    ; 

// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-trigger-transact-sql
create_or_alter_trigger
    : create_or_alter_dml_trigger
    | create_or_alter_ddl_trigger
    ;

create_or_alter_dml_trigger
    : ((CREATE (OR ALTER)?) | ALTER) TRIGGER simple_name
      ON table_name
      (WITH trigger_option (COMMA trigger_option)* )?
      (FOR | AFTER | INSTEAD OF)
      dml_trigger_operation (COMMA dml_trigger_operation)*
      (WITH APPEND)?
      for_replication?
      AS (sql_clauses+ | external_name)
    ;

dml_trigger_operation
    : (INSERT | UPDATE | DELETE)
    ;

create_or_alter_ddl_trigger
    : ((CREATE (OR ALTER)?) | ALTER) TRIGGER simple_name
      ON (ALL SERVER | DATABASE)
      (WITH trigger_option (COMMA trigger_option)* )?
      (FOR | AFTER) ddl_trigger_operation+=ID (COMMA ddl_trigger_operation+=ID)*      
      AS (sql_clauses+ | external_name)
    ;

trigger_option
    : ENCRYPTION
    | NATIVE_COMPILATION
    | SCHEMABINDING    
    | execute_as_clause
    ;
    
// https://msdn.microsoft.com/en-us/library/ms186755.aspx
create_or_alter_function
    : ((CREATE (OR ALTER)?) | ALTER) FUNCTION funcName=func_proc_name_schema
        (( LR_BRACKET procedure_param (COMMA procedure_param)* RR_BRACKET ) | LR_BRACKET RR_BRACKET ) //must have (), but can be empty
        ( func_body_returns_select | func_body_returns_table | func_body_returns_scalar | func_body_returns_table_clr ) SEMI?
    ;

func_body_returns_select
    : RETURNS TABLE
        (WITH function_option (COMMA function_option)*)?
        AS?
        func_body_return_select_body
    ;

func_body_return_select_body
    : RETURN ( LR_BRACKET select_statement_standalone RR_BRACKET | select_statement_standalone)
    ;

func_body_returns_table
    : RETURNS local_id table_type_definition
        (WITH function_option (COMMA function_option)*)?
        AS?
        BEGIN sql_clauses* SEMI? END
    ;

func_body_returns_table_clr
    : RETURNS table_type_definition
        (WITH function_option (COMMA function_option)*)?
        (ORDER LR_BRACKET column_name_list_with_order RR_BRACKET)?
        AS?
        external_name
    ;

func_body_returns_scalar
    : RETURNS data_type
        (WITH function_option (COMMA function_option)*)?
        AS?
		( BEGIN atomic_func_body? sql_clauses* SEMI? END | external_name )
    ;

atomic_func_body    
    : atomic WITH LR_BRACKET atomic_body_options RR_BRACKET
    ;    

// CREATE PROC p @p INT NULL --> this appears to be accepted syntax for non-native compiled procs, though formally not allowed
procedure_param
    : local_id AS? data_type VARYING? (NOT? NULL_P)? (EQUAL default_val=expression)? param_option=(OUT | OUTPUT | READONLY)?
    ;

//  drop_procedure_param can be used in a DROP FUNCTION or DROP PROCEDURE command
drop_procedure_param
    : LOCAL_ID? data_type
    ;

procedure_option
    : ENCRYPTION
    | NATIVE_COMPILATION
    | SCHEMABINDING
    | RECOMPILE
    | execute_as_clause
    ;

function_option
    : ENCRYPTION
    | NATIVE_COMPILATION
    | SCHEMABINDING
    | RETURNS NULL_P ON NULL_P INPUT
    | CALLED ON NULL_P INPUT
    | execute_as_clause
    ;

// https://msdn.microsoft.com/en-us/library/ms188038.aspx
create_statistics
    : CREATE STATISTICS id ON table_name LR_BRACKET column_name_list RR_BRACKET
      (WITH (FULLSCAN | SAMPLE DECIMAL (PERCENT | ROWS) | STATS_STREAM)
            (COMMA NORECOMPUTE)? (COMMA INCREMENTAL EQUAL on_off)? )? SEMI?
    ;

update_statistics
    : UPDATE STATISTICS table_name (LR_BRACKET column_name_list RR_BRACKET)?
      (WITH update_statistics_option (COMMA? update_statistics_option)*)?
 SEMI?
    ;

update_statistics_option
    : FULLSCAN (COMMA? update_statistics_option_persist_pct)?
    | SAMPLE expression (PERCENT|ROWS) (COMMA? update_statistics_option_persist_pct)?
    | RESAMPLE (ON PARTITIONS LR_BRACKET ((DECIMAL|LOCAL_ID)|(DECIMAL|LOCAL_ID) TO (DECIMAL|LOCAL_ID)) (COMMA ((DECIMAL|LOCAL_ID)|(DECIMAL|LOCAL_ID) TO (DECIMAL|LOCAL_ID)))* RR_BRACKET )?
    | update_statistics_option_stats_stream (COMMA update_statistics_option_stats_stream)*
    | (ALL|COLUMNS|INDEX)
    | NOCOMPUTE
    | INCREMENTAL EQUAL on_off
    | maxdop_option
    ;

update_statistics_option_persist_pct
    :  PERSIST_SAMPLE_PERCENT EQUAL on_off
    ;

update_statistics_option_stats_stream
    : STATS_STREAM EQUAL hex_string
    | ROWCOUNT EQUAL DECIMAL
	| PAGECOUNT EQUAL DECIMAL
    ;

maxdop_option
    : MAXDOP EQUAL DECIMAL
    ;

// https://msdn.microsoft.com/en-us/library/ms174979.aspx
create_table
    : CREATE TABLE tabname=table_name LR_BRACKET column_def_table_constraints  (COMMA? (table_constraint|inline_index))*  COMMA? RR_BRACKET create_table_options* SEMI?
    | CREATE TABLE tabname=table_name (LR_BRACKET (column_definition (COMMA column_definition)*)? column_constraint* COMMA? RR_BRACKET)?  graph_clause create_table_options* SEMI?
    | CREATE TABLE tabname=table_name AS FILETABLE (WITH LR_BRACKET file_table_option (COMMA file_table_option)* RR_BRACKET)? SEMI?
    ;
    
create_table_options
    : LOCK ID
    | table_options
    | ON storage_partition_clause
    | TEXTIMAGE_ON storage_partition_clause
    | FILESTREAM_ON storage_partition_clause
    ;
    
graph_clause
    : AS (NODE | EDGE)
    ;

table_options
    : WITH (LR_BRACKET index_option_list? system_versioning_options? RR_BRACKET | index_option_list )
    ;

file_table_option
    : id EQUAL expression
    ;    

storage_partition_clause
    : id (LR_BRACKET id RR_BRACKET)?
    | PRIMARY_SQBRACKET
    | DEFAULT_DOUBLE_QUOTE
    ;

// https://msdn.microsoft.com/en-us/library/ms187956.aspx
create_or_alter_view
    : ((CREATE (OR ALTER)?) | ALTER) VIEW simple_name (LR_BRACKET column_name_list RR_BRACKET)?
      (WITH view_attribute (COMMA view_attribute)*)?
      AS select_statement_standalone (WITH CHECK OPTION)? SEMI?
    ;

view_attribute
    : ENCRYPTION | SCHEMABINDING | VIEW_METADATA
    ;

// https://msdn.microsoft.com/en-us/library/ms190273.aspx
alter_table
    : ALTER TABLE tabname=table_name 
       (  (WITH (NOCHECK | CHECK))? ADD column_def_table_constraints
	    | ALTER COLUMN (colname=id | column_definition) ((ADD | DROP) special_column_option)? (WITH ( LR_BRACKET online_clause RR_BRACKET ))?
	    | DROP alter_table_drop (COMMA alter_table_drop)*
	    | (WITH (NOCHECK | CHECK))? (NOCHECK | CHECK) CONSTRAINT ( ALL | id (COMMA id)* )
	    | (ENABLE | DISABLE) TRIGGER ( ALL | id (COMMA id)* )
	    | (ENABLE | DISABLE) CHANGE_TRACKING (WITH LR_BRACKET TRACK_COLUMNS_UPDATED EQUAL on_off RR_BRACKET)?
	    | SPLIT RANGE LR_BRACKET expression RR_BRACKET
	    | MERGE RANGE LR_BRACKET expression RR_BRACKET
	    | SWITCH (PARTITION expression)? TO table_name (PARTITION expression)? (WITH LR_BRACKET low_priority_lock_wait RR_BRACKET)?
	    | SET LR_BRACKET SYSTEM_VERSIONING EQUAL on_off system_versioning_options? RR_BRACKET
	    | SET LR_BRACKET FILESTREAM_ON EQUAL storage_partition_clause RR_BRACKET
	    | SET LR_BRACKET file_table_option (COMMA file_table_option)* RR_BRACKET
	    | SET LR_BRACKET LOCK_ESCALATION EQUAL (AUTO | TABLE | DISABLE) RR_BRACKET
	    | REBUILD table_options?
       )
    ;
   
alter_table_drop
    : alter_table_drop_column
    | alter_table_drop_constraint
    | alter_table_drop_constraint_id
    | period_for_system_time
    ;
    
alter_table_drop_column
    : COLUMN if_exists? id (COMMA (COLUMN if_exists?)? id)*
    ;
    
alter_table_drop_constraint
    : CONSTRAINT if_exists? alter_table_drop_constraint_id (COMMA (CONSTRAINT if_exists?)? id)*
    ;

alter_table_drop_constraint_id
    : id (WITH LR_BRACKET alter_table_drop_constraint_option (COMMA alter_table_drop_constraint_option)* RR_BRACKET)?
    ;
     
alter_table_drop_constraint_option
    : maxdop_option
    | online_clause
    | MOVE TO storage_partition_clause
    ;

online_clause
    : ONLINE EQUAL on_off (LR_BRACKET low_priority_lock_wait RR_BRACKET)?
    ;
            
low_priority_lock_wait
    : WAIT_AT_LOW_PRIORITY LR_BRACKET MAX_DURATION EQUAL DECIMAL MINUTES? COMMA ABORT_AFTER_WAIT EQUAL (NONE | SELF | BLOCKERS) RR_BRACKET
    ;
            
// https://msdn.microsoft.com/en-us/library/ms174269.aspx
alter_database
    : ALTER DATABASE (database=id | CURRENT)
      (  SET database_optionspec (COMMA database_optionspec)* (WITH termination)?
       | collation
       | MODIFY NAME EQUAL new_name=id
       | ADD FILE file_spec (COMMA file_spec)* ( TO FILEGROUP filegroup=id )?
       | ADD LOG FILE file_spec (COMMA file_spec)*
       | REMOVE FILE filename=id
       | MODIFY FILE file_spec
       | ADD FILEGROUP filegroup=id ( CONTAINS FILESTREAM | CONTAINS MEMORY_OPTIMIZED_DATA )?
       | REMOVE FILEGROUP filegroup=id
       | MODIFY FILEGROUP filegroup=id ( filegroup_updatability_option | DEFAULT | NAME EQUAL filegroup=id | AUTOGROW_SINGLE_FILE | AUTOGROW_ALL_FILES )
      )
 SEMI?
    ;
    
filegroup_updatability_option
    : ( READONLY | READ_ONLY | READWRITE | READ_WRITE )
    ;

// https://msdn.microsoft.com/en-us/library/bb522682.aspx
database_optionspec
    : auto_option
    | accelerated_database_recovery
    | change_tracking_option
    | containment_option
    | cursor_option
    | database_mirroring_option
    | date_correlation_optimization_option
    | db_encryption_option
    | db_state_option
    | db_update_option
    | db_user_access_option
    | delayed_durability_option
    | external_access_option
    | FILESTREAM database_filestream_option
    | hadr_options
    | mixed_page_allocation_option
    | parameterization_option
    | query_store_option
    | recovery_option
//  | remote_data_archive_option
    | service_broker_option
    | snapshot_option
    | sql_option
    | target_recovery_time_option
    | termination
    ;

alter_database_scoped_configuration
    : ALTER DATABASE SCOPED CONFIGURATION ( FOR SECONDARY )? SET id EQUAL ( on_off | PRIMARY | AUTO | WHEN_SUPPORTED | FAIL_UNSUPPORTED | DECIMAL )
    | ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE hex_string
    ;

auto_option
    : AUTO_CLOSE on_off
    | AUTO_CREATE_STATISTICS ( OFF | ON ( INCREMENTAL EQUAL ON | OFF )? )
    | AUTO_SHRINK on_off
    | AUTO_UPDATE_STATISTICS on_off
    | AUTO_UPDATE_STATISTICS_ASYNC  (ON | OFF )
    ;

accelerated_database_recovery
    : ACCELERATED_DATABASE_RECOVERY EQUAL on_off ( LR_BRACKET PERSISTENT_VERSION_STORE_FILEGROUP EQUAL id RR_BRACKET )?
    ;
    
change_tracking_option
    : CHANGE_TRACKING  EQUAL ( OFF | ON (change_tracking_option_list (COMMA change_tracking_option_list)*)*  )
    ;

change_tracking_option_list
    : AUTO_CLEANUP EQUAL on_off
    | CHANGE_RETENTION EQUAL ( DAYS | HOURS | MINUTES )
    ;

containment_option
    : CONTAINMENT EQUAL ( NONE | PARTIAL )
    ;

cursor_option
    : CURSOR_CLOSE_ON_COMMIT on_off
    | CURSOR_DEFAULT ( LOCAL | GLOBAL )
    ;

create_or_alter_database_audit_specification
    : (CREATE | ALTER) DATABASE AUDIT SPECIFICATION audit_specification_name=id
      FOR SERVER AUDIT server_audit=id 
      ((ADD | DROP) LR_BRACKET audit_item (COMMA audit_item)* RR_BRACKET)?
      WITH LR_BRACKET STATE EQUAL on_off RR_BRACKET
      SEMI?
    ;
       
audit_item
    : audit_action_group_name=ID
    | audit_action_specification
    ;

audit_action_specification
    : permission (COMMA permission)* ON (object_type colon_colon)? entity=entity_name BY principals
    ;
  
create_diagnostic_session
    : CREATE DIAGNOSTICS SESSION session_name=ID AS xml=char_string SEMI
    ;
      
// https://docs.microsoft.com/en-us/sql/t-sql/statements/create-endpoint-transact-sql        
// https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-endpoint-transact-sql
create_or_alter_endpoint
    : (CREATE | ALTER) ENDPOINT endpointname=id (AUTHORIZATION login=id)?
       ( STATE EQUAL ( state=STARTED | state=STOPPED | state=DISABLED ) )?
            AS TCP LR_BRACKET
               LISTENER_PORT EQUAL port=DECIMAL
                 ( COMMA LISTENER_IP EQUAL
                   (ALL | LR_BRACKET IPV4_ADDR RR_BRACKET | LR_BRACKET char_string RR_BRACKET) )?
            RR_BRACKET
           ( FOR TSQL LR_BRACKET RR_BRACKET
           |
            FOR SERVICE_BROKER LR_BRACKET
               AUTHENTICATION EQUAL
                       ( WINDOWS ( NTLM |KERBEROS | NEGOTIATE )?  (CERTIFICATE cert_name=id)?
                       | CERTIFICATE cert_name=id  WINDOWS? ( NTLM |KERBEROS | NEGOTIATE )?
                       )
               ( COMMA? ENCRYPTION EQUAL ( DISABLED |SUPPORTED | REQUIRED )
                  ( ALGORITHM ( AES | RC4 | AES RC4 | RC4 AES ) )?
               )?

               ( COMMA? MESSAGE_FORWARDING EQUAL ( ENABLED | DISABLED ) )?
               ( COMMA? MESSAGE_FORWARD_SIZE EQUAL DECIMAL)?
           RR_BRACKET
          |
           FOR DATABASE_MIRRORING LR_BRACKET
               AUTHENTICATION EQUAL
                       ( WINDOWS ( NTLM |KERBEROS | NEGOTIATE )?  (CERTIFICATE cert_name=id)?
                       | CERTIFICATE cert_name=id  WINDOWS? ( NTLM |KERBEROS | NEGOTIATE )?
                       )

               ( COMMA? ENCRYPTION EQUAL ( DISABLED |SUPPORTED | REQUIRED )
                  ( ALGORITHM ( AES | RC4 | AES RC4 | RC4 AES ) )?
               )?

               COMMA? ROLE EQUAL ( WITNESS | PARTNER | ALL )
           RR_BRACKET
         )
    ;
        
database_mirroring_option
    : mirroring_set_option
    ;

mirroring_set_option
    : mirroring_partner  partner_option
    | mirroring_witness  witness_option
    ;
mirroring_partner
    : PARTNER
    ;

mirroring_witness
    : WITNESS
    ;

witness_partner_equal
    : EQUAL
    ;

partner_option
    : witness_partner_equal partner_server
    | FAILOVER
    | FORCE_SERVICE_ALLOW_DATA_LOSS
    | OFF
    | RESUME
    | SAFETY (FULL | OFF )
    | SUSPEND
    | TIMEOUT DECIMAL
    ;

witness_option
    : witness_partner_equal witness_server
    | OFF
    ;

witness_server
    : partner_server
    ;

partner_server
    : partner_server_tcp_prefix host mirroring_host_port_seperator port_number
    ;

mirroring_host_port_seperator
    : COLON
    ;

partner_server_tcp_prefix
    : TCP COLON DOUBLE_FORWARD_SLASH
    ;
port_number
    : port=DECIMAL
    ;

host
    : id (DOT host?)?
    ;

date_correlation_optimization_option
    : DATE_CORRELATION_OPTIMIZATION on_off
    ;

db_encryption_option
    : ENCRYPTION on_off
    ;
db_state_option
    : ( ONLINE | OFFLINE | EMERGENCY )
    ;

db_update_option
    : READ_ONLY | READ_WRITE
    ;

db_user_access_option
    : SINGLE_USER | RESTRICTED_USER | MULTI_USER
    ;
delayed_durability_option
    : DELAYED_DURABILITY EQUAL ( DISABLED | ALLOWED | FORCED )
    ;

external_access_option
    : DB_CHAINING on_off
    | TRUSTWORTHY on_off
    | DEFAULT_LANGUAGE EQUAL ( id | char_string | DECIMAL )
    | DEFAULT_FULLTEXT_LANGUAGE EQUAL ( id | char_string | DECIMAL )
    | NESTED_TRIGGERS EQUAL on_off
    | TRANSFORM_NOISE_WORDS EQUAL on_off
    | TWO_DIGIT_YEAR_CUTOFF EQUAL DECIMAL
    ;

hadr_options
    : HADR
      ( ( AVAILABILITY GROUP EQUAL availability_group_name=id | OFF ) |(SUSPEND|RESUME) )
    ;

mixed_page_allocation_option
    : MIXED_PAGE_ALLOCATION on_off
    ;

parameterization_option
    : PARAMETERIZATION ( SIMPLE | FORCED )
    ;

query_store_option
    : QUERY_STORE EQUAL OFF ( LR_BRACKET FORCED RR_BRACKET )?
    | QUERY_STORE CLEAR ALL?
    | QUERY_STORE ( EQUAL ON )? ( LR_BRACKET query_store_option_item ( COMMA query_store_option_item )* RR_BRACKET )?
	;

query_store_option_item
    : CLEANUP_POLICY EQUAL LR_BRACKET STALE_QUERY_THRESHOLD_DAYS EQUAL thr_days=DECIMAL RR_BRACKET
    | DATA_FLUSH_INTERVAL_SECONDS EQUAL DECIMAL
    | INTERVAL_LENGTH_MINUTES EQUAL DECIMAL
    | MAX_PLANS_PER_QUERY EQUAL DECIMAL
    | MAX_SIZE_MB EQUAL DECIMAL
    | MAX_STORAGE_SIZE_MB EQUAL DECIMAL
    | OPERATION_MODE EQUAL ( READ_WRITE | READ_ONLY )
    | QUERY_CAPTURE_MODE EQUAL ( ALL | AUTO | CUSTOM | NONE )
    | QUERY_CAPTURE_POLICY EQUAL LR_BRACKET query_capture_policy_option ( COMMA query_capture_policy_option )* RR_BRACKET
    | SIZE_BASED_CLEANUP_MODE EQUAL ( AUTO | OFF )
    | WAIT_STATS_CAPTURE_MODE EQUAL on_off
    ;

query_capture_policy_option
    : EXECUTION_COUNT EQUAL DECIMAL
    | STALE_CAPTURE_POLICY_THRESHOLD EQUAL DECIMAL ( DAYS | HOURS )
    | TOTAL_COMPILE_CPU_TIME_MS EQUAL DECIMAL
    | TOTAL_EXECUTION_CPU_TIME_MS EQUAL DECIMAL
    ;

recovery_option
    : RECOVERY ( FULL | BULK_LOGGED | SIMPLE )
    | TORN_PAGE_DETECTION on_off
    | PAGE_VERIFY ( CHECKSUM | TORN_PAGE_DETECTION | NONE )
    ;

service_broker_option:
    ENABLE_BROKER
    | DISABLE_BROKER
    | NEW_BROKER
    | ERROR_BROKER_CONVERSATIONS
    | HONOR_BROKER_PRIORITY on_off
    ;
    
snapshot_option
    : ALLOW_SNAPSHOT_ISOLATION on_off
    | READ_COMMITTED_SNAPSHOT (ON | OFF )
    | MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = (ON | OFF )
    ;

sql_option
    : ANSI_NULL_DEFAULT on_off
    | ANSI_NULLS on_off
    | ANSI_PADDING on_off
    | ANSI_WARNINGS on_off
    | ARITHABORT on_off
    | COMPATIBILITY_LEVEL EQUAL DECIMAL
    | CONCAT_NULL_YIELDS_NULL on_off
    | NUMERIC_ROUNDABORT on_off
    | QUOTED_IDENTIFIER on_off
    | RECURSIVE_TRIGGERS on_off
    | NO_BROWSETABLE on_off
    ;

target_recovery_time_option
    : TARGET_RECOVERY_TIME EQUAL DECIMAL ( SECONDS | MINUTES )
    ;

termination
    : ROLLBACK AFTER seconds = DECIMAL
    | ROLLBACK IMMEDIATE
    | NO_WAIT
    ;

// https://msdn.microsoft.com/en-us/library/ms176118.aspx
drop_index
    : DROP INDEX if_exists?
    ( drop_relational_or_xml_or_spatial_index (COMMA drop_relational_or_xml_or_spatial_index)*
    | drop_backward_compatible_index (COMMA drop_backward_compatible_index)*
    )
    with_index_options?
 SEMI?
    ;

drop_relational_or_xml_or_spatial_index
    : index_name=id ON full_object_name
    ;

drop_backward_compatible_index
    : (owner_name=id DOT)? table_or_view_name=id DOT index_name=id
    ;

// https://msdn.microsoft.com/en-us/library/ms174969.aspx
drop_procedure
    : DROP proc=(PROC | PROCEDURE) if_exists? func_proc_name_schema (COMMA func_proc_name_schema)* SEMI?
    | DROP proc=(PROC | PROCEDURE) if_exists? func_proc_name_schema (( LR_BRACKET drop_procedure_param (COMMA drop_procedure_param)* RR_BRACKET ) | LR_BRACKET RR_BRACKET ) SEMI?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/drop-trigger-transact-sql
drop_trigger
    : DROP TRIGGER if_exists? simple_name (COMMA simple_name)* (ddl=ON (DATABASE | ALL SERVER))? SEMI?
    ;

// https://msdn.microsoft.com/en-us/library/ms190290.aspx
drop_function
    : DROP FUNCTION if_exists? func_proc_name_schema (COMMA func_proc_name_schema)* SEMI?
    | DROP FUNCTION if_exists? func_proc_name_schema (( LR_BRACKET drop_procedure_param (COMMA drop_procedure_param)* RR_BRACKET ) | LR_BRACKET RR_BRACKET ) SEMI?
    ;

// https://msdn.microsoft.com/en-us/library/ms175075.aspx
drop_statistics
    : DROP STATISTICS full_object_name (COMMA full_object_name)* SEMI?
    ;
    
// https://msdn.microsoft.com/en-us/library/ms173790.aspx
drop_table
    : DROP TABLE if_exists? table_name (COMMA table_name)* SEMI?
    ;

// https://msdn.microsoft.com/en-us/library/ms173492.aspx
drop_view
    : DROP VIEW if_exists? simple_name (COMMA simple_name)* SEMI?
    ;

create_type
    : CREATE TYPE name=simple_name
      (FROM data_type null_notnull? default_value=expression?)?
      (AS TABLE LR_BRACKET column_def_table_constraints (COMMA? inline_index)* RR_BRACKET table_options?)?
    ;

drop_type:
    DROP TYPE if_exists? simple_name
    ;

rowset_function
    : open_xml
    | open_json
    | open_query
    | open_datasource
    | open_rowset
    | change_table
    | predict_function
	;

// https://docs.microsoft.com/en-us/sql/t-sql/functions/openxml-transact-sql
open_xml
    : OPENXML LR_BRACKET expression COMMA expression (COMMA expression)? RR_BRACKET
    (WITH ( table_name | LR_BRACKET schema_declaration RR_BRACKET) )?
    ;

schema_declaration
    : xml_col+=column_declaration (COMMA xml_col+=column_declaration)*
    ;

open_json
    : OPENJSON LR_BRACKET expression (COMMA expression)? RR_BRACKET
    (WITH LR_BRACKET json_declaration RR_BRACKET )?
    ;

json_declaration
    : json_col+=json_column_declaration (COMMA json_col+=json_column_declaration)*
    ;

json_column_declaration
    : column_declaration (AS JSON)?
    ;

// https://msdn.microsoft.com/en-us/library/ms188427(v=sql.120).aspx
open_query
    : OPENQUERY LR_BRACKET linked_server=id COMMA query=char_string RR_BRACKET
    ;

// https://msdn.microsoft.com/en-us/library/ms179856.aspx
open_datasource
    : OPENDATASOURCE LR_BRACKET provider=char_string COMMA init=char_string RR_BRACKET
     (DOT id)+
    ;

// https://msdn.microsoft.com/en-us/library/ms190312.aspx
open_rowset
    :  OPENROWSET LR_BRACKET provider_name = char_string COMMA connectionString = char_string COMMA sql = char_string RR_BRACKET
     | OPENROWSET LR_BRACKET BULK data_file=char_string COMMA (bulk_option (COMMA bulk_option)* | id) RR_BRACKET
    ;

change_table
    : CHANGETABLE LR_BRACKET (change_table_changes | change_table_version) (COMMA FORCESEEK)? RR_BRACKET
    ;

change_table_changes
    :  CHANGES changetable=table_name COMMA changesid=(NULL_P | DECIMAL | LOCAL_ID)
    ;
change_table_version
    : VERSION versiontable=table_name COMMA LR_BRACKET pk_columns=full_column_name_list RR_BRACKET COMMA LR_BRACKET pk_values=select_list RR_BRACKET
    ;

predict_function
    : PREDICT LR_BRACKET MODEL EQUAL expression COMMA DATA EQUAL (table_name | function_call) AS table_alias (RUNTIME EQUAL id)? RR_BRACKET
      WITH LR_BRACKET column_definition (COMMA column_definition)* RR_BRACKET
    ;

// https://msdn.microsoft.com/en-us/library/ms188927.aspx
declare_statement
    : DECLARE local_id AS? table_type_definition SEMI?
    | DECLARE loc+=declare_local (COMMA loc+=declare_local)* SEMI?
    ;
    
declare_xmlnamespaces_statement
    : WITH XMLNAMESPACES LR_BRACKET xml_dec+=xml_declaration (COMMA xml_dec+=xml_declaration)* RR_BRACKET (select_statement | insert_statement | update_statement | delete_statement | merge_statement )? SEMI?
    ;
    
xml_declaration
    : xml_namespace_uri=char_string AS id
    | DEFAULT char_string
    ;

// https://msdn.microsoft.com/en-us/library/ms181441(v=sql.120).aspx
cursor_statement
    // https://msdn.microsoft.com/en-us/library/ms175035(v=sql.120).aspx
    : CLOSE GLOBAL? cursor_name SEMI?
    // https://msdn.microsoft.com/en-us/library/ms188782(v=sql.120).aspx
    | DEALLOCATE GLOBAL? CURSOR? cursor_name SEMI?
    // https://msdn.microsoft.com/en-us/library/ms180169(v=sql.120).aspx
    | declare_cursor
    // https://msdn.microsoft.com/en-us/library/ms180152(v=sql.120).aspx
    | fetch_cursor
    // https://msdn.microsoft.com/en-us/library/ms190500(v=sql.120).aspx
    | OPEN GLOBAL? cursor_name SEMI?
    ;

checkpoint_statement
    : CHECKPOINT chkptduration=DECIMAL?
    ;

restore_database
    : RESTORE DATABASE ( database_name=id | LOCAL_ID )
          (files_or_filegroups (COMMA files_or_filegroups)*)?
          FROM (COMMA? backup_device)+
          (WITH restore_options (COMMA? restore_options)* )?
    ;

files_or_filegroups
    : READ_WRITE_FILEGROUPS
    | (FILE|FILEGROUP) EQUAL (char_string|LOCAL_ID)
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/backup-transact-sql
backup_database
    : BACKUP DATABASE ( database_name=id | LOCAL_ID )
          (files_or_filegroups (COMMA files_or_filegroups)*)?
          TO (COMMA? backup_device)+
          (MIRROR TO (COMMA? backup_device)+)?
          (WITH backup_options (COMMA backup_options)* )?
    ;

backup_log
    : BACKUP LOG ( database_name=id | LOCAL_ID )
          (TO (COMMA? backup_device)+)?
          (MIRROR TO (COMMA? backup_device)+)?
          (WITH backup_options (COMMA backup_options)* )?
    ;

backup_device
    : (DISK|TAPE|URL) EQUAL (char_string|LOCAL_ID)
    | LOCAL_ID
    | id
    ;

backup_options
    : backup_option
    | backup_restore_option
    ;

restore_options
    : restore_option
    | backup_restore_option
    ;

backup_option
    : DIFFERENTIAL
    | COPY_ONLY
    | (COMPRESSION|NO_COMPRESSION)
    | DESCRIPTION EQUAL (char_string|id|LOCAL_ID)
    | NAME EQUAL (id|LOCAL_ID)
    | CREDENTIAL
    | FILE_SNAPSHOT
    | (EXPIREDATE EQUAL (char_string|id|LOCAL_ID) | RETAINDAYS EQUAL (DECIMAL|id|LOCAL_ID) )
    | (NOINIT|INIT)
    | (NOSKIP|SKIP_KEYWORD)
    | (NOFORMAT|FORMAT)
    | RESTART
    | ENCRYPTION LR_BRACKET ALGORITHM EQUAL ( AES_128 | AES_192 | AES_256 | TRIPLE_DES_3KEY )
                                    COMMA (SERVER CERTIFICATE EQUAL encryptor_name=id | SERVER ASYMMETRIC KEY EQUAL encryptor_name=id)
                 RR_BRACKET
	// log backup options:
    | (NORECOVERY| STANDBY EQUAL (char_string|LOCAL_ID))
    | NO_TRUNCATE
    | NO_LOG
    ;

restore_option
    : (RECOVERY | NORECOVERY | STANDBY) EQUAL (char_string |LOCAL_ID)
    | MOVE (char_string|LOCAL_ID) TO (char_string|LOCAL_ID)
	| REPLACE
	| RESTART
	| RESTRICTED_USER
	| CREDENTIAL
	| FILE EQUAL (char_string|LOCAL_ID)
	| PASSWORD EQUAL (char_string|LOCAL_ID)
	| KEEP_REPLICATION
	| KEEP_CDC
	| FILESTREAM LR_BRACKET DIRECTORY_NAME EQUAL (char_string|LOCAL_ID) RR_BRACKET
	| ENABLE_BROKER
	| ERROR_BROKER_CONVERSATIONS
	| NEW_BROKER
	| STOPAT EQUAL (char_string|LOCAL_ID)
	| STOPATMARK EQUAL (char_string) (AFTER (char_string|LOCAL_ID))?
	| STOPBEFOREMARK EQUAL (char_string) (AFTER (char_string|LOCAL_ID))?
    ;

backup_restore_option
    : MEDIADESCRIPTION EQUAL (char_string|id|LOCAL_ID)
    | MEDIANAME EQUAL (char_string|LOCAL_ID)
    | BLOCKSIZE EQUAL (DECIMAL|id|LOCAL_ID)
    | BUFFERCOUNT EQUAL (DECIMAL|id|LOCAL_ID)
    | MAXTRANSFER EQUAL (DECIMAL|id|LOCAL_ID)
    | (NO_CHECKSUM|CHECKSUM)
    | (STOP_ON_ERROR|CONTINUE_AFTER_ERROR)
    | STATS (EQUAL (DECIMAL|LOCAL_ID))?
    | (REWIND|NOREWIND)
    | (LOAD|NOUNLOAD)
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/backup-certificate-transact-sql
backup_certificate
    : BACKUP CERTIFICATE certname=id TO FILE EQUAL cert_file=char_string
       ( WITH PRIVATE KEY
 LR_BRACKET
             (COMMA? FILE EQUAL private_key_file=char_string
             |COMMA? ENCRYPTION BY PASSWORD EQUAL encryption_password=char_string
             |COMMA? DECRYPTION BY PASSWORD EQUAL decryption_pasword=char_string
             )+
 RR_BRACKET
       )?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/backup-master-key-transact-sql
backup_master_key
    : BACKUP MASTER KEY TO FILE EQUAL master_key_backup_file=char_string
         ENCRYPTION BY PASSWORD EQUAL encryption_password=char_string
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/statements/backup-service-master-key-transact-sql
backup_service_master_key
    : BACKUP SERVICE MASTER KEY TO FILE EQUAL service_master_key_backup_file=char_string
         ENCRYPTION BY PASSWORD EQUAL encryption_password=char_string
    ;

kill_statement
    : KILL (kill_process | kill_query_notification | kill_stats_job)
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/kill-transact-sql
kill_process
    : ((DECIMAL|char_string) | UOW) (WITH STATUSONLY)?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/kill-query-notification-subscription-transact-sql
kill_query_notification
    : QUERY NOTIFICATION SUBSCRIPTION (ALL | subscription_id=DECIMAL)
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/kill-stats-job-transact-sql
kill_stats_job
    : STATS JOB job_id=DECIMAL
    ;

// https://msdn.microsoft.com/en-us/library/ms188332.aspx
execute_statement
    : (EXECUTE|EXEC) execute_body SEMI?
    ;

execute_body_batch
    : func_proc_name_server_database_schema execute_statement_arg? (WITH execute_option (COMMA execute_option)* )? SEMI?
    ;

execute_body
    : (return_status=LOCAL_ID EQUAL)? (func_proc_name_server_database_schema (SEMI proc_version=DECIMAL)? | proc_var=LOCAL_ID)  execute_statement_arg? (WITH execute_option (COMMA execute_option)* )?
    | LR_BRACKET execute_var_string (PLUS execute_var_string)* RR_BRACKET (execute_var_string_option (COMMA execute_var_string_option)* )?
    ;
  
execute_var_string_option
    : AS (LOGIN | USER) EQUAL char_string
    | AT_KEYWORD linked_server=id
    | AT_KEYWORD DATA_SOURCE id
    ;

execute_statement_arg
    :
    execute_statement_arg_unnamed (COMMA execute_statement_arg)?     //Unnamed params can continue unnamed
    |
    execute_statement_arg_named (COMMA execute_statement_arg_named)* //Named can only be continued by unnamed
    ;    

execute_statement_arg_named
    : name=local_id  EQUAL  value=execute_parameter
    ;

execute_statement_arg_unnamed
    : value=execute_parameter
    ;

execute_parameter
    : constant   
    | local_id (OUTPUT | OUT)?
    | id
    | DEFAULT    
    ;    

execute_var_string
    : local_id
    | char_string
    ;
    
execute_option
    : RECOMPILE
    | RESULT SETS (NONE |UNDEFINED)
    | RESULT SETS LR_BRACKET (COMMA? LR_BRACKET schema_declaration RR_BRACKET)+ RR_BRACKET (AS (OBJECT full_object_name | TYPE full_object_name | FOR XML) )?
    ;

security_statement
    : ( execute_as_statement
    | revert_statement
    | grant_statement
    | revoke_statement
    | deny_statement    
    | open_key
    | close_key
    | create_certificate ) SEMI?
    ;    

grant_statement
    : GRANT (ALL PRIVILEGES? | permissions) (ON permission_object)? TO principals (WITH GRANT OPTION)? (AS principal_id)? 
    ;     
        
revoke_statement
    : REVOKE (GRANT OPTION FOR)? (ALL PRIVILEGES? | permissions) (ON permission_object)? (TO|FROM) principals CASCADE? (AS principal_id)? 
    ;

deny_statement
    : DENY (ALL PRIVILEGES? | permissions) (ON permission_object)? TO principals CASCADE? (AS principal_id)? 
    ;
     
permission_object
    : (permission_object_type colon_colon)? full_object_name (LR_BRACKET column_name_list RR_BRACKET)? 
    ;

principals
    : principal_id (COMMA principal_id)*
    ;

permissions
    : permission (COMMA permission)*
    ;
    
permission
    : single_permission (LR_BRACKET column_name_list RR_BRACKET)? 
    ;  
    
single_permission
    : (EXECUTE|EXEC) (ANY EXTERNAL SCRIPT)?
    | CREATE ANY? object_type?
    | ALTER ANY? object_type?
    | SELECT (ALL USER SECURABLES)?
    | INSERT
    | UPDATE
    | DELETE
    | REFERENCES
    | CONTROL SERVER?
    | IMPERSONATE (ANY LOGIN)?
    | CHECKPOINT
    | CONNECT (REPLICATION | SQL | ANY DATABASE)?
    | SEND
    | RECEIVE
    | VIEW DEFINITION
    | TAKE OWNERSHIP
    | VIEW ANY? object_type
    | AUTHENTICATE SERVER?
    | SHOWPLAN
    | BACKUP (DATABASE | LOG)
    | ADMINISTER DATABASE? BULK OPERATIONS
    | EXTERNAL ACCESS ASSEMBLY
    | SHUTDOWN
    | KILL DATABASE CONNECTION    
    | SUBSCRIBE QUERY NOTIFICATIONS
    | UNMASK
    | UNSAFE ASSEMBLY
    ;

permission_object_type
    : (APPLICATION|SERVER)? ROLE
    | ASSEMBLY
    | (ASYMMETRIC|SYMMETRIC) KEY
    | AVAILABILITY GROUP
    | CERTIFICATE
    | CONTRACT
    | DATABASE (SCOPED CREDENTIAL)?
    | ENDPOINT
    | FULLTEXT (CATALOG|STOPLIST)
    | LOGIN
    | (MESSAGE)? TYPE
    | OBJECT
    | REMOTE SERVICE BINDING
    | ROUTE
    | SCHEMA
    | SEARCH PROPERTY LIST
    | SERVICE
    | USER
    | XML SCHEMA COLLECTION
    ;

object_type
	: AGGREGATE
    | APPLICATION ROLE
	| ASSEMBLY
	| ASYMMETRIC KEY
	| AVAILABILITY GROUP
	| CERTIFICATE
	| CHANGE TRACKING
	| COLUMN ( ENCRYPTION | MASTER ) KEY DEFINITION?
	| CONNECTION
	| CONTRACT
	| CREDENTIAL
	| DATABASE (AUDIT|DDL? EVENT (NOTIFICATION|SESSION)|DDL TRIGGER|SCOPED CONFIGURATION|STATE)?
	| DATASPACE
	| DDL EVENT NOTIFICATION
	| DEFAULT
	| ENDPOINT
	| EVENT ( NOTIFICATION | SESSION )
	| EXTERNAL (DATA SOURCE | FILE FORMAT | LIBRARY)
	| FULLTEXT CATALOG	
	| FULLTEXT STOPLIST    
	| FUNCTION
    | LINKED SERVER	
    | LOGIN
    | MASK
	| MESSAGE TYPE
	| OBJECT
	| PROCEDURE
	| QUEUE
	| REMOTE SERVICE BINDING
    | RESOURCES
	| ROLE
	| ROUTE
	| RULE
	| SCHEMA	
	| SECURITY POLICY
	| SEARCH PROPERTY LIST    	
	| SEQUENCE
	| SERVER (AUDIT|ROLE|STATE)
	| SERVICE
	| SETTINGS
	| SYMMETRIC KEY
	| SYNONYM
	| TABLE
	| TRACE (EVENT NOTIFICATION)?
	| TYPE
	| USER
	| VIEW
	| XML SCHEMA COLLECTION
    ;
                         
principal_id
    : id
    | PUBLIC
    ;

create_certificate
    : CREATE CERTIFICATE certificate_name=id (AUTHORIZATION user_name=id)?
      (FROM existing_keys | generate_new_keys)
      (ACTIVE FOR BEGIN DIALOG  EQUAL  (ON | OFF))?
    ;

existing_keys
    : ASSEMBLY assembly_name=id
    | EXECUTABLE? FILE EQUAL path_to_file=char_string (WITH PRIVATE KEY LR_BRACKET private_key_options RR_BRACKET )?
    ;

private_key_options
    : (FILE | hex_string)  EQUAL  path=char_string (COMMA (DECRYPTION | ENCRYPTION) BY PASSWORD  EQUAL  password=char_string)?
    ;

generate_new_keys
    : (ENCRYPTION BY PASSWORD  EQUAL  password=char_string)?
      WITH SUBJECT EQUAL certificate_subject_name=char_string (COMMA date_options)*
    ;

date_options
    : (START_DATE | EXPIRY_DATE) EQUAL char_string
    ;

open_key
    : OPEN SYMMETRIC KEY key_name=id DECRYPTION BY decryption_mechanism
    | OPEN MASTER KEY DECRYPTION BY PASSWORD  EQUAL  password=char_string
    ;

close_key
    : CLOSE SYMMETRIC KEY key_name=id
    | CLOSE ALL SYMMETRIC KEYS
    | CLOSE MASTER KEY
    ;

key_options
    : KEY_SOURCE EQUAL pass_phrase=char_string
    | ALGORITHM EQUAL algorithm
    | IDENTITY_VALUE EQUAL identity_phrase=char_string
    | PROVIDER_KEY_NAME EQUAL key_name_in_provider=char_string
    | CREATION_DISPOSITION EQUAL (CREATE_NEW | OPEN_EXISTING)
    ;

algorithm
    : DES
    | TRIPLE_DES
    | TRIPLE_DES_3KEY
    | RC2
    | RC4
    | RC4_128
    | DESX
    | AES_128
    | AES_192
    | AES_256
    ;

encryption_mechanism
    : CERTIFICATE certificate_name=id
    | ASYMMETRIC KEY asym_key_name=id
    | SYMMETRIC KEY decrypting_Key_name=id
    | PASSWORD  EQUAL  char_string
    ;

decryption_mechanism
    : CERTIFICATE certificate_name=id (WITH PASSWORD EQUAL char_string)?
    | ASYMMETRIC KEY asym_key_name=id (WITH PASSWORD EQUAL char_string)?
    | SYMMETRIC KEY decrypting_Key_name=id
    | PASSWORD EQUAL char_string
    ;

// https://msdn.microsoft.com/en-us/library/ms190356.aspx
// https://msdn.microsoft.com/en-us/library/ms189484.aspx
set_statement
    : SET LOCAL_ID (DOT member_name=id)?  EQUAL  expression SEMI?
    | SET LOCAL_ID assignment_operator expression SEMI?
    | SET LOCAL_ID  EQUAL
      CURSOR declare_cursor_options* FOR select_statement_standalone (FOR (READ ONLY | UPDATE (OF column_name_list)?))? SEMI?
    // https://msdn.microsoft.com/en-us/library/ms189837.aspx
    | set_special SEMI?
    ;

// https://msdn.microsoft.com/en-us/library/ms174377.aspx
transaction_statement
    // https://msdn.microsoft.com/en-us/library/ms188386.aspx
    : BEGIN DISTRIBUTED (TRAN | TRANSACTION) (id | local_id)? SEMI?
    // https://msdn.microsoft.com/en-us/library/ms188929.aspx
    | BEGIN (TRAN | TRANSACTION) ((id | local_id) (WITH MARK char_string)?)? SEMI?
    // https://msdn.microsoft.com/en-us/library/ms190295.aspx
    | COMMIT (TRAN | TRANSACTION) (id | local_id)? (WITH LR_BRACKET DELAYED_DURABILITY EQUAL (OFF | ON) RR_BRACKET )? SEMI?
    // https://msdn.microsoft.com/en-us/library/ms178628.aspx
    | COMMIT WORK? SEMI?
    | COMMIT id
    | ROLLBACK id
    // https://msdn.microsoft.com/en-us/library/ms181299.aspx
    | ROLLBACK (TRAN | TRANSACTION) (id | local_id)? SEMI?
    // https://msdn.microsoft.com/en-us/library/ms174973.aspx
    | ROLLBACK WORK? SEMI?
    // https://msdn.microsoft.com/en-us/library/ms188378.aspx
    | SAVE (TRAN | TRANSACTION) (id | local_id)? SEMI?
    ;

// https://msdn.microsoft.com/en-us/library/ms188366.aspx
use_statement
    : USE dbname=id SEMI?
    ;

setuser_statement
    : SETUSER user=char_string?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/reconfigure-transact-sql
reconfigure_statement
    : RECONFIGURE (WITH OVERRIDE)?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/shutdown-transact-sql
shutdown_statement
    : SHUTDOWN (WITH NOWAIT)?
    ;

dbcc_statement
    : DBCC CHECKIDENT ( LR_BRACKET dbcc_table_name ( (COMMA NORESEED) | (COMMA RESEED (COMMA MINUS? checkident_new_value)?) )? RR_BRACKET ) (WITH dbcc_options)? SEMI?
    | DBCC name=dbcc_command ( LR_BRACKET expression_list RR_BRACKET )? (WITH dbcc_options)? SEMI?
    //These are dbcc commands with strange syntax that doesn't fit the regular dbcc syntax
    | DBCC SHRINKLOG ( LR_BRACKET SIZE  EQUAL   (constant_expression| id | DEFAULT) (KB | MB | GB | TB)? RR_BRACKET )? (WITH dbcc_options)? SEMI?
    ;

dbcc_command
    : ID
    | CHECKDB
    | CHECKFILEGROUP
    | CHECKTABLE
    | CLEANTABLE
    | CLONEDATABASE
    | DBREINDEX
    | DROPCLEANBUFFERS
    | FREEPROCCACHE
    | FREESESSIONCACHE
    | FREESYSTEMCACHE
    | HELP
    | INDEXDEFRAG
    | INPUTBUFFER
    | OPENTRAN
    | OUTPUTBUFFER
    | PROCCACHE
    | SHOW_STATISTICS
    | SHOWCONTIG
    | SHRINKDATABASE
    | SHRINKFILE
    | SQLPERF
    | TRACEOFF
    | TRACEON
    | TRACESTATUS
    | UPDATEUSAGE
    | USEROPTIONS
    ;

dbcc_options
    :  ID (COMMA ID)?
    ;

dbcc_table_name
    : table = id
    | char_string
    | local_id
    ;

checkident_new_value
    : DECIMAL
    | FLOAT
    | local_id
    ;

execute_as_clause
    : (EXECUTE|EXEC) AS (CALLER | SELF | OWNER | char_string)
    ;

execute_as_statement
    : (EXECUTE|EXEC) AS ( CALLER | ( LOGIN | USER ) EQUAL char_string (WITH (NO REVERT | COOKIE INTO LOCAL_ID ))? )
    ;

revert_statement
    : REVERT (LR_BRACKET WITH COOKIE EQUAL LOCAL_ID RR_BRACKET)?
    ;

declare_local
    : LOCAL_ID AS? data_type ( EQUAL  expression)?
    ;

table_type_definition
    : TABLE LR_BRACKET column_def_table_constraints (COMMA? table_type_indices)* RR_BRACKET
    ;

table_type_indices
    :  ((PRIMARY KEY | UNIQUE) clustered?) LR_BRACKET column_name_list_with_order RR_BRACKET
    | inline_index
    | CHECK LR_BRACKET search_condition RR_BRACKET
    ;

xml_type_definition
    : id LR_BRACKET ( CONTENT | DOCUMENT )? xml_schema_collection RR_BRACKET
    | XML COLUMN_SET FOR ALL_SPARSE_COLUMNS
    ;

xml_schema_collection
    : id (DOT id)?
    ;

column_def_table_constraints
    : column_def_table_constraint (COMMA? column_def_table_constraint)*
    ;

column_def_table_constraint
    : column_definition
    | table_constraint
    | period_for_system_time
    ;

// https://msdn.microsoft.com/en-us/library/ms187742.aspx
// empirically found: ROWGUIDCOL can be in various locations
column_definition
    : simple_column_name (data_type system_versioning_column? | AS expression PERSISTED? ) ( special_column_option | collation | null_notnull )*
      ( column_constraint* IDENTITY (LR_BRACKET sign? seed=DECIMAL COMMA sign? increment=DECIMAL RR_BRACKET)? )? for_replication? ROWGUIDCOL?
      column_constraint* inline_index?
    | TIMESTAMP null_notnull? column_constraint?
    ;

// Temporary workaround for COLLATE default in INSERT BULK
insert_bulk_column_definition
    : simple_column_name (data_type system_versioning_column? | AS expression PERSISTED? ) ( special_column_option | (COLLATE (id | DEFAULT)) | null_notnull )*
      ( column_constraint* IDENTITY (LR_BRACKET sign? seed=DECIMAL COMMA sign? increment=DECIMAL RR_BRACKET)? )? for_replication? ROWGUIDCOL?
      column_constraint* inline_index?
    ;

inline_index
    : INDEX id UNIQUE? clustered? COLUMNSTORE? (LR_BRACKET column_name_list_with_order RR_BRACKET)?
      (WHERE where=search_condition)?
      with_index_options?
      (ON storage_partition_clause)?
      (FILESTREAM_ON storage_partition_clause)?
    ;

special_column_option
    : FILESTREAM
    | SPARSE
    | ROWGUIDCOL
    | HIDDEN_RENAMED
    | PERSISTED
    | MASKED ( WITH LR_BRACKET FUNCTION EQUAL char_string RR_BRACKET )?
    | column_encrypted
    | for_replication
    ;
    
column_encrypted
    : ENCRYPTED WITH LR_BRACKET column_encrypted_option (COMMA column_encrypted_option)* RR_BRACKET
    ;
    
column_encrypted_option
    : COLUMN_ENCRYPTION_KEY EQUAL id
    | ENCRYPTION_TYPE EQUAL ( DETERMINISTIC | RANDOMIZED )
    | ALGORITHM EQUAL char_string
    ;
        
system_versioning_column
    : GENERATED ALWAYS AS (ROW|TRANSACTION_ID|SEQUENCE_NUMBER) (START|END) HIDDEN_RENAMED? 
    ;

period_for_system_time
    : PERIOD FOR SYSTEM_TIME (LR_BRACKET id COMMA id RR_BRACKET)?
    ;

system_versioning_options
    : LR_BRACKET system_versioning_option (COMMA system_versioning_option)* RR_BRACKET
    ;

system_versioning_option
    : SYSTEM_VERSIONING EQUAL on_off 
    | LEDGER EQUAL on_off sub_options?
    | DATA_CONSISTENCY_CHECK EQUAL on_off
    | HISTORY_RETENTION_PERIOD EQUAL ( INFINITE | DECIMAL (DAY|DAYS|WEEK|WEEKS|MONTH|MONTHS|YEAR|YEARS) )
    | history_table_option
    ;

history_table_option
    : HISTORY_TABLE EQUAL table_name
    | LR_BRACKET history_table_option RR_BRACKET
    ;

for_system_time
    : FOR SYSTEM_TIME for_system_time_range
    ;

for_system_time_range
    : ALL
    | AS OF (char_string|LOCAL_ID)
    | BETWEEN (char_string|LOCAL_ID) AND (char_string|LOCAL_ID)
    | CONTAINED IN LR_BRACKET (char_string|LOCAL_ID) COMMA (char_string|LOCAL_ID) RR_BRACKET
    | FROM (char_string|LOCAL_ID) TO (char_string|LOCAL_ID)
    ;

for_replication
    : (NOT? FOR REPLICATION)
    ;

// https://msdn.microsoft.com/en-us/library/ms186712.aspx
column_constraint
    :(CONSTRAINT constraint=id)?
      ((PRIMARY KEY | UNIQUE) clustered? with_index_options?
      | CHECK for_replication? LR_BRACKET search_condition RR_BRACKET
      | (FOREIGN KEY)? REFERENCES table_name (LR_BRACKET pk = column_name_list RR_BRACKET)? (on_update | on_delete)*  for_replication?
      | DEFAULT expression
      | null_notnull
      | WITH VALUES 
      | CONNECTION LR_BRACKET table_name TO table_name (COMMA table_name TO table_name)* RR_BRACKET
     )
    ;

// https://msdn.microsoft.com/en-us/library/ms188066.aspx
table_constraint
    : (CONSTRAINT constraint=id)?
       ((PRIMARY KEY | UNIQUE) clustered? LR_BRACKET column_name_list_with_order RR_BRACKET with_index_options? (ON storage_partition_clause)?
         | CHECK for_replication? LR_BRACKET search_condition RR_BRACKET
         | DEFAULT expression (FOR id)?  
         | FOREIGN KEY LR_BRACKET fk = column_name_list RR_BRACKET REFERENCES table_name (LR_BRACKET pk = column_name_list RR_BRACKET)? (on_update | on_delete)* ) for_replication?
    ;

on_update
    : ON UPDATE (NO ACTION | CASCADE | SET NULL_P | SET DEFAULT)
    ;

on_delete
    : ON DELETE (NO ACTION | CASCADE | SET NULL_P | SET DEFAULT)
    ;

with_index_options
    : WITH index_option_list
    | WITH LR_BRACKET index_option_list RR_BRACKET
    ;
    
index_option_list
    : index_option (COMMA index_option)*
    ;

// https://msdn.microsoft.com/en-us/library/ms186869.aspx
// Id runtime checking. Id in (PAD_INDEX, FILLFACTOR, IGNORE_DUP_KEY, STATISTICS_NORECOMPUTE, ALLOW_ROW_LOCKS,
// ALLOW_PAGE_LOCKS, SORT_IN_TEMPDB, ONLINE, MAXDOP, DATA_COMPRESSION).
index_option
    : option_id=id (EQUAL (set_id=id | on_off | DECIMAL))?  sub_options?
    ;

sub_options
    : LR_BRACKET sub_option (sub_options? | (COMMA sub_option)*) RR_BRACKET
    ;
 
sub_option
    : id EQUAL expression keyword?    // keyword is for cases like 'RETENTION_PERIOD = 1 WEEKS'
    | low_priority_lock_wait
    ;
    
// https://msdn.microsoft.com/en-us/library/ms180169.aspx
declare_cursor
    : DECLARE cursor_name INSENSITIVE? SCROLL? CURSOR declare_cursor_options*
      FOR select_statement_standalone (FOR (READ ONLY | UPDATE (OF full_column_name_list)?))?
    ;

declare_cursor_options
    : (LOCAL | GLOBAL)
    | (FORWARD_ONLY | SCROLL)
    | (STATIC | KEYSET | DYNAMIC | FAST_FORWARD)
    | (READ_ONLY | SCROLL_LOCKS | OPTIMISTIC)
    | TYPE_WARNING
    ;

fetch_cursor
    : FETCH ((NEXT | PRIOR | FIRST | LAST | (ABSOLUTE | RELATIVE) expression)? FROM)?
      GLOBAL? cursor_name (INTO LOCAL_ID (COMMA LOCAL_ID)*)? SEMI?
    ;

// https://msdn.microsoft.com/en-us/library/ms190356.aspx
set_special
    : SET set_on_off_option (COMMA set_on_off_option)* on_off 
    | SET STATISTICS set_statistics_keyword (COMMA set_statistics_keyword)* on_off
    | SET OFFSETS set_offsets_keyword (COMMA set_offsets_keyword)* on_off
    | SET special_variable LOCAL_ID
    | SET id_set=id (id_val=id | constant_LOCAL_ID | on_off) 
    | SET ROWCOUNT DECIMAL
    // https://msdn.microsoft.com/en-us/library/ms173763.aspx
    | SET (TRAN | TRANSACTION) ISOLATION LEVEL (READ UNCOMMITTED | READ COMMITTED | REPEATABLE READ | SNAPSHOT | SERIALIZABLE | DECIMAL) 
    // https://msdn.microsoft.com/en-us/library/ms188059.aspx
    | SET IDENTITY_INSERT table_name on_off 
    | SET TEXTSIZE DECIMAL     
    | SET xml_modify_method    
    | SET BABELFISH_STATISTICS PROFILE on_off
    ;    

special_variable
    : DATEFIRST
    | ROWCOUNT
    | LANGUAGE
    ;

set_on_off_option
    : ANSI_DEFAULTS
    | ANSI_NULLS
    | ANSI_NULL_DFLT_OFF
    | ANSI_NULL_DFLT_ON
    | ANSI_PADDING
    | ANSI_WARNINGS
    | ARITHABORT
    | ARITHIGNORE
    | CONCAT_NULL_YIELDS_NULL
    | CURSOR_CLOSE_ON_COMMIT
    | FIPS_FLAGGER
    | FMTONLY
    | FORCEPLAN
    | IMPLICIT_TRANSACTIONS
    | NOCOUNT
    | NOEXEC
    | NUMERIC_ROUNDABORT    
    | PARSEONLY
    | QUOTED_IDENTIFIER
    | REMOTE_PROC_TRANSACTIONS
    | SHOWPLAN_ALL
    | SHOWPLAN_TEXT
    | SHOWPLAN_XML
    | XACT_ABORT
    | BABELFISH_SHOWPLAN_ALL
    | NO_BROWSETABLE
    ;
    
set_statistics_keyword  
    : IO
    | PROFILE
    | TIME
    | XML
    ;  

set_offsets_keyword
    : SELECT
    | FROM
    | ORDER
    | TABLE
    | (PROCEDURE|PROC)
    | STATEMENT
    | PARAM
    | (EXECUTE|EXEC)
    ;

constant_LOCAL_ID
    : constant
    | local_id
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/expressions-transact-sql
// Operator precendence: https://docs.microsoft.com/en-us/sql/t-sql/language-elements/operator-precedence-transact-sql
expression
    : clr_udt_func_call                                                         #clr_udt_expr
    | expression collation                                                      #collate_expr
    | expression AT_KEYWORD TIME ZONE expression                                #time_zone_expr
    | op=(MINUS | PLUS | BIT_NOT) expression                                    #unary_op_expr
    | expression op=(STAR | DIVIDE | PERCENT_SIGN ) expression                  #mult_div_percent_expr
    | expression op=(PLUS | MINUS | BIT_AND | BIT_XOR | BIT_OR ) expression     #plus_minus_bit_expr
    | constant                                                                  #constant_expr
    | full_column_name                                                          #full_col_name_expr
    | DEFAULT                                                                   #default_expr
    | case_expression                                                           #case_expr
    | hierarchyid_coloncolon_methods                                            #hierarchyid_coloncolon
    | spatial_coloncolon_methods                                                #spatial_coloncolon
    | over_clause                                                               #over_clause_expr
    | odbc_literal                                                              #odbc_literal_expr
    | DOLLAR_ACTION                                                             #dollar_action_expr
    | expression vector_operator expression                                     #vector_expr
    ;       

clr_udt_func_call
    : local_id (DOT calls+=method_call)*
    | subquery (DOT calls+=method_call)*
    | LR_BRACKET expression RR_BRACKET (DOT calls+=method_call)*
    | function_call (DOT calls+=method_call)*
    ;

method_call
    : xml_methods
    | hierarchyid_methods
    | spatial_methods
    | method=id (LR_BRACKET expression_list? RR_BRACKET)?
    | NULL_P // no bracket
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/case-transact-sql
case_expression
    : CASE caseExpr=expression switch_section+ (ELSE elseExpr=expression)? END
    | CASE switch_search_condition_section+ (ELSE elseExpr=expression)? END
    ;

constant_expression
    : constant
    | LOCAL_ID
    | LR_BRACKET constant_expression RR_BRACKET
    ;

subquery
    : LR_BRACKET select_statement RR_BRACKET
    ;

// https://msdn.microsoft.com/en-us/library/ms175972.aspx
with_expression
    : WITH (XMLNAMESPACES LR_BRACKET xml_dec+=xml_declaration (COMMA xml_dec+=xml_declaration)* RR_BRACKET COMMA?)? (ctes+=common_table_expression (COMMA ctes+=common_table_expression)*)?
    ;

common_table_expression
    : expression_name=id ( LR_BRACKET columns=column_name_list RR_BRACKET )? AS LR_BRACKET cte_query=select_statement RR_BRACKET
    ;

update_elem
    : LOCAL_ID  EQUAL  full_column_name ( EQUAL  | assignment_operator) expression //Combined variable and column update
    | (full_column_name | LOCAL_ID) ( EQUAL  | assignment_operator) expression
    | udt_column_name=id DOT method_name=id LR_BRACKET expression_list RR_BRACKET
    ;

update_elem_merge
    : (full_column_name | LOCAL_ID) ( EQUAL  | assignment_operator) expression
    | udt_column_name=id DOT method_name=id LR_BRACKET expression_list RR_BRACKET
    ;

search_condition
    : pred+=predicate_br (log=(OR | AND) pred+=predicate_br)*
    ;

predicate_br
    : NOT* predicate
    | NOT* LR_BRACKET search_condition RR_BRACKET
    ;

predicate
    : EXISTS subquery
    | freetext_predicate
    | expression comparison_operator expression
    | expression comparison_operator (ALL | SOME | ANY)   subquery
    | expression NOT? IN  subquery
    | expression NOT? BETWEEN expression AND expression
    | expression NOT? IN LR_BRACKET expression_list RR_BRACKET
    | expression NOT? LIKE expression (ESCAPE expression)?
    | expression IS null_notnull
    | trigger_column_updated
    ;    
    
query_expression
    : (query_specification order_by_qs=order_by_clause? | LR_BRACKET query_expression order_by_qe=order_by_clause? RR_BRACKET ) sql_union*
    ;

// this accepts ORDER BY also when it is not in the last part of the UNION
sql_union
    : union_keyword (query_specification order_by_qs=order_by_clause? | LR_BRACKET query_expression order_by_qe=order_by_clause? RR_BRACKET )
    ;
    
union_keyword
    : (UNION ALL? | EXCEPT | INTERSECT)
    ;

query_specification
    : SELECT allOrDistinct=(ALL | DISTINCT)? top=top_clause?
      columns=select_list
      // https://msdn.microsoft.com/en-us/library/ms188029.aspx
      (INTO into=table_name)?
      (FROM from=table_sources)?
      (WHERE where=search_condition)?
      // https://msdn.microsoft.com/en-us/library/ms177673.aspx
      (GROUP BY groupByAll=ALL? group_by_item (COMMA group_by_item)* with_rollup_cube? )?
      (HAVING having=search_condition)?
    ;

// https://msdn.microsoft.com/en-us/library/ms189463.aspx
top_clause
    : TOP (top_percent | top_count) (WITH TIES)?
    ;

top_percent
    : percent_constant=(REAL | FLOAT | DECIMAL) PERCENT
    | LR_BRACKET topper_expression=expression RR_BRACKET PERCENT
    ;

top_count
    : count_constant=DECIMAL
    | LR_BRACKET topcount_expression=expression RR_BRACKET
    | subquery
    ;

// https://msdn.microsoft.com/en-us/library/ms188385.aspx
order_by_clause
    : ORDER BY order_bys+=order_by_expression (COMMA order_bys+=order_by_expression)*
      (OFFSET offset_exp=expression offset_rows=(ROW | ROWS) (FETCH fetch_offset=(FIRST | NEXT) fetch_exp=expression fetch_rows=(ROW | ROWS) ONLY)?)?
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/queries/select-for-clause-transact-sql
for_clause
    : FOR BROWSE
    | FOR XML (RAW ( LR_BRACKET char_string RR_BRACKET )? | AUTO) 
      ( xml_common_directives | (COMMA (XMLDATA | XMLSCHEMA ( LR_BRACKET char_string RR_BRACKET )?)) | (COMMA ELEMENTS (XSINIL | ABSENT)?) )*
    | FOR XML EXPLICIT ( xml_common_directives | COMMA XMLDATA)*
    | FOR XML PATH ( LR_BRACKET char_string RR_BRACKET )? (xml_common_directives | COMMA ELEMENTS (XSINIL | ABSENT)?)*
    
    | FOR JSON (AUTO | PATH)
      ( (COMMA ROOT ( LR_BRACKET char_string RR_BRACKET )?)
        | (COMMA INCLUDE_NULL_VALUES)
        | (COMMA WITHOUT_ARRAY_WRAPPER)
      )*
    ;

xml_common_directives
    : COMMA (BINARY_KEYWORD BASE64 | TYPE | ROOT ( LR_BRACKET char_string RR_BRACKET )?)
    ;

order_by_expression 
    : order_by=expression (ascending=ASC | descending=DESC)?
    ;

group_by_item
    : expression 
    | full_column_name with_distributed_agg
    | group_rollup_spec
    | group_cube_spec
    | grouping_sets_spec
    | group_grand_total_spec	
    ;

group_rollup_spec
    : ROLLUP LR_BRACKET expression_list RR_BRACKET
    ;

group_cube_spec
    : CUBE LR_BRACKET expression_list RR_BRACKET
    ;
   
grouping_sets_spec
    : GROUPING SETS LR_BRACKET grouping_set_expression_list RR_BRACKET
    ;

grouping_set_expression_list
    : LR_BRACKET grouping_set_expression_list RR_BRACKET (COMMA grouping_set_expression_list)*
    | grouping_set_expression (COMMA grouping_set_expression)*
    ;
    
grouping_set_expression
    : expression
    | group_rollup_spec 
    | group_cube_spec 
    | group_grand_total_spec
    ;
    
group_grand_total_spec
    : LR_BRACKET RR_BRACKET
    ;

with_rollup_cube
    : WITH (CUBE | ROLLUP)    
    ;

with_distributed_agg
    :  WITH LR_BRACKET DISTRIBUTED_AGG RR_BRACKET
    ;      

option_clause
    // https://msdn.microsoft.com/en-us/library/ms181714.aspx
    : OPTION LR_BRACKET options+=option (COMMA options+=option)* RR_BRACKET
    ;

// these are query hints:
option
    : ( HASH | ORDER ) GROUP
    | ( MERGE | HASH | CONCAT ) UNION
    | ( LOOP | MERGE | HASH ) JOIN
    | ( FORCE | DISABLE ) EXTERNALPUSHDOWN
    | ( FORCE | DISABLE ) SCALEOUTEXECUTION
    | ( KEEP | KEEPFIXED ) PLAN
    | EXPAND VIEWS
    | FAST number_rows=DECIMAL
    | FORCE ORDER
    | IGNORE_NONCLUSTERED_COLUMNSTORE_INDEX
    | MAX_GRANT_PERCENT EQUAL expression
    | MIN_GRANT_PERCENT EQUAL expression
    | MAXDOP number_of_processors=DECIMAL
    | MAXRECURSION number_recursion=DECIMAL
    | NO_PERFORMANCE_SPOOL
    | OPTIMIZE FOR LR_BRACKET optimize_for_arg (COMMA optimize_for_arg)* RR_BRACKET
    | OPTIMIZE FOR UNKNOWN
    | PARAMETERIZATION (SIMPLE | FORCED)
    | QUERYTRACEON traceflag=DECIMAL
    | RECOMPILE
    | ROBUST PLAN
    | TABLE HINT LR_BRACKET table_name COMMA table_hint (COMMA table_hint)* RR_BRACKET
    | USE PLAN char_string
    | USE HINT LR_BRACKET char_string (COMMA char_string)* RR_BRACKET
    ;

optimize_for_arg
    : LOCAL_ID (UNKNOWN |  EQUAL  constant)
    ;

// https://msdn.microsoft.com/en-us/library/ms176104.aspx
select_list
    : selectElement+=select_list_elem (COMMA selectElement+=select_list_elem)*
    ;

// https://docs.microsoft.com/ru-ru/sql/t-sql/queries/select-clause-transact-sql
asterisk
    : (table_name DOT)? STAR
    ;
    
expression_elem
    : leftAlias=column_alias eq=EQUAL  leftAssignment=expression
    | expressionAs=expression as_column_alias?
    ;

select_list_elem
    : asterisk
    | expression_elem    
    | LOCAL_ID (assignment_operator |  EQUAL) expression    
    ;

table_sources
    : table_source_item (COMMA table_source_item)*
    | LR_BRACKET table_source_item_dml as_table_alias column_alias_list?
    ;

// these DML statements must have an OUTPUT clause to be used in INSERT-SELECT FROM ()
table_source_item_dml
    : merge_statement
    | delete_statement RR_BRACKET
    | insert_statement RR_BRACKET
    | update_statement RR_BRACKET
    ;
    
table_source_item
	: table_source_item (ij=INNER join_hint?)? JOIN table_source_item ON search_condition
	| table_source_item oj=(LEFT|RIGHT|FULL) OUTER? join_hint? JOIN table_source_item ON search_condition
	| table_source_item cj=CROSS JOIN table_source_item
	| table_source_item lj=(CROSS|OUTER) APPLY table_source_item
	| table_source_item PIVOT pivot_clause         as_table_alias?
	| table_source_item UNPIVOT unpivot_clause     as_table_alias?
	| table_source_item for_system_time            as_table_alias?
	| full_object_name                            (as_table_alias|with_table_hints)*
	| local_id					                  (as_table_alias|with_table_hints)*
	| derived_table                               (as_table_alias column_alias_list?)?
	| subquery                                     as_table_alias?
	| rowset_function                              as_table_alias?
    | xml_nodes_method                            (as_table_alias column_alias_list?)?
	| (LOCAL_ID DOT)? function_call               (as_table_alias column_alias_list?)?
	| LR_BRACKET table_source_item RR_BRACKET
    | colon_colon function_call                    as_table_alias? // Built-in function (old syntax)
	| odbc_outer_join
    ;

join_hint
    : LOOP
    | HASH
    | MERGE
    | REMOTE
    | REDUCE
    | REDISTRIBUTE
    | REPLICATE
    ;

pivot_clause
    : LR_BRACKET aggregate_windowed_function FOR full_column_name IN column_alias_list RR_BRACKET
    ;

unpivot_clause
    : LR_BRACKET unpivot_exp=expression FOR full_column_name IN LR_BRACKET full_column_name_list RR_BRACKET RR_BRACKET
    ;

column_declaration
    : id data_type (collation | null_notnull)* char_string?
    ;

full_column_name_list
    : column+=full_column_name (COMMA column+=full_column_name)*
    ;

table_name_with_hint
    : table_name with_table_hints?
    ;

bulk_option
    : id  EQUAL (bulk_option_nr=DECIMAL | bulk_option_str=char_string)
    ;

derived_table
    : select_statement
    | subquery
    | table_value_constructor
    | LR_BRACKET table_value_constructor RR_BRACKET
    | LR_BRACKET derived_table RR_BRACKET
    ;

function_call
    : ranking_windowed_function                         
    | aggregate_windowed_function                      
    | analytic_windowed_function                       
    | spatial_proc_name_server_database_schema LR_BRACKET function_arg_list? RR_BRACKET 
    | xml_proc_name_table_column LR_BRACKET expression_list? RR_BRACKET
    | func_proc_name_server_database_schema LR_BRACKET allOrDistinct=(DISTINCT|ALL)? function_arg_list? RR_BRACKET 
    | built_in_functions                               
    | freetext_function                                
    | NEXT VALUE FOR full_object_name		         
    | odbc_scalar_function           
    | partition_function_call                           
    ;

partition_function_call
    : (db_name=id DOT)? DOLLAR_PARTITION DOT func_name=id LR_BRACKET expression RR_BRACKET
    ;

freetext_function
    : (CONTAINSTABLE | FREETEXTTABLE) LR_BRACKET table_name COMMA (full_column_name | LR_BRACKET full_column_name (COMMA full_column_name)* RR_BRACKET | (table_name DOT)? STAR  ) COMMA expression  (COMMA LANGUAGE expression)? (COMMA expression)? RR_BRACKET
    | (SEMANTICSIMILARITYTABLE | SEMANTICKEYPHRASETABLE) LR_BRACKET table_name COMMA (full_column_name | LR_BRACKET full_column_name (COMMA full_column_name)* RR_BRACKET | (table_name DOT)? STAR  ) COMMA expression RR_BRACKET
    | SEMANTICSIMILARITYDETAILSTABLE LR_BRACKET table_name COMMA full_column_name COMMA expression COMMA full_column_name COMMA expression RR_BRACKET
    ;

freetext_predicate
    : CONTAINS LR_BRACKET (full_column_name | LR_BRACKET full_column_name (COMMA full_column_name)* RR_BRACKET | (table_name DOT)? STAR  | PROPERTY LR_BRACKET full_column_name COMMA expression RR_BRACKET ) COMMA expression RR_BRACKET
    | FREETEXT LR_BRACKET (full_column_name | LR_BRACKET full_column_name (COMMA full_column_name)* RR_BRACKET | (table_name DOT)? STAR  ) COMMA expression  (COMMA LANGUAGE expression)? RR_BRACKET
    ;

// these are functions with a different call syntax than regular functions;
built_in_functions
    : bif_cast_parse
    | bif_convert
    | bif_other
    | bif_no_brackets=(
          CURRENT_TIMESTAMP                           
	    // https://msdn.microsoft.com/en-us/library/ms176050.aspx
	    | CURRENT_USER                                      
	    // https://msdn.microsoft.com/en-us/library/ms177587.aspx
	    | SESSION_USER                                      
	    // https://msdn.microsoft.com/en-us/library/ms179930.aspx
	    | SYSTEM_USER                                       
	    | USER 
	    )     										    
    ;

bif_cast_parse
    : bif=(CAST | TRY_CAST | PARSE | TRY_PARSE) LR_BRACKET expression AS data_type RR_BRACKET 
    ;
    
bif_convert
    : bif=(CONVERT | TRY_CONVERT) LR_BRACKET convert_data_type=data_type COMMA convert_expression=expression (COMMA style=expression)? RR_BRACKET 
    ;
   
bif_other
      // https://docs.microsoft.com/en-us/sql/t-sql/functions/logical-functions-iif-transact-sql 
    : IIF LR_BRACKET cond=search_condition COMMA left=expression COMMA right=expression RR_BRACKET   # IIF
    | TRIM LR_BRACKET (expression trim_from)? expression RR_BRACKET #TRIM  
    | STRING_AGG LR_BRACKET expr=expression COMMA separator=expression RR_BRACKET (WITHIN GROUP LR_BRACKET order_by_clause RR_BRACKET )?  #STRING_AGG    
    ;
    
// ODBC scalar functions/literals are called 'escape sequences' in the docs 
odbc_scalar_function
    : L_CURLY FN odbc_scalar_function_name R_CURLY
    ;
    
odbc_scalar_function_name
    : CONVERT LR_BRACKET expression COMMA data_type RR_BRACKET
    | EXTRACT LR_BRACKET (YEAR | MONTH | DAY | HOUR | MINUTE | SECOND) FROM expression RR_BRACKET
	| INSERT LR_BRACKET expression (COMMA expression)+ RR_BRACKET
	| POSITION LR_BRACKET expression IN expression RR_BRACKET
	| TRUNCATE LR_BRACKET expression (COMMA expression)+ RR_BRACKET
	| CURRENT_DATE LR_BRACKET expression? RR_BRACKET
	| CURRENT_TIME LR_BRACKET expression? RR_BRACKET
    | id (LR_BRACKET (COMMA? expression)* RR_BRACKET)?
    ;

odbc_literal
    : L_CURLY op=(D | T | TS | GUID) char_string R_CURLY
    | L_CURLY INTERVAL sign? char_string id (LR_BRACKET expression RR_BRACKET)? (TO id (LR_BRACKET expression RR_BRACKET)?)? R_CURLY   // {INTERVAL '163' HOUR(3)},  {INTERVAL '163 12' DAY(3) TO HOUR}
    ;

odbc_outer_join
    : L_CURLY OJ table_source_item oj=(LEFT|RIGHT|FULL) OUTER? join_hint? JOIN table_source_item ON search_condition R_CURLY
    ;

trigger_column_updated
    : UPDATE LR_BRACKET full_column_name RR_BRACKET
    ;

spatial_methods
    : ( geospatial_col | geospatial_func_no_arg | geospatial_func_arg ) (LR_BRACKET expression_list? RR_BRACKET)?
    ;
        
geospatial_col
    : STSRID
    | STSRID_DOUBLE_QUOTE
    | STSRID_SQBRACKET
    | STX
    | STX_SQBRACKET
    | STX_DOUBLE_QUOTE
    | STY
    | STY_SQBRACKET
    | STY_DOUBLE_QUOTE
    | LAT
    | LAT_SQBRACKET
    | LAT_DOUBLE_QUOTE
    | LONG
    | LONG_SQBRACKET
    | LONG_DOUBLE_QUOTE
    ;

geospatial_func_no_arg
    : STASTEXT
    | STASBINARY
    | STAREA
    ;

geospatial_func_arg
    : STDISTANCE
    | STEQUALS
    | STCONTAINS
    ;

hierarchyid_methods
    : method=( GETANCESTOR | GETDESCENDANT | GETLEVEL | ISDESCENDANTOF | READ | GETREPARENTEDVALUE | TOSTRING ) LR_BRACKET expression_list? RR_BRACKET
    ;

hierarchyid_coloncolon_methods
    : id colon_colon  method=(GETROOT | PARSE) LR_BRACKET expression? RR_BRACKET
    ;

spatial_coloncolon_methods
    : data_type colon_colon function_call
    ;

xml_methods
    : xml_func_arg LR_BRACKET expression_list? RR_BRACKET
    ;

xml_func_arg
    : EXIST
    | VALUE
    | QUERY
    | MODIFY
    ;

xml_modify_method
    : (loc_id=LOCAL_ID | value_id=id | subquery) DOT call=xml_modify_call
    ;

xml_modify_call
    : MODIFY LR_BRACKET xml_dml=char_string RR_BRACKET
    ;

xml_nodes_method
    : (loc_id=LOCAL_ID | value_id=id | subquery) DOT NODES LR_BRACKET xquery=char_string RR_BRACKET
    ;

switch_section
    : WHEN expression THEN expression
    ;

switch_search_condition_section
    : WHEN search_condition THEN expression
    ;

as_column_alias
    : AS? column_alias
    ;

as_table_alias
    : AS? table_alias
    ;

table_alias
    : id with_table_hints?
    ;

// https://msdn.microsoft.com/en-us/library/ms187373.aspx
// NB: WITH keyword is mandatory these days in SQL Server, but customer applications running older or backward-compatible version may still use the old syntax without WITH 
with_table_hints
    : LR_BRACKET hint+=table_hint RR_BRACKET // without WITH, one hint can be specified
    | WITH LR_BRACKET hint+=table_hint (COMMA? hint+=table_hint)* RR_BRACKET
    | sample_clause 
    ;

sample_clause
    : TABLESAMPLE SYSTEM? LR_BRACKET expression (PERCENT|ROWS) RR_BRACKET (REPEATABLE LR_BRACKET PLUS? DECIMAL RR_BRACKET)?
    ;
  
// https://github.com/MicrosoftDocs/sql-docs/blob/live/docs/t-sql/queries/hints-transact-sql-table.md
table_hint
    : NOEXPAND? ( INDEX (LR_BRACKET index_value (COMMA index_value)* RR_BRACKET | index_value (COMMA index_value)*) )
    | INDEX  EQUAL  index_value
    | NOEXPAND
    | FORCESEEK ( LR_BRACKET index_value LR_BRACKET ID  (COMMA ID)* RR_BRACKET RR_BRACKET )?
    | FORCESCAN
    | FORCESEEK
    | HOLDLOCK
    | NOLOCK
    | NOWAIT
    | PAGLOCK
    | READCOMMITTED
    | READCOMMITTEDLOCK
    | READPAST
    | READUNCOMMITTED
    | REPEATABLEREAD
    | ROWLOCK
    | SERIALIZABLE
    | SNAPSHOT
    | SPATIAL_WINDOW_MAX_CELLS  EQUAL  DECIMAL
    | TABLOCK
    | TABLOCKX
    | UPDLOCK
    | XLOCK
    ;

index_value
    : id | DECIMAL
    ;

column_alias_list
    : LR_BRACKET alias+=column_alias (COMMA alias+=column_alias)* RR_BRACKET
    ;

column_alias
    : id
    | char_string
    ;

table_value_constructor
    : VALUES LR_BRACKET exps+=expression_list RR_BRACKET (COMMA LR_BRACKET exps+=expression_list RR_BRACKET )*
    ;

function_arg_list
    : ( STAR | expression ) (COMMA exp+=expression)*
    ;
    
expression_list
    : exp+=expression (COMMA exp+=expression)*
    ;

// https://msdn.microsoft.com/en-us/library/ms189798.aspx
ranking_windowed_function
    : agg_func=(RANK | DENSE_RANK | ROW_NUMBER) LR_BRACKET RR_BRACKET over_clause
    | NTILE LR_BRACKET expression RR_BRACKET over_clause
    ;

// https://msdn.microsoft.com/en-us/library/ms173454.aspx
aggregate_windowed_function
    : agg_func=(AVG | MAX | MIN | SUM | STDEV | STDEVP | VAR | VARP) LR_BRACKET all_distinct_expression RR_BRACKET over_clause?
    | cnt=(COUNT | COUNT_BIG) LR_BRACKET ( STAR  | all_distinct_expression) RR_BRACKET over_clause?
    | CHECKSUM_AGG LR_BRACKET all_distinct_expression RR_BRACKET
    | GROUPING LR_BRACKET expression RR_BRACKET
    | GROUPING_ID LR_BRACKET expression_list RR_BRACKET
    ;

// https://docs.microsoft.com/en-us/sql/t-sql/functions/analytic-functions-transact-sql
analytic_windowed_function
    : first_last=(FIRST_VALUE | LAST_VALUE) LR_BRACKET expression RR_BRACKET over_clause
    | lag_lead=(LAG | LEAD) LR_BRACKET expression  (COMMA expression (COMMA expression)? )? RR_BRACKET over_clause
    | rank=(CUME_DIST | PERCENT_RANK) LR_BRACKET RR_BRACKET OVER LR_BRACKET (PARTITION BY expression_list)? order_by_clause RR_BRACKET
    | pct=(PERCENTILE_CONT | PERCENTILE_DISC) LR_BRACKET expression RR_BRACKET WITHIN GROUP LR_BRACKET ORDER BY expression (ASC | DESC)? RR_BRACKET over_clause
    ;
    
all_distinct_expression
    : (ALL | DISTINCT)? expression
    ;

// https://msdn.microsoft.com/en-us/library/ms189461.aspx
over_clause
    : OVER LR_BRACKET (PARTITION BY expression_list)? order_by_clause? row_or_range_clause? RR_BRACKET
    ;

row_or_range_clause
    : (ROWS | RANGE) window_frame_extent
    ;

window_frame_extent
    : window_frame_preceding
    | BETWEEN window_frame_bound AND window_frame_bound
    ;

window_frame_bound
    : window_frame_preceding
    | window_frame_following
    ;

window_frame_preceding
    : UNBOUNDED PRECEDING
    | DECIMAL PRECEDING
    | CURRENT ROW
    ;

window_frame_following
    : UNBOUNDED FOLLOWING
    | DECIMAL FOLLOWING
    ;

create_database_option
    : FILESTREAM ( database_filestream_option (COMMA database_filestream_option)* )
    | DEFAULT_LANGUAGE EQUAL ( id | char_string | DECIMAL )
    | DEFAULT_FULLTEXT_LANGUAGE EQUAL ( id | char_string | DECIMAL )
    | NESTED_TRIGGERS EQUAL on_off
    | TRANSFORM_NOISE_WORDS EQUAL on_off
    | TWO_DIGIT_YEAR_CUTOFF EQUAL DECIMAL
    | DB_CHAINING on_off
    | TRUSTWORTHY on_off
    | CATALOG_COLLATION EQUAL id   
    | PERSISTENT_LOG_BUFFER EQUAL ON LR_BRACKET DIRECTORY_NAME EQUAL STRING RR_BRACKET
    ;

database_filestream_option
    : LR_BRACKET
     (
         ( NON_TRANSACTED_ACCESS EQUAL ( OFF | READ_ONLY | FULL ) )
         |
         ( DIRECTORY_NAME EQUAL char_string )
     )
 RR_BRACKET
    ;

database_file_spec
    : file_group | file_spec
    ;

file_group
    : FILEGROUP id
     ( CONTAINS FILESTREAM )?
     ( DEFAULT )?
     ( CONTAINS MEMORY_OPTIMIZED_DATA )?
     file_spec ( COMMA file_spec )*
    ;
file_spec
    : LR_BRACKET
      NAME EQUAL ( id | char_string ) COMMA?
      ( FILENAME EQUAL file = char_string COMMA? )?
      ( SIZE EQUAL file_size COMMA? )?
      ( MAXSIZE EQUAL (file_size | UNLIMITED )COMMA? )?
      ( FILEGROWTH EQUAL file_size COMMA? )?
 RR_BRACKET
    ;

if_exists
    : IF EXISTS
    ;

trim_from 
    : FROM
    ;
    
on_off
    : ON
    | OFF
    ;

clustered
    : CLUSTERED
    | NONCLUSTERED HASH?
    ;

null_notnull
    : NOT? NULL_P
    ;

begin_conversation_timer
    : BEGIN CONVERSATION TIMER LR_BRACKET LOCAL_ID RR_BRACKET TIMEOUT  EQUAL  time SEMI?
    ;

begin_conversation_dialog
    : BEGIN DIALOG (CONVERSATION)? dialog_handle=LOCAL_ID
      FROM SERVICE initiator_service_name=service_name
      TO SERVICE target_service_name=service_name (COMMA service_broker_guid=char_string)?
      ON CONTRACT contract_name
      (WITH
        ((RELATED_CONVERSATION | RELATED_CONVERSATION_GROUP)  EQUAL  LOCAL_ID COMMA?)?
        (LIFETIME  EQUAL  (DECIMAL | LOCAL_ID) COMMA?)?
        (ENCRYPTION  EQUAL  (ON | OFF))? )?
    SEMI?
    ;

contract_name
    : (id | expression)
    ;

service_name
    : (id | expression)
    ;

end_conversation
    : END CONVERSATION conversation_handle=LOCAL_ID SEMI?
      (WITH (ERROR  EQUAL  (failure_code_v=LOCAL_ID | failure_code_s=char_string) DESCRIPTION  EQUAL (failure_text_v=LOCAL_ID | failure_text_s=char_string))? CLEANUP? )?
    ;

waitfor_conversation
    : WAITFOR? LR_BRACKET get_conversation RR_BRACKET (COMMA? TIMEOUT timeout=time)? SEMI?
    ;

get_conversation
    :GET CONVERSATION GROUP (char_string | LOCAL_ID) FROM queue=queue_id SEMI?
    ;
    
// https://docs.microsoft.com/en-us/sql/t-sql/language-elements/waitfor-transact-sql
waitfor_receive_statement
    : WAITFOR receive_statement? (COMMA TIMEOUT time)? SEMI?
    ;
    
receive_statement
    :  RECEIVE (ALL | DISTINCT | top_clause | STAR)?
      ((LOCAL_ID EQUAL)? expression COMMA?)* FROM full_object_name
      (INTO table_variable=LOCAL_ID)? (WHERE where=search_condition)? SEMI?
    | LR_BRACKET receive_statement RR_BRACKET SEMI?
    ;    

queue_id
    : database_name=id (DOT schema_name=id DOT name=id)? 
    ;

send_conversation
    : SEND ON CONVERSATION (char_string | LOCAL_ID)
      MESSAGE TYPE message_type_name=expression
      ( LR_BRACKET (message_body_s=char_string | message_body_v=LOCAL_ID) RR_BRACKET )?
    SEMI?
    ;

// https://msdn.microsoft.com/en-us/library/ms187752.aspx
data_type
    : ext_type=simple_name LR_BRACKET scale=DECIMAL COMMA prec=DECIMAL RR_BRACKET
    | NATIONAL? ext_type=simple_name VARYING? LR_BRACKET scale=(DECIMAL|MAX) RR_BRACKET
    | ext_type=simple_name IDENTITY (LR_BRACKET sign? seed=DECIMAL COMMA sign? inc=DECIMAL RR_BRACKET)?
    | cursor_type=CURSOR
    | double_prec=DOUBLE PRECISION?
    | NATIONAL? unscaled_type=simple_name VARYING?
    | xml_type_definition
    ;

// https://msdn.microsoft.com/en-us/library/ms179899.aspx
constant
    : char_string // string, datetime or uniqueidentifier
    | hex_string
    | NULL_P
    | sign? (REAL | MONEY | DECIMAL | FLOAT) 
    ;

hex_string
    : BINARY
    ;

char_string
    : STRING // single-quoted string; may also be a double-quoted string in case of SET QUOTED_IDENTIFIER OFF
    ;
        
sign
    : PLUS
    | MINUS
    ;

keyword
    : ABORT
    | ABORT_AFTER_WAIT
    | ABSENT
    | ABSOLUTE
    | ACCELERATED_DATABASE_RECOVERY
    | ACCENT_SENSITIVITY
    | ACCESS
    | ACTION
    | ACTIVATION
    | ACTIVE
    | ADDRESS
    | ADMINISTER
    | AES
    | AES_128
    | AES_192
    | AES_256
    | AFFINITY
    | AFTER
    | AGGREGATE
    | ALGORITHM
    | ALLOWED
    | ALL_SPARSE_COLUMNS   
    | ALLOW_CONNECTIONS
    | ALLOW_ENCRYPTED_VALUE_MODIFICATIONS
    | ALLOW_MULTIPLE_EVENT_LOSS
    | ALLOW_SINGLE_EVENT_LOSS
    | ALLOW_SNAPSHOT_ISOLATION
    | ALWAYS
    | ANONYMOUS
    | ANSI_DEFAULTS
    | ANSI_NULLS
    | ANSI_NULL_DEFAULT
    | ANSI_NULL_DFLT_OFF
    | ANSI_NULL_DFLT_ON
    | ANSI_PADDING
    | ANSI_WARNINGS
    | APPEND
    | APPLICATION
    | APPLICATION_LOG
    | APPLY
    | ARITHABORT
    | ARITHIGNORE
    | ASSEMBLY
    | ASYMMETRIC
    | ASYNCHRONOUS_COMMIT
    | ATOMIC
    | AT_KEYWORD
    | AUDIT
    | AUDIT_GUID
    | AUTHENTICATE
    | AUTHENTICATION
    | AUTO
    | AUTOGROW_ALL_FILES
    | AUTOGROW_SINGLE_FILE
    | AUTOMATED_BACKUP_PREFERENCE
    | AUTOMATIC
    | AUTO_CLEANUP
    | AUTO_CLOSE
    | AUTO_CREATE_STATISTICS
    | AUTO_SHRINK
    | AUTO_UPDATE_STATISTICS
    | AUTO_UPDATE_STATISTICS_ASYNC
    | AVAILABILITY
    | AVAILABILITY_MODE
    | AUTOCOMMIT
    | AVG
    | BACKUP_PRIORITY
    | BEFORE
    | BEGIN_DIALOG
    | BIGINT
    | BASE64
    | BINARY_CHECKSUM
    | BINARY_KEYWORD
    | BINDING
    | BLOB_STORAGE
    | BLOCK
    | BLOCKERS
    | BLOCKING_HIERARCHY
    | BLOCKSIZE
    | BOUNDING_BOX
    | BROKER
    | BROKER_INSTANCE
    | BUFFER
    | BUFFERCOUNT
    | BULK_LOGGED
    | CACHE
    | CALLED
    | CALLER
    | CAP_CPU_PERCENT
    | CAST
    | CATALOG
    | CATALOG_COLLATION
    | CATCH
    | CELLS_PER_OBJECT
    | CERTIFICATE
    | CHANGE
    | CHANGES
    | CHANGETABLE
    | CHANGE_RETENTION
    | CHANGE_TRACKING
    | CHECKDB
    | CHECKFILEGROUP
    | CHECKSUM
    | CHECKSUM_AGG
    | CHECKTABLE
    | CHECK_EXPIRATION
    | CHECK_POLICY
    | CLASSIFIER
    | CLASSIFIER_FUNCTION
    | CLEANTABLE
    | CLEANUP
    | CLEANUP_POLICY
    | CLEAR
    | CLONEDATABASE 
    | CLUSTER
    | COALESCE
    | COLLECTION
    | COLUMNS
    | COLUMNSTORE
    | COLUMN_SET
    | COLUMN_ENCRYPTION_KEY   
    | COLUMN_MASTER_KEY
    | COMMITTED
    | COMPATIBILITY_LEVEL
    | COMPRESSION
    | CONCAT
    | CONCAT_NULL_YIELDS_NULL
    | CONCAT_WS
    | CONFIGURATION
    | CONNECT
    | CONNECTION
    | CONTAINED
    | CONTAINMENT
    | CONTENT
    | CONTEXT
    | CONTINUE_AFTER_ERROR
    | CONTRACT
    | CONTRACT_NAME
    | CONTROL
    | CONVERSATION
    | COOKIE
    | COPY_ONLY
    | COUNT
    | COUNTER
    | COUNT_BIG
    | CPU
    | CREATE_NEW
    | CREATION_DISPOSITION
    | CREDENTIAL
    | CRYPTOGRAPHIC
    | CUBE
    | CUME_DIST
    | CURSOR_CLOSE_ON_COMMIT
    | CURSOR_DEFAULT
    | CUSTOM
    | CYCLE
    | D
    | DATA
    | DATABASE_MIRRORING
    | DATASPACE
    | DATA_COMPRESSION
    | DATA_CONSISTENCY_CHECK
    | DATA_FLUSH_INTERVAL_SECONDS
    | DATA_SOURCE
    | DATEADD
    | DATEDIFF
    | DATEDIFF_BIG
    | DATE_BUCKET
    | DATEFIRST
    | DATEFORMAT
    | DATE_FORMAT
    | DATENAME
    | DATEPART
    | DATETRUNC
    | DATE_CORRELATION_OPTIMIZATION
    | DATE_FORMAT
    | DAY
    | DAYS
    | DBREINDEX
    | DB_CHAINING
    | DB_FAILOVER
    | DDL    
    | DECRYPTION
    | DEFAULT_DATABASE
    | DEFAULT_DOUBLE_QUOTE
    | DEFAULT_FULLTEXT_LANGUAGE
    | DEFAULT_LANGUAGE
    | DEFAULT_SCHEMA
    | DEFINITION
    | DELAY
    | DELAYED_DURABILITY
    | DELETED
    | DENSE_RANK
    | DEPENDENTS
    | DES
    | DESCRIPTION
    | DESX
    | DETERMINISTIC
    | DISTRIBUTION   
    | DHCP
    | DIAGNOSTICS
    | DIALOG
    | DIFFERENTIAL
    | DIRECTORY_NAME
    | DISABLE
    | DISABLED
    | DISABLE_BROKER
    | DISK
    | DISK_DRIVE
    | DISTRIBUTED_AGG
    | DISTRIBUTION
    | DOCUMENT
    | DROPCLEANBUFFERS
    | DTC_SUPPORT
    | DYNAMIC
    | EDGE
    | ELEMENTS
    | EMERGENCY
    | EMPTY
    | ENABLE
    | ENABLED
    | ENABLE_BROKER
    | ENCODING
    | ENCRYPTED
    | ENCRYPTION_TYPE     
    | ENCRYPTED_VALUE
    | ENCRYPTION
    | ENDPOINT
    | ENDPOINT_URL
    | ERROR
    | ERROR_BROKER_CONVERSATIONS
    | EVENT
    | EVENTDATA
    | EVENT_RETENTION_MODE
    | EXCLUSIVE
    | EXECUTABLE
    | EXECUTABLE_FILE
    | EXECUTION_COUNT
    | EXIST
    | EXPAND
    | EXPIREDATE
    | EXPIRY_DATE
    | EXPLICIT
    | EXTENSION
    | EXTERNALPUSHDOWN
    | EXTERNAL_ACCESS
    | EXTRACT
    | FAILOVER
    | FAILOVER_MODE
    | FAILURE
    | FAILURECONDITIONLEVEL
    | FAILURE_CONDITION_LEVEL
    | FAIL_OPERATION
    | FAIL_UNSUPPORTED
    | FALSE
    | FAN_IN
    | FAST
    | FAST_FORWARD
    | FIELD_TERMINATOR
    | FILEGROUP
    | FILEGROWTH
    | FILENAME
    | FILEPATH
    | FILESTREAM
    | FILESTREAM_ON
    | FILETABLE
    | FILE_SNAPSHOT
    | FILTER
    | FIPS_FLAGGER
    | FIRST
    | FIRST_ROW
    | FIRST_VALUE
    | FMTONLY
    | FN
    | FOLLOWING
    | FOR_APPEND   
    | FORCE
    | FORCED
    | FORCEPLAN
    | FORCESEEK
    | FORCE_FAILOVER_ALLOW_DATA_LOSS
    | FORCE_SERVICE_ALLOW_DATA_LOSS
    | FORMAT
    | FORMAT_OPTIONS
    | FORMAT_TYPE
    | FORWARD_ONLY
    | FREEPROCCACHE
    | FREESESSIONCACHE
    | FREESYSTEMCACHE
    | FULLSCAN
    | FULLTEXT
    | GB
    | GENERATED
    | GEOGRAPHY_AUTO_GRID
    | GEOGRAPHY_GRID
    | GEOMETRY_AUTO_GRID 
    | GEOMETRY_GRID
    | GET
    | GETANCESTOR
    | GETDATE
    | GETDESCENDANT
    | GETLEVEL
    | GETREPARENTEDVALUE
    | GETROOT
    | GETUTCDATE
    | GLOBAL
    | GOVERNOR
    | GRIDS
    | GROUPING
    | GROUPING_ID
    | GROUP_MAX_REQUESTS
    | GUID
    | HADR
    | HASH
    | HASHED
    | HEALTHCHECKTIMEOUT
    | HEALTH_CHECK_TIMEOUT
    | HELP
    | HIDDEN_RENAMED
    | HIGH
    | HINT
    | HISTORY_RETENTION_PERIOD
    | HISTORY_TABLE
    | HOLDLOCK
    | HONOR_BROKER_PRIORITY
    | HOUR
    | HOURS
    | IDENTITY
    | IDENTITYCOL
    | IDENTITY_VALUE
    | IGNORE_NONCLUSTERED_COLUMNSTORE_INDEX
    | IIF
    | IMMEDIATE
    | IMPERSONATE
    | IMPLICIT_TRANSACTIONS
    | IMPORTANCE
    | INCLUDE
    | INCLUDE_NULL_VALUES
    | INCREMENT
    | INCREMENTAL
    | INDEXDEFRAG
    | INFINITE
    | INIT
    | INITIATOR
    | INPUT
    | INPUTBUFFER
    | INSENSITIVE
    | INSERTED
    | INSTEAD
    | INT
    | INTERVAL
    | INTERVAL_LENGTH_MINUTES
    | IO
    | IP
    | ISDESCENDANTOF
    | ISNULL
    | ISOLATION
    | JOB
    | JSON
    | KB
    | KEEP
    | KEEPFIXED
    | KEEP_CDC
    | KEEP_REPLICATION
    | KERBEROS
    | KEYS
    | KEYSET
    | KEY_PATH
    | KEY_SOURCE
    | KEY_STORE_PROVIDER_NAME
    | LAG
    | LANGUAGE
    | LAST
    | LAST_VALUE
    | LAT
    | LAT_DOUBLE_QUOTE
    | LAT_SQBRACKET
    | LEAD
    | LEDGER
    | LEFT
    | LEVEL
    | LIBRARY
    | LIFETIME
    | LINKED
    | LINUX
    | LIST
    | LISTENER
    | LISTENER_IP
    | LISTENER_PORT
    | LISTENER_URL
    | LOAD // works like a unreserved keyword, differently from the document
    | LOB_COMPACTION
    | LOCAL
    | LOCAL_SERVICE_NAME
    | LOCATION
    | LOCK
    | LOCK_ESCALATION
    | LOG
    | LOG10
    | LOGIN
    | LONG
    | LONG_DOUBLE_QUOTE
    | LONG_SQBRACKET
    | LOOP
    | LOW
    | MANUAL
    | MARK
    | MASK
    | MASKED
    | MASTER
    | MATCHED
    | MATERIALIZED      
    | MAX
    | MAXDOP
    | MAXRECURSION
    | MAXSIZE
    | MAXTRANSFER
    | MAXVALUE
    | MAX_CPU_PERCENT
    | MAX_DISPATCH_LATENCY
    | MAX_DOP
    | MAX_DURATION
    | MAX_EVENT_SIZE
    | MAX_FILES
    | MAX_GRANT_PERCENT
    | MAX_IOPS_PER_VOLUME
    | MAX_MEMORY
    | MAX_MEMORY_PERCENT
    | MAX_OUTSTANDING_IO_PER_VOLUME
    | MAX_PLANS_PER_QUERY
    | MAX_PROCESSES
    | MAX_QUEUE_READERS
    | MAX_ROLLOVER_FILES
    | MAX_SIZE
    | MAX_SIZE_MB
    | MAX_STORAGE_SIZE_MB
    | MB
    | MEDIADESCRIPTION
    | MEDIANAME
    | MEDIUM
    | MEMBER
    | MEMORY_OPTIMIZED_DATA
    | MEMORY_PARTITION_MODE
    | MESSAGE
    | MESSAGE_FORWARDING
    | MESSAGE_FORWARD_SIZE
    | MIN
    | MINUTE
    | MINUTES
    | MINVALUE
    | MIN_ACTIVE_ROWVERSION
    | MIN_CPU_PERCENT
    | MIN_GRANT_PERCENT
    | MIN_IOPS_PER_VOLUME
    | MIN_MEMORY_PERCENT
    | MIRROR
    | MIRROR_ADDRESS
    | MIXED_PAGE_ALLOCATION
    | MODE
    | MODEL
    | MODIFY
    | MONTH
    | MONTHS
    | MOVE
    | MULTI_USER
    | MUST_CHANGE
    | NAME
    | NATIVE_COMPILATION
    | NEGOTIATE
    | NESTED_TRIGGERS
    | NEW_ACCOUNT
    | NEW_BROKER
    | NEW_PASSWORD
    | NEXT
    | NO
    | NO_PERFORMANCE_SPOOL
    | NOCOMPUTE
    | NOCOUNT
    | NODE
    | NODES
    | NOEXEC
    | NOEXPAND
    | NOFORMAT
    | NOINIT
    | NONE
    | NON_TRANSACTED_ACCESS
    | NORECOMPUTE
    | NORECOVERY
    | NOREWIND
    | NOSKIP
    | NOTIFICATION
    | NOTIFICATIONS
    | NOUNLOAD
    | NOWAIT
    | NO_BROWSETABLE
    | NO_CHECKSUM
    | NO_COMPRESSION
    | NO_EVENT_LOSS
    | NO_LOG
    | NO_PERFORMANCE_SPOOL
    | NO_TRUNCATE
    | NO_WAIT
    | NTILE
    | NTLM
    | NULLIF
    | NUMANODE
    | NUMBER
    | NUMERIC_ROUNDABORT
    | OBJECT
    | OFFLINE
    | OFFSET
    | OJ
    | OLD_ACCOUNT
    | OLD_PASSWORD
    | ONLINE
    | ONLY
    | ON_FAILURE
    | OPENJSON
    | OPENTRAN
    | OPEN_EXISTING
    | OPERATIONS
    | OPERATION_MODE
    | OPTIMISTIC
    | OPTIMIZE
    | OUT
    | OUTPUT
    | OUTPUTBUFFER
    | OVERRIDE
    | OWNER
    | OWNERSHIP
    | PAGE
    | PAGECOUNT
    | PAGE_VERIFY
    | PARAM
    | PARAMETERIZATION
    | PARAM_NODE
    | PARSE
    | PARSEONLY
    | PARTIAL
    | PARTITION
    | PARTITIONS
    | PARTNER
    | PASSWORD
    | PATH
    | PAUSE
    | PERCENTILE_CONT
    | PERCENTILE_DISC
    | PERCENT_RANK
    | PERIOD
    | PERMISSION_SET
    | PERSISTED
    | PERSIST_SAMPLE_PERCENT
    | PERSISTENT_LOG_BUFFER
    | PERSISTENT_VERSION_STORE_FILEGROUP
    | PER_CPU
    | PER_DB
    | PER_NODE
    | PLATFORM
    | POISON_MESSAGE_HANDLING
    | POLICY
    | POOL
    | POPULATION
    | PORT
    | POSITION
    | PRECEDING
    | PREDICATE
    | PREDICT
    | PRIMARY_ROLE
    | PRIMARY_SQBRACKET
    | PRIOR
    | PRIORITY
    | PRIORITY_LEVEL
    | PRIVATE
    | PRIVATE_KEY
    | PRIVILEGES
    | PROCCACHE
    | PROCEDURE_CACHE
    | PROCEDURE_NAME
    | PROCESS
    | PROFILE
    | PROPERTY
    | PROVIDER
    | PROVIDER_KEY_NAME
    | PYTHON
    | QUERY
    | QUERY_CAPTURE_MODE
    | QUERY_CAPTURE_POLICY
    | QUERY_STORE
    | QUERYTRACEON
    | QUEUE
    | QUEUE_DELAY
    | QUOTED_IDENTIFIER
    | R
    | RANDOMIZED  
    | RANGE
    | RANK
    | RAW
    | RC2
    | RC4
    | RC4_128
    | READONLY
    | READWRITE
    | READ_COMMITTED_SNAPSHOT
    | READ_ONLY
    | READ_ONLY_ROUTING_LIST
    | READ_WRITE
    | READ_WRITE_FILEGROUPS
    | REBUILD
    | RECEIVE
    | RECOMPILE
    | RECOVERY
    | RECURSIVE_TRIGGERS
    | REDISTRIBUTE
    | REDUCE		
    | REGENERATE
    | RELATED_CONVERSATION
    | RELATED_CONVERSATION_GROUP
    | RELATIVE
    | REMOTE
    | REMOTE_PROC_TRANSACTIONS
    | REMOTE_SERVICE_NAME
    | REMOVE
    | REORGANIZE
    | REPEATABLE
    | REPLACE
    | REPLICA
    | REPLICATE	
    | REQUEST_MAX_CPU_TIME_SEC
    | REQUEST_MAX_MEMORY_GRANT_PERCENT
    | REQUEST_MEMORY_GRANT_TIMEOUT_SEC
    | REQUIRED
    | REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT
    | RESAMPLE
    | RESERVE_DISK_SPACE
    | RESET
    | RESOURCE
    | RESOURCES
    | RESOURCE_MANAGER_LOCATION
    | RESTART
    | RESTRICTED_USER
    | RESULT
    | RESUME
    | RETAINDAYS
    | RETENTION
    | RETURNS
    | REWIND
    | RIGHT
    | ROBUST
    | ROLE
    | ROLLUP
    | ROOT
    | ROUND_ROBIN       
    | ROUTE
    | ROW
    | ROWGUID
    | ROWS
    | ROW_NUMBER
    | RSA_1024
    | RSA_2048
    | RSA_3072
    | RSA_4096
    | RSA_512
    | RUNTIME
    | SAFE
    | SAFETY
    | SAMPLE
    | SCALEOUTEXECUTION
    | SCHEDULER
    | SCHEMABINDING
    | SCHEME
    | SCOPED
    | SCRIPT
    | SCROLL
    | SCROLL_LOCKS
    | SEARCH
    | SECOND
    | SECONDARY
    | SECONDARY_ONLY
    | SECONDARY_ROLE
    | SECONDS
    | SECRET
    | SECURABLES
    | SECURITY
    | SECURITY_LOG
    | SEEDING_MODE
    | SELECTIVE
    | SELF
    | SELECTIVE
    | SEMI_SENSITIVE
    | SEND
    | SENT
    | SEQUENCE
    | SEQUENCE_NUMBER
    | SERIALIZABLE
    | SERVER
    | SERVICE
    | SERVICE_BROKER
    | SERVICE_NAME
    | SESSION
    | SESSION_TIMEOUT
    | SETERROR
    | SETS
    | SETTINGS
    | SHARE
    | SHOWCONTIG
    | SHOWPLAN
    | SHOWPLAN_ALL
    | SHOWPLAN_TEXT
    | SHOWPLAN_XML
    | SHOW_STATISTICS
    | SHRINKDATABASE
    | SHRINKFILE
    | SHRINKLOG
    | SID
    | SIGNATURE
    | SIMPLE
    | SINGLETON
    | SINGLE_USER
    | SIZE
    | SIZE_BASED_CLEANUP_MODE
    | SKIP_KEYWORD
    | SMALLINT
    | SNAPSHOT
    | SOFTNUMA
    | SOURCE
    | SPARSE
    | SPATIAL
    | SPATIAL_WINDOW_MAX_CELLS
    | SPECIFICATION
    | SPLIT
    | SQL
    | SQLDUMPERFLAGS
    | SQLDUMPERPATH
    | SQLDUMPERTIMEOUT
    | SQLPERF
    | STALE_CAPTURE_POLICY_THRESHOLD
    | STALE_QUERY_THRESHOLD_DAYS
    | STANDBY
    | START
    | STAREA
    | STARTED
    | STARTUP_STATE
    | START_DATE
    | STASBINARY
    | STASTEXT
    | STATE
    | STATEMENT
    | STATIC
    | STATISTICAL_SEMANTICS
    | STATS
    | STATS_STREAM
    | STATUS
    | STATUSONLY
    | STCONTAINS
    | STDEV
    | STDEVP
    | STDISTANCE
    | STEQUALS
    | STOP
    | STOPAT
    | STOPATMARK
    | STOPBEFOREMARK
    | STOPLIST
    | STOPPED
    | STOP_ON_ERROR
    | STRING_AGG
    | STRING_DELIMITER
    | STSRID
    | STSRID_DOUBLE_QUOTE
    | STSRID_SQBRACKET
    | STUFF
    | STX
    | STX_DOUBLE_QUOTE
    | STX_SQBRACKET
    | STY
    | STY_DOUBLE_QUOTE
    | STY_SQBRACKET
    | SUBJECT
    | SUBSCRIBE
    | SUBSCRIPTION
    | SUBSTRING
    | SUM
    | SUPPORTED
    | SUSPEND
    | SWITCH
    | SYMMETRIC
    | SYNCHRONOUS_COMMIT
    | SYNONYM
    | SYSTEM
    | SYSTEM_TIME
    | SYSTEM_VERSIONING
    | T
    | TABLOCK
    | TAKE
    | TAPE
    | TARGET
    | TARGET_RECOVERY_TIME
    | TB
    | TCP
    | TEXTIMAGE_ON
    | THROW
    | TIES
    | TIME
    | TIMEOUT
    | TIMER
    | TIMESTAMP
    | TINYINT
    | TORN_PAGE_DETECTION
    | TOSTRING
    | TOTAL_COMPILE_CPU_TIME_MS
    | TOTAL_EXECUTION_CPU_TIME_MS
    | TRACE
    | TRACEOFF
    | TRACEON
    | TRACESTATUS
    | TRACKING
    | TRACK_CAUSALITY
    | TRACK_COLUMNS_UPDATED 
    | TRANSACTION_ID
    | TRANSFER
    | TRANSFORM_NOISE_WORDS
    | TRANSLATE
    | TRIM
    | TRIPLE_DES
    | TRIPLE_DES_3KEY
    | TRUE
    | TRUSTWORTHY
    | TRY
    | TRY_CAST
    | TRY_PARSE
    | TS
    | TSQL
    | TWO_DIGIT_YEAR_CUTOFF
    | TYPE
    | TYPE_WARNING
    | UNBOUNDED
    | UNCHECKED
    | UNCOMMITTED
    | UNDEFINED
    | UNKNOWN
    | UNLIMITED
    | UNLOCK
    | UNMASK    
    | UNSAFE
    | UOW
    | UPDATEUSAGE
    | URL
    | USED
    | USEROPTIONS
    | USE_TYPE_DEFAULT        
    | USING
    | VALIDATION
    | VALID_XML
    | VALUE
    | VAR
    | VARP
    | VERBOSELOGGING
    | VERSION
    | VIEWS
    | VIEW_METADATA
    | VISIBILITY
    | XACT_ABORT
    | WAIT
    | WAIT_AT_LOW_PRIORITY
    | WAIT_STATS_CAPTURE_MODE
    | WEEK
    | WEEKS
    | WELL_FORMED_XML
    | WHEN_SUPPORTED
    | WINDOWS
    | WITHOUT
    | WITHOUT_ARRAY_WRAPPER
    | WITNESS
    | WORK
    | WORKLOAD
    | XACT_ABORT
    | XMAX
    | XMIN
    | XML
    | XMLDATA
    | XMLNAMESPACES
    | XMLSCHEMA
    | XQUERY
    | XSINIL
    | YEAR
    | YEARS
    | YMAX
    | YMIN    
    | ZONE
    //Built-ins:
    | VARCHAR
    | NVARCHAR
    | BINARY_KEYWORD
    | VARBINARY_KEYWORD
    | PRECISION //For some reason this is possible to use as ID
    //Babelfish-specific
    | BABELFISH_STATISTICS
    | BABELFISH_SHOWPLAN_ALL
    ;

entity_name
	: (((server=id DOT database=id DOT)? schema=id | database=id DOT schema=id?) DOT)? table=id
    ;

full_object_name
	: (((server=id? DOT)? database=id? DOT)? schema=id? DOT)? object_name=id
    ;

table_name
    : ((database=id? DOT)? schema=id? DOT)? table=id
    ;	   

simple_name
    : DOT? (schema=id? DOT)? name=id
    ;

schema_trigger_name
    : (schema_name=id DOT)? trigger_name=id
    ;

func_proc_name_schema
    : DOT? ((schema=id)? DOT)? procedure=id
    ;

func_proc_name_database_schema
    : DOT? database=id? DOT schema=id? DOT procedure=id
    | (schema=id? DOT)? procedure=id
    ;

spatial_proc_name_server_database_schema
    : ((schema=id? DOT)? table=id? DOT)? column=id DOT ( geospatial_func_no_arg | geospatial_func_arg )
    ;

xml_proc_name_table_column
    : (table=id? DOT)? column=id DOT xml_func_arg
    ;

func_proc_name_server_database_schema
    : (server=id? DOT)? database=id? DOT schema=id? DOT procedure=id
    | (schema=id? DOT)? procedure=id
    | colon_colon procedure=id
    ;

ddl_object
    : full_object_name
    | local_id
    ;

external_name
    : EXTERNAL NAME full_object_name
    ;
    
collation
    : COLLATE id
    ;
    
full_column_name
    : ((schema=id? DOT)? table=id? DOT)? column=id DOT geospatial_col
    | (((server=id? DOT)? schema=id? DOT)? tablename=id? DOT)? column_name=id
    ;

column_name_list_with_order
    : simple_column_name (ASC | DESC)? (COMMA simple_column_name (ASC | DESC)?)*
    ;

/* We introduce specific index methods so as to avoid PG syntax leaks. */
column_name_list_with_order_for_vector
    : simple_column_name (ASC | DESC)? vector_index_ops? (COMMA simple_column_name (ASC | DESC)? vector_index_ops?)*
    ;

vector_index_ops
    : VECTOR_COSINE_OPS
    | VECTOR_IP_OPS
    | VECTOR_L1_OPS
    | VECTOR_L2_OPS
    | HALFVEC_COSINE_OPS
    | HALFVEC_IP_OPS
    | HALFVEC_L1_OPS
    | HALFVEC_L2_OPS
    | SPARSEVEC_COSINE_OPS
    | SPARSEVEC_IP_OPS
    | SPARSEVEC_L1_OPS
    | SPARSEVEC_L2_OPS
    ;

//For some reason, sql server allows any number of prefixes:  Here, h is the column: a.b.c.d.e.f.g.h
insert_column_name_list
    : col+=insert_column_id (COMMA col+=insert_column_id)*
    ;

insert_column_id
    : (ignore+=id? DOT )* id
    ;

column_name_list
    : col+=simple_column_name (COMMA col+=simple_column_name)*
    ;

cursor_name
    : id
    | LOCAL_ID
    ;

simple_column_name
    : id
    ;

// https://msdn.microsoft.com/en-us/library/ms175874.aspx
id
    : ID
    | DOUBLE_QUOTE_ID    // this is a double-quoted identifier in case of SET QUOTED_IDENTIFIER ON
    | SQUARE_BRACKET_ID
    | keyword
    | DOLLAR_IDENTITY                        
    | DOLLAR_ROWGUID								 
    | id colon_colon id
    ;

local_id
    : LOCAL_ID
    ;

// https://msdn.microsoft.com/en-us/library/ms188074.aspx
// Spaces are allowed for comparison operators.
comparison_operator
    : EQUAL | GREATER | LESS | LESS EQUAL | GREATER EQUAL | LESS GREATER | EXCLAMATION EQUAL | EXCLAMATION GREATER | EXCLAMATION LESS | MULT_ASSIGN | EQUAL_STAR_OJ | vector_operator
    ;

vector_operator
    : VECTOR_COSINE
    | VECTOR_IP
    | VECTOR_L2
    | VECTOR_L1
    | VECTOR_CONCATENATE
    ;

assignment_operator
    : PLUS_ASSIGN | MINUS_ASSIGN | MULT_ASSIGN | DIV_ASSIGN | MOD_ASSIGN | AND_ASSIGN | XOR_ASSIGN| OR_ASSIGN
    ;

file_size
    : DECIMAL( KB | MB | GB | TB | PERCENT_SIGN )?
    ;
    
//
// end of file
//    
