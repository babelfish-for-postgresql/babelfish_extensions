create database sys_sp_databases_dep_vu_prepare_db1;
go
use sys_sp_databases_dep_vu_prepare_db1;
go
create table sys_sp_databases_dep_vu_prepare_t1(a int);
go
insert into sys_sp_databases_dep_vu_prepare_t1(a) values(10);
go

create procedure sys_sp_databases_dep_vu_prepare_p1 as
    select database_name, remarks from sys.sp_databases_view where database_name='sys_sp_databases_dep_vu_prepare_db1'
go

create function sys_sp_databases_dep_vu_prepare_f1()
returns int
as
begin
    return (select COUNT(*) from sys.sp_databases_view where database_name='sys_sp_databases_dep_vu_prepare_db1')
end
go

create view sys_sp_databases_dep_vu_prepare_v1 as
    select database_name, remarks from sys.sp_databases_view where database_name='sys_sp_databases_dep_vu_prepare_db1'
go

CREATE PROCEDURE sp_databases_dep_vu_prepare_PROC1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @tmp_sp_addrole TABLE(database_name sys.SYSNAME, database_size int, remarks sys.VARCHAR(254));
	INSERT INTO @tmp_sp_addrole (database_name, database_size, remarks) EXEC sp_databases;
    SELECT database_name, (case when database_size >=0 then 1 else NULL end), remarks  FROM @tmp_sp_addrole where database_name='sys_sp_databases_dep_vu_prepare_db1';
    SET NOCOUNT OFF;
END
GO
