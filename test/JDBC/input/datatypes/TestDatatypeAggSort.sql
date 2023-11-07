-- MAX/MIN functionality already verified in upgrade scripts.
-- This test mainly focuses on query plans.
CREATE TABLE TestDatatypeAggSort_tbl (
	char_col CHAR(10), 
	varchar_col VARCHAR(10),
	datetime_col DATETIME,
	datetime2_col DATETIME2,
	datetimeoffset_col DATETIMEOFFSET,
	smalldatetime_col SMALLDATETIME,
);
go

INSERT INTO TestDatatypeAggSort_tbl VALUES (
	'abc', 'abc',
	'1900-01-01 00:00:00.000',
	'1900-01-01 00:00:00.000',
	'1900-01-01 00:00:00.000 +0:00',
	'1900-01-01 00:00:00.000'
), (
	'def', 'def',
	'1950-01-01 00:00:00.000',
	'1950-01-01 00:00:00.000',
	'1950-01-01 00:00:00.000 +0:00',
	'1950-01-01 00:00:00.000'
), (
	'ghi', 'ghi',
	'2000-01-01 00:00:00.000',
	'2000-01-01 00:00:00.000',
	'2000-01-01 00:00:00.000 +0:00',
	'2000-01-01 00:00:00.000'
), (
	'jkl', 'jkl',
	'2005-01-01 00:00:00.000',
	'2005-01-01 00:00:00.000',
	'2005-01-01 00:00:00.000 +0:00',
	'2005-01-01 00:00:00.000'
), (
	'mno', 'mno',
	'2010-01-01 00:00:00.000',
	'2010-01-01 00:00:00.000',
	'2010-01-01 00:00:00.000 +0:00',
	'2010-01-01 00:00:00.000'
), (
	'pqr', 'pqr',
	'2015-01-01 00:00:00.000',
	'2015-01-01 00:00:00.000',
	'2015-01-01 00:00:00.000 +0:00',
	'2015-01-01 00:00:00.000'
), (
	'stu', 'stu',
	'2020-01-01 00:00:00.000',
	'2020-01-01 00:00:00.000',
	'2020-01-01 00:00:00.000 +0:00',
	'2020-01-01 00:00:00.000'
), (
	'xyz', 'xyz',
	'2023-11-06 00:00:00.000',
	'2023-11-06 00:00:00.000',
	'2023-11-06 00:00:00.000 +0:00',
	'2023-11-06 00:00:00.000'
), (
	NULL, NULL, NULL, NULL, NULL, NULL
);
go

CREATE INDEX TestDatatypeAggSort_vu_prepare_char_idx ON TestDatatypeAggSort_tbl (char_col)
go
CREATE INDEX TestDatatypeAggSort_vu_prepare_varchar_idx ON TestDatatypeAggSort_tbl (varchar_col)
go
CREATE INDEX TestDatatypeAggSort_vu_prepare_datetime_idx ON TestDatatypeAggSort_tbl (datetime_col)
go
CREATE INDEX TestDatatypeAggSort_vu_prepare_datetime2_idx ON TestDatatypeAggSort_tbl (datetime2_col)
go
CREATE INDEX TestDatatypeAggSort_vu_prepare_datetimeoffset_idx ON TestDatatypeAggSort_tbl (datetimeoffset_col)
go
CREATE INDEX TestDatatypeAggSort_vu_prepare_smalldatetime_idx ON TestDatatypeAggSort_tbl (smalldatetime_col)
go


-- Check query plans, all aggregations should be optimized 
-- into LIMIT + index scan.
SELECT set_config('enable_seqscan', 'off', false)
go
SET babelfish_showplan_all ON
go

-- This is failing because of BABEL-4332
SELECT MAX(char_col) FROM TestDatatypeAggSort_tbl WHERE varchar_col <= 'xxx'
go
SELECT MIN(char_col) FROM TestDatatypeAggSort_tbl WHERE varchar_col <= 'xxx'
go

SELECT MAX(varchar_col) FROM TestDatatypeAggSort_tbl WHERE varchar_col <= 'xxx'
go
SELECT MIN(varchar_col) FROM TestDatatypeAggSort_tbl WHERE varchar_col > 'xxx'
go

SELECT MAX(datetime_col) FROM TestDatatypeAggSort_tbl WHERE datetime_col <= '2020-12-31 23:59:59'
go
SELECT MIN(datetime_col) FROM TestDatatypeAggSort_tbl WHERE datetime_col > '2020-12-31 23:59:59'
go

SELECT MAX(datetime2_col) FROM TestDatatypeAggSort_tbl WHERE datetime2_col <= '2020-12-31 23:59:59'
go
SELECT MIN(datetime2_col) FROM TestDatatypeAggSort_tbl WHERE datetime2_col > '2020-12-31 23:59:59'
go

SELECT MAX(datetimeoffset_col) FROM TestDatatypeAggSort_tbl WHERE datetimeoffset_col <= '2020-12-31 23:59:59'
go
SELECT MIN(datetimeoffset_col) FROM TestDatatypeAggSort_tbl WHERE datetimeoffset_col > '2020-12-31 23:59:59'
go

SELECT MAX(smalldatetime_col) FROM TestDatatypeAggSort_tbl WHERE smalldatetime_col <= '2020-12-31 23:59:59'
go
SELECT MIN(smalldatetime_col) FROM TestDatatypeAggSort_tbl WHERE smalldatetime_col > '2020-12-31 23:59:59'
go

-- Reset
SET babelfish_showplan_all OFF
go
SELECT set_config('enable_seqscan', 'on', false)
go

DROP TABLE TestDatatypeAggSort_tbl
go
