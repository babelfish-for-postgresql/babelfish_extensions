CREATE TABLE emp_salary(emp_id int, salary int);
GO

CREATE TABLE tbl_emp_salary(emp_id int, salary int);
GO

CREATE VIEW vw_emp_salary as SELECT * FROM tbl_emp_salary;
GO