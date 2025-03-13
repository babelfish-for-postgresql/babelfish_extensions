-- varbinary(max)
CREATE TABLE BINARY_dt(a VARBINARY(max));
GO

INSERT INTO BINARY_dt(a) values (NULL);
GO
INSERT INTO BINARY_dt(a) values (123456);
GO
INSERT INTO BINARY_dt(a) values (0x);
GO
INSERT INTO BINARY_dt(a) values (' Abc   ');
GO
INSERT INTO BINARY_dt(a) values (cast(replicate(0x41, 8010) as varbinary(max)));
GO

SELECT * FROM BINARY_dt order by a;
GO

UPDATE BINARY_dt set a = 0x where a = NULL;
GO

SELECT * FROM BINARY_dt order by a;
GO

UPDATE BINARY_dt set a = 0x where a IS NOT NULL;
GO

SELECT * FROM BINARY_dt order by a;
GO

DROP TABLE BINARY_dt;
GO

-- simple varbinary(max) testing along with other columns
create table BINARY_dt (a VARBINARY(max), b int, c int, d int, e int ,f int, g int, h int, i int);
GO

insert into BINARY_dt (a,b,c,d,e,f,g,h,i) values (NULL,1,2,3,4,5,6,7,8);
GO

DELETE FROM BINARY_dt WHERE a = NULL;

select * from BINARY_dt;
GO

drop table BINARY_dt;
GO

-- FK-PK testing
CREATE TABLE BINARY_dt_pkey(a VARBINARY(400) primary key);
GO

INSERT INTO BINARY_dt_pkey(a) values (NULL);
GO
INSERT INTO BINARY_dt_pkey(a) values (123456);
GO
INSERT INTO BINARY_dt_pkey(a) values (0x);
GO
INSERT INTO BINARY_dt_pkey(a) values (0x3132333435);
GO

CREATE TABLE BINARY_dt_fkey
    (
     a varbinary(400),
     FOREIGN KEY (a) REFERENCES BINARY_dt_pkey(a)
    );

INSERT INTO BINARY_dt_fkey(a) values (NULL);
GO
INSERT INTO BINARY_dt_fkey(a) values (123456);
GO
INSERT INTO BINARY_dt_fkey(a) values (0x);
GO
INSERT INTO BINARY_dt_fkey(a) values (0x3132333435);
GO

select * from BINARY_dt_fkey order by a;
GO

select t1.a, t2.a from BINARY_dt_pkey t1 join BINARY_dt_fkey t2 on t1.a = t2.a order by t1.a;
GO

-- delete pkey which is referenced by fkey
DELETE from BINARY_dt_pkey where a = 123456;
GO

DELETE from BINARY_dt_fkey where a = 0x3132333435;
GO

select * from BINARY_dt_fkey order by a;
GO

DROP TABLE BINARY_dt_fkey;
DROP TABLE BINARY_dt_pkey;
GO

-- partitioned table testing on varbinary
CREATE PARTITION FUNCTION BINARY_dt_partition_func (VARBINARY(400)) 
    AS RANGE RIGHT FOR VALUES(
        0x2550,
        0x4749,
        0xFFD8,
        0x8950
    );
GO

CREATE PARTITION SCHEME BINARY_dt_partition_scheme
    AS PARTITION BINARY_dt_partition_func ALL
    TO ([PRIMARY]);
GO

CREATE TABLE BINARY_dt_partition(
    a VARBINARY(400),
    type VARCHAR(10))
ON BINARY_dt_partition_scheme(a);
GO

INSERT INTO BINARY_dt_partition (a, type) VALUES (0x255044462D312E350D0A, 'PDF');
GO
INSERT INTO BINARY_dt_partition (a, type) VALUES  (0x255044462D312E360D0A, 'PDF');
GO

INSERT INTO BINARY_dt_partition (a, type) VALUES (0x474946383961, 'GIF');
GO
INSERT INTO BINARY_dt_partition (a, type) VALUES (0x474946383961, 'GIF');
GO

INSERT INTO BINARY_dt_partition (a, type) VALUES (0xFFD8FFE000104A4649460001, 'JPEG');
GO
INSERT INTO BINARY_dt_partition (a, type) VALUES (0xFFD8FFE000104A4649460001, 'JPEG');
GO

INSERT INTO BINARY_dt_partition (a, type) VALUES (0x89504E470D0A1A0A, 'PNG');
GO
INSERT INTO BINARY_dt_partition (a, type) VALUES (0x89504E470D0A1A0A, 'PNG');
GO

-- Query to show files in each partition
SELECT a, type, $PARTITION.BINARY_dt_partition_func(a) AS PartitionNumber
    FROM BINARY_dt_partition ORDER BY PartitionNumber;
GO

-- Query to show count of files by partition
SELECT $PARTITION.BINARY_dt_partition_func(a) AS PartitionNumber, type, COUNT(*) AS FileCount
    FROM BINARY_dt_partition
    GROUP BY $PARTITION.BINARY_dt_partition_func(a), type
    ORDER BY PartitionNumber;
GO

DROP TABLE BINARY_dt_partition;
DROP PARTITION SCHEME BINARY_dt_partition_scheme;
DROP PARTITION FUNCTION BINARY_dt_partition_func;
GO

-- partitioning support testing with binary data type
CREATE PARTITION FUNCTION BINARY_dt_partition_func (BINARY(20)) 
    AS RANGE RIGHT FOR VALUES(
        0x2550,
        0x4749,
        0xFFD8,
        0x8950
    );
GO

CREATE PARTITION SCHEME BINARY_dt_partition_scheme
    AS PARTITION BINARY_dt_partition_func ALL
    TO ([PRIMARY]);
GO

CREATE TABLE BINARY_dt_partition(
    a BINARY(20),
    type VARCHAR(10))
ON BINARY_dt_partition_scheme(a);
GO

INSERT INTO BINARY_dt_partition (a, type) VALUES (0x255044462D312E350D0A, 'PDF');
GO
INSERT INTO BINARY_dt_partition (a, type) VALUES  (0x255044462D312E360D0A, 'PDF');
GO

INSERT INTO BINARY_dt_partition (a, type) VALUES (0x474946383961, 'GIF');
GO
INSERT INTO BINARY_dt_partition (a, type) VALUES (0x474946383961, 'GIF');
GO

INSERT INTO BINARY_dt_partition (a, type) VALUES (0xFFD8FFE000104A4649460001, 'JPEG');
GO
INSERT INTO BINARY_dt_partition (a, type) VALUES (0xFFD8FFE000104A4649460001, 'JPEG');
GO

INSERT INTO BINARY_dt_partition (a, type) VALUES (0x89504E470D0A1A0A, 'PNG');
GO
INSERT INTO BINARY_dt_partition (a, type) VALUES (0x89504E470D0A1A0A, 'PNG');
GO

-- Query to show files in each partition
SELECT a, type, $PARTITION.BINARY_dt_partition_func(a) AS PartitionNumber
    FROM BINARY_dt_partition ORDER BY PartitionNumber;
GO

-- Query to show count of files by partition
SELECT $PARTITION.BINARY_dt_partition_func(a) AS PartitionNumber, type, COUNT(*) AS FileCount
    FROM BINARY_dt_partition
    GROUP BY $PARTITION.BINARY_dt_partition_func(a), type
    ORDER BY PartitionNumber;
GO

DROP TABLE BINARY_dt_partition;
DROP PARTITION SCHEME BINARY_dt_partition_scheme;
DROP PARTITION FUNCTION BINARY_dt_partition_func;
GO

-- function returns VARBINARY(MAX)
CREATE FUNCTION GenerateRandomVarbinaryMax
(
    @length INT
)
RETURNS VARBINARY(MAX)
AS
BEGIN
    DECLARE @result VARBINARY(MAX) = cast(replicate('a', @length) as varbinary(max));
    return @result;
END;
GO

select dbo.GenerateRandomVarbinaryMax(10), DATALENGTH(GenerateRandomVarbinaryMax(10));
GO

select dbo.GenerateRandomVarbinaryMax(8020), DATALENGTH(GenerateRandomVarbinaryMax(8020));
GO

select probin from pg_proc where proname = lower('GenerateRandomVarbinaryMax')
GO

DROP FUNCTION GenerateRandomVarbinaryMax;
GO

-- function returns VARBINARY(n)
CREATE FUNCTION dbo.GenerateRandomVarbinary
(
    @length INT
)
RETURNS VARBINARY(400)
AS
BEGIN
    DECLARE @result VARBINARY(400) = cast(replicate('a', @length) as varbinary(max));
    return @result;
END;
GO

select dbo.GenerateRandomVarbinary(10), DATALENGTH(GenerateRandomVarbinary(10));
GO

select dbo.GenerateRandomVarbinary(8004), DATALENGTH(GenerateRandomVarbinary(8004));
GO

select probin from pg_proc where proname = lower('GenerateRandomVarbinary')
GO

DROP FUNCTION GenerateRandomVarbinary
GO

-- function that returns binary(400)
CREATE FUNCTION dbo.GenerateRandomBinary
(
    @length INT
)
RETURNS BINARY(400)
AS
BEGIN
    return 0x616161616161
END;
GO

select dbo.GenerateRandomBinary(10), DATALENGTH(GenerateRandomBinary(10));
GO

select dbo.GenerateRandomBinary(8004), DATALENGTH(GenerateRandomBinary(8004));
GO

select probin from pg_proc where proname = lower('GenerateRandomBinary')
GO

DROP FUNCTION dbo.GenerateRandomBinary
GO

-- function that takes varbinary(max) input
CREATE FUNCTION dbo.GetVarbinaryMaxLength
(
    @bin varbinary(max)
)
RETURNS int
AS
BEGIN
    return DATALENGTH(@bin)
END;
GO

select dbo.GetVarbinaryMaxLength(0x616161616161)
GO

select dbo.GetVarbinaryMaxLength(0x)
GO

select dbo.GetVarbinaryMaxLength(cast(replicate('a', 8020) as varbinary(max)))
GO

select probin from pg_proc where proname = lower('GetVarbinaryMaxLength')
GO

DROP FUNCTION dbo.GetVarbinaryMaxLength
GO

-- function that takes varbinary(n) input
CREATE FUNCTION dbo.GetVarbinaryLength
(
    @bin varbinary(400)
)
RETURNS int
AS
BEGIN
    return DATALENGTH(@bin)
END;
GO

select dbo.GetVarbinaryLength(0x616161616161)
GO

select dbo.GetVarbinaryLength(0x)
GO

select dbo.GetVarbinaryLength(cast(replicate('a', 8020) as varbinary(max)))
GO

select probin from pg_proc where proname = lower('GetVarbinaryLength')
GO

DROP FUNCTION dbo.GetVarbinaryLength
GO

-- function that takes binary(n) input
CREATE FUNCTION dbo.GetBinaryLength
(
    @bin binary(400)
)
RETURNS int
AS
BEGIN
    return DATALENGTH(@bin)
END;
GO

select dbo.GetBinaryLength(0x616161616161)
GO

select dbo.GetBinaryLength(0x)
GO

select dbo.GetBinaryLength(cast(replicate('a', 8020) as varbinary(max)))
GO

select probin from pg_proc where proname = lower('GetBinaryLength')
GO

DROP FUNCTION dbo.GetBinaryLength
GO

-- [var]binary as default, check constraints 
CREATE TABLE BINARY_dt(a VARBINARY(10) default 0x61, b VARBINARY(10), c int, check (b > 0x61));
GO

insert into BINARY_dt (b,c) values (0x62, 1);
GO
insert into BINARY_dt (b,c) values (0x60, 2);
GO

select * from BINARY_dt;
GO

DROP TABLE BINARY_dt
GO

CREATE TABLE BINARY_dt(a BINARY(10) default 0x61, b BINARY(10), c int, check (b > 0x61));
GO

insert into BINARY_dt (b,c) values (0x62, 1);
GO
insert into BINARY_dt (b,c) values (0x60, 2);
GO

select * from BINARY_dt;
GO

DROP TABLE BINARY_dt
GO

-- typmod should be in range [1, 8000]
CREATE TABLE BINARY_dt(a varbinary, b binary);
GO

select atttypmod from pg_attribute where attrelid = (select oid from pg_class where relname = 'binary_dt') and attname in ('a', 'b')
GO

DROP TABLE BINARY_dt
GO

CREATE TABLE BINARY_dt(a varbinary(-1), b binary);
GO

CREATE TABLE BINARY_dt(a varbinary, b binary(-1));
GO

CREATE TABLE BINARY_dt(a varbinary(0), b binary);
GO

CREATE TABLE BINARY_dt(a varbinary, b binary(0));
GO

CREATE TABLE BINARY_dt(a varbinary(8800), b binary);
GO

CREATE TABLE BINARY_dt(a varbinary, b binary(8800));
GO

CREATE TABLE BINARY_dt(a varbinary(8000), b binary(8000));
GO

DROP TABLE BINARY_dt
GO

-- check the typmod with cast
select datalength(cast(replicate('a', 30) as varbinary))
GO

select datalength(cast(replicate('a', 30) as binary))
GO

-- ability to use varbinary / binary as part of table variable
DECLARE @BINARY_dt TABLE (
    a BINARY(4),
    b VARBINARY(10),
    c varbinary(max)
);
insert into @BINARY_dt values (0x, 0x, 0x), (NULL, NULL, NULL), (0x41, 0x41, 0x41), (0x41, 0x41, cast(replicate('a', 8020) as varbinary(max)));
select * from @BINARY_dt
GO

-- select into testing
create table BINARY_dt (a varbinary, b varbinary(20), c varbinary(max), d binary, e binary(20))
GO

