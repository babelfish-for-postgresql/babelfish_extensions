CREATE TABLE t_2317 (c1 int IDENTITY PRIMARY KEY, c2 int default 42);
INSERT INTO t_2317 DEFAULT VALUES;
INSERT t_2317 DEFAULT VALUES;
INSERT INTO t_2317 with (dummy_hint) DEFAULT VALUES;
GO

SELECT * FROM t_2317;
GO

-- not yet supported since conflict at backend parser
INSERT INTO t_2317 output inserted.* DEFAULT VALUES;
GO
CREATE TABLE t_2317_2 (d1 int, d2 int);
GO
INSERT INTO t_2317 output inserted.c1, inserted.c2 INTO t_2317_2 DEFAULT VALUES;
GO
INSERT INTO t_2317 output inserted.c1, inserted.c2 INTO t_2317_2(d1, d2) DEFAULT VALUES;
GO

DROP TABLE t_2317;
DROP TABLE t_2317_2;
GO
