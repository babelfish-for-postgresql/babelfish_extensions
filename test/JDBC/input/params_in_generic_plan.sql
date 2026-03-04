SELECT set_config('plan_cache_mode', 'force_generic_plan', false);
go

-- test_dynamic_local_vars
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

create table ident_tst(id_num INT IDENTITY(1, 1), b varchar(10))
GO

insert into ident_tst values ('test')
GO

declare @a int = 1
select @a = @@IDENTITY
select @a
select 1 where @a = @@IDENTITY
GO

-- additional testing for update with dynamic variables
GO

create table local_var_tst (id int) 
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO


set QUOTED_IDENTIFIER on
GO

declare @i varchar(100)
update local_var_tst set id = id + 10, @i = cast("xmax" as varchar(100))
select 1 where @i IS NOT NULL
GO

set QUOTED_IDENTIFIER off
GO

select * from local_var_tst order by id;
GO

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

-- long identifier with update
declare @incnjkdncjknxdjnkxnknvjkdfjvbdfbvjbdfhjbvjdbfvkjbdnjnlkanjfnvjnjfdlsahdnuejncdiebnjcnjksndjnjxndjcx int
update local_var_tst set id =10, @incnjkdncjknxdjnkxnknvjkdfjvbdfbvjbdfhjbvjdbfvkjbdnjnlkanjfnvjnjfdlsahdnuejncdiebnjcnjksndjnjxndjcx = id
select @incnjkdncjknxdjnkxnknvjkdfjvbdfbvjbdfhjbvjdbfvkjbdnjnlkanjfnvjnjfdlsahdnuejncdiebnjcnjksndjnjxndjcx
GO

select * from local_var_tst
GO

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

-- @@ variables
declare @@incnjkdnc int
update local_var_tst set id =10, @@incnjkdnc = id
select @@incnjkdnc
GO

select * from local_var_tst
GO

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

declare @i int 
update local_var_tst set id = id + 2, @i = id * 5;
select @i
GO

select * from local_var_tst order by id;
GO

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

declare @i int, @j int;
update local_var_tst set id =10, @i = case when @j =0 then 1 else 0 end;
select @i, @j
go

select * from local_var_tst;
GO

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

declare @i int, @j int;
update local_var_tst set id = 10, @j = id, @i = case when @j =0 then 1 else 0 end;
select @i, @j
go

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

declare @i int, @j int = 0
update local_var_tst set id =10, @i = charindex('a','a',@j)
select @i
GO

select * from local_var_tst;
GO

declare @i int, @j int = 0
update local_var_tst set id =10, @i = charindex('a','a',@j);
select @i
GO

select * from local_var_tst;
GO

declare @i int, @j int;
update local_var_tst set id = 10, @j = id, @i = @j * 2
select @i, @j
go

select * from local_var_tst;
GO

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

declare @i int = 1
update local_var_tst set id = @i, @i = id * 2 where id = @i
select @i
GO

select * from local_var_tst
go

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

declare @i int = 1
update local_var_tst set id = @i, @i += id * 2 where id = @i
select @i
GO

select * from local_var_tst
go

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

declare @i VARCHAR(200) = ''
update local_var_tst set id = id * 2, @i = @i + cast(id as varchar(20))
select @i
GO

select * from local_var_tst order by id
go

-- @i should be NULL as no row passes the qual condition
declare @i int 
update local_var_tst set id =10, @i = id * 5 where id = 1
select @i
GO

select * from local_var_tst order by id
go

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO


declare @i int = 1
update local_var_tst set id = @i, @i = id * 5 where id = @i
select @i
GO

select * from local_var_tst order by id
go

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

declare @i int 
set @i = 0
update local_var_tst set id = @i, @i = id * 5
select @i
GO

select * from local_var_tst;
GO

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

-- trim is re-written by antlr
declare @i varchar(200) 
select @i = ''
update local_var_tst set id = @i, @i = TRIM(@i + cast(id as varchar(10)));
select @i
GO

select * from local_var_tst;
GO

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

-- variables in the where clause should be treated as const

declare @i int = 1;
update local_var_tst set id = @i * 100, @i = id * 2 where id = @i
select @i
GO

select * from local_var_tst order by id;
GO

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

declare @i int = 1;
update local_var_tst set id = @i * 100, @i = @@IDENTITY
select @i
select 1 where @i = @@IDENTITY
GO

select * from local_var_tst
GO

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

CREATE PARTITION FUNCTION RangePF1 ( INT )  
AS RANGE RIGHT FOR VALUES (10, 100, 1000) ;  
GO

declare @i int = -1;
SELECT @i = $PARTITION.RangePF1 (10);
select @i
update local_var_tst set id = @i, @i = $PARTITION.RangePF1 (10);
select @i
GO

select * from local_var_tst;
GO

DROP PARTITION FUNCTION RangePF1 
GO

CREATE PROCEDURE var_with_procedure (@i int, @a numeric(10,4) OUTPUT) AS
BEGIN
  update local_var_tst set id = @i * 2, @a = id * 5 where id = @i
  select @a
END;
GO

TRUNCATE table local_var_tst
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

declare @input int = 1, @res int;
exec var_with_procedure @input, @res
select @res
GO

select * from local_var_tst
go

declare @input int = 2, @a int;
exec var_with_procedure @input, @a
select @a
GO

DROP PROCEDURE var_with_procedure;
GO

DROP TABLE local_var_tst
GO

create table local_var_tst_1 (id int) 
GO

insert into local_var_tst_1 values (1)
insert into local_var_tst_1 values (2)
GO

create unique index idx_local_var_tst_1 on local_var_tst_1(id)
GO


SELECT set_config('enable_indexscan', '1', false);
SELECT set_config('enable_indexonlyscan', '0', false);
SELECT set_config('enable_seqscan', '0', false);
GO

