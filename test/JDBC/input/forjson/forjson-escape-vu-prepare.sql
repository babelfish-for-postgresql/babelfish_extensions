/*
BABEL - 5112 - FOR JSON unnecessarily adds escape character to JSON_QUERY Output

           |              Scenerios                  |               Explain 
Test 1     |     FOR JSON - both AUTO & PATH mode    |      Testing both mode of "for json" + without_array_wrapper
Test 2     |     JSON_QUERY                          |      Testing Extraction of Json, Array both using JSON_QUERY only 
Test 3     |     JSON_QUERY + FOR JSON               |      Testing JSON_QUERY and FOR JSON both in single query              
Test 4     |     where clause                        |      Testing JSON_QUERY in where clause with FOR JSON
Test 5     |     Subquery                            |      Testing parent column reference from JSON_QUERY in subquery query
Test 6     |     Comparison Operator                 |      Testing JSON_QUERY in comparison operator with FOR JSON       
Test 7     |     Union                               |      Testing JSON_QUERY in union with FOR JSON    
Test 8     |     Append String                       |      Testing JSON_QUERY + string with FOR JSON
Test 9     |     Views                               |      Testing JSON_QUERY in views with FOR JSON
Test 10    |     Adding JSON_QUERY                   |      Testing JSON_QUERY + JSON_QUERY
Test 11    |     Complex Scenerios                   |      Testing JSON_QUERY( FOR JSON INSIDE ) + FOR JSON OUTSIDE
Test 12    |     Nestes FOR JSON                     |      Te sting Double FOR JSON to check multiple escape character issue
Test 13    |     Functions                           |      Testing Functions
Test 14    |     Stored Procedure                    |      Testing Stored Procedure
Test 15    |     CAST                                |      Testing different cast function on JSON_QUERY
Test 16    |     Unicode Char                        |      Testing different chars for NVARCHAR
*/


CREATE TABLE babel_5112_test1( ID INT PRIMARY KEY, EmpId VARCHAR(100), EmployeeDetails NVARCHAR(MAX) );
INSERT INTO babel_5112_test1 (ID, EmpID, EmployeeDetails) VALUES (1,'{"name": "Naruto", "age": 25}', N'{"name": "Sasuke", "age": 28}');
INSERT INTO babel_5112_test1 (ID, EmpID, EmployeeDetails) VALUES (2,'{"name": "Uchiha", "age": 35}', N'{"name": "Ken kaneki", "age": 35}');
GO

CREATE TABLE babel_5112_test2( ID INT PRIMARY KEY, EmpId VARCHAR(100), EmployeeDetails NVARCHAR(MAX) );
INSERT INTO babel_5112_test2 (ID, EmpID, EmployeeDetails) VALUES (1,'{"name": "Naruto", "age": 17}', N'{"skills": ["SQL", "Python"] , "contact": {"email": "naruto@example.com", "phone": "123-456-7890"}}');
INSERT INTO babel_5112_test2 (ID, EmpID, EmployeeDetails) VALUES (2,'{"name": "Sasuke", "age": 19}', N'{"skills": ["C++"] , "contact": {"email": "sasuke@example.com", "phone": "923-456-777"}}');
GO

CREATE TABLE babel_5112_test3( ID INT PRIMARY KEY, EmpId VARCHAR(100), EmployeeDetails NVARCHAR(MAX) );
INSERT INTO babel_5112_test3 (ID, EmpID, EmployeeDetails) VALUES (1,'{"name": "Naruto", "age": 17}', N'{"skills": ["SQL", "Python"] , "contact": {"email": "naruto@example.com", "phone": "123-456-7890"}}');
INSERT INTO babel_5112_test3 (ID, EmpID, EmployeeDetails) VALUES (2,'{"name": "Sasuke", "age": 19}', N'{"skills": ["C++"] , "contact": {"email": "sasuke@example.com", "phone": "923-456-777"}}');
GO

CREATE TABLE babel_5112_test4( ID INT PRIMARY KEY, EmpId NVARCHAR(100), EmployeeDetails VARCHAR(MAX) );
INSERT INTO babel_5112_test4 (ID, EmpID, EmployeeDetails) VALUES (1,N'{"name": "Naruto", "age": 17}', '{"skills": ["SQL", "Python"] , "contact": {"email": "naruto@example.com", "phone": "123-456-7890"}}');
INSERT INTO babel_5112_test4 (ID, EmpID, EmployeeDetails) VALUES (2,N'{"name": "Sasuke", "age": 19}', '{"skills": ["C++"] , "contact": {"email": "sasuke@example.com", "phone": "923-456-777"}}');
GO

