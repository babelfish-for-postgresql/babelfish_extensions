-- Setup
CREATE TABLE sys_triggers_vu_prepare_master_table(a int)
GO

CREATE TRIGGER sys_triggers_vu_prepare_master_trig ON sys_triggers_vu_prepare_master_table AFTER INSERT
AS
BEGIN
SELECT 1
END
GO

CREATE DATABASE sys_triggers_vu_prepare_db1
GO

USE sys_triggers_vu_prepare_db1
GO

CREATE TABLE sys_triggers_vu_prepare_t1(a int)
GO

CREATE TABLE sys_triggers_vu_prepare_t2(b int)
GO

CREATE TRIGGER sys_triggers_vu_prepare_trig1 ON sys_triggers_vu_prepare_t1 INSTEAD OF INSERT
AS
BEGIN
SELECT 1
END
GO

CREATE TRIGGER sys_triggers_vu_prepare_trig2 ON sys_triggers_vu_prepare_t2 AFTER INSERT
AS
BEGIN
SELECT 1
END
GO