declare @i int = 1
update local_var_tst_1 set id = @i, @i = id * 5 where id = 1
select @i
GO

declare @i int = 1
update local_var_tst_1 set id = 10 output deleted.id where id = 1
select @i
GO

SELECT set_config('enable_indexscan', '1', false);
SELECT set_config('enable_indexonlyscan', '1', false);
SELECT set_config('enable_seqscan', '1', false);
GO

DROP TABLE local_var_tst_1
GO

CREATE TABLE update_test_tbl (
    age int,
    fname char(10),
    lname char(10),
    city nchar(20)
)
GO

TRUNCATE TABLE update_test_tbl
GO

INSERT INTO update_test_tbl(age, fname, lname, city) 
VALUES  (50, 'fname1', 'lname1', 'london'),
        (34, 'fname2', 'lname2', 'paris'),
        (35, 'fname3', 'lname3', 'brussels'),
        (90, 'fname4', 'lname4', 'new york'),
        (26, 'fname5', 'lname5', 'los angeles'),
        (74, 'fname6', 'lname6', 'tokyo'),
        (44, 'fname7', 'lname7', 'oslo'),
        (19, 'fname8', 'lname8', 'hong kong'),
        (61, 'fname9', 'lname9', 'shanghai'),
        (29, 'fname10', 'lname10', 'mumbai')
GO

CREATE TABLE update_test_tbl2 (
    year int,
    lname char(10),
)
GO

TRUNCATE TABLE update_test_tbl2
GO

INSERT INTO update_test_tbl2(year, lname) 
VALUES  (51, 'lname1'),
        (34, 'lname3'),
        (25, 'lname8'),
        (95, 'lname9'),
        (36, 'lname10')
GO

UPDATE update_test_tbl SET fname = 'fname13'
FROM update_test_tbl t1
INNER JOIN update_test_tbl2 t2
ON t1.lname = t2.lname
WHERE year > 50
GO

declare @a varchar(4000) = '';
UPDATE update_test_tbl SET fname = 'fname13', @a = @a + fname
FROM update_test_tbl t1
INNER JOIN update_test_tbl2 t2
ON t1.lname = t2.lname
WHERE year > 50
select @a
GO

DROP TABLE update_test_tbl2;
GO

DROP TABLE update_test_tbl
GO

drop table ident_tst
GO

create table local_var_tst (id int) 
GO

insert into local_var_tst values (1)
insert into local_var_tst values (2)
GO

declare @i int = 0, @j int
update local_var_tst set id = id + 2, @i = id, @j = @i * 2, @i = @j
select @i, @j
GO

declare @i int = 0, @j int
update local_var_tst set id = id + 2, @i += id, @j = @i * 2
select @i, @j
GO

select * from local_var_tst order by id
GO

drop table local_var_tst
GO

-- end of test_dynamic_local_vars


-- Setup test table
create table t1 (a int, b int, c varchar(50));
go

CREATE PROCEDURE reset_t1
AS
BEGIN
    TRUNCATE TABLE t1;
    INSERT INTO t1 VALUES (1, 10, 'first');
    INSERT INTO t1 VALUES (2, 20, 'second');
    INSERT INTO t1 VALUES (3, 30, 'third');
    INSERT INTO t1 VALUES (4, 40, 'fourth');
END
GO

EXEC reset_t1
GO

-- Using local variable without assignment
-- in targetlist
declare @a int;
set @a = 5;
select a, b, @a as param_value from t1 where a < 3;
go

CREATE PROCEDURE proc_targetlist_param @a int
AS
BEGIN
    select a, b, @a as param_value from t1 where a < 3;
END
GO

EXEC proc_targetlist_param @a = 5;
GO

DROP PROCEDURE proc_targetlist_param;
GO

EXEC sp_executesql N'select a, b, @a as param_value from t1 where a < 3', N'@a int', @a = 5;
GO

-- in qual
declare @a int;
set @a = 2;
select * from t1 where a = @a;
go

CREATE PROCEDURE proc_qual_param @a int
AS
BEGIN
    select * from t1 where a = @a;
END
GO

EXEC proc_qual_param @a = 2;
GO

DROP PROCEDURE proc_qual_param;
GO

EXEC sp_executesql N'select * from t1 where a = @a', N'@a int', @a = 2;
GO

declare @filter int;
set @filter = 1;
update t1 set b = 5942 where a = @filter;
select * from t1 where a = @filter;
go

CREATE PROCEDURE proc_update_filter @filter int
AS
BEGIN
    update t1 set b = 5942 where a = @filter;
    select * from t1 where a = @filter;
END
GO

EXEC reset_t1;
GO
EXEC proc_update_filter @filter = 1;
GO

DROP PROCEDURE proc_update_filter;
GO

EXEC reset_t1;
GO

EXEC sp_executesql N'update t1 set b = 5942 where a = @filter; select * from t1 where a = @filter', N'@filter int', @filter = 1;
GO

EXEC reset_t1
GO

create table t_temp (a int);
insert into t_temp values (1), (2), (3), (4);
declare @del_val int;
set @del_val = 2;
delete from t_temp where a = @del_val;
select * from t_temp order by a;
drop table t_temp;
go

-- both
declare @update_val int, @filter int;
set @update_val = 100;
set @filter = 1;
update t1 set b = @update_val where a = @filter;
select * from t1 where a = @filter;
go

EXEC reset_t1
GO

declare @filter int;
set @filter = 1;
update t1 set b = @filter where a = @filter;
select * from t1 where a = @filter;
go

EXEC reset_t1
GO

-- top(NULL) from BABEL-1181
-- Local variable in TOP clause
declare @a int;
set @a = 2;
select top (@a) * from t1 order by a;
go

declare @a int;
set @a = 2;
select top (NULL) * from t1 order by a;
go

