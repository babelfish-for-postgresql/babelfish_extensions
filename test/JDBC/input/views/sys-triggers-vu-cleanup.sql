USE sys_triggers_vu_prepare_db1
GO

-- Cleanup
DROP TRIGGER sys_triggers_vu_prepare_trig1
GO

DROP TRIGGER sys_triggers_vu_prepare_trig2
GO

DROP table sys_triggers_vu_prepare_t1
GO

DROP table sys_triggers_vu_prepare_t2
GO

USE master
GO

DROP TRIGGER sys_triggers_vu_prepare_master_trig
GO

DROP table sys_triggers_vu_prepare_master_table
GO

DROP database sys_triggers_vu_prepare_db1
GO