create table exactnumeric_table (
	id int,
	tinyint_col tinyint,
	smallint_col smallint,
	integer_col integer,
	bigint_col bigint
);
GO

-- min value testing
INSERT INTO exactnumeric_table (tinyint_col) VALUES (0);
GO

INSERT INTO exactnumeric_table (smallint_col) VALUES (-32768);
GO

INSERT INTO exactnumeric_table (integer_col) VALUES (-2147483648);
GO

INSERT INTO exactnumeric_table (bigint_col) VALUES (-9223372036854775808);
GO

-- max value testing
INSERT INTO exactnumeric_table (tinyint_col) VALUES (127);
GO

INSERT INTO exactnumeric_table (smallint_col) VALUES (32767);
GO

INSERT INTO exactnumeric_table (integer_col) VALUES (2147483647);
GO

INSERT INTO exactnumeric_table (bigint_col) VALUES (9223372036854775807);
GO

-- insert null value
INSERT INTO exactnumeric_table (tinyint_col) VALUES (null);
GO

INSERT INTO exactnumeric_table (smallint_col) VALUES (null);
GO

INSERT INTO exactnumeric_table (integer_col) VALUES (null);
GO

INSERT INTO exactnumeric_table (bigint_col) VALUES (null);
GO

-- inserting zero value
INSERT INTO exactnumeric_table (tinyint_col) VALUES (0);
GO

INSERT INTO exactnumeric_table (smallint_col) VALUES (0);
GO

INSERT INTO exactnumeric_table (integer_col) VALUES (0);
GO

INSERT INTO exactnumeric_table (bigint_col) VALUES (0);
GO

-- inserting negative zero value
INSERT INTO exactnumeric_table (tinyint_col) VALUES (-0);
GO

INSERT INTO exactnumeric_table (smallint_col) VALUES (-0);
GO

INSERT INTO exactnumeric_table (integer_col) VALUES (-0);
GO

INSERT INTO exactnumeric_table (bigint_col) VALUES (-0);
GO

-- overflow testing
INSERT INTO exactnumeric_table (tinyint_col) VALUES (-1);
GO

INSERT INTO exactnumeric_table (smallint_col) VALUES (-32769);
GO

INSERT INTO exactnumeric_table (integer_col) VALUES (-2147483649);
GO

INSERT INTO exactnumeric_table (bigint_col) VALUES (-9223372036854775809);
GO

INSERT INTO exactnumeric_table (tinyint_col) VALUES (128);
GO

INSERT INTO exactnumeric_table (smallint_col) VALUES (32768);
GO

INSERT INTO exactnumeric_table (integer_col) VALUES (2147483648);
GO

INSERT INTO exactnumeric_table (bigint_col) VALUES (9223372036854775808);
GO

-- inserting data
INSERT INTO exactnumeric_table (id, tinyint_col, smallint_col, integer_col, bigint_col) VALUES (1, 5, 100, 10000, 1000000000);
GO

-- ABS function testing
SELECT
	ABS(tinyint_col) AS abs_tinyint,
	ABS(smallint_col) AS abs_smallint,
	ABS(integer_col) AS abs_integer,
	ABS(bigint_col) AS abs_bigint
FROM exactnumeric_table
WHERE
	tinyint_col != 0 AND
	smallint_col != -32768 AND
	integer_col != -2147483648 AND
	bigint_col != -9223372036854775808;
GO

SELECT
	ABS(-tinyint_col) AS abs_tinyint
FROM exactnumeric_table
GO

SELECT
	ABS(-smallint_col) AS abs_smallint,
	ABS(-integer_col) AS abs_integer,
	ABS(-bigint_col) AS abs_bigint
FROM exactnumeric_table
WHERE
	smallint_col != -32768 AND
	integer_col != -2147483648 AND
	bigint_col != -9223372036854775808;
GO

-- CEILING and FLOOR
SELECT
	CEILING(tinyint_col + 0.5) AS ceil_tinyint,
	CEILING(smallint_col + 0.5) AS ceil_smallint,
	CEILING(integer_col + 0.5) AS ceil_int,
	CEILING(bigint_col + 0.5) AS ceil_bigint
FROM exactnumeric_table order by ceil_tinyint;
GO

SELECT
	FLOOR(tinyint_col + 0.5) AS floor_tinyint,
	FLOOR(smallint_col + 0.5) AS floor_smallint,
	FLOOR(integer_col + 0.5) AS floor_int,
	FLOOR(bigint_col + 0.5) AS floor_bigint
FROM exactnumeric_table order by floor_tinyint;
GO

-- DEGREES and RADIANS
SELECT DEGREES(cast(2 as tinyint)) AS degrees_tinyint
GO

SELECT DEGREES(cast(2 as smallint)) AS degrees_smallint
GO

SELECT DEGREES(cast(2 as int)) AS degrees_int
GO

SELECT DEGREES(cast(2 as bigint)) AS degrees_bigint
GO

SELECT
	RADIANS(tinyint_col) AS radians_tinyint,
	RADIANS(smallint_col) AS radians_smallint,
	RADIANS(integer_col) AS radians_int,
	RADIANS(bigint_col) AS radians_bigint
FROM exactnumeric_table;
GO

-- PI
SELECT PI();
GO

-- POWER
SELECT POWER(cast(2 as tinyint), 2);
GO

SELECT POWER(cast(2 as smallint), 2);
GO

SELECT POWER(cast(2 as int), 2);
GO

SELECT POWER(cast(2 as bigint), 2);
GO

-- SQUARE
SELECT SQUARE(tinyint_col) FROM exactnumeric_table;
GO

SELECT SQUARE(smallint_col) FROM exactnumeric_table;
GO

SELECT SQUARE(bigint_col) FROM exactnumeric_table;
GO

