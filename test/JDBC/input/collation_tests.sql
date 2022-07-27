--varchar
CREATE TABLE collation_tests_english_collation_varchar (name varchar(20) COLLATE latin1_general_ci_as);
GO
INSERT INTO collation_tests_english_collation_varchar VALUES ('new delhi');
INSERT INTO collation_tests_english_collation_varchar VALUES ('new Delhi');
INSERT INTO collation_tests_english_collation_varchar VALUES ('new DELHI');
INSERT INTO collation_tests_english_collation_varchar VALUES ('NEW delhi');
INSERT INTO collation_tests_english_collation_varchar VALUES ('NEW Delhi');
INSERT INTO collation_tests_english_collation_varchar VALUES ('NEW DELHI');
INSERT INTO collation_tests_english_collation_varchar VALUES ('New delhi');
INSERT INTO collation_tests_english_collation_varchar VALUES ('New Delhi');
INSERT INTO collation_tests_english_collation_varchar VALUES ('New DELHI');
GO

SELECT * FROM collation_tests_english_collation_varchar ORDER BY name;
GO

SELECT * FROM collation_tests_english_collation_varchar WHERE name LIKE 'n%';
GO
SELECT * FROM collation_tests_english_collation_varchar WHERE name LIKE 'n%i';
GO
SELECT * FROM collation_tests_english_collation_varchar WHERE name LIKE 'n%D%';
GO
SELECT * FROM collation_tests_english_collation_varchar WHERE name LIKE 'N%';
GO
SELECT * FROM collation_tests_english_collation_varchar WHERE name LIKE 'N%i';
GO
SELECT * FROM collation_tests_english_collation_varchar WHERE name LIKE 'N%D%';
GO

SELECT * FROM collation_tests_english_collation_varchar WHERE name='NeW deLHi';
GO
SELECT * FROM collation_tests_english_collation_varchar WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO

-- table for inner join
CREATE TABLE collation_tests_english_collation_varchar_innerjoin(name_same_cp varchar(20) COLLATE latin1_general_ci_as, 
name_diff_cp varchar(20) COLLATE sql_latin1_general_cp1250_cs_as);
GO
INSERT INTO collation_tests_english_collation_varchar_innerjoin VALUES ('new delhi', 'new delhi');
INSERT INTO collation_tests_english_collation_varchar_innerjoin VALUES ('new Delhi', 'new Delhi');
INSERT INTO collation_tests_english_collation_varchar_innerjoin VALUES ('new DELHI', 'new DELHI');
INSERT INTO collation_tests_english_collation_varchar_innerjoin VALUES ('NEW delhi', 'NEW delhi');
INSERT INTO collation_tests_english_collation_varchar_innerjoin VALUES ('NEW Delhi', 'NEW Delhi');
INSERT INTO collation_tests_english_collation_varchar_innerjoin VALUES ('NEW DELHI', 'NEW DELHI');
INSERT INTO collation_tests_english_collation_varchar_innerjoin VALUES ('New delhi', 'New delhi');
INSERT INTO collation_tests_english_collation_varchar_innerjoin VALUES ('New Delhi', 'New Delhi');
INSERT INTO collation_tests_english_collation_varchar_innerjoin VALUES ('New DELHI', 'New DELHI');
GO

CREATE VIEW [INNER JOIN SAME CP] AS
SELECT collation_tests_english_collation_varchar.name AS name, collation_tests_english_collation_varchar_innerjoin.name_same_cp AS same_name
FROM collation_tests_english_collation_varchar
INNER JOIN collation_tests_english_collation_varchar_innerjoin ON collation_tests_english_collation_varchar.name = collation_tests_english_collation_varchar_innerjoin.name_same_cp;
GO
SELECT * FROM [INNER JOIN SAME CP] WHERE same_name = 'new DelHI';
GO


DROP VIEW [INNER JOIN SAME CP];
GO

DROP TABLE collation_tests_english_collation_varchar_innerjoin;
GO

DROP TABLE collation_tests_english_collation_varchar;
GO

-- table for computed columns on string
-- 1st column is for the actual string
-- 2nd column is for the substring
CREATE TABLE collation_tests_english_collation_varchar_computed_columns(name_same varchar(20) COLLATE latin1_general_ci_as, 
substr AS SUBSTRING (name_same, 1, 5));
GO

