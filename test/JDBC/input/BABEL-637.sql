use master;
go

CREATE FUNCTION babel_637_int_multiply (@a int, @b int)
RETURNS int AS
BEGIN
  RETURN @a * @b;
END;
GO

-- reported case: numeric->int4
SELECT babel_637_int_multiply(21.1, 2.2);
GO

-- reported case: varbinary->int4
SELECT babel_637_int_multiply(0xe, 0xe);
GO

-- case expession. should pick float since it has higher precedence
SELECT cast(pg_typeof(case when 2 > 1 then cast(3.14 as double precision) else cast(42 as int) end) as varchar(20)) as return_type;
GO

SELECT cast(pg_typeof(case when 2 > 1 then cast(42 as int) else cast(3.14 as double precision) end) as varchar(20)) as reutrn_type;
GO

--union-all
SELECT cast(pg_typeof(T.c1) as varchar(20)) as return_type from (SELECT cast(3.14 as double precision) c1 UNION ALL SELECT cast(42 as int) c1) T
GO

SELECT cast(pg_typeof(T.c1) as varchar(20)) as return_type from (SELECT cast(42 as int) c1 UNION ALL SELECT cast(3.14 as double precision) c1) T
GO


-- all number type to double precision
CREATE FUNCTION babel_637_double_precision (@a double precision)
RETURNS double precision AS
BEGIN
  RETURN @a;
END;
GO

SELECT babel_637_double_precision(cast(41.9 as double precision));
GO

SELECT babel_637_double_precision(cast(123456789012.1 as double precision));
GO

SELECT babel_637_double_precision(cast(41.9 as float));
GO

SELECT babel_637_double_precision(cast(123456789012.1 as float));
GO

SELECT babel_637_double_precision(cast(41.9 as fixeddecimal));
GO

SELECT babel_637_double_precision(cast(123456789012.1 as fixeddecimal));
GO

SELECT babel_637_double_precision(cast(41.9 as numeric(18,4)));
GO

SELECT babel_637_double_precision(cast(123456789012.1 as numeric(18,4)));
GO

SELECT babel_637_double_precision(cast(41.9 as money));
GO

SELECT babel_637_double_precision(cast(922337203685475.5807 as money));
GO

SELECT babel_637_double_precision(cast(41.9 as smallmoney));
GO

SELECT babel_637_double_precision(cast(214746.3647 as smallmoney));
GO

SELECT babel_637_double_precision(cast(41 as bigint));
GO

SELECT babel_637_double_precision(cast(9223372036854775806 as bigint));
GO

SELECT babel_637_double_precision(cast(41 as int));
GO

SELECT babel_637_double_precision(cast(2147483646 as int));
GO

SELECT babel_637_double_precision(cast(41 as smallint));
GO

SELECT babel_637_double_precision(cast(32766 as smallint));
GO

SELECT babel_637_double_precision(cast(41 as tinyint));
GO

SELECT babel_637_double_precision(cast(254 as tinyint));
GO


-- all number type to float
CREATE FUNCTION babel_637_float (@a float)
RETURNS float AS
BEGIN
  RETURN @a;
END;
GO

SELECT babel_637_float(cast(41.9 as double precision));
GO

SELECT babel_637_float(cast(123456789012.1 as double precision));
GO

SELECT babel_637_float(cast(41.9 as float));
GO

SELECT babel_637_float(cast(123456789012.1 as float));
GO

SELECT babel_637_float(cast(41.9 as fixeddecimal));
GO

SELECT babel_637_float(cast(123456789012.1 as fixeddecimal));
GO

SELECT babel_637_float(cast(41.9 as numeric(8,4)));
GO

SELECT babel_637_float(cast(123456789012.1 as numeric(18,4)));
GO

SELECT babel_637_float(cast(41.9 as money));
GO

SELECT babel_637_float(cast(922337203685475.5807 as money));
GO

SELECT babel_637_float(cast(41.9 as smallmoney));
GO

SELECT babel_637_float(cast(214746.3647 as smallmoney));
GO

SELECT babel_637_float(cast(41 as bigint));
GO

SELECT babel_637_float(cast(9223372036854775806 as bigint));
GO

