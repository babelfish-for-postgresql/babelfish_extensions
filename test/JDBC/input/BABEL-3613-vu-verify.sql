-- sla 400000
USE MASTER
GO

select current_setting('babelfishpg_tsql.dump_restore_min_oid');
go

-- There should not have any duplicated object_ids
select object_id, name, schema_id, type_desc from sys.all_objects
where 
      object_id in (select object_id from sys.all_objects group by object_id having count(object_id) > 1)
order by object_id, name;
GO

-- BABEL-4662
select count(*) from sys.all_objects where name = 'pltsql_call_handler';
go
select count(*) from sys.procedures where name = 'pltsql_call_handler';
go
select count(*) from sys.system_objects where name = 'pltsql_call_handler';
go
