-- parallel_query_expected
SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false)
go

/*
 * These tests validate the T-SQL RECOMPILE behaviour for stored procedures.
 * The approach is to demonstrate the recompilation by disabling index scans, 
 * and observing a different plan being generated only when RECOMPILE is used.

 * Note that when a cached plan is used, there is no good way to prove in these tests that 
 * it was indeed a cached plan, as it could just as well be a newly generated plan that 
 * happens to be the same as the previous plan. While developing this fix, the PG planner() 
 * function was instrumented to prove that cached plans are indeed used when plan_cache_mode={auto|force_generic_plan},
 * but that is outside the scope of what can be used in these automated tests.

 * This fix for forcing plans for statements in the procedure body to be recompiled only
 * applies to paramtrized statements. Non-parametrized stmts, like the 2nd select in tb_recomp_11, 
 * will not be recompiled since choose_custom_plan() will always return false for those.
 * The current fix can be extended to also force such stmts to be recompiled but that is 
 * left for later.
 
 * Not tested:
 * - recursive procedure calls, since Babelfish does not show plans when a conditional statement 
 *   is involved (manual testing has shown RECOMPILE works as expected, i.e. the recursive call is
 *   handled independently from the higher-level call)
 * - plans inside SQL functions or triggers (not shown by PG when called from a procedure)
 
 */

select '==== EXEC with RECOMPILE tests with plan_cache_mode=auto ======'  
go
select set_config('plan_cache_mode', 'auto', false)
go
select set_config('enable_indexscan', 'on', false)
go
SELECT current_setting('plan_cache_mode') as plan_mode_before
go
SELECT current_setting('enable_indexscan') as enable_indexscan_before
go

select '--- p_recomp_11: no generic plan generated first -----'
go
select '--- using index scan ----'
go
set babelfish_showplan_all on
go
execute p_recomp_11 1
go
set babelfish_showplan_all off
go

select '--- tb_recomp_12: generate generic plan after repeated custom plans -----'
go

-- tb_recomp_12: generate generic plan after repeated custom plans
declare @i int = 6
while @i > 0
begin
exec    p_recomp_12 1
set @i -= 1
end
go
-- generic plan is now created for tb_recomp_12 --> no further replanning according to PG approach

set babelfish_showplan_all on
go
exec    p_recomp_12 1
go
set babelfish_showplan_all off
go

select '--- turning off index scan ----'
go
select set_config('enable_indexscan', 'off', false)
go
select current_setting('enable_indexscan') as indexscan_off
go

select '--- EXEC with RECOMPILE: recompiled plan: bitmap scan for parametrized stmt, index scan for non-parametrized ----'
go

set babelfish_showplan_all on
go
execute p_recomp_11 1 with recompile
go
exec    p_recomp_12 1 with recompile
go
set babelfish_showplan_all off
go

select '--- EXEC without RECOMPILE: index scan (using cached plan) ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_12 1 
go
set babelfish_showplan_all off
go


select '--- RECOMPILE combined with other option ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_11 1 with recompile, result sets none
go
exec    p_recomp_11 1 with result sets none, recompile
go
set babelfish_showplan_all off
go

select '--- tb_recomp_13: first execution: bitmap scan for both statements ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_13 1
go
exec    p_recomp_13 1 with recompile
go
set babelfish_showplan_all off
go

-- tb_recomp_13: generate generic plan after repeated custom plans
declare @i int = 6
while @i > 0
begin
exec    p_recomp_13 1
set @i -= 1
end
go
-- generic plan is now created for tb_recomp_13 --> no further replanning according to PG approach

select '--- turning on index scan ----'
go
select set_config('enable_indexscan', 'on', false)
go
select current_setting('enable_indexscan') as indexscan_on
go

select '--- EXEC with RECOMPILE: recompiled plan: index scan ----'
go
set babelfish_showplan_all on
go
execute p_recomp_11 1 with recompile 
go
exec    p_recomp_12 1 with recompile 
go
set babelfish_showplan_all off
go

select '--- EXEC without RECOMPILE: index scan (using cached plan) ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_12 1 
go
set babelfish_showplan_all off
go

select '--- tb_recomp_13: EXEC with RECOMPILE: recompiled plan: index scan for paramtrized stmt, bitmap scan for non-param stmt ----'
go
set babelfish_showplan_all on
go
execute p_recomp_13 1 with recompile 
go
set babelfish_showplan_all off
go

select '--- tb_recomp_13 without RECOMPILE: bitmap scan for both statements ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_13 1
go
exec    p_recomp_13 1 with recompile
go
set babelfish_showplan_all off
go


select '==== EXEC with RECOMPILE tests with plan_cache_mode=force_generic_plan ======'  
go
select set_config('plan_cache_mode', 'force_generic_plan', false)
go
SELECT current_setting('plan_cache_mode') as plan_mode_before
go
SELECT current_setting('enable_indexscan') as enable_indexscan_after
go