-- SQRT
SELECT
	SQRT(tinyint_col) AS sqrt_tinyint,
	SQRT(smallint_col) AS sqrt_smallint,
	SQRT(integer_col) AS sqrt_int,
	SQRT(bigint_col) AS sqrt_bigint
FROM exactnumeric_table
WHERE
	tinyint_col >= 0 AND
	smallint_col >= 0 AND
	integer_col >= 0 AND
	bigint_col >= 0;
GO

-- SIGN
SELECT
	SIGN(tinyint_col) AS sign_tinyint,
	SIGN(smallint_col) AS sign_smallint, 
	SIGN(integer_col) AS sign_int,
	SIGN(bigint_col) AS sign_bigint
FROM exactnumeric_table;
GO

SELECT
	SIGN(-tinyint_col) AS sign_tinyint
FROM exactnumeric_table;
GO

SELECT
	SIGN(-smallint_col) AS sign_smallint, 
	SIGN(-integer_col) AS sign_int,
	SIGN(-bigint_col) AS sign_bigint
FROM exactnumeric_table
WHERE
	smallint_col != 32767 AND
	integer_col != 2147483647 AND
	bigint_col != 9223372036854775807;
GO

-- ROUND
SELECT
	ROUND(tinyint_col + 0.5) AS round_tinyint,
	ROUND(smallint_col + 0.5) AS round_smallint,
	ROUND(integer_col + 0.5) AS round_int,
	ROUND(bigint_col + 0.5) AS round_bigint
FROM exactnumeric_table order by round_tinyint;
GO

-- Division by zero
SELECT 1 / tinyint_col FROM exactnumeric_table WHERE tinyint_col = 0;

-- Log of zero or negative numbers
SELECT LOG(tinyint_col) FROM exactnumeric_table WHERE tinyint_col <= 0;
GO

SELECT LOG(smallint_col) FROM exactnumeric_table WHERE smallint_col <= 0;
GO

SELECT LOG(integer_col) FROM exactnumeric_table WHERE integer_col <= 0;
GO

SELECT LOG(bigint_col) FROM exactnumeric_table WHERE bigint_col <= 0;
GO

-- SQRT of negative numbers
SELECT SQRT(tinyint_col) FROM exactnumeric_table WHERE tinyint_col < 0;
GO

SELECT SQRT(smallint_col) FROM exactnumeric_table WHERE smallint_col < 0;
GO

SELECT SQRT(integer_col) FROM exactnumeric_table WHERE integer_col < 0;
GO

SELECT SQRT(bigint_col) FROM exactnumeric_table WHERE bigint_col < 0;
GO

-- ACOS, ASIN, ATAN (Trigonometric functions)
-- Note: Input should be between -1 and 1 for ACOS and ASIN
SELECT
	ACOS(tinyint_col/100) AS acos_tinyint
FROM exactnumeric_table;
GO

SELECT
	ACOS(smallint_col/10000) AS acos_smallint
FROM exactnumeric_table;
GO

SELECT
	ACOS(integer_col/1000000) AS acos_int
FROM exactnumeric_table;
GO

SELECT
	ACOS(bigint_col/100000000000) AS acos_bigint
FROM exactnumeric_table;
GO

SELECT
	ASIN(tinyint_col/100) AS asin_tinyint,
	ASIN(smallint_col/10000) AS asin_smallint,
	ASIN(integer_col/1000000) AS asin_int,
	ASIN(bigint_col/100000000000) AS asin_bigint
FROM exactnumeric_table;
GO

SELECT
	ATAN(tinyint_col) AS atan_tinyint,
	ATAN(smallint_col) AS atan_smallint,
	ATAN(integer_col) AS atan_int,
	ATAN(bigint_col) AS atan_bigint
FROM exactnumeric_table;
GO

-- COS, COT, SIN, TAN (Trigonometric functions)
SELECT
	COS(tinyint_col) AS cos_tinyint,
	COS(smallint_col) AS cos_smallint,
	COS(integer_col) AS cos_int,
	COS(bigint_col) AS cos_bigint
FROM exactnumeric_table;
GO

SELECT
	COT(tinyint_col) AS cot_tinyint,
	COT(smallint_col) AS cot_smallint,
	COT(integer_col) AS cot_int,
	COT(bigint_col) AS cot_bigint
FROM exactnumeric_table;
GO

SELECT
	SIN(tinyint_col) AS sin_tinyint,
	SIN(smallint_col) AS sin_smallint,
	SIN(integer_col) AS sin_int,
	SIN(bigint_col) AS sin_bigint
FROM exactnumeric_table;
GO

SELECT
	TAN(tinyint_col) AS tan_tinyint,
	TAN(smallint_col) AS tan_smallint,
	TAN(integer_col) AS tan_int,
	TAN(bigint_col) AS tan_bigint
FROM exactnumeric_table;
GO

-- LOG and LOG10
SELECT
	LOG(tinyint_col) AS log_tinyint,
	LOG(smallint_col) AS log_smallint,
	LOG(integer_col) AS log_int,
	LOG(bigint_col) AS log_bigint
FROM exactnumeric_table
WHERE
	tinyint_col > 0 AND
	smallint_col > 0 AND
	integer_col > 0 AND
	bigint_col > 0;
GO

SELECT
	LOG10(tinyint_col) AS log10_tinyint,
	LOG10(smallint_col) AS log10_smallint,
	LOG10(integer_col) AS log10_int,
	LOG10(bigint_col) AS log10_bigint
FROM exactnumeric_table
WHERE
	tinyint_col > 0 AND
	smallint_col > 0 AND
	integer_col > 0 AND
	bigint_col > 0;
GO

-- EXP (Exponential)
SELECT EXP(LOG(10));
GO

SELECT EXP(cast(2 as tinyint));
GO

SELECT EXP(cast(2 as smallint));
GO

SELECT EXP(cast(2 as int));
GO

SELECT EXP(cast(2 as bigint));
GO

-- MOD
SELECT tinyint_col % 2 FROM exactnumeric_table;
GO

