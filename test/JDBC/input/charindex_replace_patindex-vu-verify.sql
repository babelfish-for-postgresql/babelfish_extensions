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
INSERT INTO babel_5144_t3(src, substr1, substr2) VALUES ('abcḍèĎÈdedEDEabcd', 'de', '##')
GO

-- validate check constraint
INSERT INTO babel_5144_t2 VALUES ('abcdabcd', 'de', 'de')
GO
INSERT INTO babel_5144_t2 VALUES ('ḍèĎÈdedEDEabcd', 'de', '##')
GO
INSERT INTO babel_5144_t2 VALUES ('aaaaaabcd', 'ab', '##')
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

SELECT [b].src, [c].[src], [a].[replaced], [b].[replaced], [c].[replaced] FROM 
    (SELECT replace(src, substr1, substr2) AS [replaced] FROM babel_5144_t2) [a]
    JOIN babel_5144_t1 [b] ON ([b].[replaced] = [a].[replaced])
    JOIN babel_5144_t3 [c] ON ([c].[replaced] = [a].[replaced])
GO
SELECT [b].src, [c].[src], [a].[charIndex], [b].[charIndex], [c].[charIndex] FROM 
    (SELECT charindex(substr1, src) AS [charIndex] FROM babel_5144_t2) [a]
    JOIN babel_5144_t1 [b] ON ([b].[charIndex] = [a].[charIndex])
    JOIN babel_5144_t3 [c] ON ([c].[charIndex] = [a].[charIndex])
GO
SELECT [b].src, [c].[src], [a].[patindex], [b].[patindex], [c].[patindex] FROM 
    (SELECT patindex('%de%', src) AS [patindex] FROM babel_5144_t2) [a]
    JOIN babel_5144_t1 [b] ON ([b].[patindex] = [a].[patindex])
    JOIN babel_5144_t3 [c] ON ([c].[patindex] = [a].[patindex])
GO

SET BABELFISH_STATISTICS PROFILE OFF;
GO

SELECT * FROM babel_5144_v1
GO
