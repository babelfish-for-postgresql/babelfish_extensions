USE babel_5010_vu_prepare_db1;
GO

SET NOCOUNT ON;
GO

-- special case: when table_qualifier only contains one % wildcard character and 0 or more space characters

-- should enumerate all databases
declare @p1 sys.nvarchar=''
declare @P2 sys.nvarchar=''
declare @P3 sys.nvarchar='%     '
declare @P4 sys.nvarchar=NULL
declare @fUsePattern bit = 1
INSERT INTO babel_5010_temp_table EXEC [sys].sp_tables @p1, @P2, @P3, @P4, @fUsePattern = @fUsePattern;
SELECT * FROM babel_5010_temp_table WHERE TABLE_QUALIFIER IN ('master', 'tempdb', 'msdb', 'babel_5010_vu_prepare_db1');
DELETE FROM babel_5010_temp_table;
GO

declare @p1 sys.nvarchar=''
declare @P2 sys.nvarchar=''
declare @P3 sys.nvarchar='%'
declare @P4 sys.nvarchar=NULL
declare @fUsePattern bit = 1
INSERT INTO babel_5010_temp_table EXEC [sys].sp_tables @p1, @P2, @P3, @P4, @fUsePattern = @fUsePattern;
SELECT * FROM babel_5010_temp_table WHERE TABLE_QUALIFIER IN ('master', 'tempdb', 'msdb', 'babel_5010_vu_prepare_db1');
DELETE FROM babel_5010_temp_table;
GO

INSERT INTO babel_5010_temp_table EXEC [sys].sp_tables @table_name = '', @table_owner = '', @table_qualifier = '%     ', @table_type = NULL, @fUsePattern = 1;
SELECT * FROM babel_5010_temp_table WHERE TABLE_QUALIFIER IN ('master', 'tempdb', 'msdb', 'babel_5010_vu_prepare_db1');
DELETE FROM babel_5010_temp_table;
GO

INSERT INTO babel_5010_temp_table EXEC [sys].sp_tables @table_name = '', @table_owner = '', @table_qualifier = '%', @table_type = NULL, @fUsePattern = 1;
SELECT * FROM babel_5010_temp_table WHERE TABLE_QUALIFIER IN ('master', 'tempdb', 'msdb', 'babel_5010_vu_prepare_db1');
DELETE FROM babel_5010_temp_table;
GO

-- should return empty set
declare @p1 sys.nvarchar=''
declare @P2 sys.nvarchar=''
declare @P3 sys.nvarchar='     %'
declare @P4 sys.nvarchar=NULL
declare @fUsePattern bit = 1
EXEC [sys].sp_tables @p1, @P2, @P3, @P4, @fUsePattern = @fUsePattern
GO

declare @p1 sys.nvarchar=''
declare @P2 sys.nvarchar=''
declare @P3 sys.nvarchar='     %     '
declare @P4 sys.nvarchar=NULL
declare @fUsePattern bit = 1
EXEC [sys].sp_tables @p1, @P2, @P3, @P4, @fUsePattern = @fUsePattern
GO

declare @p1 sys.nvarchar='  '
declare @P2 sys.nvarchar=''
declare @P3 sys.nvarchar=NULL
declare @P4 sys.nvarchar=NULL
declare @fUsePattern bit = 1
EXEC [sys].sp_tables @p1, @P2, @P3, @P4, @fUsePattern = @fUsePattern
GO

-- should throw error
EXEC [sys].sp_tables @table_name = '', @table_owner = '', @table_qualifier = '  %', @table_type = NULL, @fUsePattern = 1;
GO

EXEC [sys].sp_tables @table_name = '', @table_owner = '', @table_qualifier = '  %   ', @table_type = NULL, @fUsePattern = 1;
GO

EXEC [sys].sp_tables @table_name = '', @table_owner = '', @table_qualifier = '%%', @table_type = NULL, @fUsePattern = 1;
GO

EXEC [sys].sp_tables @table_name = '', @table_owner = '', @table_qualifier = '%_', @table_type = NULL, @fUsePattern = 1;
GO

EXEC [sys].sp_tables @table_name = '', @table_owner = '', @table_qualifier = 'mast%', @table_type = NULL, @fUsePattern = 1;
GO

EXEC [sys].sp_tables @table_name = '', @table_owner = '', @table_qualifier = '%db', @table_type = NULL, @fUsePattern = 1;
GO

-- special case: when all parameters are empty string, should return empty set
EXEC [sys].sp_tables @table_name = '', @table_owner = '', @table_qualifier = '', @table_type = '', @fUsePattern = 0;
GO

EXEC [sys].sp_tables @table_name = '', @table_owner = '', @table_qualifier = '', @table_type = '';
GO

-- special case: when all parameters are NULL, should return all tables and views of current database i.e. babel_5010_vu_prepare_db1
EXEC [sys].sp_tables;
GO

SET NOCOUNT OFF;
GO

USE master;
GO