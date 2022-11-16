CREATE FUNCTION sys_proc_param_helper_func() RETURNS TABLE
AS
RETURN
(
    select name,  (CASE WHEN (id IS NULL) THEN 0 ELSE 1 END) as id,
    (CASE WHEN (xtype IS NULL) THEN 0 ELSE 1 END) as xtype,
    colid,
    collationid,
    prec,
    scale,
    isoutparam,
    collation from proc_param_helper()
);
GO

-- Setup some procedures
create procedure sys_proc_param_helper_proc1 @sys_proc_param_helper_proc1_firstparam NVARCHAR(50) as select 1
GO