-- TOP with NULL local variable (should error)
declare @top_null int;
set @top_null = NULL;
select top (@top_null) * from t1;
go

-- TOP with local variable from subquery
declare @top_val int;
set @top_val = (select 2);
select top (@top_val) * from t1 order by a;
go

declare @top_val int;
declare @fetch_val int;
set @top_val = (select @fetch_val);
select top (@top_val) * from t1 order by a;
go

-- Local variable assignment
-- in targetlist
declare @result int;
select @result = b from t1 where a = 2;
select @result;
go

-- Local variable assignment with parameter in target list and WHERE
declare @i int, @result int;
set @i = 2;
select @result = b from t1 where a = @i;
select @result;
go

declare @i int, @result int;
set @i = 2;
select @result = b + @i from t1 where a = @i;
select @result;
go

-- Multiple local variable assignments
declare @var1 int, @var2 int, @param int;
set @param = 2;
select @var1 = a, @var2 = b from t1 where a = @param;
select @var1, @var2;
go

-- Local variable assignment over multiple rows
declare @result int, @threshold int;
set @threshold = 2;
select @result = sum(b) from t1 where a > @threshold;
select @result;
go

-- Local variable in GROUP BY HAVING clause
-- TODO: make tables with proper groups for this
declare @having_val int;
set @having_val = 15;
select a, sum(b) as total from t1 group by a having sum(b) > @having_val order by a;
go

create table group_table_t1 (a int, b int, c varchar(50));
insert into group_table_t1 values (1, 3, '1abbcc');
insert into group_table_t1 values (1, 4, 'a2bbcc');
insert into group_table_t1 values (2, 5, 'aa3bcc');
insert into group_table_t1 values (2, 6, 'aab4cc');
insert into group_table_t1 values (3, 50000, 'aabb5c');
insert into group_table_t1 values (3, 60000, 'aabbc6');
declare @having_val int;
set @having_val = 3;
select a, sum(b) as total from group_table_t1 group by a having sum(b) > @having_val order by a;
go
declare @having_val int;
set @having_val = 3;
select @having_val = @having_val + 1234 from group_table_t1 group by b having sum(b) > @having_val;
select @having_val
go

drop table group_table_t1;
go

declare @having_val int;
set @having_val = 15;
select @having_val = @having_val + 1 from t1 group by a having sum(b) > @having_val;
select @having_val
go

-- in CASE expression
declare @threshold int;
set @threshold = 2;
select a, case when a > @threshold then 'high' else 'low' end as category from t1;
go

-- local variable assignment in CASE with local variable assignment
declare @threshold int, @result varchar(10);
set @threshold = 2;
select @result = case when a > @threshold then 'high' else 'low' end from t1 order by a;
select @result;
go

declare @threshold int, @result varchar(10), @at int;
set @threshold = 2;
set @at = 3;
select @result = case when a > @threshold then 'high' else 'low' end from t1 where a = @at;
select @result;
go

-- Local variable with string operations
declare @search varchar(10);
set @search = 'sec';
select * from t1 where c like '%' + @search + '%';
go

declare @search varchar(10);
set @search = 'i';
select @search = @search + 'rd' from t1 where c like '%' + @search + '%';
select @search;
go

declare @result varchar(100), @prefix varchar(10);
set @prefix = 'Value: ';
select @result = @prefix + c from t1 order by a;
select @result;
go

declare @multiplier int;
set @multiplier = 2;
select a, (select @multiplier * b) as doubled_b from t1 where a < 3;
go

declare @multiplier int;
set @multiplier = 2;
select a, (select @multiplier = @multiplier * b) from t1 where a < 3;
go

declare @val int;
set @val = 10;
select a, (select b + (select @val)) as nested_calc from t1 where a < 3;
go

declare @val int;
set @val = 2;
select * from t1 where b > (select max(b) from t1 where a < @val);
go

declare @val int;
set @val = 2;
select * from t1 where (select @val = @val + 1);
go

declare @offset int;
set @offset = 10;
select a, (select count(*) from t1 t_inner where t_inner.b > t_outer.b + @offset) as count_greater from t1 t_outer;
go

declare @null_param int;
set @null_param = NULL;
select * from t1 where a = @null_param;
go

-- Local variable in CTE
declare @cte_filter int;
set @cte_filter = 2;
with cte as (select * from t1 where a > @cte_filter)
select * from cte;
go

declare @cte_filter int;
set @cte_filter = 1;
with cte as (select * from t1 where a > @cte_filter)
select @cte_filter = @cte_filter + 3 from cte;
select @cte_filter;
go

declare @filter1 int, @filter2 int;
set @filter1 = 1;
set @filter2 = 3;
with cte1 as (select * from t1 where a > @filter1),
     cte2 as (select * from cte1 where a <= @filter2)
select * from cte2;
go

declare @filter1 int, @filter2 int;
set @filter1 = 1;
with cte1 as (select * from t1 where a > @filter1),
     cte2 as (select @filter1 = @filter1 + 3 from cte1)
select * from cte2;
go

declare @partition_val int;
set @partition_val = 2;
select a, b, row_number() over (order by case when a > @partition_val then a else b end) as rn from t1;
go

declare @partition_val int;
set @partition_val = 2;
select @partition_val = @partition_val + 1, row_number() over (order by case when a > @partition_val then a else b end) as rn from t1;
go

EXEC reset_t1
GO

-- Local variable assignment in UPDATE
-- returned values for the `captured` variables _will_ differ from sql server (BABEL-5188)
declare @captured int, @filter int;
set @filter = 2;
update t1 set b = b + 5, @captured = b where a = @filter;
select @captured;
go

EXEC reset_t1
GO

