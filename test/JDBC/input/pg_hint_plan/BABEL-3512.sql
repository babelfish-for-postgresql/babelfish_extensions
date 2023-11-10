-- parallel_query_expected
/*
 * Test stored procs WITH hints. All tests examine the query plan AND the 
 * pg_proc table to ensure that subsequent connections will be using the correct
 * query.
*/

DROP TABLE IF EXISTS babel_3512_t1
GO

DROP TABLE IF EXISTS babel_3512_t2
GO

DROP TABLE IF EXISTS babel_3512_t3
GO

DROP procedure IF EXISTS babel_3512_proc_1
GO

DROP procedure IF EXISTS babel_3512_proc_2
GO

DROP procedure IF EXISTS babel_3512_proc_3
GO

DROP procedure IF EXISTS babel_3512_proc_4
GO

DROP procedure IF EXISTS babel_3512_proc_5
GO

DROP procedure IF EXISTS babel_3512_proc_6
GO

DROP procedure IF EXISTS babel_3512_proc_7
GO

DROP procedure IF EXISTS babel_3512_proc_8
GO

DROP procedure IF EXISTS babel_3512_proc_9
GO

DROP procedure IF EXISTS babel_3512_proc_10
GO

DROP procedure IF EXISTS babel_3512_proc_conflict_1
GO

DROP procedure IF EXISTS babel_3512_proc_conflict_2
GO

DROP procedure IF EXISTS babel_3512_comment_test_1
GO

DROP procedure IF EXISTS babel_3512_comment_test_2
GO

CREATE TABLE babel_3512_t1(a1 int PRIMARY KEY, b1 int, c1 int)
GO

CREATE INDEX index_babel_3512_t1_b1 ON babel_3512_t1(b1)
GO

CREATE INDEX index_babel_3512_t1_c1 ON babel_3512_t1(c1)
GO

CREATE TABLE babel_3512_t2(a2 int PRIMARY KEY, b2 int, c2 int)
GO

CREATE TABLE babel_3512_t3(a3 int PRIMARY KEY, b3 int, c3 int)
GO

CREATE INDEX index_babel_3512_t2_b2 ON babel_3512_t2(b2)
GO

SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false)
GO

select set_config('babelfishpg_tsql.enable_pg_hint', 'on', false);
go

-- Test one line stored procs WITH join hints
CREATE PROCEDURE babel_3512_proc_1 AS SELECT babel_3512_t1.a1 FROM babel_3512_t1 inner hash join babel_3512_t2 ON a1 = b2
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3512_proc_1';
GO

SET babelfish_showplan_all ON
GO

EXEC babel_3512_proc_1
GO

SET babelfish_showplan_all OFF
GO

-- Test multi line stored procs WITH join hints
CREATE PROCEDURE babel_3512_proc_2 AS
SELECT * FROM babel_3512_t1 inner hash join babel_3512_t2 ON a1 = b2
SELECT * FROM babel_3512_t2 inner loop join babel_3512_t1 ON babel_3512_t1.c1 = babel_3512_t2.c2
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3512_proc_2';
GO

SET babelfish_showplan_all ON
GO

EXEC babel_3512_proc_2
GO

SET babelfish_showplan_all OFF
GO

-- Test one line stored procs WITH index hints
CREATE PROCEDURE babel_3512_proc_3 AS
SELECT * FROM babel_3512_t1 (index(index_babel_3512_t1_b1)) WHERE b1 = 1
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3512_proc_3';
GO

SET babelfish_showplan_all ON
GO

EXEC babel_3512_proc_3
GO

SET babelfish_showplan_all OFF
GO

-- Test multple line stored procs WITH index hints
CREATE PROCEDURE babel_3512_proc_4 AS
SELECT * FROM babel_3512_t1 (index(index_babel_3512_t1_b1)) WHERE b1 = 1
SELECT * FROM babel_3512_t1 WITH(index(index_babel_3512_t1_b1)) WHERE b1 = 1
SELECT * FROM babel_3512_t1 WHERE b1 = 3 OPTION(table hint(babel_3512_t1, index(index_babel_3512_t1_b1)))
SELECT * FROM babel_3512_t1 WITH(index=index_babel_3512_t1_b1) WHERE b1 = 1 UNION SELECT * FROM babel_3512_t2 WITH(index=index_babel_3512_t2_b2) WHERE b2 = 1
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3512_proc_4';
GO

SET babelfish_showplan_all ON
GO

