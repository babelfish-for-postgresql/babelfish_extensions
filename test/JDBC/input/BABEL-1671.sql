-- Check if default binary data length is 1 when maxLen isn't specified
-- in a data definition or variable declaration statement 
DROP PROCEDURE IF EXISTS sp_test12;
go
CREATE PROCEDURE sp_test12 (@a binary OUTPUT) AS BEGIN SET @a=0x121; Select @a as a; END;
go
Declare @a binary;Set @a=0x121; exec sp_test12 @a;select @a as a;
go
DROP PROCEDURE sp_test12;
go
DROP PROCEDURE IF EXISTS sp_test13;
go
CREATE PROCEDURE sp_test13 (@b binary OUTPUT) AS BEGIN SET @b=0x121111; Select @b as b; END;
go
Declare @b binary;Set @b=0x121111; exec sp_test13 @b;select @b as b;
go
DROP PROCEDURE sp_test13;
go
