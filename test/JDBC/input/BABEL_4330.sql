
-- We should be able to use replace function in computed column.
CREATE TABLE babel_4333_t1(a varchar(50) NULL, b as replace(a, '1', '2'));
GO

INSERT INTO babel_4333_t1 VALUES('13131');
GO

SELECT * FROM babel_4333_t1
GO

UPDATE babel_4333_t1 SET a = '14141' WHERE a = '13131';
GO

SELECT * FROM babel_4333_t1
GO

ALTER TABLE babel_4333_t1 ADD c AS replace(a, '1','5');
GO

SELECT * FROM babel_4333_t1
GO

DROP TABLE babel_4333_t1;
GO

