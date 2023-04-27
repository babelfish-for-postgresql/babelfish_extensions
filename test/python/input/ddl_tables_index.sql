/* This test files will check for scripting of tables with constraints including check , primary keys, foreign keys , NULL , unique and  single , composite indexes */

DROP TABLE IF EXISTS table_check
GO
DROP TABLE IF EXISTS table_foreign 
GO
DROP TABLE IF EXISTS table_primary
GO
DROP TABLE IF EXISTS table_unique
GO
DROP TABLE IF EXISTS isc_check_constraints_t1
GO
DROP TABLE IF EXISTS test_tsql_const
GO
DROP TABLE IF EXISTS test_tsql_cast
GO
DROP TABLE IF EXISTS test_datetime
GO
DROP TABLE IF EXISTS test_functioncall
GO
DROP TABLE IF EXISTS test_tsql_collate
GO
DROP TABLE IF EXISTS test_null
GO
DROP TABLE IF EXISTS test_upper
GO
Create table table_unique (a int NOT NULL UNIQUE)
GO
Create table table_primary (a int NOT NULL , b int NOT NULL,c int, PRIMARY KEY(a) )
GO
Create table table_foreign (aa int NOT NULL , bb int NOT NULL,a int, PRIMARY KEY(aa) ,FOREIGN KEY (a) REFERENCES table_primary(a))
GO
Create table table_check (ID int NOT NULL,NAME varchar(10)  NOT NULL,AGE int NOT NULL CHECK (AGE >= 18))
GO
Create table isc_check_constraints_t1( a varchar, check(a = 'provvwstdjtlyzygsx'));
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
Create table test_null(a int, b int, check(a IS NOT NULL), CONSTRAINT constraint1 check (a>10));
GO
Create table test_upper(a char, check (upper(a) in ('A','B')));
GO
Create index test_index on test_upper(a)
GO
Create index test_comp_index on table_unique(a)
GO
--DROP

DROP TABLE IF EXISTS table_check
GO
DROP TABLE IF EXISTS table_foreign 
GO
DROP TABLE IF EXISTS table_primary
GO
DROP TABLE IF EXISTS table_unique
GO
DROP TABLE IF EXISTS isc_check_constraints_t1
GO
DROP TABLE IF EXISTS test_tsql_const
GO
DROP TABLE IF EXISTS test_tsql_cast
GO
DROP TABLE IF EXISTS test_tsql_collate
GO
DROP TABLE IF EXISTS test_datetime
GO
DROP TABLE IF EXISTS test_functioncall
GO
DROP TABLE IF EXISTS test_null
GO
DROP TABLE IF EXISTS test_upper
GO