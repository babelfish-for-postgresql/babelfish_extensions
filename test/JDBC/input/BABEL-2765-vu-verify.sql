SELECT name, collation_name FROM sys.all_columns WHERE name = 'non_computed1' or name = 'computed1' ORDER BY name
GO

SELECT name, collation_name FROM sys.all_columns WHERE name = 'non_computed2' or name = 'computed2' ORDER BY name
GO

SELECT name, collation_name FROM sys.all_columns WHERE name = 'non_computed3' or name = 'computed3' ORDER BY name
GO

SELECT name, collation_name FROM sys.all_columns WHERE name = 'non_computed4' or name = 'computed4' ORDER BY name
GO

ALTER TABLE babel_2765_t5 ADD computed5 AS substring(non_computed5, 1, 5) COLLATE SQL_Latin1_General_CP1_CI_AS
GO
SELECT name, collation_name FROM sys.all_columns WHERE name = 'non_computed5' or name = 'computed5' ORDER BY name
GO

ALTER TABLE babel_2765_t6 ADD computed6 AS substring(non_computed6, 1, 5) COLLATE SQL_Latin1_General_CP1_CI_AI
GO
SELECT name, collation_name FROM sys.all_columns WHERE name = 'non_computed6' or name = 'computed6' ORDER BY name
GO

ALTER TABLE babel_2765_t7 ADD computed7 AS substring(non_computed7, 1, 5)
GO
SELECT name, collation_name FROM sys.all_columns WHERE name = 'non_computed7' or name = 'computed7' ORDER BY name
GO

ALTER TABLE babel_2765_t8 ADD computed8 AS substring(non_computed8s, 1, 5)
GO
SELECT name, collation_name FROM sys.all_columns WHERE name = 'non_computed8' or name = 'computed8' ORDER BY name
GO