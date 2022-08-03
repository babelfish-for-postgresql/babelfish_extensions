SELECT * FROM TestErrorHelperFunctionsUpgrade_VU_PREPARE_VIEW;
GO

DROP VIEW TestErrorHelperFunctionsUpgrade_VU_PREPARE_VIEW
GO

CREATE VIEW TestErrorHelperFunctionsUpgrade_VU_PREPARE_VIEW AS
SELECT sql_error_code from sys.fn_mapped_system_error_list();
GO

SELECT * FROM TestErrorHelperFunctionsUpgrade_VU_PREPARE_VIEW;
GO

SELECT * FROM TestErrorHelperFunctionsUpgrade_VU_PREPARE_FUNC();
GO

EXEC TestErrorHelperFunctionsUpgrade_VU_PREPARE_PROC
GO
