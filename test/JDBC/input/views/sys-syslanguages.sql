SELECT COUNT(*) FROM sys.all_columns WHERE object_id = object_id('sys.syslanguages');
GO

SELECT * FROM sys.syslanguages WHERE langid = 1;
GO
