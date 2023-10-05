-- tsql
CREATE TABLE test_babel_4279_t1([ABC.nfds] INT, [DEf.j] INT);
GO

CREATE VIEW test_babel_4279_v1 AS SELECT test_babel_4279_t1.[ABC.nfds] from test_babel_4279_t1;
GO

CREATE VIEW test_babel_4279_v2 AS SELECT [test_babel_4279_t1].[ABC.nfds] ,test_babel_4279_t1.[DEf.j] from test_babel_4279_t1;
GO

CREATE TABLE test_babel_4279_t2(AB您您对您对您对您对您对您对您对您对您对您您您 INT, 对您对您对您对您对您对您对您 INT);
GO

CREATE VIEW test_babel_4279_v3 AS SELECT test_babel_4279_t2.[AB您您对您对您对您对您对您对您对您对您对您您您] from test_babel_4279_t2;
GO

CREATE VIEW test_babel_4279_v4 AS SELECT ぁあ.[AB您您对您对您对您对您对您对您对您对您对您您您] from test_babel_4279_t2 AS ぁあ;
GO

CREATE SCHEMA "tngdf'";
GO

CREATE TABLE "tngdf'".[sc,sdg"fdsngjds']("AB[C" INT);
GO

CREATE VIEW test_babel_4279_v5 AS SELECT "tngdf'".[sc,sdg"fdsngjds']."AB[C" from "tngdf'".[sc,sdg"fdsngjds'];
GO

CREATE TABLE test_babel_4279_t3(ABCD INT);
GO

CREATE VIEW test_babel_4279_v6 AS SELECT  test_babel_4279_t3.ABCD FROM test_babel_4279_t3;
GO

CREATE TABLE test_babel_4279_t4([ぁあ'"] INT);
GO

CREATE VIEW test_babel_4279_v7 AS SELECT test_babel_4279_t4.[ぁあ'"] FROM test_babel_4279_t4;
GO
