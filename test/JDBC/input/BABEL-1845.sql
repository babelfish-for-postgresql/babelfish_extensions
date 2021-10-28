EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'strict';
GO

-- Test that ANSI_NULL_DFLT_ON can be set to ON and ANSI_NULL_DFLT_OFF can be set to OFF
set ANSI_NULL_DFLT_ON ON;
go

set ANSI_NULL_DFLT_OFF OFF;
go

-- Test a table column is nullable with the above settings (which is also the default setting)
create table t1 (c1 int);
go

insert into t1 values (NULL);
go

-- Expect one row of NULL value
select c1 from t1;
go

-- Test that ANSI_NULL_DFLT_ON can not be set to OFF and ANSI_NULL_DFLT_OFF can not be set to ON
set ANSI_NULL_DFLT_ON OFF;
go

set ANSI_NULL_DFLT_OFF ON;
go

-- Clean up
drop table if exists t1;
go

-- reset to default
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_session_settings', 'ignore';
GO
