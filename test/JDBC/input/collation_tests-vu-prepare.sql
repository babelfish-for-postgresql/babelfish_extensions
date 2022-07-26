--varchar
CREATE TABLE english_collation_varchar (name varchar(20) COLLATE latin1_general_ci_as);
GO
INSERT INTO english_collation_varchar VALUES ('new delhi');
INSERT INTO english_collation_varchar VALUES ('new Delhi');
INSERT INTO english_collation_varchar VALUES ('new DELHI');
INSERT INTO english_collation_varchar VALUES ('NEW delhi');
INSERT INTO english_collation_varchar VALUES ('NEW Delhi');
INSERT INTO english_collation_varchar VALUES ('NEW DELHI');
INSERT INTO english_collation_varchar VALUES ('New delhi');
INSERT INTO english_collation_varchar VALUES ('New Delhi');
INSERT INTO english_collation_varchar VALUES ('New DELHI');
GO

-- table for inner join
CREATE TABLE english_collation_varchar_innerjoin(name_same_cp varchar(20) COLLATE latin1_general_ci_as, 
name_diff_cp varchar(20) COLLATE sql_latin1_general_cp1250_cs_as);
GO
INSERT INTO english_collation_varchar_innerjoin VALUES ('new delhi', 'new delhi');
INSERT INTO english_collation_varchar_innerjoin VALUES ('new Delhi', 'new Delhi');
INSERT INTO english_collation_varchar_innerjoin VALUES ('new DELHI', 'new DELHI');
INSERT INTO english_collation_varchar_innerjoin VALUES ('NEW delhi', 'NEW delhi');
INSERT INTO english_collation_varchar_innerjoin VALUES ('NEW Delhi', 'NEW Delhi');
INSERT INTO english_collation_varchar_innerjoin VALUES ('NEW DELHI', 'NEW DELHI');
INSERT INTO english_collation_varchar_innerjoin VALUES ('New delhi', 'New delhi');
INSERT INTO english_collation_varchar_innerjoin VALUES ('New Delhi', 'New Delhi');
INSERT INTO english_collation_varchar_innerjoin VALUES ('New DELHI', 'New DELHI');
GO

-- table for computed columns on string
-- 1st column is for the actual string
-- 2nd column is for the substring
CREATE TABLE english_collation_varchar_computed_columns(name_same varchar(20) COLLATE latin1_general_ci_as, 
substr AS SUBSTRING (name_same, 1, 5));
GO

INSERT INTO english_collation_varchar_computed_columns VALUES ('new delhi');
INSERT INTO english_collation_varchar_computed_columns VALUES ('new Delhi');
INSERT INTO english_collation_varchar_computed_columns VALUES ('new DELHI');
INSERT INTO english_collation_varchar_computed_columns VALUES ('NEW delhi');
INSERT INTO english_collation_varchar_computed_columns VALUES ('NEW Delhi');
INSERT INTO english_collation_varchar_computed_columns VALUES ('NEW DELHI');
INSERT INTO english_collation_varchar_computed_columns VALUES ('New delhi');
INSERT INTO english_collation_varchar_computed_columns VALUES ('New Delhi');
INSERT INTO english_collation_varchar_computed_columns VALUES ('New DELHI');
GO


--nvarchar
CREATE TABLE english_collation_nvarchar (name nvarchar(20) COLLATE 
latin1_general_ci_as);
GO
INSERT INTO english_collation_nvarchar VALUES ('new delhi');
INSERT INTO english_collation_nvarchar VALUES ('new Delhi');
INSERT INTO english_collation_nvarchar VALUES ('new DELHI');
INSERT INTO english_collation_nvarchar VALUES ('NEW delhi');
INSERT INTO english_collation_nvarchar VALUES ('NEW Delhi');
INSERT INTO english_collation_nvarchar VALUES ('NEW DELHI');
INSERT INTO english_collation_nvarchar VALUES ('New delhi');
INSERT INTO english_collation_nvarchar VALUES ('New Delhi');
INSERT INTO english_collation_nvarchar VALUES ('New DELHI');
GO

--char
CREATE TABLE english_collation_char (name char(20) COLLATE 
latin1_general_ci_as);
GO
INSERT INTO english_collation_char VALUES ('new delhi');
INSERT INTO english_collation_char VALUES ('new Delhi');
INSERT INTO english_collation_char VALUES ('new DELHI');
INSERT INTO english_collation_char VALUES ('NEW delhi');
INSERT INTO english_collation_char VALUES ('NEW Delhi');
INSERT INTO english_collation_char VALUES ('NEW DELHI');
INSERT INTO english_collation_char VALUES ('New delhi');
INSERT INTO english_collation_char VALUES ('New Delhi');
INSERT INTO english_collation_char VALUES ('New DELHI');
GO

--nchar
CREATE TABLE english_collation_nchar (name nchar(20) COLLATE 
latin1_general_ci_as);
GO
INSERT INTO english_collation_nchar VALUES ('new delhi');
INSERT INTO english_collation_nchar VALUES ('new Delhi');
INSERT INTO english_collation_nchar VALUES ('new DELHI');
INSERT INTO english_collation_nchar VALUES ('NEW delhi');
INSERT INTO english_collation_nchar VALUES ('NEW Delhi');
INSERT INTO english_collation_nchar VALUES ('NEW DELHI');
INSERT INTO english_collation_nchar VALUES ('New delhi');
INSERT INTO english_collation_nchar VALUES ('New Delhi');
INSERT INTO english_collation_nchar VALUES ('New DELHI');
GO

--text
CREATE TABLE english_collation_text (name text COLLATE 
latin1_general_ci_as);
GO
INSERT INTO english_collation_text VALUES ('new delhi');
INSERT INTO english_collation_text VALUES ('new Delhi');
INSERT INTO english_collation_text VALUES ('new DELHI');
INSERT INTO english_collation_text VALUES ('NEW delhi');
INSERT INTO english_collation_text VALUES ('NEW Delhi');
INSERT INTO english_collation_text VALUES ('NEW DELHI');
INSERT INTO english_collation_text VALUES ('New delhi');
INSERT INTO english_collation_text VALUES ('New Delhi');
INSERT INTO english_collation_text VALUES ('New DELHI');
GO

--test for primary key
CREATE TABLE english_collation_primary_key(name varchar(20) COLLATE latin1_general_ci_as NOT NULL PRIMARY KEY);
GO

INSERT INTO english_collation_primary_key VALUES ('new Delhi');
GO
INSERT INTO english_collation_primary_key VALUES ('neW DElhi');
GO