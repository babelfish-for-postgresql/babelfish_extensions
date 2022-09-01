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

DROP FUNCTION babel_3144_vu_prepare_f1
DROP FUNCTION babel_3144_vu_prepare_f2
GO

DROP PROCEDURE babel_3144_vu_prepare_p1
GO

DROP TABLE babel_3144_vu_prepare_t1
DROP TABLE babel_3144_vu_prepare_t2
DROP TABLE babel_3144_vu_prepare_t3
DROP TABLE babel_3144_vu_prepare_t4
DROP TABLE babel_3144_vu_prepare_t5
GO