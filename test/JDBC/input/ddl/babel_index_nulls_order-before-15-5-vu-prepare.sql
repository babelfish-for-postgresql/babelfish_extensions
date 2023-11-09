CREATE TABLE babel_index_nulls_order_before_15_5_tbl (a INT, b VARCHAR(10))
go

INSERT INTO babel_index_nulls_order_before_15_5_tbl VALUES 
(1, 'abc'), (2, 'def'), (3, 'ghi'), (4, 'jkl'),
(5, 'mno'), (6, 'pqr'), (7, 'stu'), (8, 'xyz'),
(1, 'abc'), (2, 'def'), (3, 'ghi'), (4, 'jkl'),
(5, 'mno'), (6, 'pqr'), (7, 'stu'), (8, 'xyz'),
(NULL, NULL)
go

CREATE INDEX babel_index_nulls_order_before_15_5_asc_idx_a ON babel_index_nulls_order_before_15_5_tbl (a ASC)
go
CREATE INDEX babel_index_nulls_order_before_15_5_desc_idx_b ON babel_index_nulls_order_before_15_5_tbl (b DESC)
go
CREATE INDEX babel_index_nulls_order_before_15_5_default_idx_ab ON babel_index_nulls_order_before_15_5_tbl (a, b)
go

SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'babel_index_nulls_order_before_15_5_tbl'
ORDER BY indexname
go

CREATE VIEW babel_index_nulls_order_before_15_5_a_v1 AS
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a <= 5 OR a IS NULL ORDER BY a DESC
go

CREATE VIEW babel_index_nulls_order_before_15_5_a_v2 AS
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a > 5 OR a IS NULL ORDER BY a ASC
go

CREATE VIEW babel_index_nulls_order_before_15_5_a_v3 AS
SELECT TOP 1 a FROM babel_index_nulls_order_before_15_5_tbl WHERE a > 5 OR a IS NULL ORDER BY a
go

CREATE VIEW babel_index_nulls_order_before_15_5_b_v1 AS
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b <= 'sss' OR b IS NULL ORDER BY b DESC
go

CREATE VIEW babel_index_nulls_order_before_15_5_b_v2 AS
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b > 'sss' OR b IS NULL ORDER BY b ASC
go

CREATE VIEW babel_index_nulls_order_before_15_5_b_v3 AS
SELECT TOP 1 b FROM babel_index_nulls_order_before_15_5_tbl WHERE b > 'sss' OR b IS NULL ORDER BY b
go

CREATE VIEW babel_index_nulls_order_before_15_5_ab_v1 AS
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE (a = 3 AND b <= 'sss') OR b IS NULL ORDER BY b DESC
go

CREATE VIEW babel_index_nulls_order_before_15_5_ab_v2 AS
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE (a = 3 AND b <= 'sss') OR b IS NULL ORDER BY b ASC
go

CREATE VIEW babel_index_nulls_order_before_15_5_ab_v3 AS
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE (a = 3 AND b <= 'sss') OR b IS NULL ORDER BY b
go

CREATE VIEW babel_index_nulls_order_before_15_5_ab_v4 AS
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE (a > 5 AND b = 'xyz') OR a IS NULL ORDER BY a DESC
go

CREATE VIEW babel_index_nulls_order_before_15_5_ab_v5 AS
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE (a > 5 AND b = 'xyz') OR a IS NULL ORDER BY a ASC
go

CREATE VIEW babel_index_nulls_order_before_15_5_ab_v6 AS
SELECT TOP 1 a, b FROM babel_index_nulls_order_before_15_5_tbl WHERE (a > 5 AND b = 'xyz') OR a IS NULL ORDER BY a
go