INSERT INTO BINARY_dt (a, b, c, d, e)
VALUES
(NULL, NULL, NULL, NULL, NULL),
(0x, 0x, 0x, 0x, 0x),
(NULL, 0x, NULL, 0x, NULL),
(0x, NULL, 0x, NULL, 0x),
(0x50, 0x504B030400, 0x504B030400000000, 0x89, 0x89504E470D0A),
(0x0A, 0x0A0B0C0D0E, 0x0A0B0C0D0E0F1011, 0x0A, 0x0A0B0C0D0E),
(0x48, 0x48656C6C6F, 0x48656C6C6F776F726C64, 0x41, 0x48656C6C6F),
(0xC0, 0xC0A801010A, 0xC0A801010A0B0C0D, 0xC0, 0xC0A8010101),
(0x00, 0x0000000000, 0x0000000000000000, 0x00, 0x0000000000),
(0xFF, 0xFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF, 0xFF, 0xFFFFFFFFFF),
(0xAA, 0xAA55AA55AA, 0xAA55AA55AA55AA55, 0xAA, 0xAA55AA55AA),
(0x12, 0x1234ABCDEF, 0x1234ABCDEF567890, 0x12, 0x1234ABCDEF),
(0x0F, 0x0F0F0F0F0F, 0x0F0F0F0F0F0F0F0F, 0x0F, 0x0F0F0F0F0F),
(0xA1, 0xA1B2C3D4E5, 0xA1B2C3D4E5F6F7F8, 0xA1, 0xA1B2C3D4E5)
GO

select * into BINARY_dt_derived from BINARY_dt;
GO

select attname, atttypmod from pg_attribute where attrelid = (select oid from pg_class where relname = 'binary_dt_derived') and attnum > 0
GO

select attname, atttypmod from pg_attribute where attrelid = (select oid from pg_class where relname = 'binary_dt') and attnum > 0
GO

create index idx_binary_dt_a on BINARY_dt(a);
GO

create index idx_binary_dt_bc on BINARY_dt(b, c);
GO

create index idx_binary_dt_d on BINARY_dt(d) include (e);
GO

DROP TABLE BINARY_dt_derived
GO

DROP TABLE BINARY_dt
GO

-- UDF based on varbinary(max)
CREATE TYPE udfvarbinarymax FROM varbinary(max);
GO

CREATE TABLE BINARY_dt(a udfvarbinarymax);
GO

INSERT INTO BINARY_dt(a) values (NULL);
GO
INSERT INTO BINARY_dt(a) values (123456);
GO
INSERT INTO BINARY_dt(a) values (0x);
GO
INSERT INTO BINARY_dt(a) values (' Abc   ');
GO
INSERT INTO BINARY_dt(a) values (cast(replicate(0x41, 8010) as varbinary(max)));
GO

SELECT * FROM BINARY_dt order by a;
GO

select typtypmod, (select typname from pg_type where oid = t.typbasetype) from pg_type t where typname = 'udfvarbinarymax';
GO

DROP TABLE BINARY_dt
GO

DROP TYPE udfvarbinarymax
GO

-- UDF based on varbinary(n)
CREATE TYPE udfvarbinary10 FROM varbinary(10);
GO

CREATE TABLE BINARY_dt(a udfvarbinary10);
GO

INSERT INTO BINARY_dt(a) values (NULL);
GO
INSERT INTO BINARY_dt(a) values (123456);
GO
INSERT INTO BINARY_dt(a) values (0x);
GO
INSERT INTO BINARY_dt(a) values (' Abc   ');
GO
INSERT INTO BINARY_dt(a) values (cast(replicate(0x41, 8010) as varbinary(max)));
GO

SELECT * FROM BINARY_dt order by a;
GO

select typtypmod, (select typname from pg_type where oid = t.typbasetype) from pg_type t where typname = 'udfvarbinary10';
GO

DROP TABLE BINARY_dt
GO

DROP TYPE udfvarbinary10
GO

-- UDF based on binary(n)
CREATE TYPE udfbinary10 FROM binary(10);
GO

CREATE TABLE BINARY_dt(a udfbinary10);
GO

INSERT INTO BINARY_dt(a) values (NULL);
GO
INSERT INTO BINARY_dt(a) values (123456);
GO
INSERT INTO BINARY_dt(a) values (0x);
GO
INSERT INTO BINARY_dt(a) values (' Abc   ');
GO
INSERT INTO BINARY_dt(a) values (cast(replicate(0x41, 8010) as varbinary(max)));
GO

SELECT * FROM BINARY_dt order by a;
GO

select typtypmod, (select typname from pg_type where oid = t.typbasetype) from pg_type t where typname = 'udfbinary10';
GO

DROP TABLE BINARY_dt
GO

DROP TYPE udfbinary10
GO

-- Create a test table
CREATE TABLE BinaryCastingDemo (
    ID INT IDENTITY(1,1),
    Description VARCHAR(100),
    SourceType VARCHAR(50),
    BinaryValue VARBINARY(MAX),
    BinaryFixed BINARY(10),
    BinarySmall VARBINARY(10)
);
GO

-- CHAR and VARCHAR to Binary
INSERT INTO BinaryCastingDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall)
VALUES
    ('Empty string', 'VARCHAR', CAST('' AS VARBINARY(MAX)), CAST('' AS BINARY(10)), CAST('' AS VARBINARY(10))),
    ('NULL value', 'VARCHAR', CAST(NULL AS VARBINARY(MAX)), CAST(NULL AS BINARY(10)), CAST(NULL AS VARBINARY(10))),
    ('Simple text', 'VARCHAR', CAST('Hello' AS VARBINARY(MAX)), CAST('Hello' AS BINARY(10)), CAST('Hello' AS VARBINARY(10))),
    ('Long text', 'VARCHAR', CAST('ThisIsALongText' AS VARBINARY(MAX)), CAST('ThisIsALong' AS BINARY(10)), CAST('ThisIsALong' AS VARBINARY(10)));
GO

-- NCHAR and NVARCHAR to Binary
INSERT INTO BinaryCastingDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall)
VALUES
    ('Unicode text', 'NVARCHAR', CAST(N'Hello文' AS VARBINARY(MAX)), CAST(N'Hello文' AS BINARY(10)), CAST(N'Hello文' AS VARBINARY(10))),
    ('Unicode null', 'NVARCHAR', CAST(NULL AS VARBINARY(MAX)), CAST(NULL AS BINARY(10)), CAST(NULL AS VARBINARY(10)));
GO

-- Direct Binary Input
INSERT INTO BinaryCastingDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall)
VALUES
    ('Hex input', 'image', cast(0x48656C6C6F as image), cast(0x48656C6C6F as image), cast(0x48656C6C6F as image)),
    ('Empty binary', 'image', cast(0x as image), cast(0x as image), cast(0x as image));
GO

-- Query results
SELECT 
    ID,
    Description,
    SourceType,
    BinaryValue,
    BinaryFixed,
    BinarySmall,
    DATALENGTH(BinaryValue) AS BinaryValueLength,
    DATALENGTH(BinaryFixed) AS BinaryFixedLength,
    DATALENGTH(BinarySmall) AS BinarySmallLength
FROM BinaryCastingDemo;
GO

-- Cleanup
DROP TABLE BinaryCastingDemo;
GO

-- Create test table
CREATE TABLE DateTimeToBinaryDemo (
    ID INT IDENTITY(1,1),
    Description VARCHAR(100),
    SourceType VARCHAR(50),
    BinaryValue VARBINARY(MAX),
    BinaryFixed BINARY(10),
    BinarySmall VARBINARY(8),
    OriginalValue VARCHAR(50)
);
GO

-- DATETIME conversions
INSERT INTO DateTimeToBinaryDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall, OriginalValue)
VALUES
    ('DateTime Regular', 'DATETIME', 
    CAST('2024-01-15 14:30:00' AS VARBINARY(MAX)), 
    CAST('2024-01-15 14:30:00' AS BINARY(10)), 
    CAST('2024-01-15 14:30:00' AS VARBINARY(8)),
    '2024-01-15 14:30:00'),

    ('DateTime NULL', 'DATETIME', 
    CAST(NULL AS VARBINARY(MAX)), 
    CAST(NULL AS BINARY(10)), 
    CAST(NULL AS VARBINARY(8)),
    'NULL'),

    ('DateTime Min', 'DATETIME', 
    CAST('1753-01-01 00:00:00' AS VARBINARY(MAX)), 
    CAST('1753-01-01 00:00:00' AS BINARY(10)), 
    CAST('1753-01-01 00:00:00' AS VARBINARY(8)),
    '1753-01-01 00:00:00'),

    ('DateTime Max', 'DATETIME', 
    CAST('9999-12-31 23:59:59.997' AS VARBINARY(MAX)), 
    CAST('9999-12-31 23:59:59.997' AS BINARY(10)), 
    CAST('9999-12-31 23:59:59.997' AS VARBINARY(8)),
    '9999-12-31 23:59:59.997');
GO

-- SMALLDATETIME conversions
INSERT INTO DateTimeToBinaryDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall, OriginalValue)
VALUES
    ('SmallDateTime Regular', 'SMALLDATETIME', 
    CAST('2024-01-15 14:30:00' AS VARBINARY(MAX)), 
    CAST('2024-01-15 14:30:00' AS BINARY(10)), 
    CAST('2024-01-15 14:30:00' AS VARBINARY(8)),
    '2024-01-15 14:30:00'),

    ('SmallDateTime Min', 'SMALLDATETIME', 
    CAST('1900-01-01 00:00:00' AS VARBINARY(MAX)), 
    CAST('1900-01-01 00:00:00' AS BINARY(10)), 
    CAST('1900-01-01 00:00:00' AS VARBINARY(8)),
    '1900-01-01 00:00:00');
GO

-- DATE conversions
INSERT INTO DateTimeToBinaryDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall, OriginalValue)
VALUES
    ('Date Regular', 'DATE', 
    CAST('2024-01-15' AS VARBINARY(MAX)), 
    CAST('2024-01-15' AS BINARY(10)), 
    CAST('2024-01-15' AS VARBINARY(8)),
    '2024-01-15'),

    ('Date Min', 'DATE', 
    CAST('0001-01-01' AS VARBINARY(MAX)), 
    CAST('0001-01-01' AS BINARY(10)), 
    CAST('0001-01-01' AS VARBINARY(8)),
    '0001-01-01');
GO

-- TIME conversions
INSERT INTO DateTimeToBinaryDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall, OriginalValue)
VALUES
    ('Time Regular', 'TIME', 
    CAST('14:30:00' AS VARBINARY(MAX)), 
    CAST('14:30:00' AS BINARY(10)), 
    CAST('14:30:00' AS VARBINARY(8)),
    '14:30:00'),

    ('Time With Milliseconds', 'TIME', 
    CAST('14:30:00.1234567' AS VARBINARY(MAX)), 
    CAST('14:30:00.1234567' AS BINARY(10)), 
    CAST('14:30:00.1234567' AS VARBINARY(8)),
    '14:30:00.1234567');
GO

-- DATETIMEOFFSET conversions
INSERT INTO DateTimeToBinaryDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall, OriginalValue)
VALUES
    ('DateTimeOffset Regular', 'DATETIMEOFFSET', 
    CAST('2024-01-15 14:30:00 +00:00' AS VARBINARY(MAX)), 
    CAST('2024-01-15 14:30:00 +00:00' AS BINARY(10)), 
    CAST('2024-01-15 14:30:00 +00:00' AS VARBINARY(8)),
    '2024-01-15 14:30:00 +00:00'),

    ('DateTimeOffset With TZ', 'DATETIMEOFFSET', 
    CAST('2024-01-15 14:30:00 -08:00' AS VARBINARY(MAX)), 
    CAST('2024-01-15 14:30:00 -08:00' AS BINARY(10)), 
    CAST('2024-01-15 14:30:00 -08:00' AS VARBINARY(8)),
    '2024-01-15 14:30:00 -08:00');
GO

-- DATETIME2 conversions
INSERT INTO DateTimeToBinaryDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall, OriginalValue)
VALUES
    ('DateTime2 Regular', 'DATETIME2', 
    CAST('2024-01-15 14:30:00' AS VARBINARY(MAX)), 
    CAST('2024-01-15 14:30:00' AS BINARY(10)), 
    CAST('2024-01-15 14:30:00' AS VARBINARY(8)),
    '2024-01-15 14:30:00'),

    ('DateTime2 With Precision', 'DATETIME2', 
    CAST('2024-01-15 14:30:00.1234567' AS VARBINARY(MAX)), 
    CAST('2024-01-15 14:30:00.1234567' AS BINARY(10)), 
    CAST('2024-01-15 14:30:00.1234567' AS VARBINARY(8)),
    '2024-01-15 14:30:00.1234567');
GO

-- Query results
SELECT 
    ID,
    Description,
    SourceType,
    BinaryValue,
    CONVERT(VARCHAR(100), BinaryValue, 1) AS BinaryValueHex,
    BinaryFixed,
    CONVERT(VARCHAR(100), BinaryFixed, 1) AS BinaryFixedHex,
    BinarySmall,
    CONVERT(VARCHAR(100), BinarySmall, 1) AS BinarySmallHex,
    OriginalValue,
    DATALENGTH(BinaryValue) AS BinaryValueLength,
    DATALENGTH(BinaryFixed) AS BinaryFixedLength,
    DATALENGTH(BinarySmall) AS BinarySmallLength
FROM DateTimeToBinaryDemo
ORDER BY ID;
GO

-- Cleanup
DROP TABLE DateTimeToBinaryDemo;
GO

-- Create test table
CREATE TABLE NumericToBinaryDemo (
    ID INT IDENTITY(1,1),
    Description VARCHAR(100),
    SourceType VARCHAR(50),
    BinaryValue VARBINARY(MAX),
    BinaryFixed BINARY(10),
    BinarySmall VARBINARY(8),
    OriginalValue VARCHAR(50)
);
GO

