-- Procedure
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

DECLARE @Statement nvarchar(max) EXEC babel_5059_proc_test_main3 @Statement OUTPUT
GO

-- DDL export test for procedure

-- NVARCHAR
SELECT ROUTINE_DEFINITION from information_schema.routines WHERE SPECIFIC_SCHEMA = 'dbo' AND SPECIFIC_NAME = 'babel_5059_proc_test_1';
GO

-- NVARCHAR(MAX)
SELECT ROUTINE_DEFINITION from information_schema.routines WHERE SPECIFIC_SCHEMA = 'dbo' AND SPECIFIC_NAME = 'babel_5059_proc_test_main3';
GO

-- VARCHAR(MAX)
SELECT ROUTINE_DEFINITION from information_schema.routines WHERE SPECIFIC_SCHEMA = 'dbo' AND SPECIFIC_NAME = 'babel_5059_proc_test_7';
GO

-- VARBINARY(MAX)
SELECT ROUTINE_DEFINITION from information_schema.routines WHERE SPECIFIC_SCHEMA = 'dbo' AND SPECIFIC_NAME = 'babel_5059_proc_test_12';
GO

-- NVARCHAR(MAX) using UDT
SELECT ROUTINE_DEFINITION from information_schema.routines WHERE SPECIFIC_SCHEMA = 'dbo' AND SPECIFIC_NAME = 'babel_5059_proc_test_3_udt';
GO

-- VARCHAR(MAX) using UDT 
SELECT ROUTINE_DEFINITION from information_schema.routines WHERE SPECIFIC_SCHEMA = 'dbo' AND SPECIFIC_NAME = 'babel_5059_proc_test_6_udt';
GO

-- VARBINARY(MAX) using UDT
SELECT ROUTINE_DEFINITION from information_schema.routines WHERE SPECIFIC_SCHEMA = 'dbo' AND SPECIFIC_NAME = 'babel_5059_proc_test_9_udt';
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

-- Function
-- NVARCHAR
SELECT babel_5059_f1(N'Nvchar Value');
GO

SELECT babel_5059_f2(N'Nvchar max value');
GO

SELECT babel_5059_f2(N'Nv😆cha王小明r hello');
GO

DECLARE @inputString NVARCHAR(20) = N' abc约翰defgh'
SELECT babel_5059_f3(@inputString);
GO

-- VARCHAR
SELECT babel_5059_f4('Varchar Value');
GO

SELECT babel_5059_f5('Varchar Max Value');
GO

SELECT babel_5059_f6('Varchar Limited');
GO

-- VARBINARY
SELECT babel_5059_f7(CONVERT(VARBINARY, '0x121'));
GO

SELECT babel_5059_f8(CAST('Varbinary Max Value' AS VARBINARY(MAX)));
GO

SELECT babel_5059_f8(CONVERT(varbinary(max), Replicate('A',8000)));
GO

SELECT babel_5059_f9(CAST('Varbinary Limited' AS VARBINARY(20)));
GO

-- NCHAR
SELECT babel_5059_f10(N'N');
GO

SELECT babel_5059_f11(N'helloworld123');
GO

-- CHAR
SELECT babel_5059_f12('C');
GO

SELECT babel_5059_f13('helloworld');
GO

-- BINARY
SELECT babel_5059_f14(CAST('Binary' AS BINARY));
GO

SELECT babel_5059_f14(0x01);
GO

SELECT babel_5059_f15(CAST('Binary Limited' AS BINARY(10)));
GO

SELECT babel_5059_f15(0x5465737442696E);
GO

-- SMALLDATETIME
SELECT babel_5059_f16(CAST('2024-10-10 12:34:00' AS SMALLDATETIME));
GO

SELECT babel_5059_f16('2024-09-01 10:40:10.5453');
GO

-- DECIMAL
SELECT babel_5059_f17(12345.6789);
GO

SELECT babel_5059_f18(12345678901234567890.123456789012345678);
GO

-- DDL export test for functions

-- NVARCHAR -> NVARCHAR
SELECT ROUTINE_DEFINITION from information_schema.routines WHERE SPECIFIC_SCHEMA = 'dbo' AND SPECIFIC_NAME = 'babel_5059_f1';
GO