SELECT babel_637_float(cast(41 as int));
GO

SELECT babel_637_float(cast(2147483646 as int));
GO

SELECT babel_637_float(cast(41 as smallint));
GO

SELECT babel_637_float(cast(32766 as smallint));
GO

SELECT babel_637_float(cast(41 as tinyint));
GO

SELECT babel_637_float(cast(254 as tinyint));
GO


-- all number type to fixeddecimal
CREATE FUNCTION babel_637_add_one_fixeddecimal (@a fixeddecimal)
RETURNS fixeddecimal AS
BEGIN
  RETURN @a + 1;
END;
GO

SELECT babel_637_add_one_fixeddecimal(cast(41.9 as double precision));
GO

SELECT babel_637_add_one_fixeddecimal(cast(123456789012.1 as double precision));
GO

SELECT babel_637_add_one_fixeddecimal(cast(41.9 as float));
GO

SELECT babel_637_add_one_fixeddecimal(cast(123456789012.1 as float));
GO

SELECT babel_637_add_one_fixeddecimal(cast(41.9 as fixeddecimal));
GO

SELECT babel_637_add_one_fixeddecimal(cast(123456789012.1 as fixeddecimal));
GO

SELECT babel_637_add_one_fixeddecimal(cast(41.9 as numeric(8,4)));
GO

SELECT babel_637_add_one_fixeddecimal(cast(123456789012.1 as numeric(18,4)));
GO

SELECT babel_637_add_one_fixeddecimal(cast(41.9 as money));
GO

SELECT babel_637_add_one_fixeddecimal(cast(922337203685475.5807 as money));
GO

SELECT babel_637_add_one_fixeddecimal(cast(41.9 as smallmoney));
GO

SELECT babel_637_add_one_fixeddecimal(cast(214746.3647 as smallmoney));
GO

SELECT babel_637_add_one_fixeddecimal(cast(41 as bigint));
GO

SELECT babel_637_add_one_fixeddecimal(cast(9223372036854775806 as bigint));
GO

SELECT babel_637_add_one_fixeddecimal(cast(41 as int));
GO

SELECT babel_637_add_one_fixeddecimal(cast(2147483646 as int));
GO

SELECT babel_637_add_one_fixeddecimal(cast(41 as smallint));
GO

SELECT babel_637_add_one_fixeddecimal(cast(32766 as smallint));
GO

SELECT babel_637_add_one_fixeddecimal(cast(41 as tinyint));
GO

SELECT babel_637_add_one_fixeddecimal(cast(254 as tinyint));
GO


-- all number type to numeric
CREATE FUNCTION babel_637_add_one_numeric (@a numeric)
RETURNS numeric AS
BEGIN
  RETURN @a + 1;
END;
GO

SELECT babel_637_add_one_numeric(cast(41.9 as double precision));
GO

SELECT babel_637_add_one_numeric(cast(123456789012.1 as double precision));
GO

SELECT babel_637_add_one_numeric(cast(41.9 as float));
GO

SELECT babel_637_add_one_numeric(cast(123456789012.1 as float));
GO

SELECT babel_637_add_one_numeric(cast(41.9 as fixeddecimal));
GO

SELECT babel_637_add_one_numeric(cast(123456789012.1 as fixeddecimal));
GO

SELECT babel_637_add_one_numeric(cast(41.9 as numeric(8,4)));
GO

SELECT babel_637_add_one_numeric(cast(123456789012.1 as numeric(18,4)));
GO

SELECT babel_637_add_one_numeric(cast(41.9 as money));
GO

SELECT babel_637_add_one_numeric(cast(922337203685475.5807 as money));
GO

SELECT babel_637_add_one_numeric(cast(41.9 as smallmoney));
GO

SELECT babel_637_add_one_numeric(cast(214746.3647 as smallmoney));
GO

SELECT babel_637_add_one_numeric(cast(41 as bigint));
GO

SELECT babel_637_add_one_numeric(cast(9223372036854775806 as bigint));
GO

SELECT babel_637_add_one_numeric(cast(41 as int));
GO

SELECT babel_637_add_one_numeric(cast(2147483646 as int));
GO

