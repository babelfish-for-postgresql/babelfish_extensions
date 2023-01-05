-- sla 2500000
use babel_sp_fkeys_vu_prepare_db1
go

-- error: @pktable_name and/or @fktable_name must be provided
exec sp_fkeys
go

-- error: provided name of database we are not currently in
exec sp_fkeys @fktable_name = 'babel_sp_fkeys_vu_prepare_t2', @pktable_qualifier = 'master'
go

exec sp_fkeys @pktable_name = 'babel_sp_fkeys_vu_prepare_t1'
go

exec sys.sp_fkeys @pktable_name = 'babel_sp_fkeys_vu_prepare_t1'
go

exec sp_fkeys @fktable_name = 'babel_sp_fkeys_vu_prepare_t2', @pktable_qualifier = 'babel_sp_fkeys_vu_prepare_db1'
go

exec sp_fkeys @pktable_name = 'babel_sp_fkeys_vu_prepare_t3', @pktable_owner = 'dbo'
go

-- case-insensitive invocation
EXEC SP_FKEYS @FKTABLE_NAME = 'babel_sp_fkeys_vu_prepare_t4', @PKTABLE_NAME = 'babel_sp_fkeys_vu_prepare_t3', @PKTABLE_OWNER = 'dbo', @FKTABLE_QUALIFIER = 'babel_sp_fkeys_vu_prepare_db1'
GO

-- case-insensitive parameter calls
exec sp_fkeys @fktable_name = 'babel_sp_fkeys_vu_prepare_T4', @pktable_name = 'babel_sp_fkeys_vu_prepare_T3', @pktable_owner = 'dbo', @fktable_qualifier = 'babel_sp_fkeys_vu_prepare_db1'
go

-- [] delimiter invocation
EXEC [sys].[sp_fkeys] @FKTABLE_NAME = 'babel_sp_fkeys_vu_prepare_t4', @PKTABLE_NAME = 'babel_sp_fkeys_vu_prepare_t3', @PKTABLE_OWNER = 'dbo', @FKTABLE_QUALIFIER = 'babel_sp_fkeys_vu_prepare_db1'
GO

-- Mix-cased table tests
exec sp_fkeys @pktable_name = 'babel_sp_fkeys_vu_prepare_mytable5'
go

exec sp_fkeys @pktable_name = 'babel_sp_fkeys_vu_prepare_MYTABLE5'
go

exec sp_fkeys @fktable_name = 'babel_sp_fkeys_vu_prepare_mytable6'
go

exec sp_fkeys @fktable_name = 'babel_sp_fkeys_vu_prepare_MYTABLE6'
go

exec sp_fkeys @fktable_name = 'babel_sp_fkeys_vu_prepare_mytable7'
go

exec sp_fkeys @fktable_name = 'babel_sp_fkeys_vu_prepare_MYTABLE7'
go
-- Delimiter table tests NOTE: THese do not procude correct output due to BABEL-2883
exec sp_fkeys @pktable_name = [babel_sp_fkeys_vu_prepare_mytable5]
go

exec sp_fkeys @pktable_name = [babel_sp_fkeys_vu_prepare_MYTABLE5]
go

exec sp_fkeys @fktable_name = [babel_sp_fkeys_vu_prepare_mytable6]
go

exec sp_fkeys @fktable_name = [babel_sp_fkeys_vu_prepare_MYTABLE6]
go

exec sp_fkeys @fktable_name = [babel_sp_fkeys_vu_prepare_mytable7]
go

exec sp_fkeys @fktable_name = [babel_sp_fkeys_vu_prepare_MYTABLE7]
go

use master
go

EXEC SP_FKEYS @FKTABLE_NAME = 'babel_sp_fkeys_vu_prepare_t4'
go
