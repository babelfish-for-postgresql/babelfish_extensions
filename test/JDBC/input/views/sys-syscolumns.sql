-- create helper function to get datatype name given oid
CREATE FUNCTION OidToDataType(@Oid integer)
RETURNS VARCHAR(50)
AS
BEGIN
        DECLARE @datatype VARCHAR(50);
        SET @datatype = (SELECT typname from pg_type where oid = @Oid);
        RETURN @datatype;
END;
GO

-- create helper function to get procedure/table name given oid
CREATE FUNCTION OidToObject(@Oid integer)
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
CREATE FUNCTION OidToCollation(@Oid integer)
RETURNS VARCHAR(50)
AS
BEGIN
        DECLARE @collation VARCHAR(50);
        SET @collation = (SELECT collname from pg_collation where oid = @Oid);
        RETURN @collation;
END;
GO

-- Setup some procedures and tables
create procedure syscolumns_demo_proc1 @firstparam NVARCHAR(50) as select 1
GO

create procedure syscolumns_demo_proc2 @firstparam NVARCHAR(50), @secondparam VARCHAR(50) OUT as select 2
GO

create table syscolumns_demo_table (col_a int, col_b bigint, col_c char(10), col_d numeric(5,4))
GO

select name, OidToObject(id), OidToDataType(xtype), typestat, length from sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c' or name = 'col_d' order by OidToObject(id) asc, name
GO

select colid, cdefault, domain, number from sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c' or name = 'col_d' order by OidToObject(id) asc, name
GO

select OidToCollation(collationid), status, OidToDataType(type), prec, scale from sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c' or name = 'col_d' order by OidToObject(id) asc, name
GO

select iscomputed, isoutparam, isnullable, collation from sys.syscolumns where name = '@firstparam' or name = '@secondparam' or name = 'col_a' or name = 'col_b' or name = 'col_c' or name = 'col_d' order by OidToObject(id) asc, name
GO

-- Cleanup
DROP FUNCTION OidToDataType
DROP FUNCTION OidToObject
DROP FUNCTION OidToCollation
DROP PROCEDURE syscolumns_demo_proc1
DROP PROCEDURE syscolumns_demo_proc2
DROP TABLE syscolumns_demo_table
GO