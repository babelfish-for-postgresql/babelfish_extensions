------------------- CI_AI ----------------------
DROP TABLE test_like_for_AI_prepare_t6_ci;
GO

DROP TABLE test_like_for_AI_prepare_t7_ci;
GO

DROP TABLE test_like_for_AI_prepare_t13_1_ci;
GO

DROP TABLE test_like_for_AI_prepare_t13_2_ci;
GO

DROP TABLE test_like_for_AI_prepare_employee_CI_AI;
GO

------------------- CS_AI ----------------------
DROP TABLE test_like_for_AI_prepare_t1_cs;
GO

DROP TABLE test_like_for_AI_prepare_t6_cs;
GO

DROP TABLE test_like_for_AI_prepare_t7_cs;
GO

DROP TABLE test_like_for_AI_prepare_t13_1_cs;
GO

DROP TABLE test_like_for_AI_prepare_t13_2_cs;
GO

DROP TABLE test_like_for_AI_prepare_employee_CS_AI;
GO

-- GENERIC --
DROP TABLE test_like_for_AI_prepare_escape;
GO

DROP TABLE test_like_for_AI_prepare_max_test;
GO

DROP TABLE test_like_for_AI_prepare_chinese;
GO

-- TESTS for remove_accents_internal
DROP FUNCTION test_like_for_AI_prepare_function;
GO

DROP VIEW test_like_for_AI_prepare_view;
GO

DROP PROCEDURE test_like_for_AI_prepare_procedure;
GO


DROP TABLE test_like_for_AI_prepare_t1_ci;
GO

-- TESTS FOR INDEX SCAN
DROP INDEX c1_idx ON test_like_for_AI_prepare_index;
GO

DROP INDEX c2_idx ON test_like_for_AI_prepare_index;
GO

DROP TABLE test_like_for_AI_prepare_index;
GO

DROP TABLE test_babel_5006;
GO
