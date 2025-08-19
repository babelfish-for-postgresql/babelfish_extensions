------------------------------------------------------------------------
---- 1. SQRT Function Tests
------------------------------------------------------------------------
-- NUMERIC Tests
SELECT SQRT(CAST(144 AS NUMERIC(3,0))) AS result;                -- Positive NUMERIC
GO

SELECT SQRT(CAST(0 AS NUMERIC(3,0))) AS result;                  -- Zero NUMERIC
GO

SELECT SQRT(CAST(12.25 AS NUMERIC(4,2))) AS result;             -- Decimal NUMERIC
GO

SELECT SQRT(CAST(-144 AS NUMERIC(3,0))) AS result;              -- Negative NUMERIC
GO

SELECT SQRT(CAST(NULL AS NUMERIC(5,2))) AS result;              -- NULL NUMERIC
GO

SELECT SQRT(CAST(2 AS NUMERIC(1,0))) AS result;                 -- Irrational NUMERIC
GO

SELECT SQRT(CAST(9999999999999999 AS NUMERIC(16,0))) AS result; -- Large NUMERIC
GO

SELECT SQRT(CAST(0.0000000001 AS NUMERIC(11,10))) AS result;    -- Small NUMERIC
GO

-- DECIMAL Tests
SELECT SQRT(CAST(144 AS DECIMAL(3,0))) AS result;               -- Positive DECIMAL
GO

SELECT SQRT(CAST(0 AS DECIMAL(3,0))) AS result;                 -- Zero DECIMAL
GO

SELECT SQRT(CAST(12.25 AS DECIMAL(4,2))) AS result;            -- Decimal DECIMAL
GO

SELECT SQRT(CAST(-144 AS DECIMAL(3,0))) AS result;             -- Negative DECIMAL
GO

SELECT SQRT(CAST(NULL AS DECIMAL(5,2))) AS result;             -- NULL DECIMAL
GO

SELECT SQRT(CAST(2 AS DECIMAL(1,0))) AS result;                -- Irrational DECIMAL
GO

SELECT SQRT(CAST(9999999999999999 AS DECIMAL(16,0))) AS result;-- Large DECIMAL
GO

SELECT SQRT(CAST(0.0000000001 AS DECIMAL(11,10))) AS result;   -- Small DECIMAL
GO

-- INT Tests
SELECT SQRT(144) AS result;                                     -- Positive INT
GO

SELECT SQRT(0) AS result;                                       -- Zero INT
GO

SELECT SQRT(-144) AS result;                                    -- Negative INT
GO

SELECT SQRT(CAST(NULL AS INT)) AS result;                      -- NULL INT
GO

SELECT SQRT(2) AS result;                                      -- Irrational INT
GO

SELECT SQRT(2147483647) AS result;                            -- MAX INT
GO

-- BIGINT Tests
SELECT SQRT(CAST(144 AS BIGINT)) AS result;                    -- Positive BIGINT
GO

SELECT SQRT(CAST(0 AS BIGINT)) AS result;                      -- Zero BIGINT
GO

SELECT SQRT(CAST(-144 AS BIGINT)) AS result;                   -- Negative BIGINT
GO

SELECT SQRT(CAST(NULL AS BIGINT)) AS result;                   -- NULL BIGINT
GO

SELECT SQRT(CAST(2 AS BIGINT)) AS result;                      -- Irrational BIGINT
GO

SELECT SQRT(CAST(9223372036854775807 AS BIGINT)) AS result;    -- MAX BIGINT
GO

-- SMALLINT Tests
SELECT SQRT(CAST(144 AS SMALLINT)) AS result;                  -- Positive SMALLINT
GO

SELECT SQRT(CAST(0 AS SMALLINT)) AS result;                    -- Zero SMALLINT
GO

SELECT SQRT(CAST(-144 AS SMALLINT)) AS result;                 -- Negative SMALLINT
GO

SELECT SQRT(CAST(NULL AS SMALLINT)) AS result;                 -- NULL SMALLINT
GO

SELECT SQRT(CAST(2 AS SMALLINT)) AS result;                    -- Irrational SMALLINT
GO

SELECT SQRT(CAST(32767 AS SMALLINT)) AS result;               -- MAX SMALLINT
GO

-- TINYINT Tests
SELECT SQRT(CAST(144 AS TINYINT)) AS result;                   -- Positive TINYINT
GO