SELECT babel_637_add_one_numeric(cast(41 as smallint));
GO

SELECT babel_637_add_one_numeric(cast(32766 as smallint));
GO

SELECT babel_637_add_one_numeric(cast(41 as tinyint));
GO

SELECT babel_637_add_one_numeric(cast(254 as tinyint));
GO


-- all number type to money
CREATE FUNCTION babel_637_add_one_money (@a money)
RETURNS money AS
BEGIN
  RETURN @a + 1;
END;
GO

SELECT babel_637_add_one_money(cast(41.9 as double precision));
GO

SELECT babel_637_add_one_money(cast(123456789012.1 as double precision));
GO

SELECT babel_637_add_one_money(cast(41.9 as float));
GO

SELECT babel_637_add_one_money(cast(123456789012.1 as float));
GO

SELECT babel_637_add_one_money(cast(41.9 as fixeddecimal));
GO

SELECT babel_637_add_one_money(cast(123456789012.1 as fixeddecimal));
GO

SELECT babel_637_add_one_money(cast(41.9 as numeric(8,4)));
GO

SELECT babel_637_add_one_money(cast(123456789012.1 as numeric(18,4)));
GO

SELECT babel_637_add_one_money(cast(41.9 as money));
GO

SELECT babel_637_add_one_money(cast(922337203685475.5807 as money));
GO

SELECT babel_637_add_one_money(cast(41.9 as smallmoney));
GO

SELECT babel_637_add_one_money(cast(214746.3647 as smallmoney));
GO

SELECT babel_637_add_one_money(cast(41 as bigint));
GO

SELECT babel_637_add_one_money(cast(9223372036854775806 as bigint));
GO

SELECT babel_637_add_one_money(cast(41 as int));
GO

SELECT babel_637_add_one_money(cast(2147483646 as int));
GO

SELECT babel_637_add_one_money(cast(41 as smallint));
GO

SELECT babel_637_add_one_money(cast(32766 as smallint));
GO

SELECT babel_637_add_one_money(cast(41 as tinyint));
GO

SELECT babel_637_add_one_money(cast(254 as tinyint));
GO


-- all number type to smallmoney
CREATE FUNCTION babel_637_add_one_smallmoney (@a smallmoney)
RETURNS smallmoney AS
BEGIN
  RETURN @a + 1;
END;
GO

SELECT babel_637_add_one_smallmoney(cast(41.9 as double precision));
GO

SELECT babel_637_add_one_smallmoney(cast(123456789012.1 as double precision));
GO

SELECT babel_637_add_one_smallmoney(cast(41.9 as float));
GO

SELECT babel_637_add_one_smallmoney(cast(123456789012.1 as float));
GO

SELECT babel_637_add_one_smallmoney(cast(41.9 as fixeddecimal));
GO

SELECT babel_637_add_one_smallmoney(cast(123456789012.1 as fixeddecimal));
GO

SELECT babel_637_add_one_smallmoney(cast(41.9 as numeric(8,4)));
GO

SELECT babel_637_add_one_smallmoney(cast(123456789012.1 as numeric(18,4)));
GO

SELECT babel_637_add_one_smallmoney(cast(41.9 as money));
GO

SELECT babel_637_add_one_smallmoney(cast(922337203685475.5807 as money));
GO

SELECT babel_637_add_one_smallmoney(cast(41.9 as smallmoney));
GO

SELECT babel_637_add_one_smallmoney(cast(214746.3647 as smallmoney));
GO

SELECT babel_637_add_one_smallmoney(cast(41 as bigint));
GO

SELECT babel_637_add_one_smallmoney(cast(9223372036854775806 as bigint));
GO

SELECT babel_637_add_one_smallmoney(cast(41 as int));
GO

SELECT babel_637_add_one_smallmoney(cast(2147483646 as int));
GO

SELECT babel_637_add_one_smallmoney(cast(41 as smallint));
GO

SELECT babel_637_add_one_smallmoney(cast(32766 as smallint));
GO

SELECT babel_637_add_one_smallmoney(cast(41 as tinyint));
GO

SELECT babel_637_add_one_smallmoney(cast(254 as tinyint));
GO


