-- parallel_query_expected
-- simple vars
declare @i int
declare @j int
set @i = 10
set @j = @i + 10
select @i, @j
GO

declare @i int
declare @j int
select @i = 10, @j = @i + 10
select @i, @j
GO

declare @i int
declare @j int = 0;
select @i = 10, @j = @i + @j * 2
select @i, @j
GO

declare @i int
declare @j int
select @i = 10, @j = @i + 10
select @j += 10
select @i, @j
GO

-- should throw an error
declare @i int 
select @i = 0, @i += 2
select @i
GO

declare @i int
select @i = 10, @i += 10
select @i
GO

-- sub-expr
declare @i int
set @i = 10
select @i += (5 - 1)
select @i
GO

DECLARE @a int
select @a = (select ~cast('1' as int))
select @a
go

DECLARE @Counter INT = 1;
DECLARE @MaxValue INT = 10;

WHILE @Counter <= @MaxValue
BEGIN
    DECLARE @IsEven BIT;
    
    IF @Counter % 2 = 0
        SET @IsEven = 1;
    ELSE
        SET @IsEven = 0;
    
    IF @IsEven = 1
        SELECT CAST(@Counter AS VARCHAR(2)) + ' is even';
    ELSE
        SELECT CAST(@Counter AS VARCHAR(2)) + ' is odd';
    
    SET @Counter = @Counter + 1;
END;
GO

declare @a numeric (10, 4);
declare @b numeric (10, 4);
SET @a=100.41;
SET @b=200.82;
SELECT @a, @b
select @a+@b as r;
GO

declare @a numeric;
declare @b numeric (10, 4);
SET @a=100.41;
SET @b=200.82;
SELECT @a, @b
select @a+@b as r;
GO

declare @a varbinary
set @a = cast('test_bin' as varbinary)
select @a
GO

declare @a varbinary(max)
set @a = cast('test_bin' as varbinary)
select @a
GO

declare @a varbinary(10)
set @a = cast('test_bin' as varbinary)
select @a
GO

declare @a varbinary
declare @b varbinary
select @a = cast('test_bin' as varbinary), @b = @a
select @a, @b
GO

declare @a varbinary(max)
select @a = cast('test_bin' as varbinary)
select @a
GO

DECLARE @a varchar
set @a = '12345678901234567890123456789012345';
SELECT LEN(@a), DATALENGTH(@a)
SELECT @a
GO

DECLARE @v varchar(20);
SELECT @v = NULL;
SELECT ISNUMERIC(@v), LEN(@v), DATALENGTH(@v)
GO

DECLARE @a varchar(max)
SELECT @a = '12345678901234567890123456789012345';
SELECT LEN(@a), DATALENGTH(@a)
SELECT @a
GO

-- collate can not be used with local variables
DECLARE @v varchar(20) collate BBF_Unicode_CP1_CI_As = 'ci_as';
GO

declare @source int;
declare @target sql_variant;
select @source = 1.0
select @target = cast(@source as varchar(10));
SELECT sql_variant_property(@target, 'basetype');
select @target
GO

declare @source int;
declare @target varchar(10);
select @source = 1.0
select cast(@source as varchar(10))
select @target = cast(@source as varchar(10));
select @target
GO

DECLARE @a pg_catalog.varchar
SELECT @a = '12345678901234567890123456789012345';
SELECT LEN(@a), DATALENGTH(@a)
SELECT @a
GO

DECLARE @a pg_catalog.varchar(100)
SELECT @a = '12345678901234567890123456789012345';
SELECT LEN(@a), DATALENGTH(@a)
SELECT @a
GO

DECLARE @a pg_catalog.varchar(10)
SELECT @a = '12345678901234567890123456789012345';
SELECT LEN(@a), DATALENGTH(@a)
SELECT @a
GO

DECLARE @a varchar
SELECT @a = '12345678901234567890123456789012345';
SELECT LEN(@a), DATALENGTH(@a)
SELECT @a
GO

DECLARE @a varchar(100)
SELECT @a = '12345678901234567890123456789012345';
SELECT LEN(@a), DATALENGTH(@a)
SELECT @a
GO

DECLARE @a varchar(10)
SELECT @a = '12345678901234567890123456789012345';
SELECT LEN(@a), DATALENGTH(@a)
SELECT @a
GO

DECLARE @a int
set @a = 0
select @a ^= 1
select @a
go