-- NVARCHAR(MAX) -> NVARCHAR(MAX)
SELECT ROUTINE_DEFINITION from information_schema.routines WHERE SPECIFIC_SCHEMA = 'dbo' AND SPECIFIC_NAME = 'babel_5059_f2';
GO

-- VARCHAR(MAX), VARCHAR(20) -> VARCHAR(MAX)
SELECT ROUTINE_DEFINITION from information_schema.routines WHERE SPECIFIC_SCHEMA = 'dbo' AND SPECIFIC_NAME = 'babel_5059_f20';
GO

-- VARBINARY(MAX) -> VARBINARY(MAX)
SELECT ROUTINE_DEFINITION from information_schema.routines WHERE SPECIFIC_SCHEMA = 'dbo' AND SPECIFIC_NAME = 'babel_5059_f8';
GO

--  VARCHAR, VARCHAR(2), VARCHAR(MAX) -> VARCHAR(MAX) using UDT
SELECT ROUTINE_DEFINITION from information_schema.routines WHERE SPECIFIC_SCHEMA = 'dbo' AND SPECIFIC_NAME = 'babel_5059_udt_f1';
GO

-- NVARCHAR types as input, NVARCHAR(MAX) as output using UDT
SELECT ROUTINE_DEFINITION from information_schema.routines WHERE SPECIFIC_SCHEMA = 'dbo' AND SPECIFIC_NAME = 'babel_5059_udt_f2';
GO

-- VARBINARY types as input, VARBINARY(MAX) as output using UDT
SELECT ROUTINE_DEFINITION from information_schema.routines WHERE SPECIFIC_SCHEMA = 'dbo' AND SPECIFIC_NAME = 'babel_5059_udt_f3';
GO

-- combination 
-- VARCHAR, VARCHAR(20) -> VARCHAR
SELECT babel_5059_f19('Hello', 'World');
GO

-- VARCHAR(MAX), VARCHAR(20) -> VARCHAR(MAX)
SELECT babel_5059_f20('This is a long string', 'Short');
GO

-- VARCHAR, VARCHAR(MAX) -> VARCHAR(20)
SELECT babel_5059_f21('Short String', 'This is a long string but it will be truncated to fit within the limit');
GO

-- VARCHAR(20), VARCHAR(20) -> VARCHAR(MAX)
SELECT babel_5059_f22('FirstPart', 'SecondPart');
GO

-- VARCHAR(MAX), VARCHAR -> VARCHAR(20)
SELECT babel_5059_f23('A very long string to test truncation', 'Short');
GO

-- VARBINARY(MAX) -> VARCHAR(MAX)
SELECT babel_5059_f24(CAST('BinaryData' AS VARBINARY(MAX)));
GO

-- NCHAR(20) -> VARCHAR
SELECT babel_5059_f25(N'Unicode Test');
GO

-- DECIMAL(10,2) -> VARCHAR(20)
SELECT babel_5059_f26(12345.67);
GO

-- SMALLDATETIME -> VARCHAR
SELECT babel_5059_f27(CAST('2024-10-14 15:30:00' AS SMALLDATETIME));
GO

-- VARBINARY(MAX), VARCHAR(MAX) -> VARCHAR(MAX)
SELECT babel_5059_f28(CAST('BinaryData' AS VARBINARY(MAX)), 'TextData');
GO

-- VARCHAR(20), VARCHAR(MAX) -> NCHAR(20)
SELECT babel_5059_f29('First Part', 'This is a longer part');
GO

-- VARCHAR, VARCHAR -> DECIMAL(10,2)
SELECT babel_5059_f30('100.50', '200.75');
GO

-- VARBINARY(20) -> VARCHAR(MAX)
SELECT babel_5059_f31(CAST('BinaryData' AS VARBINARY(20)));
GO

-- VARCHAR, CHAR(10) -> CHAR(10)
SELECT babel_5059_f32('Input', 'FixedWidth');
GO

-- BINARY(20) -> CHAR(10)
SELECT babel_5059_f33(CAST('BinaryInput' AS BINARY(20)));
GO

