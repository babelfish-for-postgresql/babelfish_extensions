-- Should throw an error
SELECT * FROM TestErrorHelperFunctionsUpgrade_VU_PREPARE_VIEW;
GO

CREATE OR REPLACE VIEW TestErrorHelperFunctionsUpgrade_VU_PREPARE_VIEW AS
SELECT sql_error_code from sys.fn_mapped_system_error_list();
GO

SELECT * FROM TestErrorHelperFunctionsUpgrade_VU_PREPARE_VIEW;
GO