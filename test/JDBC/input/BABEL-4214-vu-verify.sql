-- DATETIME cases
SELECT * FROM babel_4214_datetime_to_int_view
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS DATETIME) AS BIT);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS DATETIME) AS TINYINT);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS DATETIME) AS INT);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS DATETIME) AS BIGINT);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS DATETIME) AS REAL);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS DATETIME) AS FLOAT);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS DATETIME) AS DOUBLE PRECISION);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS DATETIME) AS NUMERIC(18,4));
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS DATETIME) AS NUMERIC(18,6));
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS DATETIME) AS DECIMAL(18,5));
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS BIT);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS DATETIME) AS TINYINT);
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS INT);
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS BIGINT);
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS REAL);
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS FLOAT);
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS DOUBLE PRECISION);
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS NUMERIC(18,4));
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS NUMERIC(18,6));
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS DECIMAL(18,5));
GO

SELECT CAST(CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS sql_variant) AS BIT);
GO

SELECT CAST(CAST(CAST('1900-01-10 11:00:50.675' AS DATETIME) AS sql_variant) AS TINYINT);
GO

SELECT CAST(CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS sql_variant) AS INT);
GO

SELECT CAST(CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS sql_variant) AS BIGINT);
GO

SELECT CAST(CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS sql_variant) AS REAL);
GO

SELECT CAST(CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS sql_variant) AS FLOAT);
GO

SELECT CAST(CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS sql_variant) AS DOUBLE PRECISION);
GO

SELECT CAST(CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS sql_variant) AS NUMERIC(18,6));
GO

SELECT CAST(CAST(CAST('2023-01-01 12:56:50.675' AS DATETIME) AS sql_variant) AS DECIMAL(18,5));
GO

-- Negative dates, i.e. dates before 1900-01-01

SELECT CAST(CAST('1890-01-01 12:56:50.675' AS DATETIME) AS BIT);
GO

SELECT CAST(CAST('1899-12-21 12:56:50.675' AS DATETIME) AS TINYINT);
GO

SELECT CAST(CAST('1890-01-01 12:56:50.675' AS DATETIME) AS INT);
GO

SELECT CAST(CAST('1890-01-01 12:56:50.675' AS DATETIME) AS BIGINT);
GO

SELECT CAST(CAST('1890-01-01 12:56:50.675' AS DATETIME) AS REAL);
GO

SELECT CAST(CAST('1890-01-01 12:56:50.675' AS DATETIME) AS FLOAT);
GO

SELECT CAST(CAST('1890-01-01 12:56:50.675' AS DATETIME) AS DOUBLE PRECISION);
GO

SELECT CAST(CAST('1890-01-01 12:56:50.675' AS DATETIME) AS NUMERIC(18,4));
GO

SELECT CAST(CAST('1890-01-01 12:56:50.675' AS DATETIME) AS NUMERIC(18,6));
GO

SELECT CAST(CAST('1890-01-01 12:56:50.675' AS DATETIME) AS DECIMAL(18,5));
GO

-- SMALLDATETIME cases
SELECT CAST(CAST('1900-01-10 12:56:50.675' AS SMALLDATETIME) AS BIT);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS SMALLDATETIME) AS TINYINT);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS SMALLDATETIME) AS INT);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS SMALLDATETIME) AS BIGINT);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS SMALLDATETIME) AS REAL);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS SMALLDATETIME) AS FLOAT);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS SMALLDATETIME) AS DOUBLE PRECISION);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS SMALLDATETIME) AS NUMERIC);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS SMALLDATETIME) AS NUMERIC(18,4));
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS SMALLDATETIME) AS NUMERIC(18,6));
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS SMALLDATETIME) AS NUMERIC(18,10));
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS SMALLDATETIME) AS DECIMAL);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS SMALLDATETIME) AS DECIMAL(18,5));
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS BIT);
GO

SELECT CAST(CAST('1900-01-10 12:56:50.675' AS SMALLDATETIME) AS TINYINT);
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS INT);
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS BIGINT);
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS REAL);
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS FLOAT);
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS DOUBLE PRECISION);
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS NUMERIC);
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS NUMERIC(18,4));
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS NUMERIC(18,6));
GO

SELECT CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS DECIMAL(18,5));
GO

SELECT CAST(CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS sql_variant) AS BIT);
GO

SELECT CAST(CAST(CAST('1900-01-01 11:00:50.675' AS SMALLDATETIME) AS sql_variant) AS TINYINT);
GO

SELECT CAST(CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS sql_variant) AS INT);
GO

SELECT CAST(CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS sql_variant) AS BIGINT);
GO

SELECT CAST(CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS sql_variant) AS REAL);
GO

SELECT CAST(CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS sql_variant) AS FLOAT);
GO

SELECT CAST(CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS sql_variant) AS DOUBLE PRECISION);
GO

SELECT CAST(CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS sql_variant) AS NUMERIC(18,6));
GO

SELECT CAST(CAST(CAST('2023-01-01 12:56:50.675' AS SMALLDATETIME) AS sql_variant) AS DECIMAL(18,5));
GO

-- Negative dates are not supported by SMALLDATETIME, i.e. dates before 1900-01-01
SELECT CAST(CAST('1890-01-01 12:56:50.675' AS SMALLDATETIME) AS INT);
GO

SELECT CAST(CAST('1890-01-01 12:56:50.675' AS SMALLDATETIME) AS BIGINT);
GO

SELECT CAST(CAST('1890-01-01 12:56:50.675' AS SMALLDATETIME) AS FLOAT);
GO

SELECT CAST(CAST('1890-01-01 12:56:50.675' AS SMALLDATETIME) AS NUMERIC(18,6));
GO