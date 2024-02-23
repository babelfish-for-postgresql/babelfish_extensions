DROP TABLE IF EXISTS emp_salary;
GO

CREATE TABLE emp_salary(emp_id int, salary int)
GO

----------- Section 1 IOT INSERT Triggers
CREATE trigger tr_emp_salary_instead_insert ON emp_salary
INSTEAD OF INSERT
AS
Print 'IOT before execution tr_emp_salary_instead_insert';
INSERT INTO emp_salary values(2, 2000);
Print 'IOT after execution tr_emp_salary_instead_insert';
GO

CREATE trigger tr_emp_salary_after_insert ON emp_salary
after INSERT
AS
Print 'AT before execution tr_emp_salary_after_insert';
INSERT INTO emp_salary values(3, 3000);
Print 'AT after execution tr_emp_salary_after_insert';
GO

-- IOT INSERT TRIGGER  -> AFTER INSERT TRIGGER
INSERT INTO emp_salary values (1,1000);
GO

SELECT emp_id, salary FROM emp_salary ORDER BY emp_id;
GO

DROP TRIGGER tr_emp_salary_after_insert;
GO

DROP TRIGGER tr_emp_salary_instead_insert;
GO

-- IOT1
CREATE trigger tr_emp_salary_instead_insert ON emp_salary
INSTEAD OF INSERT
AS
Print 'IOT before execution tr_emp_salary_instead_insert';
-- Q2
UPDATE emp_salary SET salary = salary+ 999 where emp_id=2;
Print 'IOT after execution tr_emp_salary_instead_insert';
GO

-- IOT INSERT TRIGGER  -> AFTER UPDATE TRIGGER
CREATE trigger tr_emp_salary_after_update ON emp_salary
AFTER UPDATE
AS
Print 'AT before execution tr_emp_salary_after_update';
UPDATE emp_salary SET salary = salary + 9999 where emp_id=2;
Print 'AT after execution tr_emp_salary_after_update';
GO

-- extra test case
-- IOT INSERT TRIGGER  -> AFTER UPDATE TRIGGER
INSERT INTO emp_salary values (1,1000);
GO

SELECT emp_id, salary FROM emp_salary ORDER BY emp_id;
GO

DROP TRIGGER tr_emp_salary_after_update;
GO

-- AT1
CREATE trigger tr_emp_salary_after_update ON emp_salary
AFTER UPDATE
AS
Print 'AT before execution tr_emp_salary_after_update';
-- Q3
INSERT INTO emp_salary values(4, 4000);
Print 'AT after execution tr_emp_salary_after_update';
GO

INSERT INTO emp_salary values (1,1000);
GO

SELECT emp_id, salary FROM emp_salary ORDER BY emp_id;
GO

DROP TRIGGER tr_emp_salary_after_update;
GO

DROP TRIGGER tr_emp_salary_instead_insert;
GO

-- IOT INSERT TRIGGER  -> AFTER DELETE TRIGGER
CREATE trigger tr_emp_salary_instead_insert ON emp_salary
INSTEAD OF INSERT
AS
Print 'IOT before execution tr_emp_salary_instead_insert';
-- Q2
DELETE FROM emp_salary where emp_id=2;
Print 'IOT after execution tr_emp_salary_instead_insert';
GO

CREATE trigger tr_emp_salary_after_delete ON emp_salary
AFTER DELETE
AS
Print 'AT before execution tr_emp_salary_after_delete';
-- Q3
DELETE FROM emp_salary where emp_id=3;
Print 'AT after execution tr_emp_salary_after_delete';
GO

-- Q1
INSERT INTO emp_salary values (1,1000);
GO

DROP TRIGGER tr_emp_salary_after_delete;
GO

DROP TRIGGER tr_emp_salary_instead_insert;
GO

TRUNCATE TABLE emp_salary;
GO

----------- Section 2 IOT UPDATE Triggers
-- IOT UPDATE TRIGGER ->AFTER INSERT TRIGGER

CREATE trigger tr_emp_salary_instead_update ON emp_salary
INSTEAD OF UPDATE
AS
Print 'IOT before execution tr_emp_salary_instead_update';
INSERT INTO emp_salary values(2, 2000);
Print 'IOT after execution tr_emp_salary_instead_update';
GO