INSERT INTO collation_tests_english_collation_varchar_computed_columns VALUES ('new delhi');
INSERT INTO collation_tests_english_collation_varchar_computed_columns VALUES ('new Delhi');
INSERT INTO collation_tests_english_collation_varchar_computed_columns VALUES ('new DELHI');
INSERT INTO collation_tests_english_collation_varchar_computed_columns VALUES ('NEW delhi');
INSERT INTO collation_tests_english_collation_varchar_computed_columns VALUES ('NEW Delhi');
INSERT INTO collation_tests_english_collation_varchar_computed_columns VALUES ('NEW DELHI');
INSERT INTO collation_tests_english_collation_varchar_computed_columns VALUES ('New delhi');
INSERT INTO collation_tests_english_collation_varchar_computed_columns VALUES ('New Delhi');
INSERT INTO collation_tests_english_collation_varchar_computed_columns VALUES ('New DELHI');
GO

SELECT substr FROM collation_tests_english_collation_varchar_computed_columns;
GO

SELECT substr FROM collation_tests_english_collation_varchar_computed_columns WHERE substr='NEw d';
GO

SELECT 
    name, 
    collation_name 
FROM sys.columns 
WHERE name = N'substr';
GO

DROP TABLE collation_tests_english_collation_varchar_computed_columns;
GO

--nvarchar
CREATE TABLE collation_tests_english_collation_nvarchar (name nvarchar(20) COLLATE 
latin1_general_ci_as);
GO
INSERT INTO collation_tests_english_collation_nvarchar VALUES ('new delhi');
INSERT INTO collation_tests_english_collation_nvarchar VALUES ('new Delhi');
INSERT INTO collation_tests_english_collation_nvarchar VALUES ('new DELHI');
INSERT INTO collation_tests_english_collation_nvarchar VALUES ('NEW delhi');
INSERT INTO collation_tests_english_collation_nvarchar VALUES ('NEW Delhi');
INSERT INTO collation_tests_english_collation_nvarchar VALUES ('NEW DELHI');
INSERT INTO collation_tests_english_collation_nvarchar VALUES ('New delhi');
INSERT INTO collation_tests_english_collation_nvarchar VALUES ('New Delhi');
INSERT INTO collation_tests_english_collation_nvarchar VALUES ('New DELHI');
GO


SELECT * FROM collation_tests_english_collation_nvarchar ORDER BY name;
GO

SELECT * FROM collation_tests_english_collation_nvarchar WHERE name LIKE 'n%';
GO
SELECT * FROM collation_tests_english_collation_nvarchar WHERE name LIKE 'n%i';
GO
SELECT * FROM collation_tests_english_collation_nvarchar WHERE name LIKE 'n%D%';
GO
SELECT * FROM collation_tests_english_collation_nvarchar WHERE name LIKE 'N%';
GO
SELECT * FROM collation_tests_english_collation_nvarchar WHERE name LIKE 'N%i';
GO
SELECT * FROM collation_tests_english_collation_nvarchar WHERE name LIKE 'N%D%';
GO

SELECT * FROM collation_tests_english_collation_nvarchar WHERE name='NeW deLHi';
GO
SELECT * FROM collation_tests_english_collation_nvarchar WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO

DROP TABLE collation_tests_english_collation_nvarchar;
GO

--char
CREATE TABLE collation_tests_english_collation_char (name char(20) COLLATE 
latin1_general_ci_as);
GO
INSERT INTO collation_tests_english_collation_char VALUES ('new delhi');
INSERT INTO collation_tests_english_collation_char VALUES ('new Delhi');
INSERT INTO collation_tests_english_collation_char VALUES ('new DELHI');
INSERT INTO collation_tests_english_collation_char VALUES ('NEW delhi');
INSERT INTO collation_tests_english_collation_char VALUES ('NEW Delhi');
INSERT INTO collation_tests_english_collation_char VALUES ('NEW DELHI');
INSERT INTO collation_tests_english_collation_char VALUES ('New delhi');
INSERT INTO collation_tests_english_collation_char VALUES ('New Delhi');
INSERT INTO collation_tests_english_collation_char VALUES ('New DELHI');
GO


SELECT * FROM collation_tests_english_collation_char ORDER BY name;
GO

SELECT * FROM collation_tests_english_collation_char WHERE name LIKE 'n%';
GO
SELECT * FROM collation_tests_english_collation_char WHERE name LIKE 'n%i';
GO
SELECT * FROM collation_tests_english_collation_char WHERE name LIKE 'n%D%';
GO
SELECT * FROM collation_tests_english_collation_char WHERE name LIKE 'N%';
GO
SELECT * FROM collation_tests_english_collation_char WHERE name LIKE 'N%i';
GO
SELECT * FROM collation_tests_english_collation_char WHERE name LIKE 'N%D%';
GO

SELECT * FROM collation_tests_english_collation_char WHERE name='NeW deLHi';
GO
SELECT * FROM collation_tests_english_collation_char WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO

