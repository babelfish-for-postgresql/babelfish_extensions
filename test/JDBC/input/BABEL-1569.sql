-- Test CHARINDEX function with computed columns (general gives case-insensitive result)
--WRONG OUTPUT
-- CREATE TABLE check_charindex_general(check_for VARCHAR(10), document VARCHAR(64), ci as charindex(check_for, document));
-- GO

-- INSERT INTO check_charindex_general (check_for, document) VALUES ('Test','This is a Test');
-- INSERT INTO check_charindex_general (check_for, document) VALUES ('Test','test Test test');
-- INSERT INTO check_charindex_general (check_for, document) VALUES ('TEST','This is a test');
-- GO

-- Select ci from check_charindex_general;
-- GO

-- DROP TABLE check_charindex_general;
-- GO

-- Test CHARINDEX function with computed columns (case-insensitive)
CREATE TABLE check_charindex_case_insensitive(check_for VARCHAR(10), document VARCHAR(64), ci as charindex(check_for, document COLLATE SQL_Latin1_General_CP1_CI_AS));
GO

INSERT INTO check_charindex_case_insensitive (check_for, document) VALUES ('Test','This is a Test');
INSERT INTO check_charindex_case_insensitive (check_for, document) VALUES ('Test','test Test test');
INSERT INTO check_charindex_case_insensitive (check_for, document) VALUES ('TEST','This is a test');
GO

Select ci from check_charindex_case_insensitive;
GO

DROP TABLE check_charindex_case_insensitive;
GO

-- Test CHARINDEX function with computed columns (case-sensitive)
CREATE TABLE check_charindex_case_sensitive(check_for VARCHAR(10), document VARCHAR(64), ci as charindex(check_for, document COLLATE SQL_Latin1_General_CP1_CS_AS));
GO

INSERT INTO check_charindex_case_sensitive (check_for, document) VALUES ('Test','This is a Test');
INSERT INTO check_charindex_case_sensitive (check_for, document) VALUES ('Test','test Test test');
INSERT INTO check_charindex_case_sensitive (check_for, document) VALUES ('TEST','This is a test');
GO

Select ci from check_charindex_case_sensitive;
GO

DROP TABLE check_charindex_case_sensitive;
GO

-- Test CHECKSUM function with computed columns
CREATE TABLE country(name VARCHAR(64), cs as CHECKSUM(name))
GO

INSERT INTO country VALUES ('India');
INSERT INTO country VALUES ('US');
INSERT INTO country VALUES ('China');
GO

DROP TABLE country;
GO
