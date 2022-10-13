CREATE PROCEDURE sys_all_parameters_dep_vu_prepare_addTwo @num1 int, @num2 int
AS
SELECT (@num1 + @num2)
GO

CREATE VIEW sys_all_parameters_dep_vu_prepare_upgrade_view
AS
    SELECT name,
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
    FROM sys.all_parameters WHERE 
        object_id = OBJECT_ID('sys_all_parameters_dep_vu_prepare_addTwo')
        AND name = '@num1'
GO

CREATE PROC sys_all_parameters_dep_vu_prepare_upgrade_proc
AS
    SELECT name,
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
    FROM sys.all_parameters WHERE 
        object_id = OBJECT_ID('sys_all_parameters_dep_vu_prepare_addTwo')
        AND name = '@num1'
GO

CREATE FUNCTION sys_all_parameters_dep_vu_prepare_upgrade_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT parameter_id FROM sys.all_parameters WHERE 
        object_id = OBJECT_ID('sys_all_parameters_dep_vu_prepare_addTwo')
        AND name = '@num1')
END
GO
