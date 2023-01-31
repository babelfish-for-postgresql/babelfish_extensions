-- test for ensuring proper login name for windows login works properly
CREATE LOGIN [babel\aduser] from windows;
GO

-- test for ensuring proper login name for password based login works properly
CREATE LOGIN babeluser with password='123';
GO

-- test for ensuring that '\' is not allowed for password based login
CREATE LOGIN [babel\babeluser] with password='123';
GO