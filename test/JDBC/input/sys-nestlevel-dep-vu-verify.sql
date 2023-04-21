USE nextleveldb
GO

-- should expect print out of 1, 2, 3, 4, 3, 2, 1
EXEC p1
GO

-- should expect print out of 0
SELECT @@NESTLEVEL
GO

-- should expect print out of 0
SELECT * from v0
GO

-- should expect print out of 0
SELECT * from v1
GO