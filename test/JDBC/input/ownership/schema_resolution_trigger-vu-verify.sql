-- need to and recreate trigger if it exists in the incorrect schema
BEGIN TRAN
GO
IF NOT EXISTS (
    SELECT * FROM pg_proc 
    WHERE proname = 'schema_resolution_trigger_tr2' AND
    pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'master_schema_resolution_trigger_s1'))
BEGIN
    DROP TRIGGER schema_resolution_trigger_s1.schema_resolution_trigger_tr2;
END
GO
IF NOT EXISTS (select * from sys.objects where type = 'TR' and name = 'schema_resolution_trigger_tr2')
EXEC dbo.sp_executesql @statement = N'create trigger schema_resolution_trigger_s1.schema_resolution_trigger_tr2 on schema_resolution_trigger_s1.schema_resolution_trigger_mytab for insert as
select * from schema_resolution_trigger_t1'
COMMIT
GO

-- Resolves to dbo.schema_resolution_trigger_t1
insert into dbo.schema_resolution_trigger_mytab values(1)
go

-- Resolves to schema_resolution_trigger_s1.schema_resolution_trigger_t1
insert into schema_resolution_trigger_s1.schema_resolution_trigger_mytab values(1)
go

drop trigger schema_resolution_trigger_tr1
go

drop table schema_resolution_trigger_s1.schema_resolution_trigger_t1
go

-- Resolves to dbo.schema_resolution_trigger_t1
insert into schema_resolution_trigger_s1.schema_resolution_trigger_mytab values(1)
go

drop trigger schema_resolution_trigger_s1.schema_resolution_trigger_tr2
go

drop table schema_resolution_trigger_t1
go

create trigger schema_resolution_trigger_s1.schema_resolution_trigger_tr1 on schema_resolution_trigger_s1.schema_resolution_trigger_mytab for insert as
create table schema_resolution_trigger_t1(dbo_t1 char);
go

-- Creates a table in "dbo" schema
insert into schema_resolution_trigger_s1.schema_resolution_trigger_mytab values(1)
go

select * from schema_resolution_trigger_t1
go

drop trigger schema_resolution_trigger_s1.schema_resolution_trigger_tr1
go

create trigger schema_resolution_trigger_s1.schema_resolution_trigger_tr1 on schema_resolution_trigger_s1.schema_resolution_trigger_mytab for insert as
select * from dbo.schema_resolution_trigger_t1;
go

-- Resolves to dbo.schema_resolution_trigger_t1
insert into schema_resolution_trigger_s1.schema_resolution_trigger_mytab values(1)
go

drop table schema_resolution_trigger_t1;
go

drop table schema_resolution_trigger_mytab
go

drop table schema_resolution_trigger_s1.schema_resolution_trigger_mytab
go

drop schema schema_resolution_trigger_s1
go
