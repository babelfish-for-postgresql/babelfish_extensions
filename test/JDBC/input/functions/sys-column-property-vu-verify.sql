DECLARE @table_id INT
SET @table_id = (select OBJECT_ID('sys_column_property_vu_t_column_property'));

SELECT * FROM sys.columnproperty(@table_id, 'cp1', 'charmaxlen');
SELECT * FROM sys.columnproperty(@table_id, 'cp2', 'charmaxlen');
SELECT * FROM sys.columnproperty(@table_id, 'cp3', 'charmaxlen');
SELECT * FROM sys.columnproperty(@table_id, 'cp4', 'charmaxlen');
SELECT * FROM sys.columnproperty(@table_id, 'cp5', 'charmaxlen');
SELECT * FROM sys.columnproperty(@table_id, 'cp6', 'charmaxlen');
GO

DECLARE @table_id INT
SET @table_id = (select OBJECT_ID('sys_column_property_vu_t_column_property'));

SELECT * FROM sys.columnproperty(@table_id, 'cp1', 'allowsnull');
SELECT * FROM sys.columnproperty(@table_id, 'cp2', 'allowsnull');
SELECT * FROM sys.columnproperty(@table_id, 'cp3', 'allowsnull');
SELECT * FROM sys.columnproperty(@table_id, 'cp4', 'allowsnull');
SELECT * FROM sys.columnproperty(@table_id, 'cp5', 'allowsnull');
SELECT * FROM sys.columnproperty(@table_id, 'cp6', 'allowsnull');
SELECT * FROM sys.columnproperty(@table_id, 'cp7', 'allowsnull');
SELECT * FROM sys.columnproperty(@table_id, 'cp8', 'allowsnull');
GO