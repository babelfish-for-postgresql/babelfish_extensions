CREATE TABLE t_3147_1 (
        c [int] NULL,
        c_comp AS ISNULL(CONVERT(CHAR(1), 'A'), 'B')
)
GO

CREATE TABLE t_3147_2 (
        a numeric(6, 4),
        b numeric(6, 3)
)
GO

INSERT INTO t_3147_2 VALUES (10.1234, 10.123);
INSERT INTO t_3147_2 VALUES (NULL, 101.123);
GO

CREATE TABLE t_3147_3 (
        a decimal(6, 4),
        b decimal(6, 3)
)
GO

INSERT INTO t_3147_3 VALUES (10.1234, 10.123);
INSERT INTO t_3147_3 VALUES (NULL, 101.123);
GO

SELECT c_comp FROM t_3147_1
GO

-- Test ISNULL with numeric columns
SELECT ISNULL(a, b) FROM t_3147_2
GO

-- Test ISNULL with decimal columns
SELECT ISNULL(a, b) FROM t_3147_3
GO

DROP TABLE t_3147_1
DROP TABLE t_3147_2
DROP TABLE t_3147_3
GO