DECLARE @a int
set @a = 0
select @a += ~@a
select @a
go

SET QUOTED_IDENTIFIER OFF
GO

-- quoted identifiers
declare @v varchar(20) = "ABC", @v2 varchar(20)="XYZ";
select @v += "a""b''c'd", @v2 += "x""y''z";
select @v, @v2
GO

declare @v varchar(20) = "ABC", @v2 varchar(20)="XYZ";
select @v += "a""b''c'd", @v2 += @v + "x""y''z";
select @v, @v2
GO

declare @v varchar(20) = "ABC", @v2 varchar(20)="XYZ";
select @v += reverse("a""b''c'd"), @v2 += @v + "x""y''z";
select @v, @v2
GO

declare @v varchar(20) = "ABC", @v2 varchar(20)="XYZ";
select @v += reverse("a""b''c'd"), @v2 += @v + reverse("x""y''z");
select @v, @v2
GO

declare @v varchar(20) = "ABC", @v2 varchar(20)="XYZ";
select @v += reverse("a""b''c'd"), @v2 += REVERSE( @v + reverse("x""y''z"));
select @v, @v2
GO

SET QUOTED_IDENTIFIER ON
GO

declare @v varchar(20) = 'ABC', @v2 varchar(20)='XYZ';
select @v += 'abc', @v2 += 'xyz';
select @v, @v2
GO

declare @a int = 1, @b int = 2;
select @a = 2, @b = @a + 2
select @a, @b
GO

declare @a int = 1, @b int = 2;
select @a += 2, @b -= @a + 2
select @a, @b
GO

-- xml methods
DECLARE @a bit = 1
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @a |= @xml.exist('/artists/artist/@name')
select @a
GO

DECLARE @a bit = 1
DECLARE @xml XML;
SELECT @xml  = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>', @a |= @xml.exist('/artists/artist/@name')
select @a
GO

-- test all kind of udts
create type udt from NCHAR
go

declare @a udt
select @a = 'anc'
select @a
GO

DROP type udt 
GO

create type varchar_max from varchar(max)
GO

DECLARE @a varchar_max
SELECT @a = '12345678901234567890123456789012345';
SELECT LEN(@a), DATALENGTH(@a)
SELECT @a
GO

DROP type varchar_max
GO

create type num_def from numeric
GO

declare @a numeric;
declare @b num_def;
SET @a=100.41;
SET @b=200.82;
SELECT @a, @b
select @a+@b as r;
GO

drop type num_def
GO

/*
 * select/update test
 */
create table local_var_tst (id int) 
GO

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
insert into local_var_tst values (6)
GO

-- txn does not affect local variables
begin tran
declare @i int 
update local_var_tst set id = 5, @i = id * 5
select @i
ROLLBACK tran
select @i
GO

select * from local_var_tst;
GO

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

-- should return 4
declare @i int 
select @i = 1
select @i = id * 2 from local_var_tst where id = @i
select @i
GO

declare @i int 
select @i = 1
select @i = @i + id * 2 from local_var_tst
select @i
GO

declare @i int 
select @i = 1
select @i = id * 2 + @i from local_var_tst
select @i
GO

declare @i int 
select @i = 1
select @i += id * 2 from local_var_tst
select @i
GO

-- 3 parts name 
declare @i int 
select @i = 1
select @i += master.dbo.local_var_tst.id * 2 from local_var_tst
select @i
GO

-- local var name same as column
declare @id int = 1
select @id += master.dbo.local_var_tst.id * 2 from local_var_tst
select @id
GO

-- should throw an error
declare @i int
declare @j int
set @i = 10
set @j = 0;
select @i += (select @j = @j + id from local_var_tst)
select @i
GO

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

DECLARE @ans INT
SELECT @ans = AVG(id) FROM local_var_tst
select @ans
GO

-- local variable inside functions
CREATE FUNCTION var_inside_func()
RETURNS INT AS
BEGIN
    DECLARE @ans INT
    SELECT @ans = AVG(id) FROM local_var_tst
    RETURN @ans
END
GO

select var_inside_func();
GO

DROP FUNCTION var_inside_func();
GO

-- show throw an error
CREATE FUNCTION var_inside_func()
RETURNS @tab table (a int) as
BEGIN
    DECLARE @ans INT
    SELECT @ans += id from local_var_tst
    select @ans
END
GO

drop function if exists var_inside_func
go

