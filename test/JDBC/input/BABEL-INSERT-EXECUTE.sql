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