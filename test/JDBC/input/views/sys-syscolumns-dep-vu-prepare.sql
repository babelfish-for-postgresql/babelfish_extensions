create table sys_syscolumns_dep_vu_prepare_t1 (col_a1 int, col_b1 bigint, col_c1 char(10), col_d1 numeric(5,4))
GO

create procedure sys_syscolumns_dep_vu_prepare_p1 as
    SELECT COUNT(*) FROM sys.syscolumns where name = 'col_a1'
GO

create function sys_syscolumns_dep_vu_prepare_f1() 
returns int
as
BEGIN
    return (SELECT COUNT(*) FROM sys.syscolumns where name = 'col_a1')
END
GO

create view sys_syscolumns_dep_vu_prepare_v1 as
    SELECT COUNT(*) FROM sys.syscolumns where name = 'col_a1'
GO