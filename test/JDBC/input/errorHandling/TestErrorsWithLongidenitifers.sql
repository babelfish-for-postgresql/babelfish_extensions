-- ============================================================
-- BABEL-6434: Identifier length >128 must be rejected
-- All identifiers below are exactly 129 characters
-- ============================================================

-- Setup table for trigger/index tests
create table babel6434_base_table (a int, b int, c varchar(100));
GO

-- ============================================================
-- TABLE
-- ============================================================
create table babel6434_test_table_for_long_identifier_validation_that_exceeds_one_hundred_and_twenty_eight_characters_limit_in_babelfishxxxxxx (a int);
GO

-- ============================================================
-- VIEW
-- ============================================================
create view babel6434_test_view_for_long_identifier_validation_that_exceeds_one_hundred_and_twenty_eight_characters_limit_in_babelfish_xxxxxx as select 1;
GO

-- ============================================================
-- SELECT INTO
-- ============================================================
select * into babel6434_test_selectinto_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_characters_limit_babelfishxxxxxxxx from babel6434_base_table;
GO

-- ============================================================
-- FUNCTION
-- ============================================================
create function babel6434_test_function_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_characters_limit_babelfishxxxxxxxxxx() returns int as begin return 1 end;
GO

-- ============================================================
-- TABLE-VALUED FUNCTION
-- ============================================================
CREATE FUNCTION babel6434_test_tvf_function_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_characters_limit_babelfishxxxxxx() RETURNS TABLE AS RETURN ( SELECT 1 AS Value);
GO

-- ============================================================
-- PROCEDURE
-- ============================================================
create procedure babel6434_test_procedure_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_characters_limit_babelfishxxxxxxxxx as begin select 1; end
GO

-- ============================================================
-- TYPE
-- ============================================================
create type babel6434_test_type_for_long_identifier_validation_that_exceeds_one_hundred_and_twenty_eight_characters_limit_in_babelfish_xxxxxx from int;
GO

-- ============================================================
-- TRIGGER
-- ============================================================
CREATE TRIGGER babel6434_test_trigger_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_characters_limit_in_babelfishxxxxxxxx on babel6434_base_table AFTER INSERT AS BEGIN END;
GO

-- ============================================================
-- SEQUENCE
-- ============================================================
CREATE SEQUENCE babel6434_test_sequence_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_characters_limit_babelfish_xxxxxxxxx
GO

-- ============================================================
-- INDEX
-- ============================================================
create index babel6434_test_index_for_long_identifier_validation_that_exceeds_one_hundred_and_twenty_eight_characters_limit_babelfish_xxxxxxxx on babel6434_base_table(a);
GO

-- ============================================================
-- COLUMN
-- ============================================================
create table babel6434_col_test (babel6434_test_column_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_characters_limit_babelfish_xxxxxxxxxxx int);
GO

-- ============================================================
-- PRIMARY KEY CONSTRAINT
-- ============================================================
create table babel6434_pk_test (id int, CONSTRAINT babel6434_test_pk_constraint_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_characters_limit_babelfishxxxxx PRIMARY KEY (id));
GO

-- ============================================================
-- CHECK CONSTRAINT
-- ============================================================
alter table babel6434_base_table add CONSTRAINT babel6434_test_check_constraint_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_chars_limit_babelfishxxxxxxx CHECK (a > 0);
GO

-- ============================================================
-- UNIQUE CONSTRAINT
-- ============================================================
alter table babel6434_base_table add CONSTRAINT babel6434_test_unique_constraint_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_chars_limit_babelfishxxxxxx UNIQUE (c);
GO

-- ============================================================
-- FOREIGN KEY CONSTRAINT
-- ============================================================
create table babel6434_fk_test (fk_id int, CONSTRAINT babel6434_test_fk_constraint_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_characters_limit_babelfishxxxxx FOREIGN KEY (fk_id) REFERENCES babel6434_pk_test(id));
GO

-- ============================================================
-- DEFAULT CONSTRAINT
-- ============================================================
alter table babel6434_base_table add CONSTRAINT babel6434_test_default_constraint_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_chars_limit_bbfishxxxxxxxx DEFAULT 0 FOR b;
GO

-- ============================================================
-- PARAMETER (procedure)
-- ============================================================
create procedure babel6434_param_test_proc @babel6434_test_parameter_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_characters_limit_babelfishxxxxxxxxx int as begin select 1; end
GO

-- ============================================================
-- PARAMETER (function)
-- ============================================================
create function babel6434_param_test_func (@babel6434_test_parameter_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_characters_limit_babelfishxxxxxxxxx int) returns int as begin return 1 end;
GO

-- ============================================================
-- LOCAL VARIABLE (DECLARE)
-- ============================================================
DECLARE @babel6434_test_variable_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_characters_limit_babelfishxxxxxxxxx INT = 1;
SELECT @babel6434_test_variable_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_characters_limit_babelfishxxxxxxxxx;
GO

-- ============================================================
-- CURSOR (128 chars - should pass)
-- ============================================================
DECLARE babel6434_test_cursor_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_characters_limit_babelfishxxxxxxxxxxx CURSOR FOR SELECT a FROM babel6434_base_table;
GO

-- ============================================================
-- CURSOR (129 chars - should fail)
-- ============================================================
DECLARE babel6434_test_cursor_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_characters_limit_babelfishxxxxxxxxxxxx CURSOR FOR SELECT a FROM babel6434_base_table;
GO

