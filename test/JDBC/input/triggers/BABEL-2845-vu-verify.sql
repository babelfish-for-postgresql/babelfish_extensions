begin tran
GO

insert into babel_2845_vu_prepare_t1 values (6)
GO

save transaction tran1
GO

insert into babel_2845_vu_prepare_t1 values (7)
GO

rollback transaction tran1
GO

commit
GO

select * from babel_2845_vu_prepare_t1;
GO

begin tran
GO

insert into babel_2845_vu_prepare_t1 values (7)
GO

save transaction tran1
GO

-- error which should rollback the whole tran
insert into babel_2845_vu_prepare_t1 values (1)
GO

if (@@trancount > 0) rollback tran;
GO

select * from babel_2845_vu_prepare_t1;
GO

