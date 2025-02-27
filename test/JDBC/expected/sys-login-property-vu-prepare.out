-- Create dependant objects
CREATE VIEW loginproperty_vu_prepare_view AS
SELECT sys.loginproperty('test_login', 'PasswordHash')
GO

CREATE PROC loginproperty_vu_prepare_proc AS
SELECT sys.loginproperty('test_login', 'PasswordHash')
GO

CREATE FUNCTION loginproperty_vu_prepare_func()
RETURNS nvarchar(128)
AS
BEGIN
RETURN sys.loginproperty('test_login', 'PasswordHash')
END
GO