-- ============================================================
-- CLEANUP
-- ============================================================
drop table if exists babel6434_fk_test;
GO
drop table if exists babel6434_pk_test;
GO
drop table if exists babel6434_col_test;
GO
drop table if exists babel6434_base_table;
GO

-- ============================================================
-- DATABASE
-- ============================================================
CREATE DATABASE babel6434_test_database_for_long_identifier_validation_that_exceeds_one_hundred_twenty_eight_characters_limit_babelfishxxxxxxxxxx;
GO

-- ============================================================
-- SCHEMA
-- ============================================================
CREATE SCHEMA babel6434_test_schema_for_long_identifier_validation_that_exceeds_one_hundred_and_twenty_eight_characters_limit_babelfishxxxxxxxx;
GO

-- ============================================================
-- LOGIN
-- ============================================================
CREATE LOGIN babel6434_test_login_for_long_identifier_validation_that_exceeds_one_hundred_and_twenty_eight_characters_limit_in_babelfishxxxxxx WITH PASSWORD = '12345678';
GO

-- ============================================================
-- USER
-- ============================================================
CREATE USER babel6434_test_user_for_long_identifier_validation_that_exceeds_one_hundred_and_twenty_eight_characters_limit_in_babelfishxxxxxxx;
GO

-- ============================================================
-- ROLE
-- ============================================================
CREATE ROLE babel6434_test_role_for_long_identifier_validation_that_exceeds_one_hundred_and_twenty_eight_characters_limit_in_babelfishxxxxxxx;
GO

-- ============================================================
-- TEMP TABLE (>116 chars - should fail)
-- ============================================================
CREATE TABLE #babel6434_test_temp_table_for_long_identifier_validation_that_exceeds_one_hundred_and_sixteen_charsxxxxxxxxxxxxxxxxxx (a int);
GO

-- ============================================================
-- ALIAS (>128 chars - should fail)
-- ============================================================
SELECT 1 AS babel6434_test_alias_for_long_identifier_validation_that_exceeds_one_hundred_and_twenty_eight_characters_limit_in_babelfishxxxxxx;
GO

-- ============================================================
-- ============================================================
-- MULTIBYTE CHARACTERS (>128 chars - should fail)
-- ============================================================

-- Table with multibyte name (129 chars)
CREATE TABLE babel6434_あああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああああ (a int);
GO

-- Column with multibyte name (129 chars)
CREATE TABLE babel6434_mb_col_test (babel6434_いいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいいい int);
GO

-- Function with multibyte name (129 chars)
CREATE FUNCTION babel6434_ううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううう() RETURNS INT AS BEGIN RETURN 1 END;
GO

-- Temp table with multibyte name (116 chars - should pass)
CREATE TABLE #babel6434_さささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささ (a int);
GO
DROP TABLE IF EXISTS #babel6434_さささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささ;
GO

-- Temp table with multibyte name (117 chars - should fail)
CREATE TABLE #babel6434_ささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささ (a int);
GO

-- Alias with multibyte name (129 chars)
SELECT 1 AS babel6434_おおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおおお;
GO

-- ============================================================
-- PARTITION FUNCTION with multibyte name (>128 chars - should fail without crash)
-- ============================================================
CREATE PARTITION FUNCTION babel6434_かかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかかか (bigint) AS RANGE RIGHT FOR VALUES (0, 10000, 100, 1000);
GO

CREATE PARTITION FUNCTION babel6434_pf_test (bigint) AS RANGE RIGHT FOR VALUES (0, 10000, 100, 1000);
GO
-- ============================================================
-- PARTITION SCHEME with multibyte name (>128 chars - should fail without crash)
-- ============================================================
CREATE PARTITION SCHEME babel6434_ききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききききき AS PARTITION babel6434_pf_test ALL TO ([PRIMARY]);
GO
DROP PARTITION FUNCTION babel6434_pf_test;
GO

-- ============================================================
-- LOGIN with multibyte name (>128 chars - should fail without crash)
-- ============================================================
CREATE LOGIN babel6434_ううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううううう WITH PASSWORD = '123';
GO

-- ============================================================
-- CURSOR with multibyte name (>128 chars - should fail without crash)
-- ============================================================
CREATE TABLE babel6434_cursor_mb_test (a int);
GO
DECLARE babel6434_くくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくくく CURSOR FOR SELECT a FROM babel6434_cursor_mb_test;
GO
DROP TABLE IF EXISTS babel6434_cursor_mb_test;
GO

-- ============================================================
-- PROCEDURE with multibyte name (>128 chars - should fail without crash)
-- ============================================================
CREATE PROCEDURE babel6434_けけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけけ AS BEGIN SELECT 1; END
GO

-- ============================================================
-- VIEW with multibyte name (>128 chars - should fail without crash)
-- ============================================================
CREATE VIEW babel6434_こここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここここ AS SELECT 1 AS val;
GO

-- ============================================================
-- INDEX with multibyte name (>128 chars - should fail without crash)
-- ============================================================
CREATE TABLE babel6434_idx_mb_test (a int);
GO
CREATE INDEX babel6434_さささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささささ ON babel6434_idx_mb_test(a);
GO
DROP TABLE IF EXISTS babel6434_idx_mb_test;
GO

-- ============================================================
-- SCHEMA with multibyte name (>128 chars - should fail without crash)
-- ============================================================
CREATE SCHEMA babel6434_ししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししししし;
GO
