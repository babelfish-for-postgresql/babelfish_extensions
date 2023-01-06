CREATE TABLE avg_testing(
sumbigint BIGINT, sumint INT , sumsmallint SMALLINT , sumtinyint TINYINT )
GO

INSERT INTO avg_testing VALUES (9223372036854775807,2147483647,32767,255)
INSERT INTO avg_testing VALUES (9223372036854775807,2147483647,32767,255)
GO

select avg(sumbigint) from avg_testing
GO

select avg(sumint) from avg_testing
GO

drop table avg_testing
go

CREATE TABLE avg_testing2(
sumbigint BIGINT, sumint INT , sumsmallint SMALLINT , sumtinyint TINYINT )
GO

select avg(sumbigint) from avg_testing2
GO
select avg(sumint) from avg_testing2
GO
select avg(sumsmallint) from avg_testing2
GO
select avg(sumtinyint) from avg_testing2
GO

drop table avg_testing2
go

CREATE TABLE avg_testing3(
sumbigint BIGINT, sumint INT , sumsmallint SMALLINT , sumtinyint TINYINT )
GO

INSERT INTO avg_testing3 VALUES(16,8,4,2)
INSERT INTO avg_testing3 VALUES(2,4,8,16)
GO

SELECT avg( sumbigint ) AS sum_int FROM avg_testing3
GO

SELECT avg( sumint ) AS sum_int FROM avg_testing3
GO

SELECT avg( sumsmallint ) AS sum_smallintint FROM avg_testing3
GO

SELECT avg( sumtinyint ) AS sum_tinyint FROM avg_testing3
GO


SELECT 
	cast(pg_typeof( SUM( sumbigint ) ) as varchar(48) )  as sum_bigint 
	, cast(pg_typeof( SUM( sumint ) ) as varchar(48) )  as sum_int 
	, cast(pg_typeof( SUM( sumsmallint ) ) as varchar(48) )  as sum_smallint 
	, cast(pg_typeof( SUM( sumtinyint ) ) as varchar(48) )  as sum_tinyint 
FROM avg_testing3
GO

drop table avg_testing3
go