DROP TABLE collation_tests_english_collation_char;
GO

--nchar
CREATE TABLE collation_tests_english_collation_nchar (name nchar(20) COLLATE 
latin1_general_ci_as);
GO
INSERT INTO collation_tests_english_collation_nchar VALUES ('new delhi');
INSERT INTO collation_tests_english_collation_nchar VALUES ('new Delhi');
INSERT INTO collation_tests_english_collation_nchar VALUES ('new DELHI');
INSERT INTO collation_tests_english_collation_nchar VALUES ('NEW delhi');
INSERT INTO collation_tests_english_collation_nchar VALUES ('NEW Delhi');
INSERT INTO collation_tests_english_collation_nchar VALUES ('NEW DELHI');
INSERT INTO collation_tests_english_collation_nchar VALUES ('New delhi');
INSERT INTO collation_tests_english_collation_nchar VALUES ('New Delhi');
INSERT INTO collation_tests_english_collation_nchar VALUES ('New DELHI');
GO


SELECT * FROM collation_tests_english_collation_nchar ORDER BY name;
GO

SELECT * FROM collation_tests_english_collation_nchar WHERE name LIKE 'n%';
GO
SELECT * FROM collation_tests_english_collation_nchar WHERE name LIKE 'n%i';
GO
SELECT * FROM collation_tests_english_collation_nchar WHERE name LIKE 'n%D%';
GO
SELECT * FROM collation_tests_english_collation_nchar WHERE name LIKE 'N%';
GO
SELECT * FROM collation_tests_english_collation_nchar WHERE name LIKE 'N%i';
GO
SELECT * FROM collation_tests_english_collation_nchar WHERE name LIKE 'N%D%';
GO

SELECT * FROM collation_tests_english_collation_nchar WHERE name='NeW deLHi';
GO
SELECT * FROM collation_tests_english_collation_nchar WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO

DROP TABLE collation_tests_english_collation_nchar;
GO

--text
CREATE TABLE collation_tests_english_collation_text (name text COLLATE 
latin1_general_ci_as);
GO
INSERT INTO collation_tests_english_collation_text VALUES ('new delhi');
INSERT INTO collation_tests_english_collation_text VALUES ('new Delhi');
INSERT INTO collation_tests_english_collation_text VALUES ('new DELHI');
INSERT INTO collation_tests_english_collation_text VALUES ('NEW delhi');
INSERT INTO collation_tests_english_collation_text VALUES ('NEW Delhi');
INSERT INTO collation_tests_english_collation_text VALUES ('NEW DELHI');
INSERT INTO collation_tests_english_collation_text VALUES ('New delhi');
INSERT INTO collation_tests_english_collation_text VALUES ('New Delhi');
INSERT INTO collation_tests_english_collation_text VALUES ('New DELHI');
GO

SELECT * FROM collation_tests_english_collation_text ORDER BY name;
GO

SELECT * FROM collation_tests_english_collation_text WHERE name LIKE 'n%';
GO
SELECT * FROM collation_tests_english_collation_text WHERE name LIKE 'n%i';
GO
SELECT * FROM collation_tests_english_collation_text WHERE name LIKE 'n%D%';
GO
SELECT * FROM collation_tests_english_collation_text WHERE name LIKE 'N%';
GO
SELECT * FROM collation_tests_english_collation_text WHERE name LIKE 'N%i';
GO
SELECT * FROM collation_tests_english_collation_text WHERE name LIKE 'N%D%';
GO

SELECT * FROM collation_tests_english_collation_text WHERE name='NeW deLHi';
GO
SELECT * FROM collation_tests_english_collation_text WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO

DROP TABLE collation_tests_english_collation_text;
GO


--test for primary key
CREATE TABLE collation_tests_english_collation_primary_key(name varchar(20) COLLATE latin1_general_ci_as NOT NULL PRIMARY KEY);
GO

INSERT INTO collation_tests_english_collation_primary_key VALUES ('new Delhi');
GO
INSERT INTO collation_tests_english_collation_primary_key VALUES ('neW DElhi');
GO

SELECT * FROM collation_tests_english_collation_primary_key ORDER BY name;
GO

SELECT * FROM collation_tests_english_collation_primary_key WHERE name LIKE 'NE%h%';
GO

SELECT * FROM collation_tests_english_collation_primary_key WHERE name = 'NeW deLHi';
GO
SELECT * FROM collation_tests_english_collation_primary_key WHERE name='NeW deLHi' COLLATE latin1_general_cs_as;
GO

DROP TABLE collation_tests_english_collation_primary_key;
GO