-- DECIMAL/NUMERIC conversions
INSERT INTO NumericToBinaryDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall, OriginalValue)
VALUES
    ('Decimal Regular', 'DECIMAL(18,2)', 
    CAST(123456.78 AS VARBINARY(MAX)), 
    CAST(123456.78 AS BINARY(10)), 
    CAST(123456.78 AS VARBINARY(8)),
    cast('123456.78' as DECIMAL(18,2))),

    ('Decimal Zero', 'DECIMAL(18,2)', 
    CAST(0.00 AS VARBINARY(MAX)), 
    CAST(0.00 AS BINARY(10)), 
    CAST(0.00 AS VARBINARY(8)),
    cast('0.00' as DECIMAL(18,2))),

    ('Decimal NULL', 'DECIMAL(18,2)', 
    CAST(NULL AS VARBINARY(MAX)), 
    CAST(NULL AS BINARY(10)), 
    CAST(NULL AS VARBINARY(8)),
    cast('NULL' as DECIMAL(18,2))),

    ('Decimal Large', 'DECIMAL(18,2)', 
    CAST(999999999999.99 AS VARBINARY(MAX)), 
    CAST(999999999999.99 AS BINARY(10)), 
    CAST(999999999999.99 AS VARBINARY(8)),
    cast('999999999999.99' as DECIMAL(18,2))),

    ('Decimal Regular', 'NUMERIC(18,2)', 
    CAST(123456.78 AS VARBINARY(MAX)), 
    CAST(123456.78 AS BINARY(10)), 
    CAST(123456.78 AS VARBINARY(8)),
    cast('123456.78' as NUMERIC(18,2))),

    ('Decimal Zero', 'NUMERIC(18,2)', 
    CAST(0.00 AS VARBINARY(MAX)), 
    CAST(0.00 AS BINARY(10)), 
    CAST(0.00 AS VARBINARY(8)),
    cast('0.00' as NUMERIC(18,2))),

    ('Decimal NULL', 'NUMERIC(18,2)', 
    CAST(NULL AS VARBINARY(MAX)), 
    CAST(NULL AS BINARY(10)), 
    CAST(NULL AS VARBINARY(8)),
    cast('NULL' as NUMERIC(18,2))),

    ('Decimal Large', 'NUMERIC(18,2)', 
    CAST(999999999999.99 AS VARBINARY(MAX)), 
    CAST(999999999999.99 AS BINARY(10)), 
    CAST(999999999999.99 AS VARBINARY(8)),
    cast('999999999999.99' as NUMERIC(18,2)));
GO

-- FLOAT/REAL conversions
INSERT INTO NumericToBinaryDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall, OriginalValue)
VALUES
    ('Float Regular', 'FLOAT', 
    CAST(CAST(123.456 AS FLOAT) AS VARBINARY(MAX)), 
    CAST(CAST(123.456 AS FLOAT) AS BINARY(10)), 
    CAST(CAST(123.456 AS FLOAT) AS VARBINARY(8)),
    '123.456'),

    ('Real Regular', 'REAL', 
    CAST(CAST(123.456 AS REAL) AS VARBINARY(MAX)), 
    CAST(CAST(123.456 AS REAL) AS BINARY(10)), 
    CAST(CAST(123.456 AS REAL) AS VARBINARY(8)),
    '123.456'),

    ('Float Scientific', 'FLOAT', 
    CAST(CAST(1.23456E+10 AS FLOAT) AS VARBINARY(MAX)), 
    CAST(CAST(1.23456E+10 AS FLOAT) AS BINARY(10)), 
    CAST(CAST(1.23456E+10 AS FLOAT) AS VARBINARY(8)),
    '1.23456E+10');
GO

-- Integer types conversions
INSERT INTO NumericToBinaryDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall, OriginalValue)
VALUES
    ('BigInt Max', 'BIGINT', 
    CAST(9223372036854775807 AS VARBINARY(MAX)), 
    CAST(9223372036854775807 AS BINARY(10)), 
    CAST(9223372036854775807 AS VARBINARY(8)),
    '9223372036854775807'),

    ('Int Regular', 'INT', 
    CAST(2147483647 AS VARBINARY(MAX)), 
    CAST(2147483647 AS BINARY(10)), 
    CAST(2147483647 AS VARBINARY(8)),
    '2147483647'),

    ('SmallInt Regular', 'SMALLINT', 
    CAST(32767 AS VARBINARY(MAX)), 
    CAST(32767 AS BINARY(10)), 
    CAST(32767 AS VARBINARY(8)),
    '32767'),

    ('TinyInt Regular', 'TINYINT', 
    CAST(255 AS VARBINARY(MAX)), 
    CAST(255 AS BINARY(10)), 
    CAST(255 AS VARBINARY(8)),
    '255'),

    ('Integer Zero', 'INT', 
    CAST(0 AS VARBINARY(MAX)), 
    CAST(0 AS BINARY(10)), 
    CAST(0 AS VARBINARY(8)),
    '0'),

    ('Integer Negative', 'INT', 
    CAST(-12345 AS VARBINARY(MAX)), 
    CAST(-12345 AS BINARY(10)), 
    CAST(-12345 AS VARBINARY(8)),
    '-12345');
GO

-- MONEY/SMALLMONEY conversions
INSERT INTO NumericToBinaryDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall, OriginalValue)
VALUES
    ('Money Regular', 'MONEY', 
    CAST(CAST(123456.78 AS MONEY) AS VARBINARY(MAX)), 
    CAST(CAST(123456.78 AS MONEY) AS BINARY(10)), 
    CAST(CAST(123456.78 AS MONEY) AS VARBINARY(8)),
    '$123456.78'),

    ('Money Regular', 'MONEY', 
    CAST(CAST($123456.78 AS MONEY) AS VARBINARY(MAX)), 
    CAST(CAST($123456.78 AS MONEY) AS BINARY(10)), 
    CAST(CAST($123456.78 AS MONEY) AS VARBINARY(8)),
    '$123456.78'),

    ('SmallMoney Regular', 'SMALLMONEY', 
    CAST(CAST(123456.78 AS SMALLMONEY) AS VARBINARY(MAX)), 
    CAST(CAST(123456.78 AS SMALLMONEY) AS BINARY(10)), 
    CAST(CAST(123456.78 AS SMALLMONEY) AS VARBINARY(8)),
    '$123456.78'),

    ('SmallMoney Regular', 'SMALLMONEY', 
    CAST(CAST($123456.78 AS SMALLMONEY) AS VARBINARY(MAX)), 
    CAST(CAST($123456.78 AS SMALLMONEY) AS BINARY(10)), 
    CAST(CAST($123456.78 AS SMALLMONEY) AS VARBINARY(8)),
    '$123456.78'),

    ('Money Zero', 'MONEY', 
    CAST(CAST(0.00 AS MONEY) AS VARBINARY(MAX)), 
    CAST(CAST(0.00 AS MONEY) AS BINARY(10)), 
    CAST(CAST(0.00 AS MONEY) AS VARBINARY(8)),
    '$0.00'),

    ('Money Negative', 'MONEY', 
    CAST(CAST(-123456.78 AS MONEY) AS VARBINARY(MAX)), 
    CAST(CAST(-123456.78 AS MONEY) AS BINARY(10)), 
    CAST(CAST(-123456.78 AS MONEY) AS VARBINARY(8)),
    '-$123456.78');
GO

-- Query results
SELECT *
FROM NumericToBinaryDemo
ORDER BY ID;
GO

-- Cleanup
DROP TABLE NumericToBinaryDemo;
GO

-- Create test table
CREATE TABLE SpecialTypesBinaryDemo (
    ID INT IDENTITY(1,1),
    Description VARCHAR(100),
    SourceType VARCHAR(50),
    BinaryValue VARBINARY(MAX),
    BinaryFixed BINARY(10),
    BinarySmall VARBINARY(8),
    OriginalValue VARCHAR(MAX)
);
GO

-- BIT conversions
INSERT INTO SpecialTypesBinaryDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall, OriginalValue)
VALUES
    ('Bit True', 'BIT', 
    CAST(cast(1 as bit) AS VARBINARY(MAX)), 
    CAST(cast(1 as bit) AS BINARY(10)), 
    CAST(cast(1 as bit) AS VARBINARY(8)),
    '1'),

    ('Bit False', 'BIT', 
    CAST(cast(0 as bit) AS VARBINARY(MAX)), 
    CAST(cast(0 as bit) AS BINARY(10)), 
    CAST(cast(0 as bit) AS VARBINARY(8)),
    '0'),

    ('Bit NULL', 'BIT', 
    CAST(cast(NULL as bit) AS VARBINARY(MAX)), 
    CAST(cast(NULL as bit) AS BINARY(10)), 
    CAST(cast(NULL as bit) AS VARBINARY(8)),
    'NULL');
GO

-- UNIQUEIDENTIFIER conversions
INSERT INTO SpecialTypesBinaryDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall, OriginalValue)
VALUES
    ('GUID Regular', 'UNIQUEIDENTIFIER', 
    CAST('12345678-1234-1234-1234-123456789012' AS VARBINARY(MAX)), 
    CAST('12345678-1234-1234-1234-123456789012' AS BINARY(10)), 
    CAST('12345678-1234-1234-1234-123456789012' AS VARBINARY(8)),
    '12345678-1234-1234-1234-123456789012'),

    ('GUID NULL', 'UNIQUEIDENTIFIER', 
    CAST(NULL AS VARBINARY(MAX)), 
    CAST(NULL AS BINARY(10)), 
    CAST(NULL AS VARBINARY(8)),
    'NULL'),

    ('GUID Zero', 'UNIQUEIDENTIFIER', 
    CAST('00000000-0000-0000-0000-000000000000' AS VARBINARY(MAX)), 
    CAST('00000000-0000-0000-0000-000000000000' AS BINARY(10)), 
    CAST('00000000-0000-0000-0000-000000000000' AS VARBINARY(8)),
    '00000000-0000-0000-0000-000000000000');
GO

-- SQL_VARIANT conversions
INSERT INTO SpecialTypesBinaryDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall, OriginalValue)
VALUES
    ('SQL_VARIANT with INT', 'SQL_VARIANT', 
    CAST(CAST(12345 AS SQL_VARIANT) AS VARBINARY(MAX)), 
    CAST(CAST(12345 AS SQL_VARIANT) AS BINARY(10)), 
    CAST(CAST(12345 AS SQL_VARIANT) AS VARBINARY(8)),
    '12345'),

    ('SQL_VARIANT with VARCHAR', 'SQL_VARIANT', 
    CAST(CAST('Test String' AS SQL_VARIANT) AS VARBINARY(MAX)), 
    CAST(CAST('Test String' AS SQL_VARIANT) AS BINARY(10)), 
    CAST(CAST('Test String' AS SQL_VARIANT) AS VARBINARY(8)),
    'Test String'),

    ('SQL_VARIANT NULL', 'SQL_VARIANT', 
    CAST(CAST(NULL AS SQL_VARIANT) AS VARBINARY(MAX)), 
    CAST(CAST(NULL AS SQL_VARIANT) AS BINARY(10)), 
    CAST(CAST(NULL AS SQL_VARIANT) AS VARBINARY(8)),
    'NULL');
GO

-- XML conversions
DECLARE @xml XML = '<root><item>Test XML Data</item></root>';
DECLARE @xmlLarge XML = '<root>' + REPLICATE('<item>Large XML Data</item>', 10) + '</root>';

INSERT INTO SpecialTypesBinaryDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall, OriginalValue)
VALUES
    ('XML Simple', 'XML', 
    CAST(@xml AS VARBINARY(MAX)), 
    CAST(@xml AS BINARY(10)), 
    CAST(@xml AS VARBINARY(8)),
    CAST(@xml AS NVARCHAR(MAX))),

    ('XML Large', 'XML', 
    CAST(@xmlLarge AS VARBINARY(MAX)), 
    CAST(@xmlLarge AS BINARY(10)), 
    CAST(@xmlLarge AS VARBINARY(8)),
    CAST(@xmlLarge AS NVARCHAR(MAX))),

    ('XML NULL', 'XML', 
    CAST(CAST(NULL AS XML) AS VARBINARY(MAX)), 
    CAST(CAST(NULL AS XML) AS BINARY(10)), 
    CAST(CAST(NULL AS XML) AS VARBINARY(8)),
    'NULL');
GO

-- JSON conversions (note: JSON is stored as NVARCHAR)
DECLARE @json NVARCHAR(MAX) = N'{"id": 1, "name": "Test JSON"}';
DECLARE @jsonLarge NVARCHAR(MAX) = N'{"items": [' + 
    REPLICATE('{"id": 1, "value": "Large JSON Data"},', 10) + 
    '{"id": 2, "value": "Last Item"}]}';

INSERT INTO SpecialTypesBinaryDemo (Description, SourceType, BinaryValue, BinaryFixed, BinarySmall, OriginalValue)
VALUES
    ('JSON Simple', 'JSON', 
    CAST(@json AS VARBINARY(MAX)), 
    CAST(@json AS BINARY(10)), 
    CAST(@json AS VARBINARY(8)),
    @json),

    ('JSON Large', 'JSON', 
    CAST(@jsonLarge AS VARBINARY(MAX)), 
    CAST(@jsonLarge AS BINARY(10)), 
    CAST(@jsonLarge AS VARBINARY(8)),
    @jsonLarge),

    ('JSON NULL', 'JSON', 
    CAST(NULL AS VARBINARY(MAX)), 
    CAST(NULL AS BINARY(10)), 
    CAST(NULL AS VARBINARY(8)),
    'NULL');
GO

-- Query results
SELECT *
FROM SpecialTypesBinaryDemo
ORDER BY ID;

-- Cleanup
DROP TABLE SpecialTypesBinaryDemo;
GO

-- Create table to store test results
CREATE TABLE BinaryOperatorTests (
    TestID INT IDENTITY(1,1),
    TestDescription VARCHAR(100),
    LeftOperand VARBINARY(100),
    RightOperand VARBINARY(100),
    EqualResult BIT,
    NotEqualResult BIT,
    GreaterThanResult BIT,
    LessThanResult BIT,
    GreaterEqualResult BIT,
    LessEqualResult BIT
);
GO

-- Test Case 1: Simple binary values
DECLARE @bin1 VARBINARY(10) = 0x0A;
DECLARE @bin2 VARBINARY(10) = 0x0B;

