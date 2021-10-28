-- BABEL-1645
-- CAST is VOLATILE if one of these conditions exists:
-- 1. Source type is sql_variant.
-- 2. Target type is sql_variant and its source type is nondeterministic.
-- 3. Source or target type is datetime/datetime2/smalldatetime, the other source or target type is a character string/sql_variant/other datetime types.

-- VOLATILE functions can not be used to generate persisted computed columns, the following
-- tests are based on this rule.

create table t1 (id int, a varchar(10));
GO

-- CAST from char to varchar is immutable/deterministic and can be used to generate computed column
alter table t1 add b as cast(cast('01-01-2012' as char(10)) as varchar(10)) persisted;
GO

-- CAST from sql_variant to other type is VOLATILE and is not allowed to generate computed column
alter table t1 add c as cast(cast('01-01-2012' as sql_variant) as varchar(10)) persisted;
GO

-- CAST to sql_variant from VOLATILE source type is also VOLATILE
alter table t1 add c as cast(GETDATE() as sql_variant) persisted;
GO

-- CAST to sql_variant from datetime is VOLATILE
alter table t1 add c as cast(cast('01-01-2012' as datetime) as sql_variant) persisted;
GO

-- CAST to sql_variant from smalldatetime is VOLATILE
alter table t1 add c as cast(cast('01-01-2012' as smalldatetime) as sql_variant) persisted;
GO

-- CAST from datetime/datetime2/smalldatetime to character string type/other datetime typee is VOLATILE
alter table t1 add c as cast(cast('01-01-2012' as datetime) as varchar(10)) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as datetime) as nvarchar(10)) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as datetime) as char(10)) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as datetime) as nchar(10)) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as datetime) as date) persisted;
GO

alter table t1 add c as cast(cast('01:01' as datetime) as time) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as datetime2) as varchar(10)) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as datetime2) as nvarchar(10)) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as datetime2) as char(10)) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as datetime2) as nchar(10)) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as datetime2) as date) persisted;
GO

alter table t1 add c as cast(cast('01:01' as datetime2) as time) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as smalldatetime) as varchar(10)) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as smalldatetime) as nvarchar(10)) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as smalldatetime) as char(10)) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as smalldatetime) as nchar(10)) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as smalldatetime) as date) persisted;
GO

alter table t1 add c as cast(cast('01:01' as smalldatetime) as time) persisted;
GO

-- CAST to datetime/datetime2/smalldatetime from character string type/datetime type is VOLATILE
alter table t1 add c as cast(cast('01-01-2012' as varchar(10)) as datetime) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as nvarchar(10)) as datetime) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as char(10)) as datetime) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as nchar(10)) as datetime) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as date) as datetime) persisted;
GO

alter table t1 add c as cast(cast('01:01' as time) as datetime) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as varchar(10)) as datetime2) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as nvarchar(10)) as datetime2) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as char(10)) as datetime2) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as nchar(10)) as datetime2) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as date) as datetime2) persisted;
GO

alter table t1 add c as cast(cast('01:01' as time) as datetime2) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as varchar(10)) as smalldatetime) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as nvarchar(10)) as smalldatetime) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as char(10)) as smalldatetime) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as nchar(10)) as smalldatetime) persisted;
GO

alter table t1 add c as cast(cast('01-01-2012' as date) as smalldatetime) persisted;
GO

alter table t1 add c as cast(cast('01:01' as time) as smalldatetime) persisted;
GO

-- Test cast between datetime/smalldatetime and varchar/nvarchar/char/nchar since we
-- added the cast functions in this patch
select cast(cast('01-01-2012' as datetime) as varchar(10));
GO
select cast(cast('01-01-2012' as datetime) as varchar(5));
GO

select cast(cast('01-01-2012' as datetime) as nvarchar(10));
GO
select cast(cast('01-01-2012' as datetime) as nvarchar(5));
GO

select cast(cast('01-01-2012' as datetime) as char(10));
GO
select cast(cast('01-01-2012' as datetime) as char(5));
GO

select cast(cast('01-01-2012' as datetime) as nchar(10));
GO
select cast(cast('01-01-2012' as datetime) as nchar(5));
GO

select cast(cast('01-01-2012' as varchar(10)) as datetime);
GO

select cast(cast('01-01-2012' as nvarchar(10)) as datetime);
GO

select cast(cast('01-01-2012' as char(10)) as datetime);
GO

select cast(cast('01-01-2012' as nchar(10)) as datetime);
GO

-- test cast between datetime2 and varchar/char...
select cast(cast('01-01-2012' as datetime2) as varchar(10));
GO
select cast(cast('01-01-2012' as datetime2) as varchar(5));
GO

select cast(cast('01-01-2012' as datetime2) as nvarchar(10));
GO
select cast(cast('01-01-2012' as datetime2) as nvarchar(5));
GO

select cast(cast('01-01-2012' as datetime2) as char(10));
GO
select cast(cast('01-01-2012' as datetime2) as char(5));
GO

select cast(cast('01-01-2012' as datetime2) as nchar(10));
GO
select cast(cast('01-01-2012' as datetime2) as nchar(5));
GO

select cast(cast('01-01-2012' as varchar(10)) as datetime2);
GO

select cast(cast('01-01-2012' as nvarchar(10)) as datetime2);
GO

select cast(cast('01-01-2012' as char(10)) as datetime2);
GO

select cast(cast('01-01-2012' as nchar(10)) as datetime2);
GO

-- test cast between smalldatetime and varchar/char...
select cast(cast('01-01-2012' as smalldatetime) as varchar(10));
GO
select cast(cast('01-01-2012' as smalldatetime) as varchar(5));
GO

select cast(cast('01-01-2012' as smalldatetime) as nvarchar(10));
GO
select cast(cast('01-01-2012' as smalldatetime) as nvarchar(5));
GO

select cast(cast('01-01-2012' as smalldatetime) as char(10));
GO
select cast(cast('01-01-2012' as smalldatetime) as char(5));
GO

select cast(cast('01-01-2012' as smalldatetime) as nchar(10));
GO
select cast(cast('01-01-2012' as smalldatetime) as nchar(5));
GO

select cast(cast('01-01-2012' as varchar(10)) as smalldatetime);
GO

select cast(cast('01-01-2012' as nvarchar(10)) as smalldatetime);
GO

select cast(cast('01-01-2012' as char(10)) as smalldatetime);
GO

select cast(cast('01-01-2012' as nchar(10)) as smalldatetime);
GO

-- TODO BABEL-1624: CAST from datetime/smalldatetime to text/ntext type should not be allowed
-- alter table t1 add c as cast(cast('01-01-2012' as datetime) as text) persisted;
-- GO

-- alter table t1 add d as cast(cast('01-01-2012' as datetime) as ntext) persisted;
-- GO

-- alter table t1 add c as cast(cast('01-01-2012' as smalldatetime) as text) persisted;
-- GO

-- alter table t1 add d as cast(cast('01-01-2012' as smalldatetime) as ntext) persisted;
-- GO

-- clean up
drop table t1;
GO
