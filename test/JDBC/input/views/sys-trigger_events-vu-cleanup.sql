USE master
GO

DROP VIEW sys_trigger_events_vu_prepare_view
GO
DROP PROC sys_trigger_events_vu_prepare_proc
GO
DROP FUNCTION dbo.sys_trigger_events_vu_prepare_func()
GO

DROP TRIGGER sys_trigger_events_vu_prepare_trig1
GO
DROP TRIGGER sys_trigger_events_vu_prepare_schema1.sys_trigger_events_vu_prepare_trig2
GO
DROP TABLE sys_trigger_events_vu_prepare_table1
GO
DROP TABLE sys_trigger_events_vu_prepare_schema1.sys_trigger_events_vu_prepare_table1
GO
DROP SCHEMA sys_trigger_events_vu_prepare_schema1
GO