SELECT smallint_col % 2 FROM exactnumeric_table;
GO

SELECT integer_col % 2 FROM exactnumeric_table;
GO

SELECT bigint_col % 2 FROM exactnumeric_table;
GO

-- TRUNCATE with integer types
SELECT 
	ROUND(tinyint_col, 0) AS trunc_tinyint,
	ROUND(smallint_col, 0) AS trunc_smallint,
	ROUND(integer_col, 0) AS trunc_int,
	ROUND(bigint_col, 0) AS trunc_bigint
FROM exactnumeric_table;
GO

SELECT 
	ROUND(tinyint_col, -2) AS trunc_tinyint,
	ROUND(smallint_col, -2) AS trunc_smallint,
	ROUND(integer_col, -2) AS trunc_int,
	ROUND(bigint_col, -2) AS trunc_bigint
FROM exactnumeric_table;
GO

SELECT 
	ROUND(tinyint_col, 2) AS trunc_tinyint,
	ROUND(smallint_col, 2) AS trunc_smallint,
	ROUND(integer_col, 2) AS trunc_int,
	ROUND(bigint_col, 2) AS trunc_bigint
FROM exactnumeric_table;
GO

-- AGGREGATE FUNCTIONS
SELECT
	SUM(tinyint_col) AS sum_tinyint,
	SUM(smallint_col) AS sum_smallint,
	SUM(integer_col) AS sum_int,
	SUM(bigint_col) AS sum_bigint
FROM exactnumeric_table
WHERE
	tinyint_col < 127 AND
	smallint_col < 32767 AND
	integer_col < 2147483647 AND
	bigint_col < 9223372036854775807;
GO

-- Overflow error
SELECT
	SUM(tinyint_col) AS sum_tinyint,
	SUM(smallint_col) AS sum_smallint,
	SUM(integer_col) AS sum_int,
	SUM(bigint_col) AS sum_bigint
FROM exactnumeric_table;
GO

SELECT
	AVG(tinyint_col) AS avg_tinyint,
	AVG(smallint_col) AS avg_smallint,
	AVG(integer_col) AS avg_int,
	AVG(bigint_col) AS avg_bigint
FROM exactnumeric_table;
GO

SELECT
	MIN(tinyint_col) AS min_tinyint,
	MIN(smallint_col) AS min_smallint,
	MIN(integer_col) AS min_int,
	MIN(bigint_col) AS min_bigint
FROM exactnumeric_table;
GO

SELECT
	MAX(tinyint_col) AS max_tinyint,
	MAX(smallint_col) AS max_smallint,
	MAX(integer_col) AS max_int,
	MAX(bigint_col) AS max_bigint
FROM exactnumeric_table;
GO

SELECT
	COUNT(tinyint_col) AS count_tinyint,
	COUNT(smallint_col) AS count_smallint,
	COUNT(integer_col) AS count_int,
	COUNT(bigint_col) AS count_bigint
FROM exactnumeric_table;
GO

-- Cast testing
Create function exactnumeric_cast_test_tinyint(@input TINYINT)
returns TINYINT
as
begin
	return @input;
end;
GO

Create function exactnumeric_cast_test_smallint(@input SMALLINT)
returns SMALLINT
as
begin
	return @input;
end;
GO

Create function exactnumeric_cast_test_int(@input INT)
returns INT
as
begin
	return @input;
end;
GO

Create function exactnumeric_cast_test_bigint(@input BIGINT)
returns BIGINT
as
begin
	return @input;
end;
GO

-- Cast testing xyz to exact numeric
create table exactnumeric_cast_table (
	id int,
	binary_col binary,
	varbinary_col varbinary,
	char_col char,
	varchar_col varchar,
	nchar_col nchar,
	nvarchar_col nvarchar,
	datetime_col datetime,
	smalldatetime_col smalldatetime,
	date_col date,
	time_col time,
	datetimeoffset_col datetimeoffset,
	datetime2_col datetime2,
	decimal_col decimal,
	numeric_col numeric,
	float_col float,
	real_col real,
	bigint_col bigint,
	integer_col int,
	smallint_col smallint,
	tinyint_col tinyint,
	money_col money,
	smallmoney_col smallmoney,
	bit_col bit,
	uniqueidentifier_col uniqueidentifier,
	image_col image,
	ntext_col ntext,
	text_col text,
	sql_variant_col sql_variant,
	xml_col xml
);
GO

INSERT INTO exactnumeric_cast_table VALUES 
(1, 0x02, 0x02, '1', '2', N'3', N'4', '2020-01-02 00:00:00', '2020-01-02 00:00:00', '2020-01-02', '00:00:00', '2020-01-02 00:00:00 +00:00', '2020-01-02 00:00:00', 2.0, 2.0, 2.0, 2.0, 2, 2, 2, 2, 2.0, 2.0, 2, 'B0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11', 0x02, '3', '4', '5', '<root><child>3</child></root>');
GO

