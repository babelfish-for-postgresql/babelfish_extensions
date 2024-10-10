-- nvarchar
CREATE PROCEDURE babel_5059_proc_test_1 (@a NVARCHAR, @b NVARCHAR OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE babel_5059_proc_test_1_1 (@a NVARCHAR, @b NVARCHAR OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE babel_5059_proc_test_1_2 (@a NVARCHAR, @b NVARCHAR OUTPUT) AS BEGIN SET @b=@a; SELECT len(@a); END;
GO

CREATE PROCEDURE babel_5059_proc_test_2 @a NVARCHAR(max) AS BEGIN SELECT @a; END;
GO

CREATE PROCEDURE babel_5059_proc_test_2_1 (@a NVARCHAR(max), @b NVARCHAR(max) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE babel_5059_proc_test_3 (@a NVARCHAR(5), @b NVARCHAR(5) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE babel_5059_proc_test_4 (@a NVARCHAR(50), @b NVARCHAR(50) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE babel_5059_proc_test_5 (@a NVARCHAR(4000), @b NVARCHAR(4000) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

-- varchar
CREATE PROCEDURE babel_5059_proc_test_6 (@a VARCHAR, @b VARCHAR OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE babel_5059_proc_test_7 (@a VARCHAR(max), @b VARCHAR(max) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE babel_5059_proc_test_8 (@a VARCHAR(5), @b VARCHAR(5) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE babel_5059_proc_test_9 (@a VARCHAR(50), @b VARCHAR(50) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE babel_5059_proc_test_10 (@a VARCHAR(8000), @b VARCHAR(8000) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

-- varbinary
CREATE PROCEDURE babel_5059_proc_test_11 (@a VARBINARY, @b VARBINARY OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE babel_5059_proc_test_11_1 (@a VARBINARY, @b VARBINARY OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE babel_5059_proc_test_12 (@a VARBINARY(MAX), @b VARBINARY(MAX) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE babel_5059_proc_test_13 (@a VARBINARY(27), @b VARBINARY(27) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE babel_5059_proc_test_13_1 (@a VARBINARY(27), @b VARBINARY(27) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE babel_5059_proc_test_14 (@a VARBINARY(8000), @b VARBINARY(8000) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO


-- nchar
CREATE PROCEDURE babel_5059_proc_test_15 (@a NCHAR, @b NCHAR OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE babel_5059_proc_test_16 (@a NCHAR(10), @b NCHAR(10) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE babel_5059_proc_test_17 (@a NCHAR(4000), @b NCHAR(4000) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO


-- smalldatetime
CREATE PROCEDURE babel_5059_proc_test_18 (@a smalldatetime, @b smalldatetime OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE babel_5059_proc_test_19 (@a smalldatetime(2), @b smalldatetime(2) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE babel_5059_proc_test_20 (@a smalldatetime(5), @b smalldatetime(5) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE babel_5059_proc_test_21 (@a smalldatetime(6), @b smalldatetime(6) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

-- decimal
CREATE PROCEDURE babel_5059_proc_test_22 (@a decimal, @b decimal OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE babel_5059_proc_test_23 (@a decimal(38,18), @b decimal(38,18) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO


-- binary
CREATE PROCEDURE babel_5059_proc_test_24 (@a binary, @b binary OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE babel_5059_proc_test_25 (@a binary, @b binary OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE babel_5059_proc_test_26 (@a binary(10), @b binary(10) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE babel_5059_proc_test_27 (@a binary(8000), @b binary(8000) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

-- bpchar/char
CREATE PROCEDURE babel_5059_proc_test_28 (@a char, @b char OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE babel_5059_proc_test_29 (@a char(10), @b char(10) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE babel_5059_proc_test_30 (@a char(8000), @b char(8000) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

-- misc
CREATE PROCEDURE babel_5059_proc_test_main (@a smalldatetime, @b varchar OUTPUT) AS BEGIN SELECT @a;SELECT @b; END;
GO

CREATE PROCEDURE babel_5059_proc_test_main2 (@a varchar(max), @b varchar OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

-- UDT testing
-- nvarchar
CREATE TYPE babel_5059_nvchar from nvarchar
GO

CREATE PROCEDURE babel_5059_proc_test_1_udt (@a babel_5059_nvchar, @b babel_5059_nvchar OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE TYPE babel_5059_nv_2 from nvarchar(2)
GO

CREATE PROCEDURE babel_5059_proc_test_2_udt @a babel_5059_nv_2 output AS BEGIN SELECT @a; END;
GO

CREATE TYPE babel_5059_nv_max from nvarchar(max)
GO

CREATE PROCEDURE babel_5059_proc_test_3_udt @a babel_5059_nv_max output AS BEGIN SELECT @a; END;
GO

-- varchar
CREATE TYPE babel_5059_vchar FROM varchar
GO

CREATE PROCEDURE babel_5059_proc_test_4_udt (@a babel_5059_vchar, @b babel_5059_vchar OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE TYPE babel_5059_vchar_2 FROM varchar(2)
GO

CREATE PROCEDURE babel_5059_proc_test_5_udt @a babel_5059_vchar_2 OUTPUT AS BEGIN SELECT @a; END;
GO

CREATE TYPE babel_5059_vchar_max from VARCHAR(max)
GO

CREATE PROCEDURE babel_5059_proc_test_6_udt (@a babel_5059_vchar_max, @b babel_5059_vchar_max OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

-- varbinary
CREATE TYPE babel_5059_varbinary FROM varbinary
GO

CREATE PROCEDURE babel_5059_proc_test_7_udt (@a babel_5059_varbinary, @b babel_5059_varbinary OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE TYPE babel_5059_varbinary_2 FROM varbinary(2)
GO

CREATE PROCEDURE babel_5059_proc_test_8_udt @a babel_5059_varbinary_2 OUTPUT AS BEGIN SELECT @a; END;
GO

CREATE TYPE babel_5059_varbinary_max FROM varbinary(max)
GO

CREATE PROCEDURE babel_5059_proc_test_9_udt @a babel_5059_varbinary_max OUTPUT AS BEGIN SELECT @a; END;
GO

-- nchar
CREATE TYPE babel_5059_nchar FROM nchar
GO

CREATE PROCEDURE babel_5059_proc_test_10_udt (@a babel_5059_nchar, @b babel_5059_nchar OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE TYPE babel_5059_nchar_2 FROM nchar(2)
GO

CREATE PROCEDURE babel_5059_proc_test_11_udt @a babel_5059_nchar_2 OUTPUT AS BEGIN SELECT @a; END;
GO

-- smalldatetime
CREATE TYPE babel_5059_smalldatetime FROM smalldatetime
GO

CREATE PROCEDURE babel_5059_proc_test_12_udt (@a babel_5059_smalldatetime, @b babel_5059_smalldatetime OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

-- decimal
CREATE TYPE babel_5059_decimal FROM decimal
GO

CREATE PROCEDURE babel_5059_proc_test_13_udt (@a babel_5059_decimal, @b babel_5059_decimal OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE TYPE babel_5059_decimal_10_2 FROM decimal(10,2)
GO

CREATE PROCEDURE babel_5059_proc_test_14_udt @a babel_5059_decimal_10_2 OUTPUT AS BEGIN SELECT @a; END;
GO

-- binary
CREATE TYPE babel_5059_binary FROM binary
GO

CREATE PROCEDURE babel_5059_proc_test_15_udt (@a babel_5059_binary, @b babel_5059_binary OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE TYPE babel_5059_binary_2 FROM binary(2)
GO

CREATE PROCEDURE babel_5059_proc_test_16_udt @a babel_5059_binary_2 OUTPUT AS BEGIN SELECT @a; END;
GO

-- char
CREATE TYPE babel_5059_char FROM char
GO

CREATE PROCEDURE babel_5059_proc_test_17_udt (@a babel_5059_char, @b babel_5059_char OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE TYPE babel_5059_char_2 FROM char(2)
GO

CREATE PROCEDURE babel_5059_proc_test_18_udt @a babel_5059_char_2 OUTPUT AS BEGIN SELECT @a; END;
GO

-- misc
CREATE PROCEDURE babel_5059_proc_test_19_udt (@a babel_5059_smalldatetime, @b babel_5059_vchar OUTPUT) AS BEGIN SELECT @a;SELECT @b; END;
GO

CREATE PROCEDURE babel_5059_proc_test_20_udt (@a babel_5059_vchar_max, @b babel_5059_vchar OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