-- Multiple local variable assignments in UPDATE
declare @captured1 int, @captured2 int, @filter int, @increment int;
set @filter = 2;
set @increment = 5;
update t1 set b = b + @increment, @captured1 = a, @captured2 = @captured1 + b where a = @filter;
select @captured1, @captured2;
go

EXEC reset_t1
GO

-- UPDATE with local variable in subquery
declare @multiplier int;
set @multiplier = 2;
update t1 set b = (select @multiplier * 10) where a = 1;
select * from t1 where a = 1;
go

EXEC reset_t1
GO

-- DELETE with local variable in subquery
create table t_temp (a int);
insert into t_temp values (1), (2), (3), (4);
declare @threshold int;
set @threshold = 2;
delete from t_temp where a in (select a from t_temp where a <= @threshold);
select * from t_temp order by a;
drop table t_temp;
go

-- local variable in INSERT VALUES
declare @val1 int, @val2 int;
set @val1 = 5;
set @val2 = 50;
create table t_temp (a int, b int);
insert into t_temp values (@val1, @val2);
select * from t_temp;
set @val1 = 51;
set @val2 = 501;
insert into t_temp values (@val1, @val2);
select * from t_temp;
drop table t_temp;
go

-- local variable in OFFSET FETCH
declare @offset_val int, @fetch_val int;
set @offset_val = 1;
set @fetch_val = 2;
select * from t1 order by a offset @offset_val rows fetch next @fetch_val rows only;
go

declare @offset_val int, @fetch_val int;
set @offset_val = 1;
set @fetch_val = NULL;
select * from t1 order by a offset @offset_val rows fetch next @fetch_val rows only;
go

-- OFFSET NULL should error (BABEL-6347)
declare @offset_val int, @fetch_val int;
set @offset_val = NULL;
set @fetch_val = 2;
select * from t1 order by a offset @offset_val rows fetch next @fetch_val rows only;
go

declare @offset_val int, @fetch_val int;
set @fetch_val = 2;
select * from t1 order by a offset NULL rows fetch next @fetch_val rows only;
go

declare @offset_val int, @fetch_val int;
set @offset_val = 1;
set @fetch_val = 2;
select a, @fetch_val = NULL from t1 order by a offset @offset_val rows fetch next @fetch_val rows only;
go

declare @offset_val int, @fetch_val int;
set @offset_val = 1;
set @fetch_val = 2;
select a, @offset_val = NULL from t1 order by a offset @offset_val rows fetch next @fetch_val rows only;
go

-- Additional procedure and planned statement versions

-- Ref: delete with local variable
CREATE PROCEDURE proc_delete_param @del_val int
AS
BEGIN
    create table t_temp (a int);
    insert into t_temp values (1), (2), (3), (4);
    delete from t_temp where a = @del_val;
    select * from t_temp order by a;
    drop table t_temp;
END
GO

EXEC proc_delete_param @del_val = 2;
GO

DROP PROCEDURE proc_delete_param;
GO

EXEC sp_executesql N'create table t_temp (a int); insert into t_temp values (1), (2), (3), (4); delete from t_temp where a = @del_val; select * from t_temp order by a; drop table t_temp', N'@del_val int', @del_val = 2;
GO

-- Ref: update with both local variables
CREATE PROCEDURE proc_update_both @update_val int, @filter int
AS
BEGIN
    update t1 set b = @update_val where a = @filter;
    select * from t1 where a = @filter;
END
GO

EXEC proc_update_both @update_val = 100, @filter = 1;
GO

DROP PROCEDURE proc_update_both;
GO

EXEC sp_executesql N'update t1 set b = @update_val where a = @filter; select * from t1 where a = @filter', N'@update_val int, @filter int', @update_val = 100, @filter = 1;
GO

TRUNCATE TABLE t1;
insert into t1 values (1, 10, 'first'), (2, 20, 'second'), (3, 30, 'third'), (4, 40, 'fourth');
GO

-- Ref: update with same variable in both places
CREATE PROCEDURE proc_update_same @filter int
AS
BEGIN
    update t1 set b = @filter where a = @filter;
    select * from t1 where a = @filter;
END
GO

EXEC proc_update_same @filter = 1;
GO

DROP PROCEDURE proc_update_same;
GO

EXEC sp_executesql N'update t1 set b = @filter where a = @filter; select * from t1 where a = @filter', N'@filter int', @filter = 1;
GO

EXEC reset_t1
GO

-- Ref: TOP with local variable
CREATE PROCEDURE proc_top_param @a int
AS
BEGIN
    select top (@a) * from t1 order by a;
END
GO

EXEC proc_top_param @a = 2;
GO

DROP PROCEDURE proc_top_param;
GO

EXEC sp_executesql N'select top (@a) * from t1 order by a', N'@a int', @a = 2;
GO

-- Ref: TOP with NULL local variable
CREATE PROCEDURE proc_top_null @top_null int
AS
BEGIN
    select top (@top_null) * from t1;
END
GO

EXEC proc_top_null @top_null = NULL;
GO

DROP PROCEDURE proc_top_null;
GO

EXEC sp_executesql N'select top (@top_null) * from t1', N'@top_null int', @top_null = NULL;
GO

-- Ref: TOP with local variable from subquery
CREATE PROCEDURE proc_top_subquery
AS
BEGIN
    select top (select NULL) * from t1 order by a;
END
GO

EXEC proc_top_subquery;
GO

DROP PROCEDURE proc_top_subquery;
GO

EXEC sp_executesql N'select top (select NULL) * from t1 order by a';
GO

-- Ref: local variable assignment in targetlist
CREATE PROCEDURE proc_assign_targetlist @i int, @result int OUTPUT
AS
BEGIN
    select @result = b from t1 where a = @i;
END
GO

declare @out int;
EXEC proc_assign_targetlist @i = 2, @result = @out OUTPUT;
select @out;
GO

DROP PROCEDURE proc_assign_targetlist;
GO