-- UDT
-- VARCHAR types as input, VARCHAR(MAX) as output
DECLARE @result1 babel_5059_vchar_max;
EXEC @result1 = babel_5059_udt_f1 'varchar_test', 'vc', 'varchar_max_test';
SELECT @result1 AS Result1;
GO

-- NVARCHAR types as input, NVARCHAR(MAX) as output
DECLARE @result2 babel_5059_nv_max;
EXEC @result2 = babel_5059_udt_f2 N'nvarchar_test', N'nv', N'nvarchar_max_test';
SELECT @result2 AS Result2;
GO

-- VARBINARY types as input, VARBINARY(MAX) as output
DECLARE @result3 babel_5059_varbinary_max;
EXEC @result3 = babel_5059_udt_f3 0x1234, 0x56, 0x7890ABCD;
SELECT @result3 AS Result3;
GO

-- NCHAR as input, NCHAR as output
DECLARE @result4 babel_5059_nchar;
EXEC @result4 = babel_5059_udt_f4 N'nc', N'xy';
SELECT @result4 AS Result4;
GO

-- SMALLDATETIME as input, SMALLDATETIME as output
DECLARE @result5 babel_5059_smalldatetime;
EXEC @result5 = babel_5059_udt_f5 '2024-10-14T15:30:00';
SELECT @result5 AS Result5;
GO

-- DECIMAL types as input, DECIMAL(10,2) as output
DECLARE @result6 babel_5059_decimal_10_2;
EXEC @result6 = babel_5059_udt_f6 12345.67, 9876.54;
SELECT @result6 AS Result6;
GO

-- BINARY types as input, BINARY as output
DECLARE @result7 babel_5059_binary;
EXEC @result7 = babel_5059_udt_f7 0x12, 0x34;
SELECT @result7 AS Result7;
GO

-- CHAR types as input, CHAR(2) as output
DECLARE @result8 babel_5059_char_2;
EXEC @result8 = babel_5059_udt_f8 'a', 'b';
SELECT @result8 AS Result8;
GO

-- Mixed input types, VARBINARY(MAX) as output
DECLARE @result9 babel_5059_varbinary_max;
EXEC @result9 = babel_5059_udt_f9 'varchar_test', N'nchar_test', 0x123456;
SELECT @result9 AS Result9;
GO

-- Mixed input types, DECIMAL(10,2) as output
DECLARE @result10 babel_5059_decimal_10_2;
EXEC @result10 = babel_5059_udt_f10 'varchar_test', N'nvarchar_test', 12345.67;
SELECT @result10 AS Result10;
GO

-- Mixed input types, VARCHAR(MAX) as output
DECLARE @result11 babel_5059_vchar_max;
EXEC @result11 = babel_5059_udt_f11 0x1234, 'varchar_max_test';
SELECT @result11 AS Result11;
GO

-- Mixed input types, NVARCHAR(MAX) as output
DECLARE @result12 babel_5059_nv_max;
EXEC @result12 = babel_5059_udt_f12 0x12, N'nvarchar_max_test';
SELECT @result12 AS Result12;
GO

-- Mixed input types, CHAR as output
DECLARE @result13 babel_5059_char;
EXEC @result13 = babel_5059_udt_f13 12345.67, 'ch';
SELECT @result13 AS Result13;
GO

DECLARE @result1 babel_5059_vchar_max; 
EXEC @result1 = babel_5059_udt_f14 'varchar_test', 'vc', 'varchar_max_test';
SELECT @result1 AS Result1;
GO

DECLARE @result1 babel_5059_vchar_max; 
EXEC @result1 = babel_5059_udt_f15 'varchar_test', 'vc', 'varchar_max_test'; 
SELECT @result1 AS Result1;
GO

DECLARE @result1 babel_5059_vchar; 
EXEC @result1 = babel_5059_udt_f16 'varchar_test', 'vc', 'varchar_max_test'; 
SELECT @result1 AS Result1;
GO

-- ITVF 
SELECT babel_5059_itvf_func1()
GO

SELECT babel_5059_itvf_func2()
GO

SELECT babel_5059_vu_prepare_f3()
GO

-- MSTVF
select * from babel_5059_vu_prepare_mstvf_1()
GO

select * from babel_5059_vu_prepare_mstvf_2(5)
GO