SELECT
	exactnumeric_cast_test_tinyint(binary_col) AS binary_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(binary_col) AS binary_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(binary_col) AS binary_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(binary_col) AS binary_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(varbinary_col) AS varbinary_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(varbinary_col) AS varbinary_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(varbinary_col) AS varbinary_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(varbinary_col) AS varbinary_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(char_col) AS char_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(char_col) AS char_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(char_col) AS char_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(char_col) AS char_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(varchar_col) AS varchar_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(varchar_col) AS varchar_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(varchar_col) AS varchar_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(varchar_col) AS varchar_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(nchar_col) AS nchar_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(nchar_col) AS nchar_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(nchar_col) AS nchar_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(nchar_col) AS nchar_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(nvarchar_col) AS nvarchar_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(nvarchar_col) AS nvarchar_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(nvarchar_col) AS nvarchar_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(nvarchar_col) AS nvarchar_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(datetime_col) AS datetime_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(datetime_col) AS datetime_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(datetime_col) AS datetime_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(datetime_col) AS datetime_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(smalldatetime_col) AS smalldatetime_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(smalldatetime_col) AS smalldatetime_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(smalldatetime_col) AS smalldatetime_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(smalldatetime_col) AS smalldatetime_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(date_col) AS date_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(date_col) AS date_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(date_col) AS date_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(date_col) AS date_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(time_col) AS time_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(time_col) AS time_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(time_col) AS time_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(time_col) AS time_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(datetimeoffset_col) AS datetimeoffset_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(datetimeoffset_col) AS datetimeoffset_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(datetimeoffset_col) AS datetimeoffset_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(datetimeoffset_col) AS datetimeoffset_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(datetime2_col) AS datetime2_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(datetime2_col) AS datetime2_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(datetime2_col) AS datetime2_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(datetime2_col) AS datetime2_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(decimal_col) AS decimal_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(decimal_col) AS decimal_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(decimal_col) AS decimal_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(decimal_col) AS decimal_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(numeric_col) AS numeric_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(numeric_col) AS numeric_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(numeric_col) AS numeric_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(numeric_col) AS numeric_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(float_col) AS float_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(float_col) AS float_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(float_col) AS float_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(float_col) AS float_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(real_col) AS real_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(real_col) AS real_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(real_col) AS real_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(real_col) AS real_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(bigint_col) AS bigint_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(bigint_col) AS bigint_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(bigint_col) AS bigint_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(bigint_col) AS bigint_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(integer_col) AS int_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(integer_col) AS int_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(integer_col) AS int_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(integer_col) AS int_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(smallint_col) AS smallint_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(smallint_col) AS smallint_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(smallint_col) AS smallint_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(smallint_col) AS smallint_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(tinyint_col) AS tinyint_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(tinyint_col) AS tinyint_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(tinyint_col) AS tinyint_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(tinyint_col) AS tinyint_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(money_col) AS money_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(money_col) AS money_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(money_col) AS money_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(money_col) AS money_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(smallmoney_col) AS smallmoney_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(smallmoney_col) AS smallmoney_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(smallmoney_col) AS smallmoney_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(smallmoney_col) AS smallmoney_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(bit_col) AS bit_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(bit_col) AS bit_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(bit_col) AS bit_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(bit_col) AS bit_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(uniqueidentifier_col) AS uniqueidentifier_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(uniqueidentifier_col) AS uniqueidentifier_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(uniqueidentifier_col) AS uniqueidentifier_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(uniqueidentifier_col) AS uniqueidentifier_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(image_col) AS image_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(image_col) AS image_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(image_col) AS image_to_int
FROM exactnumeric_cast_table;
GO


SELECT
	exactnumeric_cast_test_bigint(image_col) AS image_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(ntext_col) AS ntext_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(ntext_col) AS ntext_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(ntext_col) AS ntext_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(ntext_col) AS ntext_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(text_col) AS text_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(text_col) AS text_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(text_col) AS text_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(text_col) AS text_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(sql_variant_col) AS sql_variant_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(sql_variant_col) AS sql_variant_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(sql_variant_col) AS sql_variant_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(sql_variant_col) AS sql_variant_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_tinyint(xml_col) AS xml_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_smallint(xml_col) AS xml_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_int(xml_col) AS xml_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	exactnumeric_cast_test_bigint(xml_col) AS xml_to_bigint
FROM exactnumeric_cast_table;
GO

SELECT
	cast(sql_variant_col as tinyint) AS sql_variant_to_tinyint
FROM exactnumeric_cast_table;
GO

SELECT
	cast(sql_variant_col as smallint) AS sql_variant_to_smallint
FROM exactnumeric_cast_table;
GO

SELECT
	cast(sql_variant_col as int) AS sql_variant_to_int
FROM exactnumeric_cast_table;
GO

SELECT
	cast(sql_variant_col as bigint) AS sql_variant_to_bigint
FROM exactnumeric_cast_table;
GO

-- JSON testing
DECLARE @json NVARCHAR(MAX) = N'{
	"tinyint_value": "255",
	"smallint_value": "32767",
	"int_value": "2147483647",
	"bigint_value": "9223372036854775807"
}';

SELECT 
	CAST(JSON_VALUE(@json, '$.tinyint_value') AS TINYINT) AS tinyint_result,
	CAST(JSON_VALUE(@json, '$.smallint_value') AS SMALLINT) AS smallint_result,
	CAST(JSON_VALUE(@json, '$.int_value') AS INT) AS int_result,
	CAST(JSON_VALUE(@json, '$.bigint_value') AS BIGINT) AS bigint_result;
GO

DECLARE @json NVARCHAR(MAX) = N'{
	"tinyint_value": "256",
	"smallint_value": "32768",
	"int_value": "2147483648",
	"bigint_value": "9223372036854775808"
}';

SELECT 
	TRY_CAST(JSON_VALUE(@json, '$.tinyint_value') AS TINYINT) AS tinyint_result,
	TRY_CAST(JSON_VALUE(@json, '$.smallint_value') AS SMALLINT) AS smallint_result,
	TRY_CAST(JSON_VALUE(@json, '$.int_value') AS INT) AS int_result,
	TRY_CAST(JSON_VALUE(@json, '$.bigint_value') AS BIGINT) AS bigint_result;
GO

-- Converting Exact Numeric Types to JSON
DECLARE @tinyint_val TINYINT = 255;
DECLARE @smallint_val SMALLINT = 32767;
DECLARE @int_val INT = 2147483647;
DECLARE @bigint_val BIGINT = 9223372036854775807;

SELECT (
    SELECT 
        @tinyint_val AS tinyint_value,
        @smallint_val AS smallint_value,
        @int_val AS int_value,
        @bigint_val AS bigint_value
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
) AS json_result;
GO

