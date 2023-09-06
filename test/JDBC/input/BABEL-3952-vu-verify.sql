-- Test with null datepart
-- Should Throw Error - 'syntax error at or near "null"' (error from parser side)
select date_bucket(null, 2, cast('2020-01-01' as date)) as db
GO

select date_bucket(null, null, cast('2020-01-01' as date)) as db2
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v3
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v4
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v5
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v6
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v7
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v8
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v9
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v10
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v11
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v11_2
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v12
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v12_origin_IS_NULL
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v13
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v14
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v15
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v16
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v17
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v18
GO

-- Should Throw - data out of range for datetimeoffset
select date_bucket(day, 1, cast('0001-01-01 00:00:00 +14:00' as datetimeoffset), cast('9999-12-31 23:59:59.999999 +14:00' as datetimeoffset)) as db1
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v20
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v21
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v22
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v23
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v24
GO

SELECT * FROM DATE_BUCKET_vu_prepare_invalid_datepart
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v25
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v26
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v27
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v28
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v29
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v30
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v31
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v32
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v33
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v34
GO
 
SELECT * FROM DATE_BUCKET_vu_prepare_v35
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v36
GO
 
SELECT * FROM DATE_BUCKET_vu_prepare_v37
GO
 
SELECT * FROM DATE_BUCKET_vu_prepare_v38
GO
 
SELECT * FROM DATE_BUCKET_vu_prepare_v39
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v40
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v41
GO
 
SELECT * FROM DATE_BUCKET_vu_prepare_v42
GO
 
SELECT * FROM DATE_BUCKET_vu_prepare_v43
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v44
GO
 
SELECT * FROM DATE_BUCKET_vu_prepare_v45
GO
 
SELECT * FROM DATE_BUCKET_vu_prepare_v46
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v47
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v48
GO

SELECT * FROM DATE_BUCKET_vu_prepare_v49
GO

SELECT DATE_BUCKET(m, 5, CAST('2034-09-23 08:34:32.432' as datetime)) as db6
GO

SELECT DATE_BUCKET(month, 2, CAST('2000-01-01 23:58:59' AS SMALLDATETIME), CAST('1909-02-11 21:55:56' AS SMALLDATETIME)) AS MONTHS_BUCKET
GO

SELECT DATE_BUCKET(day, 2, CAST('1916-08-15 22:35:05.422456' AS DATETIME2), CAST('2000-01-01 23:30:05.523456' AS DATETIME2)) AS DAYS_BUCKET
GO

SELECT DATE_BUCKET(month, 2, CAST('2000-01-01' AS DATE), CAST('1905-09-12' AS DATE)) AS MONTHS_BUCKET
GO

SELECT date_bucket(second, 1, cast('2020-08-02 02:12:30.4463 +00:00' as datetimeoffset), cast('2019-08-02 02:12:30.4467 +00:00' as datetimeoffset)) AS second_BUCKET
GO

SELECT DATE_BUCKET(second, 2, CAST('12:23:56.846363' AS TIME), CAST('23:58:59.546446' AS TIME)) AS SECONDS_BUCKET
GO
