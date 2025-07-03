create table t1 (a int);
GO
insert into t1 values (1);
GO
create table t2 (a int);
GO

-- procedure with SELECT
create procedure sp_multi_selects as
select * from t1;
select a from t1;
go
-- normal execute
execute sp_multi_selects;
go
-- insert execute
select * from t2;
go
insert into t2 execute sp_multi_selects;
go
select * from t2;
go
-- insert execute a second time
insert into t2 execute sp_multi_selects;
go
select * from t2;
go

-- column mismatch
create table t3(a int, b int, c int);
GO
insert into t3 execute sp_multi_selects;
GO
select * from t3;
GO
-- INSERT with matching column list
insert into t3 (a) execute sp_multi_selects;
GO
select * from t3;
GO

-- DML statements in procedure
create procedure sp_dml_select as
insert into t1 values(2);
update t1 set a = 3 where a = 2;
delete t1 where a = 3;
select * from t1;
GO
select * from t1;
GO
-- normal EXECUTE - each DML should send result to client
execute sp_dml_select;
GO
-- INSERT EXECUTE - only final INSERT should send result to client
insert into t2 execute sp_dml_select;
GO

-- DDL statements in procedure
create procedure sp_ddl_select as
create table sp_ddl_select_table(c int);
select * from sp_ddl_select_table;
drop table sp_ddl_select_table;
GO
-- normal EXECUTE
execute sp_ddl_select;
GO
-- INSERT EXECUTE
insert into t2 execute sp_ddl_select;
GO

-- test using OUTPUT clause in INSERT EXECUTE
insert into t2 output inserted.* into t3.a exec sp_multi_selects;
GO

-- COMMIT with no BEGIN TRAN
create procedure sp_commit_no_begin as
insert into t1 values(3);
commit;
select * from t1;
GO
-- normal EXECUTE - should insert into t1
select * from t1;
GO
execute sp_commit_no_begin;
GO
select * from t1;
GO
-- INSERT EXECUTE - should not insert into t1 or t2
select * from t2;
GO
insert into t2 execute sp_commit_no_begin;
GO
select * from t1;
GO
select * from t2;
GO
-- more COMMIT than BEGIN TRAN
create procedure sp_commits_begin as
begin tran
insert into t1 values(3);
commit;
commit;
select * from t1;
go
-- normal EXECUTE - should insert into t1
execute sp_commits_begin;
GO
select * from t1;
GO
-- INSERT EXECUTE - should not insert into t1 or t2
insert into t2 execute sp_commits_begin;
GO
select * from t1;
GO
select * from t2;
GO

-- ROLLBACK stmt is not allowed in INSERT EXEC, whether there is BEGIN TRAN or
-- not.
-- ROLLBACK with no BEGIN TRAN
create procedure sp_rollback_no_begin as
insert into t1 values(4);
rollback;
select * from t1;
GO
-- normal EXECUTE - should insert into t1
execute sp_rollback_no_begin
GO
select * from t1;
GO
-- INSERT EXECUTE - should not insert into t1 or t2
select * from t2;
GO
insert into t2 execute sp_rollback_no_begin;
GO
select * from t1;
GO
select * from t2;
GO
-- ROLLBACK with BEGIN TRAN
create procedure sp_rollback_with_begin as
begin tran;
insert into t1 values(4);
rollback;
select * from t1;
go
-- normal EXECUTE - should insert into t1 and rollback
execute sp_rollback_with_begin
GO
select * from t1;
GO
-- INSERT EXECUTE - should not insert into t1 or t2
select * from t2;
GO
insert into t2 execute sp_rollback_with_begin;
GO
select * from t1;
GO
select * from t2;
GO

-- column mismatch with previous DML - should not insert into t1 or t2
create procedure sp_select_mismatch_with_dml as
insert into t1 values(5);
select a, a from t1;
GO
select * from t1;
GO
select * from t2;
GO
insert into t2 execute sp_select_mismatch_with_dml
go
select * from t1;
GO
select * from t2;
GO

-- column mismatch with previous DML in subtransaction - should not insert into
-- t1 or t2
create procedure sp_select_mismatch_after_subtran as
begin tran;
insert into t1 values(6);
commit;
select a, a from t1;
GO
select * from t1;
GO
select * from t2;
GO
insert into t2 execute sp_select_mismatch_after_subtran;
GO
select * from t1;
GO
select * from t2;
GO

-- procedure with parameter
create procedure sp_select_param (@a int) as
select * from t1 where a = @a;
GO
insert into t1 values (2);
GO
select * from t1;
GO
-- normal EXECUTE
execute sp_select_param 1;
go
select * from t2;
GO
-- INSERT EXECUTE
insert into t2 execute sp_select_param 1;
GO
select * from t2;
GO

-- test if PL parser correctly recognizes whether EXECUTE starts a new statement
-- or not
-- INSERT has VALUES - EXEC should start a new statement
insert into t1 values(7)
exec sp_multi_selects
go
-- INSERT has SELECT - EXEC should start a new statement
insert into t2 values(8)
insert into t1 select * from t2 where a = 8
exec sp_multi_selects
go
-- INSERT has EXEC - SELECT should start a new statement
insert into t2 exec sp_multi_selects
select * from t1
go

