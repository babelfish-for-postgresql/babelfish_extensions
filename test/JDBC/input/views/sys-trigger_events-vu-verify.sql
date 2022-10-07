USE sys_trigger_events_vu_prepare_database1
GO

-- should return 1 row: 
-- one UPDATE event for trig3
SELECT type, type_desc, is_trigger_event, event_group_type, event_group_type_desc FROM sys.trigger_events ORDER BY type
GO

-- check trigger's object ID in sys.all_objects and sys.trigger_events view match up
SELECT ao.name FROM sys.all_objects ao
JOIN sys.trigger_events e ON e.object_id = ao.object_id
AND ao.type = 'TR'
GO

USE master
GO

-- should return 3 rows: 
-- one DELETE event for trig1 
-- INSERT and UPDATE events for trig2
SELECT te.type, te.type_desc, te.is_trigger_event, te.event_group_type, te.event_group_type_desc FROM sys.trigger_events te
INNER JOIN sys.triggers t ON t.object_id = te.object_id 
AND (t.name = 'sys_trigger_events_vu_prepare_trig1' OR t.name = 'sys_trigger_events_vu_prepare_trig2')
ORDER BY type
GO

SELECT * FROM sys_trigger_events_vu_prepare_view
GO

EXEC sys_trigger_events_vu_prepare_proc
GO

SELECT dbo.sys_trigger_events_vu_prepare_func()
GO

USE master
GO
