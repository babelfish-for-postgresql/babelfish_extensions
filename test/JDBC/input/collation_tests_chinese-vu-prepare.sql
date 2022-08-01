--varchar
CREATE TABLE collation_tests_chinese_vu_prepare_varchar (name varchar(20) COLLATE chinese_prc_ci_as);
GO

INSERT INTO collation_tests_chinese_vu_prepare_varchar VALUES ('爱');
INSERT INTO collation_tests_chinese_vu_prepare_varchar VALUES ('幸福');
INSERT INTO collation_tests_chinese_vu_prepare_varchar VALUES ('猫');
INSERT INTO collation_tests_chinese_vu_prepare_varchar VALUES ('狗');
INSERT INTO collation_tests_chinese_vu_prepare_varchar VALUES ('微笑');
INSERT INTO collation_tests_chinese_vu_prepare_varchar VALUES ('中国人');
INSERT INTO collation_tests_chinese_vu_prepare_varchar VALUES ('是的。');
INSERT INTO collation_tests_chinese_vu_prepare_varchar VALUES ('谢谢你。');
INSERT INTO collation_tests_chinese_vu_prepare_varchar VALUES ('再见。');
INSERT INTO collation_tests_chinese_vu_prepare_varchar VALUES ('你好。');
GO


--inner join
CREATE TABLE collation_tests_chinese_vu_prepare_varchar_innerjoin (name_same_cp varchar(20) COLLATE chinese_prc_ci_as);
GO

INSERT INTO collation_tests_chinese_vu_prepare_varchar_innerjoin VALUES ('爱');
INSERT INTO collation_tests_chinese_vu_prepare_varchar_innerjoin VALUES ('猫');
INSERT INTO collation_tests_chinese_vu_prepare_varchar_innerjoin VALUES ('微笑');
INSERT INTO collation_tests_chinese_vu_prepare_varchar_innerjoin VALUES ('是的。');
INSERT INTO collation_tests_chinese_vu_prepare_varchar_innerjoin VALUES ('再见。');
INSERT INTO collation_tests_chinese_vu_prepare_varchar_innerjoin VALUES ('你好。');
GO

CREATE VIEW [INNER JOIN SAME CP CHINESE] AS
SELECT collation_tests_chinese_vu_prepare_varchar.name AS name, collation_tests_chinese_vu_prepare_varchar_innerjoin.name_same_cp AS same_name
FROM collation_tests_chinese_vu_prepare_varchar
INNER JOIN collation_tests_chinese_vu_prepare_varchar_innerjoin ON collation_tests_chinese_vu_prepare_varchar.name = collation_tests_chinese_vu_prepare_varchar_innerjoin.name_same_cp;
GO

--computed column
-- 1st column is for the actual string
-- 2nd column is for the substring
CREATE TABLE collation_tests_chinese_vu_prepare_varchar_computed_columns(name_same varchar(20) COLLATE chinese_prc_ci_as, 
substr_chinese AS SUBSTRING (name_same, 1, 1));
GO

INSERT INTO collation_tests_chinese_vu_prepare_varchar_computed_columns VALUES ('爱');
INSERT INTO collation_tests_chinese_vu_prepare_varchar_computed_columns VALUES ('幸福');
INSERT INTO collation_tests_chinese_vu_prepare_varchar_computed_columns VALUES ('猫');
INSERT INTO collation_tests_chinese_vu_prepare_varchar_computed_columns VALUES ('狗');
INSERT INTO collation_tests_chinese_vu_prepare_varchar_computed_columns VALUES ('微笑');
INSERT INTO collation_tests_chinese_vu_prepare_varchar_computed_columns VALUES ('中国人');
INSERT INTO collation_tests_chinese_vu_prepare_varchar_computed_columns VALUES ('是的。');
INSERT INTO collation_tests_chinese_vu_prepare_varchar_computed_columns VALUES ('谢谢你。');
INSERT INTO collation_tests_chinese_vu_prepare_varchar_computed_columns VALUES ('再见。');
INSERT INTO collation_tests_chinese_vu_prepare_varchar_computed_columns VALUES ('你好。');
GO


--nvarchar
CREATE TABLE collation_tests_chinese_vu_prepare_nvarchar (name nvarchar(20) COLLATE chinese_prc_ci_as);
GO