declare @result int;
EXEC sp_executesql N'select @result = b from t1 where a = @i', N'@i int, @result int OUTPUT', @i = 2, @result = @result OUTPUT;
select @result;
GO

-- Ref: local variable assignment with parameter in target and WHERE
CREATE PROCEDURE proc_assign_both @i int, @result int OUTPUT
AS
BEGIN
    select @result = b + @i from t1 where a = @i;
END
GO

declare @out int;
EXEC proc_assign_both @i = 2, @result = @out OUTPUT;
select @out;
GO

DROP PROCEDURE proc_assign_both;
GO

declare @result int;
EXEC sp_executesql N'select @result = b + @i from t1 where a = @i', N'@i int, @result int OUTPUT', @i = 2, @result = @result OUTPUT;
select @result;
GO

-- Ref: multiple local variable assignments
CREATE PROCEDURE proc_assign_multiple @param int, @var1 int OUTPUT, @var2 int OUTPUT
AS
BEGIN
    select @var1 = a, @var2 = b from t1 where a = @param;
END
GO

declare @out1 int, @out2 int;
EXEC proc_assign_multiple @param = 2, @var1 = @out1 OUTPUT, @var2 = @out2 OUTPUT;
select @out1, @out2;
GO

DROP PROCEDURE proc_assign_multiple;
GO

declare @var1 int, @var2 int;
EXEC sp_executesql N'select @var1 = a, @var2 = b from t1 where a = @param', N'@param int, @var1 int OUTPUT, @var2 int OUTPUT', @param = 2, @var1 = @var1 OUTPUT, @var2 = @var2 OUTPUT;
select @var1, @var2;
GO

-- Ref: local variable assignment over multiple rows
CREATE PROCEDURE proc_assign_aggregate @threshold int, @result int OUTPUT
AS
BEGIN
    select @result = sum(b) from t1 where a > @threshold;
END
GO

declare @out int;
EXEC proc_assign_aggregate @threshold = 2, @result = @out OUTPUT;
select @out;
GO

DROP PROCEDURE proc_assign_aggregate;
GO

declare @result int;
EXEC sp_executesql N'select @result = sum(b) from t1 where a > @threshold', N'@threshold int, @result int OUTPUT', @threshold = 2, @result = @result OUTPUT;
select @result;
GO

-- Ref: local variable in GROUP BY HAVING
CREATE PROCEDURE proc_having_param @having_val int
AS
BEGIN
    select a, sum(b) as total from t1 group by a having sum(b) > @having_val order by a;
END
GO

EXEC proc_having_param @having_val = 15;
GO

DROP PROCEDURE proc_having_param;
GO

EXEC sp_executesql N'select a, sum(b) as total from t1 group by a having sum(b) > @having_val order by a', N'@having_val int', @having_val = 15;
GO

-- Ref: CASE expression with local variable
CREATE PROCEDURE proc_case_param @threshold int
AS
BEGIN
    select a, case when a > @threshold then 'high' else 'low' end as category from t1;
END
GO

EXEC proc_case_param @threshold = 2;
GO

DROP PROCEDURE proc_case_param;
GO

EXEC sp_executesql N'select a, case when a > @threshold then ''high'' else ''low'' end as category from t1', N'@threshold int', @threshold = 2;
GO

-- Ref: local variable assignment in CASE
CREATE PROCEDURE proc_case_assign @threshold int, @at int, @result varchar(10) OUTPUT
AS
BEGIN
    select @result = case when a > @threshold then 'high' else 'low' end from t1 where a = @at;
END
GO

declare @out varchar(10);
EXEC proc_case_assign @threshold = 2, @at = 3, @result = @out OUTPUT;
select @out;
GO

DROP PROCEDURE proc_case_assign;
GO

declare @result varchar(10);
EXEC sp_executesql N'select @result = case when a > @threshold then ''high'' else ''low'' end from t1 where a = @at', N'@threshold int, @at int, @result varchar(10) OUTPUT', @threshold = 2, @at = 3, @result = @result OUTPUT;
select @result;
GO

-- Ref: local variable with string operations
CREATE PROCEDURE proc_string_like @search varchar(10)
AS
BEGIN
    select * from t1 where c like '%' + @search + '%';
END
GO

EXEC proc_string_like @search = 'sec';
GO

DROP PROCEDURE proc_string_like;
GO

EXEC sp_executesql N'select * from t1 where c like ''%'' + @search + ''%''', N'@search varchar(10)', @search = 'sec';
GO

-- Ref: string concatenation with assignment
CREATE PROCEDURE proc_string_concat @prefix varchar(10), @result varchar(100) OUTPUT
AS
BEGIN
    select @result = @prefix + c from t1 order by a;
END
GO

declare @out varchar(100);
EXEC proc_string_concat @prefix = 'Value: ', @result = @out OUTPUT;
select @out;
GO

DROP PROCEDURE proc_string_concat;
GO

declare @result varchar(100);
EXEC sp_executesql N'select @result = @prefix + c from t1 order by a', N'@prefix varchar(10), @result varchar(100) OUTPUT', @prefix = 'Value: ', @result = @result OUTPUT;
select @result;
GO

-- Ref: subquery with local variable
CREATE PROCEDURE proc_subquery_param @multiplier int
AS
BEGIN
    select a, (select @multiplier * b) as doubled_b from t1 where a < 3;
END
GO

EXEC proc_subquery_param @multiplier = 2;
GO

DROP PROCEDURE proc_subquery_param;
GO

EXEC sp_executesql N'select a, (select @multiplier * b) as doubled_b from t1 where a < 3', N'@multiplier int', @multiplier = 2;
GO

-- Ref: nested subquery with local variable
CREATE PROCEDURE proc_nested_subquery @val int
AS
BEGIN
    select a, (select b + (select @val)) as nested_calc from t1 where a < 3;
