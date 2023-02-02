
EXEC babel_3657_vu_prepare_proc1 'Should work'
GO

-- Should throw error as currently exec doesn't support calling a procedure with a variable name
DECLARE @pro varchar(50) = 'babel_3657_vu_prepare_proc1'
DECLARE @in varchar(50) = 'Will throw error'
EXEC @pro @in
GO

-- Earlier it was crashing when constant is provided as input when calling a procedure with a variable name 
-- Now it should throw error similar to procedure does not exist
DECLARE @pro varchar(50) = 'babel_3657_vu_prepare_proc1'
EXEC @pro 'Will throw error'
GO


-- non existent procedure
EXEC non_existing_procedure 'Will throw error'
GO

DROP PROCEDURE babel_3657_vu_prepare_proc1
GO