-- test INSERT EXEC with inline code blocks
delete t1;
go
insert into t1 exec('select 1; select 2');
go
select * from t1;
go
-- test INSERT EXEC with inline code blocks on table variable
declare @a table (a int);
insert into @a execute('select * from t1; select 3');
select * from @a;
go

create schema user_defined_sch;
go

create type user_defined_sch.test_tbl_type as table (a int, b varchar(10))
go

create table user_defined_sch.test_tbl (a int, b varchar(10))
go

insert into user_defined_sch.test_tbl values (1, 'AAA'), (2, 'Bbb');
go

create procedure user_defined_sch.test_proc
as
begin
    select * from user_defined_sch.test_tbl;
end;
go

exec user_defined_sch.test_proc
go

declare @tbl_var user_defined_sch.test_tbl_type
insert into @tbl_var (a,b) exec user_defined_sch.test_proc
select * from @tbl_var
go

-- clean up
drop table t1
go
drop table t2
go
drop table t3
go
drop procedure sp_multi_selects
go
drop procedure sp_dml_select
go
drop procedure sp_ddl_select
go
drop procedure sp_commit_no_begin
go
drop procedure sp_commits_begin
go
drop procedure sp_rollback_no_begin
go
drop procedure sp_rollback_with_begin
go
drop procedure sp_select_mismatch_with_dml
go
-- drop savepoint
drop procedure sp_select_mismatch_after_subtran
go
drop procedure sp_select_param
go
drop procedure user_defined_sch.test_proc
go
drop table user_defined_sch.test_tbl
go
drop type user_defined_sch.test_tbl_type
go
drop schema user_defined_sch
go


-- Test output parameter for insert execute
CREATE TABLE t (id int)
GO

CREATE PROCEDURE p (@output INT OUTPUT) AS
    SET @output = 17
    SELECT 18
GO

DECLARE @i INT
INSERT INTO t EXEC p @output = @i OUTPUT
SELECT @i
GO

SELECT * FROM t
GO

DECLARE @i INT
INSERT INTO t EXEC p @output = @i OUTPUT
SELECT @i
GO

SELECT * FROM t
GO

ALTER PROCEDURE p (@output INT OUTPUT) AS
    SET @output = 100
    SELECT 200
GO

DECLARE @i INT
INSERT INTO t EXEC p @output = @i OUTPUT
SELECT @i
GO

SELECT * FROM t
GO

DROP PROCEDURE p
DROP TABLE t
GO

-- Test multiple output parameters
CREATE TABLE test_multi (val1 int, val2 int)
GO

CREATE PROCEDURE sp_multi_out (@out1 INT OUTPUT, @out2 INT OUTPUT) AS
    SET @out1 = 10
    SET @out2 = 20
    SELECT 5, 15
GO

DECLARE @a INT, @b INT
INSERT INTO test_multi EXEC sp_multi_out @out1 = @a OUTPUT, @out2 = @b OUTPUT
SELECT @a, @b
GO

SELECT * FROM test_multi
GO

-- Test varchar output parameter
CREATE TABLE test_varchar (msg varchar(20))
GO

CREATE PROCEDURE sp_varchar_out (@msg VARCHAR(20) OUTPUT) AS
    SET @msg = 'Hello'
    SELECT 'World'
GO

DECLARE @s VARCHAR(20)
INSERT INTO test_varchar EXEC sp_varchar_out @msg = @s OUTPUT
SELECT @s
GO

SELECT * FROM test_varchar
GO

-- Test uninitialized output parameter (should be NULL)
CREATE TABLE test_uninit (id int)
GO

CREATE PROCEDURE sp_uninit_out (@out INT OUTPUT) AS
    SELECT 42
GO

DECLARE @u INT
INSERT INTO test_uninit EXEC sp_uninit_out @out = @u OUTPUT
SELECT @u
GO

SELECT * FROM test_uninit
GO

-- Test input and output parameters together
CREATE TABLE test_in_out (result int)
GO

CREATE PROCEDURE sp_in_out (@input INT, @output INT OUTPUT) AS
    SET @output = @input * 2
    SELECT @input + 10
GO

DECLARE @out_val INT
INSERT INTO test_in_out EXEC sp_in_out 5, @output = @out_val OUTPUT
SELECT @out_val
GO

SELECT * FROM test_in_out
GO

-- Test conditional setting of output parameter
CREATE TABLE test_conditional (flag int)
GO

CREATE PROCEDURE sp_conditional_out (@flag INT, @result INT OUTPUT) AS
    IF @flag = 1
        SET @result = 100
    ELSE
        SET @result = 200
    SELECT @flag
GO

DECLARE @cond_result INT
INSERT INTO test_conditional EXEC sp_conditional_out 1, @result = @cond_result OUTPUT
SELECT @cond_result
GO

