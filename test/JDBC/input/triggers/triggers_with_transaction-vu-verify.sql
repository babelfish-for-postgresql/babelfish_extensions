insert into triggers_with_transaction_vu_prepare_t1 values(2, 'second');
go

begin tran;
go
insert into triggers_with_transaction_vu_prepare_t1 values(3, 'third');
go
commit;
go

update triggers_with_transaction_vu_prepare_t2 set c1 = 6;
GO

begin tran
go
update triggers_with_transaction_vu_prepare_t2 set c1 = 6;
go
if (@@trancount > 0) rollback;
go

begin tran
go
insert into triggers_with_transaction_vu_prepare_t1 values(6, 'six');
go
if (@@trancount > 0) rollback;
go

drop trigger triggers_with_transaction_vu_prepare_trig1;
go

create trigger triggers_with_transaction_vu_prepare_trig1 on triggers_with_transaction_vu_prepare_t1 for insert as
begin tran;
update triggers_with_transaction_vu_prepare_t2 set c1 = 6;
commit;
select * from triggers_with_transaction_vu_prepare_t2 order by c1;
select * from inserted;
go

insert into triggers_with_transaction_vu_prepare_t1 values(2, 'second');
go

begin tran;
go
insert into triggers_with_transaction_vu_prepare_t1 values(3, 'third');
go
if (@@trancount > 0) rollback;
go

drop trigger triggers_with_transaction_vu_prepare_trig1;
go

drop trigger triggers_with_transaction_vu_prepare_trig3;
go

create trigger triggers_with_transaction_vu_prepare_trig1 on triggers_with_transaction_vu_prepare_t1 for insert as
begin tran;
update triggers_with_transaction_vu_prepare_t2 set c1 = 2;
commit;
select * from triggers_with_transaction_vu_prepare_t2 order by c1;
select * from inserted;
go

create trigger triggers_with_transaction_vu_prepare_trig3 on triggers_with_transaction_vu_prepare_t3 for delete as
select * from triggers_with_transaction_vu_prepare_t3 order by c1;
insert into triggers_with_transaction_vu_prepare_t3 values(6);
select * from deleted;
rollback tran sp2;
go

insert into triggers_with_transaction_vu_prepare_t1 values(2, 'second');
go

begin tran;
go
insert into triggers_with_transaction_vu_prepare_t1 values(3, 'third');
go
if (@@trancount > 0) rollback;
go

drop trigger triggers_with_transaction_vu_prepare_trig3;
go

create trigger triggers_with_transaction_vu_prepare_trig3 on triggers_with_transaction_vu_prepare_t3 for delete as
select * from triggers_with_transaction_vu_prepare_t3 order by c1;
insert into triggers_with_transaction_vu_prepare_t3 values(1);
select * from deleted;
rollback tran sp2;
go

drop trigger triggers_with_transaction_vu_prepare_trig1;
go

create trigger triggers_with_transaction_vu_prepare_trig1 on triggers_with_transaction_vu_prepare_t1 for insert as
commit;
update triggers_with_transaction_vu_prepare_t2 set c1 = 2;
select * from triggers_with_transaction_vu_prepare_t2 order by c1;
go

insert into triggers_with_transaction_vu_prepare_t1 values(2, 'second');
go

begin tran;
go

insert into triggers_with_transaction_vu_prepare_t1 values(2, 'second');
go

drop trigger triggers_with_transaction_vu_prepare_trig1;
go

create trigger triggers_with_transaction_vu_prepare_trig1 on triggers_with_transaction_vu_prepare_t1 for insert as
rollback;
update triggers_with_transaction_vu_prepare_t2 set c1 = 3;
select * from triggers_with_transaction_vu_prepare_t2 order by c1;
go

insert into triggers_with_transaction_vu_prepare_t1 values(2, 'second');
go

begin tran;
go

insert into triggers_with_transaction_vu_prepare_t1 values(2, 'second');
go

create procedure triggerProc1 as
save tran sp1;
insert into triggers_with_transaction_vu_prepare_t1 values(3, 'third');
rollback tran sp1;
go

create procedure triggerProc2 as
begin tran;
exec triggerProc1;
insert into triggers_with_transaction_vu_prepare_t1 values(3, 'third');
commit;
go

exec triggerProc2;
go

drop procedure triggerProc2;
go

drop trigger triggers_with_transaction_vu_prepare_trig1
go

create trigger triggers_with_transaction_vu_prepare_trig1 on triggers_with_transaction_vu_prepare_t1 for insert as
commit;
update triggers_with_transaction_vu_prepare_t2 set c1 = 6;
select * from triggers_with_transaction_vu_prepare_t2 order by c1;
go

create procedure triggerProc2 as
begin tran;
exec triggerProc1;
insert into triggers_with_transaction_vu_prepare_t1 values(6, 'six');
commit;
go

