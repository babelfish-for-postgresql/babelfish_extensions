-- nvarchar
Declare @a nvarchar; Declare @b nvarchar; SET @a = 'abc' ; EXEC babel_5059_proc_test_1 @a = @a , @b = @b OUT ;
GO

Declare @a nvarchar; Declare @b nvarchar; SET @a = 'abc' ; EXEC babel_5059_proc_test_1_1 @a = @a , @b = @b OUT ;
GO
Declare @a nvarchar(max); Declare @b nvarchar(max); SET @a = '' ; EXEC babel_5059_proc_test_1_1 @a = @a , @b = @b OUT ;
GO

Declare @a nvarchar(max); SET @a = 'SELECT * FROM sys.databases' ; EXEC babel_5059_proc_test_2 @a = @a;
GO

Declare @a nvarchar(max); Declare @b nvarchar(max); SET @a = Replicate('A',8679);EXEC babel_5059_proc_test_2_1 @a = @a , @b = @b OUT ;
GO
Declare @a nvarchar(max); Declare @b nvarchar(max); SET @a = '' ; EXEC babel_5059_proc_test_2_1 @a = @a , @b = @b OUT ;
GO

Declare @a nvarchar(5); Declare @b nvarchar(5); SET @a = 'SELECT * FROM sys.databases' ; EXEC babel_5059_proc_test_3 @a = @a , @b = @b OUT ;
GO

Declare @a nvarchar(50); Declare @b nvarchar(50); SET @a = 'SELECT * FROM sys.databases' ; EXEC babel_5059_proc_test_4 @a = @a , @b = @b OUT ;
GO

Declare @a nvarchar(4000); Declare @b nvarchar(4000); SET @a = 'SELECT * FROM sys.databases' ; EXEC babel_5059_proc_test_5 @a = @a , @b = @b OUT ;
GO

-- varchar
Declare @a varchar; Declare @b varchar; SET @a = 'abc' ; EXEC babel_5059_proc_test_6 @a = @a , @b = @b OUT ;
GO

Declare @a varchar(max); Declare @b varchar(max); SET @a = Replicate('A',9340);EXEC babel_5059_proc_test_7 @a = @a , @b = @b OUT ;
GO

Declare @a varchar(5); Declare @b varchar(5); SET @a = 'SELECT * FROM sys.databases' ; EXEC babel_5059_proc_test_8 @a = @a , @b = @b OUT ;
GO

Declare @a varchar(50); Declare @b varchar(50); SET @a = 'SELECT * FROM sys.databases' ; EXEC babel_5059_proc_test_9 @a = @a , @b = @b OUT ;
GO

Declare @a varchar(8000); Declare @b varchar(8000); SET @a = 'SELECT * FROM sys.databases' ; EXEC babel_5059_proc_test_10 @a = @a , @b = @b OUT ;
GO

-- varbinary
Declare @a varbinary; Declare @b varbinary; SET @a = CONVERT(VARBINARY, '0x121') ; EXEC babel_5059_proc_test_11 @a = @a , @b = @b OUT ;
GO
Declare @a varbinary; Declare @b varbinary; SET @a = 80000 ; EXEC babel_5059_proc_test_11 @a = @a , @b = @b OUT ;
GO

Declare @a varbinary; Declare @b varbinary; SET @a = CONVERT(VARBINARY, '0x121') ; EXEC babel_5059_proc_test_11_1 @a = @a , @b = @b OUT ;
GO
Declare @a varbinary; Declare @b varbinary; SET @a = 80000 ; EXEC babel_5059_proc_test_11_1 @a = @a , @b = @b OUT ;
GO

Declare @a varbinary(max); Declare @b varbinary(max); SET @a = CONVERT(varbinary(max), Replicate('A',8000)) ; EXEC babel_5059_proc_test_12 @a = @a , @b = @b OUT ;
GO
Declare @a varbinary(max); Declare @b varbinary(max); SET @a = CONVERT(varbinary(max), Replicate('A',8)) ; EXEC babel_5059_proc_test_12 @a = @a , @b = @b OUT ;
GO
Declare @a varbinary(max); Declare @b varbinary(max); SET @a = CONVERT(VARBINARY(MAX), '0x121') ; EXEC babel_5059_proc_test_12 @a = @a , @b = @b OUT ;
GO
Declare @a varbinary(max); Declare @b varbinary(max); SET @a = 8000 ; EXEC babel_5059_proc_test_12 @a = @a , @b = @b OUT ;
GO

