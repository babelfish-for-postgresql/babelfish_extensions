-- Test casting functions
-- (var)binary <-> rowversion
SELECT CAST(CAST(0xfe AS binary(8)) AS rowversion),
       CAST(CAST(0xfe AS varbinary(8)) AS rowversion),
       CAST(CAST(0xfe AS rowversion) AS binary(8)),
       CAST(CAST(0xfe AS rowversion) AS varbinary(8));
GO

-- varchar -> rowversion
SELECT CAST(CAST('abc' AS varchar) AS rowversion),
       CAST(CAST('abc' AS char(3)) AS rowversion);
GO

-- int <-> rowversion
SELECT CAST(CAST(20 AS tinyint) AS rowversion),
       CAST(CAST(20 AS smallint) AS rowversion),
       CAST(CAST(20 AS int) AS rowversion),
       CAST(CAST(20 AS bigint) AS rowversion),
       CAST(CAST(20 AS rowversion) AS tinyint),
       CAST(CAST(20 AS rowversion) AS smallint),
       CAST(CAST(20 AS rowversion) AS int),
       CAST(CAST(20 AS rowversion) AS bigint);
GO

