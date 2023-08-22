DBCC CHECKIDENT(babel_3201_t_int, NORESEED);
GO

-- same as DBCC CHECKIDENT(<table_name>, RESEED), identity value is not changed
-- if current identity value for a table is less than the maximum identity value
-- stored in the identity column
DBCC CHECKIDENT(babel_3201_t_int);
GO


DBCC CHECKIDENT(babel_3201_t_int, RESEED);
GO

INSERT INTO babel_3201_t_int VALUES (8);
GO

SELECT * FROM babel_3201_t_int;
GO

DBCC CHECKIDENT(babel_3201_sch1.babel_3201_t2);
GO

-- Set identity value to 5 which is less than the maximum value of the identity
-- column, using RESEED option in this case should will reset the identity value
-- to maximum value of the identity column. Value inserted in next insert will
-- be (max_identity_col_value + increment).
DBCC CHECKIDENT(babel_3201_t_bigint, RESEED, 3);
GO

INSERT INTO babel_3201_t_bigint VALUES (8);
GO

SELECT * from babel_3201_t_bigint;
GO

DBCC CHECKIDENT(babel_3201_t_bigint, RESEED);
GO

INSERT INTO babel_3201_t_bigint VALUES (9);
GO

SELECT * from babel_3201_t_bigint;
GO

-- no rows have been inserted in the table; both current identity value current
-- column value should be NULL (TO-DO)
DBCC CHECKIDENT(babel_3201_t1, NORESEED);
GO

DBCC CHECKIDENT(babel_3201_t1, RESEED);
GO

-- current identity value should be NULL (TO-DO), identity value inserted in
-- next INSERT operation should be new_reseed_value.
DBCC CHECKIDENT(babel_3201_t1, RESEED, 5);
GO

INSERT INTO babel_3201_t_int VALUES (5);
GO

SELECT * FROM babel_3201_t_int;
GO

-- Remove all rows in table using TRUNCATE TABLE, identity value inserted in
-- next INSERT operation should be new_reseed_value.
TRUNCATE TABLE babel_3201_t_int;
GO

DBCC CHECKIDENT(babel_3201_t_int, RESEED, 10);
GO

INSERT INTO babel_3201_t_int VALUES (5);
GO

SELECT * FROM babel_3201_t_int;
GO

-- Remove all rows in table using DELETE TABLE, identity value inserted in next
-- INSERT operation should be (new_reseed_value + increment).
DELETE FROM babel_3201_t_bigint;
GO

DBCC CHECKIDENT(babel_3201_t_bigint, RESEED, 10);
GO

INSERT INTO babel_3201_t_bigint VALUES (5);
GO

SELECT * FROM babel_3201_t_bigint;
GO

-- Incorrect DBCC command option
DBCC CHECKIDENT(babel_3201_t1) WITH NO_INFO;
GO

-- Invalid parameter 1
DBCC CHECKIDENT(5);
GO

DBCC CHECKIDENT(babel_3201_t_int, RESEED, ) WITH NO_INFOMSGS;
GO

-- Invalid keyword
DBCC CHECKIDENT(babel_3201_t1, RESEE);
GO

-- Invalid datatype
DBCC CHECKIDENT(babel_3201_t1, RESEED, 1313abc);
GO

-- Unsupported DBCC command
DBCC CHECKTABLE(babel_3201_t1);
GO

-- Invalid DBCC command
DBCC FAKE_COMMAND(t1);
GO

-- Database undefined
DBCC CHECKIDENT(fake_db.dbo.babel_3201_t1, NORESEED);
GO

-- Table undefined
DBCC CHECKIDENT(babel_3201_t1, RESEED);
GO

-- Schema undefined
DBCC CHECKIDENT(babel_3201_sch3.babel_3201_t1, NORESEED);
GO

-- Table does not have identity column
DBCC CHECKIDENT(babel_3201_t2, RESEED);
GO

-- new_reseed_value as expression is not allowed
DBCC CHECKIDENT(babel_3201_t2, RESEED, 4+5);
GO

-- new_reseed_value is out of tinyint datatype range
DBCC CHECKIDENT(babel_3201_t_tinyint, RESEED, 256);
GO

DBCC CHECKIDENT(babel_3201_t_tinyint, RESEED, -1);
GO

-- new_reseed_value is out of smallint datatype range
DBCC CHECKIDENT(babel_3201_t_smallint, RESEED, 32768);
GO

DBCC CHECKIDENT(babel_3201_t_smallint, RESEED, -32769);
GO


-- new_reseed_value is out of int datatype range
DBCC CHECKIDENT(babel_3201_t_int, RESEED, 2147483648);
GO

DBCC CHECKIDENT(babel_3201_t_int, RESEED, -2147483649);
GO

-- new_reseed_value is out of bigint datatype range
DBCC CHECKIDENT(babel_3201_t_bigint, RESEED, 9223372036854775808);
GO

DBCC CHECKIDENT(babel_3201_t_bigint, RESEED, -9223372036854775809);
GO

-- numeric/decimal datatypes are internally converted to bigint, so allowed
-- range is same as that of bigint
DBCC CHECKIDENT(babel_3201_t_numeric, RESEED, 9223372036854775808);
GO

-- When new_reseed_value is a float value, only value before the decimal is used
DBCC CHECKIDENT(babel_3201_t_decimal, RESEED, -15.65);
GO

INSERT INTO babel_3201_t_decimal VALUES (8);
GO

SELECT * FROM babel_3201_t_decimal;
GO

-- CREATE LOGIN babel_3201_log1 WITH PASSWORD='123456789';
-- GO

-- CREATE USER babel_3201_user1 FOR LOGIN babel_3201_log1;
-- GO

-- tsql user=babel_3201_log1 password=123456789
DBCC CHECKIDENT(babel_3201_t_decimal, RESEED);
GO

begin tran;
DBCC CHECKIDENT(babel_3201_t_decimal, RESEED, 10);
INSERT INTO babel_3201_t_decimal VALUES (9);
commit;
go

SELECT * FROM babel_3201_t_decimal;
GO

BEGIN TRAN;
    DBCC CHECKIDENT(babel_3201_t_decimal, RESEED, 133ac);
    INSERT INTO babel_3201_t_decimal VALUES (10);
COMMIT;
GO

SELECT * FROM babel_3201_t_decimal;
GO

BEGIN TRAN;
    DBCC CHECKIDENT(babel_3201_t_decimal, RESEED, 20);
    INSERT INTO babel_3201_t_decimal VALUES (11);
ROLLBACK;
GO

SELECT * FROM babel_3201_t_decimal;
GO
