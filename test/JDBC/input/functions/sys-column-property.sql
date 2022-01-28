DROP TABLE IF EXISTS t_column_property
GO

CREATE TABLE t_column_property(
  cp1 CHAR(1) NOT NULL, 
  cp2 CHAR(129), 
  cp3 CHAR(4000) NOT NULL,
  cp4 VARCHAR(1),
  cp5 VARCHAR(129) NOT NULL,
  cp6 VARCHAR(4000),
  cp7 INT,
  cp8 INT NOT NULL);
GO

DECLARE @table_id INT
SET @table_id = (select OBJECT_ID('t_column_property'));

SELECT * FROM sys.columnproperty(@table_id, 'cp1', 'charmaxlen');
SELECT * FROM sys.columnproperty(@table_id, 'cp2', 'charmaxlen');
SELECT * FROM sys.columnproperty(@table_id, 'cp3', 'charmaxlen');
SELECT * FROM sys.columnproperty(@table_id, 'cp4', 'charmaxlen');
SELECT * FROM sys.columnproperty(@table_id, 'cp5', 'charmaxlen');
SELECT * FROM sys.columnproperty(@table_id, 'cp6', 'charmaxlen');
GO

DECLARE @table_id INT
SET @table_id = (select OBJECT_ID('t_column_property'));

SELECT * FROM sys.columnproperty(@table_id, 'cp1', 'allowsnull');
SELECT * FROM sys.columnproperty(@table_id, 'cp2', 'allowsnull');
SELECT * FROM sys.columnproperty(@table_id, 'cp3', 'allowsnull');
SELECT * FROM sys.columnproperty(@table_id, 'cp4', 'allowsnull');
SELECT * FROM sys.columnproperty(@table_id, 'cp5', 'allowsnull');
SELECT * FROM sys.columnproperty(@table_id, 'cp6', 'allowsnull');
SELECT * FROM sys.columnproperty(@table_id, 'cp7', 'allowsnull');
SELECT * FROM sys.columnproperty(@table_id, 'cp8', 'allowsnull');
GO

DROP TABLE IF EXISTS t_column_property
GO
