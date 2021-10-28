USE master;
GO

CREATE TABLE babel_sequence_tinyint (id [tinyint] IDENTITY, col1 [tinyint]);
go
CREATE PROCEDURE insert_babel_sequence_tinyint_id
@id tinyint, @val tinyint
AS BEGIN
    SET IDENTITY_INSERT babel_sequence_tinyint ON;
    INSERT INTO babel_sequence_tinyint (id, col1) VALUES (@id, @val);
    SET IDENTITY_INSERT babel_sequence_tinyint OFF;
END;
go
EXEC insert_babel_sequence_tinyint_id 2, 1;
go
EXEC insert_babel_sequence_tinyint_id 8, 2;
go
INSERT INTO babel_sequence_tinyint (col1) VALUES (10), (20), (30);
go
EXEC insert_babel_sequence_tinyint_id 16, 3;
go
EXEC insert_babel_sequence_tinyint_id 255, 4;
go
INSERT INTO babel_sequence_tinyint (col1) VALUES (40);
go
SELECT * FROM babel_sequence_tinyint;
go

CREATE TABLE babel_sequence_tinyint_dec (id [tinyint] IDENTITY(1,-1), col1 [tinyint]);
go
INSERT INTO babel_sequence_tinyint_dec (col1) VALUES (10);
go
INSERT INTO babel_sequence_tinyint_dec (col1) VALUES (20);
go
INSERT INTO babel_sequence_tinyint_dec (col1) VALUES (30);
go
SELECT * FROM babel_sequence_tinyint_dec;
go

CREATE TABLE babel_sequence_smallint (id [smallint] IDENTITY, col1 [int]);
go
INSERT INTO babel_sequence_smallint (col1) VALUES (10), (20), (30);
go
SELECT * FROM babel_sequence_smallint;
go

CREATE TABLE babel_sequence_int (id [int] IDENTITY, col1 [int]);
go
CREATE PROCEDURE insert_babel_sequence_int_id
@id INT, @val INT
AS BEGIN
    SET IDENTITY_INSERT babel_sequence_int ON;
    INSERT INTO babel_sequence_int (id, col1) VALUES (@id, @val);
    SET IDENTITY_INSERT babel_sequence_int OFF;
END;
go
EXEC insert_babel_sequence_int_id 2, 1;
go
EXEC insert_babel_sequence_int_id 8, 2;
go
INSERT INTO babel_sequence_int (col1) VALUES (10), (20), (30);
go
EXEC insert_babel_sequence_int_id 16, 3;
go
EXEC insert_babel_sequence_int_id 32, 4;
go
SELECT * FROM babel_sequence_int;
go

CREATE TABLE babel_sequence_bigint (id [bigint] IDENTITY, col1 [int]);
go
INSERT INTO babel_sequence_bigint (col1) VALUES (10), (20), (30);
go
SELECT * FROM babel_sequence_bigint;
go

CREATE TABLE babel_sequence_numeric (id numeric(18,0) IDENTITY, col1 int);
go
CREATE PROCEDURE insert_babel_sequence_numeric_id
@id NUMERIC, @val NUMERIC
AS BEGIN
    SET IDENTITY_INSERT babel_sequence_numeric ON;
    INSERT INTO babel_sequence_numeric (id, col1) VALUES (@id, @val);
    SET IDENTITY_INSERT babel_sequence_numeric OFF;
END;
go
EXEC insert_babel_sequence_numeric_id 2, 1;
go
EXEC insert_babel_sequence_numeric_id 8, 2;
go
INSERT INTO babel_sequence_numeric (col1) VALUES (10), (20), (30);
go
EXEC insert_babel_sequence_numeric_id 16, 3;
go
EXEC insert_babel_sequence_numeric_id 32, 4;
go
SELECT * FROM babel_sequence_numeric;
go

CREATE TABLE babel_sequence_decimal (id decimal(18,0) IDENTITY, col1 int);
go
CREATE PROCEDURE insert_babel_sequence_decimal_id
@id DECIMAL, @val DECIMAL
AS BEGIN
    SET IDENTITY_INSERT babel_sequence_decimal ON;
    INSERT INTO babel_sequence_decimal (id, col1) VALUES (@id, @val);
    SET IDENTITY_INSERT babel_sequence_decimal OFF;
END;
go
EXEC insert_babel_sequence_decimal_id 2, 1;
go
EXEC insert_babel_sequence_decimal_id 8, 2;
go
INSERT INTO babel_sequence_decimal (col1) VALUES (10), (20), (30);
go
EXEC insert_babel_sequence_decimal_id 16, 3;
go
EXEC insert_babel_sequence_decimal_id 32, 4;
go
SELECT * FROM babel_sequence_decimal;
go

-- Test faulty table creation
CREATE TABLE babel_sequence_numeric_faulty_scale (id numeric(18,6) IDENTITY, col1 int);
go
CREATE TABLE babel_sequence_numeric_faulty_precision (id numeric(20,0) IDENTITY, col1 int);
go

