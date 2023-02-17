CREATE TABLE BABEL_3478_t1 (
    ID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Salary MONEY
);
GO
-- Inserting data into the BABEL_3478_t1 table
INSERT INTO BABEL_3478_t1 (FirstName, LastName, Salary)
VALUES ('John', 'Doe', 50000), ('Jane', 'Doe', 60000), ('Jim', 'Smith', 55000);
GO

-- Checking the number of inserted rows
SELECT ROWCOUNT_BIG();
GO

-- Updating the salary of BABEL_3478_t1 with last name 'Doe'
UPDATE BABEL_3478_t1 SET Salary = 65000 WHERE LastName = 'Doe';
GO

-- Checking the number of updated rows
SELECT ROWCOUNT_BIG();
GO

-- Deleting BABEL_3478_t1 with last name 'Smith'
DELETE FROM BABEL_3478_t1 WHERE LastName = 'Smith';
GO

-- Checking the number of deleted rows
SELECT ROWCOUNT_BIG();
GO


CREATE VIEW BABEL_3478_t1_InfoView AS
SELECT ID, FirstName, LastName, Salary
FROM BABEL_3478_t1;
GO

CREATE PROCEDURE Insert_BABEL_3478_p1
AS
BEGIN
    -- Creating the BABEL_3478_t2 table
    CREATE TABLE BABEL_3478_t2 (
        ID INT PRIMARY KEY IDENTITY(1,1),
        FirstName VARCHAR(50),
        LastName VARCHAR(50),
        Salary MONEY
    );

    -- Inserting data into the BABEL_3478_t2 table
    INSERT INTO BABEL_3478_t2 (FirstName, LastName, Salary)
    VALUES ('John', 'Doe', 50000), ('Jane', 'Doe', 60000), ('Jim', 'Smith', 55000);
END;
GO


CREATE VIEW Updated_BABEL_3478_InfoView AS
SELECT ID, FirstName, LastName, Salary
FROM BABEL_3478_t1
WHERE LastName = 'Doe';
GO

CREATE PROCEDURE Update_BABEL_3478_Salary
    @LastName VARCHAR(50),
    @NewSalary MONEY
AS
BEGIN
    UPDATE BABEL_3478_t1
    SET Salary = @NewSalary 
    WHERE LastName = @LastName;
END
GO


CREATE PROCEDURE Delete_BABEL_3478_p2
  @LastName VARCHAR(50)
AS
BEGIN
  DELETE FROM BABEL_3478_t1 WHERE LastName = @LastName;
END;
GO