END
GO

EXEC proc_nested_subquery @val = 10;
GO

DROP PROCEDURE proc_nested_subquery;
GO

EXEC sp_executesql N'select a, (select b + (select @val)) as nested_calc from t1 where a < 3', N'@val int', @val = 10;
GO

-- Ref: subquery in WHERE with local variable
CREATE PROCEDURE proc_where_subquery @val int
AS
BEGIN
    select * from t1 where b > (select max(b) from t1 where a < @val);
END
GO

EXEC proc_where_subquery @val = 2;
GO

DROP PROCEDURE proc_where_subquery;
GO

EXEC sp_executesql N'select * from t1 where b > (select max(b) from t1 where a < @val)', N'@val int', @val = 2;
GO

-- Ref: correlated subquery with local variable
CREATE PROCEDURE proc_correlated_subquery @offset int
AS
BEGIN
    select a, (select count(*) from t1 t_inner where t_inner.b > t_outer.b + @offset) as count_greater from t1 t_outer;
END
GO

EXEC proc_correlated_subquery @offset = 10;
GO

DROP PROCEDURE proc_correlated_subquery;
GO

EXEC sp_executesql N'select a, (select count(*) from t1 t_inner where t_inner.b > t_outer.b + @offset) as count_greater from t1 t_outer', N'@offset int', @offset = 10;
GO

-- Ref: NULL parameter
CREATE PROCEDURE proc_null_param @null_param int
AS
BEGIN
    select * from t1 where a = @null_param;
END
GO

EXEC proc_null_param @null_param = NULL;
GO

DROP PROCEDURE proc_null_param;
GO

EXEC sp_executesql N'select * from t1 where a = @null_param', N'@null_param int', @null_param = NULL;
GO

-- Ref: CTE with local variable
CREATE PROCEDURE proc_cte_param @cte_filter int
AS
BEGIN
    with cte as (select * from t1 where a > @cte_filter)
    select * from cte;
END
GO

EXEC proc_cte_param @cte_filter = 2;
GO

DROP PROCEDURE proc_cte_param;
GO

EXEC sp_executesql N'with cte as (select * from t1 where a > @cte_filter) select * from cte', N'@cte_filter int', @cte_filter = 2;
GO

-- Ref: multiple CTEs with local variables
CREATE PROCEDURE proc_multiple_cte @filter1 int, @filter2 int
AS
BEGIN
    with cte1 as (select * from t1 where a > @filter1),
         cte2 as (select * from cte1 where a <= @filter2)
    select * from cte2;
END
GO

EXEC proc_multiple_cte @filter1 = 1, @filter2 = 3;
GO

DROP PROCEDURE proc_multiple_cte;
GO

EXEC sp_executesql N'with cte1 as (select * from t1 where a > @filter1), cte2 as (select * from cte1 where a <= @filter2) select * from cte2', N'@filter1 int, @filter2 int', @filter1 = 1, @filter2 = 3;
GO

-- Ref: window function with local variable
CREATE PROCEDURE proc_window_param @partition_val int
AS
BEGIN
    select a, b, row_number() over (order by case when a > @partition_val then a else b end) as rn from t1;
END
GO

EXEC proc_window_param @partition_val = 2;
GO

DROP PROCEDURE proc_window_param;
GO

EXEC sp_executesql N'select a, b, row_number() over (order by case when a > @partition_val then a else b end) as rn from t1', N'@partition_val int', @partition_val = 2;
GO

-- Ref: UPDATE with local variable assignment
CREATE PROCEDURE proc_update_assign @filter int, @captured int OUTPUT
AS
BEGIN
    update t1 set b = b + 5, @captured = b where a = @filter;
END
GO

TRUNCATE TABLE t1;
insert into t1 values (1, 10, 'first'), (2, 20, 'second'), (3, 30, 'third'), (4, 40, 'fourth');
GO

declare @out int;
EXEC proc_update_assign @filter = 2, @captured = @out OUTPUT;
select @out;
GO

DROP PROCEDURE proc_update_assign;
GO

TRUNCATE TABLE t1;
insert into t1 values (1, 10, 'first'), (2, 20, 'second'), (3, 30, 'third'), (4, 40, 'fourth');
GO

declare @captured int;
EXEC sp_executesql N'update t1 set b = b + 5, @captured = b where a = @filter', N'@filter int, @captured int OUTPUT', @filter = 2, @captured = @captured OUTPUT;
select @captured;
GO

TRUNCATE TABLE t1;
insert into t1 values (1, 10, 'first'), (2, 20, 'second'), (3, 30, 'third'), (4, 40, 'fourth');
GO

-- Ref: UPDATE with multiple assignments
CREATE PROCEDURE proc_update_multi_assign @filter int, @increment int, @captured1 int OUTPUT, @captured2 int OUTPUT
AS
BEGIN
    update t1 set b = b + @increment, @captured1 = a, @captured2 = @captured1 + b where a = @filter;
END
GO

declare @out1 int, @out2 int;
EXEC proc_update_multi_assign @filter = 2, @increment = 5, @captured1 = @out1 OUTPUT, @captured2 = @out2 OUTPUT;
select @out1, @out2;
GO

DROP PROCEDURE proc_update_multi_assign;
GO

TRUNCATE TABLE t1;
insert into t1 values (1, 10, 'first'), (2, 20, 'second'), (3, 30, 'third'), (4, 40, 'fourth');
GO

declare @captured1 int, @captured2 int;
EXEC sp_executesql N'update t1 set b = b + @increment, @captured1 = a, @captured2 = @captured1 + b where a = @filter', N'@filter int, @increment int, @captured1 int OUTPUT, @captured2 int OUTPUT', @filter = 2, @increment = 5, @captured1 = @captured1 OUTPUT, @captured2 = @captured2 OUTPUT;
select @captured1, @captured2;
GO

