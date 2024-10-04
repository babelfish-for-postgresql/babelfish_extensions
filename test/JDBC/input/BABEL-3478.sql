-- Creating an Employee table
CREATE TABLE Employee (
    ID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Salary MONEY
);
GO
-- Inserting data into the Employee table
INSERT INTO Employee (FirstName, LastName, Salary)
VALUES ('John', 'Doe', 50000), ('Jane', 'Doe', 60000), ('Jim', 'Smith', 55000);
GO

-- Checking the number of inserted rows
SELECT ROWCOUNT_BIG();
GO

-- Updating the salary of employees with last name 'Doe'
UPDATE Employee SET Salary = 65000 WHERE LastName = 'Doe';
GO

-- Checking the number of updated rows
SELECT ROWCOUNT_BIG();
GO

-- Deleting employees with last name 'Smith'
DELETE FROM Employee WHERE LastName = 'Smith';
GO

-- Checking the number of deleted rows
SELECT ROWCOUNT_BIG();
GO
