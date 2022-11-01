CREATE TABLE babel_3407_table1 (
[id] INT,
[name] VARCHAR(25),
[state] VARCHAR(25) );
GO

INSERT INTO babel_3407_table1 values
(1,'Divya',NULL),
(2,'Akshay','Bengaluru'),
(3,'Kavya','Kolkata');
GO

-- FOR JSON PATH clause
CREATE VIEW babel_3407_view1 AS
SELECT id, name, state
FROM babel_3407_table1
FOR JSON PATH;
GO

-- ROOT directive without specifying value
CREATE VIEW babel_3407_view2 AS
SELECT name, state
FROM babel_3407_table1
FOR JSON PATH, ROOT;
GO

-- ROOT directive with specifying ROOT value
CREATE VIEW babel_3407_view3 AS
SELECT name, state
FROM babel_3407_table1
FOR JSON PATH, ROOT('Employee');
GO

-- WITHOUT_ARRAY_WRAPPERS directive
CREATE VIEW babel_3407_view4 AS
SELECT name, state
FROM babel_3407_table1
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
GO

-- INCLUDE_NULL_VALUES directive
CREATE VIEW babel_3407_view5 AS
SELECT name, state
FROM babel_3407_table1
FOR JSON PATH, INCLUDE_NULL_VALUES;
GO

-- Multiple Directives
CREATE VIEW babel_3407_view6 AS
SELECT id, name, state
FROM babel_3407_table1
FOR JSON PATH, ROOT('Employee'), INCLUDE_NULL_VALUES;
GO

CREATE VIEW babel_3407_view7 AS
SELECT id, name, state
FROM babel_3407_table1
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES;
GO

-- Throws error as ROOT and WITHOUT_ARRAY_WRAPPER cannot be used together
CREATE VIEW babel_3407_view8 AS
SELECT id, name, state
FROM babel_3407_table1
FOR JSON PATH, ROOT, WITHOUT_ARRAY_WRAPPER;
GO

-- FOR JSON AUTO clause not supported
CREATE VIEW babel_3407_view9 AS
SELECT id, name, state
FROM babel_3407_table1
FOR JSON AUTO;
GO

-- Test for explicit call to the function
CREATE VIEW explicit_call_view AS
SELECT tsql_query_to_json_text('SELECT 2+2 AS TEST', 1, FALSE,FALSE,FALSE,'');
GO
