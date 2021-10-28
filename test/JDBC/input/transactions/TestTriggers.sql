create table triggerTab1(c1 int, c2 varchar(30))
go

create table triggerTab2(c1 int)
go

create table triggerTab3(c1 int)
go

insert into triggerTab1 values(1, 'first')
go

insert into triggerTab2 values(1)
go

insert into triggerTab3 values(1)
go

create trigger txnTrig1 on triggerTab1 for insert as
begin tran;
update triggerTab2 set c1 = 2;
commit;
select * from triggerTab2 order by c1;
select * from inserted;
go

create trigger txnTrig2 on triggerTab2 for update as
save tran sp1;
save tran sp2;
delete from triggerTab3;
rollback tran sp1;
go

create trigger txnTrig3 on triggerTab3 for delete as
select * from triggerTab3 order by c1;
insert into triggerTab3 values(1);
select * from deleted;
rollback tran sp2;
go

insert into triggerTab1 values(2, 'second');
go

begin tran;
go
insert into triggerTab1 values(3, 'third');
go
commit;
go

drop trigger txnTrig1;
go

create trigger txnTrig1 on triggerTab1 for insert as
commit;
update triggerTab2 set c1 = 2;
select * from triggerTab2 order by c1;
go

insert into triggerTab1 values(2, 'second');
go

begin tran;
go

insert into triggerTab1 values(2, 'second');
go

drop trigger txnTrig1;
go

create trigger txnTrig1 on triggerTab1 for insert as
rollback;
update triggerTab2 set c1 = 3;
select * from triggerTab2 order by c1;
go

insert into triggerTab1 values(2, 'second');
go

begin tran;
go

insert into triggerTab1 values(2, 'second');
go

create procedure triggerProc1 as
save tran sp1;
insert into triggerTab1 values(3, 'third');
rollback tran sp1;
go

create procedure triggerProc2 as
begin tran;
exec triggerProc1;
insert into triggerTab1 values(3, 'third');
commit;
go

exec triggerProc2;
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
drop trigger txnTrig1
go


create procedure triggerProc1 as
commit;
go

create procedure triggerProc2 as
exec triggerProc1;
go

create trigger txnTrig1 on triggerTab1 for insert as
exec triggerProc2;
go

insert into triggerTab1 values(1, 'value1');
go

drop procedure triggerProc1;
go
drop procedure triggerProc2;
go
drop trigger txnTrig1
go


create procedure triggerProc1 as
rollback;
go

create procedure triggerProc2 as
exec triggerProc1;
go

create trigger txnTrig1 on triggerTab1 after insert as
exec triggerProc2;
go

insert into triggerTab1 values(1, 'value2');
go

drop procedure triggerProc1;
go
drop procedure triggerProc2;
go
drop trigger txnTrig1
go


create procedure triggerProc1 as
rollback tran sp1;
go

create procedure triggerProc2 as
exec triggerProc1;
go

create trigger txnTrig1 on triggerTab1 for insert as
save tran sp1;
exec triggerProc2;
go

insert into triggerTab1 values(1, 'value3');
go


drop procedure triggerProc1;
go
drop procedure triggerProc2;
go
drop table triggerTab1;
go
drop table triggerTab2;
go
drop table triggerTab3;
go
drop table triggerErrorTab
go