-- Handling Arrays of Exact Numeric Types in JSON
DECLARE @json NVARCHAR(MAX) = N'{
	"tinyint_array": [0, 128, 255]
}';

SELECT
	CAST(value AS TINYINT) AS tinyint_value
FROM OPENJSON(@json, '$.tinyint_array');
GO

DECLARE @json NVARCHAR(MAX) = N'{
	"smallint_array": [-32768, 0, 32767]
}';

SELECT
	CAST(value AS SMALLINT) AS smallint_value
FROM OPENJSON(@json, '$.smallint_array');
GO

DECLARE @json NVARCHAR(MAX) = N'{
	"int_array": [-2147483648, 0, 2147483647]
}';

SELECT
	CAST(value AS INT) AS int_value
FROM OPENJSON(@json, '$.int_array');
GO

DECLARE @json NVARCHAR(MAX) = N'{
	"bigint_array": [-9223372036854775808, 0, 9223372036854775807]
}';

SELECT
	CAST(value AS BIGINT) AS bigint_value
FROM OPENJSON(@json, '$.bigint_array');
GO

Drop table exactnumeric_table
GO

Drop table exactnumeric_cast_table
GO

Drop function exactnumeric_cast_test_tinyint
GO

Drop function exactnumeric_cast_test_smallint
GO

Drop function exactnumeric_cast_test_int
GO

Drop function exactnumeric_cast_test_bigint
GO

-- Create a UDT for each exact numeric type
CREATE TYPE UDT_TinyInt FROM TINYINT;
GO

CREATE TYPE UDT_SmallInt FROM SMALLINT;
GO

CREATE TYPE UDT_Int FROM INT;
GO

CREATE TYPE UDT_BigInt FROM BIGINT;
GO

-- Test case function
CREATE FUNCTION TestExactNumericUDT()
RETURNS TABLE
AS
RETURN
(
    -- Basic Range Tests
    SELECT 'TinyInt Min' AS Test, CAST(0 AS UDT_TinyInt) AS Result
    UNION ALL
    SELECT 'TinyInt Max', CAST(255 AS UDT_TinyInt)
    UNION ALL
    SELECT 'SmallInt Min', CAST(-32768 AS UDT_SmallInt)
    UNION ALL
    SELECT 'SmallInt Max', CAST(32767 AS UDT_SmallInt)
    UNION ALL
    SELECT 'Int Min', CAST(-2147483648 AS UDT_Int)
    UNION ALL
    SELECT 'Int Max', CAST(2147483647 AS UDT_Int)
    UNION ALL
    SELECT 'BigInt Min', CAST(-9223372036854775808 AS UDT_BigInt)
    UNION ALL
    SELECT 'BigInt Max', CAST(9223372036854775807 AS UDT_BigInt)

    -- Overflow Tests
    UNION ALL
    SELECT 'TinyInt Overflow', TRY_CAST(256 AS UDT_TinyInt)
    UNION ALL
    SELECT 'SmallInt Overflow', TRY_CAST(32768 AS UDT_SmallInt)

    -- Conversion Tests
    UNION ALL
    SELECT 'String to TinyInt', CAST('123' AS UDT_TinyInt)
    UNION ALL
    SELECT 'Int to SmallInt', CAST(CAST(12345 AS INT) AS UDT_SmallInt)

    -- Mathematical Operation Tests
    UNION ALL
    SELECT 'TinyInt Addition', CAST(200 AS UDT_TinyInt) + CAST(55 AS UDT_TinyInt)
    UNION ALL
    SELECT 'SmallInt Multiplication', CAST(100 AS UDT_SmallInt) * CAST(100 AS UDT_SmallInt)
    UNION ALL
	SELECT 'SmallInt Subtraction', CAST(1000 AS UDT_SmallInt) - CAST(2000 AS UDT_SmallInt)
    UNION ALL
	SELECT 'Int Multiplication', CAST(10000 AS UDT_Int) * CAST(10000 AS UDT_Int)
    UNION ALL
	SELECT 'BigInt Division', CAST(9223372036854775807 AS UDT_BigInt) / CAST(2 AS UDT_BigInt)

    -- NULL Value Tests
    UNION ALL
    SELECT 'NULL TinyInt', CAST(NULL AS UDT_TinyInt)

    -- Precision Tests
    UNION ALL
    SELECT 'Decimal to Int', CAST(CAST(123.45 AS DECIMAL(5,2)) AS UDT_Int)
)
GO

-- overflow tests: error
SELECT CAST(256 AS UDT_TinyInt);
GO

SELECT CAST(32768 AS UDT_SmallInt);
GO

SELECT CAST(2147483648 AS UDT_Int);
GO

SELECT CAST(9223372036854775808 AS UDT_BigInt);
GO


-- Execute the test cases
SELECT * FROM TestExactNumericUDT();
GO

DROP FUNCTION TestExactNumericUDT;
GO

