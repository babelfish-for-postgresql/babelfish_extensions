create table sys_syscolumns_dep_vu_prepare_t1 (col_a int, col_b bigint, col_c char(10), col_d numeric(5,4))
GO

create procedure sys_syscolumns_dep_vu_prepare_p1 as
    SELECT COUNT(*) FROM sys.syscolumns where name = 'col_a'
GO

create function sys_syscolumns_dep_vu_prepare_f1() 
returns int
as
BEGIN
    return (SELECT COUNT(*) FROM sys.syscolumns where name = 'col_a')
END
GO

create view sys_syscolumns_dep_vu_prepare_v1 as
    SELECT COUNT(*) FROM sys.syscolumns where name = 'col_a'
GO