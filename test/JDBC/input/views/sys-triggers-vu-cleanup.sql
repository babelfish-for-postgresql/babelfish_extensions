USE sys_triggers_db1
GO

-- Cleanup
DROP TRIGGER sys_triggers_trig1
GO

DROP TRIGGER sys_triggers_trig2
GO

DROP table sys_triggers_t1
GO

DROP table sys_triggers_t2
GO

USE master
GO

DROP TRIGGER sys_triggers_master_trig
GO

DROP table sys_triggers_master_table
GO

DROP database sys_triggers_db1
GO