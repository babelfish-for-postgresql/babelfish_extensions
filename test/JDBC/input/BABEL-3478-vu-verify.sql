-- Test case 1: Verify that the function returns the expected number of rows affected after each insert, update, or delete statement.
INSERT INTO babel_3478 (FirstName, LastName, Salary)
VALUES ('Mary', 'Smith', 45000);
SELECT ROWCOUNT_BIG();
GO

UPDATE babel_3478 SET Salary = Salary * 1.1 WHERE LastName = 'Doe';
SELECT ROWCOUNT_BIG();
GO

DELETE FROM babel_3478 WHERE Salary < 55000;
SELECT ROWCOUNT_BIG();
GO

-- Test case 2: Verify that the function returns zero if no rows were affected by the last statement.
SELECT * FROM babel_3478 WHERE LastName = 'Johnson';
SELECT ROWCOUNT_BIG();
GO

-- Test case 3: Verify that the function returns the correct value if a large number of rows were affected.
INSERT INTO babel_3478 (FirstName, LastName, Salary)
SELECT FirstName, LastName, Salary FROM babel_3478;
SELECT ROWCOUNT_BIG();
GO

-- Test case 4: Verify that the function returns the correct value when used in a stored procedure that includes multiple SQL statements.
EXEC test_procedure;
GO

-- Test case 5: Verify that the function returns the correct value when used in a trigger that is executed as a result of an insert, update, or delete operation.
INSERT INTO babel_3478 (FirstName, LastName, Salary) VALUES ('Bob', 'Brown', 45000);
SELECT ROWCOUNT_BIG();
GO

-- Test case 6: Verify that the function returns the expected value when used in a transaction that is rolled back.
BEGIN TRANSACTION;
DELETE FROM babel_3478 WHERE Salary > 60000;
SELECT ROWCOUNT_BIG();
ROLLBACK
GO

-- Test case 7: Verify that the view returns a row count greater than 0.
SELECT * FROM babel_3478_View;
SELECT ROWCOUNT_BIG();
GO
