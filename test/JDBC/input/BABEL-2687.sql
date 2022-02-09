use master;
GO

-- real+bigint -> real
select cast(pg_typeof(CAST(324.463 AS real) + CAST(5000 AS bigint)) as varchar(100)) rettype;
GO
-- real*bigint -> real
select cast(pg_typeof(CAST(324.463 AS real) * CAST(5000 AS bigint)) as varchar(100)) rettype;
GO
-- smallmoney+bigint -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) + CAST(5000 AS bigint)) as varchar(100)) rettype;
GO
-- smallmoney/bigint -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) / CAST(5000 AS bigint)) as varchar(100)) rettype;
GO
-- real*decimal(12,4) -> real
select cast(pg_typeof(CAST(324.463 AS real) * CAST(54535.5656 AS decimal(12,4))) as varchar(100)) rettype;
GO
-- smallmoney-int -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) - CAST(1000 AS int)) as varchar(100)) rettype;
GO
-- real/decimal(12,4) -> real
select cast(pg_typeof(CAST(324.463 AS real) / CAST(54535.5656 AS decimal(12,4))) as varchar(100)) rettype;
GO
-- real-decimal(12,4) -> real
select cast(pg_typeof(CAST(324.463 AS real) - CAST(54535.5656 AS decimal(12,4))) as varchar(100)) rettype;
GO
-- real/int -> real
select cast(pg_typeof(CAST(324.463 AS real) / CAST(1000 AS int)) as varchar(100)) rettype;
GO
-- real*int -> real
select cast(pg_typeof(CAST(324.463 AS real) * CAST(1000 AS int)) as varchar(100)) rettype;
GO
-- real+int -> real
select cast(pg_typeof(CAST(324.463 AS real) + CAST(1000 AS int)) as varchar(100)) rettype;
GO
-- smallmoney*int -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) * CAST(1000 AS int)) as varchar(100)) rettype;
GO
-- smallmoney+int -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) + CAST(1000 AS int)) as varchar(100)) rettype;
GO
-- smallmoney+int -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) / CAST(1000 AS int)) as varchar(100)) rettype;
GO
-- smallint/money -> money
select cast(pg_typeof(CAST(100 AS smallint) / CAST(420.2313 AS money)) as varchar(100)) rettype;
GO
-- int/money -> money
select cast(pg_typeof(CAST(1000 AS int) / CAST(420.2313 AS money)) as varchar(100)) rettype;
GO
-- real+money -> real
select cast(pg_typeof(CAST(324.463 AS real) + CAST(420.2313 AS money)) as varchar(100)) rettype;
GO
-- real-money -> real
select cast(pg_typeof(CAST(324.463 AS real) - CAST(420.2313 AS money)) as varchar(100)) rettype;
GO
-- real/money -> real
select cast(pg_typeof(CAST(324.463 AS real) / CAST(420.2313 AS money)) as varchar(100)) rettype;
GO
-- real/numeric(12,4) -> real
select cast(pg_typeof(CAST(324.463 AS real) / CAST(54535.5656 AS numeric(12,4))) as varchar(100)) rettype;
GO
-- real-numeric(12,4) -> real
select cast(pg_typeof(CAST(324.463 AS real) - CAST(54535.5656 AS numeric(12,4))) as varchar(100)) rettype;
GO
-- real*numeric(12,4) --> real
select cast(pg_typeof(CAST(324.463 AS real) * CAST(54535.5656 AS numeric(12,4))) as varchar(100)) rettype;
GO
-- smallint+real -> real
select cast(pg_typeof(CAST(100 AS smallint) + CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- decimal(12,4)-real -> real
select cast(pg_typeof(CAST(54535.5656 AS decimal(12,4)) - CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- smallmoney-real -> real
select cast(pg_typeof(CAST(42.1256 AS smallmoney) - CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- numeric(12,4)-real -> real
select cast(pg_typeof(CAST(54535.5656 AS numeric(12,4)) - CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- int+real -> real
select cast(pg_typeof(CAST(1000 AS int) + CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- bigint-real -> real
select cast(pg_typeof(CAST(5000 AS bigint) - CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- tinyint+real -> real
select cast(pg_typeof(CAST(10 AS tinyint) + CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- tinyint-real -> real
select cast(pg_typeof(CAST(10 AS tinyint) - CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- money+real -> real
select cast(pg_typeof(CAST(420.2313 AS money) + CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- money*real -> real
select cast(pg_typeof(CAST(420.2313 AS money) * CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- decimal(12,4)+real -> real
select cast(pg_typeof(CAST(54535.5656 AS decimal(12,4)) + CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- decimal(12,4)*real -> real
select cast(pg_typeof(CAST(54535.5656 AS decimal(12,4)) * CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- smallmoney/real -> real
select cast(pg_typeof(CAST(42.1256 AS smallmoney) / CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- smallmoney*real -> real
select cast(pg_typeof(CAST(42.1256 AS smallmoney) * CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- bigint/real -> real
select cast(pg_typeof(CAST(5000 AS bigint) / CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- numeric(12,4)*real -> real
select cast(pg_typeof(CAST(54535.5656 AS numeric(12,4)) * CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- numeric(12,4)/real -> real
select cast(pg_typeof(CAST(54535.5656 AS numeric(12,4)) / CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- int/real -> real
select cast(pg_typeof(CAST(1000 AS int) / CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- smallmoney+real -> real
select cast(pg_typeof(CAST(42.1256 AS smallmoney) + CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- bigint*real -> real
select cast(pg_typeof(CAST(5000 AS bigint) * CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- tinyint/real -> real
select cast(pg_typeof(CAST(10 AS tinyint) / CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- smallint*real -> real
select cast(pg_typeof(CAST(100 AS smallint) * CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- real/smallint -> real
select cast(pg_typeof(CAST(324.463 AS real) / CAST(100 AS smallint)) as varchar(100)) rettype;
GO
-- real*smallint -> real
select cast(pg_typeof(CAST(324.463 AS real) * CAST(100 AS smallint)) as varchar(100)) rettype;
GO
-- real+smallint -> real
select cast(pg_typeof(CAST(324.463 AS real) + CAST(100 AS smallint)) as varchar(100)) rettype;
GO
-- smallmoney+smallint -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) + CAST(100 AS smallint)) as varchar(100)) rettype;
GO
-- real-smallint -> real
select cast(pg_typeof(CAST(324.463 AS real) - CAST(100 AS smallint)) as varchar(100)) rettype;
GO
-- smallmoney-smallint -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) - CAST(100 AS smallint)) as varchar(100)) rettype;
GO
-- tinyint*smallmoney -> smallmoney
select cast(pg_typeof(CAST(10 AS tinyint) * CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- bigint*smallmoney -> smallmoney
select cast(pg_typeof(CAST(5000 AS bigint) * CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- bigint-smallmoney -> smallmoney
select cast(pg_typeof(CAST(5000 AS bigint) - CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- bigint+smallmoney -> smallmoney
select cast(pg_typeof(CAST(5000 AS bigint) + CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- real+smallmoney -> real
select cast(pg_typeof(CAST(324.463 AS real) + CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- real*smallmoney -> real
select cast(pg_typeof(CAST(324.463 AS real) * CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- real/smallmoney -> real
select cast(pg_typeof(CAST(324.463 AS real) / CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- int/smallmoney -> smallmoney
select cast(pg_typeof(CAST(1000 AS int) / CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- int-smallmoney -> smallmoney
select cast(pg_typeof(CAST(1000 AS int) - CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- int+smallmoney -> smallmoney
select cast(pg_typeof(CAST(1000 AS int) + CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- tinyint+smallmoney -> smallmoney
select cast(pg_typeof(CAST(10 AS tinyint) + CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- smallint/smallmoney -> smallmoney
select cast(pg_typeof(CAST(100 AS smallint) / CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- smallint*smallmoney -> smallmoney
select cast(pg_typeof(CAST(100 AS smallint) * CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- smallint-smallmoney -> smallmoney
select cast(pg_typeof(CAST(100 AS smallint) - CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- tinyint/smallmoney -> smallmoney
select cast(pg_typeof(CAST(10 AS tinyint) / CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- smallmoney+smallmoney -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) + CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- smallmoney-smallmoney -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) - CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- smallmoney*smallmoney -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) * CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- smallmoney/smallmoney -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) / CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- real-bigint -> real
select cast(pg_typeof(CAST(324.463 AS real) - CAST(5000 AS bigint)) as varchar(100)) rettype;
GO
-- real/bigint -> real
select cast(pg_typeof(CAST(324.463 AS real) / CAST(5000 AS bigint)) as varchar(100)) rettype;
GO
-- smallmoney-bigint -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) - CAST(5000 AS bigint)) as varchar(100)) rettype;
GO
-- smallmoney*bigint -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) * CAST(5000 AS bigint)) as varchar(100)) rettype;
GO
-- real*tinyint -> real
select cast(pg_typeof(CAST(324.463 AS real) * CAST(10 AS tinyint)) as varchar(100)) rettype;
GO
-- real-tinyint -> real
select cast(pg_typeof(CAST(324.463 AS real) - CAST(10 AS tinyint)) as varchar(100)) rettype;
GO
-- smallmoney*tinyint -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) * CAST(10 AS tinyint)) as varchar(100)) rettype;
GO
-- smallmoney-tinyint -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) - CAST(10 AS tinyint)) as varchar(100)) rettype;
GO
-- smallmoney+tinyint -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) + CAST(10 AS tinyint)) as varchar(100)) rettype;
GO
-- real+tinyint -> real
select cast(pg_typeof(CAST(324.463 AS real) + CAST(10 AS tinyint)) as varchar(100)) rettype;
GO
-- tinyint+tinyint -> tinyint
select cast(pg_typeof(CAST(10 AS tinyint) + CAST(10 AS tinyint)) as varchar(100)) rettype;
GO
-- tinyint-tinyint -> tinyint
select cast(pg_typeof(CAST(10 AS tinyint) - CAST(10 AS tinyint)) as varchar(100)) rettype;
GO
-- tinyint*tinyint -> tinyint
select cast(pg_typeof(CAST(10 AS tinyint) * CAST(10 AS tinyint)) as varchar(100)) rettype;
GO
-- tinyint/tinyint -> tinyint
select cast(pg_typeof(CAST(10 AS tinyint) / CAST(10 AS tinyint)) as varchar(100)) rettype;
GO
-- real+decimal(12,4) -> real
select cast(pg_typeof(CAST(324.463 AS real) + CAST(54535.5656 AS decimal(12,4))) as varchar(100)) rettype;
GO
-- real-int -> real
select cast(pg_typeof(CAST(324.463 AS real) - CAST(1000 AS int)) as varchar(100)) rettype;
GO
-- tinyint/money -> money
select cast(pg_typeof(CAST(10 AS tinyint) / CAST(420.2313 AS money)) as varchar(100)) rettype;
GO
-- bigint/money -> money
select cast(pg_typeof(CAST(5000 AS bigint) / CAST(420.2313 AS money)) as varchar(100)) rettype;
GO
-- real*money -> real
select cast(pg_typeof(CAST(324.463 AS real) * CAST(420.2313 AS money)) as varchar(100)) rettype;
GO
-- real+numeric(12,4) -> real
select cast(pg_typeof(CAST(324.463 AS real) + CAST(54535.5656 AS numeric(12,4))) as varchar(100)) rettype;
GO
-- money-real -> real
select cast(pg_typeof(CAST(420.2313 AS money) - CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- money/real -> real
select cast(pg_typeof(CAST(420.2313 AS money) / CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- decimal(12,4)/real -> real
select cast(pg_typeof(CAST(54535.5656 AS decimal(12,4)) / CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- numeric(12,4)+real -> real
select cast(pg_typeof(CAST(54535.5656 AS numeric(12,4)) + CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- int*real -> real
select cast(pg_typeof(CAST(1000 AS int) * CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- int-real -> real
select cast(pg_typeof(CAST(1000 AS int) - CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- bigint+real -> real
select cast(pg_typeof(CAST(5000 AS bigint) + CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- tinyint*real -> real
select cast(pg_typeof(CAST(10 AS tinyint) * CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- smallint/real -> real
select cast(pg_typeof(CAST(100 AS smallint) / CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- smallint-real -> real
select cast(pg_typeof(CAST(100 AS smallint) - CAST(324.463 AS real)) as varchar(100)) rettype;
GO
-- smallmoney/smallint -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) / CAST(100 AS smallint)) as varchar(100)) rettype;
GO
-- smallmoney*smallint -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) * CAST(100 AS smallint)) as varchar(100)) rettype;
GO
-- bigint/smallmoney -> smallmoney
select cast(pg_typeof(CAST(5000 AS bigint) / CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- real-smallmoney -> real
select cast(pg_typeof(CAST(324.463 AS real) - CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- int*smallmoney -> smallmoney
select cast(pg_typeof(CAST(1000 AS int) * CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- smallint+smallmoney -> smallmoney
select cast(pg_typeof(CAST(100 AS smallint) + CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- tinyint-smallmoney -> smallmoney
select cast(pg_typeof(CAST(10 AS tinyint) - CAST(42.1256 AS smallmoney)) as varchar(100)) rettype;
GO
-- smallmoney/tinyint -> smallmoney
select cast(pg_typeof(CAST(42.1256 AS smallmoney) / CAST(10 AS tinyint)) as varchar(100)) rettype;
GO
-- real/tinyint -> real
select cast(pg_typeof(CAST(324.463 AS real) / CAST(10 AS tinyint)) as varchar(100)) rettype;
GO
