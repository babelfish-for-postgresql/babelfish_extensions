CREATE TABLE smalldate_date_cmp_t1 (
    smalldatetime_col SMALLDATETIME NULL
)
GO

INSERT INTO smalldate_date_cmp_t1 (smalldatetime_col) SELECT cast('2023-06-15 14:30:00' as smalldatetime) from generate_series(1, 100000)
GO

INSERT INTO smalldate_date_cmp_t1 (smalldatetime_col) SELECT cast('2023-09-30 14:30:00' as smalldatetime) from generate_series(1, 100000)
GO

INSERT INTO smalldate_date_cmp_t1 (smalldatetime_col) SELECT cast('2023-10-15 14:30:00' as smalldatetime) from generate_series(1, 100000)
GO

INSERT INTO smalldate_date_cmp_t1 (smalldatetime_col) SELECT cast('2023-10-06 14:30:00' as smalldatetime) from generate_series(1, 100000)
GO

INSERT INTO smalldate_date_cmp_t1 (smalldatetime_col) SELECT cast('2023-09-30 16:30:00' as smalldatetime) from generate_series(1, 100000)
GO

INSERT INTO smalldate_date_cmp_t1 (smalldatetime_col) SELECT cast('2023-06-15 10:30:00' as smalldatetime) from generate_series(1, 100000)
GO

CREATE NONCLUSTERED INDEX smalldate_date_cmp_ind1 ON smalldate_date_cmp_t1
(
    smalldatetime_col ASC
)
GO

CREATE PROCEDURE test_smalldatetime_date_p1 AS
SELECT COUNT(*) FROM smalldate_date_cmp_t1 WHERE smalldatetime_col <= CAST('2023-09-30' AS DATE) AND smalldatetime_col >= CAST('2023-08-31' AS DATE);
GO

CREATE PROCEDURE test_smalldatetime_date_p2 AS
SELECT COUNT(*) FROM smalldate_date_cmp_t1 WHERE smalldatetime_col = CAST('2023-09-30' AS DATE);
GO

CREATE PROCEDURE test_smalldatetime_date_p3 AS
SELECT COUNT(*) FROM smalldate_date_cmp_t1 WHERE smalldatetime_col < CAST('2023-09-30' AS DATE);
GO

CREATE PROCEDURE test_smalldatetime_date_p4 AS
SELECT COUNT(*) FROM smalldate_date_cmp_t1 WHERE smalldatetime_col > CAST('2023-09-30' AS DATE);
GO

CREATE PROCEDURE test_smalldatetime_date_p5 AS
SELECT COUNT(*) FROM smalldate_date_cmp_t1 WHERE smalldatetime_col <= CAST('2023-09-30' AS DATE);
GO

CREATE PROCEDURE test_smalldatetime_date_p6 AS
SELECT COUNT(*) FROM smalldate_date_cmp_t1 WHERE smalldatetime_col >= CAST('2023-08-31' AS DATE);
GO

CREATE PROCEDURE test_smalldatetime_date_p7 AS
SELECT COUNT(*) FROM smalldate_date_cmp_t1 WHERE smalldatetime_col <> CAST('2023-08-31' AS DATE);
GO

CREATE VIEW test_smalldatetime_date_v1 AS
SELECT COUNT(*) FROM smalldate_date_cmp_t1 WHERE smalldatetime_col <= CAST('2023-09-30' AS DATE) AND smalldatetime_col >= CAST('2023-08-31' AS DATE);
GO

CREATE VIEW test_smalldatetime_date_v2 AS
SELECT COUNT(*) FROM smalldate_date_cmp_t1 WHERE smalldatetime_col = CAST('2023-09-30' AS DATE);
GO

CREATE VIEW test_smalldatetime_date_v3 AS
SELECT COUNT(*) FROM smalldate_date_cmp_t1 WHERE smalldatetime_col < CAST('2023-09-30' AS DATE);
GO

CREATE VIEW test_smalldatetime_date_v4 AS
SELECT COUNT(*) FROM smalldate_date_cmp_t1 WHERE smalldatetime_col > CAST('2023-09-30' AS DATE);
GO

CREATE VIEW test_smalldatetime_date_v5 AS
SELECT COUNT(*) FROM smalldate_date_cmp_t1 WHERE smalldatetime_col <= CAST('2023-09-30' AS DATE);
GO

CREATE VIEW test_smalldatetime_date_v6 AS
SELECT COUNT(*) FROM smalldate_date_cmp_t1 WHERE smalldatetime_col >= CAST('2023-08-31' AS DATE);
GO

CREATE VIEW test_smalldatetime_date_v7 AS
SELECT COUNT(*) FROM smalldate_date_cmp_t1 WHERE smalldatetime_col <> CAST('2023-08-31' AS DATE);
GO

CREATE TABLE smalldate_date_cmp_t2 (
    smalldatetime_col SMALLDATETIME NULL
)
GO

INSERT INTO smalldate_date_cmp_t2 VALUES ('2023-06-15 14:30:00');
GO

CREATE NONCLUSTERED INDEX smalldate_date_cmp_ind2 ON smalldate_date_cmp_t2
(
    smalldatetime_col ASC
)
GO
