CREATE TABLE computed_column_vu_prepare_t1 (a NVARCHAR(10), b  AS substring(a,1,3) UNIQUE NOT NULL);
GO

-- check PERSISTED keyword
-- should be able to use columns from left and right in the expression
CREATE TABLE computed_column_vu_prepare_t2 (a INT, b  AS (a + c) / 4 PERSISTED, c INT);
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

CREATE TABLE computed_column_vu_prepare_error(a int, b as rand() PERSISTED)
GO

CREATE TABLE computed_column_vu_prepare_t3
(
 DOB     DATE NOT NULL, 
 AddDate AS DATEADD(year,60,DOB), 
);
GO

CREATE TABLE computed_column_vu_prepare_t4
  (
  EmpNumb INT NOT NULL,
  Designation VARCHAR(50) NOT NULL,
  DOBirth DATETIME NOT NULL,
  DORetirement AS 
    CASE WHEN Designation = 'Manager' 
      THEN (DATEADD(YEAR,(65),[DOBirth]))
      ELSE (DATEADD(YEAR,(60),[DOBirth]))
    END
    PERSISTED
)
GO

INSERT INTO computed_column_vu_prepare_t4 (EmpNumb,Designation,DOBirth) values (84, 'DBA', '1985-12-13')
INSERT INTO computed_column_vu_prepare_t4 (EmpNumb,Designation,DOBirth) values (85, 'DBA', '1980-11-18')
INSERT INTO computed_column_vu_prepare_t4 (EmpNumb,Designation,DOBirth) values (86, 'Manager', '1978-01-19')
INSERT INTO computed_column_vu_prepare_t4 (EmpNumb,Designation,DOBirth) values (88, 'Manager', '1985-12-13')
INSERT INTO computed_column_vu_prepare_t4 (EmpNumb,Designation,DOBirth) values (90, 'Developer', '1975-07-23')
GO

CREATE TABLE computed_column_vu_prepare_t5
  (
  Numerator INT NOT NULL,
  Denominator INT NOT NULL,
  Result AS (Numerator/NULLIF(Denominator,0)) 
  )
GO

INSERT INTO computed_column_vu_prepare_t5 (Numerator, Denominator) VALUES (840, 12)
INSERT INTO computed_column_vu_prepare_t5 (Numerator, Denominator) VALUES (805, 6)
INSERT INTO computed_column_vu_prepare_t5 (Numerator, Denominator) VALUES (846, 3)
INSERT INTO computed_column_vu_prepare_t5 (Numerator, Denominator) VALUES (88, 0)
INSERT INTO computed_column_vu_prepare_t5 (Numerator, Denominator) VALUES (90, 15)
GO


CREATE TABLE computed_column_vu_prepare_t6
  (
  EmpNumb INT NOT NULL,
  LeavesAvailed TINYINT NOT NULL,
  EmpDep AS EmpNumb%10
  )
GO

INSERT INTO computed_column_vu_prepare_t6
SELECT 840, 12 UNION ALL
SELECT 805, 6 UNION ALL
SELECT 846, 13 UNION ALL
SELECT 88, 7 UNION ALL
SELECT 90, 15
GO

CREATE FUNCTION computed_column_vu_prepare_func1 (@EmpNumb int)
RETURNS TINYINT
WITH SCHEMABINDING
AS
BEGIN
  DECLARE @LeaveBalance TINYINT
  SELECT @LeaveBalance = (20 - LeavesAvailed) 
  FROM computed_column_vu_prepare_t6
  WHERE EmpNumb = @empnumb
  RETURN @LeaveBalance
END
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

CREATE TABLE computed_column_vu_prepare_t9
(
    A INT IDENTITY(1,1),
    B AS CAST(A AS FLOAT),
    C VARCHAR(20)
)
GO

INSERT INTO computed_column_vu_prepare_t9 (c)
SELECT 'Testing1' UNION ALL
SELECT 'Testing2' UNION ALL
SELECT 'Testing3' UNION ALL
SELECT 'Testing4' UNION ALL
SELECT 'Testing5'
GO

--should error using a computed column to generate computed column
CREATE PROCEDURE computed_column_vu_prepare_p1
AS
ALTER TABLE computed_column_vu_prepare_t9 add D as B/4 PERSISTED
GO

CREATE PROCEDURE computed_column_vu_prepare_p2
AS
ALTER TABLE computed_column_vu_prepare_t9 add D as A/4 PERSISTED
GO
