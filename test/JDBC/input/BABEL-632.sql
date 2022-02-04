SELECT CAST('\x31' AS bytea);
GO

SELECT CAST('0x31' AS bytea);
GO

-- Test bytea column in a table
CREATE TABLE t_bytea(c1 int, c2 bytea);
GO

INSERT INTO t_bytea (c1, c2) VALUES (1, '\x31');
INSERT INTO t_bytea (c1, c2) VALUES (2, '0x31');
GO

-- Test cast bytea to varbinary
SELECT c1, CAST(c2 AS varbinary(10)) FROM t_bytea;
GO

--Test cast bytea to varchar
SELECT c1, CAST(c2 AS varchar(10)) FROM t_bytea;
GO

DROP TABLE t_bytea;
GO
