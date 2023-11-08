CREATE TABLE babel_index_nulls_order_before_15_4_tbl (a INT, b VARCHAR(10))
go

INSERT INTO babel_index_nulls_order_before_15_4_tbl VALUES 
(1, 'abc'), (2, 'def'), (3, 'ghi'), (4, 'jkl'),
(5, 'mno'), (6, 'pqr'), (7, 'stu'), (8, 'xyz'),
(1, 'abc'), (2, 'def'), (3, 'ghi'), (4, 'jkl'),
(5, 'mno'), (6, 'pqr'), (7, 'stu'), (8, 'xyz'),
(NULL, NULL)
go

CREATE INDEX babel_index_nulls_order_before_15_4_asc_idx_a ON babel_index_nulls_order_before_15_4_tbl (a ASC)
go
CREATE INDEX babel_index_nulls_order_before_15_4_desc_idx_b ON babel_index_nulls_order_before_15_4_tbl (b DESC)
go
CREATE INDEX babel_index_nulls_order_before_15_4_default_idx_ab ON babel_index_nulls_order_before_15_4_tbl (a, b)
go
