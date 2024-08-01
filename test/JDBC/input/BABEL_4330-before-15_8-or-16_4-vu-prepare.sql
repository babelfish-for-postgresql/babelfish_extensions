
CREATE TABLE babel_4330_vu_prepare_t1(a varchar(50) NULL);
GO

INSERT INTO babel_4330_vu_prepare_t1 VALUES('ababa');
GO

CREATE VIEW babel_4330_vu_prepare_v1 AS 
SELECT replace(a, 'a', 'c') FROM babel_4330_vu_prepare_t1
GO

CREATE FUNCTION babel_4330_vu_prepare_f1() returns table as return
SELECT replace(a, 'a', 'c') FROM babel_4330_vu_prepare_t1
GO

CREATE PROCEDURE babel_4330_vu_prepare_p1 AS SELECT replace(a, 'a', 'c') FROM babel_4330_vu_prepare_t1
GO