TRUNCATE TABLE t1;
insert into t1 values (1, 10, 'first'), (2, 20, 'second'), (3, 30, 'third'), (4, 40, 'fourth');
GO

-- Ref: UPDATE with subquery
CREATE PROCEDURE proc_update_subquery @multiplier int
AS
BEGIN
    update t1 set b = (select @multiplier * 10) where a = 1;
    select * from t1 where a = 1;
END
GO

EXEC proc_update_subquery @multiplier = 2;
GO

DROP PROCEDURE proc_update_subquery;
GO

TRUNCATE TABLE t1;
insert into t1 values (1, 10, 'first'), (2, 20, 'second'), (3, 30, 'third'), (4, 40, 'fourth');
GO

EXEC sp_executesql N'update t1 set b = (select @multiplier * 10) where a = 1; select * from t1 where a = 1', N'@multiplier int', @multiplier = 2;
GO

TRUNCATE TABLE t1;
insert into t1 values (1, 10, 'first'), (2, 20, 'second'), (3, 30, 'third'), (4, 40, 'fourth');
GO

-- Ref: DELETE with subquery
CREATE PROCEDURE proc_delete_subquery @threshold int
AS
BEGIN
    create table t_temp (a int);
    insert into t_temp values (1), (2), (3), (4);
    delete from t_temp where a in (select a from t_temp where a <= @threshold);
    select * from t_temp order by a;
    drop table t_temp;
END
GO

EXEC proc_delete_subquery @threshold = 2;
GO

DROP PROCEDURE proc_delete_subquery;
GO

EXEC sp_executesql N'create table t_temp (a int); insert into t_temp values (1), (2), (3), (4); delete from t_temp where a in (select a from t_temp where a <= @threshold); select * from t_temp order by a; drop table t_temp', N'@threshold int', @threshold = 2;
GO

-- Ref: INSERT with local variables
CREATE PROCEDURE proc_insert_params @val1 int, @val2 int
AS
BEGIN
    create table t_temp (a int, b int);
    insert into t_temp values (@val1, @val2);
    select * from t_temp;
    drop table t_temp;
END
GO

EXEC proc_insert_params @val1 = 5, @val2 = 50;
GO

DROP PROCEDURE proc_insert_params;
GO

EXEC sp_executesql N'create table t_temp (a int, b int); insert into t_temp values (@val1, @val2); select * from t_temp; drop table t_temp', N'@val1 int, @val2 int', @val1 = 5, @val2 = 50;
GO

-- Ref: OFFSET FETCH with local variables
CREATE PROCEDURE proc_offset_fetch @offset_val int, @fetch_val int
AS
BEGIN
    select * from t1 order by a offset @offset_val rows fetch next @fetch_val rows only;
END
GO

EXEC proc_offset_fetch @offset_val = 1, @fetch_val = 2;
GO

DROP PROCEDURE proc_offset_fetch;
GO

EXEC sp_executesql N'select * from t1 order by a offset @offset_val rows fetch next @fetch_val rows only', N'@offset_val int, @fetch_val int', @offset_val = 1, @fetch_val = 2;
GO

-- Ref: OFFSET FETCH with NULL fetch
CREATE PROCEDURE proc_offset_null_fetch @offset_val int, @fetch_val int
AS
BEGIN
    select * from t1 order by a offset @offset_val rows fetch next @fetch_val rows only;
END
GO

EXEC proc_offset_null_fetch @offset_val = 1, @fetch_val = NULL;
GO

DROP PROCEDURE proc_offset_null_fetch;
GO

EXEC sp_executesql N'select * from t1 order by a offset @offset_val rows fetch next @fetch_val rows only', N'@offset_val int, @fetch_val int', @offset_val = 1, @fetch_val = NULL;
GO

EXEC reset_t1
GO

-- Ref: targetlist param
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@a int', N'select a, b, @a as param_value from t1 where a < 3', @a = 5;
GO

-- Ref: qual param
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@a int', N'select * from t1 where a = @a', @a = 2;
GO

-- Ref: update filter
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@filter int', N'update t1 set b = 5942 where a = @filter; select * from t1 where a = @filter', @filter = 1;
GO

EXEC reset_t1;
GO

-- Ref: delete with local variable
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@del_val int', N'create table t_temp (a int); insert into t_temp values (1), (2), (3), (4); delete from t_temp where a = @del_val; select * from t_temp order by a; drop table t_temp', @del_val = 2;
GO

-- Ref: update with both local variables
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@update_val int, @filter int', N'update t1 set b = @update_val where a = @filter; select * from t1 where a = @filter', @update_val = 100, @filter = 1;
GO

TRUNCATE TABLE t1;
insert into t1 values (1, 10, 'first'), (2, 20, 'second'), (3, 30, 'third'), (4, 40, 'fourth');
GO

-- Ref: update with same variable in both places
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@filter int', N'update t1 set b = @filter where a = @filter; select * from t1 where a = @filter', @filter = 1;
GO

EXEC reset_t1
GO

-- Ref: TOP with local variable
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@a int', N'select top (@a) * from t1 order by a', @a = 2;
GO

-- Ref: TOP with NULL local variable
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@top_null int', N'select top (@top_null) * from t1', @top_null = NULL;
GO

-- Ref: local variable assignment in targetlist
declare @result int;
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@i int, @result int OUTPUT', N'select @result = b from t1 where a = @i', @i = 2, @result = @result OUTPUT;
select @result;
GO

-- Ref: local variable assignment with parameter in target and WHERE
declare @result int;
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@i int, @result int OUTPUT', N'select @result = b + @i from t1 where a = @i', @i = 2, @result = @result OUTPUT;
select @result;
GO

