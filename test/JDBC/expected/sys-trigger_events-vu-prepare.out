USE master
GO

CREATE TABLE sys_trigger_events_vu_prepare_table1(c1 int)
GO

CREATE SCHEMA sys_trigger_events_vu_prepare_schema1
GO

CREATE TABLE sys_trigger_events_vu_prepare_schema1.sys_trigger_events_vu_prepare_table1(c1 int)
GO

--create trigger on default schema for master database
CREATE TRIGGER sys_trigger_events_vu_prepare_trig1 ON sys_trigger_events_vu_prepare_table1 INSTEAD OF DELETE
AS
BEGIN
  SELECT 'trigger invoked'
END
GO

--create trigger on different schema
CREATE TRIGGER sys_trigger_events_vu_prepare_trig2 ON sys_trigger_events_vu_prepare_schema1.sys_trigger_events_vu_prepare_table1 FOR INSERT, UPDATE
AS
BEGIN
  SELECT 'trigger invoked'
END
GO

CREATE VIEW sys_trigger_events_vu_prepare_view AS
SELECT te.type, te.type_desc, te.is_trigger_event, te.event_group_type, te.event_group_type_desc FROM sys.trigger_events te
INNER JOIN sys.triggers t ON t.object_id = te.object_id 
AND (t.name = 'sys_trigger_events_vu_prepare_trig1' OR t.name = 'sys_trigger_events_vu_prepare_trig2')
ORDER BY type
GO

CREATE PROC sys_trigger_events_vu_prepare_proc AS
SELECT te.type, te.type_desc, te.is_trigger_event, te.event_group_type, te.event_group_type_desc FROM sys.trigger_events te
INNER JOIN sys.triggers t ON t.object_id = te.object_id 
AND (t.name = 'sys_trigger_events_vu_prepare_trig1' OR t.name = 'sys_trigger_events_vu_prepare_trig2')
ORDER BY type
GO

CREATE FUNCTION dbo.sys_trigger_events_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT COUNT(*) FROM sys.trigger_events te
INNER JOIN sys.triggers t ON t.object_id = te.object_id 
AND (t.name = 'sys_trigger_events_vu_prepare_trig1' OR t.name = 'sys_trigger_events_vu_prepare_trig2'))
END
GO


CREATE DATABASE sys_trigger_events_vu_prepare_database1
GO
USE sys_trigger_events_vu_prepare_database1
GO

CREATE TABLE sys_trigger_events_vu_prepare_table1(c1 int)
GO

--create trigger on default schema for db1 database
CREATE TRIGGER sys_trigger_events_vu_prepare_trig3 ON sys_trigger_events_vu_prepare_table1 INSTEAD OF UPDATE
AS
BEGIN
  SELECT 'trigger invoked'
END
GO

USE master
GO
