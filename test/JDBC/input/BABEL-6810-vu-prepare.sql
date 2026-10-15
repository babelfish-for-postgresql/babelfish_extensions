-- Table-valued functions returning sql_variant and nvarchar columns
CREATE FUNCTION babel_6810_vu_prepare_tvf_variant(@customerRef NVARCHAR(50))
RETURNS @AddressTable TABLE (Address SQL_VARIANT)
AS
BEGIN
	INSERT INTO @AddressTable VALUES (@customerRef)
	RETURN
END
GO

CREATE FUNCTION babel_6810_vu_prepare_tvf_nvarchar(@customerRef NVARCHAR(50))
RETURNS @AddressTable TABLE (Address NVARCHAR(50))
AS
BEGIN
	INSERT INTO @AddressTable VALUES (@customerRef)
	RETURN
END
GO

-- Procedures that invoke a table-valued function via EXEC
CREATE PROCEDURE babel_6810_vu_prepare_call_variant @customerRef NVARCHAR(50)
AS
BEGIN
	EXEC babel_6810_vu_prepare_tvf_variant @customerRef = @customerRef
END
GO

CREATE PROCEDURE babel_6810_vu_prepare_call_nvarchar @customerRef NVARCHAR(50)
AS
BEGIN
	EXEC babel_6810_vu_prepare_tvf_nvarchar @customerRef = @customerRef
END
GO

CREATE PROCEDURE babel_6810_vu_prepare_call_positional @customerRef NVARCHAR(50)
AS
BEGIN
	EXEC babel_6810_vu_prepare_tvf_nvarchar @customerRef
END
GO

-- Procedures exercising named-argument calls, an OUTPUT parameter and a default
CREATE PROCEDURE babel_6810_vu_prepare_add @a INT, @b INT
AS
BEGIN
	SELECT @a + @b AS sum
END
GO

CREATE PROCEDURE babel_6810_vu_prepare_out @x INT, @y INT OUTPUT
AS
BEGIN
	SET @y = @x * 10
END
GO

CREATE PROCEDURE babel_6810_vu_prepare_def @a INT, @b INT = 100
AS
BEGIN
	SELECT @a + @b AS total
END
GO