SELECT SQRT(CAST(0 AS TINYINT)) AS result;                     -- Zero TINYINT
GO

SELECT SQRT(CAST(NULL AS TINYINT)) AS result;                  -- NULL TINYINT
GO

SELECT SQRT(CAST(2 AS TINYINT)) AS result;                     -- Irrational TINYINT
GO

SELECT SQRT(CAST(255 AS TINYINT)) AS result;                  -- MAX TINYINT
GO

-- MONEY Tests
SELECT SQRT(CAST(144.00 AS MONEY)) AS result;                  -- Positive MONEY
GO

SELECT SQRT(CAST(0.00 AS MONEY)) AS result;                    -- Zero MONEY
GO

SELECT SQRT(CAST(-144.00 AS MONEY)) AS result;                 -- Negative MONEY
GO

SELECT SQRT(CAST(NULL AS MONEY)) AS result;                    -- NULL MONEY
GO

SELECT SQRT(CAST(2.00 AS MONEY)) AS result;                    -- Irrational MONEY
GO

SELECT SQRT(CAST(922337203685477.5807 AS MONEY)) AS result;    -- Large MONEY
GO

SELECT SQRT(CAST(0.0001 AS MONEY)) AS result;                  -- Small MONEY
GO

-- SMALLMONEY Tests
SELECT SQRT(CAST(144.00 AS SMALLMONEY)) AS result;             -- Positive SMALLMONEY
GO

SELECT SQRT(CAST(0.00 AS SMALLMONEY)) AS result;               -- Zero SMALLMONEY
GO

SELECT SQRT(CAST(-144.00 AS SMALLMONEY)) AS result;            -- Negative SMALLMONEY
GO

SELECT SQRT(CAST(NULL AS SMALLMONEY)) AS result;               -- NULL SMALLMONEY
GO

SELECT SQRT(CAST(2.00 AS SMALLMONEY)) AS result;               -- Irrational SMALLMONEY
GO

SELECT SQRT(CAST(214748.3647 AS SMALLMONEY)) AS result;        -- MAX SMALLMONEY
GO

-- BIT Tests
SELECT SQRT(CAST(1 AS BIT)) AS result;                         -- ONE BIT
GO

SELECT SQRT(CAST(0 AS BIT)) AS result;                         -- ZERO BIT
GO

SELECT SQRT(CAST(NULL AS BIT)) AS result;                      -- NULL BIT
GO

-- REAL Tests
SELECT SQRT(CAST(144.0 AS REAL)) AS result;                    -- Positive REAL
GO

SELECT SQRT(CAST(0.0 AS REAL)) AS result;                      -- Zero REAL
GO

SELECT SQRT(CAST(-144.0 AS REAL)) AS result;                   -- Negative REAL
GO

SELECT SQRT(CAST(NULL AS REAL)) AS result;                     -- NULL REAL
GO

SELECT SQRT(CAST(2.0 AS REAL)) AS result;                      -- Irrational REAL
GO

SELECT SQRT(CAST(3.402823E+38 AS REAL)) AS result;            -- Large REAL
GO

SELECT SQRT(CAST(1.175494E-38 AS REAL)) AS result;            -- Small REAL
GO

-- Character Type Tests
SELECT SQRT('144') AS result;                                  -- Positive STRING
GO

SELECT SQRT('0') AS result;                                    -- Zero STRING
GO

SELECT SQRT('-144') AS result;                                 -- Negative STRING
GO

SELECT SQRT('12.25') AS result;                               -- Decimal STRING
GO

SELECT SQRT('2') AS result;                                   -- Irrational STRING
GO

SELECT SQRT('') AS result;                                    -- Empty STRING
GO

SELECT SQRT('ABC') AS result;                                 -- Invalid STRING
GO

SELECT SQRT(N'144') AS result;                                -- Positive NSTRING
GO

SELECT SQRT(N'0') AS result;                                  -- Zero NSTRING
GO

SELECT SQRT(N'-144') AS result;                               -- Negative NSTRING
GO

SELECT SQRT(N'12.25') AS result;                             -- Decimal NSTRING
GO

SELECT SQRT(N'2') AS result;                                 -- Irrational NSTRING
GO

SELECT SQRT(N'') AS result;                                  -- Empty NSTRING
GO

SELECT SQRT(N'ABC') AS result;                               -- Invalid NSTRING
GO