exec triggerProc2;
go

if (@@trancount>0) commit;
go

drop trigger triggers_with_transaction_vu_prepare_trig1;
go

create trigger triggers_with_transaction_vu_prepare_trig1 on triggers_with_transaction_vu_prepare_t1 for insert as
begin tran;
update triggers_with_transaction_vu_prepare_t2 set c1 = 2;
commit;
select * from triggers_with_transaction_vu_prepare_t2 order by c1;
select * from inserted;
go

drop procedure triggerProc1;
go
drop procedure triggerProc2;
go

create table triggers_with_transaction_vu_prepare_tmp__1 (a int not null);
go

insert into triggers_with_transaction_vu_prepare_tmp__1 values (1)
go

create procedure triggerProc1 as
save tran sp1;
insert into triggers_with_transaction_vu_prepare_tmp__1 values (null);
rollback tran sp1;
go

create procedure triggerProc2 as
begin tran;
exec triggerProc1;
insert into triggers_with_transaction_vu_prepare_t1 values(3, 'third');
commit;
go

exec triggerProc2;
go

drop table triggers_with_transaction_vu_prepare_tmp__1 
go

create table triggerErrorTab(c1 int not null);
go

create trigger triggerErr on triggerErrorTab for insert as
insert into triggerErrorTab values(NULL);
insert into invalidTab values(1);
go

insert into triggerErrorTab values(1);
go


drop procedure triggerProc1;
go
drop procedure triggerProc2;
go
drop trigger triggers_with_transaction_vu_prepare_trig1
go


create procedure triggerProc1 as
commit;
go

create procedure triggerProc2 as
exec triggerProc1;
go

create trigger triggers_with_transaction_vu_prepare_trig1 on triggers_with_transaction_vu_prepare_t1 for insert as
exec triggerProc2;
go

insert into triggers_with_transaction_vu_prepare_t1 values(1, 'value1');
go

drop procedure triggerProc1;
go
drop procedure triggerProc2;
go
drop trigger triggers_with_transaction_vu_prepare_trig1
go


create procedure triggerProc1 as
rollback;
go

create procedure triggerProc2 as
exec triggerProc1;
go

create trigger triggers_with_transaction_vu_prepare_trig1 on triggers_with_transaction_vu_prepare_t1 after insert as
exec triggerProc2;
go

insert into triggers_with_transaction_vu_prepare_t1 values(1, 'value2');
go

drop procedure triggerProc1;
go
drop procedure triggerProc2;
go
drop trigger triggers_with_transaction_vu_prepare_trig1
go


create procedure triggerProc1 as
rollback tran sp1;
go

create procedure triggerProc2 as
exec triggerProc1;
go

create trigger triggers_with_transaction_vu_prepare_trig1 on triggers_with_transaction_vu_prepare_t1 for insert as
save tran sp1;
exec triggerProc2;
go

insert into triggers_with_transaction_vu_prepare_t1 values(1, 'value3');
go


drop procedure triggerProc1;
go
drop procedure triggerProc2;
go
drop table triggers_with_transaction_vu_prepare_t1;
go
drop table triggers_with_transaction_vu_prepare_t2;
go
drop table triggers_with_transaction_vu_prepare_t3;
go
drop table triggerErrorTab
go

create table triggers_with_transaction_vu_prepare_t1(c1 int, c2 varchar(30), check (c1 < 5))
go

create table triggers_with_transaction_vu_prepare_t2(c1 int, check (c1 < 5))
go

create table triggers_with_transaction_vu_prepare_t3(c1 int, check (c1 < 5))
go

insert into triggers_with_transaction_vu_prepare_t1 values(1, 'first')
go

insert into triggers_with_transaction_vu_prepare_t2 values(1)
go

insert into triggers_with_transaction_vu_prepare_t3 values(1)
go

create trigger triggers_with_transaction_vu_prepare_trig1 on triggers_with_transaction_vu_prepare_t1 for insert as
insert into triggers_with_transaction_vu_prepare_t2 values (2);
go

create trigger triggers_with_transaction_vu_prepare_trig2 on triggers_with_transaction_vu_prepare_t2 for insert as
insert into triggers_with_transaction_vu_prepare_t3 values (2);
go

create trigger triggers_with_transaction_vu_prepare_trig3 on triggers_with_transaction_vu_prepare_t3 for insert as
select 'nest level 3'
go

insert into triggers_with_transaction_vu_prepare_t1 values(2, 'two')
go

begin tran
go
insert into triggers_with_transaction_vu_prepare_t1 values(6, 'six')
go
if (@@trancount > 0) rollback tran;
go

select * from triggers_with_transaction_vu_prepare_t1;
GO

select * from triggers_with_transaction_vu_prepare_t2;
GO

