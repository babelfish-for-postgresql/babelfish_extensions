-- nvarchar
Declare @a nvarchar; Declare @b nvarchar; SET @a = 'abc' ; EXEC proc_test_1 @a = @a , @b = @b OUT ;
GO

Declare @a nvarchar; Declare @b nvarchar; SET @a = 'abc' ; EXEC proc_test_1_1 @a = @a , @b = @b OUT ;
GO
Declare @a nvarchar(max); Declare @b nvarchar(max); SET @a = '' ; EXEC proc_test_1_1 @a = @a , @b = @b OUT ;
GO

Declare @a nvarchar(max); Declare @b nvarchar(max); SET @a = 'SELECT * FROM sys.databases' ; EXEC proc_test_2 @a = @a , @b = @b OUT ;
GO
Declare @a nvarchar(max); Declare @b nvarchar(max); SET @a = Replicate('A',8679);EXEC proc_test_2 @a = @a , @b = @b OUT ;
GO
Declare @a nvarchar(max); Declare @b nvarchar(max); SET @a = '' ; EXEC proc_test_2 @a = @a , @b = @b OUT ;
GO

Declare @a nvarchar(5); Declare @b nvarchar(5); SET @a = 'SELECT * FROM sys.databases' ; EXEC proc_test_3 @a = @a , @b = @b OUT ;
GO

Declare @a nvarchar(50); Declare @b nvarchar(50); SET @a = 'SELECT * FROM sys.databases' ; EXEC proc_test_4 @a = @a , @b = @b OUT ;
GO

Declare @a nvarchar(4000); Declare @b nvarchar(4000); SET @a = 'SELECT * FROM sys.databases' ; EXEC proc_test_5 @a = @a , @b = @b OUT ;
GO

-- varchar
Declare @a varchar; Declare @b varchar; SET @a = 'abc' ; EXEC proc_test_6 @a = @a , @b = @b OUT ;
GO

Declare @a varchar(max); Declare @b varchar(max); SET @a = Replicate('A',9340);EXEC proc_test_7 @a = @a , @b = @b OUT ;
GO

Declare @a varchar(5); Declare @b varchar(5); SET @a = 'SELECT * FROM sys.databases' ; EXEC proc_test_8 @a = @a , @b = @b OUT ;
GO

Declare @a varchar(50); Declare @b varchar(50); SET @a = 'SELECT * FROM sys.databases' ; EXEC proc_test_9 @a = @a , @b = @b OUT ;
GO

Declare @a varchar(8000); Declare @b varchar(8000); SET @a = 'SELECT * FROM sys.databases' ; EXEC proc_test_10 @a = @a , @b = @b OUT ;
GO

-- varbinary
Declare @a varbinary; Declare @b varbinary; SET @a = CONVERT(VARBINARY, '0x121') ; EXEC proc_test_11 @a = @a , @b = @b OUT ;
GO
Declare @a varbinary; Declare @b varbinary; SET @a = 80000 ; EXEC proc_test_11 @a = @a , @b = @b OUT ;
GO

Declare @a varbinary; Declare @b varbinary; SET @a = CONVERT(VARBINARY, '0x121') ; EXEC proc_test_11_1 @a = @a , @b = @b OUT ;
GO
Declare @a varbinary; Declare @b varbinary; SET @a = 80000 ; EXEC proc_test_11_1 @a = @a , @b = @b OUT ;
GO

Declare @a varbinary(max); Declare @b varbinary(max); SET @a = CONVERT(varbinary(max), Replicate('A',8000)) ; EXEC proc_test_12 @a = @a , @b = @b OUT ;
GO
Declare @a varbinary(max); Declare @b varbinary(max); SET @a = CONVERT(varbinary(max), Replicate('A',8)) ; EXEC proc_test_12 @a = @a , @b = @b OUT ;
GO
Declare @a varbinary(max); Declare @b varbinary(max); SET @a = CONVERT(VARBINARY(MAX), '0x121') ; EXEC proc_test_12 @a = @a , @b = @b OUT ;
GO
Declare @a varbinary(max); Declare @b varbinary(max); SET @a = 8000 ; EXEC proc_test_12 @a = @a , @b = @b OUT ;
GO

