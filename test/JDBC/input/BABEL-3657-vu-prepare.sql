CREATE PROCEDURE babel_3657_vu_prepare_proc1 (@in varchar(50))
AS 
SELECT @in
GO

EXEC babel_3657_vu_prepare_proc1 'Should work'
GO



-- Should throw error as currently exec doesn't support calling a procedure with a variable name
-- it will throw error similar to procedure doesn't exist
DECLARE @pro varchar(50) = 'babel_3657_vu_prepare_proc1'
DECLARE @in varchar(50) = 'Will throw error'
EXEC @pro @in
GO


-- non existent procedure
DECLARE @in varchar(50) = 'Will throw error'
EXEC non_existing_procedure @in
GO

-- after fix of the crash, it should throw error similar to this
EXEC non_existing_procedure 'Will throw error'
GO