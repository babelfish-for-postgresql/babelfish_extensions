-- Create dependant objects
CREATE VIEW fn_varbintohexsubstring_vu_prepare_view AS
SELECT sys.fn_varbintohexsubstring(1, CAST('0x1234' AS varbinary(128)), 1, 4)
GO

CREATE PROC fn_varbintohexsubstring_vu_prepare_proc AS
SELECT sys.fn_varbintohexsubstring(1, CAST('0x1234' AS varbinary(128)), 1, 4)
GO

CREATE FUNCTION fn_varbintohexsubstring_vu_prepare_func()
RETURNS nvarchar(128)
AS
BEGIN
RETURN sys.fn_varbintohexsubstring(1, CAST('0x1234' AS varbinary(128)), 1, 4)
END
GO
