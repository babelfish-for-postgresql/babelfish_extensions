CREATE TABLE forjson_vu_t_people (
[Id] INT,
[FirstName] VARCHAR(25),
[LastName] VARCHAR(25),
[State] VARCHAR(25) )
GO

INSERT INTO forjson_vu_t_people values
(1,'Divya','Kumar',NULL),
(2,NULL,'Khanna','Bengaluru'),
(3,'Tom','Mehta','Kolkata'),
(4,'Kane',NULL,'Delhi')
GO

CREATE TABLE forjson_vu_t_countries (
[Id] INT,
[Age] INT,
[Country] VARCHAR(25))
GO

INSERT INTO forjson_vu_t_countries values
(1,25, 'India'),
(2,40, 'USA'),
(3,30, 'India'),
(4,20, NULL),
(5,10, 'USA')
GO

CREATE TABLE forjson_vu_t_values (
[Id] INT,
[value] VARCHAR(25) )
GO

INSERT INTO forjson_vu_t_values values
(1,NULL),
(2,NULL),
(3,NULL)
GO

-- FOR JSON PATH clause without nested support
CREATE VIEW forjson_vu_v_people AS
SELECT (
	SELECT Id AS EmpId, 
		   FirstName AS "Name.FirstName",
		   LastName AS  "Name.LastName",
		   State
	FROM forjson_vu_t_people
	FOR JSON PATH
) c1
GO

CREATE VIEW forjson_vu_v_countries AS
SELECT (
	SELECT Id, 
		   Age,
		   Country
	FROM forjson_vu_t_countries
	FOR JSON PATH
) c1
GO

-- Multiple tables without nested support
CREATE VIEW forjson_vu_v_join AS
SELECT (
	SELECT E.FirstName AS 'Person.Name',
		   E.LastName AS 'Person.Surname',
		   D.Age AS 'Employee.Price',
		   D.Country AS 'Employee.Quantity'
	FROM forjson_vu_t_people E
	   INNER JOIN forjson_vu_t_countries D
		 ON E.Id = D.Id
	FOR JSON PATH
) c1
GO

-- ROOT directive without specifying value
CREATE VIEW forjson_vu_v_root AS
SELECT (
	SELECT FirstName, 
		   LastName
	FROM forjson_vu_t_people
	FOR JSON PATH, ROOT
) c1
GO

-- ROOT directive with specifying ROOT value
CREATE VIEW forjson_vu_v_root_value AS
SELECT (
	SELECT FirstName, 
		   LastName
	FROM forjson_vu_t_people
	FOR JSON PATH, ROOT('Employee')
) c1
GO

-- ROOT directive with specifying ROOT value with empty string
CREATE VIEW forjson_vu_v_empty_root AS
SELECT (
	SELECT FirstName, 
		   LastName
	FROM forjson_vu_t_people
	FOR JSON PATH, ROOT('')
) c1
GO

-- WITHOUT_ARRAY_WRAPPERS directive
CREATE VIEW forjson_vu_v_without_array_wrapper AS
SELECT (
	SELECT FirstName, 
		   LastName
	FROM forjson_vu_t_people
	FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
) c1
GO

-- INCLUDE_NULL_VALUES directive
CREATE VIEW forjson_vu_v_include_null_values AS
SELECT (
	SELECT FirstName, 
		   LastName
	FROM forjson_vu_t_people
	FOR JSON PATH, INCLUDE_NULL_VALUES
) c1
GO

-- Multiple Directives
CREATE VIEW forjson_vu_v_root_include_null_values AS
SELECT (
	SELECT Id, 
		   Age,
		   Country
	FROM forjson_vu_t_countries
	FOR JSON PATH, ROOT('Employee'), INCLUDE_NULL_VALUES
) c1
GO

CREATE VIEW forjson_vu_v_without_array_wrapper_include_null_values AS
SELECT (
	SELECT Id, 
		   Age,
		   Country
	FROM forjson_vu_t_countries
	FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
) c1
GO

-- Throws error as ROOT and WITHOUT_ARRAY_WRAPPER cannot be used together
CREATE VIEW forjson_vu_v_root_and_without_array_wrapper AS
SELECT (
	SELECT Id, 
		   Age,
		   Country
	FROM forjson_vu_t_countries
	FOR JSON PATH, ROOT, WITHOUT_ARRAY_WRAPPER
) c1
GO

-- FOR JSON AUTO clause not supported
CREATE VIEW forjson_vu_v_auto AS
SELECT (
	SELECT Id,
		   State
	FROM forjson_vu_t_people
	FOR JSON AUTO
) c1
GO

-- Test case with parameters
CREATE PROCEDURE forjson_vu_p_params1 @id int AS
SELECT (
	SELECT Firstname AS [Name], 
		   State 
	FROM forjson_vu_t_people
	WHERE Id = @id
	FOR JSON PATH
) c1
GO

CREATE PROCEDURE forjson_vu_p_params2 @id int AS
SELECT (
	SELECT Firstname AS [nam"@e], 
		   State AS [State"@]
	FROM forjson_vu_t_people
	WHERE Id = @id
	FOR JSON PATH
) c1
GO

-- Alias/colname not present
CREATE VIEW forjson_vu_v_no_alias AS
SELECT (
	SELECT 2
	FOR JSON PATH
) c1
GO

-- All null values test
CREATE VIEW forjson_vu_v_nulls AS
SELECT (
	SELECT value
	FROM forjson_vu_t_values
	FOR JSON PATH
) c1
GO

-- Test for all parser rules
CREATE VIEW forjson_vu_v_order_by AS
SELECT (
	SELECT Id,
		   Age,
		   Country
	FROM forjson_vu_t_countries
	ORDER BY Age
	FOR JSON PATH
) C1
GO

CREATE VIEW forjson_vu_v_with AS
WITH forjson_vu_with1(avg_age) AS (
	SELECT avg(Age)
	FROM forjson_vu_t_countries
)
SELECT (
	SELECT Id, Age, Country
	FROM forjson_vu_t_countries, forjson_vu_with1
	WHERE Age >= forjson_vu_with1.avg_age
	FOR JSON PATH
) C1
GO

CREATE VIEW forjson_vu_v_with_order_by AS
WITH forjson_vu_with2(avg_age) AS (
	SELECT avg(Age)
	FROM forjson_vu_t_countries
)
SELECT (
	SELECT Id, Age, Country 
	FROM forjson_vu_t_countries, forjson_vu_with2
	WHERE Age >= forjson_vu_with2.avg_age
	ORDER BY Country
	FOR JSON PATH
) c1
GO

-- Test internal functions
CREATE VIEW forjson_vu_v_sfunc_internal AS
SELECT tsql_query_to_json_sfunc(
	NULL,
	row,
	1,
	FALSE,
	FALSE,
	NULL
)
FROM (SELECT TOP 1 * FROM forjson_vu_t_people) row
GO

CREATE VIEW forjson_vu_v_ffunc_internal AS
SELECT tsql_query_to_json_ffunc(
	'['
)
GO