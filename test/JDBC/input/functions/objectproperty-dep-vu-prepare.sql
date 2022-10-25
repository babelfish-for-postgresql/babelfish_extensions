-- Create dependant objects
CREATE TABLE objectproperty_vu_prepare_t1(a int)
GO

CREATE VIEW objectproperty_vu_prepare_dep_view AS
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_t1'), 'IsTable')
GO

CREATE PROC objectproperty_vu_prepare_dep_proc AS
SELECT OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_t1'), 'IsTable')
GO

CREATE FUNCTION objectproperty_vu_prepare_dep_func()
RETURNS INT
AS
BEGIN
RETURN OBJECTPROPERTY(OBJECT_ID('objectproperty_vu_prepare_t1'), 'IsTable')
END
GO

