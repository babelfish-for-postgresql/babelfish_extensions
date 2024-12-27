-- Create simplified tables
CREATE TABLE Currency (Code nvarchar(3), Name nvarchar(2), Num decimal(2,1));
CREATE TABLE Exchange (Code nvarchar(3), Rate decimal(5,2), Value decimal(9,8));
GO

-- Insert minimal test data
INSERT INTO Currency VALUES ('USD', 'US', 2.1), ('EUR', 'EU', 1.1);
INSERT INTO Exchange VALUES ('USD', 1.00, 5.12345678), ('EUR', 0.12, 1.12345678);
GO

-- The query that demonstrates the issue, works without my chnage
SELECT e.Name AS description, e.Rate + e.Value AS sum_num 
FROM 
(
    SELECT Currency.Code, Currency.Name, Exchange.Rate, Exchange.Value
    FROM Currency 
    JOIN Exchange ON Currency.Code = Exchange.Code
    UNION ALL
    SELECT Code, Name, 1 AS Rate, Num AS Value
    FROM Currency
) AS e;
GO


CREATE TABLE Currency2(CurrencyCode nvarchar(3) NOT NULL, CurrencyName nvarchar(2) NULL, curr_num decimal (2,1));
GO

CREATE TABLE ExchangeRate2(ToCurrencyCode nvarchar(3) NOT NULL, ExchangeRate decimal(5, 2) NOT NULL, Hello decimal(9,8));
GO

INSERT INTO Currency2 (CurrencyCode, CurrencyName,curr_num) VALUES ('USD', 'US',2.1), ('EUR', 'Eu',1.1), ('GBP', 'Br',3.1), ('JPY', 'Ja',4.1), ('CAD', 'Ca',5.1);
GO

INSERT INTO ExchangeRate2 (ToCurrencyCode, ExchangeRate, Hello) VALUES ('EUR', 0.12, 1.12345678), ('GBP', 23.87, 2.12345678), ('JPY', 110.50, 3.12345678), ('CAD', 1.25, 4.12345678), ('USD', 1.00 , 5.12345678);
GO

-- formatted 
SELECT 
    cr1 AS description,
    ex + Hello AS sum_num
FROM (
    SELECT 
        ExchangeRate AS ex,
        CurrencyName AS cr1,
        CurrencyName,
        Hello
    FROM currency2
    INNER JOIN ExchangeRate2
        ON ToCurrencyCode = CurrencyCode

    UNION ALL

    SELECT
        1 AS aw,
        CurrencyName AS cr,
        CurrencyName,
        curr_num AS aw1
    FROM currency2
) a;
GO

-- should  notb work withoit my changes
SELECT cr1 description, ex + Hello sum_num FROM (SELECT ExchangeRate ex,CurrencyName cr1, CurrencyName ,Hello FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT 1 AS aw,CurrencyName as cr, CurrencyName,curr_num as aw1 FROM currency2) a;
GO


-- 1.1 THIS QUERY DOES WORK when union with decimal, so not an issue of position? - 5,2 and 9,8 , went to NUMERIC_SUB_OID, final 12,8
SELECT cr1 description, ex + Hello ex1   FROM (SELECT ExchangeRate ex,CurrencyName cr1, CurrencyName ,Hello FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT curr_num AS aw,CurrencyName as cr, CurrencyName,curr_num as aw1 FROM currency2) a;
GO

SELECT 1,cr1 description, ex + Hello ex1   FROM (SELECT ExchangeRate ex,CurrencyName cr1, CurrencyName ,Hello FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT curr_num AS aw,CurrencyName as cr, CurrencyName,curr_num as aw1 FROM currency2) a;
GO

-- inner query -> works without my change
SELECT ExchangeRate + hello ex,CurrencyName cr1, CurrencyName FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT curr_num AS aw,CurrencyName as cr, CurrencyName FROM currency2 ;

-- inner query -> works without my change
SELECT ExchangeRate + hello ex,CurrencyName cr1, CurrencyName FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT 1 AS aw,CurrencyName as cr, CurrencyName FROM currency2 ;


