USE master
GO

-- should return 3 rows: 
-- one DELETE event for trig1 
-- INSERT and UPDATE events for trig2
SELECT type, type_desc, is_trigger_event, event_group_type, event_group_type_desc FROM sys.events ORDER BY type
GO

SELECT * FROM sys_events_vu_prepare_view
GO

EXEC sys_events_vu_prepare_proc
GO

SELECT dbo.sys_events_vu_prepare_func()
GO

USE sys_events_vu_prepare_database1
GO

-- should return 1 row: 
-- one UPDATE event for trig3
SELECT type, type_desc, is_trigger_event, event_group_type, event_group_type_desc FROM sys.events ORDER BY type
GO

-- check trigger's object ID in sys.all_objects and sys.events view match up
SELECT ao.name FROM sys.all_objects ao
JOIN sys.events e ON e.object_id = ao.object_id
GO