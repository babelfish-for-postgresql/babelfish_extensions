-- throws an error due to overflow
SELECT AVG( avgbigint ) AS avg_bigint FROM avg_agg_vu_prepare_t1
GO

SELECT AVG( avgint ) AS avg_int FROM avg_agg_vu_prepare_t1
GO

-- empty table return value should be NULL
SELECT AVG( avgbigint ) AS avg_bigint FROM avg_agg_vu_prepare_t2
GO

SELECT AVG( avgint ) AS avg_int FROM avg_agg_vu_prepare_t2
GO

SELECT AVG( avgsmallint ) AS avg_smallintint FROM avg_agg_vu_prepare_t2
GO

SELECT AVG( avgtinyint ) AS avg_tinyint FROM avg_agg_vu_prepare_t2
GO

-- sanity check
SELECT AVG( avgbigint ) AS avg_bigint FROM avg_agg_vu_prepare_t3
GO

SELECT AVG( avgint ) AS avg_int FROM avg_agg_vu_prepare_t3
GO

SELECT AVG( avgsmallint ) AS avg_smallintint FROM avg_agg_vu_prepare_t3
GO

SELECT AVG( avgtinyint ) AS avg_tinyint FROM avg_agg_vu_prepare_t3
GO

-- Check the return type for all integer datatypes
SELECT 
	cast(pg_typeof( AVG( avgbigint ) ) as varchar(48) )  as avg_bigint 
	, cast(pg_typeof( AVG( avgint ) ) as varchar(48) )  as avg_int 
	, cast(pg_typeof( AVG( avgsmallint ) ) as varchar(48) )  as avg_smallint 
	, cast(pg_typeof( AVG( avgtinyint ) ) as varchar(48) )  as avg_tinyint 
FROM avg_agg_vu_prepare_t3
GO

-- throws an error due to undeflow
SELECT AVG( avgbigint ) AS avg_bigint FROM avg_agg_vu_prepare_t4
GO

SELECT AVG( avgint ) AS avg_int FROM avg_agg_vu_prepare_t4
GO

--GROUP BY CLAUSE
SELECT col1int,AVG(col2int) FROM avg_agg_vu_prepare_t5 GROUP BY col1int
GO

SELECT col1int,AVG(col3bigint) FROM avg_agg_vu_prepare_t5 GROUP BY col1int
GO

-- DISTINCT CLAUSE
SELECT AVG(DISTINCT col1int),AVG(DISTINCT col3bigint) FROM avg_agg_vu_prepare_t5
GO

--OVER,PARTITION CLAUSE
SELECT dt, priceint ,AVG(priceint) OVER (
ORDER BY dt
ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
) FiveDayMovAvg
FROM avg_agg_vu_prepare_t6
GO

SELECT dt, pricebigint ,AVG(pricebigint) OVER (
ORDER BY dt
ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
) FiveDayMovAvg
FROM avg_agg_vu_prepare_t6
GO

SELECT priceint,AVG(priceint) OVER(ORDER BY priceint) FROM avg_agg_vu_prepare_t6
GO

SELECT pricebigint,AVG(pricebigint) OVER(ORDER BY pricebigint) FROM avg_agg_vu_prepare_t6
GO

SELECT dept,AVG(priceint) OVER(PARTITION BY dept) FROM avg_agg_vu_prepare_t6
GO

SELECT dept,AVG(pricebigint) OVER(PARTITION BY dept) FROM avg_agg_vu_prepare_t6
GO

-- Check for mix values
SELECT AVG( avgbigint ) AS avg_bigint FROM avg_agg_vu_prepare_t7
GO

SELECT AVG( avgint ) AS avg_int FROM avg_agg_vu_prepare_t7
GO

SELECT AVG( avgsmallint ) AS avg_smallintint FROM avg_agg_vu_prepare_t7
GO

SELECT AVG( avgtinyint ) AS avg_tinyint FROM avg_agg_vu_prepare_t7
GO

SELECT AVG( avgbigint ) AS avg_bigint FROM avg_agg_vu_prepare_t8
GO

SELECT AVG( avgint ) AS avg_int FROM avg_agg_vu_prepare_t8
GO

SELECT AVG( avgsmallint ) AS avg_smallintint FROM avg_agg_vu_prepare_t8
GO

SELECT AVG( avgtinyint ) AS avg_tinyint FROM avg_agg_vu_prepare_t8
GO

-- Cleanup
DROP TABLE avg_agg_vu_prepare_t1
DROP TABLE avg_agg_vu_prepare_t2
DROP TABLE avg_agg_vu_prepare_t3
DROP TABLE avg_agg_vu_prepare_t4
DROP TABLE avg_agg_vu_prepare_t5
DROP TABLE avg_agg_vu_prepare_t6
DROP TABLE avg_agg_vu_prepare_t7
DROP TABLE avg_agg_vu_prepare_t8
GO