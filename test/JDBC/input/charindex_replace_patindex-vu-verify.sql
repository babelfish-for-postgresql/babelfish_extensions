-- parallel_query_expected
USE babel_5144_db
GO

EXEC babel_5144_p @src = 'abcḍèĎÈdedEDEabcd', @from = 'de', @to = '##'
GO

SELECT babel_5144_f1('abcḍèĎÈdedEDEabcd', 'de', '##')
SELECT babel_5144_f2('abcḍèĎÈdedEDEabcd', 'de')
SELECT babel_5144_f3('abcḍèĎÈdedEDEabcd')
GO

INSERT INTO babel_5144_t1 VALUES ('abcḍèĎÈdedEDEabcd', 'de', '##')
INSERT INTO babel_5144_t2 VALUES ('abcḍèĎÈdedEDEabcd', 'de', '##')
-- INSERT INTO babel_5144_t3(src, substr1, substr2) VALUES ('abcḍèĎÈdedEDEabcd', 'de', '##')
GO

-- validate check constraint
INSERT INTO babel_5144_t2 VALUES ('abcdabcd', 'de', 'de')
GO
INSERT INTO babel_5144_t2 VALUES ('ḍèĎÈdedEDEabcd', 'de', '##')
GO
INSERT INTO babel_5144_t2 VALUES ('aaaaaabcd', 'ab', '##')
GO

SELECT * FROM babel_5144_t2
GO

SELECT set_config('babelfishpg_tsql.explain_verbose', 'off', false)
SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false)
SELECT set_config('babelfishpg_tsql.explain_timing', 'off', false)
SELECT set_config('babelfishpg_tsql.explain_summary', 'off', false)
GO
SET BABELFISH_STATISTICS PROFILE ON;
SELECT set_config('enable_seqscan', 'off', false);
SELECT set_config('enable_bitmapscan', 'off', false);
GO

SELECT * FROM babel_5144_t1 WHERE [replaced] = 'abc##########abcd'
GO
SELECT * FROM babel_5144_t1 WHERE [charIndex] = 4;
GO
SELECT * FROM babel_5144_t1 WHERE [patindex] = 4;
GO

SET BABELFISH_STATISTICS PROFILE OFF;
GO

SELECT * FROM babel_5144_v1
GO
