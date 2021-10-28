create table testErrorHF(c1 int not null);
insert into testErrorHF values(1);
GO

begin try
	insert into testErrorHF values('abc');
end try
begin catch
	select @@error, @@pgerror;
end catch
GO

select @@error, @@pgerror;
GO

insert into testErrorHF values(null);
GO

select @@error, @@pgerror;
GO

select * from fn_mapped_system_error_list();
GO
