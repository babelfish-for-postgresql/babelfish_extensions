select * from babel_4475_v1
go

select * from babel_4475_v2
go

select definition from sys.sql_modules where object_id = object_id('babel_4475_v1')
go

select definition from sys.sql_modules where object_id = object_id('babel_4475_v2')
go
