/*
*
* Below scenerios tried on both AUTO and PATH mode      
* For scenerios where auto Mode will fail, it is mentioned in expectation column. 
* Those scenerios not been supported yet.
* 
*            |              Scenerios                  |       Expectation 
* -----------------------------------------------------------------------------------------------------
* Test 1     |     FOR JSON - both AUTO & PATH mode    |         Escape 
* Test 2     |     JSON_QUERY                          |        Not escape         
* Test 3     |     JSON_QUERY + FOR JSON               |        Not escape
* Test 4     |     where clause                        |          Escape
* Test 5     |     Subquery                            |        PATH - Not Escape , AUTO - Fail
* Test 6     |     Comparison Operator                 |        Not Escape 
* Test 7     |     Union                               |        PATH - Not Escape , AUTO - Fail
* Test 8     |     Append String                       |          Escape
* Test 9     |     Views                               |        Not escape
* Test 10    |     Adding JSON_QUERY                   |          Escape
* Test 11    |     Complex Scenerios                   |        Not Escape , Fail for nested AUTO
* Test 12    |     Nested FOR JSON                     |        Escape only once 
* Test 13    |     Functions                           |          Escape
* Test 14    |     Stored Procedure                    |          Escape 
* Test 15    |     CAST                                |          Escape
* Test 16    |     Unicode Char                        |        Not Escape, support multi-language
* 
*/

---------------------------------------------      Test 1 - FOR JSON ONLY    -------------------------------------------------

select EmployeeDetails as json_auto FROM babel_5112_test1 FOR JSON AUTO;
go

select EmployeeDetails as json_without_array_wrapper FROM babel_5112_test1 for json path, WITHOUT_ARRAY_WRAPPER;
go

 
---------------------------------------------      Test 2  - JSON_QUERY ONLY    -------------------------------------------------


select JSON_QUERY(EmployeeDetails, '$.skills') as test_json_query from babel_5112_test2;
go
select JSON_QUERY(EmployeeDetails, '$.contact') as test_json_query from babel_5112_test2;
go
select JSON_QUERY(EmpId) as test_json_query from babel_5112_test2;
go
select JSON_QUERY(EmpID, '$.name') as test_json_query from babel_5112_test2;
go

---------------------------------------------      Test 3  - JSON_QUERY + FOR JSON ONLY    -------------------------------------------------

select JSON_QUERY(EmployeeDetails, '$.skills') as test_both from babel_5112_test3 for json auto;
go
select JSON_QUERY(EmployeeDetails, '$.contact') as test_both from babel_5112_test3 for json path;
go
select JSON_QUERY(EmpId) as test_both from babel_5112_test3 for json path, without_array_wrapper;
go
select JSON_QUERY(EmpID, '$.name') as test_both from babel_5112_test3 for json path, INCLUDE_NULL_VALUES;
go

SELECT 
    JSON_QUERY(empID, '$') AS 'employee.name',
    JSON_QUERY(EmployeeDetails, '$.contact') AS 'employee.contact.email'
FROM 
    babel_5112_test1
FOR JSON PATH
go

---------------------------------------------      Test 4  - where clause   -------- -------------------------------------------------

SELECT  ID, EmployeeDetails as non_json_query_col , JSON_QUERY(EmpID) as json_query_col FROM babel_5112_test4
WHERE JSON_QUERY(EmployeeDetails, '$.skills')  = '["C++"]'  
for json path;
go

SELECT  ID, EmployeeDetails as non_json_query_col , JSON_QUERY(EmpID) as json_query_col FROM babel_5112_test4
WHERE JSON_QUERY(EmployeeDetails, '$.skills')  = '["C++"]'  
for json auto, without_array_wrapper;
go

---------------------------------------------      Test 5  - Subquery check    -------------------------------------------------

SELECT ID, child.child_col as json_query_parent_col 
from 
  (select ID ,JSON_QUERY(EmployeeDetails,'$.contact') as child_col from babel_5112_test5 ) child
FOR JSON PATH;
go

SELECT 
    ID, 
    (SELECT JSON_QUERY(EmployeeDetails, '$.contact') as child_col FROM babel_5112_test5 e1 WHERE e1.id = e2.id) as parent_json_query_col
FROM 
    babel_5112_test5 e2
FOR JSON PATH;
go

-- FAIL (KNOWN CASE)
SELECT ID, child.child_col as json_query_parent_col 
from 
  (select ID ,JSON_QUERY(EmployeeDetails,'$.contact') as child_col from babel_5112_test5 ) child
FOR JSON AUTO;
go

-- FAIL (KNOWN CASE)
SELECT ID, child.child_col as json_query_parent_col
from
  (select ID, JSON_QUERY(EmployeeDetails, '$.contact') as child_col from babel_5112_test5) child)
SELECT 
    ID, 
    (SELECT JSON_QUERY(EmployeeDetails, '$.contact') as child_col FROM babel_5112_test5 e1 WHERE e1.id = e2.id) as parent_json_query_col
FROM 
    babel_5112_test5 e2
FOR JSON AUTO;
go

---------------------------------------------      Test 6  - Comparator Op    -------------------------------------------------

select
case when JSON_QUERY(EmployeeDetails,'$.skills') > '["C++"]' then '["yes"]' else '["no"]' end as cmp_json_query 
from babel_5112_test6
for json auto; 
go

SELECT CASE WHEN JSON_QUERY(EmployeeDetails, '$.skills') = '["C++"]' THEN 'true' ELSE 'false' END AS compare_using_json_query FROM babel_5112_test6 FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
go

