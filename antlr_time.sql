set BABELFISH_STATISTICS PROFILE on

CREATE TABLE #t1(a int, b int)
select * from dbo.#t1
GO

ALTER TABLE #t1 DROP COLUMN b
select * from dbo.#t1
GO

