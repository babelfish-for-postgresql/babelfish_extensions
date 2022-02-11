USE master
GO

--
-- Tests for T-SQL style temp tables
--

-- Basic temp table create/insert/select using tsql dialect

CREATE TABLE #local_tempt(col int);
GO

INSERT INTO #local_tempt VALUES (1);
GO

SELECT * FROM #local_tempt;
GO

CREATE TABLE ##global_tempt(col int);
GO

CREATE SCHEMA temp_tables_test;
GO

CREATE TABLE temp_tables_test.#local_tempt_withschema(col int);
GO

INSERT INTO temp_tables_test.#local_tempt_withschema VALUES (1);
GO

SELECT * FROM temp_tables_test.#local_tempt_withschema;
GO

DROP SCHEMA temp_tables_test;
GO

-- various catalog/schema cases
CREATE TABLE non_exist_db..#tt(a int)
GO
DROP TABLE #tt
GO

CREATE TABLE non_exist_schema.#tt(a int)
GO
DROP TABLE #tt
GO

CREATE TABLE .#tt(a int)
GO
DROP TABLE #tt
GO

CREATE TABLE ..#tt(a int)
GO
DROP TABLE #tt
GO

-- Implicitly creating temp tables

CREATE TABLE tt_test_t1 (col int);
GO

INSERT INTO tt_test_t1 values (1);
GO

INSERT INTO tt_test_t1 values (NULL);
GO

SELECT * INTO #local_tempt2 FROM tt_test_t1;
GO

SELECT * FROM #local_tempt2;
GO

-- Implicitly creating temp tables in procedure

CREATE PROCEDURE temp_table_sp AS
BEGIN
    SELECT * INTO #tt_sp_local FROM tt_test_t1;
    INSERT INTO #tt_sp_local VALUES(2);
END;
GO

EXEC temp_table_sp;
GO

-- BABEL-903: create temp table named #[digit][string]
create procedure babel903 AS
BEGIN
    create table #903 (a int);
    select col into #903tt from tt_test_t1;
    insert into #903 values(1);
    insert into #903tt values(1);
END
GO

exec babel903;
GO

-- BABEL-904: drop temp table
CREATE PROCEDURE babel904 AS
BEGIN
    create table #t (a int);
    create table #tt (a int);
    drop table #t;
    drop table #tt;
END
go

exec babel904;
GO

-- Visibility tests

create table #tt (a int);
go
insert into #tt values(0);
go

CREATE procedure temp_table_nested_sp_1st AS
BEGIN
    CREATE TABLE #tt_1st (a int);
    insert into #tt values(1);
    insert into #tt_1st values(1);
    insert into #tt_2nd values(1);
    insert into #tt_3rd values(1);
END;
GO

CREATE procedure temp_table_nested_sp_2nd AS
BEGIN
    CREATE TABLE #tt_2nd (a int);
	EXEC temp_table_nested_sp_1st;
    insert into #tt values(2);
    insert into #tt_2nd values(2);
    insert into #tt_3rd values(2);
END;
GO

CREATE procedure temp_table_nested_sp_3rd AS
BEGIN
    CREATE TABLE #tt_3rd (a int);
    EXEC temp_table_nested_sp_2nd;
    insert into #tt values(3);
    insert into #tt_3rd values(3);
END;
GO

EXEC temp_table_nested_sp_3rd;
GO

-- should fail to find these tables
select * from #tt_1st; 
go
select * from #tt_2nd;
go
select * from #tt_3rd;
go
-- This should print 0, 1, 2 and 3
select * from #tt; 
go

DROP PROCEDURE temp_table_nested_sp_1st;
go
DROP PROCEDURE temp_table_nested_sp_2nd;
go
DROP PROCEDURE temp_table_nested_sp_3rd;
go
DROP TABLE #tt;
go

-- creating temp tables with duplicated names.
create table #tt (a int);
go
insert into #tt values(1);
go

CREATE procedure temp_table_nested_sp_inner AS
BEGIN
    CREATE TABLE #tt (a int); -- same name as the top-level, allowed
    CREATE TABLE #tt_sp_outer (a int); -- same name as the outer procedure, allowed
    insert into #tt values(3);
END;
GO

CREATE procedure temp_table_nested_sp_outer AS
BEGIN
    CREATE TABLE #tt (a int); -- same name as the top-level, allowed
    CREATE TABLE #tt_sp_outer (a int);
    insert into #tt values(2);
    EXEC temp_table_nested_sp_inner;
END;
GO

EXEC temp_table_nested_sp_outer;
go
select * from #tt; -- should only print value '1'
go
drop table #tt;
go

-- procedure with exception
CREATE procedure temp_table_sp_exception AS
BEGIN
  CREATE TABLE #tt (a int);
  CREATE TABLE #tt (a int); -- throws error
END;
GO
EXEC temp_table_sp_exception;
GO
select * from #tt; -- can't find the table
go

-- drop/alter tables
CREATE procedure temp_table_sp_alter AS
BEGIN
   CREATE TABLE #tt (a int);
   CREATE TABLE #tt2 (a int);
   DROP TABLE #tt2;
   ALTER TABLE #tt ADD b char;
   insert into #tt values(1, 'x');
END;
GO

EXEC temp_table_sp_alter;
GO

-- constraints

create table #tt_con(a int CHECK (a > 10));
go
insert into #tt_con values(1); -- errorneous
go
CREATE PROCEDURE temp_table_sp_constraint AS
BEGIN
    create table #tt (a int CHECK (a > 10));
    insert into #tt values(11);
    insert into #tt_con(a) select a from #tt;
END
go
exec temp_table_sp_constraint;
go
select * from #tt_con; -- should print 11
go

-- statistic

create table #tt_stat(a int, b int);
go
insert into #tt_stat values(1, 2);
go
-- valid T-SQL create-statitstics is not supported yet
--CREATE STATISTICS s1 on #tt_stat(a, b);
--go
drop table #tt_stat;
go

-- BABEL-322: '#' in column name is allowed in tsql

CREATE TABLE #babel322(#col int, ##col int);
GO
DROP TABLE #babel322;
GO

-- BABEL-1637: rollback within procedure makes top-level temp table gone
create proc sp_babel1637 as 
  create table #tt_1637 (a int) 
  begin tran 
	insert into #tt_1637 values (123) 
  rollback 
  select * from #tt_1637
go
create table #tt_1637 (a int)
insert into #tt_1637 values (456)
select * from #tt_1637
go
exec sp_babel1637
go
select * from #tt_1637
go
drop table #tt_1637
go

-- cleanup

DROP PROCEDURE temp_table_sp;
GO
DROP PROCEDURE babel903;
GO
DROP PROCEDURE babel904;
GO
DROP PROCEDURE temp_table_nested_sp_inner;
GO
DROP PROCEDURE temp_table_nested_sp_outer;
GO
DROP PROCEDURE temp_table_sp_exception;
GO
DROP PROCEDURE temp_table_sp_alter;
GO
DROP PROCEDURE temp_table_sp_constraint;
GO
DROP TABLE tt_test_t1;
GO
