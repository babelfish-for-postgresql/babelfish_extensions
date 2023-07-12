create table t ( a varchar(30))
GO

insert into t values ('abc'),('bbc'),('cbc'),('=bc'),('Abc'),('a[bc'),('a]bc');
GO

select * from t where a like '[%' -- suppose not having any result
GO

select * from t where a like '[c-a]bc'
GO

select * from t where a like '[<->]bc'
GO

select * from t where a like '[0-a]bc';
GO

select * from t where a like '[abc]bc';
GO

select * from t where a like '[a-c]bc';
GO

select * from t where a like '[abc]_c';
GO

select * from t where a like '[a]%c';
GO

select * from t where a like '%[abc]c';
GO

select * from t where a like '[%]bc';
GO

select * from t where a like '[_]bc';
GO

select * from t where a like 'a[bc]c';
GO

select * from t where a like '[a-z][a-z]c';
GO

select * from t where a like '[^ a][a-z]c';
GO

select * from t where a like '[^ a-b][a-z]c';
GO

select * from t where a like '%bc';
GO

select * from t where a like '[0-9a-f][0-9a-f][0-9a-f]';
GO

insert into t values (']bc')
GO

insert into t values ('[bc')
GO

select * from t where a like ('[]]bc');
GO

select * from t where a like ('[[]bc');
GO

select * from t where a like ']bc';
GO

insert into t values ('11.22');
GO

select * from t where a like '[0-9][0-9].[0-9][0-9]'
GO

create table t2 ( b varchar(30) collate BBF_Unicode_General_CS_AS)
GO

insert into t2 values ('[abc]bc'),('[abc]_c'),('[]]bc'),('[[]bc'),('%[abc]c'),('[^ a-b][a-z]c'),('[0-9][0-9].[0-9][0-9]'),('[<->]bc')
GO

select * from t2 join t on a like b;
GO

drop table t2;
GO

drop table t;
GO

DROP TABLE IF EXISTS t1
GO
CREATE TABLE t1 
(
 c1 int IDENTITY(1, 1)
,string varchar(20) null
,patt   varchar(20) null
,esc    varchar(2) null
)
go
insert t1 values
(null,null,null),
('ABCD', 'AB[C]D', 'X'),
('ABCD', 'ABcD', null), 
('AB[C]D', 'ABZ[C]D', 'Z'),
('AB[C]D', 'ABZ[C]D', 'z')
go
-- returns 2,3,4 , babel return 2,4 BABEL-4271
select c1 from t1 where string like patt escape esc 
and c1 > 1 order by c1
go

DROP TABLE IF EXISTS t1
GO
CREATE TABLE t1
(
 c1 int IDENTITY(1, 1)
,string varchar(50) 
)
GO

--Note: we rely on identity value being generated sequentially 
--from 1 in same order as the values in INSERT
INSERT INTO t1 (string) 
VALUES
 ('451201-7825')
,('451201x7825')
,('Andersson')
,('Bertilsson')
,('Carlson')
,('Davidsson')
,('Eriksson')
,('Fredriksson')
,('F')
,('F.')
,('Göransson')
,('Karlsson')
,('KarlsTon')
,('Karlson')
,('Persson')
,('Uarlson')
,('McDonalds')
,('MacDonalds')
,('15% off')
,('15 % off')
,('15 %off')
,('15 %')
,('15 % /off')
,('My[String')
,('My]String')
,('My[]String')
,('My][String')
,('My[valid]String')

--Swedish person-nummer(nnnnnn-nnnn); should return rows 1
SELECT * FROM t1 WHERE string LIKE '[0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]' 
go

--As above, using REPLICATE; should return rows 1
SELECT * FROM t1 WHERE string LIKE REPLICATE('[0-9]', 6) + '-' + REPLICATE('[0-9]', 4)
go

--First 6 characters are numbers, using REPLICATE; should return rows 1 and 2
SELECT * FROM t1 WHERE SUBSTRING(string, 1, 6) LIKE REPLICATE('[0-9]', 6)
go

--Enumeration, all Karlsson with C or K, one or two s should return rows: 5, 12, 14
SELECT * FROM t1 WHERE string LIKE '[CK]arlson' OR string LIKE '[CK]arlsson'
go

--Negative enumeration, all Karlson except those with C or K; should return rows: 16
SELECT * FROM t1 WHERE string LIKE '[^CK]arlson'
go

