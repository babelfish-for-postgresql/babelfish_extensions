-- throws an error
SELECT SUM( sumbigint ) AS sum_bigint FROM babel_3144_vu_prepare_t1
GO

SELECT SUM( sumint ) AS sum_int FROM babel_3144_vu_prepare_t1
GO

-- empty table return value should be NULL
SELECT SUM( sumbigint ) AS sum_bigint FROM babel_3144_vu_prepare_t2
GO

SELECT SUM( sumint ) AS sum_int FROM babel_3144_vu_prepare_t2
GO

SELECT SUM( sumsmallint ) AS sum_smallintint FROM babel_3144_vu_prepare_t2
GO

SELECT SUM( sumtinyint ) AS sum_tinyint FROM babel_3144_vu_prepare_t2
GO


SELECT SUM( sumbigint ) AS sum_bigint FROM babel_3144_vu_prepare_t3
GO

SELECT SUM( sumint ) AS sum_int FROM babel_3144_vu_prepare_t3
GO

SELECT SUM( sumsmallint ) AS sum_smallintint FROM babel_3144_vu_prepare_t3
GO

SELECT SUM( sumtinyint ) AS sum_tinyint FROM babel_3144_vu_prepare_t3
GO

SELECT 
	cast(pg_typeof( SUM( sumbigint ) ) as varchar(48) )  as sum_bigint 
	, cast(pg_typeof( SUM( sumint ) ) as varchar(48) )  as sum_int 
	, cast(pg_typeof( SUM( sumsmallint ) ) as varchar(48) )  as sum_smallint 
	, cast(pg_typeof( SUM( sumtinyint ) ) as varchar(48) )  as sum_tinyint 
FROM babel_3144_vu_prepare_t3
GO

SELECT babel_3144_vu_prepare_f1()
GO

SELECT babel_3144_vu_prepare_f2()
GO

EXEC babel_3144_vu_prepare_p1
GO

-- throws an error
SELECT SUM( sumbigint ) AS sum_bigint FROM babel_3144_vu_prepare_t5
GO

SELECT SUM( sumint ) AS sum_int FROM babel_3144_vu_prepare_t5
GO

--GROUP BY CLAUSE
SELECT col1int,SUM(col2int) FROM babel_3144_vu_prepare_t6 GROUP BY col1int
GO

SELECT col1int,SUM(col3bigint) FROM babel_3144_vu_prepare_t6 GROUP BY col1int
GO

-- DISTINCT CLAUSE
SELECT SUM(DISTINCT col1int),SUM(DISTINCT col3bigint) FROM babel_3144_vu_prepare_t6
GO

--OVER,PARTITION CLAUSE
SELECT dt, priceint ,SUM(priceint) OVER (
ORDER BY dt
ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
) FiveDayMovSum
FROM babel_3144_vu_prepare_t7
GO

SELECT dt, pricebigint ,SUM(pricebigint) OVER (
ORDER BY dt
ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
) FiveDayMovSum
FROM babel_3144_vu_prepare_t7
GO

SELECT priceint,SUM(priceint) OVER(ORDER BY priceint) FROM babel_3144_vu_prepare_t7
GO

SELECT pricebigint,SUM(pricebigint) OVER(ORDER BY pricebigint) FROM babel_3144_vu_prepare_t7
GO

SELECT dept,SUM(priceint) OVER(PARTITION BY dept) FROM babel_3144_vu_prepare_t7
GO

SELECT dept,SUM(pricebigint) OVER(PARTITION BY dept) FROM babel_3144_vu_prepare_t7
GO

SELECT * FROM babel_3144_vu_prepare_v1
GO

DROP FUNCTION babel_3144_vu_prepare_f1
DROP FUNCTION babel_3144_vu_prepare_f2
DROP FUNCTION babel_3144_vu_prepare_f3
DROP FUNCTION babel_3144_vu_prepare_f4
GO

DROP PROCEDURE babel_3144_vu_prepare_p1
GO

DROP VIEW babel_3144_vu_prepare_v1
GO

DROP TABLE babel_3144_vu_prepare_t1
DROP TABLE babel_3144_vu_prepare_t2
DROP TABLE babel_3144_vu_prepare_t3
DROP TABLE babel_3144_vu_prepare_t4
DROP TABLE babel_3144_vu_prepare_t5
DROP TABLE babel_3144_vu_prepare_t6
DROP TABLE babel_3144_vu_prepare_t7
GO
