--varchar
CREATE TABLE collation_tests_polish_vu_prepare_varchar (name varchar(20) COLLATE polish_ci_as);
GO

INSERT INTO collation_tests_polish_vu_prepare_varchar VALUES ('tydzień');
INSERT INTO collation_tests_polish_vu_prepare_varchar VALUES ('rok');
INSERT INTO collation_tests_polish_vu_prepare_varchar VALUES ('dziś');
INSERT INTO collation_tests_polish_vu_prepare_varchar VALUES ('jutro');
INSERT INTO collation_tests_polish_vu_prepare_varchar VALUES ('wczoraj');
INSERT INTO collation_tests_polish_vu_prepare_varchar VALUES ('kalendarz');
INSERT INTO collation_tests_polish_vu_prepare_varchar VALUES ('sekunda');
INSERT INTO collation_tests_polish_vu_prepare_varchar VALUES ('godzina');
INSERT INTO collation_tests_polish_vu_prepare_varchar VALUES ('minuta');
INSERT INTO collation_tests_polish_vu_prepare_varchar VALUES ('móc');
GO


--inner join
CREATE TABLE collation_tests_polish_vu_prepare_varchar_innerjoin (name_same_cp varchar(20) COLLATE polish_ci_as);
GO

INSERT INTO collation_tests_polish_vu_prepare_varchar_innerjoin VALUES ('tydzień');
INSERT INTO collation_tests_polish_vu_prepare_varchar_innerjoin VALUES ('dziś');
INSERT INTO collation_tests_polish_vu_prepare_varchar_innerjoin VALUES ('wczoraj');
INSERT INTO collation_tests_polish_vu_prepare_varchar_innerjoin VALUES ('sekunda');
INSERT INTO collation_tests_polish_vu_prepare_varchar_innerjoin VALUES ('minuta');
INSERT INTO collation_tests_polish_vu_prepare_varchar_innerjoin VALUES ('móc');
GO

CREATE VIEW [INNER JOIN SAME CP POLISH] AS
SELECT collation_tests_polish_vu_prepare_varchar.name AS name, collation_tests_polish_vu_prepare_varchar_innerjoin.name_same_cp AS same_name
FROM collation_tests_polish_vu_prepare_varchar
INNER JOIN collation_tests_polish_vu_prepare_varchar_innerjoin ON collation_tests_polish_vu_prepare_varchar.name = collation_tests_polish_vu_prepare_varchar_innerjoin.name_same_cp;
GO

--computed column
-- 1st column is for the actual string
-- 2nd column is for the substring
CREATE TABLE collation_tests_polish_vu_prepare_varchar_computed_columns(name_same varchar(20) COLLATE polish_ci_as, 
substr_polish AS SUBSTRING (name_same, 1, 3));
GO

INSERT INTO collation_tests_polish_vu_prepare_varchar_computed_columns VALUES ('tydzień');
INSERT INTO collation_tests_polish_vu_prepare_varchar_computed_columns VALUES ('rok');
INSERT INTO collation_tests_polish_vu_prepare_varchar_computed_columns VALUES ('dziś');
INSERT INTO collation_tests_polish_vu_prepare_varchar_computed_columns VALUES ('jutro');
INSERT INTO collation_tests_polish_vu_prepare_varchar_computed_columns VALUES ('wczoraj');
INSERT INTO collation_tests_polish_vu_prepare_varchar_computed_columns VALUES ('kalendarz');
INSERT INTO collation_tests_polish_vu_prepare_varchar_computed_columns VALUES ('sekunda');
INSERT INTO collation_tests_polish_vu_prepare_varchar_computed_columns VALUES ('godzina');
INSERT INTO collation_tests_polish_vu_prepare_varchar_computed_columns VALUES ('minuta');
INSERT INTO collation_tests_polish_vu_prepare_varchar_computed_columns VALUES ('móc');
GO


--nvarchar
CREATE TABLE collation_tests_polish_vu_prepare_nvarchar (name nvarchar(20) COLLATE polish_ci_as);
GO

