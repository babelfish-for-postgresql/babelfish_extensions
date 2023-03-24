-- The default scale is 2 in PG.
select CAST('$100,123.4567' AS money);
GO
-- Currency symbol followed by number without being quoted is not recognized
-- as Money in postgres dialect.
select CAST($100123.4567 AS money);
GO

-- Scale changes to the sql server default 4 in tsql dialect
-- Currency symbol followed by number without being quoted is recognized
-- as Money type in tsql dialect.
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
select CAST($100123.4567 AS money);
GO
select CAST($100123. AS money);
GO
select CAST($.4567 AS money);
GO
select CAST('$100,123.4567' AS money);
GO

-- Test numeric types with brackets
create table testing1 (a [tinyint]);
GO
drop table testing1;
GO
create table testing1 (a [smallint]);
GO
drop table testing1;
GO
create table testing1 (a [int]);
GO
drop table testing1;
GO
create table testing1 (a [bigint]);
GO
drop table testing1;
GO
create table testing1 (a [real]);
GO
drop table testing1;
GO
create table testing1 (a [float]);
GO
drop table testing1;
GO

-- Comma separated format without quote is not allowed in sql server
select CAST($100,123.4567 AS money);
GO

-- Smallmoney in tsql dialect
select CAST($100123.4567 AS smallmoney);
GO
select CAST('$100,123.4567' AS smallmoney);
GO
-- Comma separated format without quote is not allowed in sql server
select CAST($100,123.4567 AS smallmoney);
GO

create table testing1(mon money, smon smallmoney);
GO
insert into testing1 (mon, smon) values ('$100,123.4567', '$123.9999');
insert into testing1 (mon, smon) values ($100123.4567, $123.9999);
GO
select * from testing1;
GO
select avg(CAST(mon AS numeric(38,4))), avg(CAST(smon AS numeric(38,4))) from testing1;
GO
select mon+smon as total from testing1;
GO
-- Comma separated format without quote is not allowed in sql server
insert into testing1 (mon, smon) values ($100,123.4567, $123.9999);
GO