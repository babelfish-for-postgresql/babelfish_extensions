-- parallel_query_expected
select set_config('babelfishpg_tsql.explain_costs', 'off', false);
go
select set_config('babelfishpg_tsql.explain_timing', 'off', false);
go
select set_config('babelfishpg_tsql.explain_summary', 'off', false);
go
select current_setting('babelfishpg_tsql.escape_hatch_showplan_all');
go

-- SHOWPLAN_ALL and STATISTICS PROFILE should be ignored
set showplan_all on;
go
select 1;
go
set showplan_all off;
go
set statistics profile on;
go
select 1;
go
set statistics profile off;
go

-- SHOWPLAN_ALL and STATISTICS PROFILE should return BBF query plans
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_showplan_all', 'ignore';
go

set showplan_all on;
go
select 1;
go
set showplan_all off;
go
set statistics profile on;
go
select 1;
go
set statistics profile off;
go

-- clean up
EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_showplan_all', 'strict';
go

select set_config('babelfishpg_tsql.explain_costs', 'on', false);
go
select set_config('babelfishpg_tsql.explain_timing', 'on', false);
go
select set_config('babelfishpg_tsql.explain_summary', 'on', false);
go
