-- expected error due to invalid syntax
CREATE PROCEDURE p1 AS
CREATE PROC p2
AS
SELECT * FROM t1
GO

-- expected error due to invalid syntax
CREATE PROCEDURE p3 AS
CREATE PROC p4
AS
SELECT 1234
GO
