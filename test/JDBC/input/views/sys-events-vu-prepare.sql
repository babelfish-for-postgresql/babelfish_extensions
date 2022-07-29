USE master
GO

CREATE TABLE sys_events_vu_prepare_table1(c1 int)
GO

CREATE SCHEMA sys_events_vu_prepare_schema1
GO

CREATE TABLE sys_events_vu_prepare_schema1.sys_events_vu_prepare_table1(c1 int)
GO

--create trigger on default schema for master database
CREATE TRIGGER sys_events_vu_prepare_trig1 ON sys_events_vu_prepare_table1 INSTEAD OF DELETE
AS
BEGIN
  SELECT 'trigger invoked'
END
GO

--create trigger on different schema
CREATE TRIGGER sys_events_vu_prepare_trig2 ON sys_events_vu_prepare_schema1.sys_events_vu_prepare_table1 FOR INSERT, UPDATE
AS
BEGIN
  SELECT 'trigger invoked'
END
GO

CREATE VIEW sys_events_vu_prepare_view AS
SELECT type, type_desc, is_trigger_event, event_group_type, event_group_type_desc FROM sys.events ORDER BY type
GO

CREATE PROC sys_events_vu_prepare_proc AS
SELECT type, type_desc, is_trigger_event, event_group_type, event_group_type_desc FROM sys.events ORDER BY type
GO

CREATE FUNCTION dbo.sys_events_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.events)
END
GO