INSERT INTO BinaryOperatorTests (
    TestDescription, 
    LeftOperand, 
    RightOperand,
    EqualResult,
    NotEqualResult,
    GreaterThanResult,
    LessThanResult,
    GreaterEqualResult,
    LessEqualResult
)
SELECT 
    'Simple Binary Compare (0x0A vs 0x0B)',
    @bin1,
    @bin2,
    CASE WHEN @bin1 = @bin2 THEN 1 ELSE 0 END,
    CASE WHEN @bin1 <> @bin2 THEN 1 ELSE 0 END,
    CASE WHEN @bin1 > @bin2 THEN 1 ELSE 0 END,
    CASE WHEN @bin1 < @bin2 THEN 1 ELSE 0 END,
    CASE WHEN @bin1 >= @bin2 THEN 1 ELSE 0 END,
    CASE WHEN @bin1 <= @bin2 THEN 1 ELSE 0 END;
GO

-- Test Case 2: Equal values
DECLARE @bin3 VARBINARY(10) = 0x0A;
DECLARE @bin4 VARBINARY(10) = 0x0A;

INSERT INTO BinaryOperatorTests (
    TestDescription, 
    LeftOperand, 
    RightOperand,
    EqualResult,
    NotEqualResult,
    GreaterThanResult,
    LessThanResult,
    GreaterEqualResult,
    LessEqualResult
)
SELECT 
    'Equal Binary Values (0x0A vs 0x0A)',
    @bin3,
    @bin4,
    CASE WHEN @bin3 = @bin4 THEN 1 ELSE 0 END,
    CASE WHEN @bin3 <> @bin4 THEN 1 ELSE 0 END,
    CASE WHEN @bin3 > @bin4 THEN 1 ELSE 0 END,
    CASE WHEN @bin3 < @bin4 THEN 1 ELSE 0 END,
    CASE WHEN @bin3 >= @bin4 THEN 1 ELSE 0 END,
    CASE WHEN @bin3 <= @bin4 THEN 1 ELSE 0 END;
GO

-- Test Case 3: Different lengths
DECLARE @bin5 VARBINARY(10) = 0x0A0B;
DECLARE @bin6 VARBINARY(10) = 0x0A;

INSERT INTO BinaryOperatorTests (
    TestDescription, 
    LeftOperand, 
    RightOperand,
    EqualResult,
    NotEqualResult,
    GreaterThanResult,
    LessThanResult,
    GreaterEqualResult,
    LessEqualResult
)
SELECT 
    'Different Lengths (0x0A0B vs 0x0A)',
    @bin5,
    @bin6,
    CASE WHEN @bin5 = @bin6 THEN 1 ELSE 0 END,
    CASE WHEN @bin5 <> @bin6 THEN 1 ELSE 0 END,
    CASE WHEN @bin5 > @bin6 THEN 1 ELSE 0 END,
    CASE WHEN @bin5 < @bin6 THEN 1 ELSE 0 END,
    CASE WHEN @bin5 >= @bin6 THEN 1 ELSE 0 END,
    CASE WHEN @bin5 <= @bin6 THEN 1 ELSE 0 END;
GO

-- Test Case 4: Zero and non-zero
DECLARE @bin7 VARBINARY(10) = 0x00;
DECLARE @bin8 VARBINARY(10) = 0x01;

INSERT INTO BinaryOperatorTests (
    TestDescription, 
    LeftOperand, 
    RightOperand,
    EqualResult,
    NotEqualResult,
    GreaterThanResult,
    LessThanResult,
    GreaterEqualResult,
    LessEqualResult
)
SELECT 
    'Zero vs Non-Zero (0x00 vs 0x01)',
    @bin7,
    @bin8,
    CASE WHEN @bin7 = @bin8 THEN 1 ELSE 0 END,
    CASE WHEN @bin7 <> @bin8 THEN 1 ELSE 0 END,
    CASE WHEN @bin7 > @bin8 THEN 1 ELSE 0 END,
    CASE WHEN @bin7 < @bin8 THEN 1 ELSE 0 END,
    CASE WHEN @bin7 >= @bin8 THEN 1 ELSE 0 END,
    CASE WHEN @bin7 <= @bin8 THEN 1 ELSE 0 END;
GO

-- Test Case 5: NULL comparison
DECLARE @bin9 VARBINARY(10) = 0x0A;
DECLARE @bin10 VARBINARY(10) = NULL;

INSERT INTO BinaryOperatorTests (
    TestDescription, 
    LeftOperand, 
    RightOperand,
    EqualResult,
    NotEqualResult,
    GreaterThanResult,
    LessThanResult,
    GreaterEqualResult,
    LessEqualResult
)
SELECT 
    'NULL Comparison (0x0A vs NULL)',
    @bin9,
    @bin10,
    CASE WHEN @bin9 = @bin10 THEN 1 WHEN @bin9 <> @bin10 THEN 0 ELSE NULL END,
    CASE WHEN @bin9 <> @bin10 THEN 1 WHEN @bin9 = @bin10 THEN 0 ELSE NULL END,
    CASE WHEN @bin9 > @bin10 THEN 1 WHEN @bin9 <= @bin10 THEN 0 ELSE NULL END,
    CASE WHEN @bin9 < @bin10 THEN 1 WHEN @bin9 >= @bin10 THEN 0 ELSE NULL END,
    CASE WHEN @bin9 >= @bin10 THEN 1 WHEN @bin9 < @bin10 THEN 0 ELSE NULL END,
    CASE WHEN @bin9 <= @bin10 THEN 1 WHEN @bin9 > @bin10 THEN 0 ELSE NULL END;
GO

-- Test Case 6: Larger values
DECLARE @bin11 VARBINARY(10) = 0xFFFF;
DECLARE @bin12 VARBINARY(10) = 0x0001;

INSERT INTO BinaryOperatorTests (
    TestDescription, 
    LeftOperand, 
    RightOperand,
    EqualResult,
    NotEqualResult,
    GreaterThanResult,
    LessThanResult,
    GreaterEqualResult,
    LessEqualResult
)
SELECT 
    'Large Value Compare (0xFFFF vs 0x0001)',
    @bin11,
    @bin12,
    CASE WHEN @bin11 = @bin12 THEN 1 ELSE 0 END,
    CASE WHEN @bin11 <> @bin12 THEN 1 ELSE 0 END,
    CASE WHEN @bin11 > @bin12 THEN 1 ELSE 0 END,
    CASE WHEN @bin11 < @bin12 THEN 1 ELSE 0 END,
    CASE WHEN @bin11 >= @bin12 THEN 1 ELSE 0 END,
    CASE WHEN @bin11 <= @bin12 THEN 1 ELSE 0 END;
GO

-- Display results
SELECT 
    TestID,
    TestDescription,
    LeftOperand,
    RightOperand,
    CASE WHEN EqualResult = 1 THEN 'True' 
         WHEN EqualResult = 0 THEN 'False' 
         ELSE 'NULL' END AS Equal,
    CASE WHEN NotEqualResult = 1 THEN 'True' 
         WHEN NotEqualResult = 0 THEN 'False' 
         ELSE 'NULL' END AS NotEqual,
    CASE WHEN GreaterThanResult = 1 THEN 'True' 
         WHEN GreaterThanResult = 0 THEN 'False' 
         ELSE 'NULL' END AS GreaterThan,
    CASE WHEN LessThanResult = 1 THEN 'True' 
         WHEN LessThanResult = 0 THEN 'False' 
         ELSE 'NULL' END AS LessThan,
    CASE WHEN GreaterEqualResult = 1 THEN 'True' 
         WHEN GreaterEqualResult = 0 THEN 'False' 
         ELSE 'NULL' END AS GreaterEqual,
    CASE WHEN LessEqualResult = 1 THEN 'True' 
         WHEN LessEqualResult = 0 THEN 'False' 
         ELSE 'NULL' END AS LessEqual
FROM BinaryOperatorTests
ORDER BY TestID;
GO

-- Direct comparison examples
SELECT 'Direct Comparisons' AS TestType;
GO

SELECT 'Compare 0x0A = 0x0A' AS Test, 
    CASE WHEN 0x0A = 0x0A THEN 'True' ELSE 'False' END AS Result;
GO

SELECT 'Compare 0x0A > 0x0B' AS Test, 
    CASE WHEN 0x0A > 0x0B THEN 'True' ELSE 'False' END AS Result;
GO

SELECT 'Compare 0x0A < 0x0B' AS Test, 
    CASE WHEN 0x0A < 0x0B THEN 'True' ELSE 'False' END AS Result;
GO

SELECT 'Compare 0xFFFF > 0x0001' AS Test, 
    CASE WHEN 0xFFFF > 0x0001 THEN 'True' ELSE 'False' END AS Result;
GO

-- Cleanup
DROP TABLE BinaryOperatorTests;
GO

-- Create test table
CREATE TABLE BinaryMixedTypeComparisons (
    TestID INT IDENTITY(1,1),
    TestDescription VARCHAR(100),
    BinaryValue VARBINARY(100),
    OtherValue SQL_VARIANT,
    OtherValueType VARCHAR(50),
    EqualResult VARCHAR(10),
    NotEqualResult VARCHAR(10),
    GreaterThanResult VARCHAR(10),
    LessThanResult VARCHAR(10)
);
GO

-- String comparisons
INSERT INTO BinaryMixedTypeComparisons
SELECT 
    'Binary vs VARCHAR', 
    CAST('Test' AS VARBINARY(100)),
    CAST('Test' AS VARCHAR(100)),
    'VARCHAR',
    CASE WHEN CAST('Test' AS VARBINARY(100)) = CAST('Test' AS VARBINARY(100)) THEN 'True' ELSE 'False' END,
    CASE WHEN CAST('Test' AS VARBINARY(100)) <> CAST('Test' AS VARBINARY(100)) THEN 'True' ELSE 'False' END,
    CASE WHEN CAST('Test' AS VARBINARY(100)) > CAST('Test' AS VARBINARY(100)) THEN 'True' ELSE 'False' END,
    CASE WHEN CAST('Test' AS VARBINARY(100)) < CAST('Test' AS VARBINARY(100)) THEN 'True' ELSE 'False' END;
GO

-- Integer comparisons
INSERT INTO BinaryMixedTypeComparisons
SELECT 
    'Binary vs INTEGER', 
    CAST(12345 AS VARBINARY(100)),
    12345,
    'INTEGER',
    CASE WHEN CAST(12345 AS VARBINARY(100)) = CAST(12345 AS VARBINARY(100)) THEN 'True' ELSE 'False' END,
    CASE WHEN CAST(12345 AS VARBINARY(100)) <> CAST(12345 AS VARBINARY(100)) THEN 'True' ELSE 'False' END,
    CASE WHEN CAST(12345 AS VARBINARY(100)) > CAST(12345 AS VARBINARY(100)) THEN 'True' ELSE 'False' END,
    CASE WHEN CAST(12345 AS VARBINARY(100)) < CAST(12345 AS VARBINARY(100)) THEN 'True' ELSE 'False' END;
GO

-- Date comparisons
INSERT INTO BinaryMixedTypeComparisons
SELECT 
    'Binary vs DATE', 
    CAST('2024-01-15' AS VARBINARY(100)),
    CAST('2024-01-15' AS DATE),
    'DATE',
    CASE WHEN CAST('2024-01-15' AS VARBINARY(100)) = CAST(CAST('2024-01-15' AS DATE) AS VARBINARY(100)) THEN 'True' ELSE 'False' END,
    CASE WHEN CAST('2024-01-15' AS VARBINARY(100)) <> CAST(CAST('2024-01-15' AS DATE) AS VARBINARY(100)) THEN 'True' ELSE 'False' END,
    CASE WHEN CAST('2024-01-15' AS VARBINARY(100)) > CAST(CAST('2024-01-15' AS DATE) AS VARBINARY(100)) THEN 'True' ELSE 'False' END,
    CASE WHEN CAST('2024-01-15' AS VARBINARY(100)) < CAST(CAST('2024-01-15' AS DATE) AS VARBINARY(100)) THEN 'True' ELSE 'False' END;
GO

-- Direct comparison examples
SELECT 'Direct Comparisons' AS TestType;
GO

-- Binary vs String
SELECT 'Binary = String' AS Test,
CASE WHEN CAST('Test' AS VARBINARY(100)) = CAST('Test' AS VARCHAR(100)) THEN 'True' ELSE 'False' END AS Result
UNION ALL
SELECT 'Binary > String',
CASE WHEN CAST('Test2' AS VARBINARY(100)) > CAST('Test1' AS VARCHAR(100)) THEN 'True' ELSE 'False' END
UNION ALL
SELECT 'Binary < String',
CASE WHEN CAST('Test1' AS VARBINARY(100)) < CAST('Test2' AS VARCHAR(100)) THEN 'True' ELSE 'False' END
ORDER BY Test;
GO

-- Binary vs Integer
SELECT 'Binary vs Integer Comparisons' AS TestType;
DECLARE @binInt VARBINARY(100) = CAST(100 AS VARBINARY(100));
DECLARE @regularInt INT = 100;

SELECT 'Binary = Integer' AS Test,
CASE WHEN @binInt = CAST(@regularInt AS VARBINARY(100)) THEN 'True' ELSE 'False' END AS Result
UNION ALL
SELECT 'Binary > Integer',
CASE WHEN @binInt > CAST(@regularInt-1 AS VARBINARY(100)) THEN 'True' ELSE 'False' END
UNION ALL
SELECT 'Binary < Integer',
CASE WHEN @binInt < CAST(@regularInt+1 AS VARBINARY(100)) THEN 'True' ELSE 'False' END
ORDER BY Test;
GO

-- Binary vs DateTime
SELECT 'Binary vs DateTime Comparisons' AS TestType;
DECLARE @binDate VARBINARY(100) = CAST('2024-01-15' AS VARBINARY(100));
DECLARE @regularDate DATETIME = '2024-01-15';

