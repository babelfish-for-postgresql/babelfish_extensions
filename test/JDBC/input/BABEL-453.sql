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


-- test for string-literal to (var)binary
CREATE TABLE t453_bin(a binary(4));
CREATE TABLE t453_varbin(a varbinary(4));
GO

INSERT INTO t453_bin VALUES ('ab');
GO
INSERT INTO t453_varbin VALUES ('ab');
GO

INSERT INTO t453_bin VALUES ('');
GO
INSERT INTO t453_varbin VALUES ('');
GO

DECLARE @var CHAR(10) = 'ab';
INSERT INTO t453_bin VALUES (@var);
GO
DECLARE @var CHAR(10) = 'ab';
INSERT INTO t453_varbin VALUES (@var);
GO

DECLARE @var VARCHAR(10) = 'ab';
INSERT INTO t453_bin VALUES (@var);
GO
DECLARE @var VARCHAR(10) = 'ab';
INSERT INTO t453_varbin VALUES (@var);
GO


-- valid
INSERT INTO t453_bin VALUES (NULL);
INSERT INTO t453_varbin VALUES (NULL);
GO

INSERT INTO t453_bin VALUES (0xab);
INSERT INTO t453_varbin VALUES (0xab);
GO

INSERT INTO t453_bin VALUES (0xabcd1234);
INSERT INTO t453_varbin VALUES (0xabcd1234);
GO

INSERT INTO t453_bin VALUES (1);
INSERT INTO t453_varbin VALUES (1);
GO

DECLARE @var VARCHAR(10) = 'ab';
INSERT INTO t453_bin VALUES (convert(binary(4), @var));
GO
DECLARE @var VARCHAR(10) = 'ab';
INSERT INTO t453_varbin VALUES (convert(binary(4), @var));
GO

SELECT count(*) FROM t453_bin;
GO
SELECT count(*) FROM t453_varbin;
GO

DROP TABLE t453_bin;
DROP TABLE t453_varbin;
GO
