-- throws an error
SELECT SUM( sumbigint ) AS sum_bigint FROM babel_3144_vu_preppare_t1
GO

SELECT SUM( sumint ) AS sum_int FROM babel_3144_vu_preppare_t1
GO

-- empty table return value should be NULL
SELECT SUM( sumbigint ) AS sum_bigint FROM babel_3144_vu_preppare_t2
GO

SELECT SUM( sumint ) AS sum_int FROM babel_3144_vu_preppare_t2
GO

SELECT SUM( sumsmallint ) AS sum_smallintint FROM babel_3144_vu_preppare_t2
GO

SELECT SUM( sumtinyint ) AS sum_tinyint FROM babel_3144_vu_preppare_t2
GO

SELECT SUM( sumbigint ) AS sum_bigint FROM babel_3144_vu_preppare_t3
GO

SELECT SUM( sumint ) AS sum_int FROM babel_3144_vu_preppare_t3
GO

SELECT SUM( sumsmallint ) AS sum_smallintint FROM babel_3144_vu_preppare_t3
GO

SELECT SUM( sumtinyint ) AS sum_tinyint FROM babel_3144_vu_preppare_t3
GO

SELECT 
	cast(pg_typeof( SUM( sumbigint ) ) as varchar(48) )  as sum_bigint 
	, cast(pg_typeof( SUM( sumint ) ) as varchar(48) )  as sum_int 
	, cast(pg_typeof( SUM( sumsmallint ) ) as varchar(48) )  as sum_smallint 
	, cast(pg_typeof( SUM( sumtinyint ) ) as varchar(48) )  as sum_tinyint 
FROM babel_3144_vu_preppare_t3
GO

SELECT * FROM babel_3144_vu_prepare_v1
GO

DROP VIEW babel_3144_vu_prepare_v1
GO

DROP TABLE babel_3144_vu_preppare_t1
DROP TABLE babel_3144_vu_preppare_t2
DROP TABLE babel_3144_vu_preppare_t3
DROP TABLE babel_3144_vu_preppare_t4
GO