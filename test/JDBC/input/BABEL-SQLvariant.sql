
--[BABEL-582]Checking all base datatypes for sql_variant
--The following list of base datatypes cannot be stored by using sql_variant:
--[datetimeoffset(SQL server 2012), geography, geometry, hierarchyid, image, ntext, nvarchar(max),
--rowversion (timestamp), text, varchar(max), varbinary(max), User-defined types, xml]

DROP TABLE IF EXISTS sourceTable;
go
DROP TABLE IF EXISTS destinationTable;
go
Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast (1 as BIT),cast (1 as BIT));
go
Insert into sourceTable values (cast (NULL as BIT), cast (0 as BIT));
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go


Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast (0 as TINYINT),cast (10 as TINYINT));
go
Insert into sourceTable values (cast (002 as TINYINT),cast (029 as TINYINT));
go
Insert into sourceTable values (cast (004 as TINYINT),cast (87 as TINYINT));
go
Insert into sourceTable values (cast (255 as TINYINT),cast (1000 as TINYINT));
go
Insert into sourceTable values (cast (NULL as TINYINT), cast (100 as TINYINT));
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go


Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast (0 as SMALLINT),cast (-10 as SMALLINT));
go
Insert into sourceTable values (cast (002 as SMALLINT),cast (-029 as SMALLINT));
go
Insert into sourceTable values (cast (876 as SMALLINT),cast (-1234 as SMALLINT));
go
Insert into sourceTable values (cast (-32768 as SMALLINT),cast (32767 as SMALLINT));
go
Insert into sourceTable values (cast (NULL as SMALLINT), cast (100 as SMALLINT));
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go



Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast (0 as INT),cast (-10 as INT));
go
Insert into sourceTable values (cast (-12345 as INT),cast (10 as INT));
go
Insert into sourceTable values (cast (004 as INT),cast (224466 as INT));
go
Insert into sourceTable values (cast (-2147483648 as INT),cast (2147483647 as INT));
go
Insert into sourceTable values (cast (NULL as INT), cast (100 as INT));
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go



Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast (0 as BIGINT),cast (-120 as BIGINT));
go
Insert into sourceTable values (cast (-12345 as BIGINT),cast (00100 as BIGINT));
go
Insert into sourceTable values (cast (-12245532534 as BIGINT),cast (00000000000000086 as BIGINT));
go
Insert into sourceTable values (cast (-9223372036854775808 as BIGINT),cast (9223372036854775807 as BIGINT));
go
Insert into sourceTable values (cast (NULL as BIGINT), cast (-004 as BIGINT));
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go


Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast (0 as REAL),cast (1.050 as REAL));
go
Insert into sourceTable values (cast (-004 as REAL),cast (01.05 as REAL));
go
Insert into sourceTable values (cast (00000000000000086 as REAL),cast (-0122455324.5 as REAL));
go
Insert into sourceTable values (cast (3.40E+38 as REAL),cast (-3.40E+38 as REAL));
go
Insert into sourceTable values (cast (NULL as REAL), cast (-000002 as REAL));
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go


Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast (0 as FLOAT),cast (1.050 as FLOAT));
go
Insert into sourceTable values (cast (-0012345234.5 as FLOAT),cast (01.05 as FLOAT));
go
Insert into sourceTable values (cast (00000000000086 as FLOAT),cast (-00000002 as FLOAT));
go
Insert into sourceTable values (cast (-1.79E+308 as FLOAT),cast (1.79E+308 as FLOAT));
go
Insert into sourceTable values (cast (NULL as FLOAT), cast (100 as FLOAT));
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go