--Starts in range A-F; should return rows 3-10
SELECT * FROM t1 WHERE string LIKE '[A-F]%' ORDER BY c1
go

--Two ranges, A-B and E-G; should return rows 3-4, 7-11
SELECT * FROM t1 WHERE string LIKE '[A-BE-G]%' ORDER BY c1
go

--Starts in range A-C and also starting with E and G; should return rows 3, 4, 5, 7, 11
SELECT * FROM t1 WHERE string LIKE '[A-CEG]%' ORDER BY c1
go

--All Donalds starting with M, exclude following c; should return rows 18
SELECT * FROM t1 WHERE string LIKE 'M[^c]%Donalds' ORDER BY c1
go

--15% off using ESCAPE; should return rows 19
SELECT * FROM t1 WHERE string LIKE '15/% %' ESCAPE '/' ORDER BY c1
go

--15% off using a different ESCAPE character; should return rows 19
SELECT * FROM t1 WHERE string LIKE '15!% %' ESCAPE '!' ORDER BY c1
go

--15% off using square brackets; should return rows 19
SELECT * FROM t1 WHERE string LIKE '15[%] %'  ORDER BY c1
go

--15 % off ; should return rows 21
SELECT * FROM t1 WHERE string LIKE '15 /%___' ESCAPE '/' ORDER BY c1
go

--Searching for the escape character itself; should return rows 23
SELECT * FROM t1 WHERE string LIKE '15 [%] //off' ESCAPE '/' ORDER BY c1
go

--Contains [; should return rows 24, 26, 27, 28
SELECT * FROM t1 WHERE string LIKE '%[[]%'  ORDER BY c1
go

--Contains ]; should return rows 25, 26, 27, 28
SELECT * FROM t1 WHERE string LIKE '%]%'  ORDER BY c1
go

--As above, but allow "ö", should return same as above, except row 11 (Göransson)
SELECT * FROM t1 WHERE string LIKE '%[^a-zA-Z0-9öÖ]%' ORDER BY c1
go

--Negate above, and exclude the numbers, i.e. "only clean letters". Should return 3-9, 11-18
SELECT * FROM t1 WHERE string NOT LIKE '%[^a-zA-ZåÅäÄöÖ]%' ORDER BY c1
go

--As above, but also allow for dot ".". Should return 3-18
SELECT * FROM t1 WHERE string  NOT LIKE '%[^a-zA-ZåÅäÄöÖ.]%' ORDER BY c1
go

--As above, but also allow for "[". Should return 3-18, 24
SELECT * FROM t1 WHERE string  NOT LIKE '%[^a-zA-ZåÅäÄöÖ.[?[]%' ESCAPE '?' ORDER BY c1
go


--- test case with LIKE in a CHECK constraint  -----------------
DROP TABLE IF EXISTS t1
GO
CREATE TABLE t1
(
 c1 int PRIMARY KEY
,pnr char(11) CHECK (pnr LIKE '[0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')
)
GO
--Verify it does its job
INSERT INTO t1 (c1, pnr) VALUES(1, '451201-7825') --Should be OK
GO
INSERT INTO t1 (c1, pnr) VALUES(1, '451d01-7825') --Should fail
GO
INSERT INTO t1 (c1, pnr) VALUES(1, '451201w7825') --Should fail
GO

drop table t1;
GO

DROP TABLE IF EXISTS IP_address
GO
CREATE TABLE IP_address
(
 c1 int IDENTITY(1, 1)
,string varchar(50) 
,is_valid bit
)
GO

INSERT INTO IP_address (string, is_valid)
VALUES
--Valid:
 ('131.107.2.201', 1)
,('131.33.2.201', 1)
,('131.33.2.202', 1)
,('3.107.2.4', 1)
,('3.107.3.169', 1)
,('3.107.104.172', 1)
,('22.107.202.123', 1)
,('22.20.2.77', 1)
,('22.156.9.91', 1)
,('22.156.89.32', 1)
--Not valid:
,('22.356.89.32', 0)
,('1.1.1.256', 0)
,('1.1.1.1.1', 0)
,('1.1.1', 0)
,('1..1.1', 0)
,('.1.1.1', 0)
,('a.1.1.1', 0)
go

