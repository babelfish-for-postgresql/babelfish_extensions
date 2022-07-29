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
