create database sys_syscolumns_vu_prepare_db1;
go

use sys_syscolumns_vu_prepare_db1;
go

-- create helper function to get datatype name given oid
CREATE FUNCTION sys_syscolumns_vu_prepare_OidToDataType(@Oid integer)
RETURNS VARCHAR(50)
AS
BEGIN
        DECLARE @datatype VARCHAR(50);
        SET @datatype = (SELECT typname from pg_type where oid = @Oid);
        RETURN @datatype;
END;
GO

-- create helper function to get procedure/table name given oid
CREATE FUNCTION sys_syscolumns_vu_prepare_OidToObject(@Oid integer)
RETURNS VARCHAR(50)
AS
BEGIN
        DECLARE @object_name VARCHAR(50);

        SET @object_name = (SELECT relname from pg_class where oid = @Oid);

        IF (@object_name is null)
        BEGIN
                SET @object_name = (SELECT proname from pg_proc where oid = @Oid);
        END

        RETURN @object_name
END;
GO

-- create helper function to get collation name given oid
CREATE FUNCTION sys_syscolumns_vu_prepare_OidToCollation(@Oid integer)
RETURNS VARCHAR(50)
AS
BEGIN
        DECLARE @collation VARCHAR(50);
        SET @collation = (SELECT collname from pg_collation where oid = @Oid);
        RETURN @collation;
END;
GO

-- Setup some procedures and tables
create procedure sys_syscolumns_vu_prepare_proc1 @firstparam NVARCHAR(50) as select 1
GO

create procedure sys_syscolumns_vu_prepare_proc2 @firstparam NVARCHAR(50), @secondparam VARCHAR(50) OUT as select 2
GO

create table sys_syscolumns_vu_prepare_t1 (col_a int, col_b bigint, col_c char(10), col_d numeric(5,4))
GO

use master;
go

create procedure sys_syscolumns_vu_prepare_proc3 @thirdparam NVARCHAR(50) as select 3;
go

