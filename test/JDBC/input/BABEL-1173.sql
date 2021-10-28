CREATE PROCEDURE proc_babel_1173
(
	@p INT NULL
)
AS PRINT 'helloworld'
GO

EXEC proc_babel_1173 1
GO

DROP PROCEDURE proc_babel_1173
GO

