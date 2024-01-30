-- Multiple procedures with same name and equal number of parameters
EXEC p492 4;
GO

DROP PROC p492(INT, FLOAT);
DROP PROC p492(INT, DECIMAL);
GO

-- Multiple procedures with different number of parameters
EXEC p492 1, 2; -- 2 arguments supplied
GO

DROP PROC p492(INT);
DROP PROC p492(INT, FLOAT, DECIMAL);
GO

-- Test for unique functions/procedures (Only one definition exists)
-- Procedure with no parameters
EXEC p492 2, 3; -- Supply arguments to procedure with no parameters
GO

DROP PROC p492;
GO

-- Some parameters not specified.
EXEC p492 1, 2; -- Only positional arguments
GO

EXEC p492 @b=2, @a=1; -- Only named arguments
GO

EXEC p492 1, @c=3; -- Mixed positional and named arguments
GO

EXEC p492 1, @x=2, @y=3; -- Unknown non-default argument names
GO

EXEC p492 1, 2, 3, 4; -- Supply arguments more than the procedure expects
GO

DROP PROC p492;
GO

-- Procedure with default parameters.
EXEC p492 1, 2, 3; -- Valid call
GO

EXEC p492 1, 2, @x=5; -- Unknown default argument name
GO

DECLARE @var DATETIME2;
SET @var= GETDATE();
EXEC p492 1, @var; -- Invalid datatype
GO

DROP PROC p492;
GO