CREATE trigger tr_emp_salary_after_insert ON emp_salary
after INSERT
AS
Print 'AT before execution tr_emp_salary_after_insert';
INSERT INTO emp_salary values(3, 3000);
Print 'AT after execution tr_emp_salary_after_insert';
GO

-- IOT UPDATE TRIGGER  -> AFTER INSERT TRIGGER
UPDATE emp_salary SET salary = salary + 5 where emp_id=2;
GO

DROP TRIGGER tr_emp_salary_after_insert;
GO

DROP TRIGGER tr_emp_salary_instead_update;
GO

CREATE trigger tr_emp_salary_instead_update ON emp_salary
INSTEAD OF UPDATE
AS
Print 'IOT before execution tr_emp_salary_instead_update';
UPDATE emp_salary SET salary = salary+ 999 where emp_id=2;
Print 'IOT after execution tr_emp_salary_instead_update';
GO

-- IOT UPDATE TRIGGER  -> AFTER UPDATE TRIGGER
CREATE trigger tr_emp_salary_after_update ON emp_salary
AFTER UPDATE
AS
Print 'AT before execution tr_emp_salary_after_update';
UPDATE emp_salary SET salary = salary + 9999 where emp_id=2;
Print 'AT after execution tr_emp_salary_after_update';
GO

-- IOT UPDATE TRIGGER  -> AFTER UPDATE TRIGGER
UPDATE emp_salary SET salary = salary + 5 where emp_id=2;
GO

DROP TRIGGER tr_emp_salary_after_update;
GO

DROP TRIGGER tr_emp_salary_instead_update;
GO

-- IOT UPDATE TRIGGER  -> AFTER DELETE TRIGGER
CREATE trigger tr_emp_salary_instead_update ON emp_salary
INSTEAD OF UPDATE
AS
Print 'IOT before execution tr_emp_salary_instead_update';
-- Q2
DELETE FROM emp_salary where emp_id=2;
Print 'IOT after execution tr_emp_salary_instead_update';
GO

CREATE trigger tr_emp_salary_after_delete ON emp_salary
AFTER DELETE
AS
Print 'AT before execution tr_emp_salary_after_delete';
-- Q3
DELETE FROM emp_salary where emp_id=3;
Print 'AT after execution tr_emp_salary_after_delete';
GO

UPDATE emp_salary SET salary = salary + 5 where emp_id=2;
GO

DROP TRIGGER tr_emp_salary_after_delete;
GO

DROP TRIGGER tr_emp_salary_instead_update;
GO

TRUNCATE TABLE emp_salary;
GO

----------- Section 3 IOT DELETE Triggers
-- IOT DELETE TRIGGER -> AFTER INSERT TRIGGER
INSERT INTO emp_salary values(1, 1000);
GO

CREATE trigger tr_emp_salary_instead_delete ON emp_salary
INSTEAD OF DELETE
AS
Print 'IOT before execution tr_emp_salary_instead_delete';
INSERT INTO emp_salary values(2, 2000);
Print 'IOT after execution tr_emp_salary_instead_delete';
GO

CREATE trigger tr_emp_salary_after_insert ON emp_salary
AFTER INSERT
AS
Print 'AT before execution tr_emp_salary_after_insert';
INSERT INTO emp_salary values(3, 3000);
Print 'AT after execution tr_emp_salary_after_insert';
GO

-- IOT DELETE TRIGGER -> AFTER INSERT TRIGGER
DELETE FROM emp_salary where emp_id=1;
GO

DROP TRIGGER tr_emp_salary_after_insert;
GO

DROP TRIGGER tr_emp_salary_instead_delete;
GO

-- IOT DELETE TRIGGER  -> AFTER UPDATE TRIGGER
CREATE trigger tr_emp_salary_instead_delete ON emp_salary
INSTEAD OF DELETE
AS
Print 'IOT before executiON tr_emp_salary_instead_delete';
UPDATE emp_salary SET salary = salary+ 999 where emp_id=2;
Print 'IOT after executiON tr_emp_salary_instead_delete';
GO

CREATE trigger tr_emp_salary_after_update ON emp_salary
AFTER UPDATE
AS
Print 'AT before executiON tr_emp_salary_after_update';
UPDATE emp_salary SET salary = salary + 9999 where emp_id=2;
Print 'AT after executiON tr_emp_salary_after_update';
GO