Declare @a varbinary(27); Declare @b varbinary(27); SET @a = 8000 ; EXEC babel_5059_proc_test_13 @a = @a , @b = @b OUT ;
GO
Declare @a varbinary(27); Declare @b varbinary(27); SET @a = CONVERT(VARBINARY(27), '0x121') ; EXEC babel_5059_proc_test_13 @a = @a , @b = @b OUT
GO

Declare @a varbinary(27); Declare @b varbinary(27); SET @a = 8000 ; EXEC babel_5059_proc_test_13_1 @a = @a , @b = @b OUT ;
GO
Declare @a varbinary(27); Declare @b varbinary(27); SET @a = CONVERT(VARBINARY(27), '0x121') ; EXEC babel_5059_proc_test_13_1 @a = @a , @b = @b OUT
GO

Declare @a varbinary(8000); Declare @b varbinary(8000); SET @a = 8000 ; EXEC babel_5059_proc_test_14 @a = @a , @b = @b OUT ;
GO

-- nchar
Declare @a nchar; Declare @b nchar; SET @a = 'abc' ; EXEC babel_5059_proc_test_15 @a = @a , @b = @b OUT ;
GO

Declare @a nchar(10); Declare @b nchar(10); SET @a = 'SELECT * FROM sys.databases' ; EXEC babel_5059_proc_test_16 @a = @a , @b = @b OUT ;
GO

Declare @a nchar(4000); Declare @b nchar(4000); SET @a = 'SELECT * FROM sys.databases' ; EXEC babel_5059_proc_test_17 @a = @a , @b = @b OUT ;
GO
Declare @a nchar(4000); Declare @b nchar(4000); SET @a = Replicate('A',9340);EXEC babel_5059_proc_test_17 @a = @a , @b = @b OUT ;
GO

-- smalldatetime
Declare @a smalldatetime; Declare @b smalldatetime; SET @a = '2024-09-01 10:00' ; EXEC babel_5059_proc_test_18 @a = @a , @b = @b OUT ;
GO

Declare @a smalldatetime(2); Declare @b smalldatetime(2); SET @a = '2024-09-01 10:40:10' ; EXEC babel_5059_proc_test_19 @a = @a , @b = @b OUT ;
GO

Declare @a smalldatetime(5); Declare @b smalldatetime(5); SET @a = '2024-09-01 10:40:10.5453' ; EXEC babel_5059_proc_test_20 @a = @a , @b = @b OUT ;
GO

Declare @a smalldatetime(6); Declare @b smalldatetime(6); SET @a = '2024-09-01 10:40:10' ; EXEC babel_5059_proc_test_21 @a = @a , @b = @b OUT ;
GO

--decimal
Declare @a decimal; Declare @b decimal; SET @a = 1234567.5678 ; EXEC babel_5059_proc_test_22 @a = @a , @b = @b OUT ;
GO

Declare @a decimal(38,18); Declare @b decimal(38,18); SET @a = 1234567.5678 ; EXEC babel_5059_proc_test_23 @a = @a , @b = @b OUT ;
GO

-- binary
Declare @a binary; Declare @b binary; SET @a = 0x01 ; EXEC babel_5059_proc_test_24 @a = @a , @b = @b OUT ;
GO

Declare @a binary; Declare @b binary; SET @a = 0x5465737442696E ; EXEC babel_5059_proc_test_25 @a = @a , @b = @b OUT ;
GO

Declare @a binary(10); Declare @b binary(10); SET @a = 0x5465737442696E ; EXEC babel_5059_proc_test_26 @a = @a , @b = @b OUT ;
GO

Declare @a binary(8000); Declare @b binary(8000); SET @a = 0x5465737442696E ; EXEC babel_5059_proc_test_27 @a = @a , @b = @b OUT ;
GO

-- bpchar/char
Declare @a char; Declare @b char; SET @a = 'abc' ; EXEC babel_5059_proc_test_28 @a = @a , @b = @b OUT ;
GO

Declare @a char(10); Declare @b char(10); SET @a = 'SELECT * FROM sys.databases' ; EXEC babel_5059_proc_test_29 @a = @a , @b = @b OUT ;
GO

Declare @a char(8000); Declare @b char(8000); SET @a = 'SELECT * FROM sys.databases' ; EXEC babel_5059_proc_test_30 @a = @a , @b = @b OUT ;
GO
Declare @a char(8000); Declare @b char(8000); SET @a = Replicate('A',9340); EXEC babel_5059_proc_test_30 @a = @a , @b = @b OUT ;
GO

