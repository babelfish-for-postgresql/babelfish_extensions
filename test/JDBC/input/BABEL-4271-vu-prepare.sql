-- Test to check like escape null and like escape ''
create table testvikasprj(a varchar(30), b varchar(30));
go

insert into testvikasprj values ('cbc','[c-a]bc');
insert into testvikasprj values ('abc','abc');
insert into testvikasprj values ('cbc','def');
go