CREATE TABLE #babel_temp_table (ID INT identity(1,1), Data INT)
INSERT INTO #babel_temp_table (Data) VALUES (100), (200), (300)
GO

SELECT * from #babel_temp_table
GO

EXEC sys.sp_reset_connection
GO

SELECT * from #babel_temp_table
Go