-- Assuming UDTs are already created as in the previous example
CREATE FUNCTION ExtendedTestExactNumericUDT()
RETURNS TABLE
AS
RETURN
(
	-- 1. Boundary Value Tests
	SELECT 'TinyInt Boundary Low' AS Test, CAST(0 AS UDT_TinyInt) AS Result
	UNION ALL SELECT 'TinyInt Boundary High', CAST(255 AS UDT_TinyInt)
	UNION ALL SELECT 'SmallInt Boundary Low', CAST(-32768 AS UDT_SmallInt)
	UNION ALL SELECT 'SmallInt Boundary High', CAST(32767 AS UDT_SmallInt)
	UNION ALL SELECT 'Int Boundary Low', CAST(-2147483648 AS UDT_Int)
	UNION ALL SELECT 'Int Boundary High', CAST(2147483647 AS UDT_Int)
	UNION ALL SELECT 'BigInt Boundary Low', CAST(-9223372036854775808 AS UDT_BigInt)
	UNION ALL SELECT 'BigInt Boundary High', CAST(9223372036854775807 AS UDT_BigInt)

	-- 2. Just Inside Boundary Tests
	UNION ALL SELECT 'TinyInt Just Inside Low', CAST(1 AS UDT_TinyInt)
	UNION ALL SELECT 'TinyInt Just Inside High', CAST(254 AS UDT_TinyInt)
	UNION ALL SELECT 'SmallInt Just Inside Low', CAST(-32767 AS UDT_SmallInt)
	UNION ALL SELECT 'SmallInt Just Inside High', CAST(32766 AS UDT_SmallInt)

	-- 3. Overflow Tests
	UNION ALL SELECT 'TinyInt Overflow High', TRY_CAST(256 AS UDT_TinyInt)
	UNION ALL SELECT 'TinyInt Overflow Low', TRY_CAST(-1 AS UDT_TinyInt)
	UNION ALL SELECT 'SmallInt Overflow High', TRY_CAST(32768 AS UDT_SmallInt)
	UNION ALL SELECT 'SmallInt Overflow Low', TRY_CAST(-32769 AS UDT_SmallInt)

	-- 4. Type Conversion Tests
	UNION ALL SELECT 'String to TinyInt', TRY_CAST('123' AS UDT_TinyInt)
	UNION ALL SELECT 'String to SmallInt', TRY_CAST('-12345' AS UDT_SmallInt)
	UNION ALL SELECT 'String to Int', TRY_CAST('2147483647' AS UDT_Int)
	UNION ALL SELECT 'String to BigInt', TRY_CAST('-9223372036854775808' AS UDT_BigInt)
	UNION ALL SELECT 'Decimal to TinyInt', TRY_CAST(123.45 AS UDT_TinyInt)
	UNION ALL SELECT 'Float to SmallInt', TRY_CAST(12345.67 AS UDT_SmallInt)

	-- 5. Invalid Conversion Tests
	UNION ALL SELECT 'Invalid String to TinyInt', TRY_CAST('ABC' AS UDT_TinyInt)
	UNION ALL SELECT 'Invalid String to SmallInt', TRY_CAST('12345.67' AS UDT_SmallInt)

	-- 6. Mathematical Operations
	UNION ALL SELECT 'TinyInt Addition', CAST(200 AS UDT_TinyInt) + CAST(55 AS UDT_TinyInt)
	UNION ALL SELECT 'SmallInt Subtraction', CAST(1000 AS UDT_SmallInt) - CAST(2000 AS UDT_SmallInt)
	UNION ALL SELECT 'Int Multiplication', CAST(10000 AS UDT_Int) * CAST(10000 AS UDT_Int)
	UNION ALL SELECT 'BigInt Division', CAST(9223372036854775807 AS UDT_BigInt) / CAST(2 AS UDT_BigInt)

	-- 7. Mathematical Operation Overflow Tests
	UNION ALL SELECT 'TinyInt Addition Overflow', TRY_CAST((CAST(200 AS UDT_TinyInt) + CAST(100 AS UDT_TinyInt)) AS UDT_TinyInt)
	UNION ALL SELECT 'SmallInt Multiplication Overflow', TRY_CAST((CAST(1000 AS UDT_Int) * CAST(1000 AS UDT_Int)) AS UDT_SmallInt)

	-- 8. NULL Value Tests
	UNION ALL SELECT 'NULL TinyInt', CAST(NULL AS UDT_TinyInt)
	UNION ALL SELECT 'NULL SmallInt', CAST(NULL AS UDT_SmallInt)
	UNION ALL SELECT 'NULL Int', CAST(NULL AS UDT_Int)
	UNION ALL SELECT 'NULL BigInt', CAST(NULL AS UDT_BigInt)

	-- 9. NULL in Mathematical Operations
	UNION ALL SELECT 'TinyInt Plus NULL', CAST(100 AS UDT_TinyInt) + CAST(NULL AS UDT_TinyInt)
	UNION ALL SELECT 'SmallInt Multiply NULL', CAST(100 AS UDT_SmallInt) * CAST(NULL AS UDT_SmallInt)

	-- 10. Precision Tests
	UNION ALL SELECT 'Decimal to Int Rounding', CAST(CAST(123.45 AS DECIMAL(5,2)) AS UDT_Int)
	UNION ALL SELECT 'Decimal to SmallInt Rounding', CAST(CAST(123.55 AS DECIMAL(5,2)) AS UDT_SmallInt)

	-- 11. Comparison Tests
	UNION ALL SELECT 'SmallInt Comparison', CASE WHEN CAST(-1000 AS UDT_SmallInt) < CAST(1000 AS UDT_SmallInt) THEN 1 ELSE 0 END
	UNION ALL SELECT 'TinyInt Comparison', CASE WHEN CAST(100 AS UDT_TinyInt) > CAST(50 AS UDT_TinyInt) THEN 1 ELSE 0 END

	-- 12. Bitwise Operation Tests
	UNION ALL SELECT 'TinyInt Bitwise AND', CAST(240 AS UDT_TinyInt) & CAST(15 AS UDT_TinyInt)
	UNION ALL SELECT 'SmallInt Bitwise OR', CAST(240 AS UDT_SmallInt) | CAST(15 AS UDT_SmallInt)

	-- 13. Aggregate Function Tests
	UNION ALL SELECT 'TinyInt SUM', (SELECT SUM(CAST(n AS UDT_TinyInt)) FROM (VALUES(1),(2),(3)) AS T(n))
	UNION ALL SELECT 'SmallInt AVG', (SELECT AVG(CAST(n AS UDT_SmallInt)) FROM (VALUES(1000),(-1000),(0)) AS T(n))
)
GO

-- Execute the extended test cases
SELECT * FROM ExtendedTestExactNumericUDT();
GO

drop function ExtendedTestExactNumericUDT;
GO

-- Drop the UDTs
DROP TYPE UDT_TinyInt;
GO