SELECT 'Binary = DateTime' AS Test,
CASE WHEN @binDate = CAST(@regularDate AS VARBINARY(100)) THEN 'True' ELSE 'False' END AS Result
UNION ALL
SELECT 'Binary > Earlier DateTime',
CASE WHEN @binDate > CAST('2024-01-14' AS VARBINARY(100)) THEN 'True' ELSE 'False' END
UNION ALL
SELECT 'Binary < Later DateTime',
CASE WHEN @binDate < CAST('2024-01-16' AS VARBINARY(100)) THEN 'True' ELSE 'False' END
ORDER BY Test;
GO

-- Binary vs Decimal
SELECT 'Binary vs Decimal Comparisons' AS TestType;
DECLARE @binDecimal VARBINARY(100) = CAST(123.45 AS VARBINARY(100));
DECLARE @regularDecimal DECIMAL(10,2) = 123.45;

SELECT 'Binary = Decimal' AS Test,
CASE WHEN @binDecimal = CAST(@regularDecimal AS VARBINARY(100)) THEN 'True' ELSE 'False' END AS Result
UNION ALL
SELECT 'Binary > Smaller Decimal',
CASE WHEN @binDecimal > CAST(123.44 AS VARBINARY(100)) THEN 'True' ELSE 'False' END
UNION ALL
SELECT 'Binary < Larger Decimal',
CASE WHEN @binDecimal < CAST(123.46 AS VARBINARY(100)) THEN 'True' ELSE 'False' END
ORDER BY Test;
GO

-- Binary vs UNIQUEIDENTIFIER
SELECT 'Binary vs UNIQUEIDENTIFIER Comparisons' AS TestType;
DECLARE @binGuid VARBINARY(100) = CAST('12345678-1234-1234-1234-123456789012' AS VARBINARY(100));
DECLARE @regularGuid UNIQUEIDENTIFIER = '12345678-1234-1234-1234-123456789012';

SELECT 'Binary = GUID' AS Test,
CASE WHEN @binGuid = CAST(@regularGuid AS VARBINARY(100)) THEN 'True' ELSE 'False' END AS Result;
GO

-- Binary vs BIT
SELECT 'Binary vs BIT Comparisons' AS TestType;
DECLARE @binBit VARBINARY(100) = CAST(1 AS VARBINARY(100));
DECLARE @regularBit BIT = 1;

SELECT 'Binary = Bit' AS Test,
CASE WHEN @binBit = CAST(@regularBit AS VARBINARY(100)) THEN 'True' ELSE 'False' END AS Result;
GO

-- Display all results
SELECT 
    TestID,
    TestDescription,
    BinaryValue,
    CAST(OtherValue AS VARCHAR(100)) AS OtherValue,
    OtherValueType,
    EqualResult,
    NotEqualResult,
    GreaterThanResult,
    LessThanResult
FROM BinaryMixedTypeComparisons
ORDER BY TestID;
GO

-- Cleanup
DROP TABLE BinaryMixedTypeComparisons;
GO


-- Create table for bitwise operation tests
CREATE TABLE BitwiseOperationTests (
    TestID INT IDENTITY(1,1),
    TestDescription VARCHAR(100),
    Value1 VARBINARY(10),
    Value2 VARBINARY(10),
    BitwiseAND VARBINARY(10),
    BitwiseOR VARBINARY(10),
    BitwiseXOR VARBINARY(10),
    BitwiseNOT VARBINARY(10)
);
GO

-- Test Case 1: Simple values
DECLARE @val1 VARBINARY(10) = 0x0F; -- 00001111
DECLARE @val2 VARBINARY(10) = 0xF0; -- 11110000

INSERT INTO BitwiseOperationTests (
    TestDescription,
    Value1,
    Value2,
    BitwiseAND,
    BitwiseOR,
    BitwiseXOR,
    BitwiseNOT
)
SELECT 
    'Simple Binary Values (0x0F AND 0xF0)',
    @val1,
    @val2,
    @val1 & @val2,                -- AND
    @val1 | @val2,                -- OR
    @val1 ^ @val2,                -- XOR
    ~@val1;                       -- NOT
GO

-- Test Case 2: All bits set vs all bits clear
DECLARE @allSet VARBINARY(10) = 0xFF;    -- 11111111
DECLARE @allClear VARBINARY(10) = 0x00;  -- 00000000

INSERT INTO BitwiseOperationTests (
    TestDescription,
    Value1,
    Value2,
    BitwiseAND,
    BitwiseOR,
    BitwiseXOR,
    BitwiseNOT
)
SELECT 
    'All Bits Set vs Clear (0xFF AND 0x00)',
    @allSet,
    @allClear,
    @allSet & @allClear,
    @allSet | @allClear,
    @allSet ^ @allClear,
    ~@allSet;
GO

-- Test Case 3: Alternating bits
DECLARE @alternating1 VARBINARY(10) = 0xAA; -- 10101010
DECLARE @alternating2 VARBINARY(10) = 0x55; -- 01010101

INSERT INTO BitwiseOperationTests (
    TestDescription,
    Value1,
    Value2,
    BitwiseAND,
    BitwiseOR,
    BitwiseXOR,
    BitwiseNOT
)
SELECT 
    'Alternating Bits (0xAA AND 0x55)',
    @alternating1,
    @alternating2,
    @alternating1 & @alternating2,
    @alternating1 | @alternating2,
    @alternating1 ^ @alternating2,
    ~@alternating1;
GO

-- Test Case 4: Same values
DECLARE @sameVal VARBINARY(10) = 0x55;

INSERT INTO BitwiseOperationTests (
    TestDescription,
    Value1,
    Value2,
    BitwiseAND,
    BitwiseOR,
    BitwiseXOR,
    BitwiseNOT
)
SELECT 
    'Same Values (0x55 AND 0x55)',
    @sameVal,
    @sameVal,
    @sameVal & @sameVal,
    @sameVal | @sameVal,
    @sameVal ^ @sameVal,
    ~@sameVal;
GO

-- Test Case 5: Multiple bytes
DECLARE @multiByte1 VARBINARY(10) = 0x1234;
DECLARE @multiByte2 VARBINARY(10) = 0x5678;

INSERT INTO BitwiseOperationTests (
    TestDescription,
    Value1,
    Value2,
    BitwiseAND,
    BitwiseOR,
    BitwiseXOR,
    BitwiseNOT
)
SELECT 
    'Multiple Bytes (0x1234 AND 0x5678)',
    @multiByte1,
    @multiByte2,
    @multiByte1 & @multiByte2,
    @multiByte1 | @multiByte2,
    @multiByte1 ^ @multiByte2,
    ~@multiByte1;
GO

-- Display results for regular bitwise operations
SELECT 
    TestID,
    TestDescription,
    Value1,
    Value2,
    BitwiseAND,
    BitwiseOR,
    BitwiseXOR,
    BitwiseNOT
FROM BitwiseOperationTests
ORDER BY TestID;
GO

-- Test assignment operators
DECLARE @assignTest TABLE (
    TestID INT IDENTITY(1,1),
    TestDescription VARCHAR(100),
    OriginalValue VARBINARY(10),
    AssignmentResult VARBINARY(10)
);

-- AND Assignment (&=)
DECLARE @andAssign VARBINARY(10) = 0xFF;
SET @andAssign &= 0x0F;

INSERT INTO @assignTest (TestDescription, OriginalValue, AssignmentResult)
VALUES ('AND Assignment (0xFF &= 0x0F)', 0xFF, @andAssign);

-- OR Assignment (|=)
DECLARE @orAssign VARBINARY(10) = 0x0F;
SET @orAssign |= 0xF0;

INSERT INTO @assignTest (TestDescription, OriginalValue, AssignmentResult)
VALUES ('OR Assignment (0x0F |= 0xF0)', 0x0F, @orAssign);

-- XOR Assignment (^=)
DECLARE @xorAssign VARBINARY(10) = 0xFF;
SET @xorAssign ^= 0x0F;

INSERT INTO @assignTest (TestDescription, OriginalValue, AssignmentResult)
VALUES ('XOR Assignment (0xFF ^= 0x0F)', 0xFF, @xorAssign);

-- Display results for assignment operators
SELECT 
    TestID,
    TestDescription,
    OriginalValue,
    AssignmentResult
FROM @assignTest
ORDER BY TestID;
GO

-- Cleanup
DROP TABLE BitwiseOperationTests;
GO

-- Create table for bitwise operation tests
CREATE TABLE BitwiseTypeTests (
    TestID INT IDENTITY(1,1),
    TestDescription VARCHAR(100),
    LeftOperandType VARCHAR(20),
    RightOperandType VARCHAR(20),
    LeftOperandValue VARBINARY(20),
    RightOperandValue VARBINARY(20),
    BitwiseAND VARBINARY(20),
    BitwiseOR VARBINARY(20),
    BitwiseXOR VARBINARY(20)
);
GO

-- 1. BINARY with integer types
INSERT INTO BitwiseTypeTests
SELECT 
    'BINARY & INT', 
    'BINARY(4)', 'INT',
    CAST(0x0F AS BINARY(4)),
    CAST(15 AS VARBINARY(4)),
    CAST(0x0F AS BINARY(4)) & 15,
    CAST(0x0F AS BINARY(4)) | 15,
    CAST(0x0F AS BINARY(4)) ^ 15
UNION ALL
SELECT 
    'BINARY & SMALLINT', 
    'BINARY(4)', 'SMALLINT',
    CAST(0x0F AS BINARY(4)),
    CAST(CAST(15 AS SMALLINT) AS VARBINARY(4)),
    CAST(0x0F AS BINARY(4)) & CAST(15 AS SMALLINT),
    CAST(0x0F AS BINARY(4)) | CAST(15 AS SMALLINT),
    CAST(0x0F AS BINARY(4)) ^ CAST(15 AS SMALLINT)
UNION ALL
SELECT 
    'BINARY & TINYINT', 
    'BINARY(4)', 'TINYINT',
    CAST(0x0F AS BINARY(4)),
    CAST(CAST(15 AS TINYINT) AS VARBINARY(4)),
    CAST(0x0F AS BINARY(4)) & CAST(15 AS TINYINT),
    CAST(0x0F AS BINARY(4)) | CAST(15 AS TINYINT),
    CAST(0x0F AS BINARY(4)) ^ CAST(15 AS TINYINT);
GO

-- 2. BIGINT with all supported types
INSERT INTO BitwiseTypeTests
SELECT 
    'BIGINT & BINARY', 
    'BIGINT', 'BINARY(4)',
    CAST(CAST(255 AS BIGINT) AS VARBINARY(8)),
    CAST(0x0F AS VARBINARY(4)),
    CAST(CAST(255 AS BIGINT) & CAST(0x0F AS BINARY(4)) AS VARBINARY(8)),
    CAST(CAST(255 AS BIGINT) | CAST(0x0F AS BINARY(4)) AS VARBINARY(8)),
    CAST(CAST(255 AS BIGINT) ^ CAST(0x0F AS BINARY(4)) AS VARBINARY(8));
GO

-- 3. INT with supported types
INSERT INTO BitwiseTypeTests
SELECT 
    'INT & BINARY', 
    'INT', 'BINARY(4)',
    CAST(255 AS VARBINARY(4)),
    CAST(0x0F AS VARBINARY(4)),
    CAST(255 & CAST(0x0F AS BINARY(4)) AS VARBINARY(4)),
    CAST(255 | CAST(0x0F AS BINARY(4)) AS VARBINARY(4)),
    CAST(255 ^ CAST(0x0F AS BINARY(4)) AS VARBINARY(4));
GO

-- 4. VARBINARY with integer types
INSERT INTO BitwiseTypeTests
SELECT 
    'VARBINARY & INT', 
    'VARBINARY(4)', 'INT',
    CAST(0x0F AS VARBINARY(4)),
    CAST(15 AS VARBINARY(4)),
    CAST(0x0F AS VARBINARY(4)) & 15,
    CAST(0x0F AS VARBINARY(4)) | 15,
    CAST(0x0F AS VARBINARY(4)) ^ 15
UNION ALL
SELECT 
    'VARBINARY & SMALLINT', 
    'VARBINARY(4)', 'SMALLINT',
    CAST(0x0F AS VARBINARY(4)),
    CAST(CAST(15 AS SMALLINT) AS VARBINARY(4)),
    CAST(0x0F AS VARBINARY(4)) & CAST(15 AS SMALLINT),
    CAST(0x0F AS VARBINARY(4)) | CAST(15 AS SMALLINT),
    CAST(0x0F AS VARBINARY(4)) ^ CAST(15 AS SMALLINT);
GO

-- Test NOT operator
CREATE TABLE BitwiseNOTTests (
    TestID INT IDENTITY(1,1),
    TestDescription VARCHAR(100),
    OperandType VARCHAR(20),
    OperandValue VARBINARY(20),
    NOTResult VARBINARY(20)
);

INSERT INTO BitwiseNOTTests (TestDescription, OperandType, OperandValue, NOTResult)
VALUES
    ('NOT BINARY', 'BINARY(4)', 
     CAST(0x0F AS VARBINARY(4)),
     CAST(~CAST(0x0F AS BINARY(4)) AS VARBINARY(4))),
    
    ('NOT BIGINT', 'BIGINT',
     CAST(CAST(255 AS BIGINT) AS VARBINARY(8)),
     CAST(~CAST(255 AS BIGINT) AS VARBINARY(8))),
    
    ('NOT INT', 'INT',
     CAST(255 AS VARBINARY(4)),
     CAST(~255 AS VARBINARY(4))),
    
    ('NOT VARBINARY', 'VARBINARY(4)',
     CAST(0x0F AS VARBINARY(4)),
     CAST(~CAST(0x0F AS VARBINARY(4)) AS VARBINARY(4)));
GO

SELECT 
    TestID,
    TestDescription,
    LeftOperandType,
    RightOperandType,
    LeftOperandValue,
    RightOperandValue,
    BitwiseAND,
    BitwiseOR,
    BitwiseXOR