select '--- p_recomp_21: no generic plan generated first ------'
go
select '--- using index scan ----'
go
set babelfish_showplan_all on
go
execute p_recomp_21 1
go
set babelfish_showplan_all off
go

select '--- tb_recomp_22: generate generic plan after repeated custom plans ------'
go

-- tb_recomp_22: generate generic plan after repeated custom plans
declare @i int = 6
while @i > 0
begin
exec    p_recomp_22 1
set @i -= 1
end
go
-- generic plan is now created for tb_recomp_22 --> no further replanning according to PG approach

set babelfish_showplan_all on
go
exec    p_recomp_22 1
go
set babelfish_showplan_all off
go

select '--- turning off index scan ----'
go
select set_config('enable_indexscan', 'off', false)
go
select current_setting('enable_indexscan') as indexscan_off
go

select '--- EXEC with RECOMPILE: recompiled plan: bitmap scan for parametrized stmt, index scan for non-parametrized ----'
go

set babelfish_showplan_all on
go
execute p_recomp_21 1 with recompile
go
exec    p_recomp_22 1 with recompile
go
set babelfish_showplan_all off
go

select '--- EXEC without RECOMPILE: index scan (using cached plan) ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_22 1 
go
set babelfish_showplan_all off
go

select '--- tb_recomp_23: first execution: bitmap scan for both statements ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_23 1
go
exec    p_recomp_23 1 with recompile
go
set babelfish_showplan_all off
go

-- tb_recomp_23: generate generic plan after repeated custom plans
declare @i int = 6
while @i > 0
begin
exec    p_recomp_23 1
set @i -= 1
end
go
-- generic plan is now created for tb_recomp_23 --> no further replanning according to PG approach

select '--- turning on index scan ----'
go
select set_config('enable_indexscan', 'on', false)
go
select current_setting('enable_indexscan') as indexscan_on
go

select '--- EXEC with RECOMPILE: recompiled plan: index scan ----'
go
set babelfish_showplan_all on
go
execute p_recomp_21 1 with recompile 
go
exec    p_recomp_22 1 with recompile 
go
set babelfish_showplan_all off
go

select '--- EXEC without RECOMPILE: index scan (using cached plan) ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_22 1 
go
set babelfish_showplan_all off
go

select '--- tb_recomp_23: EXEC with RECOMPILE: recompiled plan: index scan for paramtrized stmt, bitmap scan for non-param stmt ----'
go
set babelfish_showplan_all on
go
execute p_recomp_23 1 with recompile 
go
set babelfish_showplan_all off
go

select '--- tb_recomp_23 without RECOMPILE: bitmap scan for both statements ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_23 1
go
exec    p_recomp_23 1 with recompile
go
set babelfish_showplan_all off
go


select '==== EXEC with RECOMPILE tests with plan_cache_mode=force_custom_plan ======'  
go
select set_config('plan_cache_mode', 'force_custom_plan', false)
go
SELECT current_setting('plan_cache_mode') as plan_mode_before
go
SELECT current_setting('enable_indexscan') as enable_indexscan_after
go



select '--- p_recomp_31: no generic plan generated first ------'
go
select '--- using index scan ----'
go
set babelfish_showplan_all on
go
execute p_recomp_31 1
go
set babelfish_showplan_all off
go

select '--- tb_recomp_32: generate generic plan after repeated custom plans ------'
go

-- tb_recomp_32: generate generic plan after repeated custom plans
declare @i int = 6
while @i > 0
begin
exec    p_recomp_32 1
set @i -= 1
end
go
-- generic plan is now created for tb_recomp_32 --> no further replanning according to PG approach

set babelfish_showplan_all on
go
exec    p_recomp_32 1
go
set babelfish_showplan_all off
go

select '--- turning off index scan ----'
go
select set_config('enable_indexscan', 'off', false)
go
select current_setting('enable_indexscan') as indexscan_off
go

select '--- EXEC with RECOMPILE: recompiled plan: bitmap scan for parametrized stmt, index scan for non-parametrized ----'
go

set babelfish_showplan_all on
go
execute p_recomp_31 1 with recompile
go
exec    p_recomp_32 1 with recompile
go
set babelfish_showplan_all off
go

select '--- EXEC without RECOMPILE: bitmap scan (due to force_custom_plans ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_32 1 
go
set babelfish_showplan_all off
go

select '--- tb_recomp_33: first execution: bitmap scan for both statements ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_33 1
go
exec    p_recomp_33 1 with recompile
go
set babelfish_showplan_all off
go

-- tb_recomp_33: generate generic plan after repeated custom plans
declare @i int = 6
while @i > 0
begin
exec    p_recomp_33 1
set @i -= 1
end
go
-- generic plan is now created for tb_recomp_33 --> no further replanning according to PG approach

select '--- turning on index scan ----'
go
select set_config('enable_indexscan', 'on', false)
go
select current_setting('enable_indexscan') as indexscan_on
go

