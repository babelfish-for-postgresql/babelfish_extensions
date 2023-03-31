DROP VIEW IF EXISTS sys_all_views_select_vu_prepare
GO
DROP VIEW IF EXISTS sys_all_views_select_chk_option_vu_prepare
GO
DROP TABLE IF EXISTS sys_all_views_table_vu_prepare
GO
DROP TRIGGER IF EXISTS babel_1654_vu_prepare_trig_t
GO
DROP TABLE IF EXISTS babel_1654_vu_prepare_t 
GO
drop  procedure IF EXISTS routines_test_nvar;
go
drop  function  IF EXISTS routines_fc1;
go
drop  function  IF EXISTS routines_fc2;
go
drop  function  IF EXISTS routines_fc3;
go
drop  function  IF EXISTS routines_fc4;
go
drop  function  IF EXISTS routines_fc5;
go
drop  function  IF EXISTS routines_fc6;
go
DROP TABLE IF EXISTS test_tsql_const
GO
DROP TABLE IF EXISTS test_datetime
GO
DROP TABLE IF EXISTS test_tsql_collate
GO

Create table test_tsql_const(
    c_int int primary key,
    c_bit sys.bit check(c_bit <> cast(1 as sys.bit)),
    check(c_int < 10),
    c_smallint smallint check(c_smallint < cast(cast(CAST('20' AS smallint) as sql_variant) as smallint)),
    c_binary binary(8) check(c_binary > cast(0xfe as binary(8))),
    c_varbinary varbinary(8) check(c_varbinary > cast(0xfe as varbinary(8)))
)
GO
Create table test_datetime(
    c_time time check(cast(c_time as pg_catalog.time) < cast('09:00:00' as time) and c_time < cast('09:00:00' as time(6))),
    c_date date check(c_date < cast('2001-01-01' as date)),
    c_datetime datetime check(c_datetime < cast('2020-10-20 09:00:00' as datetime)),
    c_datetime2 datetime2 check(c_datetime2 < cast('2020-10-20 09:00:00' as datetime2) and c_datetime2 < cast('2020-10-20 09:00:00' as datetime2(6)) ),
    c_datetimeoffset datetimeoffset check(c_datetimeoffset < cast('12-10-25 12:32:10 +01:00' as sys.datetimeoffset) and c_datetimeoffset < cast('12-10-25 12:32:10 +01:00' as datetimeoffset(4))),
    c_smalldatetime smalldatetime check(c_smalldatetime < cast('2007-05-08 12:35:29.123' AS smalldatetime)),
)
GO
create table test_tsql_collate(
	c_varchar varchar check(c_varchar <> cast('sflkjasdlkfjf' as varchar(12)) COLLATE latin1_general_ci_as),
	c_char char check(c_char <> cast('sflkjasdlkfjf' as char(7)) COLLATE japanese_ci_as),
	c_nchar nchar check(cast(c_nchar as nchar(7)) <> cast('sflkjasdlkfjf' as nchar(7)) COLLATE bbf_unicode_cp1_ci_as),
)
GO

create procedure routines_test_nvar(@test_nvar_a nvarchar , @test_nvar_b int = 8)
AS
BEGIN
        SELECT @test_nvar_b=8;
END
go
create function routines_fc1(@fc1_a nvarchar) RETURNS nvarchar AS BEGIN return @fc1_a END;
go
create function routines_fc2(@fc2_a varchar) RETURNS varchar AS BEGIN return @fc2_a END;
go
create function routines_fc3(@fc3_a nchar) RETURNS nchar AS BEGIN return @fc3_a END;
go
create function routines_fc4(@fc4_a binary, @fc4_b tinyint, @fc4_c BIGINT, @fc4_d float) RETURNS binary AS BEGIN return @fc4_a END;
go
create function routines_fc5(@fc5_a varbinary) RETURNS varbinary AS BEGIN return @fc5_a END;
go
create function routines_fc6(@fc6_a char) RETURNS char AS BEGIN return @fc6_a END;
go

create table babel_1654_vu_prepare_t ( ID INT IDENTITY (1,1) PRIMARY KEY , a varchar(50), b varchar(50))
GO

CREATE TRIGGER babel_1654_vu_prepare_trig_t on babel_1654_vu_prepare_t after update as
	select COLUMNS_UPDATED();
GO

CREATE TABLE sys_all_views_table_vu_prepare(a int)
GO
CREATE VIEW sys_all_views_select_vu_prepare AS
SELECT * FROM sys_all_views_table_vu_prepare
GO
CREATE VIEW sys_all_views_select_chk_option_vu_prepare AS
SELECT * FROM sys_all_views_table_vu_prepare
WITH CHECK OPTION
GO

--DROP

DROP VIEW IF EXISTS sys_all_views_select_vu_prepare
GO
DROP VIEW IF EXISTS sys_all_views_select_chk_option_vu_prepare
GO
DROP TABLE IF EXISTS sys_all_views_table_vu_prepare
GO
DROP TRIGGER IF EXISTS babel_1654_vu_prepare_trig_t
GO
DROP TABLE IF EXISTS babel_1654_vu_prepare_t 
GO
drop  procedure IF EXISTS routines_test_nvar;
go
drop  function  IF EXISTS routines_fc1;
go
drop  function  IF EXISTS routines_fc2;
go
drop  function  IF EXISTS routines_fc3;
go
drop  function  IF EXISTS routines_fc4;
go
drop  function  IF EXISTS routines_fc5;
go
drop  function  IF EXISTS routines_fc6;
go
DROP TABLE IF EXISTS test_tsql_const
GO
DROP TABLE IF EXISTS test_datetime
GO
DROP TABLE IF EXISTS test_tsql_collate
GO
