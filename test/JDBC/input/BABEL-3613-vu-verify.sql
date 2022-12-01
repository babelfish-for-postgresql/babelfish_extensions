-- sla 400000
USE MASTER
GO

select current_setting('babelfishpg_tsql.dump_restore_min_oid');
go

-- wrong value
select set_config('babelfishpg_tsql.dump_restore_min_oid', 'wrong value', false);
go

-- invalid OID
select set_config('babelfishpg_tsql.dump_restore_min_oid', 0, false);
go

-- uint32 max should be allowed
select set_config('babelfishpg_tsql.dump_restore_min_oid', 4294967295, false);
go

-- out of range
select set_config('babelfishpg_tsql.dump_restore_min_oid', 4294967296, false);
go

-- There should not have any duplicated object_ids
select object_id, name, schema_id, type_desc from sys.all_objects
where 
      object_id in (select object_id from sys.all_objects group by object_id having count(object_id) > 1)
order by object_id, name;
GO
