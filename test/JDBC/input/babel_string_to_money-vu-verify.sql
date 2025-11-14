--Standard currency symbols
SELECT CAST('$100.123' AS money);
GO

SELECT CAST('¢100.989723' AS money);
GO

SELECT CAST('£100.123' AS money);
GO

SELECT CAST('৲10056367,098.23' AS money);
GO

SELECT CAST('฿1043,79,123' AS money);
GO

SELECT CAST('₠100.123' AS money);
GO

SELECT CAST('₣165400,123' AS money);
GO

SELECT CAST('₥107730.123' AS money);
GO

SELECT CAST('₩104320.123' AS money);
GO

SELECT CAST('₯100.7574653123' AS money);
GO

SELECT CAST('₱10757640.123' AS money);
GO

SELECT CAST('＄10065327.123' AS money);
GO

SELECT CAST('￥10032.123' AS money);
GO

--Negative cases - Invalid inputs
SELECT cast('!100.90' as money);
GO

SELECT cast('abcd' as money);
GO

SELECT CAST('@#$100.00' AS money);
GO

SELECT CAST('$100''OR 1=1' AS MONEY); 
GO

SELECT CAST('&100' AS MONEY);  
GO  

SELECT CAST('%100' AS MONEY);
GO

SELECT CAST('$$100') AS MONEY; 
GO

SELECT CAST('  ' AS money);
GO

SELECT CAST('£test' AS MONEY);  
GO

SELECT CAST('''$100''' AS MONEY);
GO

SELECT CAST('$--100' AS MONEY);
GO

--valid cases
SELECT CAST('$-100' AS MONEY); 
GO

SELECT CAST('$,100' AS MONEY); 
GO

SELECT CAST('$a123' AS MONEY); 
GO

SELECT cast('$ ' as MONEY);
GO

SELECT CAST('$1000000000000000' AS MONEY);
GO

SELECT CAST('€922337203685477.5807' AS MONEY) % CAST('€-922337203685477.5808' AS MONEY);
GO

SELECT CAST(922337203685477.5807 AS MONEY) % CAST(0.0001 AS MONEY);
GO

--Boundary tests
SELECT CAST('$0.0001' AS MONEY);
GO

SELECT CAST('$1.23E+10' AS MONEY);
GO

--Decimal cases
SELECT CAST('0.50' AS MONEY);
GO

SELECT CAST('.50' AS MONEY);
GO

SELECT CAST('$.' AS MONEY);
GO

SELECT CAST('100₨.123' AS money)
GO

SELECT CAST('-.1089' AS MONEY);
GO

SELECT CAST('$1,000,000.50' AS MONEY);
GO

SELECT CAST(SUBSTRING('$100.50', 1, 4) AS MONEY); 
GO

SELECT CAST('$0.0001' AS MONEY);
GO

select TRY_CAST(CAST(-1.56 as money) As int);
GO

--Arithmetic operations
SELECT CAST(-27328391434.2737 AS MONEY) % CAST(283828323.2273 AS MONEY);
GO

SELECT CAST('¤100.123' AS MONEY) + CAST('¤100,70.89' AS SMALLMONEY);
GO

-- With space
SELECT CAST('  +100' AS MONEY);
GO

SELECT CAST('  -100' AS MONEY);
GO

SELECT CAST('$100  ' AS MONEY);
GO

SELECT CAST('  $ 100.50  ' AS MONEY); 
GO

SELECT CAST('  $  100' AS MONEY);
GO

SELECT CAST('                                 $        100' AS MONEY);
GO

SELECT CAST('R$ 100,50' AS MONEY);
GO

SELECT CAST('$  -100' AS MONEY); 
GO

SELECT CAST('$    +    100' AS MONEY);
GO

-- Invalid currency symbols
SELECT CAST('₽100' AS MONEY); 
GO

SELECT CAST('₿100' AS MONEY); 
GO

SELECT CAST('$$100' AS MONEY); 
GO

SELECT TRY_CAST('@100' AS MONEY);  
GO

SELECT CAST('$999999999999999' AS MONEY); 
GO

SELECT CAST('$1000000' AS MONEY); 
GO

SELECT CAST(CHAR(9) + '100' AS MONEY);
GO

--Test currency symbol with Transaction 
BEGIN TRANSACTION;
SELECT CAST('$100' AS MONEY);                               
COMMIT;
GO

--Procedure 
EXEC TestMoneyCast '₸100';   --Tenge currency symbol
GO

EXEC TestMoneyCast '$.  100';
GO

-- Thousands separators
SELECT CAST('$1009999999999,123' AS MONEY);
GO

SELECT CAST('$100999999999,123' AS MONEY);
GO

SELECT CAST('¢1,234.56' AS SMALLMONEY);
GO

SELECT CAST('£+.200' AS MONEY);
GO

SELECT CAST(NULL AS MONEY);
GO

SELECT CAST('₢0' AS MONEY); 
GO

---Function to validate the valid and invalid money
SELECT dbo.test_money_func(CAST('৳50.25' AS MONEY)) AS valid_basic_test;
GO

SELECT dbo.test_money_func(CAST('$ - .99' AS MONEY)) AS test;
GO

SELECT dbo.test_money_func(CAST('$12.34.56' as MONEY)) AS test;
GO

SELECT dbo.test_money_func(CAST('￦100.123' AS MONEY)) AS test;
GO

-- declare statements
DECLARE @val VARCHAR(20) = '$100';
SELECT CAST(@val AS MONEY); 
go

--views
SELECT * FROM test_validcurrency;
GO

SELECT * FROM test1;
GO

--Function
SELECT * FROM dbo.money_func();
GO
--complex case 
SELECT 
    id,
    debit,
    credit,
    balance,
    CASE 
        WHEN balance > '$0' THEN 'Positive'
        WHEN balance < '$0' THEN 'Negative'
        ELSE 'Zero'
    END AS balance_status
FROM transactions;
GO

-- Function to convert smallmoney to money
SELECT dbo.fn_SmallToMoney('$123,45') AS ConvertedValue;
GO
SELECT dbo.fn_SmallToMoney('€1209,84.45') AS ConvertedValue;
GO

--Procedure for arithmrtic operations
EXEC Test_Arithmetic;
GO

--Procedure for Boundary condition
EXEC Test_Boundaries;
GO

--Function 
SELECT dbo.round_money(CAST('$123.458' AS MONEY), 2);
GO

SELECT dbo.round_money(CAST('$8757645343.029' AS MONEY), 2);
GO

SELECT dbo.round_money(CAST('@123.6' AS MONEY), DEFAULT);
GO

SELECT dbo.round_money(CAST('-999999.999' AS MONEY), DEFAULT);
GO
