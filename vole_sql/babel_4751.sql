CREATE procedure temp_table_test_s AS
BEGIN
  CREATE TABLE #tt (a int);
  CREATE TABLE #tt (a int);
END;

DECLARE @i int = 0

WHILE @i < 500
BEGIN
EXEC temp_table_test_s;
SET @i = @i + 1
END

create table #temp(c1 int)

go
