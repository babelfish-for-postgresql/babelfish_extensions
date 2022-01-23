use master;
go

CREATE TABLE t453_real(a real);
CREATE TABLE t453_dp(a double precision);

-- binary -> real
declare @a binary(4) = 0xabcdabcd;
select (cast (@a as real));
go
declare @a binary(4) = 0xabcdabcd;
insert into t453_real values (@a);
go

-- binary -> double precision
declare @a binary(4) = 0xabcdabcd;
select (cast (@a as double precision));
go
declare @a binary(4) = 0xabcdabcd;
insert into t453_dp values (@a);
go

-- varbinary -> real
declare @a varbinary(4) = 0xabcdabcd;
select (cast (@a as real));
go
declare @a varbinary(4) = 0xabcdabcd;
insert into t453_real values (@a);
go

-- varbinary -> double precision
declare @a varbinary(4) = 0xabcdabcd;
select (cast (@a as double precision));
go
declare @a varbinary(4) = 0xabcdabcd;
insert into t453_dp values (@a);
go

-- reported case
CREATE PROCEDURE p453(@val real) AS
BEGIN
  DECLARE @BinaryVariable sys.varbinary(4) = @val
  PRINT @BinaryVariable
  PRINT cast(@BinaryVariable as real)
END
GO
EXEC p453 1.1;
GO

DROP PROCEDURE p453;
DROP TABLE t453_real;
DROP TABLE t453_dp;
GO