-- works oder of hello and ex - doing this
SELECT cr1 description, ex+ Hello sum_num  FROM (SELECT Hello,CurrencyName cr1, CurrencyName ,ExchangeRate ex FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT 1 AS aw,CurrencyName as cr, CurrencyName,curr_num as aw1 FROM currency2);
-- SELECT cr1 description, ex+ Hello sum_num  FROM (SELECT Hello,CurrencyName cr1 (this is var why?), CurrencyName (this is const why??) ,ExchangeRate ex FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT 1 AS aw,CurrencyName as cr, CurrencyName,curr_num as aw1 FROM currency2) a;
GO

-- works 
SELECT cr1 description, ex+ Hello sum_num  FROM (SELECT Hello,CurrencyName cr1, CurrencyName ,ExchangeRate ex FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT 1 AS aw,CurrencyName as cr, CurrencyName,curr_num as aw1 FROM currency2) a where cr1 = 'US';
go

SELECT cr1 description, ex+ Hello sum_num  FROM (SELECT Hello,CurrencyName cr1, CurrencyName ,ExchangeRate ex FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT 1 AS aw,CurrencyName as cr, CurrencyName,curr_num as aw1 FROM currency2);
go
-- from second union
SELECT cr1 description, curr_num+ curr_num sum_num  FROM (SELECT Hello,CurrencyName cr1, CurrencyName ,ExchangeRate ex FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT 1 AS aw,CurrencyName as cr, CurrencyName,curr_num as aw1 FROM currency2);
go


-- 2 works without my fix, correct answer also, 5,2 and 9.8 -> final 12,8
SELECT cr1 description, ex + Hello sum_numeric   FROM (SELECT CurrencyName cr1,ExchangeRate ex, Hello,CurrencyName FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT CurrencyName as cr,1 AS aw,curr_num as aw1, CurrencyName FROM currency2) a;
go
-- 3 works without my fix, correct answer also ,so not an issue of position -- for this we got 5,2 and 9,8 , went to NUMERIC_SUB_OID, final 12,8 as expected by tsql also
-- but here also we have numeric and decimal in union result
-- T_RelabelType and T_Var
SELECT cr1 description, ex + Hello sum_numeric   FROM (SELECT Hello,CurrencyName cr1,CurrencyName,CurrencyName cr2,ExchangeRate ex   FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT 1 AS aw,CurrencyName as cr, CurrencyName,CurrencyName cr3,curr_num as aw1 FROM currency2) a;
go

-- 5 alias issue ??? -- SEEEE THISSS , does not work before my fix, numeric and decimal -- works after fix
-- in union select 1
SELECT description d1, ex2+h2 test1 from (SELECT CurrencyName description, ex ex2, h1 h2  FROM (SELECT ExchangeRate ex,CurrencyName cr1, CurrencyName ,Hello h1 FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT 1 AS aw,CurrencyName as cr, CurrencyName,curr_num as aw1 FROM currency2) a)
go

-- 6 this works - union decimal and decimal
SELECT description d1, ex2+h2 test1 from (SELECT CurrencyName description, ex ex2, h1 h2  FROM (SELECT ExchangeRate ex,CurrencyName cr1, CurrencyName ,Hello h1 FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT curr_num AS aw,CurrencyName as cr, CurrencyName,curr_num as aw1 FROM currency2) a)
go
-- does not work, in union select 1 and 1, after my fix works
-- SELECT description d1, ex2+h2 test1 from (SELECT CurrencyName description, ex ex2, h1 h2  FROM (SELECT ExchangeRate ex,CurrencyName cr1, CurrencyName ,Hello h1 FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT 1 AS aw,CurrencyName as cr, CurrencyName,1 as aw1 FROM currency2) a)
-- go


