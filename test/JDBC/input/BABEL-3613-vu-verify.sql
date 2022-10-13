USE MASTER
GO

-- There should not have any duplicated object_ids
select object_id, name, schema_id, type_desc from sys.all_objects
where 
      object_id in (select object_id from sys.all_objects group by object_id having count(object_id) > 1)

      -- should be removed after fixing duplicated object_ids for Table Type and Table Valued Functions
      and type not in ('U', 'TT')
order by object_id, name;
GO