CREATE FUNCTION var_inside_func()
RETURNS INT AS
BEGIN
    DECLARE @ans INT
    SELECT @ans += id FROM local_var_tst
    RETURN @ans
END
GO

select var_inside_func()
go

drop function if exists var_inside_func
go

CREATE FUNCTION var_inside_func(@def int)
RETURNS INT AS
BEGIN
    DECLARE @ans INT;
    select @ans = @def;
    SELECT @ans += id FROM local_var_tst
    RETURN @ans
END
GO

select var_inside_func(0)
go

declare @def int = 1;
select var_inside_func(@def)
go

drop function if exists var_inside_func
go

CREATE FUNCTION var_inside_func()
RETURNS INT AS
BEGIN
    DECLARE @ans INT
    select @ans = 0
    SELECT @ans += id + @ans FROM local_var_tst
    RETURN @ans
END
GO

select var_inside_func()
go

drop function if exists var_inside_func
go

-- variable with procedure
CREATE PROCEDURE var_with_procedure (@a numeric(10,4) OUTPUT) AS
BEGIN
  SET @a=100.41;
  select @a as a;
END;
GO

exec var_with_procedure 2.000;
GO

-- value of @out should remain 2.000
declare @out numeric(10,4);
set @out = 2.000;
exec var_with_procedure 2.000;
select @out
GO

drop procedure var_with_procedure;
GO

CREATE PROCEDURE var_with_procedure_1 (@a numeric(10,4) OUTPUT, @b numeric(10,4) OUTPUT) AS
BEGIN
  SET @a=100.41;
  SET @b=200.82;
  select @a+@b as r;
END;
GO

EXEC var_with_procedure_1 2.000, 3.000;
GO

-- value of @a should be 100
DECLARE @a INT;
EXEC var_with_procedure_1 @a OUT, 3.000;
SELECT @a;
GO

drop procedure var_with_procedure_1;
GO

CREATE PROCEDURE var_with_procedure_2
AS
BEGIN
  declare @a int
  declare @b int
  set @a = 1
  return
  select @b=@a+1
END
GO

exec var_with_procedure_2
GO

DROP PROCEDURE var_with_procedure_2
GO

-- insert testing with local variables
truncate table dbo.local_var_tst
go

-- should throw an error
declare @a int = 1
insert into local_var_tst select @a = @a + 1
GO

-- syntax error
declare @a int = 1
insert into local_var_tst values (@a = @a + 1)
GO

declare @a int = 1
insert into local_var_tst values (@a + 1)
GO

-- output clause with insert
declare @a int = 1
declare @mytbl table(a int)
insert local_var_tst output inserted.id into @mytbl values (@a + 1) 
select * from @mytbl
GO

-- output clause with delete
declare @a int = 1
declare @mytbl table(a int)
delete local_var_tst output deleted.id into @mytbl where id = @a + 1
select * from @mytbl
GO

drop table dbo.local_var_tst
go

create table local_var_tst_1 (a int, b int)
GO

insert into local_var_tst_1 values (1,3), (2, 4)
go

-- select test with multi-variable assignment

declare @a int = 0
declare @b int = 0
select @a += a, @b += b from local_var_tst_1
select @a, @b
go

declare @a int = 0
declare @b int = 0
select @a += a, @b += @a + b from local_var_tst_1
select @a, @b
go

declare @a int = 0
declare @b int = 0
select @a += a, @b += @a + ~b from local_var_tst_1
select @a, @b
go

drop table local_var_tst_1
go

create table local_var_str_tst (id varchar(100))
GO

insert into local_var_str_tst values ('abc'), (' '), ('def')
GO

declare @i varchar(1000)
set @i = ''
select @i = @i + id from local_var_str_tst
select @i
go

declare @i varchar(1000)
set @i = ''
select @i = id + @i from local_var_str_tst
select @i
go

declare @i varchar(1000)
set @i = ''
select @i += id from local_var_str_tst
select @i
go

declare @i varchar(1000)
set @i = ''
select @i = reverse(@i + 'id') from local_var_str_tst
select @i
go

declare @i varchar(1000)
set @i = ''
select @i += reverse(id) from local_var_str_tst
select @i
go

declare @i varchar(1000)
set @i = 'abc'
select @i = reverse(@i)
select @i
go

