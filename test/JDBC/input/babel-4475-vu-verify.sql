select * from babel_4475_v1
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

select * from babel_4475_v2
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go

select definition from sys.sql_modules where object_id = object_id('babel_4475_v1')
go

select definition from sys.sql_modules where object_id = object_id('babel_4475_v2')
go
