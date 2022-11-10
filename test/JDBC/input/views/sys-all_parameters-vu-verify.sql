-- sla 80000
SELECT 
name,
parameter_id,
max_length,
precision,
scale,
is_output,
is_cursor_ref,
has_default_value,
default_value,
xml_collection_id,
is_readonly,
is_nullable,
encryption_type,
encryption_type_desc,
encryption_algorithm_name,
column_encryption_key_id,
column_encryption_key_database_name
FROM sys.all_parameters WHERE object_id = OBJECT_ID('sys_all_parameters_vu_prepare_addTwo')
ORDER BY parameter_id
GO

SELECT
name,
parameter_id,
max_length,
precision,
scale,
is_output,
is_cursor_ref,
has_default_value,
default_value,
xml_collection_id,
is_readonly,
is_nullable,
encryption_type,
encryption_type_desc,
encryption_algorithm_name,
column_encryption_key_id,
column_encryption_key_database_name
FROM sys.all_parameters WHERE object_id = OBJECT_ID('sys_all_parameters_vu_prepare_complexProc')
ORDER BY parameter_id
GO

SELECT
name,
parameter_id,
max_length,
precision,
scale,
is_output,
is_cursor_ref,
has_default_value,
default_value,
xml_collection_id,
is_readonly,
is_nullable,
encryption_type,
encryption_type_desc,
encryption_algorithm_name,
column_encryption_key_id,
column_encryption_key_database_name
FROM sys.all_parameters WHERE object_id = OBJECT_ID('sys_all_parameters_schema_vu_prepare.sys_all_parameters_vu_prepare_complexProc')
ORDER BY parameter_id
GO

SELECT
name,
parameter_id,
max_length,
precision,
scale,
is_output,
is_cursor_ref,
has_default_value,
default_value,
xml_collection_id,
is_readonly,
is_nullable,
encryption_type,
encryption_type_desc,
encryption_algorithm_name,
column_encryption_key_id,
column_encryption_key_database_name
FROM sys.all_parameters WHERE object_id = OBJECT_ID('sys.sp_sproc_columns')
ORDER BY parameter_id
GO

SELECT
name,
parameter_id,
max_length,
precision,
scale,
is_output,
is_cursor_ref,
has_default_value,
default_value,
xml_collection_id,
is_readonly,
is_nullable,
encryption_type,
encryption_type_desc,
encryption_algorithm_name,
column_encryption_key_id,
column_encryption_key_database_name
FROM sys.all_parameters WHERE object_id = OBJECT_ID('sys_all_parameters_vu_prepare_scalFunc')
ORDER BY parameter_id
GO

SELECT 
name,
parameter_id,
max_length,
precision,
scale,
is_output,
is_cursor_ref,
has_default_value,
default_value,
xml_collection_id,
is_readonly,
is_nullable,
encryption_type,
encryption_type_desc,
encryption_algorithm_name,
column_encryption_key_id,
column_encryption_key_database_name
FROM sys.all_parameters WHERE object_id = OBJECT_ID('sys_all_parameters_vu_prepare_tableFunc')
ORDER BY parameter_id
GO

SELECT 
name,
parameter_id,
max_length,
precision,
scale,
is_output,
is_cursor_ref,
has_default_value,
default_value,
xml_collection_id,
is_readonly,
is_nullable,
encryption_type,
encryption_type_desc,
encryption_algorithm_name,
column_encryption_key_id,
column_encryption_key_database_name
FROM sys.all_parameters WHERE object_id = OBJECT_ID('sys_all_parameters_vu_prepare_InlineTableFunc')
ORDER BY parameter_id
GO

SELECT 
name,
parameter_id,
max_length,
precision,
scale,
is_output,
is_cursor_ref,
has_default_value,
default_value,
xml_collection_id,
is_readonly,
is_nullable,
encryption_type,
encryption_type_desc,
encryption_algorithm_name,
column_encryption_key_id,
column_encryption_key_database_name
FROM sys.all_parameters WHERE object_id = OBJECT_ID('sys_all_parameters_vu_prepare_tableFunc2')
ORDER BY parameter_id
GO

SELECT 
name,
parameter_id,
max_length,
precision,
scale,
is_output,
is_cursor_ref,
has_default_value,
default_value,
xml_collection_id,
is_readonly,
is_nullable,
encryption_type,
encryption_type_desc,
encryption_algorithm_name,
column_encryption_key_id,
column_encryption_key_database_name
FROM sys.all_parameters WHERE object_id = OBJECT_ID('sys_all_parameters_vu_prepare_InlineTableFunc2')
ORDER BY parameter_id
GO

SELECT 
name,
parameter_id,
max_length,
precision,
scale,
is_output,
is_cursor_ref,
has_default_value,
default_value,
xml_collection_id,
is_readonly,
is_nullable,
encryption_type,
encryption_type_desc,
encryption_algorithm_name,
column_encryption_key_id,
column_encryption_key_database_name
FROM sys.all_parameters WHERE object_id = OBJECT_ID('sys_all_parameters_vu_prepare_tvpProc')
ORDER BY parameter_id
GO

SELECT 
name,
parameter_id,
max_length,
precision,
scale,
is_output,
is_cursor_ref,
has_default_value,
default_value,
xml_collection_id,
is_readonly,
is_nullable,
encryption_type,
encryption_type_desc,
encryption_algorithm_name,
column_encryption_key_id,
column_encryption_key_database_name
FROM sys.all_parameters WHERE object_id = OBJECT_ID('sys_all_parameters_vu_prepare_myDecFunc')
ORDER BY parameter_id
GO

SELECT 
name,
parameter_id,
max_length,
precision,
scale,
is_output,
is_cursor_ref,
has_default_value,
default_value,
xml_collection_id,
is_readonly,
is_nullable,
encryption_type,
encryption_type_desc,
encryption_algorithm_name,
column_encryption_key_id,
column_encryption_key_database_name
FROM sys.all_parameters WHERE object_id = OBJECT_ID('sys_all_parameters_vu_prepare_typeModifier')
ORDER BY parameter_id
GO

SELECT 
name,
parameter_id,
max_length,
precision,
scale,
is_output,
is_cursor_ref,
has_default_value,
default_value,
xml_collection_id,
is_readonly,
is_nullable,
encryption_type,
encryption_type_desc,
encryption_algorithm_name,
column_encryption_key_id,
column_encryption_key_database_name
FROM sys.all_parameters WHERE object_id = OBJECT_ID('sys_all_parameters_vu_prepare_DataTypeExamples')
ORDER BY parameter_id
GO
