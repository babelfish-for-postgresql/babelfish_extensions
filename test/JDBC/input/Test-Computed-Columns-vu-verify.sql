INSERT INTO computed_column_vu_prepare_t1 VALUES('abcd');
SELECT * FROM computed_column_vu_prepare_t1;
GO

-- test whether other constraints are working with computed columns
INSERT INTO computed_column_vu_prepare_t1 VALUES('abcd'); -- throws error
GO

INSERT INTO computed_column_vu_prepare_t2 (a,c) VALUES (12, 12);
SELECT * FROM computed_column_vu_prepare_t2;
GO

-- should throw error - order matters
CREATE TABLE computed_column_vu_prepare_error (a INT, b  AS a/4 NOT NULL PERSISTED);
GO

-- should throw error if postgres syntax is used in TSQL dialect
CREATE TABLE computed_column_vu_prepare_error (a INT, b NUMERIC GENERATED ALWAYS AS (a/4) stored);
GO
-- should throw error if there is any error in computed column expression
CREATE TABLE computed_column_vu_prepare_error (a NVARCHAR(10), b  AS non_existant_function(a,1,3) UNIQUE NOT NULL);
GO
-- should throw error in case of nested computed columns
CREATE TABLE computed_column_vu_prepare_error (a INT, b AS c, c AS a);
CREATE TABLE computed_column_vu_prepare_error (a INT, b AS b + 1);
GO
-- in case of multiple computed column, the entire statement should be rolled
-- back even when the last one throws error
CREATE TABLE computed_column_vu_prepare_error (a INT, b AS a, c AS b);
SELECT * FROM computed_column_vu_prepare_error;
GO

-- ALTER TABLE... ADD <column_name> AS <computed_column_vu_prepare_expression>
--							  	    ^	[ PERSISTED ] <column constraints>)
ALTER TABLE computed_column_vu_prepare_t1 ADD c INT;
ALTER TABLE computed_column_vu_prepare_t1 ADD d AS c / 4;
INSERT INTO computed_column_vu_prepare_t1(a, c) VALUES ('efgh', 12);
SELECT * FROM computed_column_vu_prepare_t1;
GO

--should thow error in case of nested computed columns
ALTER TABLE computed_column_vu_prepare_t1 ADD e AS d;
ALTER TABLE computed_column_vu_prepare_t1 ADD E AS e + 1;
GO

-- should throw error if any of the dependant columns is modified or dropped.
ALTER TABLE computed_column_vu_prepare_t1 DROP column a;
ALTER TABLE computed_column_vu_prepare_t1 ALTER column a VARCHAR;
GO
-- should throw error as rand is non-deterministic
ALTER TABLE computed_column_vu_prepare_t1 ADD e AS rand() PERSISTED;
GO

-- but rand[seed] should succeed
ALTER TABLE computed_column_vu_prepare_t1 ADD e AS rand(1) PERSISTED;
GO

CREATE TABLE computed_column_vu_prepare_error(a int, b as rand() PERSISTED)
GO

--should error out inserting values into computed column
INSERT INTO computed_column_vu_prepare_t3 (DOB,AddDate) values ('01-01-2000','01-01-2000')
GO

ALTER TABLE computed_column_vu_prepare_t3 DROP COLUMN AddDate 
GO

--should fail since getdate is immutable
ALTER TABLE computed_column_vu_prepare_t3 ADD AddDate as GETDATE()
GO

INSERT INTO computed_column_vu_prepare_t4 (EmpNumb,Designation,DOBirth) values (84, 'DBA', '1985-12-13')
INSERT INTO computed_column_vu_prepare_t4 (EmpNumb,Designation,DOBirth) values (85, 'DBA', '1980-11-18')
INSERT INTO computed_column_vu_prepare_t4 (EmpNumb,Designation,DOBirth) values (86, 'Manager', '1978-01-19')
INSERT INTO computed_column_vu_prepare_t4 (EmpNumb,Designation,DOBirth) values (88, 'Manager', '1985-12-13')
INSERT INTO computed_column_vu_prepare_t4 (EmpNumb,Designation,DOBirth) values (90, 'Developer', '1975-07-23')
GO

SELECT Designation, DATEDIFF(yy,dobirth,doretirement ) AgeLimit, DOBirth, DORetirement FROM computed_column_vu_prepare_t4
GO

INSERT INTO computed_column_vu_prepare_t5 (Numerator, Denominator) VALUES (840, 12)
INSERT INTO computed_column_vu_prepare_t5 (Numerator, Denominator) VALUES (805, 6)
INSERT INTO computed_column_vu_prepare_t5 (Numerator, Denominator) VALUES (846, 3)
INSERT INTO computed_column_vu_prepare_t5 (Numerator, Denominator) VALUES (88, 0)
INSERT INTO computed_column_vu_prepare_t5 (Numerator, Denominator) VALUES (90, 15)
GO

SELECT * FROM computed_column_vu_prepare_t5
GO

INSERT INTO computed_column_vu_prepare_t6
SELECT 840, 12 UNION ALL
SELECT 805, 6 UNION ALL
SELECT 846, 13 UNION ALL
SELECT 88, 7 UNION ALL
SELECT 90, 15
GO

SELECT * FROM computed_column_vu_prepare_t6
GO

--using a UDF as computed column
--will fail with expression immutabe error
CREATE TABLE computed_column_vu_prepare_t7
  (
  EmpNumb INT NOT NULL,
  Designation VARCHAR(50) NOT NULL,
  LeaveBalance AS (computed_column_vu_prepare_func1(EmpNumb))
  )
GO

--immutable expression
CREATE TABLE computed_column_vu_prepare_t8
(
  FirstName VARCHAR(20),
  LastName VARCHAR(20),
  FullName AS CONCAT(FirstName,' ',LastName)
)
GO

INSERT INTO computed_column_vu_prepare_t9 (c)
SELECT 'Testing1' UNION ALL
SELECT 'Testing2' UNION ALL
SELECT 'Testing3' UNION ALL
SELECT 'Testing4' UNION ALL
SELECT 'Testing5'
GO

SELECT * FROM computed_column_vu_prepare_t9
GO

EXEC computed_column_vu_prepare_p1
GO

EXEC computed_column_vu_prepare_p2
GO

SELECT * FROM computed_column_vu_prepare_t9
GO
