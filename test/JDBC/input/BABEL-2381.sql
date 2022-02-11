USE master
go

declare @v int = 0;
if @v = '' print 'a' else print 'b';
go

-- From String literals
select cast('' as tinyint);
go
select cast(' ' as tinyint);
go
select cast('1' as tinyint);
go
select cast(' 123 ' as tinyint);
go
select cast(null as tinyint);
go

select cast('' as smallint);
go
select cast(' ' as smallint);
go
select cast('1' as smallint);
go
select cast(' 123 ' as smallint);
go
select cast(null as smallint);
go

select cast('' as int);
go
select cast(' ' as int);
go
select cast('1' as int);
go
select cast(' 123 ' as int);
go
select cast(null as int);
go

select cast('' as bigint);
go
select cast(' ' as bigint);
go
select cast('1' as bigint);
go
select cast(' 123 ' as bigint);
go
select cast(null as bigint);
go

select cast('' as decimal);
go
select cast(' ' as decimal);
go
select cast('1' as decimal);
go
select cast(' 123 ' as decimal);
go
select cast(null as decimal);
go

select cast('' as float(20));
go
select cast(' ' as float(20));
go
select cast('1' as float(20));
go
select cast(' 123 ' as float(20));
go
select cast(null as float(20));
go

select cast('' as float(50));
go
select cast(' ' as float(50));
go
select cast('1' as float(50));
go
select cast(' 123 ' as float(50));
go
select cast(null as float(50));
go

select cast('' as real);
go
select cast(' ' as real);
go
select cast('1' as real);
go
select cast(' 123 ' as real);
go
select cast(null as real);
go

select cast('' as numeric);
go
select cast(' ' as numeric);
go
select cast('1' as numeric);
go
select cast(' 123 ' as numeric);
go
select cast(null as numeric);
go

-- From VARCHAR
select cast(cast ('' as varchar) as tinyint);
go
select cast(cast (' ' as varchar) as tinyint);
go
select cast(cast ('1' as varchar) as tinyint);
go
select cast(cast (' 123 ' as varchar) as tinyint);
go
select cast(cast (null as varchar) as tinyint);
go

select cast(cast ('' as varchar) as smallint);
go
select cast(cast (' ' as varchar) as smallint);
go
select cast(cast ('1' as varchar) as smallint);
go
select cast(cast (' 123 ' as varchar) as smallint);
go
select cast(cast (null as varchar) as smallint);
go

select cast(cast ('' as varchar) as int);
go
select cast(cast (' ' as varchar) as int);
go
select cast(cast ('1' as varchar) as int);
go
select cast(cast (' 123 ' as varchar) as int);
go
select cast(cast (null as varchar) as int);
go

select cast(cast ('' as varchar) as bigint);
go
select cast(cast (' ' as varchar) as bigint);
go
select cast(cast ('1' as varchar) as bigint);
go
select cast(cast (' 123 ' as varchar) as bigint);
go
select cast(cast (null as varchar) as bigint);
go

select cast(cast ('' as varchar) as float(20));
go
select cast(cast (' ' as varchar) as float(20));
go
select cast(cast ('1' as varchar) as float(20));
go
select cast(cast (' 123.1 ' as varchar) as float(20));
go
select cast(cast (null as varchar) as float(20));
go

select cast(cast ('' as varchar) as float(50));
go
select cast(cast (' ' as varchar) as float(50));
go
select cast(cast ('1' as varchar) as float(50));
go
select cast(cast (' 123.1 ' as varchar) as float(50));
go
select cast(cast (null as varchar) as float(50));
go

select cast(cast ('' as varchar) as decimal);
go
select cast(cast (' ' as varchar) as decimal);
go
select cast(cast ('1' as varchar) as decimal);
go
select cast(cast (' 123.1 ' as varchar) as decimal);
go
select cast(cast (null as varchar) as decimal);
go

select cast(cast ('' as varchar) as real);
go
select cast(cast (' ' as varchar) as real);
go
select cast(cast ('1' as varchar) as real);
go
select cast(cast (' 123.1 ' as varchar) as real);
go
select cast(cast (null as varchar) as real);
go

select cast(cast ('' as varchar) as numeric);
go
select cast(cast (' ' as varchar) as numeric);
go
select cast(cast ('1' as varchar) as numeric);
go
select cast(cast (' 123.1 ' as varchar) as numeric);
go
select cast(cast (null as varchar) as numeric);
go

-- From CHAR
select cast(cast ('' as char) as tinyint);
go
select cast(cast (' ' as char) as tinyint);
go
select cast(cast ('1' as char) as tinyint);
go
select cast(cast (' 123 ' as char) as tinyint);
go
select cast(cast (null as char) as tinyint);
go

select cast(cast ('' as char) as smallint);
go
select cast(cast (' ' as char) as smallint);
go
select cast(cast ('1' as char) as smallint);
go
select cast(cast (' 123 ' as char) as smallint);
go
select cast(cast (null as char) as smallint);
go

select cast(cast ('' as char) as int);
go
select cast(cast (' ' as char) as int);
go
select cast(cast ('1' as char) as int);
go
select cast(cast (' 123 ' as char) as int);
go
select cast(cast (null as char) as int);
go

select cast(cast ('' as char) as bigint);
go
select cast(cast (' ' as char) as bigint);
go
select cast(cast ('1' as char) as bigint);
go
select cast(cast (' 123 ' as char) as bigint);
go
select cast(cast (null as char) as bigint);
go

select cast(cast ('' as char) as float(20));
go
select cast(cast (' ' as char) as float(20));
go
select cast(cast ('1' as char) as float(20));
go
select cast(cast (' 123.1 ' as char) as float(20));
go
select cast(cast (null as char) as float(20));
go

select cast(cast ('' as char) as float(50));
go
select cast(cast (' ' as char) as float(50));
go
select cast(cast ('1' as char) as float(50));
go
select cast(cast (' 123.1 ' as char) as float(50));
go
select cast(cast (null as char) as float(50));
go

select cast(cast ('' as char) as decimal);
go
select cast(cast (' ' as char) as decimal);
go
select cast(cast ('1' as char) as decimal);
go
select cast(cast (' 123.1 ' as char) as decimal);
go
select cast(cast (null as char) as decimal);
go

select cast(cast ('' as char) as real);
go
select cast(cast (' ' as char) as real);
go
select cast(cast ('1' as char) as real);
go
select cast(cast (' 123.1 ' as char) as real);
go
select cast(cast (null as char) as real);
go

select cast(cast ('' as char) as numeric);
go
select cast(cast (' ' as char) as numeric);
go
select cast(cast ('1' as char) as numeric);
go
select cast(cast (' 123.1 ' as char) as numeric);
go
select cast(cast (null as char) as numeric);
go