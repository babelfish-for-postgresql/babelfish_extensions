--varchar
CREATE TABLE collation_tests_greek_vu_prepare_varchar (name varchar(20) COLLATE greek_ci_as);
GO

INSERT INTO collation_tests_greek_vu_prepare_varchar VALUES ('ελπίδα');
INSERT INTO collation_tests_greek_vu_prepare_varchar VALUES ('χαρμολύπη');
INSERT INTO collation_tests_greek_vu_prepare_varchar VALUES ('φιλοξενία');
INSERT INTO collation_tests_greek_vu_prepare_varchar VALUES ('υγεία');
INSERT INTO collation_tests_greek_vu_prepare_varchar VALUES ('ψυχή');
INSERT INTO collation_tests_greek_vu_prepare_varchar VALUES ('ίριδα');
INSERT INTO collation_tests_greek_vu_prepare_varchar VALUES ('ευτυχία');
INSERT INTO collation_tests_greek_vu_prepare_varchar VALUES ('αιώνια');
INSERT INTO collation_tests_greek_vu_prepare_varchar VALUES ('αγάπη');
INSERT INTO collation_tests_greek_vu_prepare_varchar VALUES ('µεράκι');
GO


--inner join
CREATE TABLE collation_tests_greek_vu_prepare_varchar_innerjoin (name_same_cp varchar(20) COLLATE greek_ci_as);
GO

INSERT INTO collation_tests_greek_vu_prepare_varchar_innerjoin VALUES ('ελπίδα');
INSERT INTO collation_tests_greek_vu_prepare_varchar_innerjoin VALUES ('φιλοξενία');
INSERT INTO collation_tests_greek_vu_prepare_varchar_innerjoin VALUES ('ψυχή');
INSERT INTO collation_tests_greek_vu_prepare_varchar_innerjoin VALUES ('ευτυχία');
INSERT INTO collation_tests_greek_vu_prepare_varchar_innerjoin VALUES ('αγάπη');
INSERT INTO collation_tests_greek_vu_prepare_varchar_innerjoin VALUES ('µεράκι');
GO

CREATE VIEW [INNER JOIN SAME CP GREEK] AS
SELECT collation_tests_greek_vu_prepare_varchar.name AS name, collation_tests_greek_vu_prepare_varchar_innerjoin.name_same_cp AS same_name
FROM collation_tests_greek_vu_prepare_varchar
INNER JOIN collation_tests_greek_vu_prepare_varchar_innerjoin ON collation_tests_greek_vu_prepare_varchar.name = collation_tests_greek_vu_prepare_varchar_innerjoin.name_same_cp;
GO

--computed column
-- 1st column is for the actual string
-- 2nd column is for the substring
CREATE TABLE collation_tests_greek_vu_prepare_varchar_computed_columns(name_same varchar(20) COLLATE greek_ci_as, 
substr_greek AS SUBSTRING (name_same, 1, 3));
GO

INSERT INTO collation_tests_greek_vu_prepare_varchar_computed_columns VALUES ('ελπίδα');
INSERT INTO collation_tests_greek_vu_prepare_varchar_computed_columns VALUES ('χαρμολύπη');
INSERT INTO collation_tests_greek_vu_prepare_varchar_computed_columns VALUES ('φιλοξενία');
INSERT INTO collation_tests_greek_vu_prepare_varchar_computed_columns VALUES ('υγεία');
INSERT INTO collation_tests_greek_vu_prepare_varchar_computed_columns VALUES ('ψυχή');
INSERT INTO collation_tests_greek_vu_prepare_varchar_computed_columns VALUES ('ίριδα');
INSERT INTO collation_tests_greek_vu_prepare_varchar_computed_columns VALUES ('ευτυχία');
INSERT INTO collation_tests_greek_vu_prepare_varchar_computed_columns VALUES ('αιώνια');
INSERT INTO collation_tests_greek_vu_prepare_varchar_computed_columns VALUES ('αγάπη');
INSERT INTO collation_tests_greek_vu_prepare_varchar_computed_columns VALUES ('µεράκι');
GO


--nvarchar
CREATE TABLE collation_tests_greek_vu_prepare_nvarchar (name nvarchar(20) COLLATE greek_ci_as);
GO