CREATE TABLE babel_5112_test5( ID INT PRIMARY KEY, EmpId VARCHAR(100), EmployeeDetails VARCHAR(MAX) );
INSERT INTO babel_5112_test5 (ID, EmpID, EmployeeDetails) VALUES (1,'{"name": "Naruto", "age": 17}', '{"skills": ["SQL", "Python"] , "contact": {"email": "naruto@example.com", "phone": "123-456-7890"}}');
INSERT INTO babel_5112_test5 (ID, EmpID, EmployeeDetails) VALUES (2,'{"name": "Sasuke", "age": 19}', '{"skills": ["C++"] , "contact": {"email": "sasuke@example.com", "phone": "923-456-777"}}');
GO

CREATE TABLE babel_5112_test6( ID INT PRIMARY KEY, EmpId VARCHAR(100), EmployeeDetails VARCHAR(MAX) );
INSERT INTO babel_5112_test6 (ID, EmpID, EmployeeDetails) VALUES (1,'{"name": "Naruto", "age": 17}', '{"skills": ["SQL", "Python"] , "contact": {"email": "naruto@example.com", "phone": "123-456-7890"}}');
INSERT INTO babel_5112_test6 (ID, EmpID, EmployeeDetails) VALUES (2,'{"name": "Sasuke", "age": 19}', '{"skills": ["C++"] , "contact": {"email": "sasuke@example.com", "phone": "923-456-777"}}');
GO

CREATE TABLE babel_5112_test7( ID INT PRIMARY KEY, EmpId VARCHAR(100), EmployeeDetails VARCHAR(MAX) );
INSERT INTO babel_5112_test7 (ID, EmpID, EmployeeDetails) VALUES (1,'{"name": "Naruto", "age": 17}', '{"skills": ["SQL", "Python"] , "contact": {"email": "naruto@example.com", "phone": "123-456-7890"}}');
INSERT INTO babel_5112_test7 (ID, EmpID, EmployeeDetails) VALUES (2,'{"name": "Sasuke", "age": 19}', '{"skills": ["C++"] , "contact": {"email": "sasuke@example.com", "phone": "923-456-777"}}');
GO

CREATE TABLE babel_5112_test8( ID INT PRIMARY KEY, EmpId NVARCHAR(100), EmployeeDetails VARCHAR(MAX) );
INSERT INTO babel_5112_test8 (ID, EmpID, EmployeeDetails) VALUES (1, N'{"name": "Naruto", "age": 17}', '{"skills": ["SQL", "Python"] , "contact": {"email": "naruto@example.com", "phone": "123-456-7890"}}');
INSERT INTO babel_5112_test8 (ID, EmpID, EmployeeDetails) VALUES (2, N'{"name": "Sasuke", "age": 19}', '{"skills": ["C++"] , "contact": {"email": "sasuke@example.com", "phone": "923-456-777"}}');
GO

CREATE TABLE babel_5112_test9( ID INT PRIMARY KEY, EmpId VARCHAR(100), EmployeeDetails NVARCHAR(MAX) );
INSERT INTO babel_5112_test9 (ID, EmpID, EmployeeDetails) VALUES (1, '{"name": "Naruto", "age": 17}', N'{"skills": ["SQL", "Python"] , "contact": {"email": "naruto@example.com", "phone": "123-456-7890"}}');
INSERT INTO babel_5112_test9 (ID, EmpID, EmployeeDetails) VALUES (2, '{"name": "Sasuke", "age": 19}', N'{"skills": ["C++"] , "contact": {"email": "sasuke@example.com", "phone": "923-456-777"}}');
GO

CREATE VIEW test_babel_5112_view AS
WITH escape_issue_cte AS (
    SELECT JSON_QUERY(EmpID) AS json_query_col FROM babel_5112_test9
)
SELECT * 
FROM (
    SELECT json_query_col from escape_issue_cte
) AS p;
GO


