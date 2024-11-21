CREATE TABLE #t1(a int, b int)
ALTER TABLE #t1 DROP COLUMN b
select * from tempdb.sys.objects
GO