-- from second union, we choose colname based on first query only in union all. so our approach will work in all cases.
SELECT cr1 description, curr_num+ curr_num sum_num  FROM (SELECT Hello,CurrencyName cr1, CurrencyName ,ExchangeRate ex,curr_num FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT 1 AS aw,CurrencyName as cr, CurrencyName,curr_num as aw1, curr_num FROM currency2);
go
SELECT cr1 description, curr_num+ 5.2 sum_num  FROM (SELECT Hello,CurrencyName cr1, CurrencyName ,ExchangeRate ex,curr_num FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT 1 AS aw,CurrencyName as cr, CurrencyName,curr_num as aw1, curr_num FROM currency2);
go
-- works 
select description, sum_num + sum_num from (SELECT cr1 description, curr_num+ curr_num sum_num  FROM (SELECT Hello,CurrencyName cr1, CurrencyName ,ExchangeRate ex,curr_num FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT 1 AS aw,CurrencyName as cr, CurrencyName,curr_num as aw1, curr_num FROM currency2))
go
-- works
select sum_num+sum_num from (SELECT cr1 description, ex + Hello sum_num FROM (SELECT ExchangeRate ex,CurrencyName cr1, CurrencyName ,Hello FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT 1 AS aw,CurrencyName as cr, CurrencyName,curr_num as aw1 FROM currency2) a)
go


Select result+result as sum_result from (select case 1 when 1 then cast(1.12343 as decimal(5,2)) end as result Union all select Hello from ExchangeRate2) as derived_table
go

-- multiple union all
select ex5 + ex5 ex_result from (select ToCurrencyCode, exchangerate ex5 from ExchangeRate2 union all (SELECT cr1 description, ex + Hello ex1   FROM (SELECT ExchangeRate ex,CurrencyName cr1, CurrencyName ,Hello FROM currency2 INNER JOIN ExchangeRate2 ON ToCurrencyCode = CurrencyCode UNION ALL SELECT curr_num AS aw,CurrencyName as cr, CurrencyName,curr_num as aw1 FROM currency2) a)) 
go


-- Setup: Create a UDT and additional test tables
CREATE TYPE TestUDT FROM decimal(10,4);
GO

CREATE TABLE TestTypes (
    IntCol int,
    FloatCol float,
    SmallIntCol smallint,
    NumericCol numeric(10,5),
    UDTCol TestUDT
);
GO

INSERT INTO TestTypes VALUES 
(100, 100.5, 10, 100.12345, 100.1234),
(200, 200.5, 20, 200.12345, 200.1234);
GO

-- Test Case 1: Multiple UNION ALLs with different combinations
SELECT 
    CASE WHEN IntCol > 150 THEN FloatCol ELSE SmallIntCol END AS result,
    NumericCol + UDTCol AS sum_result
FROM TestTypes
UNION ALL
SELECT 
    CAST(NumericCol AS float) AS result,
    IntCol + FloatCol AS sum_result
FROM TestTypes
UNION ALL
SELECT 
    COALESCE(SmallIntCol, 0) AS result,
    CAST(UDTCol AS numeric(12,6)) + NumericCol AS sum_result
FROM TestTypes;
GO
-- Test Case 2: Nested queries with decimal and numeric operations
SELECT outer_result + inner_result AS final_result
FROM (
    SELECT 
        (SELECT AVG(NumericCol) FROM TestTypes) AS outer_result,
        (
            SELECT TOP 1 UDTCol + FloatCol 
            FROM TestTypes 
            ORDER BY IntCol DESC
        ) AS inner_result
) AS nested_query;
GO
-- Test Case 3: Decimal + Numeric with different scales and precisions
SELECT 
    CAST(12345.6789 AS decimal(10,4)) + NumericCol AS dec_num_sum,
    CAST(12345.6789 AS decimal(10,4)) * NumericCol AS dec_num_product
FROM TestTypes
UNION ALL
SELECT 
    CAST(9876.54321 AS numeric(12,8)) + UDTCol,
    CAST(9876.54321 AS numeric(12,8)) * UDTCol
FROM TestTypes;
GO
-- Test Case 4: UDT operations
SELECT 
    UDTCol + IntCol AS udt_int_sum,
    UDTCol * FloatCol AS udt_float_product,
    UDTCol / NULLIF(SmallIntCol, 0) AS udt_smallint_div
FROM TestTypes;
GO
-- Test Case 5: Mixed type operations with CAST
SELECT 
    CAST(IntCol AS decimal(10,2)) + FloatCol AS int_float_sum,
    CAST(SmallIntCol AS numeric(8,4)) * NumericCol AS smallint_numeric_product,
    CAST(UDTCol AS float) / NULLIF(IntCol, 0) AS udt_int_div