DROP TYPE UDT_SmallInt;
GO

DROP TYPE UDT_Int;
GO

DROP TYPE UDT_BigInt;
GO

CREATE FUNCTION ExtendedOperationTestsExactNumeric()
RETURNS TABLE
AS
RETURN
(
	-- 1. Arithmetic Operators
	SELECT 'TinyInt + SmallInt' AS Test, CAST(254 AS TINYINT) -+CAST(1 AS SMALLINT) AS Result
	UNION ALL SELECT 'SmallInt - Int', CAST(32767 AS SMALLINT) - CAST(1 AS INT)
	UNION ALL SELECT 'Int * BigInt', CAST(2147483647 AS INT) * CAST(2 AS BIGINT)
	UNION ALL SELECT 'BigInt / TinyInt', CAST(9223372036854775807 AS BIGINT) / CAST(255 AS TINYINT)
	UNION ALL SELECT 'TinyInt % SmallInt', CAST(255 AS TINYINT) % CAST(100 AS SMALLINT)

	-- 2. Bitwise Operators
	UNION ALL SELECT 'TinyInt & SmallInt', CAST(255 AS TINYINT) & CAST(15 AS SMALLINT)
	UNION ALL SELECT 'SmallInt | Int', CAST(32767 AS SMALLINT) | CAST(1 AS INT)
	UNION ALL SELECT 'Int ^ BigInt', CAST(2147483647 AS INT) ^ CAST(1 AS BIGINT)
	UNION ALL SELECT 'BigInt ~ (Bitwise NOT)', ~CAST(9223372036854775807 AS BIGINT)

	-- 3. Comparison Operators
	UNION ALL SELECT 'TinyInt = SmallInt', CASE WHEN CAST(255 AS TINYINT) = CAST(255 AS SMALLINT) THEN 1 ELSE 0 END
	UNION ALL SELECT 'SmallInt <> Int', CASE WHEN CAST(32767 AS SMALLINT) <> CAST(32767 AS INT) THEN 1 ELSE 0 END
	UNION ALL SELECT 'Int < BigInt', CASE WHEN CAST(2147483647 AS INT) < CAST(9223372036854775807 AS BIGINT) THEN 1 ELSE 0 END
	UNION ALL SELECT 'BigInt > TinyInt', CASE WHEN CAST(9223372036854775807 AS BIGINT) > CAST(255 AS TINYINT) THEN 1 ELSE 0 END
	UNION ALL SELECT 'TinyInt <= SmallInt', CASE WHEN CAST(255 AS TINYINT) <= CAST(32767 AS SMALLINT) THEN 1 ELSE 0 END
	UNION ALL SELECT 'SmallInt >= Int', CASE WHEN CAST(32767 AS SMALLINT) >= CAST(-2147483648 AS INT) THEN 1 ELSE 0 END

	-- 4. Logical Operators
	UNION ALL SELECT 'TinyInt AND SmallInt', CASE WHEN CAST(255 AS TINYINT) > 0 AND CAST(32767 AS SMALLINT) > 0 THEN 1 ELSE 0 END
	UNION ALL SELECT 'SmallInt OR Int', CASE WHEN CAST(0 AS SMALLINT) > 0 OR CAST(2147483647 AS INT) > 0 THEN 1 ELSE 0 END
	UNION ALL SELECT 'Int NOT', CASE WHEN NOT (CAST(0 AS INT) > 0) THEN 1 ELSE 0 END

	-- 5. Unary Operators
	UNION ALL SELECT 'TinyInt +', +CAST(255 AS TINYINT)
	UNION ALL SELECT 'SmallInt -', -CAST(32767 AS SMALLINT)
	UNION ALL SELECT 'Int ~', ~CAST(2147483647 AS INT)
	UNION ALL SELECT 'BigInt Unary -', -CAST(9223372036854775807 AS BIGINT)

	-- 6. Overflow Tests
	UNION ALL SELECT 'Overflow TinyInt + SmallInt', TRY_CAST((CAST(255 AS TINYINT) + CAST(1 AS SMALLINT)) AS TINYINT)
	UNION ALL SELECT 'Overflow SmallInt * Int', TRY_CAST((CAST(32767 AS SMALLINT) * CAST(2 AS INT)) AS SMALLINT)
	UNION ALL SELECT 'Overflow Int + BigInt', TRY_CAST((CAST(2147483647 AS INT) + CAST(1 AS BIGINT)) AS INT)

	-- 7. NULL Handling
	UNION ALL SELECT 'NULL TinyInt + SmallInt', CAST(NULL AS TINYINT) + CAST(1 AS SMALLINT)
	UNION ALL SELECT 'SmallInt * NULL Int', CAST(32767 AS SMALLINT) * CAST(NULL AS INT)
	UNION ALL SELECT 'NULL BigInt / TinyInt', CAST(NULL AS BIGINT) / CAST(255 AS TINYINT)
)
GO

-- Execute the extended operation tests
SELECT * FROM ExtendedOperationTestsExactNumeric();
GO

DROP function ExtendedOperationTestsExactNumeric;
GO


-- Compound Operators
-- TinyInt += SmallInt
DECLARE @t TINYINT = 254;
SET @t += CAST(1 AS SMALLINT);
SELECT 'TinyInt += SmallInt' AS Test, @t AS Result;
GO

-- SmallInt -= Int
DECLARE @s SMALLINT = 32767;
SET @s -= CAST(1 AS INT);
SELECT 'SmallInt -= Int' AS Test, @s AS Result;
GO

-- Int *= BigInt
DECLARE @i INT = 1073741824;
SET @i *= CAST(2 AS BIGINT);
SELECT 'Int *= BigInt' AS Test, @i AS Result;
GO

-- BigInt /= TinyInt
DECLARE @b BIGINT = 9223372036854775807;
SET @b /= CAST(2 AS TINYINT);
SELECT 'BigInt /= TinyInt' AS Test, @b AS Result;
GO