DECLARE @cond_result2 INT
INSERT INTO test_conditional EXEC sp_conditional_out 0, @result = @cond_result2 OUTPUT
SELECT @cond_result2
GO

SELECT * FROM test_conditional
GO

-- Cleanup additional test objects
DROP PROCEDURE sp_multi_out
DROP TABLE test_multi
GO

DROP PROCEDURE sp_varchar_out
DROP TABLE test_varchar
GO

DROP PROCEDURE sp_uninit_out
DROP TABLE test_uninit
GO

DROP PROCEDURE sp_in_out
DROP TABLE test_in_out
GO

DROP PROCEDURE sp_conditional_out
DROP TABLE test_conditional
GO


-- Test case for nested INSERT ... EXECUTE statements
CREATE TABLE t8164(id int);
GO

CREATE PROC p8164 AS 
    DECLARE @test table(id int) 
    INSERT INTO @test values (1) 
    SELECT * FROM @test;
GO

CREATE PROC p8164a AS 
    INSERT INTO t8164 EXEC p8164 
    DECLARE @test table(id int) 
    INSERT INTO @test values (2) 
    SELECT * FROM @test;
GO

-- Should fail with nested INSERT ... EXECUTE error
INSERT INTO t8164 EXEC p8164a;
GO

-- Cleanup
DROP PROCEDURE p8164a;
GO
DROP PROCEDURE p8164;
GO
DROP TABLE t8164;
GO


-- Test Case 1: Simple 2-level nesting (basic scenario)
CREATE TABLE t_nest1(id int);
CREATE TABLE t_nest2(id int);
GO

CREATE PROC p_inner AS 
    SELECT 1 as id;
GO

CREATE PROC p_outer AS 
    INSERT INTO t_nest1 EXEC p_inner; -- Nested INSERT EXEC
    SELECT 2 as id;
GO

-- Should fail with nested INSERT EXECUTE error
INSERT INTO t_nest2 EXEC p_outer;
GO

-- Cleanup
DROP PROCEDURE p_outer;
DROP PROCEDURE p_inner;
DROP TABLE t_nest2;
DROP TABLE t_nest1;
GO

-- Test Case 2: Table variable nesting
CREATE TABLE t_var_nest(val int);
GO

CREATE PROC p_var_inner AS 
    SELECT 100 as val;
GO

CREATE PROC p_var_outer AS 
    DECLARE @temp table(val int);
    INSERT INTO @temp EXEC p_var_inner; -- Nested with table variable
    SELECT * FROM @temp;
GO

-- Should fail with nested INSERT EXECUTE error
INSERT INTO t_var_nest EXEC p_var_outer;
GO

-- Cleanup
DROP PROCEDURE p_var_outer;
DROP PROCEDURE p_var_inner;
DROP TABLE t_var_nest;
GO

-- Test Case 3: Transaction with nesting
CREATE TABLE t_tran_nest(data int);
GO

CREATE PROC p_tran_inner AS 
    SELECT 50 as data;
GO

CREATE PROC p_tran_outer AS 
    BEGIN TRAN;
    DECLARE @temp table(data int);
    INSERT INTO @temp EXEC p_tran_inner; -- Nested in transaction
    COMMIT;
    SELECT * FROM @temp;
GO

-- Should fail with nested INSERT EXECUTE error
INSERT INTO t_tran_nest EXEC p_tran_outer;
GO

-- Cleanup
DROP PROCEDURE p_tran_outer;
DROP PROCEDURE p_tran_inner;
DROP TABLE t_tran_nest;
GO

-- Test Case 4: Parameter passing in nested calls
CREATE TABLE t_param_nest(result int);
GO

CREATE PROC p_param_inner(@input int) AS 
    SELECT @input * 2 as result;
GO

CREATE PROC p_param_outer(@value int) AS 
    DECLARE @temp table(result int);
    INSERT INTO @temp EXEC p_param_inner @value; -- Nested with parameters
    SELECT * FROM @temp;
GO

-- Should fail with nested INSERT EXECUTE error
INSERT INTO t_param_nest EXEC p_param_outer 10;
GO

-- Cleanup
DROP PROCEDURE p_param_outer;
DROP PROCEDURE p_param_inner;
DROP TABLE t_param_nest;
GO

-- Test Case 5: Error propagation in nested calls
CREATE TABLE t_err_nest(num int NOT NULL);
GO

CREATE PROC p_err_inner AS 
    SELECT NULL as num; -- Will cause constraint violation
GO

CREATE PROC p_err_outer AS 
    INSERT INTO t_err_nest EXEC p_err_inner; -- Should fail here
    SELECT 1 as num;
GO

-- Should fail with both constraint violation and nested INSERT EXECUTE error
DECLARE @err_temp table(num int);
INSERT INTO @err_temp EXEC p_err_outer;
GO

-- Cleanup
DROP PROCEDURE p_err_outer;
DROP PROCEDURE p_err_inner;
DROP TABLE t_err_nest;
GO