-- function call like trim, ltrim, etc will be rewritten by ANTLR
declare @i varchar(1000)
set @i = ' '
select @i += id from local_var_str_tst
select len(@i), @i
select @i = trim(@i)
select len(@i), @i
go

drop table local_var_str_tst;
go

-- $PARTITION is rewritten by ANTLR
CREATE PARTITION FUNCTION RangePF1 ( INT )  
AS RANGE RIGHT FOR VALUES (10, 100, 1000) ;  
GO

declare @res int = -1;
SELECT @res = $PARTITION.RangePF1 (10);
select @res
select 1 where @res = $PARTITION.RangePF1 (10);
SELECT @res = $PARTITION.RangePF1 (@res);
select @res
GO

DROP PARTITION FUNCTION RangePF1 
GO

CREATE SEQUENCE CountBy1  
    START WITH 1  
    INCREMENT BY 1 ;
GO

-- NEXT VALUE FOR gets re-written by ANTLR
DECLARE @myvar1 BIGINT = NEXT VALUE FOR CountBy1 ;
DECLARE @myvar2 BIGINT ;  
DECLARE @myvar3 BIGINT ;  
select @myvar2 = NEXT VALUE FOR CountBy1 ;  
SELECT @myvar3 = NEXT VALUE FOR CountBy1 ;  
SELECT @myvar1 AS myvar1, @myvar2 AS myvar2, @myvar3 AS myvar3 ;  
GO

DROP SEQUENCE CountBy1
GO

-- any @@ is also re-written by ANTLR
declare @pid int = 0
select @pid += @@spid
select 1 where @pid = @@spid
go

-- float point notation also gets rewritten by ANTLR e.g., 2.1E, -.2e+, -2.e-
declare @a float = 0
select @a = 2.1E
select @a
select @a = -.2e+
select @a 
select @a = -2.e-
select @a
go

-- variables only in select target list shows dynamic behavior
create table local_var_tst (id int) 
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
insert into local_var_tst values (1)
GO

declare @i int = 1
declare @j int = 0
select @j += id, @i = id + 1  from local_var_tst where id = @i
select @i, @j
go

declare @i int = 1
select @i = id * 2 from local_var_tst where id = @i
select @i
GO


select set_config('babelfishpg_tsql.explain_timing', 'off', false);
GO

select set_config('babelfishpg_tsql.explain_summary', 'off', false);
GO

set babelfish_statistics profile On;
GO

declare @i int = 1
declare @j int = 0
select @j += id, @i = id + 1  from local_var_tst where id = @i
select @i, @j
go

declare @i int = 1
select @i = @i * 2 from local_var_tst where id = @i
select @i
GO

set babelfish_statistics profile OFF
GO

select set_config('babelfishpg_tsql.explain_timing', 'on', false);
GO

select set_config('babelfishpg_tsql.explain_summary', 'on', false);
GO

-- declared variable name with length > 63
declare @abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr int = 1
select @abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr += 1
select @abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr
GO

-- variable names starting with @@
declare @@a int = 1;
select @@a = @@a + 1
select @@a 
GO

declare @@a int = 1;
select @@a += 1
select @@a 
GO

declare @@abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr int = 1
select @@abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr = @@abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr + 1
select @@abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr
GO

truncate table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
insert into local_var_tst values (1)
GO

declare @@abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr int = 1
select @@abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr = @@abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr + id from local_var_tst
select @@abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr
GO

declare @@abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr int = 1
select @@abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr = id + @@abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr from local_var_tst
select @@abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr
GO

declare @@abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr int = 1
select @@abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr += id from local_var_tst
select @@abcbjbnjfbjrnfjrnfkrelnfksnrfenjkfrfrfrfrfrfnknslkrnflkernklfnkmklfr
GO

truncate table local_var_tst
GO

insert into local_var_tst values (1)
GO

select set_config('babelfishpg_tsql.explain_timing', 'off', false);
GO

select set_config('babelfishpg_tsql.explain_summary', 'off', false);
GO

set babelfish_statistics profile On;
GO

-- error while evaluating const expression
declare @a int = 1;
select @a = 1 / 0 from local_var_tst
select * from local_var_tst where id = @a
GO

set babelfish_statistics profile OFF
GO

select set_config('babelfishpg_tsql.explain_timing', 'on', false);
GO

select set_config('babelfishpg_tsql.explain_summary', 'on', false);
GO

drop table local_var_tst
GO