Declare @a varbinary(27); Declare @b varbinary(27); SET @a = 8000 ; EXEC proc_test_13 @a = @a , @b = @b OUT ;
GO
Declare @a varbinary(27); Declare @b varbinary(27); SET @a = CONVERT(VARBINARY(27), '0x121') ; EXEC proc_test_13 @a = @a , @b = @b OUT
GO

Declare @a varbinary(27); Declare @b varbinary(27); SET @a = 8000 ; EXEC proc_test_13_1 @a = @a , @b = @b OUT ;
GO
Declare @a varbinary(27); Declare @b varbinary(27); SET @a = CONVERT(VARBINARY(27), '0x121') ; EXEC proc_test_13_1 @a = @a , @b = @b OUT
GO

Declare @a varbinary(8000); Declare @b varbinary(8000); SET @a = 8000 ; EXEC proc_test_14 @a = @a , @b = @b OUT ;
GO

-- nchar
Declare @a nchar; Declare @b nchar; SET @a = 'abc' ; EXEC proc_test_15 @a = @a , @b = @b OUT ;
GO

Declare @a nchar(10); Declare @b nchar(10); SET @a = 'SELECT * FROM sys.databases' ; EXEC proc_test_16 @a = @a , @b = @b OUT ;
GO

Declare @a nchar(4000); Declare @b nchar(4000); SET @a = 'SELECT * FROM sys.databases' ; EXEC proc_test_17 @a = @a , @b = @b OUT ;
GO
Declare @a nchar(4000); Declare @b nchar(4000); SET @a = Replicate('A',9340);EXEC proc_test_17 @a = @a , @b = @b OUT ;
GO

-- smalldatetime
Declare @a smalldatetime; Declare @b smalldatetime; SET @a = '2024-09-01 10:00' ; EXEC proc_test_18 @a = @a , @b = @b OUT ;
GO

Declare @a smalldatetime(2); Declare @b smalldatetime(2); SET @a = '2024-09-01 10:40:10' ; EXEC proc_test_19 @a = @a , @b = @b OUT ;
GO

Declare @a smalldatetime(5); Declare @b smalldatetime(5); SET @a = '2024-09-01 10:40:10.5453' ; EXEC proc_test_20 @a = @a , @b = @b OUT ;
GO

Declare @a smalldatetime(6); Declare @b smalldatetime(6); SET @a = '2024-09-01 10:40:10' ; EXEC proc_test_21 @a = @a , @b = @b OUT ;
GO

--decimal
Declare @a decimal; Declare @b decimal; SET @a = 1234567.5678 ; EXEC proc_test_22 @a = @a , @b = @b OUT ;
GO

Declare @a decimal(38,18); Declare @b decimal(38,18); SET @a = 1234567.5678 ; EXEC proc_test_23 @a = @a , @b = @b OUT ;
GO

-- binary
Declare @a binary; Declare @b binary; SET @a = 0x01 ; EXEC proc_test_24 @a = @a , @b = @b OUT ;
GO

Declare @a binary; Declare @b binary; SET @a = 0x5465737442696E ; EXEC proc_test_25 @a = @a , @b = @b OUT ;
GO

Declare @a binary(10); Declare @b binary(10); SET @a = 0x5465737442696E ; EXEC proc_test_26 @a = @a , @b = @b OUT ;
GO

Declare @a binary(8000); Declare @b binary(8000); SET @a = 0x5465737442696E ; EXEC proc_test_27 @a = @a , @b = @b OUT ;
GO

-- bpchar
Declare @a bpchar; Declare @b bpchar; SET @a = 'abc' ; EXEC proc_test_28 @a = @a , @b = @b OUT ;
GO

Declare @a bpchar(10); Declare @b bpchar(10); SET @a = 'SELECT * FROM sys.databases' ; EXEC proc_test_29 @a = @a , @b = @b OUT ;
GO

Declare @a bpchar(8000); Declare @b bpchar(8000); SET @a = 'SELECT * FROM sys.databases' ; EXEC proc_test_30 @a = @a , @b = @b OUT ;
GO
Declare @a bpchar(8000); Declare @b bpchar(8000); SET @a = Replicate('A',9340); EXEC proc_test_30 @a = @a , @b = @b OUT ;
GO

