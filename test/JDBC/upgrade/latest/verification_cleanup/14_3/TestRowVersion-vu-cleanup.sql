EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go

drop view testrowversion_v1;
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

drop function testrowversion_tvf1;
go

drop table testrowversion_t1;
drop table testrowversion_t2;
go

drop table testrowversion_t3;
go

drop table testrowversion_t4;
go

drop table testrowversion_t5;
go

drop table testrowversion_t8;
go

drop table testrowversion_t11;
go

drop table testrowversion_t12;
go

drop table testrowversion_t13;
go

drop table testrowversion_t14;
go

drop table babel_3139_t;
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go
