-- parallel_query_expected

EXEC babel_5144_p @src = 'abcḍèĎÈdedEDEabcd', @from = 'de', @to = '##'
GO

SELECT babel_5144_f1('abcḍèĎÈdedEDEabcd', 'de', '##')
SELECT babel_5144_f2('abcḍèĎÈdedEDEabcd', 'de')
SELECT babel_5144_f3('abcḍèĎÈdedEDEabcd')
GO

INSERT INTO babel_5144_t1 VALUES ('abcḍèĎÈdedEDEabcd', 'de', '##')
INSERT INTO babel_5144_t2 VALUES ('abcḍèĎÈdedEDEabcd', 'de', '##')
INSERT INTO babel_5144_t3(src, substr1, substr2) VALUES ('abcḍèĎÈdedEDEabcd', 'de', '##')
GO

-- validate check constraint
INSERT INTO babel_5144_t2 VALUES ('abcdabcd', 'de', 'de')
GO
INSERT INTO babel_5144_t2 VALUES ('deĎÈdedEDEabcd', 'de', '##')
GO
INSERT INTO babel_5144_t2 VALUES ('aaaaaabcd', 'ab', '##')
GO

SELECT * FROM babel_5144_t2
GO

-- need to store output of charindex other wise explain analyze prints the entire function text
-- which could vary for version upgrade tests
CREATE TABLE #table_5144_result_store (id INT);
GO
INSERT INTO #table_5144_result_store VALUES (sys.charindex('de', 'abcḍèĎÈdedEDEabcd'))
GO

SELECT set_config('babelfishpg_tsql.explain_verbose', 'off', false)
SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false)
SELECT set_config('babelfishpg_tsql.explain_timing', 'off', false)
SELECT set_config('babelfishpg_tsql.explain_summary', 'off', false)
SELECT set_config('enable_seqscan', 'off', false);
SELECT set_config('enable_bitmapscan', 'off', false);
GO
SET BABELFISH_STATISTICS PROFILE ON;
GO

SELECT * FROM babel_5144_t1 WHERE [replaced] = sys.replace('abcḍèĎÈdedEDEabcd', 'de', '##')
GO
SELECT * FROM babel_5144_t1 WHERE [charIndex] = (SELECT id FROM #table_5144_result_store);
GO
SELECT * FROM babel_5144_t1 WHERE [patindex] = sys.patindex('%de%', 'abcḍèĎÈdedEDEabcd');
GO
SELECT * FROM babel_5144_t3 WHERE [replaced] = sys.replace('abcḍèĎÈdedEDEabcd', 'de', '##');
GO
SELECT * FROM babel_5144_t3 WHERE [charIndex] = (SELECT id FROM #table_5144_result_store);
GO
SELECT * FROM babel_5144_t3 WHERE [patindex] = sys.patindex('%de%', 'abcḍèĎÈdedEDEabcd');
GO

SET BABELFISH_STATISTICS PROFILE OFF;
GO

SELECT * FROM babel_5144_v1
GO
