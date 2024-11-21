CREATE TABLE t3(a int, b int)
select * from dbo.t3
GO

ALTER TABLE t3 DROP COLUMN b
select * from dbo.t3
GO
