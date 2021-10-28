create table babel1239 (a int);
go
SELECT * from babel1239
OPTION (MAXRECURSION 256);
go
WITH
z
AS (
      SELECT a FROM babel1239
   )
SELECT * from z
OPTION (MAXRECURSION 256);
go
drop table babel1239;
go
