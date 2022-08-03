EXEC test_identity_vu_prepare_p1
GO

SELECT MAX(id) as MaximumUsedIdentity FROM test_identity_vu_prepare_t1
SELECT SCOPE_IDENTITY()
SELECT @@IDENTITY
SELECT IDENT_CURRENT('test_identity_vu_prepare_t1')
GO

EXEC test_identity_vu_prepare_p1
GO

SELECT * FROM test_identity_vu_prepare_t1
GO

EXEC test_identity_vu_prepare_p2
GO

EXEC test_identity_vu_prepare_p3
GO

SELECT * FROM test_identity_vu_prepare_t2
GO
SELECT * FROM test_identity_vu_prepare_t3
GO

SELECT test_identity_vu_prepare_func1()
GO

SELECT test_identity_vu_prepare_func2()
GO

SELECT test_identity_vu_prepare_func3()
GO

SELECT * FROM test_identity_vu_prepare_t4
GO

SELECT SCOPE_IDENTITY()
SELECT @@IDENTITY
SELECT IDENT_CURRENT('test_identity_vu_prepare_t4')
GO

ALTER TABLE test_identity_vu_prepare_t4 ADD id INT IDENTITY(1,1) NOT NULL
GO

SELECT * FROM test_identity_vu_prepare_t4
GO

SELECT MAX(id) as MaximumUsedIdentity FROM test_identity_vu_prepare_t4
SELECT SCOPE_IDENTITY()
SELECT @@IDENTITY
SELECT IDENT_CURRENT('test_identity_vu_prepare_t4')
GO

SELECT * FROM test_identity_vu_prepare_t5
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