EXEC babel_3512_proc_4
GO

SET babelfish_showplan_all OFF
GO

-- Test CTE Queries single line
CREATE PROCEDURE babel_3512_proc_5 AS
WITH babel_3512_t1_cte (a1, b1, c1) as (SELECT * FROM babel_3512_t1 WITH(index=index_babel_3512_t1_b1) WHERE b1 = 1) SELECT * FROM babel_3512_t1_cte WHERE c1 = 1
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3512_proc_5';
GO

SET babelfish_showplan_all ON
GO

EXEC babel_3512_proc_5
GO

SET babelfish_showplan_all OFF
GO

-- Test CTE Queries multi-line
CREATE PROCEDURE babel_3512_proc_6 AS
WITH babel_3512_t1_cte (a1, b1, c1) as (SELECT * FROM babel_3512_t1 WITH(index=index_babel_3512_t1_b1) WHERE b1 = 1) SELECT * FROM babel_3512_t1_cte WHERE c1 = 1
WITH babel_3512_t2_cte (a1, b2, c2) as (SELECT * FROM babel_3512_t2 WITH(index=index_babel_3512_t2_b1) WHERE b2 = 1) SELECT * FROM babel_3512_t2_cte WHERE c2 = 1
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3512_proc_6';
GO

SET babelfish_showplan_all ON
GO

EXEC babel_3512_proc_6
GO

SET babelfish_showplan_all OFF
GO

-- Test table hints single line
CREATE PROCEDURE babel_3512_proc_7 AS
SELECT * FROM babel_3512_t1, babel_3512_t2 WHERE b1 = 1 AND b2 = 1 OPTION(table hint(babel_3512_t1, index(index_babel_3512_t1_b1)), table hint(babel_3512_t2, index(index_babel_3512_t2_b2)))
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3512_proc_7';
GO

SET babelfish_showplan_all ON
GO

EXEC babel_3512_proc_7
GO

SET babelfish_showplan_all OFF
GO

-- Test table hints multi line
CREATE PROCEDURE babel_3512_proc_8 AS
SELECT * FROM babel_3512_t1, babel_3512_t2 WHERE b1 = 1 AND b2 = 1
SELECT * FROM babel_3512_t1, babel_3512_t2 WHERE b1 = 1 AND b2 = 1 OPTION(table hint(babel_3512_t1, index(index_babel_3512_t1_b1)), table hint(babel_3512_t2, index(index_babel_3512_t2_b2)))
SELECT * FROM babel_3512_t1 babel_3512_t1 WITH(index=index_babel_3512_t1_b1), babel_3512_t2 babel_3512_t2 WITH(index=index_babel_3512_t2_b2) WHERE b1 = 1 AND b2 = 1
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3512_proc_8';
GO

SET babelfish_showplan_all ON
GO

EXEC babel_3512_proc_8
GO

SET babelfish_showplan_all OFF
GO
-- Test multiple hints combined single line
CREATE PROCEDURE babel_3512_proc_9 AS
SELECT * FROM babel_3512_t1 WITH(index(index_babel_3512_t1_b1)) inner loop join babel_3512_t2 (index(index_babel_3512_t2_b2)) ON babel_3512_t1.a1 = babel_3512_t2.a2 WHERE b1 = 1 AND b2 = 1
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3512_proc_9';
GO

SET babelfish_showplan_all ON
GO

EXEC babel_3512_proc_9
GO

SET babelfish_showplan_all OFF
GO
-- Test multiple hints combined multi-line
CREATE PROCEDURE babel_3512_proc_10 AS
SELECT * FROM babel_3512_t1 join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2 WHERE b1 = 1 AND b2 = 1
SELECT * FROM babel_3512_t1 join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2 WHERE b1 = 1 AND b2 = 1 OPTION(loop join, table hint(babel_3512_t1, index(index_babel_3512_t1_b1)), table hint(babel_3512_t2, index(index_babel_3512_t2_b2)))
SELECT * FROM babel_3512_t1 WITH(index(index_babel_3512_t1_b1)) right outer merge join babel_3512_t2 (index(index_babel_3512_t2_b2)) ON babel_3512_t1.a1 = babel_3512_t2.a2 WHERE b1 = 1 AND b2 = 1
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3512_proc_10';
GO

SET babelfish_showplan_all ON
GO

EXEC babel_3512_proc_10
GO

SET babelfish_showplan_all OFF
GO