FROM BitwiseTypeTests
ORDER BY TestID;
GO

SELECT 
    TestID,
    TestDescription,
    OperandType,
    OperandValue,
    NOTResult
FROM BitwiseNOTTests
ORDER BY TestID;
GO

-- Cleanup
DROP TABLE BitwiseTypeTests;
DROP TABLE BitwiseNOTTests;
GO

-- Create table for concatenation tests
CREATE TABLE BinaryConcatTests (
    TestID INT IDENTITY(1,1),
    TestDescription VARCHAR(100),
    LeftOperandType VARCHAR(20),
    RightOperandType VARCHAR(20),
    LeftOperand VARBINARY(100),
    RightOperand VARBINARY(100),
    ConcatResult VARBINARY(200),
    ResultType VARCHAR(20),
    ResultLength INT
);
GO

-- Test Case 1: Basic concatenation with same types
INSERT INTO BinaryConcatTests (
    TestDescription,
    LeftOperandType,
    RightOperandType,
    LeftOperand,
    RightOperand,
    ConcatResult,
    ResultType,
    ResultLength
)
VALUES
-- BINARY + BINARY
(
    'BINARY(4) + BINARY(4)',
    'BINARY(4)',
    'BINARY(4)',
    CAST(0x1234 AS BINARY(4)),
    CAST(0x5678 AS BINARY(4)),
    CAST(0x1234 AS BINARY(4)) + CAST(0x5678 AS BINARY(4)),
    'BINARY(8)',
    DATALENGTH(CAST(0x1234 AS BINARY(4)) + CAST(0x5678 AS BINARY(4)))
),
-- VARBINARY + VARBINARY
(
    'VARBINARY(4) + VARBINARY(4)',
    'VARBINARY(4)',
    'VARBINARY(4)',
    CAST(0x1234 AS VARBINARY(4)),
    CAST(0x5678 AS VARBINARY(4)),
    CAST(0x1234 AS VARBINARY(4)) + CAST(0x5678 AS VARBINARY(4)),
    'VARBINARY(8)',
    DATALENGTH(CAST(0x1234 AS VARBINARY(4)) + CAST(0x5678 AS VARBINARY(4)))
);
GO

-- Test Case 2: Mixed type concatenation
INSERT INTO BinaryConcatTests (
    TestDescription,
    LeftOperandType,
    RightOperandType,
    LeftOperand,
    RightOperand,
    ConcatResult,
    ResultType,
    ResultLength
)
VALUES
-- BINARY + VARBINARY
(
    'BINARY(4) + VARBINARY(4)',
    'BINARY(4)',
    'VARBINARY(4)',
    CAST(0x1234 AS BINARY(4)),
    CAST(0x5678 AS VARBINARY(4)),
    CAST(0x1234 AS BINARY(4)) + CAST(0x5678 AS VARBINARY(4)),
    'VARBINARY(8)',
    DATALENGTH(CAST(0x1234 AS BINARY(4)) + CAST(0x5678 AS VARBINARY(4)))
),
-- VARBINARY + BINARY
(
    'VARBINARY(4) + BINARY(4)',
    'VARBINARY(4)',
    'BINARY(4)',
    CAST(0x1234 AS VARBINARY(4)),
    CAST(0x5678 AS BINARY(4)),
    CAST(0x1234 AS VARBINARY(4)) + CAST(0x5678 AS BINARY(4)),
    'VARBINARY(8)',
    DATALENGTH(CAST(0x1234 AS VARBINARY(4)) + CAST(0x5678 AS BINARY(4)))
);
GO

-- Test Case 3: NULL value concatenation
INSERT INTO BinaryConcatTests (
    TestDescription,
    LeftOperandType,
    RightOperandType,
    LeftOperand,
    RightOperand,
    ConcatResult,
    ResultType,
    ResultLength
)
VALUES
-- NULL + BINARY
(
    'NULL + BINARY(4)',
    'NULL',
    'BINARY(4)',
    NULL,
    CAST(0x5678 AS BINARY(4)),
    NULL + CAST(0x5678 AS BINARY(4)),
    'VARBINARY',
    DATALENGTH(NULL + CAST(0x5678 AS BINARY(4)))
),
-- BINARY + NULL
(
    'BINARY(4) + NULL',
    'BINARY(4)',
    'NULL',
    CAST(0x1234 AS BINARY(4)),
    NULL,
    CAST(0x1234 AS BINARY(4)) + NULL,
    'VARBINARY',
    DATALENGTH(CAST(0x1234 AS BINARY(4)) + NULL)
),
-- NULL + NULL
(
    'NULL + NULL',
    'NULL',
    'NULL',
    NULL,
    NULL,
    NULL + NULL,
    'VARBINARY',
    DATALENGTH(NULL + NULL)
);
GO

-- Test Case 4: Zero length value concatenation
INSERT INTO BinaryConcatTests (
    TestDescription,
    LeftOperandType,
    RightOperandType,
    LeftOperand,
    RightOperand,
    ConcatResult,
    ResultType,
    ResultLength
)
VALUES
-- Empty VARBINARY + BINARY
(
    'Empty VARBINARY + BINARY(4)',
    'VARBINARY(4)',
    'BINARY(4)',
    CAST(0x AS VARBINARY(4)),
    CAST(0x5678 AS BINARY(4)),
    CAST(0x AS VARBINARY(4)) + CAST(0x5678 AS BINARY(4)),
    'VARBINARY',
    DATALENGTH(CAST(0x AS VARBINARY(4)) + CAST(0x5678 AS BINARY(4)))
),
-- BINARY + Empty VARBINARY
(
    'BINARY(4) + Empty VARBINARY',
    'BINARY(4)',
    'VARBINARY(4)',
    CAST(0x1234 AS BINARY(4)),
    CAST(0x AS VARBINARY(4)),
    CAST(0x1234 AS BINARY(4)) + CAST(0x AS VARBINARY(4)),
    'VARBINARY',
    DATALENGTH(CAST(0x1234 AS BINARY(4)) + CAST(0x AS VARBINARY(4)))
),
-- Empty VARBINARY + Empty VARBINARY
(
    'Empty VARBINARY + Empty VARBINARY',
    'VARBINARY(4)',
    'VARBINARY(4)',
    CAST(0x AS VARBINARY(4)),
    CAST(0x AS VARBINARY(4)),
    CAST(0x AS VARBINARY(4)) + CAST(0x AS VARBINARY(4)),
    'VARBINARY',
    DATALENGTH(CAST(0x AS VARBINARY(4)) + CAST(0x AS VARBINARY(4)))
);
GO

-- Test Case 5: Different length concatenation
INSERT INTO BinaryConcatTests (
    TestDescription,
    LeftOperandType,
    RightOperandType,
    LeftOperand,
    RightOperand,
    ConcatResult,
    ResultType,
    ResultLength
)
VALUES
(
    'BINARY(2) + BINARY(4)',
    'BINARY(2)',
    'BINARY(4)',
    CAST(0x12 AS BINARY(2)),
    CAST(0x5678 AS BINARY(4)),
    CAST(0x12 AS BINARY(2)) + CAST(0x5678 AS BINARY(4)),
    'BINARY(6)',
    DATALENGTH(CAST(0x12 AS BINARY(2)) + CAST(0x5678 AS BINARY(4)))
),
(
    'VARBINARY(2) + VARBINARY(4)',
    'VARBINARY(2)',
    'VARBINARY(4)',
    CAST(0x12 AS VARBINARY(2)),
    CAST(0x5678 AS VARBINARY(4)),
    CAST(0x12 AS VARBINARY(2)) + CAST(0x5678 AS VARBINARY(4)),
    'VARBINARY(6)',
    DATALENGTH(CAST(0x12 AS VARBINARY(2)) + CAST(0x5678 AS VARBINARY(4)))
);
GO

-- Display results
SELECT 
    TestID,
    TestDescription,
    LeftOperandType,
    RightOperandType,
    LeftOperand,
    RightOperand,
    ConcatResult,
    ResultType,
    ResultLength
FROM BinaryConcatTests
ORDER BY TestID;
GO

-- Additional verification queries
SELECT 'Type Precedence Tests' AS TestType;
GO

-- Test BINARY + VARBINARY type precedence
SELECT 
    'BINARY + VARBINARY Results in: ' + 
    CASE 
        WHEN SQL_VARIANT_PROPERTY(
            CAST(0x12 AS BINARY(2)) + CAST(0x34 AS VARBINARY(2)), 'BaseType'
        ) = 'varbinary' 
        THEN 'VARBINARY (Higher Precedence)'
        ELSE 'Other'
    END AS TypePrecedenceTest;
GO

-- Test NULL handling
SELECT 'NULL Handling Tests' AS TestType;
SELECT 
    CASE 
        WHEN (CAST(0x12 AS BINARY(2)) + NULL) IS NULL THEN 'NULL'
        ELSE 'Not NULL'
    END AS BinaryPlusNULL,
    CASE 
        WHEN (NULL + CAST(0x12 AS BINARY(2))) IS NULL THEN 'NULL'
        ELSE 'Not NULL'
    END AS NULLPlusBinary,
    CASE 
        WHEN (NULL + NULL) IS NULL THEN 'NULL'
        ELSE 'Not NULL'
    END AS NULLPlusNULL;
GO

-- Cleanup
DROP TABLE BinaryConcatTests;
GO

-- Create a test table
CREATE TABLE BinaryFunctionTests (
    TestID INT IDENTITY(1,1),
    TestDescription VARCHAR(100),
    InputValue VARBINARY(MAX),
    OutputValue VARBINARY(MAX),
    FunctionUsed VARCHAR(50)
);
GO

-- 1. Aggregate Functions
INSERT INTO BinaryFunctionTests VALUES
-- MAX
('MAX Function', 0x1234, 
 CAST((SELECT MAX(CAST(0x1234 AS VARBINARY(10))) FROM (VALUES (1)) AS t(c)) AS VARBINARY(100)),
 'MAX'),
-- MIN
('MIN Function', 0x1234, 
 CAST((SELECT MIN(CAST(0x1234 AS VARBINARY(10))) FROM (VALUES (1)) AS t(c)) AS VARBINARY(100)),
 'MIN');
GO

-- 2. String/Binary Functions
INSERT INTO BinaryFunctionTests VALUES
('DATALENGTH', 0x1234, 
 DATALENGTH(0x1234),
 'DATALENGTH');
GO

INSERT INTO BinaryFunctionTests VALUES
('LEN', 0x1234, 
 LEN(0x1234),
 'LEN');
GO

INSERT INTO BinaryFunctionTests VALUES
('SUBSTRING', 0x123456, 
 SUBSTRING(0x123456, 2, 2),
 'SUBSTRING');
GO

INSERT INTO BinaryFunctionTests VALUES
('LEFT', 0x123456, 
 cast(LEFT(0x123456, 2) as varbinary(100)),
 'LEFT');
GO

INSERT INTO BinaryFunctionTests VALUES
('RIGHT', 0x123456, 
 cast(RIGHT(0x123456, 2) as varbinary(100)),
 'RIGHT');
GO

-- 3. Cryptographic Functions
INSERT INTO BinaryFunctionTests VALUES
-- HASHBYTES
('HASHBYTES SHA2_256', CAST('Test' AS VARBINARY(100)), 
 HASHBYTES('SHA2_256', 'Test'),
 'HASHBYTES');
GO

-- 4. Mathematical Functions that work with binary
INSERT INTO BinaryFunctionTests VALUES
('AVG Function', 0x1234, 
 CAST((SELECT AVG(CAST(0x12 AS INT)) FROM (VALUES (1)) AS t(c)) AS VARBINARY(100)),
 'AVG');
GO

-- 5. System Metadata Functions
-- INSERT INTO BinaryFunctionTests VALUES
-- -- DATABASEPROPERTYEX
-- ('DATABASEPROPERTYEX', NULL, 
--  CAST(DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS VARCHAR(100)) IS NOT NULL,
--  'DATABASEPROPERTYEX');
GO

-- Display results
SELECT 
    TestID,
    TestDescription,
    CASE 
        WHEN InputValue IS NULL THEN NULL
        ELSE InputValue
    END AS InputValueHex,
    OutputValue,
    FunctionUsed
FROM BinaryFunctionTests
ORDER BY TestID;
GO

DROp TABLE BinaryFunctionTests
GO

-- Test Case 1: Simple UNION with different VARBINARY sizes
select t.* into temp_tbl from
(
SELECT 'UNION Test 1' AS Test,
    CAST(0x1234 AS VARBINARY(4)) AS Value,
    DATALENGTH(CAST(0x1234 AS VARBINARY(4))) AS Length1
UNION
SELECT 'UNION Test 1',
    CAST(0x5678 AS VARBINARY(8)) AS Value,
    DATALENGTH(CAST(0x5678 AS VARBINARY(8))) AS Length2
) t order by value;
GO