---------------------------------------------      Test 7  - Union   -----------------------------------------------------------

select top 1 * from (
    SELECT JSON_QUERY(EmployeeDetails, '$.skills') as test_union FROM babel_5112_test7
    UNION
    SELECT JSON_QUERY(EmployeeDetails, '$.contact') as test_union FROM babel_5112_test7
) as union_query
order by test_union
FOR JSON PATH;
go

--FAIL (KNOWN CASE)
select * from (
    SELECT JSON_QUERY(EmployeeDetails, '$.skills') as test_union FROM babel_5112_test7
    UNION 
    SELECT JSON_QUERY(EmployeeDetails, '$.contact') as test_union FROM babel_5112_test7
) as union_query
FOR JSON AUTO;
go

---------------------------------------------      Test 8  - Append String to JSON_QUERY    -------------------------------------------------

select JSON_QUERY(EmpID,'$') + 'add' as test_append from babel_5112_test8 for json path;
go

select JSON_QUERY(EmpID,'$') + 'add' as test_append from babel_5112_test8 for json auto;
go

---------------------------------------------      Test 9  - Views      ---------------------------------------------------------------


SELECT * FROM test_babel_5112_view FOR JSON PATH;
GO

SELECT * FROM test_babel_5112_view FOR JSON AUTO;
GO

---------------------------------------------      Test 10  - Adding JSON_QUERY      -----------------------------------------------------------

select JSON_QUERY(EmpID) + JSON_QUERY(EmployeeDetails) as add_json_query from babel_5112_test10 for json path;
GO

---------------------------------------------      Test 11  - Complex Cases      ----------------------------------------------------------------

SELECT 
    ID,
    JSON_QUERY(
        (SELECT name = JSON_VALUE(e2.EmpID, '$.name')
         FROM babel_5112_test11 e2 
         WHERE e2.ID = e1.ID 
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    ) as employee_info
FROM babel_5112_test11 e1
FOR JSON PATH;
GO

-- FAIL ( KNOWN CASE )
SELECT 
    ID,
    JSON_QUERY(
        (SELECT name = JSON_VALUE(e2.EmpID, '$.name')
         FROM babel_5112_test11 e2 
         WHERE e2.ID = e1.ID 
         FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER)
    ) as employee_info
FROM babel_5112_test11 e1
FOR JSON AUTO;
GO

SELECT 
    ID,
    JSON_QUERY(
        (SELECT name = JSON_VALUE(e2.EmpID, '$.name')
         FROM babel_5112_test11 e2 
         WHERE e2.ID = e1.ID 
         FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER)
    ) as employee_info
FROM babel_5112_test11 e1
FOR JSON PATH;
GO

---------------------------------------------      Test 12  - Nested FOR JSON      -----------------------------------------------------------

SELECT 
    ID,
    (select JSON_QUERY( EmployeeDetails, '$.contact') as inside_json_path from babel_5112_test12 FOR JSON AUTO ) as test_nested_for_json
FROM babel_5112_test12
FOR JSON PATH;
go

SELECT 
    ID,
    (select JSON_QUERY( EmployeeDetails, '$.contact') as inside_json_path from babel_5112_test12 FOR JSON AUTO ) as test_nested_for_json
FROM babel_5112_test12
FOR JSON AUTO;
go

---------------------------------------------      Test 13 - Functions      --------------------------------------------------------------

CREATE FUNCTION dbo.GetEmployeeSkills
(
    @EmployeeID INT
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN (
        SELECT JSON_QUERY(EmployeeDetails, '$.skills')
        FROM babel_5112_test13
        WHERE ID = @EmployeeID
    );
END;
GO

SELECT e.ID, dbo.GetEmployeeSkills(e.ID) AS skills
FROM  babel_5112_test13 e
FOR JSON PATH;
go

---------------------------------------------      Test 14 -  Stored Procedure      --------------------------------------------------------------

CREATE PROCEDURE GetEmployeeBasicInfo
    @EmployeeID INT
AS
BEGIN
    SELECT ID, JSON_QUERY(EmployeeDetails, '$.skills') AS skills 
    FROM babel_5112_test14 
    WHERE ID = @EmployeeID
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
END;
GO

-- Execute the procedure and get the JSON result directly
EXEC GetEmployeeBasicInfo @EmployeeID = 1;
GO

---------------------------------------------      Test 15 - CAST      --------------------------------------------------------------

select CAST(JSON_QUERY(EmployeeDetails, '$.skills') AS NVARCHAR(100) ) as test_cast from babel_5112_test15 for json PATH;
go
select CAST(JSON_QUERY(EmployeeDetails, '$.skills') AS VARCHAR(100) ) as test_cast from babel_5112_test15 for json AUTO;
go

---------------------------------------------      Test 16 -  Testing Nvarchar Unicode      --------------------------------------------------------------

SELECT 
    JSON_QUERY(EmployeeDetails, '$.skills') as skills,
    JSON_VALUE(EmployeeDetails, '$.skills[0]') as first_skill
FROM  babel_5112_test16 FOR JSON AUTO;
GO

SELECT 
    JSON_QUERY(EmployeeDetails, '$.skills') as skills,
    JSON_VALUE(EmployeeDetails, '$.skills[0]') as first_skill
FROM  babel_5112_test16 FOR JSON PATH;
go

--------------------------------------------   Test 17 - Testing Nvarchar_JSON Casting  -----------------------------------------------

select CAST(JSON_QUERY(EmployeeDetails) as nvarchar_json) as test_cast from babel_5112_test16;
go