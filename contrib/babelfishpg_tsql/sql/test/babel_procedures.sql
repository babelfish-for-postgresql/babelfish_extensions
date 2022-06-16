CREATE EXTENSION IF NOT EXISTS "babelfishpg_tsql";

-- test sp_unprepare
create table t1 ( a int );
insert into t1 values (1);
insert into t1 values (2);

prepare s_100 (int) as select * from t1 where a = $1;
execute s_100(1);

set babelfishpg_tsql.sql_dialect = "tsql";

call sp_unprepare(null);
call sp_unprepare(10);
call sp_unprepare(100);

execute s_100(1);

\tsql on

-- Test 'with' in procedure language that shouldn't be recognized as CTE
create or replace procedure prc1 as begin
select count(*) from t1 with (tablockx)
end
go

call prc1();
go

create or replace procedure prc2 as begin
insert into t1 select * from t1 with (tablockx);
end
go

call prc2();
go

-- Test C-style comment with a following '@'
create procedure prc3
/* comment */
@p int
as 
select 123;
go

-- BABEL-831
CREATE PROCEDURE babel_831_proc
AS
BEGIN
        CREATE TABLE #t(id INT)
        DECLARE Babel831Cursor CURSOR FOR SELECT id FROM #t
        OPEN Babel831Cursor
        CLOSE Babel831Cursor
END
GO

exec babel_831_proc
GO

--BABEL-1099
CREATE TABLE babel_1099_t1 (a int);
CREATE TABLE babel_1099_t2 (a int);
CREATE PROCEDURE babel_1099_proc AS
    TRUNCATE TABLE babel_1099_t1
    TRUNCATE TABLE babel_1099_t2
GO

EXEC babel_1099_proc
GO

\tsql off

drop table t1;
drop table babel_1099_t1;
drop table babel_1099_t2;
drop procedure prc1;
drop procedure prc2;
drop procedure prc3;
drop procedure babel_831_proc;
drop procedure babel_1099_proc;