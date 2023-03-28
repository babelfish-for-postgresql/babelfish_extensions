-- table type is only supported in tsql dialect
CREATE TYPE tableType AS table(
	a text not null,
	b int primary key,
	c int);

-- a table with the same name is created
select * from tableType;
GO

-- dropping the table should fail, as it depends on the table type
DROP TABLE tableType;
GO

-- dropping the table type should drop the table as well
DROP TYPE tableType;
GO

-- creating index (other than primary and unique keys) during table type creation is not
-- yet supported
-- TODO: BABEL-688: fully support TSQL CREATE TABLE syntax
CREATE TYPE tableType AS table(
    a text not null,
    b int primary key,
    c int,
    d int index idx1 nonclustered,
    index idx2(c),
	index idx3(e),
	e varchar);
GO


-- not allowed to have more than one dotted prefix
CREATE TYPE postgres.public.tableType AS table(a int, b int);
GO

CREATE TYPE tableType AS table(
	a text not null,
	b int primary key,
	c int);
GO

-- test declaring variables with table type
create procedure table_var_procedure as
begin
	declare @a int;
	declare @b tableType;
	insert into @b values('hello', 4, 100);
	select count(*) from @b;
end;
GO
EXEC table_var_procedure;
GO
DROP PROCEDURE table_var_procedure;
GO

-- test declaring table variable without table type, and doing DMLs
create procedure table_var_procedure as
begin
	declare @tableVar table (a int, b int);
	insert into @tableVar values(1, 100);
	insert into @tableVar values(2, 200);
	update @tableVar set b = 1000 where a = 1;
	delete from @tableVar where a = 2;
	select * from @tableVar;
end;
GO
EXEC table_var_procedure;
GO
DROP PROCEDURE table_var_procedure;
GO

-- test declaring table variable with whitespace before column definition
create procedure table_var_procedure as
begin
	declare @tableVar1 table
	(a int, b int);
	insert into @tableVar1 values(1, 100);
	declare @tableVar2 table 	(c int, d varchar);
	insert into @tableVar2 values(1, 'a');
	select * from @tableVar1 t1 join @tableVar2 t2 on t1.a = t2.c;
end;
GO
EXEC table_var_procedure;
GO
DROP PROCEDURE table_var_procedure;
GO


-- test declaring a variable whose name is already used - should throw error
create procedure dup_var_name_procedure as
begin
	declare @a int;
	declare @a tableType;
end;
GO

-- test declaring a variable whose name is already used as table name - should work
create table test_table (d int);
GO
create procedure dup_var_name_procedure as
begin
	declare @test_table tableType;
	insert into @test_table values('hello1', 1, 100);
	select * from @test_table;
end;
GO
EXEC dup_var_name_procedure;
GO
drop procedure dup_var_name_procedure;
GO
drop table test_table;
GO

-- test assigning to table variables, should not be allowed
create table test_table(a int, b int);
GO
insert into test_table values(1, 10);
GO
create procedure assign_proc as
begin
	declare @tableVar table (a int, b int);
	set @tableVar = test_table;
end;
GO


-- test JOIN on table variables, on both sides
create procedure join_proc1 as
begin
	declare @tableVar table (a int, b int, c int);
	insert into @tableVar values(1, 2, 3);
	select * from test_table t inner join @tableVar tv on t.a = tv.a;
end;
GO
EXEC join_proc1;
GO
DROP PROCEDURE join_proc1;
GO

create procedure join_proc2 as
begin
	declare @tableVar table (a int, b int, c int);
	insert into @tableVar values(1, 2, 3);
	select * from @tableVar tv inner join test_table t on tv.a = t.a;
end;
GO
EXEC join_proc2;
GO
DROP PROCEDURE join_proc2;
GO


-- test using the same variables as source and target
create procedure source_target_proc as
begin
	declare @tv table (a int);
	insert into @tv values (1);
	insert into @tv select a+1 from @tv;
	insert into @tv select a+2 from @tv;
	insert into @tv select a+4 from @tv;
	select * from @tv;
end;
GO
EXEC source_target_proc;
GO
DROP PROCEDURE source_target_proc;
GO

