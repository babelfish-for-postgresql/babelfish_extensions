-- implict castings
DECLARE @a binary(10); SET @a = CAST('21' AS char(10)); SELECT @a
go

DECLARE @a binary(10); SET @a = CAST('21' AS varchar(10)); SELECT @a
go

DECLARE @a varbinary(10); SET @a = CAST('21' AS char(10)); SELECT @a
go

DECLARE @a varbinary(10); SET @a = CAST('21' AS varchar(10)); SELECT @a
go

-- explicit castings
DECLARE @a binary(10); SET @a = CONVERT(binary(10), CAST('21' AS char(10))); SELECT @a
go

DECLARE @a binary(10); SET @a = CONVERT(binary(10), CAST('21' AS varchar(10))); SELECT @a
go

DECLARE @a varbinary(10); SET @a = CONVERT(varbinary(10), CAST('21' AS char(10))); SELECT @a
go

DECLARE @a varbinary(10); SET @a = CONVERT(varbinary(10), CAST('21' AS varchar(10))); SELECT @a
go
