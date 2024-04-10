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
DROP TABLE IF EXISTS babel_4817_t1, babel_4817_t2, babel_4817_t3, babel_4817_t4, babel_4817_t5;
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

CREATE TABLE babel_4817_t1 (col1 INT, col2 INT NOT NULL, col3 AS col1*col2, col4 INT, col5 INT, col6 INT, col7 INT, col8 INT NOT NULL, PRIMARY KEY NONCLUSTERED(col3, col7 DESC), UNIQUE (col2 DESC, col8));
GO
CREATE INDEX babel_4817_t1_idx_1 ON dbo.babel_4817_t1 (col5) INCLUDE (col1);
GO

CREATE TABLE babel_4817_t2 (col1 INT, col2 INT NOT NULL, col3 AS col1*col2, col4 INT, col5 INT, col6 INT, col7 INT NOT NULL IDENTITY, col8 INT NOT NULL)
GO
ALTER TABLE babel_4817_t2 ADD CONSTRAINT babel_4817_t2_pk PRIMARY KEY NONCLUSTERED (col3, col7);
GO
CREATE UNIQUE NONCLUSTERED INDEX babel_4817_t2_unique_index ON dbo.babel_4817_t2 (col2 DESC, col8) INCLUDE (col4);
GO
CREATE NONCLUSTERED INDEX babel_4817_t2_idx ON dbo.babel_4817_t2 (col5) INCLUDE (col1);
GO
CREATE TABLE babel_4817_t3 (col1 INT IDENTITY, col2 INT, col3 INT, col4 INT, col5 AS col1*col2, col6 VARCHAR(30))
GO
ALTER TABLE babel_4817_t3 DROP COLUMN col4
GO
ALTER TABLE babel_4817_t3 ADD col4 INT
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[babel_4817_t4](
    [id] [int] NULL,
    [filename] [varchar](200) NOT NULL,
    [commited_dt] [datetime] NOT NULL,
    [commited_sql] [ntext] NULL,
PRIMARY KEY CLUSTERED 
(
    [filename] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE TABLE [dbo].[babel_4817_t5]
(
  [id] [int] NOT NULL,
  [filename] [varchar](200) NOT NULL,
  [commited_dt] [datetime] NOT NULL,
  [commited_sql] [ntext] NULL,
  PRIMARY KEY CLUSTERED
(
              [filename] ASC, [ID] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX ix_test ON [dbo].[babel_4817_t5] ([filename]) INCLUDE ([id],[commited_dt])
GO

--DROP

DROP TABLE IF EXISTS babel_4817_3, babel_4817_4;
GO
DROP TABLE IF EXISTS babel_4817_t1, babel_4817_t2, babel_4817_t3, babel_4817_t4, babel_4817_t5;
GO
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