-- Test cast between varbinary and varbinary
select CAST(CAST(0x01 AS varbinary) AS binary(1));
go
select CAST(CAST(0x01 AS binary(1)) AS varbinary);
go

-- Test cast between varbinary and varbinary with sqlvariant
select CAST(CAST(CAST(0x0101 AS varbinary) AS sql_variant) AS binary(2));
go
select CAST(CAST(CAST(0x0101 AS binary(2)) AS sql_variant) AS varbinary);
go

-- Test Comparison bewteen two binary
if CAST(0x01 AS binary(1)) = CAST(0x02 AS binary(1))
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x01 AS binary(1)) <> CAST(0x02 AS binary(1))
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x01 AS binary(1)) < CAST(0x02 AS binary(1))
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x01 AS binary(1)) <= CAST(0x02 AS binary(1))
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x0001 AS binary(2)) <= CAST(0x0001 AS binary(2))
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x0001 AS binary(2)) > CAST(0x0002 AS binary(2))
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x0101 AS binary(2)) >= CAST(0x0102 AS binary(2))
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x0101 AS binary(2)) >= CAST(0x0101 AS binary(2))
	SELECT 1
ELSE 
	SELECT 0
GO

-- Test Comparison bewteen two varbinary
if CAST(0x01 AS varbinary) = CAST(0x02 AS varbinary)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x01 AS varbinary) <> CAST(0x02 AS varbinary)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x01 AS varbinary) < CAST(0x02 AS varbinary)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x01 AS varbinary) <= CAST(0x02 AS varbinary)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x0001 AS varbinary) <= CAST(0x0001 AS varbinary)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x0001 AS varbinary) > CAST(0x0002 AS varbinary)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x0101 AS varbinary) >= CAST(0x0102 AS varbinary)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x0101 AS varbinary) >= CAST(0x0101 AS varbinary)
	SELECT 1
ELSE 
	SELECT 0
GO

-- Test Comparison bewteen binary and varbinary
if CAST(0x01 AS varbinary) = CAST(0x02 AS varbinary)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x01 AS binary(1)) <> CAST(0x02 AS binary(1))
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x01 AS varbinary) < CAST(0x02 AS binary(1))
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x01 AS binary(1)) <= CAST(0x02 AS varbinary)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x01 AS varbinary) > CAST(0x02 AS binary(1))
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x01 AS binary(1)) >= CAST(0x02 AS varbinary)
	SELECT 1
ELSE 
	SELECT 0
GO

-- Test Comparison between sqlvariant binary and varbinary
if CAST(CAST(0x01 AS varbinary) AS sql_variant) = CAST(CAST(0x02 AS varbinary) AS sql_variant)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(CAST(0x01 AS binary(1)) AS sql_variant) <> CAST(CAST(0x02 AS binary(1)) AS sql_variant)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(CAST(0x01 AS varbinary) AS sql_variant) < CAST(CAST(0x02 AS binary(1)) AS sql_variant)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(CAST(0x01 AS binary(1)) AS sql_variant) <= CAST(CAST(0x02 AS varbinary) AS sql_variant)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(CAST(0x01 AS varbinary) AS sql_variant) > CAST(CAST(0x02 AS binary(1)) AS sql_variant)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(CAST(0x01 AS binary(1)) AS sql_variant) >= CAST(CAST(0x02 AS varbinary) AS sql_variant)
	SELECT 1
ELSE 
	SELECT 0
GO

-- Test Comparison of binary and varbinary with unequal length
if CAST(0x0100 AS varbinary) = CAST(0x01 AS varbinary)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x0001 AS varbinary) = CAST(0x01 AS varbinary)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(CAST(0x0100 AS varbinary) AS sql_variant) <> CAST(CAST(0x01 AS varbinary) AS sql_variant)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(CAST(0x0001 AS varbinary) AS sql_variant) <> CAST(CAST(0x01 AS varbinary) AS sql_variant)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x0101 AS varbinary) > CAST(0x01 AS varbinary)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(0x0100 AS varbinary) > CAST(0x01 AS varbinary)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(CAST(0x01 AS varbinary) AS sql_variant) < CAST(CAST(0x0101 AS varbinary) AS sql_variant)
	SELECT 1
ELSE 
	SELECT 0
GO
if CAST(CAST(0x01 AS varbinary) AS sql_variant) < CAST(CAST(0x0100 AS varbinary) AS sql_variant)
    SELECT 1
ELSE 
	SELECT 0
GO