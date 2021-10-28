-- BABEL-1400
-- Test NCHAR/NCARCHAR/VARBINARY/CHAR/VARCHAR/BINARY parameter default length as a procedure parameter
CREATE PROCEDURE sp_test1 (@a nchar OUTPUT, @b nvarchar OUTPUT, @c varbinary OUTPUT, @d char OUTPUT, @e varchar OUTPUT, @f binary OUTPUT) AS BEGIN Select @a, @b, @c, @d, @e, @f; END;
GO
Declare @a nchar; Set @a = 'hello';
Declare @b nvarchar; Set @b = 'world';
Declare @c varbinary; Set @c = 0xABCD;
Declare @d char; Set @d = 'HELLO';
Declare @e varchar; Set @e = 'WORLD';
Declare @f binary; Set @f = 0x1234;
exec sp_test1 @a, @b, @c, @d, @e, @f;
GO

CREATE PROCEDURE sp_test2 (@a nchar OUTPUT, @b nvarchar OUTPUT, @c varbinary OUTPUT, @d char OUTPUT, @e varchar OUTPUT, @f binary OUTPUT) AS BEGIN Select @a, @b, @c, @d, @e, @f; END;
GO
Declare @a nchar(2); Set @a = 'hello';
Declare @b nvarchar(2); Set @b = 'world';
Declare @c varbinary(2); Set @c = 0xABCD;
Declare @d char(2); Set @d = 'HELLO';
Declare @e varchar(2); Set @e = 'WORLD';
Declare @f binary(2); Set @f = 0x1234;
exec sp_test2 @a, @b, @c, @d, @e, @f;
GO

CREATE PROCEDURE sp_test3 (@a nchar(2) OUTPUT, @b nvarchar(2) OUTPUT, @c varbinary(2) OUTPUT, @d char(2) OUTPUT, @e varchar(2) OUTPUT, @f binary(2) OUTPUT) AS BEGIN Select @a, @b, @c, @d, @e, @f; END;
GO
Declare @a nchar(2); Set @a = 'hello';
Declare @b nvarchar(2); Set @b = 'world';
Declare @c varbinary(2); Set @c = 0xABCD;
Declare @d char(2); Set @d = 'HELLO';
Declare @e varchar(2); Set @e = 'WORLD';
Declare @f binary(2); Set @f = 0x1234;
exec sp_test3 @a, @b, @c, @d, @e, @f;
GO

-- Test changing parameter value inside procedure
CREATE PROCEDURE sp_test4 (@a nchar OUTPUT, @b nvarchar OUTPUT, @c varbinary OUTPUT, @d char OUTPUT, @e varchar OUTPUT, @f binary OUTPUT) AS BEGIN SET @a = 'world'; SET @b = 'hello'; SET @c = 0x1234; SET @d = 'WORLD'; SET @e = 'HELLO'; SET @f = 0xABCD; Select @a, @b, @c, @d, @e, @f; END;
GO
Declare @a nchar; Set @a = 'hello';
Declare @b nvarchar; Set @b = 'world';
Declare @c varbinary; Set @c = 0xABCD;
Declare @d char; Set @d = 'HELLO';
Declare @e varchar; Set @e = 'WORLD';
Declare @f binary; Set @f = 0x1234;
exec sp_test4 @a, @b, @c, @d, @e, @f;
GO

-- Clean up
DROP PROCEDURE sp_test1;
DROP PROCEDURE sp_test2;
DROP PROCEDURE sp_test3;
DROP PROCEDURE sp_test4;
GO
