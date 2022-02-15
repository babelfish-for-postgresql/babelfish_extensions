create type tt_type as table(tt_type_a int, tt_type_b char);
GO

-- Note : table types's database visibility has been already tested in sys-types.sql

select name
      , system_type_id
      , principal_id
      , max_length
      , precision
      , scale
      , collation_name
      , is_nullable
      , is_user_defined
      , is_assembly_type
      , default_object_id
      , rule_object_id
      , is_table_type
      , is_memory_optimized
from sys.table_types
where name = 'tt_type';
GO

select principal_id
      , parent_object_id
      , type
      , type_desc
      , create_date
      , modify_date
      , is_ms_shipped
      , is_published
      , is_schema_published
from sys.objects
where name like 'TT_tt_type%';
GO

select principal_id
      , parent_object_id
      , type
      , type_desc
      , create_date
      , modify_date
      , is_ms_shipped
      , is_published
      , is_schema_published
from sys.all_objects
where name like 'TT_tt_type%';
GO

drop type tt_type;
GO