SELECT 42 = CAST(42 AS numeric(38,0))
GO

SELECT CAST(42 AS numeric(38,0)) = 42
GO


CREATE TABLE babel_820_test_table1(test_id INT IDENTITY, test_col1 INT)
GO

INSERT INTO babel_820_test_table1 (test_col1) VALUES (10), (20), (30)
GO


SELECT test_col1 FROM babel_820_test_table1 WHERE test_id = @@IDENTITY
GO


DROP TABLE babel_820_test_table1
GO

