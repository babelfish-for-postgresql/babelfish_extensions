USE sys_triggers_vu_prepare_db1
GO

-- test instead of insert trigger
SELECT 
    name,
    parent_class,
    parent_class_desc,
    type,
    type_desc,
    is_ms_shipped,
    is_disabled,
    is_not_for_replication,
    is_instead_of_trigger
FROM sys.triggers
WHERE name = 'sys_triggers_vu_prepare_trig1'
GO

-- test after insert trigger
SELECT 
    name,
    parent_class,
    parent_class_desc,
    type,
    type_desc,
    is_ms_shipped,
    is_disabled,
    is_not_for_replication,
    is_instead_of_trigger
FROM sys.triggers
WHERE name = 'sys_triggers_vu_prepare_trig2'
GO

-- test schema-scoped visibility of view
SELECT 
    name,
    parent_class,
    parent_class_desc,
    type,
    type_desc,
    is_ms_shipped,
    is_disabled,
    is_not_for_replication,
    is_instead_of_trigger
FROM sys.triggers
WHERE name = 'sys_triggers_vu_prepare_master_trig'
GO
