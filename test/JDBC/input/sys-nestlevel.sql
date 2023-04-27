CREATE DATABASE nextleveldb
GO

USE nextleveldb
GO

CREATE PROC p1
AS
SELECT @@NESTLEVEL AS p1BeforeShouldBe1
EXEC p2
SELECT @@NESTLEVEL AS p1AfterShouldBe1
GO

CREATE PROC p2
    AS
        SELECT @@NESTLEVEL AS p2BeforeShouldBe2
        EXEC p3
        SELECT @@NESTLEVEL AS p2AfterShouldBe2
GO

CREATE PROC p3
AS
SELECT @@NESTLEVEL AS p3BeforeShouldBe3
EXEC p4
SELECT @@NESTLEVEL AS p3AfterShouldBe3
GO

CREATE PROC p4
AS
SELECT @@NESTLEVEL AS p4ShouldBe4
GO

CREATE VIEW v0
AS
SELECT @@NESTLEVEL AS v0ShouldBe0
GO

CREATE VIEW v1
AS
SELECT * FROM v0
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

DROP PROC p4
GO

DROP PROC p3
GO

DROP PROC p2
GO

DROP PROC p1
GO

DROP VIEW v1
GO

DROP VIEW v0
GO

USE master
GO

DROP DATABASE nextleveldb
GO