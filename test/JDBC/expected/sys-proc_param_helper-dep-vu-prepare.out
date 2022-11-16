CREATE PROCEDURE sys_proc_param_helper_proc @rolename AS sys.SYSNAME
AS
BEGIN
    SELECT count(*) FROM proc_param_helper() WHERE NAME = @rolename
END
GO

-- Setup some procedures
create procedure sys_proc_param_helper_proc1 @sys_proc_param_helper_proc1_firstparam NVARCHAR(50) as select 1
GO