-- IOT DELETE TRIGGER  -> AFTER UPDATE TRIGGER
DELETE FROM emp_salary where emp_id=1;
GO

DROP TRIGGER tr_emp_salary_after_update;
GO

DROP TRIGGER tr_emp_salary_instead_delete;
GO

-- IOT DELETE TRIGGER  -> AFTER DELETE TRIGGER
CREATE trigger tr_emp_salary_instead_delete ON emp_salary
INSTEAD OF DELETE
AS
Print 'IOT before executiON tr_emp_salary_instead_delete';
-- Q2
DELETE FROM emp_salary where emp_id=2;
Print 'IOT after executiON tr_emp_salary_instead_delete';
GO

CREATE trigger tr_emp_salary_after_delete ON emp_salary
AFTER DELETE
AS
Print 'AT before execution tr_emp_salary_after_delete';
-- Q3
DELETE FROM emp_salary where emp_id=3;
Print 'AT after execution tr_emp_salary_after_delete';
GO

-- IOT DELETE TRIGGER  -> AFTER DELETE TRIGGER
DELETE FROM emp_salary where emp_id=1;
GO

DROP TRIGGER tr_emp_salary_after_delete;
GO

DROP TRIGGER tr_emp_salary_instead_delete;
GO

TRUNCATE TABLE emp_salary;
GO

----------- Section 4 Cases with views for INSERT and UPDATE

INSERT INTO emp_salary values (1, 11), (2, 12), (3, 13);
GO

CREATE VIEW vw_emp_salary as SELECT * FROM emp_salary;
GO

CREATE trigger tr_vw_emp_salary_instead
ON vw_emp_salary
INSTEAD OF INSERT, UPDATE
AS
INSERT INTO emp_salary SELECT emp_id, salary+999 FROM INSERTED
GO

CREATE trigger tr_emp_salary_instead
ON emp_salary
INSTEAD OF INSERT, UPDATE
AS
INSERT INTO emp_salary SELECT emp_id, salary+1000000 FROM INSERTED
GO

INSERT INTO vw_emp_salary values (7,7000);
GO

CREATE trigger tr_emp_salary_after
ON emp_salary
AFTER INSERT, UPDATE
AS
INSERT INTO emp_salary SELECT emp_id+100, salary+999 FROM INSERTED
GO

INSERT INTO vw_emp_salary values (8,1);
GO

UPDATE vw_emp_salary SET salary = salary + 500;
GO

SELECT emp_id, salary FROM vw_emp_salary ORDER BY emp_id, salary;
GO

DROP TRIGGER IF EXISTS tr_emp_salary_after;
GO

DROP TRIGGER IF EXISTS tr_emp_salary_instead;
GO

DROP TRIGGER IF EXISTS tr_vw_emp_salary_instead;
GO

----------- Section 5 Cases with views for DELETE
TRUNCATE TABLE emp_salary;
GO

INSERT INTO emp_salary values (1, 11), (2, 12), (3, 13), (4, 14);
GO

CREATE trigger tr_vw_emp_salary_instead_delete
ON vw_emp_salary
INSTEAD OF DELETE
AS
DELETE FROM emp_salary where emp_id = (SELECT emp_id from DELETED) + 1;
GO

CREATE trigger tr_emp_salary_instead_delete
ON emp_salary
INSTEAD OF DELETE
AS
DELETE FROM emp_salary where emp_id = (SELECT emp_id from DELETED) + 2;
GO

CREATE trigger tr_emp_salary_after
ON emp_salary
AFTER DELETE
AS
DELETE FROM emp_salary where emp_id = (SELECT emp_id from DELETED) + 3;
GO

SELECT emp_id, salary FROM vw_emp_salary ORDER BY emp_id, salary;
GO

DELETE FROM emp_salary where emp_id=1;
GO

SELECT emp_id, salary FROM vw_emp_salary ORDER BY emp_id, salary;
GO

DROP TRIGGER IF EXISTS tr_emp_salary_after_delete;
GO

DROP TRIGGER IF EXISTS tr_emp_salary_instead_delete;
GO

DROP TRIGGER IF EXISTS tr_vw_emp_salary_instead_delete;
GO

DROP VIEW IF EXISTS vw_emp_salary;
GO

DROP TABLE IF EXISTS emp_salary;
GO
