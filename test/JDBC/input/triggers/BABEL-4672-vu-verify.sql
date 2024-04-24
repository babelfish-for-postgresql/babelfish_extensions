----------- Section 1 IOT INSERT Triggers
-- IOT INSERT TRIGGER  -> AFTER INSERT TRIGGER
CREATE TRIGGER tr_emp_salary_instead_insert ON emp_salary
INSTEAD OF INSERT
AS
INSERT INTO emp_salary VALUES(2, 2000);
GO

CREATE TRIGGER tr_emp_salary_after_insert ON emp_salary
AFTER INSERT
AS
INSERT INTO emp_salary VALUES(3, 3000);
GO

INSERT INTO emp_salary VALUES (1,1000);
GO

SELECT emp_id, salary FROM emp_salary ORDER BY emp_id;
GO

DROP TRIGGER tr_emp_salary_after_insert;
GO

DROP TRIGGER tr_emp_salary_instead_insert;
GO

-- IOT INSERT TRIGGER  -> AFTER UPDATE TRIGGER
CREATE TRIGGER tr_emp_salary_instead_insert ON emp_salary
INSTEAD OF INSERT
AS
UPDATE emp_salary SET salary = salary + 999 where emp_id = 2;
GO

CREATE TRIGGER tr_emp_salary_after_update ON emp_salary
AFTER UPDATE
AS
UPDATE emp_salary SET salary = salary + 9999 where emp_id = 2;
GO

INSERT INTO emp_salary VALUES (4,4000);
GO

SELECT emp_id, salary FROM emp_salary ORDER BY emp_id;
GO

DROP TRIGGER tr_emp_salary_after_update;
GO

DROP TRIGGER tr_emp_salary_instead_insert;
GO

-- IOT INSERT TRIGGER  -> AFTER DELETE TRIGGER
CREATE TRIGGER tr_emp_salary_instead_insert ON emp_salary
INSTEAD OF INSERT
AS
DELETE FROM emp_salary where emp_id = (SELECT emp_id from INSERTED);
GO

CREATE TRIGGER tr_emp_salary_after_delete ON emp_salary
AFTER DELETE
AS
DELETE FROM emp_salary where emp_id = (SELECT emp_id -1 from DELETED);
GO

INSERT INTO emp_salary VALUES (3,1000);
GO

SELECT emp_id, salary FROM emp_salary ORDER BY emp_id;
GO

DROP TRIGGER tr_emp_salary_after_delete;
GO

DROP TRIGGER tr_emp_salary_instead_insert;
GO

TRUNCATE TABLE emp_salary;
GO

----------- Section 2 IOT UPDATE Triggers
-- IOT UPDATE TRIGGER  -> AFTER INSERT TRIGGER
INSERT INTO emp_salary VALUES (1, 1000);
GO

CREATE TRIGGER tr_emp_salary_instead_update ON emp_salary
INSTEAD OF UPDATE
AS
INSERT INTO emp_salary VALUES(2, 2000);
GO

CREATE TRIGGER tr_emp_salary_after_insert ON emp_salary
AFTER INSERT
AS
INSERT INTO emp_salary VALUES(3, 3000);
GO

UPDATE emp_salary SET salary = salary + 5 where emp_id = 1;
GO

SELECT emp_id, salary FROM emp_salary ORDER BY emp_id;
GO

DROP TRIGGER tr_emp_salary_after_insert;
GO

DROP TRIGGER tr_emp_salary_instead_update;
GO

-- IOT UPDATE TRIGGER  -> AFTER UPDATE TRIGGER
CREATE TRIGGER tr_emp_salary_instead_update ON emp_salary
INSTEAD OF UPDATE
AS
UPDATE emp_salary SET salary = salary + 999 where emp_id = 2;
GO

CREATE TRIGGER tr_emp_salary_after_update ON emp_salary
AFTER UPDATE
AS
UPDATE emp_salary SET salary = salary + 9999 where emp_id = 2;
GO

UPDATE emp_salary SET salary = salary + 5 where emp_id = 2;
GO

SELECT emp_id, salary FROM emp_salary ORDER BY emp_id;
GO

DROP TRIGGER tr_emp_salary_after_update;
GO

DROP TRIGGER tr_emp_salary_instead_update;
GO

-- IOT UPDATE TRIGGER  -> AFTER DELETE TRIGGER
CREATE TRIGGER tr_emp_salary_instead_update ON emp_salary
INSTEAD OF UPDATE
AS
DELETE FROM emp_salary where emp_id = (SELECT emp_id from INSERTED)
GO

CREATE TRIGGER tr_emp_salary_after_delete ON emp_salary
AFTER DELETE
AS
DELETE FROM emp_salary where emp_id = (SELECT emp_id +1 from DELETED)
GO

UPDATE emp_salary SET salary = salary + 5 where emp_id = 1;
GO

SELECT emp_id, salary FROM emp_salary ORDER BY emp_id;
GO

DROP TRIGGER tr_emp_salary_after_delete;
GO

DROP TRIGGER tr_emp_salary_instead_update;
GO

TRUNCATE TABLE emp_salary;
GO

----------- Section 3 IOT DELETE Triggers
-- IOT DELETE TRIGGER -> AFTER INSERT TRIGGER
INSERT INTO emp_salary VALUES(1, 1000);
GO

CREATE TRIGGER tr_emp_salary_instead_delete ON emp_salary
INSTEAD OF DELETE
AS
INSERT INTO emp_salary VALUES(2, 2000);
GO

CREATE TRIGGER tr_emp_salary_after_insert ON emp_salary
AFTER INSERT
AS
INSERT INTO emp_salary VALUES(3, 3000);
GO

DELETE FROM emp_salary where emp_id = 1;
GO

SELECT emp_id, salary FROM emp_salary ORDER BY emp_id;
GO

DROP TRIGGER tr_emp_salary_after_insert;
GO

DROP TRIGGER tr_emp_salary_instead_delete;
GO

-- IOT DELETE TRIGGER  -> AFTER UPDATE TRIGGER
CREATE TRIGGER tr_emp_salary_instead_delete ON emp_salary
INSTEAD OF DELETE
AS
UPDATE emp_salary SET salary = salary + 999 where emp_id = 2;
GO

CREATE TRIGGER tr_emp_salary_after_update ON emp_salary
AFTER UPDATE
AS
UPDATE emp_salary SET salary = salary + 9999 where emp_id = 2;
GO

DELETE FROM emp_salary where emp_id = 1;
GO

SELECT emp_id, salary FROM emp_salary ORDER BY emp_id;
GO

DROP TRIGGER tr_emp_salary_after_update;
GO

DROP TRIGGER tr_emp_salary_instead_delete;
GO

-- IOT DELETE TRIGGER  -> AFTER DELETE TRIGGER
CREATE TRIGGER tr_emp_salary_instead_delete ON emp_salary
INSTEAD OF DELETE
AS
DELETE FROM emp_salary where emp_id = 2;
GO

CREATE TRIGGER tr_emp_salary_after_delete ON emp_salary
AFTER DELETE
AS
DELETE FROM emp_salary where emp_id = 3;
GO

DELETE FROM emp_salary where emp_id = 1;
GO

SELECT emp_id, salary FROM emp_salary ORDER BY emp_id;
GO

DROP TRIGGER tr_emp_salary_after_delete;
GO

DROP TRIGGER tr_emp_salary_instead_delete;
GO

TRUNCATE TABLE emp_salary;
GO