select '--- EXEC with RECOMPILE: recompiled plan: index scan ----'
go
set babelfish_showplan_all on
go
execute p_recomp_31 1 with recompile 
go
exec    p_recomp_32 1 with recompile 
go
set babelfish_showplan_all off
go

select '--- EXEC without RECOMPILE: index scan (using cached plan) ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_32 1 
go
set babelfish_showplan_all off
go

select '--- tb_recomp_33: EXEC with RECOMPILE: recompiled plan: index scan for paramtrized stmt, bitmap scan for non-param stmt ----'
go
set babelfish_showplan_all on
go
execute p_recomp_33 1 with recompile 
go
set babelfish_showplan_all off
go

select '--- tb_recomp_33 without RECOMPILE: index scan for paramtrized stmt, bitmap scan for non-param stmt due to force_custom_plan ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_33 1
go
exec    p_recomp_33 1 with recompile
go
set babelfish_showplan_all off
go

select '==== CREATE with RECOMPILE tests with plan_cache_mode=auto ======'  
go
select set_config('plan_cache_mode', 'auto', false)
go
select set_config('enable_indexscan', 'on', false)
go
SELECT current_setting('plan_cache_mode') as plan_mode_before
go
SELECT current_setting('enable_indexscan') as enable_indexscan_before
go

select '--- tb_recomp_41/61 was created with RECOMPILE, so every execution uses RECOMPILE implicitly ------'
go

-- tb_recomp_41/61: following the same logic as for creating a generic plan, even though every call creates a custom plan
declare @i int = 6
while @i > 0
begin
exec    p_recomp_41 1
exec    p_recomp_61 1
set @i -= 1
end
go

select '--- index scan for both statements ---'
go
set babelfish_showplan_all on
go
exec    p_recomp_41 1
exec    p_recomp_61 1
go
set babelfish_showplan_all off
go

select '--- turning off index scan ----'
go
select set_config('enable_indexscan', 'off', false)
go
select current_setting('enable_indexscan') as indexscan_off
go

select '--- EXEC without RECOMPILE: still creating recompiled plan on every execution: bitmap scan for parametrized stmt, index scan for non-parametrized ----'
go

set babelfish_showplan_all on
go
exec    p_recomp_41 1 
exec    p_recomp_61 1 
go
set babelfish_showplan_all off
go

select '--- EXEC with RECOMPILE: same as EXEC without RECOMPILE ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_41 1 with recompile
exec    p_recomp_61 1 with recompile
go
set babelfish_showplan_all off
go

select '--- turning on index scan ----'
go
select set_config('enable_indexscan', 'on', false)
go
select current_setting('enable_indexscan') as indexscan_on
go

select '--- EXEC without RECOMPILE: still creating recompiled plan on every execution: index scan for both statements ----'
go

set babelfish_showplan_all on
go
exec    p_recomp_41 1 
exec    p_recomp_61 1 
go
set babelfish_showplan_all off
go

select '--- EXEC with RECOMPILE: same as EXEC without RECOMPILE ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_41 1 with recompile
exec    p_recomp_61 1 with recompile
go
set babelfish_showplan_all off
go

select '==== nested proc calls with plan_cache_mode=auto ======'  
go
select set_config('plan_cache_mode', 'auto', false)
go
select set_config('enable_indexscan', 'on', false)
go
SELECT current_setting('plan_cache_mode') as plan_mode_before
go
SELECT current_setting('enable_indexscan') as enable_indexscan_before
go

-- tb_recomp_51: creating a generic plan
declare @i int = 6
while @i > 0
begin
exec    p_recomp_51 1
set @i -= 1
end
go

select '--- index scan for all stmts ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_51 1
go
set babelfish_showplan_all off
go

select '--- turning off index scan ----'
go
select set_config('enable_indexscan', 'off', false)
go
select current_setting('enable_indexscan') as indexscan_off
go

select '--- index scan for all stmts, bitmap scan for paramterized stmts in recompiled calls ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_51 1
go
set babelfish_showplan_all off
go

select '--- bitmap scan for paramterized stmts in recompiled calls, index scan on all others ----'
go
set babelfish_showplan_all on
go
exec    p_recomp_51 1 with recompile
go
set babelfish_showplan_all off
go

select '--- turning on index scan ----'
go
select set_config('enable_indexscan', 'on', false)
go
select current_setting('enable_indexscan') as indexscan_on
go

select '--- index scan for all stmts ----'
go

set babelfish_showplan_all on
go
exec    p_recomp_51 1 
go
set babelfish_showplan_all off
go

select '--- index scan for all stmts ----'
go

set babelfish_showplan_all on
go
exec    p_recomp_51 1 with recompile
go
set babelfish_showplan_all off
go

select '==== end of tests ======'  
go
select set_config('plan_cache_mode', 'auto', false)
go
SELECT current_setting('plan_cache_mode') as plan_mode_after
go
SELECT current_setting('enable_indexscan') as enable_indexscan_after
go
