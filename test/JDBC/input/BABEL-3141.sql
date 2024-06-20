CREATE TABLE t1(
	id INT,
	comment NVARCHAR(20)
) 
GO

CREATE TABLE t2(
	id INT,
	t1_id INT,
	PRIMARY KEY(id ASC)
) 
GO

INSERT t1 VALUES (1, 'test')	
GO

SELECT * FROM t1 a LEFT JOIN t2 b ON b.t1_id = a.id 
GO

-- Cleanup
DROP TABLE t1
GO

DROP TABLE t2
GO