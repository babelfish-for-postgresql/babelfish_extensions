drop table babel_1206_vu_prepare_t1;
go
drop table babel_1206_vu_prepare_t2;
go
drop table babel_1206_vu_prepare_t3;
go
drop table babel_1206_vu_prepare_t4;
go
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'strict';
go