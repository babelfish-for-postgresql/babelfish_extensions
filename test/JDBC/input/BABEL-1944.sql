create table t1(a int);
go
create table t2(a int);
go
create procedure sp_trancount as
select @@trancount;
GO
create procedure sp_commit_no_begin as
insert into t1 values(3);
commit;
select * from t1;
GO
create procedure sp_rollback_no_begin as
insert into t1 values(4);
rollback;
select * from t1;
GO
create procedure sp_rollback_with_begin as
begin tran;
insert into t1 values(4);
rollback;
select * from t1;
go

select @@trancount;
go
-- trancount inside normal EXEC should be same as outside
exec sp_trancount;
go
-- trancount inside INSERT-EXEC should be 1 more than outside
insert into t1 exec sp_trancount;
go
select * from t1;
go
delete t1;
go

-- zero level - normal EXEC should succeed with warning for no BEGIN TRAN on the
-- COMMIT
exec sp_commit_no_begin;
go
-- zero level - INSERT-EXEC should fail with error message about the COMMIT
-- inside INSERT-EXEC must have a BEGIN TRAN
delete t1;
go
insert into t2 exec sp_commit_no_begin;
go
select count(*) from t1;
select count(*) from t2;
go

-- one level - should fail and abort that level of transaction
begin tran;
go
select @@trancount;
go
insert into t2 execute sp_commit_no_begin;
go
select @@trancount;
go
select count(*) from t1;
select count(*) from t2;
go

-- previous level aborted, this should be the same as before
begin tran;
go
select @@trancount;
go
insert into t2 execute sp_commit_no_begin;
go
select count(*) from t1;
select count(*) from t2;
go

-- normal EXEC with COMMIT is allowed with one level - should succeed with
-- unbalanced level warning from 1 to 0
begin tran;
go
select @@trancount;
go
execute sp_commit_no_begin;
go
select count(*) from t1;
select count(*) from t2;
go

-- two levels - should succeed with unbalanced level warning from 2 to 1, and
-- should not send any Row tokens
select @@trancount;
go
begin tran;
go
begin tran;
go
select @@trancount;
go
insert into t2 execute sp_commit_no_begin;
go
select count(*) from t1;
select count(*) from t2;
go
select @@trancount;
go
commit;
go

-- INSERT-EXEC with ROLLBACK in one level of transaction - should fail and abort
-- that level of transaction
begin tran;
go
select @@trancount;
go
insert into t2 exec sp_rollback_no_begin;
go
select @@trancount;
go

begin tran;
go
select @@trancount;
go
insert into t2 exec sp_rollback_with_begin;
go
select @@trancount;
go

-- cleanup
drop table t1;
go
drop table t2;
go
drop procedure sp_trancount;
go
drop procedure sp_commit_no_begin;
go
drop procedure sp_rollback_no_begin;
go
drop procedure sp_rollback_with_begin;
go
