-- nvarchar
CREATE PROCEDURE proc_test_1 (@a NVARCHAR, @b NVARCHAR OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE proc_test_1_1 (@a NVARCHAR, @b NVARCHAR OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE proc_test_2 (@a NVARCHAR(max), @b NVARCHAR(max) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE proc_test_3 (@a NVARCHAR(5), @b NVARCHAR(5) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE proc_test_4 (@a NVARCHAR(50), @b NVARCHAR(50) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE proc_test_5 (@a NVARCHAR(4000), @b NVARCHAR(4000) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

-- varchar
CREATE PROCEDURE proc_test_6 (@a VARCHAR, @b VARCHAR OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE proc_test_7 (@a VARCHAR(max), @b VARCHAR(max) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE proc_test_8 (@a VARCHAR(5), @b VARCHAR(5) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE proc_test_9 (@a VARCHAR(50), @b VARCHAR(50) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE proc_test_10 (@a VARCHAR(8000), @b VARCHAR(8000) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

-- varbinary
CREATE PROCEDURE proc_test_11 (@a VARBINARY, @b VARBINARY OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE proc_test_11_1 (@a VARBINARY, @b VARBINARY OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE proc_test_12 (@a VARBINARY(MAX), @b VARBINARY(MAX) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE proc_test_13 (@a VARBINARY(27), @b VARBINARY(27) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE proc_test_13_1 (@a VARBINARY(27), @b VARBINARY(27) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE proc_test_14 (@a VARBINARY(8000), @b VARBINARY(8000) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO


-- nchar
CREATE PROCEDURE proc_test_15 (@a NCHAR, @b NCHAR OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE proc_test_16 (@a NCHAR(10), @b NCHAR(10) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE proc_test_17 (@a NCHAR(4000), @b NCHAR(4000) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO


-- smalldatetime
CREATE PROCEDURE proc_test_18 (@a smalldatetime, @b smalldatetime OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE proc_test_19 (@a smalldatetime(2), @b smalldatetime(2) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE proc_test_20 (@a smalldatetime(5), @b smalldatetime(5) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE proc_test_21 (@a smalldatetime(6), @b smalldatetime(6) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

-- decimal
CREATE PROCEDURE proc_test_22 (@a decimal, @b decimal OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE proc_test_23 (@a decimal(38,18), @b decimal(38,18) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO


-- binary
CREATE PROCEDURE proc_test_24 (@a binary, @b binary OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE proc_test_25 (@a binary, @b binary OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE proc_test_26 (@a binary(10), @b binary(10) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE proc_test_27 (@a binary(8000), @b binary(8000) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

-- bpchar
CREATE PROCEDURE proc_test_28 (@a bpchar, @b bpchar OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

CREATE PROCEDURE proc_test_29 (@a bpchar(10), @b bpchar(10) OUTPUT) AS BEGIN SET @b=@a; SELECT @b; END;
GO

CREATE PROCEDURE proc_test_30 (@a bpchar(8000), @b bpchar(8000) OUTPUT) AS BEGIN SET @b=@a; SELECT len(@b); END;
GO

