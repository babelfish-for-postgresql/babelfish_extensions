-- [BABEL-879] Money Casts are not rounded correctly

-- Expected:1.1112
select cast(1.11119 as money);
GO

-- Expected:1.1111
select cast(1.11114 as money);
GO

-- [BABEL-926] Incorrect TRY_CAST behavior from various numeric types to tinyint

-- Expected:1
select try_cast(cast(1.23 as real) as tinyint);
GO

-- Expected:1
select try_cast(cast(1.23 as money) as tinyint);
GO

-- Expected:1
select try_cast(cast(1.23 as float(53)) as tinyint);
GO

-- Expected:1
select try_cast(cast(1.23 as smallmoney) as tinyint);
GO

-- Expected:1
select try_cast(cast(1.23 as numeric) as tinyint);
GO

-- Expected:1
select try_cast(cast(1.23 as double precision) as tinyint);
GO

-- [BABEL-2643] Money type not working with choose() function in MSSQL

-- Expected:3.14
select choose (2.6, cast('$123.123' as money), cast(3.14 as float));
GO

-- Expected:1.0000
select choose ('2', cast('$123.123' as money), cast(1 as int));
GO

-- Expected:123.123
select choose (1.6, cast('$123.123' as money), cast(3.14 as float));
GO

-- Expected:123.1230
select choose ('1', cast('$123.123' as money), cast(1 as int));
GO