-- misc
Declare @a smalldatetime; Declare @b varchar; SET @a = '2024-09-01 10:00' ; SET @b = 'abc' EXEC babel_5059_proc_test_main @a = @a , @b = @b OUT ;
GO

Declare @a varchar(max); Declare @b varchar; SET @a = Replicate('A',9340);EXEC babel_5059_proc_test_main2 @a = @a , @b = @b OUT ;
GO

-- UDT testing
-- nvarchar

Declare @a babel_5059_nvchar; Declare @b babel_5059_nvchar; SET @a = 'abc' ; EXEC babel_5059_proc_test_1_udt @a = @a , @b = @b OUT ;
GO

Declare @a babel_5059_nv_2; SET @a = 'SELECT * FROM sys.databases' ; EXEC babel_5059_proc_test_2_udt @a = @a OUT ;
GO

Declare @a babel_5059_nv_max; SET @a = 'abcdefghijk' ; EXEC babel_5059_proc_test_3_udt @a = @a OUT ;
GO

-- varchar
Declare @a babel_5059_vchar; Declare @b babel_5059_vchar; SET @a = 'abc' ; EXEC babel_5059_proc_test_4_udt @a = @a , @b = @b OUT ;
GO

DECLARE @a babel_5059_vchar_2; SET @a = 'abcdef'; EXEC babel_5059_proc_test_5_udt @a = @a OUT;
GO

Declare @a babel_5059_vchar_max; Declare @b babel_5059_vchar_max; SET @a = Replicate('A',9340);EXEC babel_5059_proc_test_6_udt @a = @a , @b = @b OUT ;
GO

-- varbinary

DECLARE @a babel_5059_varbinary; DECLARE @b babel_5059_varbinary; SET @a = 0x0123; EXEC babel_5059_proc_test_7_udt @a = @a, @b = @b OUT;
GO

DECLARE @a babel_5059_varbinary_2; SET @a = 0x0123; EXEC babel_5059_proc_test_8_udt @a = @a OUT;
GO

DECLARE @a babel_5059_varbinary_max; SET @a = 0x0123456789ABCDEF; EXEC babel_5059_proc_test_9_udt @a = @a OUT;
GO

-- nchar
DECLARE @a babel_5059_nchar; DECLARE @b babel_5059_nchar; SET @a = N'a'; EXEC babel_5059_proc_test_10_udt @a = @a, @b = @b OUT;
GO

DECLARE @a babel_5059_nchar_2; SET @a = N'abcd'; EXEC babel_5059_proc_test_11_udt @a = @a OUT;
GO

-- smalldatetime
DECLARE @a babel_5059_smalldatetime; DECLARE @b babel_5059_smalldatetime; SET @a = '2023-06-15 10:30:00';
EXEC babel_5059_proc_test_12_udt @a = @a, @b = @b OUT;
GO

-- decimal
DECLARE @a babel_5059_decimal; DECLARE @b babel_5059_decimal; SET @a = 123.45; EXEC babel_5059_proc_test_13_udt @a = @a, @b = @b OUT;
GO

DECLARE @a babel_5059_decimal_10_2; SET @a = 1234567.89; EXEC babel_5059_proc_test_14_udt @a = @a OUT;
GO

-- binary
Declare @a babel_5059_binary; Declare @b babel_5059_binary; SET @a = 0x01 ; EXEC babel_5059_proc_test_15_udt @a = @a , @b = @b OUT ;
GO

DECLARE @a babel_5059_binary_2; SET @a = 0x0123; EXEC babel_5059_proc_test_16_udt @a = @a OUT;
GO

-- char
DECLARE @a babel_5059_char; DECLARE @b babel_5059_char; SET @a = 'a'; EXEC babel_5059_proc_test_17_udt @a = @a, @b = @b OUT;
GO

DECLARE @a19 babel_5059_char_2; SET @a19 = 'SELECT * FROM sys.databases'; EXEC babel_5059_proc_test_18_udt @a = @a19 OUT;
GO

-- misc

Declare @a babel_5059_smalldatetime; Declare @b babel_5059_vchar; SET @a = '2024-09-01 10:00' ;
SET @b = 'abc' EXEC babel_5059_proc_test_19_udt @a = @a , @b = @b OUT ;
GO

Declare @a babel_5059_vchar_max; Declare @b babel_5059_vchar; SET @a = Replicate('A',9340);EXEC babel_5059_proc_test_20_udt @a = @a , @b = @b OUT ;
GO