CREATE TABLE babel_5112_test10( ID INT PRIMARY KEY, EmpId VARCHAR(100), EmployeeDetails NVARCHAR(MAX) );
INSERT INTO babel_5112_test10 (ID, EmpID, EmployeeDetails) VALUES (1,'{"name": "Naruto", "age": 17}', N'{"skills": ["SQL", "Python"] , "contact": {"email": "naruto@example.com", "phone": "123-456-7890"}}');
INSERT INTO babel_5112_test10 (ID, EmpID, EmployeeDetails) VALUES (2,'{"name": "Sasuke", "age": 19}', N'{"skills": ["C++"] , "contact": {"email": "sasuke@example.com", "phone": "923-456-777"}}');
GO

CREATE TABLE babel_5112_test11( ID INT PRIMARY KEY, EmpId VARCHAR(100), EmployeeDetails NVARCHAR(MAX) );
INSERT INTO babel_5112_test11 (ID, EmpID, EmployeeDetails) VALUES (1,'{"name": "Naruto", "age": 17}', N'{"skills": ["SQL", "Python"] , "contact": {"email": "naruto@example.com", "phone": "123-456-7890"}}');
INSERT INTO babel_5112_test11 (ID, EmpID, EmployeeDetails) VALUES (2,'{"name": "Sasuke", "age": 19}', N'{"skills": ["C++"] , "contact": {"email": "sasuke@example.com", "phone": "923-456-777"}}');
GO

CREATE TABLE babel_5112_test12( ID INT PRIMARY KEY, EmpId VARCHAR(100), EmployeeDetails NVARCHAR(MAX) );
INSERT INTO babel_5112_test12 (ID, EmpID, EmployeeDetails) VALUES (1,'{"name": "Naruto", "age": 17}', N'{"skills": ["SQL", "Python"] , "contact": {"email": "naruto@example.com", "phone": "123-456-7890"}}');
INSERT INTO babel_5112_test12 (ID, EmpID, EmployeeDetails) VALUES (2,'{"name": "Sasuke", "age": 19}', N'{"skills": ["C++"] , "contact": {"email": "sasuke@example.com", "phone": "923-456-777"}}');
GO

CREATE TABLE babel_5112_test13( ID INT PRIMARY KEY, EmpId VARCHAR(100), EmployeeDetails NVARCHAR(MAX) );
INSERT INTO babel_5112_test13 (ID, EmpID, EmployeeDetails) VALUES (1,'{"name": "Naruto", "age": 17}', N'{"skills": ["SQL", "Python"] , "contact": {"email": "naruto@example.com", "phone": "123-456-7890"}}');
INSERT INTO babel_5112_test13 (ID, EmpID, EmployeeDetails) VALUES (2,'{"name": "Sasuke", "age": 19}', N'{"skills": ["C++"] , "contact": {"email": "sasuke@example.com", "phone": "923-456-777"}}');
GO

CREATE TABLE babel_5112_test14( ID INT PRIMARY KEY, EmpId VARCHAR(100), EmployeeDetails NVARCHAR(MAX) );
INSERT INTO babel_5112_test14 (ID, EmpID, EmployeeDetails) VALUES (1,'{"name": "Naruto", "age": 17}', N'{"skills": ["SQL", "Python"] , "contact": {"email": "naruto@example.com", "phone": "123-456-7890"}}');
INSERT INTO babel_5112_test14 (ID, EmpID, EmployeeDetails) VALUES (2,'{"name": "Sasuke", "age": 19}', N'{"skills": ["C++"] , "contact": {"email": "sasuke@example.com", "phone": "923-456-777"}}');
GO

CREATE TABLE babel_5112_test15( ID INT PRIMARY KEY, EmpId VARCHAR(100), EmployeeDetails NVARCHAR(MAX) );
INSERT INTO babel_5112_test15 (ID, EmpID, EmployeeDetails) VALUES (1,'{"name": "Naruto", "age": 17}', N'{"skills": ["SQL", "Python"] , "contact": {"email": "naruto@example.com", "phone": "123-456-7890"}}');
INSERT INTO babel_5112_test15 (ID, EmpID, EmployeeDetails) VALUES (2,'{"name": "Sasuke", "age": 19}', N'{"skills": ["C++"] , "contact": {"email": "sasuke@example.com", "phone": "923-456-777"}}');
GO

CREATE TABLE babel_5112_test16( EmployeeDetails NVARCHAR(MAX) );
INSERT INTO babel_5112_test16 (EmployeeDetails) VALUES (N'{"skills": ["SQL", "Python", "日本語", "Español"]}'),(N'{"skills": ["C++", "русский язык", "中文"]}'), (N'{"skills": ["JavaScript", "العربية", "हिन्दी"]}');
GO