CREATE TABLE money_dt(a sql_variant, b sql_variant);
go
prepst#!#INSERT INTO money_dt(a, b) VALUES (@a, @b) #!#smallmoney|-|a|-|100.5#!#money|-|b|-|10.05
go
prepst#!#exec#!#smallmoney|-|a|-|10#!#money|-|b|-|10
go
prepst#!#exec#!#smallmoney|-|a|-|-10.05 #!#money|-|b|-|-10.0
go
prepst#!#exec#!#smallmoney|-|a|-|-214748.3648#!#money|-|b|-|-922337203685477.5808
go
prepst#!#exec#!#smallmoney|-|a|-|214748.3647#!#money|-|b|-|22337203685477.5807
go
prepst#!#exec#!#smallmoney|-|a|-|214748.3647#!#money|-|b|-|22337203685477.5807
go
prepst#!#exec#!#smallmoney|-|a|-|-214,748.3648#!#money|-|b|-|-922,337,203,685,477.5808
go
prepst#!#exec#!#smallmoney|-|a|-|214,748.3647#!#money|-|b|-|922,337,203,685,477.5807
go
prepst#!#exec#!#smallmoney|-|a|-|214,748.3647#!#money|-|b|-|922,337,203,685,477.5807
go
prepst#!#exec#!#smallmoney|-|a|-|<NULL>#!#money|-|b|-|<NULL>
go
SELECT * FROM money_dt;
go
DROP TABLE money_dt;
go

Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast (0 as MONEY),cast ('$1050' as MONEY));
go
Insert into sourceTable values (cast (NULL as MONEY), cast (-000002 as MONEY));
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go


Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast (0 as SMALLMONEY),cast ('$1050' as SMALLMONEY));
go
Insert into sourceTable values (cast (NULL as SMALLMONEY), cast (-000002 as SMALLMONEY));
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go



Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
INSERT INTO sourceTable values(CAST('2000-12-13' as DATE), CAST('1900-02-28' as DATE))
go
INSERT INTO sourceTable values(CAST(NULL as DATE), CAST('0001-01-01' as DATE))
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go



Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
INSERT INTO sourceTable values(CAST('2007-05-08 12:35:29' as SMALLDATETIME), CAST('2007-05-08 12:35:30' as SMALLDATETIME))
go
INSERT INTO sourceTable values(CAST('2007-05-08 12:59:59.998' as SMALLDATETIME), CAST('2000-02-28 23:59:59.999' as SMALLDATETIME))
go
INSERT INTO sourceTable values(CAST('1900-02-28 23:59:59.999' as SMALLDATETIME), CAST('2000-02-28 23:45:29.999' as SMALLDATETIME))
go
INSERT INTO sourceTable values(CAST(NULL as SMALLDATETIME), CAST('1900-01-01 00:00:00' as SMALLDATETIME))
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go




Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
INSERT INTO sourceTable values(CAST('2000-12-13 12:58:23.123' as DATETIME), CAST('1900-02-28 23:59:59.989' as DATETIME))
go
INSERT INTO sourceTable values(CAST('1900-02-28 23:59:59.990' as DATETIME), CAST('1900-02-28 23:59:59.992' as DATETIME))
go
INSERT INTO sourceTable values(CAST('1900-02-28 23:59:59.994' as DATETIME), CAST('1900-02-28 23:59:59.996' as DATETIME))
go
INSERT INTO sourceTable values(CAST('1900-02-28 23:59:59.998' as DATETIME), CAST('1753-01-01 00:00:00.000' as DATETIME))
go
INSERT INTO sourceTable values(CAST(NULL as DATETIME), CAST('9999-12-31 23:59:59.997' as DATETIME))
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go


Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast ('Satarupa' as CHAR(24)),cast ('    Satarupa' as CHAR(24)));
go
Insert into sourceTable values (cast ('' as CHAR(24)),cast ('   S,B' as CHAR(24)));
go
Insert into sourceTable values (cast (NULL as CHAR(24)), cast ('  ' as CHAR(24)));
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go



Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast ('Satarupa' as NCHAR(24)),cast ('    Satarupa' as NCHAR(24)));
go
Insert into sourceTable values (cast ('' as NCHAR(24)),cast ('   S,B' as NCHAR(24)));
go
INSERT INTO sourceTable  values(cast (' dthdcjdfjwf dwfw fgegegeg' as NCHAR(24)), cast ('😊😋😎😍😅😆' as NCHAR(24)))
go
Insert into sourceTable values (cast (NULL as NCHAR(24)), cast ('  ' as NCHAR(24)));
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go



Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast ('Satarupa' as NVARCHAR(24)),cast ('    Satarupa' as NVARCHAR(24)));
go
Insert into sourceTable values (cast ('' as NVARCHAR(24)),cast ('   S,B' as NVARCHAR(24)));
go
INSERT INTO sourceTable  values(cast (' dthdcjdfjwf dwfw fgegegeg' as NVARCHAR(24)), cast ('😊😋😎😍😅😆' as NVARCHAR(24)))
go
Insert into sourceTable values (cast (NULL as NVARCHAR(24)), cast ('  ' as NVARCHAR(24)));
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go




Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
INSERT INTO sourceTable values(CAST('51f178a6-53c7-472c-9be1-1c08942342d7' as uniqueidentifier), CAST('bab96bc8-60b9-40dd-b0de-c90a80f5739e' as uniqueidentifier)) 
go
INSERT INTO sourceTable values(CAST('dba2726c-2131-409f-aefa-5c8079571623' as uniqueidentifier), CAST('51f178a6-53c7-472c-9be1-1c08942342d7thisIsTooLong' as uniqueidentifier)) 
go
INSERT INTO sourceTable values(NULL, CAST('60aeaa5c-e272-4b17-bad0-c25710fd7a60' as uniqueidentifier)) 
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go

Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast ('Delhi' as VARCHAR(24)),cast ('    Surat' as VARCHAR(24)));
go
Insert into sourceTable values (cast ('' as VARCHAR(24)),cast ('   S,B' as VARCHAR(24)));
go
Insert into sourceTable values (cast (NULL as VARCHAR(24)), cast ('  ' as VARCHAR(24)));
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go