SELECT * FROM IP_address
WHERE 
	-- 3 periods and no empty octets
    string LIKE '_%._%._%._%'
  AND
    -- not 4 periods or more
    string NOT LIKE '%.%.%.%.%'
  AND
    -- no characters other than digits and periods
    string NOT LIKE '%[^0-9.]%'
  AND
    -- not more than 3 digits per octet
    string NOT LIKE '%[0-9][0-9][0-9][0-9]%'
  AND
    -- NOT 300 - 999
    string NOT LIKE '%[3-9][0-9][0-9]%'
  AND
    -- NOT 260 - 299
    string NOT LIKE '%2[6-9][0-9]%'
  AND
    -- NOT 256 - 259
    string NOT LIKE '%25[6-9]%'
ORDER BY c1
go

--Negate the full above predicate; should return rows 11-17
SELECT * FROM IP_address
WHERE NOT(
	-- 3 periods and no empty octets
    string LIKE '_%._%._%._%'
  AND
    -- not 4 periods or more
    string NOT LIKE '%.%.%.%.%'
  AND
    -- no characters other than digits and periods
    string NOT LIKE '%[^0-9.]%'
  AND
    -- not more than 3 digits per octet
    string NOT LIKE '%[0-9][0-9][0-9][0-9]%'
  AND
    -- NOT 300 - 999
    string NOT LIKE '%[3-9][0-9][0-9]%'
  AND
    -- NOT 260 - 299
    string NOT LIKE '%2[6-9][0-9]%'
  AND
    -- NOT 256 - 259
    string NOT LIKE '%25[6-9]%')
ORDER BY c1
go

drop table IP_address
GO

select 1 where '9' like '[a-z0-9]'  -- 1
GO

select 1 where '9' like '[0-9'  -- no row 
GO

select 1 where 'b' like '[a-z0-9]'  -- 1
GO

select 1 where '7' like '[^a-z0-9]'  -- no row
GO

select 1 where 'D' like '[C-P5-7]'  -- 1
go

select 1 where 'B' like '[C-P5-7]'  -- no row
go

select 1 where 'B' like '[^C-P5-7]'  -- 1
go

select 1 where '4' like '[C-P5-7]'  -- no row
go

select 1 where '9' like '[C-P5-7]'  -- no row
go

select 1 where '1357' like '[0-9][0-9][0-9][0-9]'  -- 1
go

select 1 where 'a[abc]b' like 'a[abc]b'  -- no row
go

select 1 where 'a[abc]b' like 'a[[]abc]b'  -- 1
go

select 1 where 'a[abc]b' like 'a\[abc]b' escape '\'  -- 1
go

select 1 where 'a[b' like 'a[%'  -- no row
go

select 1 where 'a[b' like 'a[[]%'  -- 1
go

select 1 where '$abc' like '[0-9!@#$.,;_]%'  -- 1
go

select 1 where '$abc' like '[^0-9!@#$.,;_]%'  -- no row
go

select 1 where '$abc' like '[^0-9!@#.,;_]%'  -- 1
go

select 1 where 'abc_efgh' like 'abc[_]efg%'  -- 1
go

select 1 where 'abcdefgh' like 'abc[_]efg%'  -- no row
go

select 1 where 'abcdefgh' like 'abc[^_]efg%'  -- 1
go

select 1 where 'd' like '[asdf]'  -- 1
go

select 1 where 'e' like '[asdf]'  -- no row
go

select 1 where 'e' like '[^asdf]'  -- 1
go

select 1 where 'd' like '[^asdf]'  -- no row
go

declare @v varchar = 'a[bc'
SELECT 1 where @v LIKE '%[%' escape '~' OR @v LIKE '%]%'                -- no row
go

declare @v varchar = 'a[bc'
SELECT 1 where @v LIKE '%[[]%' OR @v LIKE '%[]]%'                       -- no row
go

declare @v varchar = 'a[bc'
SELECT 1 where @v LIKE '%~[%' escape '~' OR @v LIKE '%~]%' escape '~'   -- no row
GO

declare @v varchar = 'a[bc'
set @v = 'a]bc'
SELECT 1 where @v LIKE '%[%' escape '~' OR @v LIKE '%]%'                -- no row
go

declare @v varchar = 'a[bc'
set @v = 'a]bc'
SELECT 1 where @v LIKE '%[[]%' OR @v LIKE '%[]]%'                       -- no row
go