-- Test ALTER on identity property
CREATE TABLE babel_sequence_alter (col1 [int]);
go
INSERT INTO babel_sequence_alter VALUES (-5), (10), (42);
go

ALTER TABLE babel_sequence_alter ADD id_tinyint [tinyint] IDENTITY(1,1);
go
SELECT * FROM babel_sequence_alter;
go
ALTER TABLE babel_sequence_alter DROP COLUMN id_tinyint;
go

ALTER TABLE babel_sequence_alter ADD id_smallint [smallint] IDENTITY(1,1);
go
SELECT * FROM babel_sequence_alter;
go
ALTER TABLE babel_sequence_alter DROP COLUMN id_smallint;
go

ALTER TABLE babel_sequence_alter ADD id_int [int] IDENTITY;
go
SELECT * FROM babel_sequence_alter;
go
ALTER TABLE babel_sequence_alter DROP COLUMN id_int;
go

ALTER TABLE babel_sequence_alter ADD id_bigint [bigint] IDENTITY(32,8);
go
INSERT INTO babel_sequence_alter VALUES (-5), (10), (42);
go
SELECT * FROM babel_sequence_alter;
go
ALTER TABLE babel_sequence_alter DROP COLUMN id_bigint;
go

ALTER TABLE babel_sequence_alter ADD id_numeric numeric(18,0) IDENTITY(32,8);
go
INSERT INTO babel_sequence_alter VALUES (-5), (10), (42);
go
SELECT * FROM babel_sequence_alter;
go
ALTER TABLE babel_sequence_alter DROP COLUMN id_numeric;
go

ALTER TABLE babel_sequence_alter ADD id_decimal decimal(18,0) IDENTITY(32,8);
go
INSERT INTO babel_sequence_alter VALUES (-5), (10), (42);
go
SELECT * FROM babel_sequence_alter;
go
ALTER TABLE babel_sequence_alter DROP COLUMN id_decimal;
go

-- Test sequences
CREATE SEQUENCE seq_tinyint
AS [tinyint]
START WITH 1
INCREMENT BY 1
CACHE  50
go
SELECT nextval('seq_tinyint');
go
SELECT setval('seq_tinyint', 255);
go
SELECT nextval('seq_tinyint');
go

CREATE SEQUENCE seq_smallint
AS [smallint]
START WITH 1
INCREMENT BY 1
CACHE  50
go
SELECT nextval('seq_smallint');
go
SELECT setval('seq_smallint', 32767);
go
SELECT nextval('seq_smallint');
go

CREATE SEQUENCE seq_int
AS [int]
START WITH 1
INCREMENT BY 1
CACHE  50
go
SELECT nextval('seq_int');
go
SELECT setval('seq_int', 2147483647);
go
SELECT nextval('seq_int');
go

CREATE SEQUENCE seq_bigint
AS [bigint]
START WITH 1
INCREMENT BY 1
CACHE  50
go
SELECT nextval('seq_bigint');
go
SELECT setval('seq_bigint', 9223372036854775807);
go
SELECT nextval('seq_bigint');
go

CREATE SEQUENCE seq_numeric
AS numeric(18,0)
START WITH 1
INCREMENT BY 1
CACHE  50
go
SELECT nextval('seq_numeric');
go
SELECT setval('seq_numeric', 9223372036854775807);
go
SELECT nextval('seq_numeric');
go

CREATE SEQUENCE seq_decimal
AS decimal(18,0)
START WITH 1
INCREMENT BY 1
CACHE  50
go
SELECT nextval('seq_decimal');
go
SELECT setval('seq_decimal', 9223372036854775807);
go
SELECT nextval('seq_decimal');
go

-- Test faulty sequence creation
CREATE SEQUENCE seq_tinyint_faulty_min
AS [tinyint]
START WITH 1
INCREMENT BY 1
MINVALUE -1
MAXVALUE 255
CACHE  50
go

CREATE SEQUENCE seq_tinyint_faulty_max
AS [tinyint]
START WITH 1
INCREMENT BY 1
MINVALUE 0
MAXVALUE 256
CACHE  50
go

CREATE SEQUENCE seq_numeric_faulty_scale
AS numeric(10,1)
START WITH 1
INCREMENT BY 1
CACHE  50
go

CREATE SEQUENCE seq_numeric_faulty_precision
AS numeric(21,0)
START WITH 1
INCREMENT BY 1
CACHE  50
go

DROP PROC insert_babel_sequence_tinyint_id, insert_babel_sequence_int_id, insert_babel_sequence_numeric_id, insert_babel_sequence_decimal_id;
go
DROP TABLE babel_sequence_tinyint, babel_sequence_tinyint_dec, babel_sequence_smallint, babel_sequence_int, babel_sequence_bigint, babel_sequence_numeric, babel_sequence_decimal, babel_sequence_alter;
go
DROP SEQUENCE seq_tinyint, seq_smallint, seq_int, seq_bigint, seq_numeric, seq_decimal;
go