INSERT INTO collation_tests_polish_vu_prepare_nvarchar VALUES ('tydzień');
INSERT INTO collation_tests_polish_vu_prepare_nvarchar VALUES ('rok');
INSERT INTO collation_tests_polish_vu_prepare_nvarchar VALUES ('dziś');
INSERT INTO collation_tests_polish_vu_prepare_nvarchar VALUES ('jutro');
INSERT INTO collation_tests_polish_vu_prepare_nvarchar VALUES ('wczoraj');
INSERT INTO collation_tests_polish_vu_prepare_nvarchar VALUES ('kalendarz');
INSERT INTO collation_tests_polish_vu_prepare_nvarchar VALUES ('sekunda');
INSERT INTO collation_tests_polish_vu_prepare_nvarchar VALUES ('godzina');
INSERT INTO collation_tests_polish_vu_prepare_nvarchar VALUES ('minuta');
INSERT INTO collation_tests_polish_vu_prepare_nvarchar VALUES ('móc');
GO

--char
CREATE TABLE collation_tests_polish_vu_prepare_char (name char(20) COLLATE polish_ci_as);
GO

INSERT INTO collation_tests_polish_vu_prepare_char VALUES ('tydzień');
INSERT INTO collation_tests_polish_vu_prepare_char VALUES ('rok');
INSERT INTO collation_tests_polish_vu_prepare_char VALUES ('dziś');
INSERT INTO collation_tests_polish_vu_prepare_char VALUES ('jutro');
INSERT INTO collation_tests_polish_vu_prepare_char VALUES ('wczoraj');
INSERT INTO collation_tests_polish_vu_prepare_char VALUES ('kalendarz');
INSERT INTO collation_tests_polish_vu_prepare_char VALUES ('sekunda');
INSERT INTO collation_tests_polish_vu_prepare_char VALUES ('godzina');
INSERT INTO collation_tests_polish_vu_prepare_char VALUES ('minuta');
INSERT INTO collation_tests_polish_vu_prepare_char VALUES ('móc');
GO

--nchar
CREATE TABLE collation_tests_polish_vu_prepare_nchar (name nchar(20) COLLATE polish_ci_as);
GO

INSERT INTO collation_tests_polish_vu_prepare_nchar VALUES ('tydzień');
INSERT INTO collation_tests_polish_vu_prepare_nchar VALUES ('rok');
INSERT INTO collation_tests_polish_vu_prepare_nchar VALUES ('dziś');
INSERT INTO collation_tests_polish_vu_prepare_nchar VALUES ('jutro');
INSERT INTO collation_tests_polish_vu_prepare_nchar VALUES ('wczoraj');
INSERT INTO collation_tests_polish_vu_prepare_nchar VALUES ('kalendarz');
INSERT INTO collation_tests_polish_vu_prepare_nchar VALUES ('sekunda');
INSERT INTO collation_tests_polish_vu_prepare_nchar VALUES ('godzina');
INSERT INTO collation_tests_polish_vu_prepare_nchar VALUES ('minuta');
INSERT INTO collation_tests_polish_vu_prepare_nchar VALUES ('móc');
GO


--text
CREATE TABLE collation_tests_polish_vu_prepare_text (name text COLLATE polish_ci_as);
GO

INSERT INTO collation_tests_polish_vu_prepare_text VALUES ('tydzień');
INSERT INTO collation_tests_polish_vu_prepare_text VALUES ('rok');
INSERT INTO collation_tests_polish_vu_prepare_text VALUES ('dziś');
INSERT INTO collation_tests_polish_vu_prepare_text VALUES ('jutro');
INSERT INTO collation_tests_polish_vu_prepare_text VALUES ('wczoraj');
INSERT INTO collation_tests_polish_vu_prepare_text VALUES ('kalendarz');
INSERT INTO collation_tests_polish_vu_prepare_text VALUES ('sekunda');
INSERT INTO collation_tests_polish_vu_prepare_text VALUES ('godzina');
INSERT INTO collation_tests_polish_vu_prepare_text VALUES ('minuta');
INSERT INTO collation_tests_polish_vu_prepare_text VALUES ('móc');
GO

--primary key
CREATE TABLE collation_tests_polish_vu_prepare_primary(name varchar(20) COLLATE polish_ci_as NOT NULL PRIMARY KEY);
GO