-- -- test multiple '@' characters in table variable name
-- -- TODO: BABEL-476 Support variable name with multiple '@' characters
-- /*
-- create procedure nameing_proc as
-- begin
-- 	declare @@@tv@1@@@ as table(a int);
-- 	insert  @@@tv@1@@@ values(1);
-- 	select * from  @@@tv@1@@@;
-- end;
-- GO
-- CALL naming_proc();
-- GO
-- DROP PROCEDURE naming_proc;
-- GO
-- */

-- test nested functions using table variables with the same name, each should
-- have its own variable
create function inner_func() returns int as
begin
	declare @result int;
	declare @tableVar table (a int);
	insert into @tableVar values(1);
	select @result = count(*) from @tableVar; -- should be 1
	return @result;
end;
GO
create function outer_func() returns int as
begin
	declare @result int;
	declare @tableVar table(b int);
	select @result = count(*) from @tableVar; -- should be 0
	select @result = @result + inner_func(); -- should be 0 + 1 = 1
	-- the temp table in inner_func() should have been dropped by now, so the
	-- next call to inner_func() should still return 1
	select @result = @result + inner_func(); -- should be 1 + 1 = 2
	return @result;
end;
GO
select outer_func();
GO
DROP FUNCTION outer_func;
GO

-- test calling a function with table variables in a loop, each should have its
-- own variable
create procedure loop_func_proc as
begin
	declare @result int;
    declare @counter int;
	select @result = 0;
    set @counter = 1;
    while (@counter < 6)
    begin
		select @result = @result + inner_func(); -- each call to inner_func should return 1
        set @counter = @counter + 1;
    end
	select @result;
end;
GO
EXEC loop_func_proc;
GO
DROP PROCEDURE loop_func_proc;
GO

DROP FUNCTION inner_func;
GO

-- test declaring the same variable in a loop - should not have any error, and
-- should all refer to the same underlying table
create procedure loop_proc as
begin
	declare @result int;
	declare @curr int;
    declare @counter int;
	select @result = 0;
    set @counter = 1;
    while (@counter < 6)
    begin
		declare @a tableType;
		insert into @a values('hello', @counter, 100);
		select @curr = count(*) from @a; -- @curr in each loop should be 1,2,3,4,5
		select @result = @result + @curr;
        set @counter = @counter + 1;
    end
	select @result;
end;
GO
EXEC loop_proc
GO
DROP PROCEDURE loop_proc;
GO

-- test using table variables in CTE, both in with clause and in main query
create procedure cte_proc as
begin
	declare @tablevar1 tableType;
	insert into @tablevar1 values('hello1', 1, 100);
	declare @tablevar2 tableType;
	insert into @tablevar2 values('hello1', 1, 100);
	insert into @tablevar2 values('hello2', 2, 200);
	WITH t1 (a) AS (SELECT a FROM @tablevar1) SELECT * FROM @tablevar2 t2 JOIN t1 ON t2.a = t1.a;
end;
GO
EXEC cte_proc
GO
DROP PROCEDURE cte_proc;
GO

-- BABEL-894: test PLtsql_expr->tsql_tablevars is initialized to NIL so that it
-- won't cause seg faults when looked up during execution. One place missed
-- earlier is when parsing the SET command.
create procedure pl_set_proc as
begin
	set datefirst 7;
end;
GO
EXEC pl_set_proc
GO
DROP PROCEDURE pl_set_proc;
GO

-- test select from multiple table variables
create procedure select_multi_tablevars as
begin
	declare @tablevar1 tableType;
	insert into @tablevar1 values('hello1', 1, 100);
	declare @tablevar2 tableType;
	insert into @tablevar2 values('hello1', 1, 100);
	insert into @tablevar2 values('hello2', 2, 200);
	select * from @tablevar1, @tablevar2;
end;
GO
EXEC select_multi_tablevars
GO
DROP PROCEDURE select_multi_tablevars;
GO

-- test select from table and table variable
create procedure select_table_tablevar as
begin
	declare @tablevar tableType;
	insert into @tablevar values('hello1', 1, 100);
	select * from test_table, @tablevar;
