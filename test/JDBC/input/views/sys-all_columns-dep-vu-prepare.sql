DROP TABLE IF EXISTS sys_all_columns_dep_vu_prepare_table
GO

CREATE TABLE sys_all_columns_dep_vu_prepare_table (
	sac_int_col INT PRIMARY KEY,
	sac_text_col_not_null VARCHAR(50) NOT NULL
)
GO

CREATE PROCEDURE sys_all_columns_dep_vu_prepare_proc1
AS
    SELECT name, is_nullable, column_id 
    FROM sys.all_columns 
    WHERE name in ('sac_int_col', 'sac_text_col_not_null');
GO

CREATE FUNCTION sys_all_columns_dep_vu_prepare_func1() 
RETURNS INT
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.all_columns'))
END
GO

CREATE VIEW sys_all_columns_dep_vu_prepare_view1
AS
    SELECT name, max_length, precision
    FROM sys.all_columns
    WHERE name in ('sac_int_col', 'sac_text_col_not_null');
GO
