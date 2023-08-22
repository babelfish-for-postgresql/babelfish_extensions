
-- We should be able to use replace function in computed column.
CREATE TABLE babel_4330_t1(a varchar(50) NULL, b as replace(a, '1', '2'));
GO

INSERT INTO babel_4330_t1 VALUES('13131');
GO

SELECT * FROM babel_4330_t1
GO

UPDATE babel_4330_t1 SET a = '14141' WHERE a = '13131';
GO

SELECT * FROM babel_4330_t1
GO

ALTER TABLE babel_4330_t1 ADD c AS replace(a, '1','5');
GO

SELECT * FROM babel_4330_t1
GO


CREATE TABLE babel_4330_t2(a varchar(50) NULL, b as replace(a, NULL, '2'));
GO

INSERT INTO babel_4330_t2 VALUES('13131');
GO

SELECT * FROM babel_4330_t2
GO

CREATE TABLE babel_4330_t3(a varchar(50) NULL, b as replace(a, '1', NULL));
GO

INSERT INTO babel_4330_t3 VALUES('13131');
GO

SELECT * FROM babel_4330_t3
GO

DROP TABLE babel_4330_t1;
GO


DROP TABLE babel_4330_t2;
GO


DROP TABLE babel_4330_t3;
GO

