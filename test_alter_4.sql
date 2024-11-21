CREATE TABLE #t4(a int, b int)
select * from dbo.#t4
GO

ALTER TABLE #t4 DROP COLUMN b
select * from dbo.#t4
GO

SELECT *
FROM tempdb.sys.tables;
