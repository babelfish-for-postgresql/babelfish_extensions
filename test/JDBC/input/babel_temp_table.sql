-- Basic temp table create/insert/select using tsql dialect
CREATE TABLE #local_tempt(col int);
INSERT INTO #local_tempt VALUES (1);
SELECT * FROM #local_tempt;
GO

-- Implicitly creating temp tables

DROP TABLE IF EXISTS t1;
GO
CREATE TABLE t1 (col int);
INSERT INTO t1 values (1);
INSERT INTO t1 values (NULL);
SELECT * INTO #local_tempt2 FROM t1;
GO
SELECT * FROM #local_tempt2;
GO

-- Implicitly creating temp tables in procedure
CREATE PROCEDURE temp_table_sp AS
BEGIN
	SELECT * INTO #tt_sp_local FROM t1;
	INSERT INTO #tt_sp_local VALUES(2);
END;
GO

EXEC temp_table_sp;
GO

-- BABEL-903: create temp table named #[digit][string]
create procedure babel903 AS
BEGIN
	create table #904 (a int);
	select col into #904tt from t1;
	insert into #904 values(1);
	insert into #904tt values(1);
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
GO

-- index should be dropped
CREATE procedure temp_table_sp_index AS
BEGIN
	  CREATE TABLE #tt (a int);
	  CREATE INDEX i_a ON tt (a);
END;
GO

EXEC temp_table_sp_index;
GO

SELECT * FROM pg_indexes WHERE tablename LIKE 'tt%'; -- should be no result
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
select * from #tt_con;
go

-- temp table created in sp_executesql behaves like in procedure too
CREATE procedure temp_table_sp_exec AS
BEGIN
	DECLARE @SQLString NVARCHAR(500);
	SET @SQLString = N'create table #tt_spexec(a int)';
	CREATE TABLE #tt_spexec (a int);
	EXECUTE sp_executesql @SQLString;
	insert into #tt_spexec values (1);
END;
GO
exec temp_table_sp_exec
go
drop table #tt_spexec; -- already dropped
go
drop procedure temp_table_sp_exec
go

-- BABEL-322: '#' in column name is allowed in tsql

CREATE TABLE #babel322(#col int, ##col int);
GO
DROP TABLE #babel322;
GO

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
DROP PROCEDURE temp_table_sp_index;
GO
DROP PROCEDURE temp_table_sp_alter;
GO
DROP PROCEDURE temp_table_sp_constraint;
GO
DROP TABLE t1;
GO
