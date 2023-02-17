-- Test case 1: Verify that the function returns the expected number of rows affected after each insert, update, or delete statement.
INSERT INTO Employee (FirstName, LastName, Salary)
VALUES ('Mary', 'Smith', 45000);
SELECT ROWCOUNT_BIG();
GO

UPDATE Employee SET Salary = Salary * 1.1 WHERE LastName = 'Doe';
SELECT ROWCOUNT_BIG();
GO

DELETE FROM Employee WHERE Salary < 55000;
SELECT ROWCOUNT_BIG();
GO

-- Test case 2: Verify that the function returns zero if no rows were affected by the last statement.
SELECT * FROM Employee WHERE LastName = 'Johnson';
SELECT ROWCOUNT_BIG();
GO

-- Test case 3: Verify that the function returns the correct value if a large number of rows were affected.
INSERT INTO Employee (FirstName, LastName, Salary)
SELECT FirstName, LastName, Salary FROM Employee;
SELECT ROWCOUNT_BIG();
GO

-- Test case 4: Verify that the function returns the correct value when used in a stored procedure that includes multiple SQL statements.
EXEC test_procedure;
GO

-- Test case 5: Verify that the function returns the correct value when used in a trigger that is executed as a result of an insert, update, or delete operation.
INSERT INTO Employee (FirstName, LastName, Salary) VALUES ('Bob', 'Brown', 45000);
SELECT ROWCOUNT_BIG();
GO

-- Test case 6: Verify that the function returns the expected value when used in a transaction that is rolled back.
BEGIN TRANSACTION;
DELETE FROM Employee WHERE Salary > 60000;
SELECT ROWCOUNT_BIG();
ROLLBACK
GO