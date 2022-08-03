CREATE VIEW TestErrorHelperFunctionsUpgrade_VU_PREPARE_VIEW AS
SELECT sql_error_code from sys.fn_mapped_system_error_list();
GO

create function TestErrorHelperFunctionsUpgrade_VU_PREPARE_FUNC() returns table
as
return (select sql_error_code from sys.fn_mapped_system_error_list());
GO

create procedure TestErrorHelperFunctionsUpgrade_VU_PREPARE_PROC as
select count(*) from sys.fn_mapped_system_error_list()
GO