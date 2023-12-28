select set_config('enable_bitmapscan', 'off', false);
GO

exec babel_3939_vu_prepare_p1;
GO

exec sp_babelfish_configure 'explain_costs', 'off';
GO

SET BABELFISH_SHOWPLAN_ALL ON;
GO



exec babel_3939_vu_prepare_p1;
GO

exec babel_3939_vu_prepare_p2;
GO

SET BABELFISH_SHOWPLAN_ALL OFF;
GO

select set_config('enable_bitmapscan', 'on', false);
GO

exec sp_babelfish_configure 'explain_costs', 'on';
GO