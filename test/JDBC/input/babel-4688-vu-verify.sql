select * from babel_4688_v1
go

select * from babel_4688_v2
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

select * from babel_4688_v3
go

select * from babel_4688_v4
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go
