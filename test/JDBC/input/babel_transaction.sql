create table TxnTable(c1 int);
GO


-- Begin transaction -> commit transaction
begin transaction;
select @@trancount;
GO
begin transaction;
select @@trancount;
GO
insert into TxnTable values(1);
commit transaction;
select @@trancount;
GO
commit transaction;
select @@trancount;
GO
select c1 from TxnTable;
GO

-- Begin transaction -> rollback transaction
begin transaction;
insert into TxnTable values(2);
rollback transaction;
select c1 from TxnTable;
GO

-- Begin tran -> commit tran
begin tran;
insert into TxnTable values(2);
commit tran;
select c1 from TxnTable;
GO

-- Begin tran -> rollback tran
begin tran;
set transaction isolation level read uncommitted;
select @@trancount;
begin tran;
insert into TxnTable values(3);
select @@trancount;
rollback tran;
select @@trancount;
select c1 from TxnTable;
GO


-- Begin transaction -> commit
begin transaction;
insert into TxnTable values(4);
commit;
select c1 from TxnTable;
GO

-- Begin transaction -> commit work
begin transaction;
insert into TxnTable values(5);
commit work;
select c1 from TxnTable;
GO

-- Begin transaction -> rollback
begin transaction;
insert into TxnTable values(6);
rollback;
select c1 from TxnTable;
GO

-- Begin transaction -> rollback work
begin transaction;
insert into TxnTable values(7);
rollback work;
select c1 from TxnTable;
GO

-- Begin transaction name -> commit transaction name
begin transaction txn1;
insert into TxnTable values(8);
commit transaction txn1;
select c1 from TxnTable;
GO

-- Begin transaction name -> rollback transaction name
begin transaction txn1;
insert into TxnTable values(9);
rollback transaction txn1;
select c1 from TxnTable;
GO

-- Begin tran name -> commit tran name
begin tran txn1;
insert into TxnTable values(10);
commit tran txn1;
select c1 from TxnTable;
Go

-- Begin tran name -> rollback tran name
begin tran txn1;
insert into TxnTable values(10);
rollback tran txn1;
select c1 from TxnTable;
GO
truncate table TxnTable;
GO

-- save tran name -> rollback tran name
begin transaction txn1;
insert into TxnTable values(1);
save transaction sp1;
select @@trancount;
GO
insert into TxnTable values(2);
save tran sp2;
insert into TxnTable values(3);
save tran sp2;
select @@trancount;
GO
insert into TxnTable values(4);
select c1 from TxnTable;
GO
rollback tran sp2;
select @@trancount;
GO
select c1 from TxnTable;
GO
rollback tran sp2;
select @@trancount;
GO
select c1 from TxnTable;
GO
rollback tran sp1;
select @@trancount;
GO
select c1 from TxnTable;
GO
rollback tran txn1;
select @@trancount;
GO
select c1 from TxnTable;
GO

-- begin transaction name -> save transaction name -> rollback tran name
-- Rollback whole transaction
begin transaction txn1;
insert into TxnTable values(1);
save transaction sp1;
begin transaction txn1;
insert into TxnTable values(2);
save transaction sp1;
insert into TxnTable values(3);
select @@trancount;
GO
rollback tran txn1;
select @@trancount;
GO
select c1 from TxnTable;
GO

-- begin transaction -> save transaction name -> rollback to savepoint
-- commit transaction
begin transaction txn1;
insert into TxnTable values(1);
save transaction sp1;
insert into TxnTable values(2);
select c1 from TxnTable;
GO
rollback tran sp1;
commit transaction;
select c1 from TxnTable;
GO

-- begin transaction -> save transaction name -> rollback to savepoint
-- save transaction name -> commit transaction
begin transaction txn1;
insert into TxnTable values(3);
save transaction sp1;
insert into TxnTable values(4);
select c1 from TxnTable;
GO
rollback tran sp1;
save transaction sp2;
insert into TxnTable values(5);
commit transaction;
select c1 from TxnTable;
GO

-- begin transaction -> save transaction name -> error -> rollback to savepoint
-- commit transaction
rollback tran sp1;
commit transaction;
select c1 from TxnTable;
GO

drop table TxnTable;
GO
