select choose (1, cast('2020-10-20 09:00:00' as datetime), cast('2020-10-21' as date));
GO
select choose ('1', cast('abc' as varchar(3)), cast('cba' as char(3)));
GO
select choose (1.3, cast(3.14 as float), cast(31.4 as numeric(3, 1)));
GO
select choose (2, cast(3.14 as float), cast(1 as int));
GO
select choose ('2', cast('$123.123' as money), cast(1 as int));
GO
select choose (2.6, cast('$123.123' as money), cast(3.14 as float));
GO
select choose (3, cast('2020-10-20 09:00:00' as datetime), cast('09:00:00' as time), cast('2001-01-01' as date));
GO
select choose ('3', cast('$123.123' as money), cast(321 as bigint), cast(1 as tinyint));
GO
select choose (3.9, cast(3.14 as float), cast('$123.123' as money), cast(-1 as smallint));
GO

-- test select with variables
CREATE PROCEDURE test_choose
AS BEGIN
    DECLARE @v int;
    SET @v = 1;
    SELECT choose(@v, 2, 3);
END
GO
EXEC test_choose
GO
DROP PROCEDURE test_choose
GO

-- test select with SQL Expressions
select choose (choose (1, 2, 3), 'a', 'b', 'c');
GO

-- Error, different categories
select choose (1, cast(1 as int), cast('abc' as varchar(3)));
GO
select choose (2, cast(0 as bit), cast(1 as int));
GO

-- Error, insufficient arguments
select choose (1);
GO

-- Null handling
-- choose null as result
select isnull(choose (1, null, 0), 100);
GO
-- null as choose index
select isnull(choose (null, 1, 0), 100);
GO
-- choose out of index
select isnull(choose (0, 1, 2), 100);
GO
select isnull(choose (3, 1, 2), 100);
GO