INSERT INTO collation_tests_chinese_vu_prepare_nvarchar VALUES ('爱');
INSERT INTO collation_tests_chinese_vu_prepare_nvarchar VALUES ('幸福');
INSERT INTO collation_tests_chinese_vu_prepare_nvarchar VALUES ('猫');
INSERT INTO collation_tests_chinese_vu_prepare_nvarchar VALUES ('狗');
INSERT INTO collation_tests_chinese_vu_prepare_nvarchar VALUES ('微笑');
INSERT INTO collation_tests_chinese_vu_prepare_nvarchar VALUES ('中国人');
INSERT INTO collation_tests_chinese_vu_prepare_nvarchar VALUES ('是的。');
INSERT INTO collation_tests_chinese_vu_prepare_nvarchar VALUES ('谢谢你。');
INSERT INTO collation_tests_chinese_vu_prepare_nvarchar VALUES ('再见。');
INSERT INTO collation_tests_chinese_vu_prepare_nvarchar VALUES ('你好。');
GO

--char
CREATE TABLE collation_tests_chinese_vu_prepare_char (name char(20) COLLATE chinese_prc_ci_as);
GO

INSERT INTO collation_tests_chinese_vu_prepare_char VALUES ('爱');
INSERT INTO collation_tests_chinese_vu_prepare_char VALUES ('幸福');
INSERT INTO collation_tests_chinese_vu_prepare_char VALUES ('猫');
INSERT INTO collation_tests_chinese_vu_prepare_char VALUES ('狗');
INSERT INTO collation_tests_chinese_vu_prepare_char VALUES ('微笑');
INSERT INTO collation_tests_chinese_vu_prepare_char VALUES ('中国人');
INSERT INTO collation_tests_chinese_vu_prepare_char VALUES ('是的。');
INSERT INTO collation_tests_chinese_vu_prepare_char VALUES ('谢谢你。');
INSERT INTO collation_tests_chinese_vu_prepare_char VALUES ('再见。');
INSERT INTO collation_tests_chinese_vu_prepare_char VALUES ('你好。');
GO

--nchar
CREATE TABLE collation_tests_chinese_vu_prepare_nchar (name nchar(20) COLLATE chinese_prc_ci_as);
GO

INSERT INTO collation_tests_chinese_vu_prepare_nchar VALUES ('爱');
INSERT INTO collation_tests_chinese_vu_prepare_nchar VALUES ('幸福');
INSERT INTO collation_tests_chinese_vu_prepare_nchar VALUES ('猫');
INSERT INTO collation_tests_chinese_vu_prepare_nchar VALUES ('狗');
INSERT INTO collation_tests_chinese_vu_prepare_nchar VALUES ('微笑');
INSERT INTO collation_tests_chinese_vu_prepare_nchar VALUES ('中国人');
INSERT INTO collation_tests_chinese_vu_prepare_nchar VALUES ('是的。');
INSERT INTO collation_tests_chinese_vu_prepare_nchar VALUES ('谢谢你。');
INSERT INTO collation_tests_chinese_vu_prepare_nchar VALUES ('再见。');
INSERT INTO collation_tests_chinese_vu_prepare_nchar VALUES ('你好。');
GO


--text
CREATE TABLE collation_tests_chinese_vu_prepare_text (name text COLLATE chinese_prc_ci_as);
GO

INSERT INTO collation_tests_chinese_vu_prepare_text VALUES ('爱');
INSERT INTO collation_tests_chinese_vu_prepare_text VALUES ('幸福');
INSERT INTO collation_tests_chinese_vu_prepare_text VALUES ('猫');
INSERT INTO collation_tests_chinese_vu_prepare_text VALUES ('狗');
INSERT INTO collation_tests_chinese_vu_prepare_text VALUES ('微笑');
INSERT INTO collation_tests_chinese_vu_prepare_text VALUES ('中国人');
INSERT INTO collation_tests_chinese_vu_prepare_text VALUES ('是的。');
INSERT INTO collation_tests_chinese_vu_prepare_text VALUES ('谢谢你。');
INSERT INTO collation_tests_chinese_vu_prepare_text VALUES ('再见。');
INSERT INTO collation_tests_chinese_vu_prepare_text VALUES ('你好。');
GO

--primary key
CREATE TABLE collation_tests_chinese_vu_prepare_primary(name varchar(20) COLLATE chinese_prc_ci_as NOT NULL PRIMARY KEY);
GO


--Truncation error
CREATE TABLE collation_tests_chinese_vu_prepare_truncation(name varchar(3) COLLATE chinese_prc_ci_as);
GO