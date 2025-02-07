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