FROM TestTypes
UNION ALL
SELECT 
    CAST(12.34 AS decimal(5,2)) + CAST(56.78 AS numeric(6,3)),
    CAST(100 AS smallint) * CAST(2.5 AS float),
    CAST(1000 AS numeric(10,4)) / NULLIF(CAST(3 AS int), 0)
FROM TestTypes;
GO
-- Test Case 6: All possible operations
SELECT 
    IntCol + FloatCol AS addition,
    NumericCol - UDTCol AS subtraction,
    SmallIntCol * FloatCol AS multiplication,
    CAST(NumericCol AS float) / NULLIF(IntCol, 0) AS division,
    POWER(FloatCol, 2) AS exponentiation,
    IntCol % 3 AS modulo
FROM TestTypes;
GO
-- Test Case 7: UNION with different scales and precisions
SELECT CAST(IntCol AS decimal(10,2)) AS result
FROM TestTypes
UNION
SELECT CAST(FloatCol AS decimal(12,4))
FROM TestTypes
UNION
SELECT NumericCol
FROM TestTypes
UNION
SELECT UDTCol
FROM TestTypes;
GO

DROP TABLE TestTypes;
GO
DROP TABLE Currency2;
GO
DROP TABLE ExchangeRate2;
GO
DROP TABLE Currency;
GO
DROP TABLE Exchange;
GO
DROP TYPE TestUDT;
GO


CREATE TABLE testdecimal_vu_prepare_tab21 (id INT IDENTITY(1,1) PRIMARY KEY,in4 DECIMAL(10,2),in5 DECIMAL(10,2));

CREATE TABLE tab2 (id INT IDENTITY(1,1) PRIMARY KEY, a DECIMAL(10,2));

INSERT INTO testdecimal_vu_prepare_tab21 (in4, in5) VALUES (10.50, 2.00), (25.75, 4.00), (100.00, 0.50), (7.25, 3.00), (50.00, 1.50);
go

INSERT INTO tab2 (a) VALUES (30.00), (45.50), (75.25), (12.75), (60.00);

select result1+result1 as result2 , a from (SELECT a , a AS result1 FROM tab2 union all SELECT in4, in4 + in5 AS result FROM testdecimal_vu_prepare_tab21)
go

-- getting 
-- result2                                  a           
-- ---------------------------------------- ------------
--                              25.00000000        10.50
--                              59.50000000        25.75
--                             201.00000000       100.00
--                              20.50000000         7.25
--                             103.00000000        50.00
--                              60.00000000        30.00
--                              91.00000000        45.50
--                             150.50000000        75.25
--                              25.50000000        12.75
--                             120.00000000        60.00

-- expected 
-- result2        a           
-- -------------- ------------
--          25.00        10.50
--          59.50        25.75
--         201.00       100.00
--          20.50         7.25
--         103.00        50.00
--          60.00        30.00
--          91.00        45.50
--         150.50        75.25
--          25.50        12.75
--         120.00        60.00

-- with my change and without parallel query 
-- result2        a           
-- -------------- ------------
--          60.00        30.00
--          91.00        45.50
--         150.50        75.25
--          25.50        12.75
--         120.00        60.00
--          25.00        10.50
--          59.50        25.75
--         201.00       100.00
--          20.50         7.25
--         103.00        50.00

-- with return -> with my changes 9n parallel 
-- 2> go
-- result2        a           
-- -------------- ------------
--          25.00        10.50
--          59.50        25.75
--         201.00       100.00
--          20.50         7.25
--         103.00        50.00
--          60.00        30.00
--          91.00        45.50
--         150.50        75.25
--          25.50        12.75
--         120.00        60.00


CREATE TABLE testdecimal_vu_prepare_tab2 (id INT IDENTITY(1,1) PRIMARY KEY, in4 DECIMAL(20,6), in5 DECIMAL(20,6));
CREATE TABLE tab2 (id INT IDENTITY(1,1) PRIMARY KEY, a DECIMAL(20,6));
INSERT INTO testdecimal_vu_prepare_tab2 (in4, in5) VALUES (99999999999999.111111, 11111111111111.999999);
INSERT INTO tab2 (a) VALUES (99999999999999.111111);
-- correct 
select result1+result1 as result2 , a from (SELECT a , a AS result1 FROM tab2 union all SELECT in4, in4 + in5 AS result FROM testdecimal_vu_prepare_tab2)
