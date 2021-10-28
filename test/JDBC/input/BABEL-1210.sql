CREATE FUNCTION test_implicit_2int2(@i INT2)
RETURNS INT2
AS
BEGIN
    RETURN (@i)
END;
GO

CREATE FUNCTION test_implicit_2int4(@i INT4)
RETURNS INT4
AS
BEGIN
    RETURN (@i)
END;
GO

CREATE FUNCTION test_implicit_2int8(@i INT8)
RETURNS INT8
AS
BEGIN
    RETURN (@i)
END;
GO

CREATE FUNCTION test_implicit_2float4(@i float4)
RETURNS float4
AS
BEGIN
    RETURN (@i)
END;
GO

CREATE FUNCTION test_implicit_2float8(@i float8)
RETURNS float8
AS
BEGIN
    RETURN (@i)
END;
GO


CREATE TABLE t1 (a text, b varchar(20), c char(4));
GO

INSERT INTO t1 values ('1234.56', '-12.12', '3.14');
GO
INSERT INTO t1 values ('0', '-10000', '1');
GO
INSERT INTO t1 values ('-23.33', '12345', '0');
GO
INSERT INTO t1 values ('-33', '22', '-145');
GO

-- Test implicit casting to float4

SELECT test_implicit_2float4(a), test_implicit_2float4(b), test_implicit_2float4(c) from t1;
GO

-- Test implicit casting to float8
SELECT test_implicit_2float8(a), test_implicit_2float8(b), test_implicit_2float8(c) from t1;
GO

CREATE TABLE t2 (a text, b varchar(20), c char(4));
GO

INSERT INTO t2 values ('1234', '-12', '0');
GO
INSERT INTO t2 values ('0', '10000', '-123');
GO
INSERT INTO t2 values ('-1234', '0', '52');
GO

-- Test implicit casting to int2
SELECT test_implicit_2int2(a), test_implicit_2int2(b), test_implicit_2int2(c) from t2;
GO

-- Test implicit casting to int4
SELECT test_implicit_2int4(a), test_implicit_2int4(b), test_implicit_2int4(c) from t2;
GO

-- Test implicit casting to int8
SELECT test_implicit_2int8(a), test_implicit_2int8(b), test_implicit_2int8(c) from t2;
GO

DROP TABLE t1;
GO
DROP TABLE t2;
GO
DROP FUNCTION test_implicit_2int2;
GO
DROP FUNCTION test_implicit_2int4;
GO
DROP FUNCTION test_implicit_2int8;
GO
DROP FUNCTION test_implicit_2float4;
GO
DROP FUNCTION test_implicit_2float8;
GO