end;
GO
EXEC select_table_tablevar
GO
DROP PROCEDURE select_table_tablevar;
GO

-- test table-valued parameters
-- if no READONLY behind table-valued param: report error
create function error_func(@tableVar tableType) returns int as
begin
	return 1;
end
GO
-- if READONLY on other param type: report error
create function error_func(@a int, @b int READONLY) returns int as
begin
	return 1;
end
GO
-- correct syntax
create function tvp_func(@tableVar tableType READONLY) returns int as
begin
	declare @result int;
	select @result = count(*) from @tableVar;
	return @result;
end
GO
-- test passing in a table variable whose type is different from what the function wants
-- TODO: BABEL-899: error message should be "Operand type clash: table is incompatible with tableType"
EXEC error_proc
GO
DROP PROCEDURE error_proc;
GO
create procedure tvp_proc as
begin
	declare @tableVar tableType;
	insert into @tablevar values('hello1', 1, 100);
	select tvp_func(@tableVar);
end;
GO
EXEC tvp_proc
GO
DROP PROCEDURE tvp_proc;
GO
DROP FUNCTION tvp_func;
GO
-- test multiple table-valued parameters
CREATE TYPE tableType1 AS table(d int, e int);
GO
create function multi_tvp_func(@tableVar tableType READONLY,
							   @tableVar1 tableType1 READONLY) returns int as
begin
	declare @result int;
	select @result = count(*) from @tableVar tv inner join @tableVar1 tv1 on tv.b = tv1.d;
	return @result;
end
GO
create procedure multi_tvp_proc as
begin
	declare @v1 tableType;
	declare @v2 tableType1;
	insert into @v1 values('hello1', 1, 100);
	insert into @v2 values(1, 100);
	insert into @v2 values(2, 200);
	select multi_tvp_func(@v1, @v2);
end;
GO
EXEC multi_tvp_proc
GO
DROP PROCEDURE multi_tvp_proc;
GO
DROP FUNCTION multi_tvp_func;
GO
DROP TYPE tableType1;
GO

-- test multi-statement table-valued functions
create function mstvf(@i int) returns @tableVar table
(
	a text not null,
	b int primary key,
	c int
)
as
begin
	insert into @tableVar values('hello1', 1, 100);
	insert into @tableVar values('hello2', 2, 200);
end;
GO
select * from mstvf(1);
GO
DROP FUNCTION mstvf;
GO
-- test mstvf whose return table has only one column
create function mstvf_one_col(@i int) returns @tableVar table
(
	a text not null
)
as
begin
	insert into @tableVar values('hello1');
end;
GO
select * from mstvf_one_col(1);
GO
DROP FUNCTION mstvf_one_col;
GO
-- test mstvf whose return table has only one column
create function mstvf_return(@i int) returns @tableVar table
(
	a text not null
)
as
begin
	insert into @tableVar values('hello2');
	return;
end;
GO
select * from mstvf_return(1);
GO
DROP FUNCTION mstvf_return;
GO
-- test mstvf's with same names in different schemas
create function mstvf_schema(@i int) returns @resultTable table
(
	name varchar(128) not null
)
as
begin
	insert into @resultTable (name) select 'test_name';
	RETURN;
end;
GO
create schema test_schema;
GO
create function test_schema.mstvf_schema(@i int) returns @resultTable table
(
	name1 varchar(128) not null
)
as
begin
	insert into @resultTable (name1) select 'test_name1';
	RETURN;
end;
GO
select * from mstvf_schema(1);
GO
select * from test_schema.mstvf_schema(1);
GO
drop function mstvf_schema;
GO
drop function test_schema.mstvf_schema;
GO
drop schema test_schema;
GO
-- test mstvf with constraints in result table
create function mstvf_constraints(@i int) returns @resultTable table
(
	name varchar(128) not null,
	unique (name),
	id int,
	primary key clustered (id)
)
as
begin
	insert into @resultTable (name, id) select 'test_name', @i;
	RETURN;
end;
GO
select * from mstvf_constraints(1);
GO
drop function mstvf_constraints;
GO

-- cleanup
DROP TYPE tableType;
GO
DROP TABLE test_table;
GO