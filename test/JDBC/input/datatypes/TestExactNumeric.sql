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
FROM exactnumeric_table;
GO

SELECT
	FLOOR(tinyint_col + 0.5) AS floor_tinyint,
	FLOOR(smallint_col + 0.5) AS floor_smallint,
	FLOOR(integer_col + 0.5) AS floor_int,
	FLOOR(bigint_col + 0.5) AS floor_bigint
FROM exactnumeric_table;
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

SELECT SQUARE(integer_col) FROM exactnumeric_table;
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
FROM exactnumeric_table;
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
