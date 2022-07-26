--varchar
SELECT * FROM english_collation_varchar ORDER BY name;
GO

SELECT * FROM english_collation_varchar WHERE name LIKE 'n%';
GO
SELECT * FROM english_collation_varchar WHERE name LIKE 'n%i';
GO
SELECT * FROM english_collation_varchar WHERE name LIKE 'n%D%';
GO
SELECT * FROM english_collation_varchar WHERE name LIKE 'N%';
GO
SELECT * FROM english_collation_varchar WHERE name LIKE 'N%i';
GO
SELECT * FROM english_collation_varchar WHERE name LIKE 'N%D%';
GO

SELECT * FROM english_collation_varchar WHERE name='NeW deLHi';
GO
SELECT * FROM english_collation_varchar WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO

--inner join
CREATE VIEW [INNER JOIN SAME CP] AS
SELECT english_collation_varchar.name AS name, english_collation_varchar_innerjoin.name_same_cp AS same_name
FROM english_collation_varchar
INNER JOIN english_collation_varchar_innerjoin ON english_collation_varchar.name = english_collation_varchar_innerjoin.name_same_cp;
GO
SELECT * FROM [INNER JOIN SAME CP] WHERE same_name = 'new DelHI';
GO

CREATE VIEW [INNER JOIN DIFF CP] AS
SELECT english_collation_varchar.name AS name , english_collation_varchar_innerjoin.name_diff_cp AS diff_name
FROM english_collation_varchar
INNER JOIN english_collation_varchar_innerjoin ON english_collation_varchar.name = english_collation_varchar_innerjoin.name_diff_cp;
GO
SELECT * FROM [INNER JOIN DIFF CP] WHERE diff_name = 'NEW DELHI';
GO

--computed column
SELECT substr FROM english_collation_varchar_computed_columns;
GO
SELECT substr FROM english_collation_varchar_computed_columns;
GO
SELECT 
    name, 
    collation_name 
FROM sys.columns 
WHERE name = N'substr';
GO
--SELECT cast ( case when collation_name = 'latin1_general_ci_as' then 1 else 0 end as int) as cmp from sys.all_columns where name = 'substr';
--GO


--nvarchar
SELECT * FROM english_collation_nvarchar ORDER BY name;
GO

SELECT * FROM english_collation_nvarchar WHERE name LIKE 'n%';
GO
SELECT * FROM english_collation_nvarchar WHERE name LIKE 'n%i';
GO
SELECT * FROM english_collation_nvarchar WHERE name LIKE 'n%D%';
GO
SELECT * FROM english_collation_nvarchar WHERE name LIKE 'N%';
GO
SELECT * FROM english_collation_nvarchar WHERE name LIKE 'N%i';
GO
SELECT * FROM english_collation_nvarchar WHERE name LIKE 'N%D%';
GO

SELECT * FROM english_collation_nvarchar WHERE name='NeW deLHi';
GO
SELECT * FROM english_collation_nvarchar WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO

--char
SELECT * FROM english_collation_char ORDER BY name;
GO

SELECT * FROM english_collation_char WHERE name LIKE 'n%';
GO
SELECT * FROM english_collation_char WHERE name LIKE 'n%i';
GO
SELECT * FROM english_collation_char WHERE name LIKE 'n%D%';
GO
SELECT * FROM english_collation_char WHERE name LIKE 'N%';
GO
SELECT * FROM english_collation_char WHERE name LIKE 'N%i';
GO
SELECT * FROM english_collation_char WHERE name LIKE 'N%D%';
GO

SELECT * FROM english_collation_char WHERE name='NeW deLHi';
GO
SELECT * FROM english_collation_char WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO

--nchar
SELECT * FROM english_collation_nchar ORDER BY name;
GO

SELECT * FROM english_collation_nchar WHERE name LIKE 'n%';
GO
SELECT * FROM english_collation_nchar WHERE name LIKE 'n%i';
GO
SELECT * FROM english_collation_nchar WHERE name LIKE 'n%D%';
GO
SELECT * FROM english_collation_nchar WHERE name LIKE 'N%';
GO
SELECT * FROM english_collation_nchar WHERE name LIKE 'N%i';
GO
SELECT * FROM english_collation_nchar WHERE name LIKE 'N%D%';
GO

SELECT * FROM english_collation_nchar WHERE name='NeW deLHi';
GO
SELECT * FROM english_collation_nchar WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO

--text
SELECT * FROM english_collation_text ORDER BY name;
GO

SELECT * FROM english_collation_text WHERE name LIKE 'n%';
GO
SELECT * FROM english_collation_text WHERE name LIKE 'n%i';
GO
SELECT * FROM english_collation_text WHERE name LIKE 'n%D%';
GO
SELECT * FROM english_collation_text WHERE name LIKE 'N%';
GO
SELECT * FROM english_collation_text WHERE name LIKE 'N%i';
GO
SELECT * FROM english_collation_text WHERE name LIKE 'N%D%';
GO

SELECT * FROM english_collation_text WHERE name='NeW deLHi';
GO
SELECT * FROM english_collation_text WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO


--test for primary key
SELECT * FROM english_collation_primary_key ORDER BY name;
GO

SELECT * FROM english_collation_primary_key WHERE name LIKE 'NE%h%';
GO

SELECT * FROM english_collation_primary_key WHERE name = 'NeW deLHi';
GO
SELECT * FROM english_collation_primary_key WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO