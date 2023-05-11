create database db1;
go
use db1;
go
create table t_spdatabases(a int);
go
insert into t_spdatabases(a) values(10);
go
insert into t_spdatabases(a) values(10);
go
insert into t_spdatabases(a) values(10);
go
insert into t_spdatabases(a) values(10);
go

select database_name, remarks from sys.sp_databases_view where database_name='db1';
go

select database_name, remarks from sys.sp_databases_view where database_name='DB1';
go

CREATE PROCEDURE sp_databases_PROC1
AS
BEGIN
DECLARE
    @tmp_sp_addrole TABLE(database_name sys.SYSNAME, database_size int, remarks sys.VARCHAR(254));
	INSERT INTO @tmp_sp_addrole (database_name, database_size, remarks) EXEC sp_databases;
    SELECT database_name, (case when database_size >=0 then 1 else NULL end), remarks  FROM @tmp_sp_addrole where database_name='DB1';
END
GO

exec sp_databases_PROC1;
GO

DROP PROCEDURE sp_databases_PROC1;
GO

drop table t_spdatabases;
go
use master;
go
drop database db1;
go
