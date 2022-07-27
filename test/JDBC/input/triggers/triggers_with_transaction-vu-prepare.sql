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
begin tran;
update triggers_with_transaction_vu_prepare_t2 set c1 = 2;
commit;
select * from triggers_with_transaction_vu_prepare_t2 order by c1;
select * from inserted;
go

create trigger triggers_with_transaction_vu_prepare_trig2 on triggers_with_transaction_vu_prepare_t2 for update as
save tran sp1;
save tran sp2;
delete from triggers_with_transaction_vu_prepare_t3;
rollback tran sp1;
go

create trigger triggers_with_transaction_vu_prepare_trig3 on triggers_with_transaction_vu_prepare_t3 for delete as
select * from triggers_with_transaction_vu_prepare_t3 order by c1;
insert into triggers_with_transaction_vu_prepare_t3 values(1);
select * from deleted;
rollback tran sp2;
go


