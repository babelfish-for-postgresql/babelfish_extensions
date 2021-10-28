use master;
go

-- sql batch
SELECT NULLIF(NULL, 2);
GO

-- create procedure -> should throw compile-time error
CREATE PROCEDURE p_2234 AS
  SELECT NULLIF(NULL, 2);
GO

-- NULL variable should be allowed
declare @a int;
set @a = NULL;
select nullif(@a, 2);
go

-- mixed case nullif
SELECT NuLlIf(nULL, 2);
GO
