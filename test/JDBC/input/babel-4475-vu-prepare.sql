create view babel_4475_v1 as select cast(cast('a' as binary(2)) as varchar(2))
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

create view babel_4475_v2 as select cast(cast('ab' as rowversion) as varchar(2))
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go
