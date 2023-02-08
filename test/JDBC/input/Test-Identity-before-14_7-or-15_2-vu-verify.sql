EXEC test_identity_vu_prepare_p1
GO

-- SCOPE_IDENTITY should return NULL because insert into t1 happened inside a function
-- Validated the same behaviour in SQLServer
SELECT MAX(id) as MaximumUsedIdentity FROM test_identity_vu_prepare_t1
SELECT SCOPE_IDENTITY()
SELECT @@IDENTITY
SELECT IDENT_CURRENT('test_identity_vu_prepare_t1')
GO

EXEC test_identity_vu_prepare_p1
GO

SELECT * FROM test_identity_vu_prepare_t1 ORDER BY id
GO

-- SCOPE_IDENTITY should not be the same as IDENTITY
-- SCOPE_IDENTITY matches max(id) in t2
-- IDENTITY is the value from trigger
-- validated same behaviour in SQLServer
EXEC test_identity_vu_prepare_p2
GO

-- insert into t3, no triggers during insert into t3
-- all identities should be the same
-- validated in SQL Server
EXEC test_identity_vu_prepare_p3
GO

SELECT * FROM test_identity_vu_prepare_t2 ORDER BY id
GO
SELECT * FROM test_identity_vu_prepare_t3 ORDER BY DepartmentID
GO

SELECT test_identity_vu_prepare_func1()
GO

SELECT test_identity_vu_prepare_func2()
GO

SELECT test_identity_vu_prepare_func3()
GO

SELECT * FROM test_identity_vu_prepare_t4 ORDER BY Name
GO

-- SCOPE_IDENTITY is NULL because all INSERTs so far happened inside a function
-- Similarly, this was validated against SQL Server
SELECT SCOPE_IDENTITY()
SELECT @@IDENTITY
SELECT IDENT_CURRENT('test_identity_vu_prepare_t4')
GO

ALTER TABLE test_identity_vu_prepare_t4 ADD id INT IDENTITY(1,1) NOT NULL
GO

SELECT * FROM test_identity_vu_prepare_t4 ORDER BY Name
GO

SELECT MAX(id) as MaximumUsedIdentity FROM test_identity_vu_prepare_t4
SELECT SCOPE_IDENTITY()
SELECT @@IDENTITY
SELECT IDENT_CURRENT('test_identity_vu_prepare_t4')
GO

SELECT * FROM test_identity_vu_prepare_t5 ORDER BY Name
GO

SELECT test_identity_vu_prepare_func4()
GO

EXEC test_identity_vu_prepare_p4
GO

SELECT test_identity_vu_prepare_func4()
GO

INSERT test_identity_vu_prepare_t6 
OUTPUT INSERTED.ID
VALUES ('Babelfish5'),('Babelfish6'),('Babelfish7')
GO

EXEC test_identity_vu_prepare_p5
GO