INSERT INTO collation_tests_greek_vu_prepare_nvarchar VALUES ('ελπίδα');
INSERT INTO collation_tests_greek_vu_prepare_nvarchar VALUES ('χαρμολύπη');
INSERT INTO collation_tests_greek_vu_prepare_nvarchar VALUES ('φιλοξενία');
INSERT INTO collation_tests_greek_vu_prepare_nvarchar VALUES ('υγεία');
INSERT INTO collation_tests_greek_vu_prepare_nvarchar VALUES ('ψυχή');
INSERT INTO collation_tests_greek_vu_prepare_nvarchar VALUES ('ίριδα');
INSERT INTO collation_tests_greek_vu_prepare_nvarchar VALUES ('ευτυχία');
INSERT INTO collation_tests_greek_vu_prepare_nvarchar VALUES ('αιώνια');
INSERT INTO collation_tests_greek_vu_prepare_nvarchar VALUES ('αγάπη');
INSERT INTO collation_tests_greek_vu_prepare_nvarchar VALUES ('µεράκι');
GO

--char
CREATE TABLE collation_tests_greek_vu_prepare_char (name char(20) COLLATE greek_ci_as);
GO

INSERT INTO collation_tests_greek_vu_prepare_char VALUES ('ελπίδα');
INSERT INTO collation_tests_greek_vu_prepare_char VALUES ('χαρμολύπη');
INSERT INTO collation_tests_greek_vu_prepare_char VALUES ('φιλοξενία');
INSERT INTO collation_tests_greek_vu_prepare_char VALUES ('υγεία');
INSERT INTO collation_tests_greek_vu_prepare_char VALUES ('ψυχή');
INSERT INTO collation_tests_greek_vu_prepare_char VALUES ('ίριδα');
INSERT INTO collation_tests_greek_vu_prepare_char VALUES ('ευτυχία');
INSERT INTO collation_tests_greek_vu_prepare_char VALUES ('αιώνια');
INSERT INTO collation_tests_greek_vu_prepare_char VALUES ('αγάπη');
INSERT INTO collation_tests_greek_vu_prepare_char VALUES ('µεράκι');
GO

--nchar
CREATE TABLE collation_tests_greek_vu_prepare_nchar (name nchar(20) COLLATE greek_ci_as);
GO

INSERT INTO collation_tests_greek_vu_prepare_nchar VALUES ('ελπίδα');
INSERT INTO collation_tests_greek_vu_prepare_nchar VALUES ('χαρμολύπη');
INSERT INTO collation_tests_greek_vu_prepare_nchar VALUES ('φιλοξενία');
INSERT INTO collation_tests_greek_vu_prepare_nchar VALUES ('υγεία');
INSERT INTO collation_tests_greek_vu_prepare_nchar VALUES ('ψυχή');
INSERT INTO collation_tests_greek_vu_prepare_nchar VALUES ('ίριδα');
INSERT INTO collation_tests_greek_vu_prepare_nchar VALUES ('ευτυχία');
INSERT INTO collation_tests_greek_vu_prepare_nchar VALUES ('αιώνια');
INSERT INTO collation_tests_greek_vu_prepare_nchar VALUES ('αγάπη');
INSERT INTO collation_tests_greek_vu_prepare_nchar VALUES ('µεράκι');
GO


--text
CREATE TABLE collation_tests_greek_vu_prepare_text (name text COLLATE greek_ci_as);
GO

INSERT INTO collation_tests_greek_vu_prepare_text VALUES ('ελπίδα');
INSERT INTO collation_tests_greek_vu_prepare_text VALUES ('χαρμολύπη');
INSERT INTO collation_tests_greek_vu_prepare_text VALUES ('φιλοξενία');
INSERT INTO collation_tests_greek_vu_prepare_text VALUES ('υγεία');
INSERT INTO collation_tests_greek_vu_prepare_text VALUES ('ψυχή');
INSERT INTO collation_tests_greek_vu_prepare_text VALUES ('ίριδα');
INSERT INTO collation_tests_greek_vu_prepare_text VALUES ('ευτυχία');
INSERT INTO collation_tests_greek_vu_prepare_text VALUES ('αιώνια');
INSERT INTO collation_tests_greek_vu_prepare_text VALUES ('αγάπη');
INSERT INTO collation_tests_greek_vu_prepare_text VALUES ('µεράκι');
GO

--primary key
CREATE TABLE collation_tests_greek_vu_prepare_primary(name varchar(20) COLLATE greek_ci_as NOT NULL PRIMARY KEY);
GO