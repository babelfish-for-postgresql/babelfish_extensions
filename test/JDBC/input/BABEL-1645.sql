CREATE TABLE test(c1 int)
go
CREATE VIEW vt
AS
SELECT * FROM test
go

-- Below should fail
CREATE TABLE #t(c1 int)
go
CREATE VIEW v
AS
SELECT * FROM #t
go

-- clean up
DROP VIEW vt
go

DROP TABLE test
go

DROP TABLE #t
go
