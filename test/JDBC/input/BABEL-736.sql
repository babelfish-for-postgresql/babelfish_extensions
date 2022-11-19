SELECT degrees(10)
GO

SELECT degrees(NULL)
GO

SELECT degrees(9999*9999)
GO

SELECT degrees(9999.0 * 9999.0)
GO

---------------------------------------------------
--TINYINT__TEST_CASES_FOR_DEGREES

--Positive_value_test_case
SELECT degrees(CAST(1 AS TINYINT));
GO

--Normal_value_test_case
SELECT degrees(CAST(4 AS TINYINT));
GO

SELECT degrees(CAST(255 AS TINYINT));
GO

--Null_value_test_case
SELECT degrees(CAST(NULL AS TINYINT));
GO

--Trigger_an_error_message_integer_out_of_range
SELECT degrees(CAST(256 AS TINYINT));
GO

---------------------------------------------------
--SMALLINT__TEST_CASES_FOR_DEGREES

--Positive_value_test_case
SELECT degrees(CAST(10 AS SMALLINT));
GO

--Negative_value_test_case 
SELECT degrees(CAST(-10 AS SMALLINT));
GO

--Normal_value_test_case
SELECT degrees(CAST(5680 AS SMALLINT));
GO

SELECT degrees(CAST(32767 AS SMALLINT));
GO

--Null_value_test_case
SELECT degrees(CAST(NULL AS SMALLINT));
GO

--Trigger_an_error_message_integer_out_of_range
SELECT degrees(CAST(32768 AS SMALLINT));
GO

---------------------------------------------------
--BIGINT__TEST_CASES_FOR_DEGREES

--Positive_value_test_case
SELECT degrees(CAST(10 AS BIGINT));
GO

--Negative_value_test_case 
SELECT degrees(CAST(-10 AS BIGINT));
GO

---Normal_value_test_case
SELECT degrees(CAST(37272900 AS BIGINT));
GO

SELECT degrees(CAST(8764210 AS BIGINT));
GO

--Null_value_test_case
SELECT degrees(CAST(NULL AS BIGINT));
GO

--Trigger_an_error_message_integer_out_of_range
SELECT degrees(CAST(9223372036858847777 AS BIGINT));
GO

---------------------------------------------------
--INT__TEST_CASES_FOR_DEGREES

--Positive_value_test_case
SELECT degrees(CAST(10 AS INT));
GO

--Negative_value_test_case 
SELECT degrees(CAST(-10 AS INT));
GO

--Normal_value_test_case
SELECT degrees(CAST(250 AS INT));
GO

SELECT degrees(CAST(893 AS INT));
GO

--Null_value_test_case
SELECT degrees(CAST(NULL AS INT));
GO

--Trigger_an_error_message_integer_out_of_range
SELECT degrees(CAST(2147483648 AS INT));
GO
