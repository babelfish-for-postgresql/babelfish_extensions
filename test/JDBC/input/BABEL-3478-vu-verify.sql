SELECT * FROM BABEL_3478_t1
ORDER BY FirstName, LastName;
SELECT ROWCOUNT_BIG();
GO


-- Updating the salary of BABEL_3478_t1 with last name 'Doe'
UPDATE BABEL_3478_t1 SET Salary = 65000 WHERE LastName = 'Doe';
SELECT ROWCOUNT_BIG();
GO


-- Deleting BABEL_3478_t1 with last name 'Smith'
DELETE FROM BABEL_3478_t1 WHERE LastName = 'Smith';
SELECT ROWCOUNT_BIG();
GO


SELECT * FROM BABEL_3478_t1_InfoView;
GO


EXEC Insert_BABEL_3478_p1;
GO



SELECT * FROM Updated_BABEL_3478_InfoView;
GO

EXEC Update_BABEL_3478_Salary 'Doe', 700000;
GO

EXEC Delete_BABEL_3478_p2 'Doe';
GO