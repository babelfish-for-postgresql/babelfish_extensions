CREATE TABLE babel_4566 (id int)
GO
INSERT INTO babel_4566 VALUES ( OBJECT_ID('babel_4566') )
GO

SELECT COUNT(*) FROM babel_4566 WHERE 1=1 AND NOT OBJECT_NAME(id) LIKE '%Blah%'
GO

DROP TABLE babel_4566
GO