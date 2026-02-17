DROP VIEW enr_view
GO

DROP TYPE temp_table_type
GO

DROP PROCEDURE test_rollback_in_proc
GO

DROP PROCEDURE implicit_rollback_in_proc
GO

DROP PROCEDURE tv_base_rollback
GO

DROP PROCEDURE tv_tt_no_error
GO

DROP PROCEDURE tv_mapped_error
GO

DROP PROCEDURE tv_unmapped_error
GO

DROP FUNCTION func_get_sum_temp
GO

DROP FUNCTION func_get_count_temp
GO

DROP FUNCTION func_get_min_max_temp
GO

DROP PROCEDURE test_temp_table_drop_intermediate_idx
GO

DROP PROCEDURE test_alter_index_truncate_cache_fix
GO


DROP PROC p_drop
GO

DROP PROC p_drop_multi
GO

DROP PROC p_outer
GO

DROP PROC p_inner
GO

DROP PROC p_trans_drop
GO

DROP PROC p_create_insert
GO

DROP PROC p_update_delete
GO

DROP PROC p_nested_inner
GO

DROP PROC p_nested_outer
GO

DROP PROC p_rollback_ops
GO

DROP PROC p_multi_temp_ops
GO

DROP PROC p_error_ops
GO

DROP PROC p_truncate_ops
GO

DROP PROC p_conditional_ops
GO

DROP PROC p_insert_exec_basic
GO

DROP PROC p_insert_exec_nested_inner
GO

DROP PROC p_insert_exec_nested_outer
GO

DROP PROC p_insert_exec_temp_ops
GO

DROP PROC p_insert_exec_transaction
GO

DROP PROC p_insert_exec_multi_results
GO

DROP PROC p_insert_exec_error_handling
GO

DROP PROC p_insert_exec_table_var
GO

DROP PROC p_insert_exec_drop_table
GO