-- all number type to bigint
CREATE FUNCTION babel_637_add_one_bigint (@a bigint)
RETURNS bigint AS
BEGIN
  RETURN @a + 1;
END;
GO

SELECT babel_637_add_one_bigint(cast(41.9 as double precision));
GO

SELECT babel_637_add_one_bigint(cast(123456789012.1 as double precision));
GO

SELECT babel_637_add_one_bigint(cast(41.9 as float));
GO

SELECT babel_637_add_one_bigint(cast(123456789012.1 as float));
GO

SELECT babel_637_add_one_bigint(cast(41.9 as fixeddecimal));
GO

SELECT babel_637_add_one_bigint(cast(123456789012.1 as fixeddecimal));
GO

SELECT babel_637_add_one_bigint(cast(41.9 as numeric(8,4)));
GO

SELECT babel_637_add_one_bigint(cast(123456789012.1 as numeric(18,4)));
GO

SELECT babel_637_add_one_bigint(cast(41.9 as money));
GO

SELECT babel_637_add_one_bigint(cast(922337203685475.5807 as money));
GO

SELECT babel_637_add_one_bigint(cast(41.9 as smallmoney));
GO

SELECT babel_637_add_one_bigint(cast(214746.3647 as smallmoney));
GO

SELECT babel_637_add_one_bigint(cast(41 as bigint));
GO

SELECT babel_637_add_one_bigint(cast(9223372036854775806 as bigint));
GO

SELECT babel_637_add_one_bigint(cast(41 as int));
GO

SELECT babel_637_add_one_bigint(cast(2147483646 as int));
GO

SELECT babel_637_add_one_bigint(cast(41 as smallint));
GO

SELECT babel_637_add_one_bigint(cast(32766 as smallint));
GO

SELECT babel_637_add_one_bigint(cast(41 as tinyint));
GO

SELECT babel_637_add_one_bigint(cast(254 as tinyint));
GO


-- all number type to int4
CREATE FUNCTION babel_637_add_one_int4 (@a int)
RETURNS int AS
BEGIN
  RETURN @a + 1;
END;
GO

SELECT babel_637_add_one_int4(cast(41.9 as double precision));
GO

SELECT babel_637_add_one_int4(cast(123456789012.1 as double precision));
GO

SELECT babel_637_add_one_int4(cast(41.9 as float));
GO

SELECT babel_637_add_one_int4(cast(123456789012.1 as float));
GO

SELECT babel_637_add_one_int4(cast(41.9 as fixeddecimal));
GO

SELECT babel_637_add_one_int4(cast(123456789012.1 as fixeddecimal));
GO

SELECT babel_637_add_one_int4(cast(41.9 as numeric(8,4)));
GO

SELECT babel_637_add_one_int4(cast(123456789012.1 as numeric(18,4)));
GO

SELECT babel_637_add_one_int4(cast(41.9 as money));
GO

SELECT babel_637_add_one_int4(cast(922337203685475.5807 as money));
GO

SELECT babel_637_add_one_int4(cast(41.9 as smallmoney));
GO

SELECT babel_637_add_one_int4(cast(214746.3647 as smallmoney));
GO

SELECT babel_637_add_one_int4(cast(41 as bigint));
GO

SELECT babel_637_add_one_int4(cast(9223372036854775806 as bigint));
GO

SELECT babel_637_add_one_int4(cast(41 as int));
GO

SELECT babel_637_add_one_int4(cast(2147483646 as int));
GO

SELECT babel_637_add_one_int4(cast(41 as smallint));
GO

SELECT babel_637_add_one_int4(cast(32766 as smallint));
GO

SELECT babel_637_add_one_int4(cast(41 as tinyint));
GO

SELECT babel_637_add_one_int4(cast(254 as tinyint));
GO


-- all number type to smallint
CREATE FUNCTION babel_637_add_one_smallint (@a smallint)
RETURNS smallint AS
BEGIN
  RETURN @a + 1;
END;
GO

SELECT babel_637_add_one_smallint(cast(41.9 as double precision));
GO

SELECT babel_637_add_one_smallint(cast(123456789012.1 as double precision));
GO

