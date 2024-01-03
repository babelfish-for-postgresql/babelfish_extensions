select * from babel_4475_v1
go

select babel_4475_f1()
go

exec babel_4475_p1
go

select * from babel_4475_v2
go

select babel_4475_f2()
go

exec babel_4475_p2
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

select * from babel_4475_v3
go

select babel_4475_f3()
go

exec babel_4475_p3
go

select * from babel_4475_v4
go

select babel_4475_f4()
go

exec babel_4475_p4
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go

select definition from sys.sql_modules where object_id = object_id('babel_4475_v1')
go

select definition from sys.sql_modules where object_id = object_id('babel_4475_v2')
go

select definition from sys.sql_modules where object_id = object_id('babel_4475_v3')
go

select definition from sys.sql_modules where object_id = object_id('babel_4475_v4')
go

-- tests for validating typmod and maxlen
select cast(cast('abcdef' as binary(6)) as varchar(6))
go

select cast(cast('abcdef' as binary(6)) as varchar)
go

select cast(cast('abcdef' as binary(6)) as varchar(max))
go

select cast(cast('abcdef' as binary(6)) as varchar(2))
go

select cast(cast('abcdef' as binary(6)) as varchar(10485761))
go

select cast(cast('abcdef' as binary(6)) as varchar(10485760))
go