select * from temp_tbl
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test Case 2: UNION with NULL and non-NULL values
select t.* into temp_tbl from
(
SELECT 'UNION Test 2' AS Test,
    CAST(NULL AS VARBINARY(4)) AS Value,
    NULL AS Length1
UNION
SELECT 'UNION Test 2',
    CAST(0x5678 AS VARBINARY(4)) AS Value,
    DATALENGTH(CAST(0x5678 AS VARBINARY(4))) AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test Case 3: UNION with empty and non-empty values
select t.* into temp_tbl from
(
SELECT 'UNION Test 3' AS Test,
    CAST(0x AS VARBINARY(8)) AS Value,
    DATALENGTH(CAST(0x AS VARBINARY(8))) AS Length1
UNION
SELECT 'UNION Test 3',
    CAST(0x5678 AS VARBINARY(4)) AS Value,
    DATALENGTH(CAST(0x5678 AS VARBINARY(4))) AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test Case 4: UNION with BINARY and VARBINARY
select t.* into temp_tbl from
(
SELECT 'UNION Test 4' AS Test,
    CAST(0x1234 AS BINARY(4)) AS Value,
    DATALENGTH(CAST(0x1234 AS BINARY(4))) AS Length1
UNION
SELECT 'UNION Test 4',
    CAST(0x5678 AS VARBINARY(4)) AS Value,
    DATALENGTH(CAST(0x5678 AS VARBINARY(4))) AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test Case 5: UNION with different size values
select t.* into temp_tbl from
(
SELECT 'UNION Test 5' AS Test,
    CAST(0x12 AS VARBINARY(4)) AS Value,
    DATALENGTH(CAST(0x12 AS VARBINARY(4))) AS Length1
UNION
SELECT 'UNION Test 5',
    CAST(0x345678 AS BINARY(8)) AS Value,
    DATALENGTH(CAST(0x345678 AS BINARY(8))) AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test Case 6: UNION with different size values for BINARY
select t.* into temp_tbl from
(
SELECT 'UNION Test 6' AS Test,
    CAST(0x12 AS BINARY(4)) AS Value,
    DATALENGTH(CAST(0x12 AS BINARY(4))) AS Length1
UNION
SELECT 'UNION Test 6',
    CAST(0x345678 AS BINARY(8)) AS Value,
    DATALENGTH(CAST(0x345678 AS BINARY(8))) AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test Case 7: UNION with varbinary[n] and varbinary[max]
select t.* into temp_tbl from
(
SELECT 'UNION Test 7' AS Test,
    CAST(0x12 AS VARBINARY(4)) AS Value,
    DATALENGTH(CAST(0x12 AS VARBINARY(4))) AS Length1
UNION
SELECT 'UNION Test 7',
    CAST(0x345678 AS VARBINARY(max)) AS Value,
    DATALENGTH(CAST(0x345678 AS VARBINARY(max))) AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test Case 8: UNION with binary[n] and varbinary[max]
select t.* into temp_tbl from
(
SELECT 'UNION Test 8' AS Test,
    CAST(0x12 AS BINARY(4)) AS Value,
    DATALENGTH(CAST(0x12 AS BINARY(4))) AS Length1
UNION
SELECT 'UNION Test 8',
    CAST(0x345678 AS VARBINARY(max)) AS Value,
    DATALENGTH(CAST(0x345678 AS VARBINARY(max))) AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test 1: VARBINARY and VARCHAR
SELECT t.* INTO temp_tbl FROM
(
SELECT 'VARBINARY and VARCHAR' AS Test,
    CAST(0x48656C6C6F AS VARBINARY(10)) AS Value,
    DATALENGTH(CAST(0x48656C6C6F AS VARBINARY(10))) AS Length1
UNION
SELECT 'VARBINARY and VARCHAR',
    CAST('World' AS VARCHAR(10)) AS Value,
    DATALENGTH(CAST('World' AS VARCHAR(10))) AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test 2: VARBINARY and INT
SELECT t.* INTO temp_tbl FROM
(
SELECT 'VARBINARY and INT' AS Test,
    CAST(0x0064 AS VARBINARY(10)) AS Value,
    DATALENGTH(CAST(0x0064 AS VARBINARY(10))) AS Length1
UNION
SELECT 'VARBINARY and INT',
    CAST(200 AS INT) AS Value,
    DATALENGTH(CAST(200 AS VARCHAR(10))) AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test 3: VARBINARY and DATETIME
SELECT t.* INTO temp_tbl FROM
(
SELECT 'VARBINARY and DATETIME' AS Test,
    CAST(0x0000AB0C AS VARBINARY(10)) AS Value,
    DATALENGTH(CAST(0x0000AB0C AS VARBINARY(10))) AS Length1
UNION
SELECT 'VARBINARY and DATETIME',
    CAST('2024-01-16' AS DATETIME) AS Value,
    DATALENGTH(CAST('2024-01-16' AS DATETIME)) AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test 4: VARBINARY and DECIMAL
SELECT t.* INTO temp_tbl FROM
(
SELECT 'VARBINARY and DECIMAL' AS Test,
    CAST(0x0064 AS VARBINARY(10)) AS Value,
    DATALENGTH(CAST(0x0064 AS VARBINARY(10))) AS Length1
UNION
SELECT 'VARBINARY and DECIMAL',
    CAST(200.00 AS DECIMAL(10,2)) AS Value,
    DATALENGTH(CAST(200.00 AS DECIMAL(10,2))) AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test 5: VARBINARY and UNIQUEIDENTIFIER
SELECT t.* INTO temp_tbl FROM
(
SELECT 'VARBINARY and UNIQUEIDENTIFIER' AS Test,
    CAST('12345678-1234-1234-1234-123456789012' AS VARBINARY(16)) AS Value,
    DATALENGTH(CAST('12345678-1234-1234-1234-123456789012' AS VARBINARY(16))) AS Length1
UNION
SELECT 'VARBINARY and UNIQUEIDENTIFIER',
    CAST('87654321-4321-4321-4321-210987654321' AS UNIQUEIDENTIFIER) AS Value,
    DATALENGTH(CAST('87654321-4321-4321-4321-210987654321' AS UNIQUEIDENTIFIER)) AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test 6: VARBINARY and BIT
SELECT t.* INTO temp_tbl FROM
(
SELECT 'VARBINARY and BIT' AS Test,
    CAST(0x01 AS VARBINARY(1)) AS Value,
    DATALENGTH(CAST(0x01 AS VARBINARY(1))) AS Length1
UNION
SELECT 'VARBINARY and BIT',
    CAST(0 AS BIT) AS Value,
    DATALENGTH(CAST(0 AS BIT)) AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test 7: VARBINARY and FLOAT
SELECT t.* INTO temp_tbl FROM
(
SELECT 'VARBINARY and FLOAT' AS Test,
    CAST(123.45 AS VARBINARY(8)) AS Value,
    DATALENGTH(CAST(123.45 AS VARBINARY(8))) AS Length1
UNION
SELECT 'VARBINARY and FLOAT',
    CAST(567.89 AS FLOAT) AS Value,
    DATALENGTH(CAST(567.89 AS FLOAT)) AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test 8: VARBINARY and NVARCHAR
SELECT t.* INTO temp_tbl FROM
(
SELECT 'VARBINARY and NVARCHAR' AS Test,
    CAST(0x48656C6C6F AS VARBINARY(10)) AS Value,
    DATALENGTH(CAST(0x48656C6C6F AS VARBINARY(10))) AS Length1
UNION
SELECT 'VARBINARY and NVARCHAR',
    CAST(N'World' AS NVARCHAR(10)) AS Value,
    DATALENGTH(CAST(N'World' AS NVARCHAR(10))) AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test 9: VARBINARY(MAX) and regular VARBINARY
SELECT t.* INTO temp_tbl FROM
(
SELECT 'VARBINARY(MAX) and VARBINARY' AS Test,
    CAST(0x12345678 AS VARBINARY(MAX)) AS Value,
    DATALENGTH(CAST(0x12345678 AS VARBINARY(MAX))) AS Length1
UNION
SELECT 'VARBINARY(MAX) and VARBINARY',
    CAST(0x9ABCDEF0 AS VARBINARY(8)) AS Value,
    DATALENGTH(CAST(0x9ABCDEF0 AS VARBINARY(8))) AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO

-- Test 10: BINARY and VARBINARY with NULL
SELECT t.* INTO temp_tbl FROM
(
SELECT 'BINARY and NULL' AS Test,
    CAST(0x1234 AS BINARY(4)) AS Value,
    DATALENGTH(CAST(0x1234 AS BINARY(4))) AS Length1
UNION
SELECT 'BINARY and NULL',
    CAST(NULL AS VARBINARY(4)) AS Value,
    NULL AS Length2
) t order by value;
GO

select name, (select name from sys.types where system_type_id = c.system_type_id), max_length from sys.columns c where object_id = object_id('temp_tbl');
GO

drop table temp_tbl
GO


-- Create test table with binary data
CREATE TABLE #BinaryData (
    ID INT,
    GroupID INT,
    BinaryValue VARBINARY(10),
    Description VARCHAR(50)
);
GO

-- Insert test data
INSERT INTO #BinaryData VALUES
-- Group 1: Regular values
(1, 1, 0x0A, 'Group 1 - Small value'),
(2, 1, 0x0F, 'Group 1 - Larger value'),
(3, 1, NULL, 'Group 1 - NULL value'),

-- Group 2: NULL values
(4, 2, NULL, 'Group 2 - NULL value 1'),
(5, 2, NULL, 'Group 2 - NULL value 2'),
(6, 2, 0x12, 'Group 2 - Non-NULL value'),

-- Group 3: Same values
(7, 3, 0x0A, 'Group 3 - Duplicate value'),
(8, 3, 0x0A, 'Group 3 - Duplicate value'),
(9, 3, NULL, 'Group 3 - NULL value');
GO

-- Test Case 1: CHECKSUM_AGG
SELECT t.* INTO #ChecksumResults FROM
(
SELECT 'Regular CHECKSUM_AGG' AS Test,
    GroupID,
    CHECKSUM_AGG(CAST(BinaryValue AS INT)) AS ChecksumResult
FROM #BinaryData
GROUP BY GroupID
UNION
SELECT 'CHECKSUM_AGG with DISTINCT',
    GroupID,
    CHECKSUM_AGG(DISTINCT CAST(BinaryValue AS INT)) AS ChecksumResult
FROM #BinaryData
GROUP BY GroupID
) t;
GO

-- Test Case 2: CHECKSUM_AGG with NULL handling
SELECT t.* INTO #ChecksumNullResults FROM
(
SELECT 'Default NULL handling' AS Test,
    GroupID,
    CHECKSUM_AGG(CAST(BinaryValue AS INT)) AS ChecksumResult
FROM #BinaryData
GROUP BY GroupID
UNION
SELECT 'NULL handling with ISNULL',
    GroupID,
    CHECKSUM_AGG(CAST(ISNULL(BinaryValue, 0x00) AS INT)) AS ChecksumResult
FROM #BinaryData
GROUP BY GroupID
) t;
GO

-- Test Case 3: MAX aggregate
SELECT t.* INTO #MaxResults FROM
(
SELECT 'Regular MAX' AS Test,
    GroupID,
    MAX(BinaryValue) AS MaxValue,
    DATALENGTH(MAX(BinaryValue)) AS MaxLength
FROM #BinaryData
GROUP BY GroupID
UNION
SELECT 'MAX with ISNULL',
    GroupID,
    MAX(ISNULL(BinaryValue, 0x00)) AS MaxValue,
    DATALENGTH(MAX(ISNULL(BinaryValue, 0x00))) AS MaxLength
FROM #BinaryData
GROUP BY GroupID
) t order by GroupID, MaxValue, Test;
GO

-- Test Case 4: MIN aggregate
SELECT t.* INTO #MinResults FROM
(
SELECT 'Regular MIN' AS Test,
    GroupID,
    MIN(BinaryValue) AS MinValue,
    DATALENGTH(MIN(BinaryValue)) AS MinLength
FROM #BinaryData
GROUP BY GroupID
UNION
SELECT 'MIN with ISNULL',
    GroupID,
    MIN(ISNULL(BinaryValue, 0xFF)) AS MinValue,
    DATALENGTH(MIN(ISNULL(BinaryValue, 0xFF))) AS MinLength
FROM #BinaryData
GROUP BY GroupID
) t order by GroupID, MinValue, Test;
GO

-- Test Case 5: Combining multiple aggregates
SELECT t.* INTO #CombinedResults FROM
(
SELECT 'Combined Aggregates' AS Test,
    GroupID,
    MAX(BinaryValue) AS MaxValue,
    MIN(BinaryValue) AS MinValue,
    CHECKSUM_AGG(CAST(BinaryValue AS INT)) AS ChecksumResult,
    COUNT(*) AS TotalRows,
    COUNT(BinaryValue) AS NonNullRows
FROM #BinaryData
GROUP BY GroupID
) t;
GO

-- Display results
-- CHECKSUM_AGG results
SELECT 'CHECKSUM_AGG Results' AS ResultType, *
FROM #ChecksumResults
ORDER BY GroupID;
GO

-- CHECKSUM_AGG NULL handling results
SELECT 'CHECKSUM_AGG NULL Handling' AS ResultType, *
FROM #ChecksumNullResults
ORDER BY GroupID;
GO

-- MAX results
SELECT 'MAX Results' AS ResultType,
    Test,
    GroupID,
    MaxValue,
    MaxLength
FROM #MaxResults;
GO

-- MIN results
SELECT 'MIN Results' AS ResultType,
    Test,
    GroupID,
    MinValue,
    MinLength
FROM #MinResults;
GO

-- Combined results
SELECT 'Combined Results' AS ResultType,
    Test,
    GroupID,
    MaxValue,
    MinValue,
    ChecksumResult,
    TotalRows,
    NonNullRows
FROM #CombinedResults
ORDER BY GroupID;
GO

-- Additional verification queries
-- Verify NULL handling
SELECT 'NULL Handling Verification' AS Test,
    GroupID,
    COUNT(*) AS TotalCount,
    COUNT(BinaryValue) AS NonNullCount,
    COUNT(CASE WHEN BinaryValue IS NULL THEN 1 END) AS NullCount
FROM #BinaryData
GROUP BY GroupID;
GO

-- Verify distinct values
SELECT 'Distinct Values' AS Test,
    GroupID,
    COUNT(DISTINCT BinaryValue) AS DistinctValues
FROM #BinaryData
GROUP BY GroupID;
GO

-- Cleanup
DROP TABLE #BinaryData;
GO
DROP TABLE #ChecksumResults;
GO
DROP TABLE #ChecksumNullResults;
GO
DROP TABLE #MaxResults;
GO
DROP TABLE #MinResults;
GO
DROP TABLE #CombinedResults;
GO

-- test cases to test convert where target type is [var]binary
GO

-- String Types to BINARY/VARBINARY
SELECT 'CHAR to BINARY(10)' AS Test,
    CONVERT(BINARY(10), CAST('Hello' AS CHAR(10))) AS ConvertedValue,
    DATALENGTH(CONVERT(BINARY(10), 'Hello')) AS Length;
GO

SELECT 'VARCHAR to VARBINARY(MAX)' AS Test,
    CONVERT(VARBINARY(MAX), CAST('World' AS VARCHAR(10))) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(MAX), 'World')) AS Length;
GO

SELECT 'NVARCHAR to VARBINARY(10)' AS Test,
    CONVERT(VARBINARY(10), CAST(N'测试' AS NVARCHAR(10))) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(10), N'测试')) AS Length;
GO

SELECT 'CHAR to BINARY(10)' AS Test,
    CONVERT(BINARY(2), CAST('Hello' AS CHAR(10))) AS ConvertedValue,
    DATALENGTH(CONVERT(BINARY(10), 'Hello')) AS Length;
GO

SELECT 'VARCHAR to VARBINARY(MAX)' AS Test,
    CONVERT(VARBINARY(2), CAST('World' AS VARCHAR(10))) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(MAX), 'World')) AS Length;
GO

SELECT 'NVARCHAR to VARBINARY(10)' AS Test,
    CONVERT(VARBINARY(2), CAST(N'测试' AS NVARCHAR(10))) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(10), N'测试')) AS Length;
GO

-- Numeric Types to BINARY/VARBINARY
SELECT 'INT to BINARY(4)' AS Test,
    CONVERT(BINARY(4), CAST(12345 AS INT)) AS ConvertedValue,
    DATALENGTH(CONVERT(BINARY(4), 12345)) AS Length;
GO

SELECT 'DECIMAL to VARBINARY(10)' AS Test,
    CONVERT(VARBINARY(10), CAST(123.45 AS DECIMAL(10,2))) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(10), 123.45)) AS Length;
GO

SELECT 'FLOAT to VARBINARY(8)' AS Test,
    CONVERT(VARBINARY(8), CAST(123.45 AS FLOAT)) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(8), 123.45)) AS Length;
GO

-- DateTime Types to BINARY/VARBINARY
SELECT 'DATETIME to BINARY(8)' AS Test,
    CONVERT(BINARY(8), CAST('2024-01-15' AS DATETIME)) AS ConvertedValue,
    DATALENGTH(CONVERT(BINARY(8), '2024-01-15')) AS Length;
GO

SELECT 'DATE to VARBINARY(6)' AS Test,
    CONVERT(VARBINARY(6), CAST('2024-01-15' AS DATE)) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(6), '2024-01-15')) AS Length;
GO

SELECT 'TIME to VARBINARY(5)' AS Test,
    CONVERT(VARBINARY(5), CAST('12:34:56' AS TIME)) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(5), '12:34:56')) AS Length;
