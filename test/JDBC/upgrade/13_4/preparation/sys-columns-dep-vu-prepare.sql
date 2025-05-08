create table sys_columns_dep_vu_prepare_t1(a int, b float, c bigint, d numeric, e smallint, f tinyint, g decimal, h money, i smallmoney);
go

create procedure sys_columns_dep_vu_prepare_p1 as
    select name, column_id, precision, scale from sys.columns where object_id=OBJECT_ID('sys_columns_dep_vu_prepare_t1') order by column_id;
go

create view sys_columns_dep_vu_prepare_v1 as
    select name, column_id, precision, scale from sys.columns where object_id=OBJECT_ID('sys_columns_dep_vu_prepare_t1') order by column_id;
go

create function sys_columns_dep_vu_prepare_f1()
returns int 
as
begin
    return (select count(*) from sys.columns where object_id=OBJECT_ID('sys_columns_dep_vu_prepare_t1'));
end
go