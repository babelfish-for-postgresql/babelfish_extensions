-- clean up
drop table BABEL_1566_vu_prepare_1;
go

drop table BABEL_1566_vu_prepare_2;
go

drop table BABEL_1566_vu_prepare_3;
go

drop table BABEL_1566_vu_prepare_dates;
go

drop table BABEL_1566_vu_prepare_4;
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go