select * from triggers_with_transaction_vu_prepare_t3;
GO

drop trigger triggers_with_transaction_vu_prepare_trig1;
go

create trigger triggers_with_transaction_vu_prepare_trig1 on triggers_with_transaction_vu_prepare_t1 for insert as
insert into triggers_with_transaction_vu_prepare_t2 values (6);
go

insert into triggers_with_transaction_vu_prepare_t2 values(2)
go

begin tran
go
insert into triggers_with_transaction_vu_prepare_t2 values(6)
go
if (@@trancount > 0) rollback tran;
go

begin tran
go
insert into triggers_with_transaction_vu_prepare_t1 values(3, 'three')
go
if (@@trancount > 0) rollback tran;
go

select * from triggers_with_transaction_vu_prepare_t1;
GO

select * from triggers_with_transaction_vu_prepare_t2;
GO

select * from triggers_with_transaction_vu_prepare_t3;
GO

drop trigger triggers_with_transaction_vu_prepare_trig1;
go
drop trigger triggers_with_transaction_vu_prepare_trig2;
go

create trigger triggers_with_transaction_vu_prepare_trig1 on triggers_with_transaction_vu_prepare_t1 for insert as
insert into triggers_with_transaction_vu_prepare_t2 values (2);
go

create trigger triggers_with_transaction_vu_prepare_trig2 on triggers_with_transaction_vu_prepare_t2 for insert as
insert into triggers_with_transaction_vu_prepare_t3 values (6);
go

insert into triggers_with_transaction_vu_prepare_t3 values(2)
go

begin tran
go
insert into triggers_with_transaction_vu_prepare_t3 values(6)
go
if (@@trancount > 0) rollback tran;
go

begin tran
go
insert into triggers_with_transaction_vu_prepare_t1 values(3, 'three')
go
if (@@trancount > 0) rollback tran;
go

select * from triggers_with_transaction_vu_prepare_t1;
GO
select * from triggers_with_transaction_vu_prepare_t2;
GO
select * from triggers_with_transaction_vu_prepare_t3;
GO

drop table triggers_with_transaction_vu_prepare_t1;
go
drop table triggers_with_transaction_vu_prepare_t2;
go
drop table triggers_with_transaction_vu_prepare_t3;
go

create table triggers_with_transaction_vu_prepare_t1(c1 int not null)
go

create table triggers_with_transaction_vu_prepare_t2(c1 int not null)
go

create table triggers_with_transaction_vu_prepare_t3(c1 int not null)
go

insert into triggers_with_transaction_vu_prepare_t1 values(1)
go

insert into triggers_with_transaction_vu_prepare_t2 values(1)
go

insert into triggers_with_transaction_vu_prepare_t3 values(1)
go

create trigger triggers_with_transaction_vu_prepare_trig1 on triggers_with_transaction_vu_prepare_t1 for insert as
select 'nest level 1'
insert into triggers_with_transaction_vu_prepare_t2 values (2);
go

create trigger triggers_with_transaction_vu_prepare_trig2 on triggers_with_transaction_vu_prepare_t2 for insert as
select 'nest level 2'
insert into triggers_with_transaction_vu_prepare_t3 values (null);
go

create trigger triggers_with_transaction_vu_prepare_trig3 on triggers_with_transaction_vu_prepare_t3 for insert as
select 'nest level 3'
go

begin tran
go
insert into triggers_with_transaction_vu_prepare_t1 values(2)
go
if (@@trancount > 0) rollback tran;
go

begin tran
go
insert into triggers_with_transaction_vu_prepare_t1 values(NULL)
go
if (@@trancount > 0) rollback tran;
go

select * from triggers_with_transaction_vu_prepare_t1;
go
select * from triggers_with_transaction_vu_prepare_t2;
go
select * from triggers_with_transaction_vu_prepare_t3;
go

drop trigger triggers_with_transaction_vu_prepare_trig1;
go

drop trigger triggers_with_transaction_vu_prepare_trig2;
go

create trigger triggers_with_transaction_vu_prepare_trig1 on triggers_with_transaction_vu_prepare_t1 for insert as
select 'nest level 1'
insert into triggers_with_transaction_vu_prepare_t2 values (NULL);
go

create trigger triggers_with_transaction_vu_prepare_trig2 on triggers_with_transaction_vu_prepare_t2 for insert as
select 'nest level 2'
insert into triggers_with_transaction_vu_prepare_t3 values (3);
go

begin tran
go
insert into triggers_with_transaction_vu_prepare_t1 values(3)
go
if (@@trancount > 0) rollback tran;
go

select * from triggers_with_transaction_vu_prepare_t1;
go
select * from triggers_with_transaction_vu_prepare_t2;
go
select * from triggers_with_transaction_vu_prepare_t3;
go