declare @v varchar = 'a[bc'
set @v = 'a]bc'
SELECT 1 where @v LIKE '%~[%' escape '~' OR @v LIKE '%~]%' escape '~'   -- no row
go


declare @v varchar(20), @p varchar(20), @esc char(1)

set @v = '9'set @p = '[a-z0-9]'  -- 1
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)

set @v = '9'set @p = '[0-9'  -- no row
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)

set @v = 'b'set @p = '[a-z0-9]'  -- 1
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)

set @v = '7'set @p = '[^a-z0-9]'  -- no row
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)

set @v = 'D'set @p = '[C-P5-7]'  -- 1
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)

set @v = 'B'set @p = '[C-P5-7]'  -- no row
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = 'B'set @p = '[^C-P5-7]'  -- 1
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = '4'set @p = '[C-P5-7]'  -- no row
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = '9'set @p = '[C-P5-7]'  -- no row
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = 'a[abc]b'set @p = 'a[abc]b'  -- no row
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = 'a[abc]b'set @p = 'a[[]abc]b'   -- 1
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = 'a[abc]b'set @p = 'a\[abc]b' set @esc = '\' -- 1
select 1 where @v like @p escape @esc 
go

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = 'a[b'set @p = 'a[%'  -- no row
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = 'a[b'set @p = 'a[[]%'  -- 1
select 1 where @v like @p 
GO

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = '$abc'set @p = '[0-9!@#$.,;_]%'  -- 1
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = '$abc'set @p = '[^0-9!@#$.,;_]%'  -- no row
select 1 where @v like @p 
GO

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = 'abc_efgh' set @p = 'abc[_]efg%'  -- 1
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = 'abcdefgh' set @p = 'abc[_]efg%'  -- no row
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = 'abcdefgh' set @p = 'abc[^_]efg%'  -- 1
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = 'd' set @p = '[asdf]'  -- 1
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = 'e' set @p = '[asdf]'  -- no row
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = 'e' set @p = '[^asdf]'  -- 1
select 1 where @v like @p 
go

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = 'd' set @p = '[^asdf]'  -- no row
select 1 where @v like @p 
go

-- the following currently returns wrong result in BBF!
select 1 where '_ab' like '\_ab'          -- no row, but returns 1  in BBF , BABEL-4270
GO

select 1 where '%AAABBB%' like '\%AAA%'   -- no row, but returns 1  in BBF , BABEL-4270
go

select 1 where '_ab' like '\_ab'  escape '\'         -- 1 
select 1 where '%AAABBB%' like '\%AAA%' escape '\'   -- 1
go

select 1 where 'AB[C]D' LIKE 'AB~[C]D'             -- no row
select 1 where 'AB[C]D' LIKE 'AB~[C]D' ESCAPE '~'  -- 1
go

select 1 where 'AB[C]D' LIKE 'AB\[C]D'             -- no row
select 1 where 'AB[C]D' LIKE 'AB\[C]D' ESCAPE '\'  -- 1
GO

select 1 where 'AB[C]D' LIKE 'AB [C]D'             -- no row
select 1 where 'AB[C]D' LIKE 'AB [C]D' ESCAPE ' '  -- 1
GO

select 1 where 'AB[C]D' LIKE 'AB[C]D' ESCAPE 'B'   -- no row
select 1 where 'AB[C]D' LIKE 'ABB[C]D' ESCAPE 'B'  -- no row
go

select 1 where 'AB[C]D' LIKE 'ABZ[C]D' ESCAPE 'Z'  -- 1
select 1 where 'AB[C]D' LIKE 'ABZ[C]D' ESCAPE 'z'  -- no row! Note: SQL Server treats the escape as case-sensitive!
select 1 where 'ABCD' LIKE 'ABcD'                  -- 1 : SQL Server treats normal LIKE pattern case-INsensitive
go

select 1 where null like null -- no row
go
select 1 where null like null escape null -- no row
go
select 1 where null like 'ABC' -- no row
go
select 1 where 'ABC' like null -- no row
go

 
select 1 where 'ABCD' LIKE 'AB[C]D' ESCAPE ''  -- should raise error , BABEL-4271
go
select 1 where 'ABCD' LIKE 'AB[C]D' ESCAPE 'xy'  -- raise error
go

create table tt ( a bytea);
go

insert into tt values (0xdaa)
GO

select * from tt where a like 'da[%]';
GO

select * from tt where a not like 'da[%]';
go

drop table tt;
GO
