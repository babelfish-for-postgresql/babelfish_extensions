CREATE VIEW sys_assembly_types_view_vu_prepare AS
SELECT name, principal_id, max_length, precision, scale, collation_name, is_nullable, is_user_defined, is_assembly_type, default_object_id, rule_object_id, assembly_id, assembly_class, is_binary_ordered, is_fixed_length, prog_id, assembly_qualified_name, is_table_type FROM sys.assembly_types ORDER BY name DESC
GO

CREATE PROC sys_assembly_types_proc_vu_prepare AS
SELECT name, principal_id, max_length, precision, scale, collation_name, is_nullable, is_user_defined, is_assembly_type, default_object_id, rule_object_id, assembly_id, assembly_class, is_binary_ordered, is_fixed_length, prog_id, assembly_qualified_name, is_table_type FROM sys.assembly_types ORDER BY name DESC
GO

CREATE FUNCTION sys_assembly_types_func_vu_prepare()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.assembly_types)
END
GO
