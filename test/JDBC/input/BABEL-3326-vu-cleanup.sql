-- Cleanup 
use master;
go

DROP TRIGGER IF EXISTS TR_ins_babel_3326_Employees
DROP TRIGGER IF EXISTS TR_upd_babel_3326_Employees
GO
DROP TABLE IF EXISTS babel_3326_Employees
GO