SELECT * FROM TestDatatypeAggSort_vu_prepare_char_view_max
go
SELECT * FROM TestDatatypeAggSort_vu_prepare_char_view_min
go

SELECT * FROM TestDatatypeAggSort_vu_prepare_varchar_view_max
go
SELECT * FROM TestDatatypeAggSort_vu_prepare_varchar_view_min
go

SELECT * FROM TestDatatypeAggSort_vu_prepare_datetime_view_max
go
SELECT * FROM TestDatatypeAggSort_vu_prepare_datetime_view_min
go

SELECT * FROM TestDatatypeAggSort_vu_prepare_datetime2_view_max
go
SELECT * FROM TestDatatypeAggSort_vu_prepare_datetime2_view_min
go

SELECT * FROM TestDatatypeAggSort_vu_prepare_datetimeoffset_view_max
go
SELECT * FROM TestDatatypeAggSort_vu_prepare_datetimeoffset_view_min
go

SELECT * FROM TestDatatypeAggSort_vu_prepare_smalldatetime_view_max
go
SELECT * FROM TestDatatypeAggSort_vu_prepare_smalldatetime_view_min
go

EXEC TestDatatypeAggSort_vu_prepare_proc
go

SELECT * FROM TestDatatypeAggSort_vu_prepare_tbl2 ORDER BY max_min
go

-- This is failing because of BABEL-4332
SELECT MAX(char_col) FROM TestDatatypeAggSort_vu_prepare_tbl WHERE varchar_col <= 'xxx'
go
SELECT MIN(char_col) FROM TestDatatypeAggSort_vu_prepare_tbl WHERE varchar_col <= 'xxx'
go

SELECT MAX(varchar_col) FROM TestDatatypeAggSort_vu_prepare_tbl WHERE varchar_col <= 'xxx'
go
SELECT MIN(varchar_col) FROM TestDatatypeAggSort_vu_prepare_tbl WHERE varchar_col > 'xxx'
go

SELECT MAX(datetime_col) FROM TestDatatypeAggSort_vu_prepare_tbl WHERE datetime_col <= '2020-12-31 23:59:59'
go
SELECT MIN(datetime_col) FROM TestDatatypeAggSort_vu_prepare_tbl WHERE datetime_col > '2020-12-31 23:59:59'
go

SELECT MAX(datetime2_col) FROM TestDatatypeAggSort_vu_prepare_tbl WHERE datetime2_col <= '2020-12-31 23:59:59'
go
SELECT MIN(datetime2_col) FROM TestDatatypeAggSort_vu_prepare_tbl WHERE datetime2_col > '2020-12-31 23:59:59'
go

SELECT MAX(datetimeoffset_col) FROM TestDatatypeAggSort_vu_prepare_tbl WHERE datetimeoffset_col <= '2020-12-31 23:59:59'
go
SELECT MIN(datetimeoffset_col) FROM TestDatatypeAggSort_vu_prepare_tbl WHERE datetimeoffset_col > '2020-12-31 23:59:59'
go

SELECT MAX(smalldatetime_col) FROM TestDatatypeAggSort_vu_prepare_tbl WHERE smalldatetime_col <= '2020-12-31 23:59:59'
go
SELECT MIN(smalldatetime_col) FROM TestDatatypeAggSort_vu_prepare_tbl WHERE smalldatetime_col > '2020-12-31 23:59:59'
go