Create table sourceTable(a sql_variant, b sql_variant not null);
go
Create table destinationTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast ('Delhi' as char(24)),cast ('    Surat' as char(24)));
go
Insert into sourceTable values (cast ('' as char(24)),cast ('   S,B' as char(24)));
go
Insert into sourceTable values (cast (NULL as char(24)), cast ('  ' as char(24)));
go
insertbulk#!#sourceTable#!#destinationTable
go
Select * from sourceTable;
go
Select * from destinationTable;
go
drop table sourceTable;
go
drop table destinationTable;
go

Create table sourceTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast (123.456 as numeric(5,2)), cast (123.4 as numeric(5,2)));
go
Insert into sourceTable values (cast (NULL as numeric(5,2)), cast (123 as numeric(5,2)));
go
Insert into sourceTable values (cast (-123.456 as numeric(5,2)), cast (-123 as numeric(5,2)));
go
Select * from sourceTable;
go
drop table sourceTable;
go

Create table sourceTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast (123.456 as decimal(5,2)), cast (123.4 as decimal(5,2)));
go
Insert into sourceTable values (cast (NULL as decimal(5,2)), cast (123 as decimal(5,2)));
go
Insert into sourceTable values (cast (-123.456 as decimal(5,2)), cast (-123 as decimal(5,2)));
go
Select * from sourceTable;
go
drop table sourceTable;
go


Create table sourceTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast ('12:45:37.123' as time(0)), cast ('12:45:37.123' as time(1)));
go
Insert into sourceTable values (cast (NULL as time(3)), cast ('12:45:37.123' as time(2)));
go
Insert into sourceTable values (cast ('12:45:37.123' as time(3)), cast ('12:45:37.1234' as time(4)));
go
Insert into sourceTable values (cast ('12:45:37.12345' as time(5)), cast ('12:45:37.123456' as time(6)));
go
Select * from sourceTable;
go
drop table sourceTable;
go


Create table sourceTable(a sql_variant, b sql_variant not null);
go
Insert into sourceTable values (cast ('2016-10-23 12:45:37.123' as datetime2(0)), cast ('2016-10-23 12:45:37.123' as datetime2(1)));
go
Insert into sourceTable values (cast (NULL as datetime2(3)), cast ('2016-10-23 12:45:37.123' as datetime2(2)));
go
Insert into sourceTable values (cast ('2016-10-23 12:45:37.123' as datetime2(3)), cast ('2016-10-23 12:45:37.1234' as datetime2(4)));
go
Insert into sourceTable values (cast ('2016-10-23 12:45:37.12345' as datetime2(5)), cast ('2016-10-23 12:45:37.123456' as datetime2(6)));
go
Select * from sourceTable;
go
drop table sourceTable;
go