-- Ref: multiple local variable assignments
declare @var1 int, @var2 int;
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@param int, @var1 int OUTPUT, @var2 int OUTPUT', N'select @var1 = a, @var2 = b from t1 where a = @param', @param = 2, @var1 = @var1 OUTPUT, @var2 = @var2 OUTPUT;
select @var1, @var2;
GO

-- Ref: local variable assignment over multiple rows
declare @result int;
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@threshold int, @result int OUTPUT', N'select @result = sum(b) from t1 where a > @threshold', @threshold = 2, @result = @result OUTPUT;
select @result;
GO

-- Ref: local variable in GROUP BY HAVING
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@having_val int', N'select a, sum(b) as total from t1 group by a having sum(b) > @having_val order by a', @having_val = 15;
GO

-- Ref: CASE expression with local variable
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@threshold int', N'select a, case when a > @threshold then ''high'' else ''low'' end as category from t1', @threshold = 2;
GO

-- Ref: local variable assignment in CASE
declare @result varchar(10);
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@threshold int, @at int, @result varchar(10) OUTPUT', N'select @result = case when a > @threshold then ''high'' else ''low'' end from t1 where a = @at', @threshold = 2, @at = 3, @result = @result OUTPUT;
select @result;
GO

-- Ref: local variable with string operations
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@search varchar(10)', N'select * from t1 where c like ''%'' + @search + ''%''', @search = 'sec';
GO

-- Ref: string concatenation with assignment
declare @result varchar(100);
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@prefix varchar(10), @result varchar(100) OUTPUT', N'select @result = @prefix + c from t1 order by a', @prefix = 'Value: ', @result = @result OUTPUT;
select @result;
GO

-- Ref: subquery with local variable
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@multiplier int', N'select a, (select @multiplier * b) as doubled_b from t1 where a < 3', @multiplier = 2;
GO

-- Ref: nested subquery with local variable
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@val int', N'select a, (select b + (select @val)) as nested_calc from t1 where a < 3', @val = 10;
GO

-- Ref: subquery in WHERE with local variable
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@val int', N'select * from t1 where b > (select max(b) from t1 where a < @val)', @val = 2;
GO

-- Ref: correlated subquery with local variable
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@offset int', N'select a, (select count(*) from t1 t_inner where t_inner.b > t_outer.b + @offset) as count_greater from t1 t_outer', @offset = 10;
GO

-- Ref: NULL parameter
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@null_param int', N'select * from t1 where a = @null_param', @null_param = NULL;
GO

-- Ref: CTE with local variable
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@cte_filter int', N'with cte as (select * from t1 where a > @cte_filter) select * from cte', @cte_filter = 2;
GO

-- Ref: multiple CTEs with local variables
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@filter1 int, @filter2 int', N'with cte1 as (select * from t1 where a > @filter1), cte2 as (select * from cte1 where a <= @filter2) select * from cte2', @filter1 = 1, @filter2 = 3;
GO

-- Ref: window function with local variable
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@partition_val int', N'select a, b, row_number() over (order by case when a > @partition_val then a else b end) as rn from t1', @partition_val = 2;
GO

-- Ref: UPDATE with local variable assignment
TRUNCATE TABLE t1;
insert into t1 values (1, 10, 'first'), (2, 20, 'second'), (3, 30, 'third'), (4, 40, 'fourth');
GO

declare @captured int;
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@filter int, @captured int OUTPUT', N'update t1 set b = b + 5, @captured = b where a = @filter', @filter = 2, @captured = @captured OUTPUT;
select @captured;
GO

TRUNCATE TABLE t1;
insert into t1 values (1, 10, 'first'), (2, 20, 'second'), (3, 30, 'third'), (4, 40, 'fourth');
GO

-- Ref: UPDATE with multiple assignments
declare @captured1 int, @captured2 int;
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@filter int, @increment int, @captured1 int OUTPUT, @captured2 int OUTPUT', N'update t1 set b = b + @increment, @captured1 = a, @captured2 = @captured1 + b where a = @filter', @filter = 2, @increment = 5, @captured1 = @captured1 OUTPUT, @captured2 = @captured2 OUTPUT;
select @captured1, @captured2;
GO

TRUNCATE TABLE t1;
insert into t1 values (1, 10, 'first'), (2, 20, 'second'), (3, 30, 'third'), (4, 40, 'fourth');
GO

-- Ref: UPDATE with subquery
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@multiplier int', N'update t1 set b = (select @multiplier * 10) where a = 1; select * from t1 where a = 1', @multiplier = 2;
GO

TRUNCATE TABLE t1;
insert into t1 values (1, 10, 'first'), (2, 20, 'second'), (3, 30, 'third'), (4, 40, 'fourth');
GO

-- Ref: DELETE with subquery
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@threshold int', N'create table t_temp (a int); insert into t_temp values (1), (2), (3), (4); delete from t_temp where a in (select a from t_temp where a <= @threshold); select * from t_temp order by a; drop table t_temp', @threshold = 2;
GO

-- Ref: INSERT with local variables
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@val1 int, @val2 int', N'create table t_temp (a int, b int); insert into t_temp values (@val1, @val2); select * from t_temp; drop table t_temp', @val1 = 5, @val2 = 50;
GO

-- Ref: OFFSET FETCH with local variables
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@offset_val int, @fetch_val int', N'select * from t1 order by a offset @offset_val rows fetch next @fetch_val rows only', @offset_val = 1, @fetch_val = 2;
GO

-- Ref: OFFSET FETCH with NULL fetch
declare @handle as int;
EXEC sp_prepexec @handle OUTPUT, N'@offset_val int, @fetch_val int', N'select * from t1 order by a offset @offset_val rows fetch next @fetch_val rows only', @offset_val = 1, @fetch_val = NULL;
GO

-- cleanup

drop procedure reset_t1;
go

drop table t1;
go