-- TinyInt %= SmallInt
DECLARE @t2 TINYINT = 255;
SET @t2 %= CAST(100 AS SMALLINT);
SELECT 'TinyInt %= SmallInt' AS Test, @t2 AS Result;
GO

-- Logical Operators
SELECT 'BigInt XOR TinyInt' AS Test,
	CASE 
		WHEN ((CAST(1 AS BIGINT) > 0) AND NOT (CAST(0 AS TINYINT) > 0)) 
			OR (NOT (CAST(1 AS BIGINT) > 0) AND (CAST(0 AS TINYINT) > 0))
		THEN 1 
		ELSE 0 
	END AS Result;
GO

SELECT (CAST(255 AS TINYINT) + CAST(32767 AS SMALLINT)) * CAST(2 AS INT);
GO

SELECT (CAST(2147483647 AS INT) / CAST(255 AS TINYINT)) - CAST(32767 AS SMALLINT);
GO

SELECT CAST(9223372036854775807 AS BIGINT) % (CAST(32767 AS SMALLINT) * CAST(255 AS TINYINT))
GO

-- Complex queries
CREATE TABLE testexactnumeric_emp_babel_5621 (
	id INT PRIMARY KEY,
	name VARCHAR(50),
	department_id TINYINT,
	salary SMALLINT
);
GO

CREATE TABLE testexactnumeric_dept_babel_5621 (
	id TINYINT PRIMARY KEY,
	name VARCHAR(50),
	budget INT
);
GO

CREATE TABLE testexactnumeric_proj_babel_5621 (
	id SMALLINT PRIMARY KEY,
	name VARCHAR(50),
	department_id TINYINT,
	cost BIGINT
);
GO

-- Insert sample data
INSERT INTO testexactnumeric_emp_babel_5621 VALUES 
(1, 'John Doe', 1, 5000),
(2, 'Jane Smith', 2, 6000),
(3, 'Bob Johnson', 1, 4500),
(4, 'Alice Brown', 3, 5500);
GO

INSERT INTO testexactnumeric_dept_babel_5621 VALUES
(1, 'IT', 1000000),
(2, 'HR', 500000),
(3, 'Finance', 750000);
GO

INSERT INTO testexactnumeric_proj_babel_5621 VALUES
(1, 'Project A', 1, 500000),
(2, 'Project B', 2, 250000),
(3, 'Project C', 1, 750000),
(4, 'Project D', 3, 1000000);
GO

-- Multiple join conditions
SELECT e.name AS employee_name, d.name AS department_name, p.name AS project_name
FROM testexactnumeric_emp_babel_5621 e
JOIN testexactnumeric_dept_babel_5621 d ON e.department_id = d.id
JOIN testexactnumeric_proj_babel_5621 p ON d.id = p.department_id AND e.salary < p.cost
WHERE e.id > 0 AND d.budget > 100000 AND p.cost < 1000000;
GO

-- Subquery
SELECT e.name, e.salary
FROM testexactnumeric_emp_babel_5621 e
WHERE e.department_id IN (
    SELECT d.id
    FROM testexactnumeric_dept_babel_5621 d
    WHERE d.budget > (SELECT AVG(cost) FROM testexactnumeric_proj_babel_5621)
);
GO

-- CTE
WITH dept_project_count AS (
    SELECT d.id, d.name, COUNT(p.id) AS project_count
    FROM testexactnumeric_dept_babel_5621 d
    LEFT JOIN testexactnumeric_proj_babel_5621 p ON d.id = p.department_id
    GROUP BY d.id, d.name
)
SELECT e.name AS employee_name, dpc.name AS department_name, dpc.project_count
FROM testexactnumeric_emp_babel_5621 e
JOIN dept_project_count dpc ON e.department_id = dpc.id
WHERE e.salary > (SELECT AVG(salary) FROM testexactnumeric_emp_babel_5621);
GO

--views
CREATE VIEW testexactnumeric_emp_babel_5621_proj_summary AS
SELECT 
    e.id AS employee_id,
    e.name AS employee_name,
    d.name AS department_name,
    COUNT(p.id) AS project_count,
    SUM(p.cost) AS total_project_cost
FROM testexactnumeric_emp_babel_5621 e
JOIN testexactnumeric_dept_babel_5621 d ON e.department_id = d.id
LEFT JOIN testexactnumeric_proj_babel_5621 p ON d.id = p.department_id
GROUP BY e.id, e.name, d.name;
GO

-- Query using the view
SELECT *
FROM testexactnumeric_emp_babel_5621_proj_summary
WHERE total_project_cost > 500000 AND project_count > 0;
GO

-- Complex query combining multiple techniques
WITH high_budget_depts AS (
    SELECT id, name, budget
    FROM testexactnumeric_dept_babel_5621
    WHERE budget > (SELECT AVG(budget) FROM testexactnumeric_dept_babel_5621)
)
SELECT 
    e.name AS employee_name,
    hbd.name AS department_name,
    p.name AS project_name,
    e.salary,
    p.cost AS project_cost
FROM testexactnumeric_emp_babel_5621 e
JOIN high_budget_depts hbd ON e.department_id = hbd.id
LEFT JOIN testexactnumeric_proj_babel_5621 p ON hbd.id = p.department_id
WHERE e.salary > (
    SELECT AVG(salary) 
    FROM testexactnumeric_emp_babel_5621 
    WHERE department_id = e.department_id
)
AND p.cost < hbd.budget
ORDER BY hbd.budget DESC, e.salary DESC;
GO

DROP VIEW testexactnumeric_emp_babel_5621_proj_summary;
GO

DROP TABLE testexactnumeric_emp_babel_5621;
GO

DROP TABLE testexactnumeric_dept_babel_5621;
GO

DROP TABLE testexactnumeric_proj_babel_5621;
GO