GO

-- Special Types to BINARY/VARBINARY
SELECT 'UNIQUEIDENTIFIER to BINARY(16)' AS Test,
    CONVERT(BINARY(16), CAST('12345678-1234-1234-1234-123456789012' AS UNIQUEIDENTIFIER)) AS ConvertedValue,
    DATALENGTH(CONVERT(BINARY(16), '12345678-1234-1234-1234-123456789012')) AS Length;
GO

SELECT 'BIT to VARBINARY(1)' AS Test,
    CONVERT(VARBINARY(1), CAST(1 AS BIT)) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(1), 1)) AS Length;
GO

-- NULL and Empty Values
SELECT 'NULL to BINARY(10)' AS Test,
    CONVERT(BINARY(10), NULL) AS ConvertedValue,
    DATALENGTH(CONVERT(BINARY(10), NULL)) AS Length;
GO

SELECT 'Empty string to VARBINARY(10)' AS Test,
    CONVERT(VARBINARY(10), '') AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(10), '')) AS Length;
GO

-- Style Parameter Tests
SELECT 'Style 1 (hex)' AS Test,
    CONVERT(VARBINARY(10), '1234', 1) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(10), '1234', 1)) AS Length;
GO

SELECT 'Style 2 (decimal)' AS Test,
    CONVERT(VARBINARY(10), '1234', 2) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(10), '1234', 2)) AS Length;
GO

-- Style 0 (Default)
SELECT 'Style 0 - Default String' AS Test,
    CONVERT(VARBINARY(10), CAST('ABC' AS VARCHAR(10)), 0) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(10), 'ABC', 0)) AS Length;
GO

-- Style 1 (Hex strings)
SELECT 'Style 1 - Basic Hex' AS Test,
    CONVERT(VARBINARY(10), CAST('1234' AS VARCHAR(10)), 1) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(10), '1234', 1)) AS Length;
GO

SELECT 'Style 1 - With 0x Prefix' AS Test,
    CONVERT(VARBINARY(10), CAST('0x1234' AS VARCHAR(10)), 1) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(10), '0x1234', 1)) AS Length;
GO

SELECT 'Style 1 - Long Hex' AS Test,
    CONVERT(VARBINARY(10), CAST('ABCDEF1234' AS VARCHAR(10)), 1) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(10), 'ABCDEF1234', 1)) AS Length;
GO

SELECT 'Style 1 - Odd Length Hex' AS Test,
    CONVERT(VARBINARY(10), CAST('123' AS VARCHAR(10)), 1) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(10), '123', 1)) AS Length;
GO

-- Style 2 (Decimal strings)
SELECT 'Style 2 - Small Number' AS Test,
    CONVERT(VARBINARY(10), CAST('123' AS VARCHAR(10)), 2) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(10), '123', 2)) AS Length;
GO

SELECT 'Style 2 - Large Number' AS Test,
    CONVERT(VARBINARY(10), CAST('65535' AS VARCHAR(10)), 2) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(10), '65535', 2)) AS Length;
GO

SELECT 'Style 2 - Zero' AS Test,
    CONVERT(VARBINARY(10), CAST('0' AS VARCHAR(10)), 2) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(10), '0', 2)) AS Length;
GO

-- Different target types
SELECT 'Style 1 - To BINARY' AS Test,
    CONVERT(BINARY(8), CAST('1234ABCD' AS VARCHAR(8)), 1) AS ConvertedValue,
    DATALENGTH(CONVERT(BINARY(8), '1234ABCD', 1)) AS Length;
GO

SELECT 'Style 1 - To VARBINARY(MAX)' AS Test,
    CONVERT(VARBINARY(MAX), CAST('1234ABCD' AS VARCHAR(8)), 1) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(MAX), '1234ABCD', 1)) AS Length;
GO

-- Empty and NULL values
SELECT 'Style 1 - Empty String' AS Test,
    CONVERT(VARBINARY(10), CAST('' AS VARCHAR(1)), 1) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(10), '', 1)) AS Length;
GO

SELECT 'Style 1 - NULL Value' AS Test,
    CONVERT(VARBINARY(10), CAST(NULL AS VARCHAR(1)), 1) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(10), NULL, 1)) AS Length;
GO

-- Different lengths
SELECT 'Style 1 - Short to Long' AS Test,
    CONVERT(BINARY(10), CAST('12' AS VARCHAR(2)), 1) AS ConvertedValue,
    DATALENGTH(CONVERT(BINARY(10), '12', 1)) AS Length;
GO

SELECT 'Style 1 - Long to Short' AS Test,
    CONVERT(VARBINARY(5), CAST('123456789A' AS VARCHAR(10)), 1) AS ConvertedValue,
    DATALENGTH(CONVERT(VARBINARY(5), '123456789A', 1)) AS Length;
GO

-- Error cases using TRY_CONVERT
SELECT 'Style 1 - Invalid Hex' AS Test,
    TRY_CONVERT(VARBINARY(10), CAST('GHIJK' AS VARCHAR(5)), 1) AS ConvertedValue,
    DATALENGTH(TRY_CONVERT(VARBINARY(10), 'GHIJK', 1)) AS Length;
GO

SELECT 'Style 2 - Negative Number' AS Test,
    TRY_CONVERT(VARBINARY(10), CAST('-123' AS VARCHAR(4)), 2) AS ConvertedValue,
    DATALENGTH(TRY_CONVERT(VARBINARY(10), '-123', 2)) AS Length;
GO

SELECT 'Invalid Style Number' AS Test,
    TRY_CONVERT(VARBINARY(10), CAST('1234' AS VARCHAR(4)), 3) AS ConvertedValue,
    DATALENGTH(TRY_CONVERT(VARBINARY(10), '1234', 3)) AS Length;
GO

-- Basic ascending sort with simple binary values
SELECT 'Basic Ascending Sort' AS Test,
    CAST(0x00 AS VARBINARY(2)) AS BinaryValue
UNION ALL
SELECT 'Basic Ascending Sort',
    CAST(0x01 AS VARBINARY(2))
UNION ALL
SELECT 'Basic Ascending Sort',
    CAST(0xFF AS VARBINARY(2))
ORDER BY BinaryValue ASC;
GO

-- Basic descending sort with simple binary values
SELECT 'Basic Descending Sort' AS Test,
    CAST(0x00 AS VARBINARY(2)) AS BinaryValue
UNION ALL
SELECT 'Basic Descending Sort',
    CAST(0x01 AS VARBINARY(2))
UNION ALL
SELECT 'Basic Descending Sort',
    CAST(0xFF AS VARBINARY(2))
ORDER BY BinaryValue DESC;
GO

-- Sort with different lengths
SELECT 'Different Lengths Sort' AS Test,
    CAST(0x01 AS VARBINARY(4)) AS BinaryValue
UNION ALL
SELECT 'Different Lengths Sort',
    CAST(0x0101 AS VARBINARY(4))
UNION ALL
SELECT 'Different Lengths Sort',
    CAST(0x010101 AS VARBINARY(4))
ORDER BY BinaryValue;
GO

-- Sort with NULL values
SELECT 'NULL Values Sort' AS Test,
    CAST(NULL AS VARBINARY(2)) AS BinaryValue
UNION ALL
SELECT 'NULL Values Sort',
    CAST(0x00 AS VARBINARY(2))
UNION ALL
SELECT 'NULL Values Sort',
    CAST(0x01 AS VARBINARY(2))
ORDER BY BinaryValue;
GO

-- Sort with same prefix, different endings
SELECT 'Same Prefix Sort' AS Test,
    CAST(0x0100 AS VARBINARY(4)) AS BinaryValue
UNION ALL
SELECT 'Same Prefix Sort',
    CAST(0x0101 AS VARBINARY(4))
UNION ALL
SELECT 'Same Prefix Sort',
    CAST(0x01FF AS VARBINARY(4))
ORDER BY BinaryValue;
GO

-- Sort with hex values
SELECT 'Hex Values Sort' AS Test,
    CAST(0xAA AS VARBINARY(2)) AS BinaryValue
UNION ALL
SELECT 'Hex Values Sort',
    CAST(0xBB AS VARBINARY(2))
UNION ALL
SELECT 'Hex Values Sort',
    CAST(0xCC AS VARBINARY(2))
ORDER BY BinaryValue;
GO

-- Sort with mixed case hex (should be same)
SELECT 'Mixed Case Hex Sort' AS Test,
    CAST(0xAA AS VARBINARY(2)) AS BinaryValue
UNION ALL
SELECT 'Mixed Case Hex Sort',
    CAST(0xaa AS VARBINARY(2))
UNION ALL
SELECT 'Mixed Case Hex Sort',
    CAST(0xAa AS VARBINARY(2))
ORDER BY BinaryValue;
GO

-- Sort with empty and non-empty values
SELECT 'Empty Values Sort1' AS Test,
    CAST(0x AS VARBINARY(4)) AS BinaryValue
UNION ALL
SELECT 'Empty Values Sort2',
    CAST(0x00 AS VARBINARY(4))
UNION ALL
SELECT 'Empty Values Sort',
    CAST(0x0001 AS VARBINARY(4))
ORDER BY BinaryValue, Test;
GO

-- Sort with repeated values
SELECT 'Repeated Values Sort' AS Test,
    CAST(0x0101 AS VARBINARY(4)) AS BinaryValue
UNION ALL
SELECT 'Repeated Values Sort',
    CAST(0x0101 AS VARBINARY(4))
UNION ALL
SELECT 'Repeated Values Sort',
    CAST(0x0102 AS VARBINARY(4))
ORDER BY BinaryValue;
GO

-- Sort with binary zeros in different positions
SELECT 'Zero Position Sort' AS Test,
    CAST(0x0100 AS VARBINARY(4)) AS BinaryValue
UNION ALL
SELECT 'Zero Position Sort',
    CAST(0x0010 AS VARBINARY(4))
UNION ALL
SELECT 'Zero Position Sort',
    CAST(0x0001 AS VARBINARY(4))
ORDER BY BinaryValue;
GO

-- Sort mixing BINARY and VARBINARY
SELECT 'Mixed Type Sort' AS Test,
    CAST(0x01 AS BINARY(2)) AS BinaryValue
UNION ALL
SELECT 'Mixed Type Sort',
    CAST(0x01 AS VARBINARY(2))
UNION ALL
SELECT 'Mixed Type Sort',
    CAST(0x0100 AS VARBINARY(2))
ORDER BY BinaryValue;
GO

-- Sort with trailing zeros
SELECT 'Trailing Zeros Sort' AS Test,
    CAST(0x0100 AS VARBINARY(4)) AS BinaryValue
UNION ALL
SELECT 'Trailing Zeros Sort',
    CAST(0x01 AS VARBINARY(4))
UNION ALL
SELECT 'Trailing Zeros Sort',
    CAST(0x0100 AS VARBINARY(4))
ORDER BY BinaryValue;
GO

-- Sort with leading zeros
SELECT 'Leading Zeros Sort' AS Test,
    CAST(0x0001 AS VARBINARY(4)) AS BinaryValue
UNION ALL
SELECT 'Leading Zeros Sort',
    CAST(0x0100 AS VARBINARY(4))
UNION ALL
SELECT 'Leading Zeros Sort',
    CAST(0x1000 AS VARBINARY(4))
ORDER BY BinaryValue;
GO
