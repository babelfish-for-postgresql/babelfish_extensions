-- creating procedure
CREATE PROCEDURE storeOriginalQuery_procedure AS BEGIN DECLARE @storeOriginalQuery_var [varchar] (8000) END
go
-- creating function
CREATE FUNCTION storeOriginalQuery_function() RETURNS [VARCHAR](8000) AS BEGIN DECLARE @storeOriginalQuery_var [VARCHAR](8000) RETURN @storeOriginalQuery_var END
go