SELECT babel_637_add_one_smallint(cast(41.9 as float));
GO

SELECT babel_637_add_one_smallint(cast(123456789012.1 as float));
GO

SELECT babel_637_add_one_smallint(cast(41.9 as fixeddecimal));
GO

SELECT babel_637_add_one_smallint(cast(123456789012.1 as fixeddecimal));
GO

SELECT babel_637_add_one_smallint(cast(41.9 as numeric(8,4)));
GO

SELECT babel_637_add_one_smallint(cast(123456789012.1 as numeric(18,4)));
GO

SELECT babel_637_add_one_smallint(cast(41.9 as money));
GO

SELECT babel_637_add_one_smallint(cast(922337203685475.5807 as money));
GO

SELECT babel_637_add_one_smallint(cast(41.9 as smallmoney));
GO

SELECT babel_637_add_one_smallint(cast(214746.3647 as smallmoney));
GO

SELECT babel_637_add_one_smallint(cast(41 as bigint));
GO

SELECT babel_637_add_one_smallint(cast(9223372036854775806 as bigint));
GO

SELECT babel_637_add_one_smallint(cast(41 as int));
GO

SELECT babel_637_add_one_smallint(cast(2147483646 as int));
GO

SELECT babel_637_add_one_smallint(cast(41 as smallint));
GO

SELECT babel_637_add_one_smallint(cast(32766 as smallint));
GO

SELECT babel_637_add_one_smallint(cast(41 as tinyint));
GO

SELECT babel_637_add_one_smallint(cast(254 as tinyint));
GO


-- all number type to tinyint
CREATE FUNCTION babel_637_add_one_tinyint (@a tinyint)
RETURNS tinyint AS
BEGIN
  RETURN @a + 1;
END;
GO

SELECT babel_637_add_one_tinyint(cast(41.9 as double precision));
GO

SELECT babel_637_add_one_tinyint(cast(123456789012.1 as double precision));
GO

SELECT babel_637_add_one_tinyint(cast(41.9 as float));
GO

SELECT babel_637_add_one_tinyint(cast(123456789012.1 as float));
GO

SELECT babel_637_add_one_tinyint(cast(41.9 as fixeddecimal));
GO

SELECT babel_637_add_one_tinyint(cast(123456789012.1 as fixeddecimal));
GO

SELECT babel_637_add_one_tinyint(cast(41.9 as numeric(8,4)));
GO

SELECT babel_637_add_one_tinyint(cast(123456789012.1 as numeric(18,4)));
GO

SELECT babel_637_add_one_tinyint(cast(41.9 as money));
GO

SELECT babel_637_add_one_tinyint(cast(922337203685475.5807 as money));
GO

SELECT babel_637_add_one_tinyint(cast(41.9 as smallmoney));
GO

SELECT babel_637_add_one_tinyint(cast(214746.3647 as smallmoney));
GO

SELECT babel_637_add_one_tinyint(cast(41 as bigint));
GO

SELECT babel_637_add_one_tinyint(cast(9223372036854775806 as bigint));
GO

SELECT babel_637_add_one_tinyint(cast(41 as int));
GO

SELECT babel_637_add_one_tinyint(cast(2147483646 as int));
GO

SELECT babel_637_add_one_tinyint(cast(41 as smallint));
GO

SELECT babel_637_add_one_tinyint(cast(32766 as smallint));
GO

SELECT babel_637_add_one_tinyint(cast(41 as tinyint));
GO

SELECT babel_637_add_one_tinyint(cast(254 as tinyint));
GO

DROP FUNCTION babel_637_int_multiply;
DROP FUNCTION babel_637_double_precision;
DROP FUNCTION babel_637_float;
DROP FUNCTION babel_637_add_one_fixeddecimal;
DROP FUNCTION babel_637_add_one_numeric;
DROP FUNCTION babel_637_add_one_money;
DROP FUNCTION babel_637_add_one_smallmoney;
DROP FUNCTION babel_637_add_one_bigint;
DROP FUNCTION babel_637_add_one_int4;
DROP FUNCTION babel_637_add_one_smallint;
DROP FUNCTION babel_637_add_one_tinyint;
GO