-- Test conflicting hints raises error
CREATE PROCEDURE babel_3512_proc_conflict_1 AS
SELECT * FROM babel_3512_t1 inner hash join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2 OPTION(merge join)
GO

EXEC babel_3512_proc_conflict_1
GO

-- Test conflicting hints in multi-line stored proc raises error
CREATE PROCEDURE babel_3512_proc_conflict_2 AS
SELECT * FROM babel_3512_t1 inner hash join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
SELECT * FROM babel_3512_t1 inner hash join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2 OPTION(merge join)
GO

EXEC babel_3512_proc_conflict_2
GO

SET babelfish_showplan_all ON
GO

-- Test hints with comment blocks
SELECT/* this is a comment block */ * FROM babel_3512_t1 inner join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
GO

SELECT/* this is a comment block */ * FROM babel_3512_t1 inner loop join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
GO

SELECT /* this is a comment block */ * FROM babel_3512_t1 inner loop join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
GO

SELECT	/* this is a comment block */ * FROM babel_3512_t1 inner loop join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
GO

SELECT
*
FROM
babel_3512_t1
inner
hash
join
babel_3512_t2
ON
babel_3512_t1.a1
=
babel_3512_t2.a2
GO

SELECT/*test*/SUM(1)
GO

SELECT/*this is a comment block*/*FROM babel_3512_t1 inner loop join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
GO

/* this is another comment block */SELECT/*this is a comment block*/* FROM babel_3512_t1 inner loop join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
GO

/* this is another comment block *//*thisisanothercommentblock*/SELECT/*this is a comment block*/ * FROM babel_3512_t1 inner loop join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
GO

/* this is another comment block *//* this is another comment block */SELECT/*this is a comment block1234*//*this is a comment block*/ * FROM babel_3512_t1 inner loop join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
GO
SELECT/*this is a comment
 multi line block */
 /*this is a comment block*/	* FROM babel_3512_t1 inner loop join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
GO

-- Test hints with comment blocks in stored procs
SET babelfish_showplan_all OFF
GO

CREATE PROCEDURE babel_3512_comment_test_1 AS
SELECT/* this is a comment block */ * FROM babel_3512_t1 inner join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
SELECT/* this is a comment block */ * FROM babel_3512_t1 inner loop join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
SELECT /* this is a comment block */ * FROM
 babel_3512_t1 inner merge join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
SELECT/*this is a comment block*/*FROM babel_3512_t1 inner loop join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
/* this is another comment block */SELECT/*this is a comment block*/ * FROM babel_3512_t1 inner loop join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3512_comment_test_1';
GO

CREATE PROCEDURE babel_3512_comment_test_2 AS
/* this is another comment block *//*thisisanothercommentblock*/SELECT/*this is a comment block*/ * FROM babel_3512_t1 inner loop join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
/* this is another comment block *//* this is another comment block */SELECT/*this is a comment block1234*//*this is a comment block*/ * FROM babel_3512_t1 inner loop join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
SELECT/*this is a comment
 multi line block */
 /*this is a comment block*/ * FROM babel_3512_t1 inner loop join babel_3512_t2 ON babel_3512_t1.a1 = babel_3512_t2.a2
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3512_comment_test_2';
GO

SET babelfish_showplan_all ON
GO

EXEC babel_3512_comment_test_1
GO

EXEC babel_3512_comment_test_2
GO

-- clean up 
SET babelfish_showplan_all OFF
GO

DROP PROCEDURE  babel_3512_proc_1
GO

DROP PROCEDURE  babel_3512_proc_2
GO

DROP PROCEDURE  babel_3512_proc_3
GO

DROP PROCEDURE  babel_3512_proc_4
GO

DROP PROCEDURE  babel_3512_proc_5
GO

DROP PROCEDURE  babel_3512_proc_6
GO

DROP PROCEDURE  babel_3512_proc_7
GO

DROP PROCEDURE  babel_3512_proc_8
GO

DROP PROCEDURE  babel_3512_proc_9
GO

DROP PROCEDURE  babel_3512_proc_10
GO

DROP procedure IF EXISTS babel_3512_proc_conflict_1
GO

DROP procedure IF EXISTS babel_3512_proc_conflict_2
GO

DROP procedure IF EXISTS babel_3512_comment_test_1
GO

DROP procedure IF EXISTS babel_3512_comment_test_2
GO

DROP TABLE babel_3512_t1
GO

DROP TABLE babel_3512_t2
GO

DROP TABLE babel_3512_t3
GO
