-- Test implicit cast: bit -> int2/int4/int8
CREATE FUNCTION implicit_2int2(@i INT2)
RETURNS INT
AS
BEGIN
    RETURN (@i)
END;
GO
SELECT implicit_2int2(CAST(1 AS bit));
GO

CREATE FUNCTION implicit_2int4(@i INT4)
RETURNS INT
AS
BEGIN
    RETURN (@i)
END;
GO
SELECT implicit_2int4(CAST(1 AS bit));
GO

CREATE FUNCTION implicit_2int8(@i INT8)
RETURNS INT
AS
BEGIN
    RETURN (@i)
END;
GO
SELECT implicit_2int8(CAST(1 AS bit));
GO

-- Test implicit cast: int2/int4/int8 -> bit
CREATE FUNCTION implicit_2bit(@i bit)
RETURNS bit
AS
BEGIN
    RETURN (@i)
END;
GO
SELECT implicit_2bit(CAST(1 AS INT2));
GO
SELECT implicit_2bit(CAST(1 AS INT4));
GO
SELECT implicit_2bit(CAST(1 AS INT8));
GO



-- Test ISNULL() with bit and int arguments
SELECT ISNULL(CAST(1 AS bit), CAST(1 AS INT2))
GO
SELECT ISNULL(CAST(1 AS bit), CAST(1 AS INT4))
GO
SELECT ISNULL(CAST(1 AS bit), CAST(1 AS INT8))
GO
SELECT ISNULL(CAST(1 AS INT2), CAST(1 AS bit))
GO
SELECT ISNULL(CAST(1 AS INT4), CAST(1 AS bit))
GO
SELECT ISNULL(CAST(1 AS INT8), CAST(1 AS bit))
GO
