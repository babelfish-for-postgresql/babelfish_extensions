-- parallel_query_expected
-- tsql
------------------- CI_AI ----------------------

-- CASE 1: T_Const LIKE T_CollateExpr(T_Const)
select 1 where 'cantáis' like 'Cá%' collate Latin1_General_CI_AI;
GO

select 1 where CAST('cantáis' AS text) like CAST('Cá%' AS text) collate Latin1_General_CI_AI;
GO

select 1 where CAST('cantáis' AS ntext) like CAST('Cá%' AS ntext) collate Latin1_General_CI_AI;
GO

select 1 where CAST('cantáis' AS varchar) like CAST('Cá%' AS varchar) collate Latin1_General_CI_AI;
GO

select 1 where CAST('cantáis' AS nvarchar) like CAST('Cá%' AS nvarchar) collate Latin1_General_CI_AI;
GO

select 1 where CAST('cantáis' AS char) like 'Cá%' collate Latin1_General_CI_AI;
GO

select 1 where CAST('cantáis' AS nchar) like 'Cá%' collate Latin1_General_CI_AI;
GO

select 1 where 'shaEpéD' like '%Æ%e%' collate Latin1_General_CI_AI;
GO

select 1 where 'BleȘȘing' like '%nĜ' collate Latin1_General_CI_AI
GO

-- CASE 2: T_CollateExpr(T_Const) LIKE T_Const
select 1 where 'cOntáis' collate Latin1_General_CI_AI like 'CŐ%';
GO

select 1 where 'shaEpüD' collate Latin1_General_CI_AI like '%Æ%ú%';
GO

select 1 where CAST('shaEpüD' AS text) collate Latin1_General_CI_AI like CAST('%Æ%ú%' AS text);
GO

select 1 where CAST('shaEpüD' AS ntext) collate Latin1_General_CI_AI like CAST('%Æ%ú%' AS ntext);
GO

select 1 where CAST('shaEpüD' AS varchar) collate Latin1_General_CI_AI like CAST('%Æ%ú%' AS varchar);
GO

select 1 where CAST('shaEpüD' AS nvarchar) collate Latin1_General_CI_AI like CAST('%Æ%ú%' AS nvarchar);
GO

select 1 where CAST('shaEpüD' AS char) collate Latin1_General_CI_AI like '%Æ%ú%';
GO

select 1 where CAST('shaEpüD' AS nchar) collate Latin1_General_CI_AI like '%Æ%ú%';
GO

select 1 where 'BleȘȘing' collate Latin1_General_CI_AI like '%ŝ%nĜ';
GO

-- CASE 3: T_CollateExpr(T_Const) LIKE T_CollateExpr(T_Const)
select 1 where 'cOntáis' collate Latin1_General_CI_AI like 'CŐ%' collate Latin1_General_CI_AI;
GO

select 1 where 'shaEpüD' collate Latin1_General_CI_AI like '%Æ%ú%' collate Latin1_General_CI_AI;
GO

select 1 where 'BleȘȘing' collate Latin1_General_CI_AI like '%ŝ%nĜ' collate Latin1_General_CI_AI;
GO

select 1 where CAST('BleȘȘing' AS text) collate Latin1_General_CI_AI like CAST('%ŝ%nĜ' AS text) collate Latin1_General_CI_AI;
GO

select 1 where CAST('BleȘȘing' AS ntext) collate Latin1_General_CI_AI like CAST('%ŝ%nĜ' AS ntext) collate Latin1_General_CI_AI;
GO

select 1 where CAST('BleȘȘing' AS varchar) collate Latin1_General_CI_AI like CAST('%ŝ%nĜ' AS varchar) collate Latin1_General_CI_AI;
GO

select 1 where CAST('BleȘȘing' AS nvarchar) collate Latin1_General_CI_AI like CAST('%ŝ%nĜ' AS nvarchar) collate Latin1_General_CI_AI;
GO

select 1 where CAST('BleȘȘing' AS char) collate Latin1_General_CI_AI like '%ŝ%nĜ' collate Latin1_General_CI_AI;
GO

select 1 where CAST('BleȘȘing' AS nchar) collate Latin1_General_CI_AI like '%ŝ%nĜ' collate Latin1_General_CI_AI;
GO

-- CASE 4: T_ReLabelType (T_Var) LIKE T_Const
-- Simple matches
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'cafe';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'jalapeno';
GO

-- Wildcards
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 're%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%n%';
GO

-- Case insensitive
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'TELefONO';
GO

-- Accents variations 
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'resume';
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'movie';
GO

-- Multiple accented characters
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'naïve';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'Piñata';
GO

-- Different positions
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%é%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%ñ%';
GO

-- Wildcard start
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'ch%';
GO

-- Wildcard end 
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%is';
GO

-- Wildcard middle
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%é%';
GO

-- Multiple wildcards 
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%ia%s';
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'orange';
GO

-- Diacritic variations
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'jalapen%';
GO

-- Different accented vowels
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'e%ito';
GO

SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'c%eR';
GO

-- test_like_for_AI_prepare_t1_ci with ñ 
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%ñ%';
GO

-- test_like_for_AI_prepare_t1_ci with ü
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%ú%';
GO

-- different datatypes
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_v LIKE 'cafe';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_v LIKE 'ch%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_v LIKE '%ñ%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_v LIKE '%is';
GO

SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_t LIKE 'cafe';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_t LIKE 'ch%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_t LIKE '%ñ%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_t LIKE '%is';
GO

SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_ntext LIKE 'cafe';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_ntext LIKE 'ch%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_ntext LIKE '%ñ%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_ntext LIKE '%is';
GO

SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_c LIKE 'cafe';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_c LIKE 'ch%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_c LIKE '%ñ%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_c LIKE '%is';
GO

SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_nchar LIKE 'cafe';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_nchar LIKE 'ch%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_nchar LIKE '%ñ%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col_nchar LIKE '%is';
GO


-- CASE 5: T_ReLabelType(T_Var) LIKE T_CollateExpr(T_Const)
-- Simple matches
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'cafe' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'jalapeno' COLLATE Latin1_General_CI_AI;
GO

-- Wildcards
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 're%' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%n%' COLLATE Latin1_General_CI_AI;
GO

-- Case insensitive
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'TELefONO' COLLATE Latin1_General_CI_AI;
GO

-- Accents variations 
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'resume' COLLATE Latin1_General_CI_AI;
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'movie' COLLATE Latin1_General_CI_AI;
GO

-- Multiple accented characters
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'naïve' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'Piñata' COLLATE Latin1_General_CI_AI;
GO

-- Different positions
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%é%' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%ñ%' COLLATE Latin1_General_CI_AI;
GO

-- Wildcard start
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'ch%' COLLATE Latin1_General_CI_AI;
GO

-- Wildcard end 
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%is' COLLATE Latin1_General_CI_AI;
GO

-- Wildcard middle
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%é%' COLLATE Latin1_General_CI_AI;
GO

-- Multiple wildcards 
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%ia%s' COLLATE Latin1_General_CI_AI;
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'orange' COLLATE Latin1_General_CI_AI;
GO

-- Diacritic variations
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'jalapen%' COLLATE Latin1_General_CI_AI;
GO

-- Different accented vowels
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'e%ito' COLLATE Latin1_General_CI_AI;
GO

SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'c%eR' COLLATE Latin1_General_CI_AI;
GO

-- test_like_for_AI_prepare_t1_ci with ñ 
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%ñ%' COLLATE Latin1_General_CI_AI;
GO

-- test_like_for_AI_prepare_t1_ci with ü
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%ú%' COLLATE Latin1_General_CI_AI;
GO


-- CASE 6: T_ReLabelType(T_Var) LIKE T_ReLabelType(T_Var)
SELECT * FROM test_like_for_AI_prepare_t6_ci WHERE a LIKE b
GO

-- CASE 7: T_CollateExpr(T_ReLabel(T_Var)) LIKE T_Const
-- Simple matches
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'cafe';
GO
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'jalapeno';
GO

-- Wildcards
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 're%';
GO
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%n%';
GO

-- Case insensitive
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'TELefONO';
GO

-- Accents variations 
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'resume';
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'movie';
GO

-- Multiple accented characters
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'naïve';
GO
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'Piñata';
GO

-- Wildcard start
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'ch%';
GO

-- Wildcard end 
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%is';
GO

-- Wildcard middle
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%é%';
GO

-- Multiple wildcards 
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%ia%s';
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'orange';
GO

-- Diacritic variations
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'jalapen%';
GO

-- Different accented vowels
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'e%ito';
GO

SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'c%eR';
GO

-- test_like_for_AI_prepare_t7_ci with ñ 
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%ñ%';
GO

-- test_like_for_AI_prepare_t7_ci with ü
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%ú%';
GO


-- CASE 8: T_CollateExpr(T_ReLabel(T_Var)) LIKE T_CollateExpr(T_Const)
-- Simple matches
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'cafe' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'jalapeno' COLLATE Latin1_General_CI_AI;
GO

-- Wildcards
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 're%' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%n%' COLLATE Latin1_General_CI_AI;
GO

-- Case insensitive
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'TELefONO' COLLATE Latin1_General_CI_AI;
GO

-- Accents variations 
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'resume' COLLATE Latin1_General_CI_AI;
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'movie' COLLATE Latin1_General_CI_AI;
GO

-- Multiple accented characters
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'naïve' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'Piñata' COLLATE Latin1_General_CI_AI;
GO

-- Different positions
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%é%' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%ñ%' COLLATE Latin1_General_CI_AI;
GO

-- Wildcard start
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'ch%' COLLATE Latin1_General_CI_AI;
GO

-- Wildcard end 
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%is' COLLATE Latin1_General_CI_AI;
GO

-- Wildcard middle
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%é%' COLLATE Latin1_General_CI_AI;
GO

-- Multiple wildcards 
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%ia%s' COLLATE Latin1_General_CI_AI;
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'orange' COLLATE Latin1_General_CI_AI;
GO

-- Diacritic variations
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'jalapen%' COLLATE Latin1_General_CI_AI;
GO

-- Different accented vowels
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'e%ito' COLLATE Latin1_General_CI_AI;
GO

SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'c%eR' COLLATE Latin1_General_CI_AI;
GO

-- test_like_for_AI_prepare_t7_ci with ñ 
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%ñ%' COLLATE Latin1_General_CI_AI;
GO

-- test_like_for_AI_prepare_t7_ci with ü
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%ú%' COLLATE Latin1_General_CI_AI;
GO


-- CASE 9: T_FuncExpr LIKE T_CollateExpr(T_Const)
-- Simple matches
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE UPPER(col) COLLATE Latin1_General_CI_AI LIKE 'cafe' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE UPPER(col) COLLATE Latin1_General_CI_AI LIKE 'jalapeno' COLLATE Latin1_General_CI_AI;
GO

-- Wildcards
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE SUBSTRING(col, 1, 3) COLLATE Latin1_General_CI_AI LIKE 're%' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE LOWER(col) COLLATE Latin1_General_CI_AI LIKE '%n%' COLLATE Latin1_General_CI_AI;
GO

-- Case insensitive
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE LOWER(col) COLLATE Latin1_General_CI_AI LIKE 'TELefONO' COLLATE Latin1_General_CI_AI;
GO

-- Accents variations 
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE UPPER(col) COLLATE Latin1_General_CI_AI LIKE 'resume' COLLATE Latin1_General_CI_AI;
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE UPPER(LOWER(col)) COLLATE Latin1_General_CI_AI LIKE 'movie' COLLATE Latin1_General_CI_AI;
GO

-- Multiple accented characters
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE UPPER(LOWER(col)) COLLATE Latin1_General_CI_AI LIKE 'naïve' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE LOWER(UPPER(col)) COLLATE Latin1_General_CI_AI LIKE 'Piñata' COLLATE Latin1_General_CI_AI;
GO

-- Different positions
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE SUBSTRING(UPPER(LOWER(col)), 1, 3) COLLATE Latin1_General_CI_AI LIKE '%é%' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE UPPER(col) COLLATE Latin1_General_CI_AI LIKE '%ñ%' COLLATE Latin1_General_CI_AI;
GO


-- Wildcard start
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE SUBSTRING(col, 1, 3) COLLATE Latin1_General_CI_AI LIKE 'ch%' COLLATE Latin1_General_CI_AI;
GO

-- Wildcard end 
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE UPPER(col) COLLATE Latin1_General_CI_AI LIKE '%is' COLLATE Latin1_General_CI_AI;
GO

-- Wildcard middle
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE UPPER(col) COLLATE Latin1_General_CI_AI LIKE '%é%' COLLATE Latin1_General_CI_AI;
GO

-- Multiple wildcards 
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE UPPER(col) COLLATE Latin1_General_CI_AI LIKE '%ia%s' COLLATE Latin1_General_CI_AI;
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE UPPER(col) COLLATE Latin1_General_CI_AI LIKE 'orange' COLLATE Latin1_General_CI_AI;
GO

-- Diacritic variations
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE LOWER(col) COLLATE Latin1_General_CI_AI LIKE 'jalapen%' COLLATE Latin1_General_CI_AI;
GO

-- Different accented vowels
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE LOWER(col) COLLATE Latin1_General_CI_AI LIKE 'e%ito' COLLATE Latin1_General_CI_AI;
GO

SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE LOWER(col) COLLATE Latin1_General_CI_AI LIKE 'c%eR' COLLATE Latin1_General_CI_AI;
GO

-- test_like_for_AI_prepare_t7_ci with ñ 
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE LOWER(col) COLLATE Latin1_General_CI_AI LIKE '%ñ%' COLLATE Latin1_General_CI_AI;
GO

-- test_like_for_AI_prepare_t7_ci with ü
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE LOWER(col) COLLATE Latin1_General_CI_AI LIKE '%ú%' COLLATE Latin1_General_CI_AI;
GO

-- same experiments as above with column collated with Latin1_General_CI_AI
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE LOWER(col) LIKE 'c%eR';
GO

SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE LOWER(col) LIKE 'jalapen%';
GO

SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE UPPER(col) LIKE '%ia%s';
GO

SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE SUBSTRING(col, 1, 3) LIKE 'ch%';
GO

-- CASE 10: T_ReLabelType(T_Param) LIKE T_ReLabelType(T_Param)
declare @a varchar='RaŊdom';
declare @b varchar='Ra%';
SELECT 1 WHERE @a LIKE @b COLLATE Latin1_General_CI_AI;
GO

-- number of chars > 8000
DECLARE @var VARCHAR(MAX);
SET @var = REPLICATE('A', 8005);
SELECT 1 WHERE @var COLLATE Latin1_General_CI_AI LIKE '%a%'
GO

-- CASE 11: T_ReLabelType(T_Var) LIKE T_ReLabelType(T_Param)
declare @c varchar(51)='e%ito';
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE @c;
GO

declare @c varchar(51)='c%eR';
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE @c;
GO

declare @d varchar(51)='%ú%';
SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col LIKE @d COLLATE Latin1_General_CI_AI;
GO

-- CASE 12: LIKE inside CASE
SELECT CASE WHEN col COLLATE Latin1_General_CI_AI LIKE 'jalapen%' THEN 1 ELSE 2 END FROM test_like_for_AI_prepare_t7_ci;
GO

SELECT CASE WHEN col LIKE '%is' COLLATE Latin1_General_CI_AI THEN 1 ELSE 2 END FROM test_like_for_AI_prepare_t7_ci;
GO

-- CASE 13: SUBQUERY

-- SIMPLE SUBQUERY (LIKE OPERATOR AS SUBQUERY)
-- returns 1 row
SELECT col1 FROM test_like_for_AI_prepare_t13_1_ci WHERE col2 IN (SELECT col FROM test_like_for_AI_prepare_t13_2_ci WHERE col LIKE 'Àb%');
GO

-- returns 2 rows
SELECT col1 FROM test_like_for_AI_prepare_t13_1_ci WHERE col2 IN (SELECT col FROM test_like_for_AI_prepare_t13_2_ci WHERE col LIKE '%aŖ%l%');
GO

-- returns 1 rows
SELECT col1 FROM test_like_for_AI_prepare_t13_1_ci WHERE col2 IN (SELECT col FROM test_like_for_AI_prepare_t13_2_ci WHERE col LIKE '%ţÕ');
GO

-- COMPLEX SUBQUERY (LIKE OPERATOR CONRTAINING SUBQUERY)
-- returns 1 row
SELECT * FROM test_like_for_AI_prepare_t13_1_ci WHERE col1 LIKE (CASE WHEN (SELECT 1 WHERE 'shaEpéD' LIKE 'Ș%' COLLATE Latin1_General_CI_AI) = 1 THEN 'TEñ%' ELSE 'ár%' END);
GO

SELECT * FROM test_like_for_AI_prepare_t13_1_ci WHERE col1 LIKE (CASE WHEN (SELECT 1 WHERE 'naïve' LIKE 'Ș%' COLLATE Latin1_General_CI_AI) = 1 THEN 'TEñ%' ELSE 'ár%' END);
GO

-- returns 4 rows
SELECT * FROM test_like_for_AI_prepare_t13_1_ci WHERE col1 LIKE (CASE WHEN 1 = 1 THEN '%I%' ELSE '%t%' END);
GO

-- rerurns 4 rows
SELECT * FROM test_like_for_AI_prepare_t13_1_ci WHERE col1 LIKE (CASE WHEN 2 = 1 THEN '%I%' ELSE '%t%' END);
GO

-- returns 2 rows
SELECT * FROM test_like_for_AI_prepare_t13_1_ci WHERE col1 LIKE (CASE WHEN (SELECT 1 WHERE 'shaEpéD' LIKE 'Ș%' COLLATE Latin1_General_CI_AI) = 1 THEN '%a' ELSE '%é' END);
GO

-- returns 4 rows
SELECT * FROM test_like_for_AI_prepare_t13_1_ci WHERE col1 LIKE (CASE WHEN (SELECT 1 WHERE 'naïve' LIKE 'Ș%' COLLATE Latin1_General_CI_AI) = 1 THEN '%a' ELSE '%é' END);
GO

-- returns 1 row
SELECT * FROM test_like_for_AI_prepare_t13_1_ci WHERE col1 IN (SELECT col1 FROM test_like_for_AI_prepare_t13_1_ci t1 JOIN test_like_for_AI_prepare_t13_2_ci t2 ON t1.col1 LIKE 'r%' AND t2.col LIKE 'r%');
GO

-- returns 1 row
SELECT col1 FROM test_like_for_AI_prepare_t13_1_ci WHERE col2 IN (SELECT col FROM test_like_for_AI_prepare_t13_2_ci WHERE col LIKE test_like_for_AI_prepare_t13_1_ci.col1);
GO

-- CASE 14: DIFFERENT WILDCARDS
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'ca_e';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'c[ĥżâ]%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%[^oa]ñ%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%[i-s]';
GO

-- CASE 15: LIKE CLAUSE AS FUNCTION ARGUMENT - works when LIKE returns one row (expected)
SELECT SUM(10 + (SELECT 90 WHERE 'cantáis' like 'Cá%' collate Latin1_General_CI_AI));
GO

SELECT CONCAT('Hi ', (SELECT col FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE 'ca_e'));
GO

SELECT UPPER((SELECT col FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE '%oNo'));
GO

-- CASE 16: JOIN
SELECT * FROM test_like_for_AI_prepare_t13_1_ci JOIN test_like_for_AI_prepare_t13_2_ci on test_like_for_AI_prepare_t13_1_ci.col2 LIKE test_like_for_AI_prepare_t13_2_ci.col
GO

SELECT * FROM test_like_for_AI_prepare_t13_1_ci t1 JOIN test_like_for_AI_prepare_t13_2_ci t2 ON t1.col1 LIKE 'r%' AND t2.col LIKE 'r%';
GO

SELECT * FROM test_like_for_AI_prepare_t13_1_ci t1 JOIN test_like_for_AI_prepare_t13_2_ci t2 ON t1.col1 LIKE '%a%' AND t2.col LIKE '%a%';
GO

SELECT * FROM test_like_for_AI_prepare_t13_1_ci t1 JOIN test_like_for_AI_prepare_t13_2_ci t2 ON t1.col2 LIKE '%o' AND t2.col LIKE '%o';
GO

-- CASE 17: PREPARED STATEMENTS
DECLARE @prefix NVARCHAR(50) = 'ár';
EXEC sp_executesql N'SELECT * FROM test_like_for_AI_prepare_t13_1_ci WHERE col1 LIKE @prefix + ''%'';', N'@prefix NVARCHAR(50)', @prefix;
GO

DECLARE @pattern NVARCHAR(50) = '%bo%';
EXEC sp_executesql N'SELECT * FROM test_like_for_AI_prepare_t13_1_ci WHERE col1 LIKE @pattern + ''%'';', N'@pattern NVARCHAR(50)', @pattern;
GO

DECLARE @suffix NVARCHAR(50) = 'éR';
EXEC sp_executesql N'SELECT * FROM test_like_for_AI_prepare_t13_1_ci WHERE col1 LIKE ''%'' + @suffix;', N'@suffix NVARCHAR(50)', @suffix;
GO

-- CASE 18: LIKE OBJECT_NAME()
SELECT COUNT(*) FROM test_like_for_AI_prepare_t13_1_ci WHERE 1=1 AND NOT OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_ci')) LIKE '%Blah%' COLLATE Latin1_General_CI_AI;
GO

SELECT COUNT(*) FROM test_like_for_AI_prepare_t13_1_ci WHERE 1=1 AND OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_ci')) LIKE '%AI_prepãr%' COLLATE Latin1_General_CI_AI;
GO

SELECT COUNT(*) FROM test_like_for_AI_prepare_t13_1_ci WHERE 1=1 AND NOT OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_ci')) LIKE 'Blah%' COLLATE Latin1_General_CI_AI;
GO

SELECT COUNT(*) FROM test_like_for_AI_prepare_t13_1_ci WHERE 1=1 AND NOT OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_ci')) LIKE '%Blah' COLLATE Latin1_General_CI_AI;
GO

SELECT COUNT(*) FROM test_like_for_AI_prepare_t13_1_ci WHERE NOT 1>1 AND ((NOT OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_ci')) LIKE '%Blah%' COLLATE Latin1_General_CI_AI) AND (OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_ci')) COLLATE Latin1_General_CI_AI LIKE '%like_for_AI%'))
GO

SELECT COUNT(*) FROM test_like_for_AI_prepare_t13_1_ci WHERE 1>1 OR ((NOT OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_ci')) COLLATE Latin1_General_CI_AI LIKE '%Blah%') AND (NOT OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_ci')) LIKE '%Blâh%' COLLATE Latin1_General_CI_AI))
GO

SELECT COUNT(*) FROM test_like_for_AI_prepare_t13_1_ci WHERE (1=1 AND NOT OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_ci')) COLLATE Latin1_General_CI_AI LIKE '%Blah%') OR ((NOT 2<1) AND (NOT OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_ci')) COLLATE Latin1_General_CI_AI LIKE '%Blâh%'))
GO

-- CASE 19: ESCAPE WITH LIKE
--15% off using ESCAPE; should return rows 19
SELECT * FROM test_like_for_AI_prepare_escape WHERE string COLLATE Latin1_General_CI_AI LIKE '15/% %' ESCAPE '/' ORDER BY c1
GO

--15% off using a different ESCAPE character; should return rows 19
SELECT * FROM test_like_for_AI_prepare_escape WHERE string COLLATE Latin1_General_CI_AI LIKE '15!% %' ESCAPE '!' ORDER BY c1
GO

--15 % off ; should return rows 21
SELECT * FROM test_like_for_AI_prepare_escape WHERE string COLLATE Latin1_General_CI_AI LIKE '15 /%___' ESCAPE '/' ORDER BY c1
GO

--Searching for the escape character itself; should return rows 23
SELECT * FROM test_like_for_AI_prepare_escape WHERE string COLLATE Latin1_General_CI_AI LIKE '15 [%] //off' ESCAPE '/' ORDER BY c1
GO

--As above, but also allow for "[". Should return 3-18, 24
SELECT * FROM test_like_for_AI_prepare_escape WHERE string COLLATE Latin1_General_CI_AI NOT LIKE '%[^a-zA-ZåÅäÄöÖ.[?[]%' ESCAPE '?' ORDER BY c1
GO

SELECT 1 WHERE 'a[abc]b' COLLATE Latin1_General_CI_AI LIKE 'a\[abc]b' escape '\'  -- 1
GO

declare @v varchar = 'a[bc'
SELECT 1 WHERE @v COLLATE Latin1_General_CI_AI LIKE '%[%' escape '~' OR @v COLLATE Latin1_General_CI_AI LIKE '%]%'                -- no row
GO

declare @v varchar = 'a[bc'
SELECT 1 WHERE @v COLLATE Latin1_General_CI_AI LIKE '%~[%' escape '~' OR @v COLLATE Latin1_General_CI_AI LIKE '%~]%' escape '~'   -- no row
GO

declare @v varchar = 'a[bc'
set @v = 'a]bc'
SELECT 1 WHERE @v COLLATE Latin1_General_CI_AI LIKE '%[%' escape '~' OR @v COLLATE Latin1_General_CI_AI LIKE '%]%'                -- no row
GO


declare @v varchar = 'a[bc'
set @v = 'a]bc'
SELECT 1 WHERE @v LIKE '%~[%' COLLATE Latin1_General_CI_AI escape '~' OR @v LIKE '%~]%' escape '~'  COLLATE Latin1_General_CI_AI -- no row
GO

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = 'a[abc]b'set @p = 'a\[abc]b' set @esc = '\' -- 1
SELECT 1 WHERE @v COLLATE Latin1_General_CI_AI LIKE @p escape @esc 
GO

SELECT 1 WHERE '_ab' COLLATE Latin1_General_CI_AI LIKE '\_ab'  escape '\'         -- 1 
GO
SELECT 1 WHERE '%AAABBB%' COLLATE Latin1_General_CI_AI LIKE '\%AAA%' escape '\'   -- 1
GO

SELECT 1 WHERE 'AB[C]D' COLLATE Latin1_General_CI_AI LIKE 'AB~[C]D' ESCAPE '~'  -- 1
GO

SELECT 1 WHERE 'AB[C]D' LIKE 'AB\[C]D' COLLATE Latin1_General_CI_AI ESCAPE '\'  -- 1
GO

SELECT 1 WHERE 'AB[C]D' LIKE 'AB\[C]D' ESCAPE '\'  COLLATE Latin1_General_CI_AI  -- 1
GO

SELECT 1 WHERE 'AB[C]D' LIKE 'AB [C]D' COLLATE Latin1_General_CI_AI ESCAPE ' '  -- 1
GO

SELECT 1 WHERE 'AB[C]D' LIKE 'AB[C]D' COLLATE Latin1_General_CI_AI ESCAPE 'B'   -- no row
GO
SELECT 1 WHERE 'AB[C]D' LIKE 'ABB[C]D' COLLATE Latin1_General_CI_AI ESCAPE 'B'  -- no row
GO

SELECT 1 WHERE 'AB[C]D' LIKE 'ABZ[C]D' ESCAPE 'Z' COLLATE Latin1_General_CI_AI -- 1
GO
SELECT 1 WHERE 'AB[C]D' COLLATE Latin1_General_CI_AI LIKE 'ABZ[C]D' ESCAPE 'z'  -- no row! Note: SQL Server treats the escape as case-sensitive!
GO

SELECT 1 WHERE null like null COLLATE Latin1_General_CI_AI escape null -- no row
GO

SELECT 1 WHERE null COLLATE Latin1_General_CI_AI like null escape null -- no row
GO

SELECT 1 WHERE null COLLATE Latin1_General_CI_AI like null COLLATE Latin1_General_CI_AI escape null -- no row
GO

SELECT 1 WHERE null like null escape null COLLATE Latin1_General_CI_AI  -- no row
GO

SELECT 1 WHERE 'ABCD' LIKE 'AB[C]D' COLLATE Latin1_General_CI_AI ESCAPE ''  -- should raise error , BABEL-4271
GO
SELECT 1 WHERE 'ABCD' COLLATE Latin1_General_CI_AI LIKE 'AB[C]D' ESCAPE 'xy'  -- raise error
GO

SELECT 1 WHERE 'ABCD' COLLATE Latin1_General_CI_AI LIKE 'AB[C]D' ESCAPE null;
GO

-- CASE 20: LIKE IN TARGET LIST
SELECT col, CASE WHEN col LIKE 'ch%' THEN 'Prefix Match' ELSE 'No Match' END AS match_status FROM test_like_for_AI_prepare_t1_ci;
GO

SELECT col,
       CASE 
           WHEN col LIKE 'prefix%' THEN 'Prefix Match'
           WHEN col LIKE '%ONO' THEN 'Suffix Match'
           ELSE 'No Match' 
       END AS match_category
FROM test_like_for_AI_prepare_t1_ci;
GO

SELECT col,
       CASE 
           WHEN col LIKE 'prefix%' THEN 'Prefix Match'
           WHEN col LIKE '%suffix' THEN 'Suffix Match'
           WHEN col LIKE '%íc%' THEN 'Match'
           ELSE 'No Match' 
       END AS extracted_substring
FROM test_like_for_AI_prepare_t1_ci;
GO

-- CASE 21: COLUMN LEVEL CONSTRAINT
-- Test the constraint
-- This insert will succeed
INSERT INTO test_like_for_AI_prepare_employee_CI_AI (id, name) VALUES (1, 'Adam');
GO
INSERT INTO test_like_for_AI_prepare_employee_CI_AI (id, name) VALUES (2, 'ådAm');
GO
INSERT INTO test_like_for_AI_prepare_employee_CI_AI (id, name) VALUES (3, 'ädam');
GO
INSERT INTO test_like_for_AI_prepare_employee_CI_AI (id, name) VALUES (4, 'adam');
GO
INSERT INTO test_like_for_AI_prepare_employee_CI_AI (id, name) VALUES (5, 'ædam');
GO

-- This insert will fail due to the check constraint
INSERT INTO test_like_for_AI_prepare_employee_CI_AI (id, name) VALUES (6, 'Bob');
GO
INSERT INTO test_like_for_AI_prepare_employee_CI_AI (id, name) VALUES (7, 'ôob');
GO

SELECT * FROM test_like_for_AI_prepare_employee_CI_AI;
GO

-- CASE 22: Sublink (with other combinations)
SELECT 1 WHERE 'Götterdämmerung' LIKE (SELECT 'Götterdämmerung' COLLATE Latin1_General_CI_AI);
GO

SELECT 1 WHERE 'Götterdämmerung' LIKE (SELECT 'Götterdämmerung' COLLATE Latin1_General_CI_AI) COLLATE Latin1_General_CI_AI;
GO

SELECT 1 WHERE 'Götterdämmerung' COLLATE Latin1_General_CI_AI LIKE (SELECT 'Götterdämmerung' COLLATE Latin1_General_CI_AI);
GO

SELECT 1 WHERE 'Götterdämmerung' COLLATE Latin1_General_CI_AI LIKE (SELECT 'Götterdämmerung' COLLATE Latin1_General_CI_AI) COLLATE Latin1_General_CI_AI;
GO

SELECT 1 WHERE N'chaptéR' LIKE (SELECT col FROM test_like_for_AI_prepare_t1_ci where col like N'chaptéR');
GO

SELECT 1 WHERE N'chaptéR' COLLATE Latin1_General_CI_AI LIKE (SELECT col FROM test_like_for_AI_prepare_t1_ci where col like N'chaptéR');
GO

SELECT 1 WHERE (SELECT 'Götterdämmerung' COLLATE Latin1_General_CI_AI) LIKE (SELECT 'Götterdämmerung' COLLATE Latin1_General_CI_AI);
GO

SELECT 1 WHERE (SELECT 'chaptéR' COLLATE Latin1_General_CI_AI) LIKE (SELECT col FROM test_like_for_AI_prepare_t1_ci where col like N'chaptéR');
GO

SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE (SELECT a FROM test_like_for_AI_prepare_t6_ci WHERE a LIKE 'spain') LIKE '%pai%';
GO

SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE 'spain' LIKE (SELECT a FROM test_like_for_AI_prepare_t6_ci WHERE a LIKE 'spain');
GO

SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE (SELECT a FROM test_like_for_AI_prepare_t6_ci WHERE a LIKE 'spain') LIKE (SELECT a FROM test_like_for_AI_prepare_t6_ci WHERE b LIKE 'spain');
GO

SELECT col, (SELECT a FROM test_like_for_AI_prepare_t6_ci WHERE a LIKE 'spain') AS subquery_result FROM test_like_for_AI_prepare_t1_ci 
WHERE col LIKE (SELECT col FROM test_like_for_AI_prepare_t7_ci WHERE col LIKE 'résumé' COLLATE Latin1_General_CI_AI);
GO

SELECT col, (SELECT a FROM test_like_for_AI_prepare_t6_ci WHERE a LIKE 'spain') AS subquery_result FROM test_like_for_AI_prepare_t1_ci
WHERE (SELECT col FROM test_like_for_AI_prepare_t7_ci WHERE col LIKE 'résumé' COLLATE Latin1_General_CI_AI) LIKE 'ResumE' COLLATE Latin1_General_CI_AI;
GO

SELECT col, (SELECT a FROM test_like_for_AI_prepare_t6_ci WHERE a LIKE 'spain') AS subquery_result FROM test_like_for_AI_prepare_t1_ci
WHERE (SELECT col FROM test_like_for_AI_prepare_t7_ci WHERE col LIKE 'résumé' COLLATE Latin1_General_CI_AI) LIKE 
(SELECT col FROM test_like_for_AI_prepare_t7_ci WHERE col LIKE 'résumé' COLLATE Latin1_General_CI_AI);
GO

SELECT col, 
(SELECT a FROM test_like_for_AI_prepare_t6_ci WHERE a LIKE 'spain') AS subquery_result1,
(SELECT col FROM test_like_for_AI_prepare_t7_ci WHERE col LIKE 'résumé' COLLATE Latin1_General_CI_AI) AS subquery_result2
FROM test_like_for_AI_prepare_t1_ci
WHERE (SELECT col FROM test_like_for_AI_prepare_t7_ci WHERE col LIKE 'résumé' COLLATE Latin1_General_CI_AI) LIKE 'ré%';
GO

SELECT col, 
(SELECT a FROM test_like_for_AI_prepare_t6_ci WHERE a LIKE 'spain' COLLATE Latin1_General_CI_AI) AS subquery_result
FROM test_like_for_AI_prepare_t1_ci
WHERE 
(col IS NOT NULL AND EXISTS (SELECT 1 FROM test_like_for_AI_prepare_t7_ci WHERE col_v LIKE 'résumé' COLLATE Latin1_General_CI_AI)) OR
(col IS NULL AND col LIKE 'ré%' COLLATE Latin1_General_CI_AI);
GO

-- CASE 23: T_CoerceViaIO (with other combinations)
SELECT 1 WHERE N'123' collate Latin1_General_CI_AI LIKE CAST(123 as nvarchar(3));
GO

SELECT 1 WHERE N'123' collate Latin1_General_CI_AI LIKE CAST(123 as varchar(3));
GO

SELECT 1 WHERE N'123' collate Latin1_General_CI_AI LIKE CAST(123 as char(3));
GO

SELECT 1 WHERE  CAST(123 as nvarchar(3)) LIKE N'123' collate Latin1_General_CI_AI;
GO

SELECT 1 WHERE  CAST(123 as varchar(3)) LIKE N'123' collate Latin1_General_CI_AI;
GO

SELECT 1 WHERE  CAST(123 as char(3)) LIKE N'123' collate Latin1_General_CI_AI;
GO

SELECT c1, (SELECT CAST(c1 AS NVARCHAR(50)) WHERE CAST(c1 AS NVARCHAR(50)) COLLATE Latin1_General_CI_AI LIKE '1%') FROM test_like_for_AI_prepare_escape;
GO

SELECT c1, (SELECT string WHERE string COLLATE Latin1_General_CI_AI LIKE CAST('451201%' AS NVARCHAR(50))) FROM test_like_for_AI_prepare_escape;
GO

SELECT c1, (SELECT CAST(c1 AS NVARCHAR(50)) WHERE CAST(c1 AS NVARCHAR(50)) COLLATE Latin1_General_CI_AI LIKE CAST('1%' AS NVARCHAR(50))) FROM test_like_for_AI_prepare_escape;
GO

SELECT c1, string, (SELECT CAST(string AS NVARCHAR(50)) WHERE CAST(string AS NVARCHAR(50)) COLLATE Latin1_General_CI_AI LIKE '451201%') FROM test_like_for_AI_prepare_escape;
GO

------------------- CS_AI ----------------------
-- CASE 1: T_Const LIKE T_CollateExpr(T_Const)
select 1 where 'cantáis' like 'cá%' collate Latin1_General_CS_AI;
GO

select 1 where CAST('cantáis' AS text) like CAST('Cá%' AS text) collate Latin1_General_CS_AI;
GO

select 1 where CAST('cantáis' AS ntext) like CAST('Cá%' AS ntext) collate Latin1_General_CS_AI;
GO

select 1 where CAST('cantáis' AS varchar) like CAST('Cá%' AS varchar) collate Latin1_General_CS_AI;
GO

select 1 where CAST('cantáis' AS nvarchar) like CAST('Cá%' AS nvarchar) collate Latin1_General_CS_AI;
GO

select 1 where CAST('cantáis' AS char) like 'Cá%' collate Latin1_General_CS_AI;
GO

select 1 where CAST('cantáis' AS nchar) like 'Cá%' collate Latin1_General_CS_AI;
GO

select 1 where 'shaEpéD' like '%ǣ%e%' collate Latin1_General_CS_AI;
GO

select 1 where 'BleȘȘing' like '%nĝ' collate Latin1_General_CS_AI
GO

-- CASE 2: T_CollateExpr(T_Const) LIKE T_Const
select 1 where 'cOntáis' collate Latin1_General_CS_AI like 'cŐ%';
GO

select 1 where 'shaEpüD' collate Latin1_General_CS_AI like '%ǣ%ú%';
GO

select 1 where CAST('shaEpüD' AS text) collate Latin1_General_CS_AI like CAST('%Æ%ú%' AS text);
GO

select 1 where CAST('shaEpüD' AS ntext) collate Latin1_General_CS_AI like CAST('%Æ%ú%' AS ntext);
GO

select 1 where CAST('shaEpüD' AS varchar) collate Latin1_General_CS_AI like CAST('%Æ%ú%' AS varchar);
GO

select 1 where CAST('shaEpüD' AS nvarchar) collate Latin1_General_CS_AI like CAST('%Æ%ú%' AS nvarchar);
GO

select 1 where CAST('shaEpüD' AS char) collate Latin1_General_CS_AI like '%Æ%ú%';
GO

select 1 where CAST('shaEpüD' AS nchar) collate Latin1_General_CS_AI like '%Æ%ú%';
GO

select 1 where 'BlesȘing' collate Latin1_General_CS_AI like '%ŝ%nĝ';
GO

-- CASE 3: T_CollateExpr(T_Const) LIKE T_CollateExpr(T_Const)
select 1 where 'cOntáis' collate Latin1_General_CS_AI like 'cŐ%' collate Latin1_General_CS_AI;
GO

select 1 where 'shaEpüD' collate Latin1_General_CS_AI like '%ǣ%ú%' collate Latin1_General_CS_AI;
GO

select 1 where 'BleȘsing' collate Latin1_General_CS_AI like '%ŝ%ng' collate Latin1_General_CS_AI;
GO

select 1 where CAST('BleȘȘing' AS text) collate Latin1_General_CS_AI like CAST('%ŝ%nĜ' AS text) collate Latin1_General_CS_AI;
GO

select 1 where CAST('BleȘȘing' AS ntext) collate Latin1_General_CS_AI like CAST('%ŝ%nĜ' AS ntext) collate Latin1_General_CS_AI;
GO

select 1 where CAST('BleȘȘing' AS varchar) collate Latin1_General_CS_AI like CAST('%ŝ%nĜ' AS varchar) collate Latin1_General_CS_AI;
GO

select 1 where CAST('BleȘȘing' AS nvarchar) collate Latin1_General_CS_AI like CAST('%ŝ%nĜ' AS nvarchar) collate Latin1_General_CS_AI;
GO

select 1 where CAST('BleȘȘing' AS char) collate Latin1_General_CS_AI like '%ŝ%nĜ' collate Latin1_General_CS_AI;
GO

select 1 where CAST('BleȘȘing' AS nchar) collate Latin1_General_CS_AI like '%ŝ%nĜ' collate Latin1_General_CS_AI;
GO

-- CASE 4: T_ReLabelType (T_Var) LIKE T_Const
-- Simple matches
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'cafe';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'jalapeno';
GO

-- Wildcards
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 're%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%n%';
GO

-- Case insensitive
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'TELefONO';
GO

-- Accents variations 
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'resume';
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'movie';
GO

-- Multiple accented characters
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'naïve';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'Piñata';
GO

-- Different positions
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%é%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%ñ%';
GO

-- Wildcard start
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'ch%';
GO

-- Wildcard end 
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%is';
GO

-- Wildcard middle
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%é%';
GO

-- Multiple wildcards 
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%ia%s';
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'orange';
GO

-- Diacritic variations
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'jalapen%';
GO

-- Different accented vowels
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'e%ito';
GO

SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'c%eR';
GO

-- test_like_for_AI_prepare_t1_cs with ñ 
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%ñ%';
GO

-- test_like_for_AI_prepare_t1_cs with ü
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%ú%';
GO

-- different datatypes
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_v LIKE 'cafe';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_v LIKE 'ch%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_v LIKE '%ñ%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_v LIKE '%is';
GO

SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_t LIKE 'cafe';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_t LIKE 'ch%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_t LIKE '%ñ%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_t LIKE '%is';
GO

SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_ntext LIKE 'cafe';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_ntext LIKE 'ch%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_ntext LIKE '%ñ%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_ntext LIKE '%is';
GO

SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_c LIKE 'cafe';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_c LIKE 'ch%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_c LIKE '%ñ%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_c LIKE '%is';
GO

SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_nchar LIKE 'cafe';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_nchar LIKE 'ch%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_nchar LIKE '%ñ%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col_nchar LIKE '%is';
GO

-- CASE 5: T_ReLabelType(T_Var) LIKE T_CollateExpr(T_Const)
-- Simple matches
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'cafe' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'jalapeno' COLLATE Latin1_General_CS_AI;
GO

-- Wildcards
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 're%' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%n%' COLLATE Latin1_General_CS_AI;
GO

-- Case insensitive
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'TELefONO' COLLATE Latin1_General_CS_AI;
GO

-- Accents variations 
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'resume' COLLATE Latin1_General_CS_AI;
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'movie' COLLATE Latin1_General_CS_AI;
GO

-- Multiple accented characters
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'naïve' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'Piñata' COLLATE Latin1_General_CS_AI;
GO

-- Different positions
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%é%' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%ñ%' COLLATE Latin1_General_CS_AI;
GO

-- Wildcard start
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'ch%' COLLATE Latin1_General_CS_AI;
GO

-- Wildcard end 
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%is' COLLATE Latin1_General_CS_AI;
GO

-- Wildcard middle
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%é%' COLLATE Latin1_General_CS_AI;
GO

-- Multiple wildcards 
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%ia%s' COLLATE Latin1_General_CS_AI;
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'orange' COLLATE Latin1_General_CS_AI;
GO

-- Diacritic variations
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'jalapen%' COLLATE Latin1_General_CS_AI;
GO

-- Different accented vowels
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'e%ito' COLLATE Latin1_General_CS_AI;
GO

SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'c%eR' COLLATE Latin1_General_CS_AI;
GO

-- test_like_for_AI_prepare_t1_cs with ñ 
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%ñ%' COLLATE Latin1_General_CS_AI;
GO

-- test_like_for_AI_prepare_t1_cs with ü
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%ú%' COLLATE Latin1_General_CS_AI;
GO


-- CASE 6: T_ReLabelType(T_Var) LIKE T_ReLabelType(T_Var)
SELECT * FROM test_like_for_AI_prepare_t6_cs WHERE a LIKE b
GO

-- CASE 7: T_CollateExpr(T_ReLabel(T_Var)) LIKE T_Const
-- Simple matches
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'cafe';
GO
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'jalapeno';
GO

-- Wildcards
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 're%';
GO
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%n%';
GO

-- Case insensitive
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'TELefONO';
GO

-- Accents variations 
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'resume';
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'movie';
GO

-- Multiple accented characters
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'naïve';
GO
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'Piñata';
GO

-- Wildcard start
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'ch%';
GO

-- Wildcard end 
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%is';
GO

-- Wildcard middle
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%é%';
GO

-- Multiple wildcards 
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%ia%s';
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'orange';
GO

-- Diacritic variations
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'jalapen%';
GO

-- Different accented vowels
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'e%ito';
GO

SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'c%eR';
GO

-- test_like_for_AI_prepare_t7_cs with ñ 
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%ñ%';
GO

-- test_like_for_AI_prepare_t7_cs with ü
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%ú%';
GO


-- CASE 8: T_CollateExpr(T_ReLabel(T_Var)) LIKE T_CollateExpr(T_Const)
-- Simple matches
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'cafe' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'jalapeno' COLLATE Latin1_General_CS_AI;
GO

-- Wildcards
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 're%' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%n%' COLLATE Latin1_General_CS_AI;
GO

-- Case insensitive
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'TELefONO' COLLATE Latin1_General_CS_AI;
GO

-- Accents variations 
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'resume' COLLATE Latin1_General_CS_AI;
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'movie' COLLATE Latin1_General_CS_AI;
GO

-- Multiple accented characters
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'naïve' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'Piñata' COLLATE Latin1_General_CS_AI;
GO

-- Different positions
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%é%' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%ñ%' COLLATE Latin1_General_CS_AI;
GO

-- Wildcard start
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'ch%' COLLATE Latin1_General_CS_AI;
GO

-- Wildcard end 
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%is' COLLATE Latin1_General_CS_AI;
GO

-- Wildcard middle
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%é%' COLLATE Latin1_General_CS_AI;
GO

-- Multiple wildcards 
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%ia%s' COLLATE Latin1_General_CS_AI;
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'orange' COLLATE Latin1_General_CS_AI;
GO

-- Diacritic variations
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'jalapen%' COLLATE Latin1_General_CS_AI;
GO

-- Different accented vowels
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'e%ito' COLLATE Latin1_General_CS_AI;
GO

SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'c%eR' COLLATE Latin1_General_CS_AI;
GO

-- test_like_for_AI_prepare_t7_cs with ñ 
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%ñ%' COLLATE Latin1_General_CS_AI;
GO

-- test_like_for_AI_prepare_t7_cs with ü
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%ú%' COLLATE Latin1_General_CS_AI;
GO


-- CASE 9: T_FuncExpr LIKE T_CollateExpr(T_Const)
-- Simple matches
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE UPPER(col) COLLATE Latin1_General_CS_AI LIKE 'cafe' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE UPPER(col) COLLATE Latin1_General_CS_AI LIKE 'jalapeno' COLLATE Latin1_General_CS_AI;
GO

-- Wildcards
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE SUBSTRING(col, 1, 3) COLLATE Latin1_General_CS_AI LIKE 're%' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE LOWER(col) COLLATE Latin1_General_CS_AI LIKE '%n%' COLLATE Latin1_General_CS_AI;
GO

-- Case insensitive
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE LOWER(col) COLLATE Latin1_General_CS_AI LIKE 'TELefONO' COLLATE Latin1_General_CS_AI;
GO

-- Accents variations 
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE UPPER(col) COLLATE Latin1_General_CS_AI LIKE 'resume' COLLATE Latin1_General_CS_AI;
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE UPPER(LOWER(col)) COLLATE Latin1_General_CS_AI LIKE 'movie' COLLATE Latin1_General_CS_AI;
GO

-- Multiple accented characters
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE UPPER(LOWER(col)) COLLATE Latin1_General_CS_AI LIKE 'naïve' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE LOWER(UPPER(col)) COLLATE Latin1_General_CS_AI LIKE 'Piñata' COLLATE Latin1_General_CS_AI;
GO

-- Different positions
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE SUBSTRING(UPPER(LOWER(col)), 1, 3) COLLATE Latin1_General_CS_AI LIKE '%é%' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE UPPER(col) COLLATE Latin1_General_CS_AI LIKE '%ñ%' COLLATE Latin1_General_CS_AI;
GO


-- Wildcard start
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE SUBSTRING(col, 1, 3) COLLATE Latin1_General_CS_AI LIKE 'ch%' COLLATE Latin1_General_CS_AI;
GO

-- Wildcard end 
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE UPPER(col) COLLATE Latin1_General_CS_AI LIKE '%is' COLLATE Latin1_General_CS_AI;
GO

-- Wildcard middle
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE UPPER(col) COLLATE Latin1_General_CS_AI LIKE '%é%' COLLATE Latin1_General_CS_AI;
GO

-- Multiple wildcards 
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE UPPER(col) COLLATE Latin1_General_CS_AI LIKE '%ia%s' COLLATE Latin1_General_CS_AI;
GO

-- No match
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE UPPER(col) COLLATE Latin1_General_CS_AI LIKE 'orange' COLLATE Latin1_General_CS_AI;
GO

-- Diacritic variations
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE LOWER(col) COLLATE Latin1_General_CS_AI LIKE 'jalapen%' COLLATE Latin1_General_CS_AI;
GO

-- Different accented vowels
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE LOWER(col) COLLATE Latin1_General_CS_AI LIKE 'e%ito' COLLATE Latin1_General_CS_AI;
GO

SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE LOWER(col) COLLATE Latin1_General_CS_AI LIKE 'c%eR' COLLATE Latin1_General_CS_AI;
GO

-- test_like_for_AI_prepare_t7_cs with ñ 
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE LOWER(col) COLLATE Latin1_General_CS_AI LIKE '%ñ%' COLLATE Latin1_General_CS_AI;
GO

-- test_like_for_AI_prepare_t7_cs with ü
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE LOWER(col) COLLATE Latin1_General_CS_AI LIKE '%ú%' COLLATE Latin1_General_CS_AI;
GO

-- same experiments as above with column collated with Latin1_General_CS_AI
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE LOWER(col) LIKE 'c%eR';
GO

SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE LOWER(col) LIKE 'jalapen%';
GO

SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE UPPER(col) LIKE '%ia%s';
GO

SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE SUBSTRING(col, 1, 3) LIKE 'ch%';
GO


-- CASE 10: T_ReLabelType(T_Param) LIKE T_ReLabelType(T_Param)
declare @a varchar='RaŊdom';
declare @b varchar='ra%';
SELECT 1 WHERE @a LIKE @b COLLATE Latin1_General_CS_AI;
GO

-- number of chars > 8000
DECLARE @var VARCHAR(MAX);
SET @var = REPLICATE('A', 8005);
SELECT 1 WHERE @var COLLATE Latin1_General_CS_AI LIKE '%A%'
GO

-- CASE 11: T_ReLabelType(T_Var) LIKE T_ReLabelType(T_Param)
declare @c varchar(51)='e%ito';
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE @c;
GO

declare @c varchar(51)='c%eR';
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE @c;
GO

declare @d varchar(51)='%ú%';
SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col LIKE @d COLLATE Latin1_General_CS_AI;
GO

-- CASE 12: LIKE inside CASE
SELECT CASE WHEN col COLLATE Latin1_General_CS_AI LIKE 'jalapen%' THEN 1 ELSE 2 END FROM test_like_for_AI_prepare_t7_cs;
GO

SELECT CASE WHEN col LIKE '%is' COLLATE Latin1_General_CS_AI THEN 1 ELSE 2 END FROM test_like_for_AI_prepare_t7_cs;
GO

-- CASE 13: SUBQUERY

-- SIMPLE SUBQUERY (LIKE OPERATOR AS SUBQUERY)
-- returns 1 row
SELECT col1 FROM test_like_for_AI_prepare_t13_1_cs WHERE col2 IN (SELECT col FROM test_like_for_AI_prepare_t13_2_cs WHERE col LIKE 'áb%');
GO

-- returns 2 rows
SELECT col1 FROM test_like_for_AI_prepare_t13_1_cs WHERE col2 IN (SELECT col FROM test_like_for_AI_prepare_t13_2_cs WHERE col LIKE '%ar%l%');
GO

-- returns 1 rows
SELECT col1 FROM test_like_for_AI_prepare_t13_1_cs WHERE col2 IN (SELECT col FROM test_like_for_AI_prepare_t13_2_cs WHERE col LIKE '%ţö');
GO

-- COMPLEX SUBQUERY (LIKE OPERATOR CONRTAINING SUBQUERY)
-- returns 1 row
SELECT * FROM test_like_for_AI_prepare_t13_1_cs WHERE col1 LIKE (CASE WHEN (SELECT 1 WHERE 'ShaEpéD' LIKE 'Ș%' COLLATE Latin1_General_CS_AI) = 1 THEN 'TEñ%' ELSE 'ár%' END);
GO

SELECT * FROM test_like_for_AI_prepare_t13_1_cs WHERE col1 LIKE (CASE WHEN (SELECT 1 WHERE 'naïve' LIKE 'Ș%' COLLATE Latin1_General_CS_AI) = 1 THEN 'TEñ%' ELSE 'ár%' END);
GO

-- returns 4 rows
SELECT * FROM test_like_for_AI_prepare_t13_1_cs WHERE col1 LIKE (CASE WHEN 1 = 1 THEN '%i%' ELSE '%t%' END);
GO

-- rerurns 2 rows
SELECT * FROM test_like_for_AI_prepare_t13_1_cs WHERE col1 LIKE (CASE WHEN 2 = 1 THEN '%i%' ELSE '%t%' END);
GO

-- returns 2 rows
SELECT * FROM test_like_for_AI_prepare_t13_1_cs WHERE col1 LIKE (CASE WHEN (SELECT 1 WHERE 'ShaEpéD' LIKE 'Ș%' COLLATE Latin1_General_CS_AI) = 1 THEN '%a' ELSE '%é' END);
GO

-- returns 4 rows
SELECT * FROM test_like_for_AI_prepare_t13_1_cs WHERE col1 LIKE (CASE WHEN (SELECT 1 WHERE 'naïve' LIKE 'Ș%' COLLATE Latin1_General_CS_AI) = 1 THEN '%a' ELSE '%é' END);
GO

-- returns 1 row
SELECT * FROM test_like_for_AI_prepare_t13_1_cs WHERE col1 IN (SELECT col1 FROM test_like_for_AI_prepare_t13_1_cs t1 JOIN test_like_for_AI_prepare_t13_2_cs t2 ON t1.col1 LIKE 'r%' AND t2.col LIKE 'r%');
GO

-- returns 1 row
SELECT col1 FROM test_like_for_AI_prepare_t13_1_cs WHERE col2 IN (SELECT col FROM test_like_for_AI_prepare_t13_2_cs WHERE col LIKE test_like_for_AI_prepare_t13_1_cs.col1);
GO

-- CASE 14: DIFFERENT WILDCARDS
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'ca_e';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'c[ĥżâ]%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%[^oa]ñ%';
GO
SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%[i-s]';
GO

-- CASE 15: LIKE CLAUSE AS FUNCTION ARGUMENT - works when LIKE returns one row (expected)
SELECT SUM(10 + (SELECT 90 WHERE 'Cantáis' like 'Cá%' collate Latin1_General_CS_AI));
GO

SELECT CONCAT('Hi ', (SELECT col FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE 'ca_e'));
GO

SELECT UPPER((SELECT col FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE '%no'));
GO

-- CASE 16: JOIN
SELECT * FROM test_like_for_AI_prepare_t13_1_cs JOIN test_like_for_AI_prepare_t13_2_cs on test_like_for_AI_prepare_t13_1_cs.col2 LIKE test_like_for_AI_prepare_t13_2_cs.col
GO

SELECT * FROM test_like_for_AI_prepare_t13_1_cs t1 JOIN test_like_for_AI_prepare_t13_2_cs t2 ON t1.col1 LIKE 'r%' AND t2.col LIKE 'r%';
GO

SELECT * FROM test_like_for_AI_prepare_t13_1_cs t1 JOIN test_like_for_AI_prepare_t13_2_cs t2 ON t1.col1 LIKE '%a%' AND t2.col LIKE '%a%';
GO

SELECT * FROM test_like_for_AI_prepare_t13_1_cs t1 JOIN test_like_for_AI_prepare_t13_2_cs t2 ON t1.col2 LIKE '%o' AND t2.col LIKE '%o';
GO

-- CASE 17: PREPARED STATEMENTS
DECLARE @prefix NVARCHAR(50) = 'ár';
EXEC sp_executesql N'SELECT * FROM test_like_for_AI_prepare_t13_1_cs WHERE col1 LIKE @prefix + ''%'';', N'@prefix NVARCHAR(50)', @prefix;
GO

DECLARE @pattern NVARCHAR(50) = '%bo%';
EXEC sp_executesql N'SELECT * FROM test_like_for_AI_prepare_t13_1_cs WHERE col1 LIKE @pattern + ''%'';', N'@pattern NVARCHAR(50)', @pattern;
GO

DECLARE @suffix NVARCHAR(50) = 'éR';
EXEC sp_executesql N'SELECT * FROM test_like_for_AI_prepare_t13_1_cs WHERE col1 LIKE ''%'' + @suffix;', N'@suffix NVARCHAR(50)', @suffix;
GO

-- CASE 18: LIKE OBJECT_NAME()
SELECT COUNT(*) FROM test_like_for_AI_prepare_t13_1_cs WHERE 1=1 AND NOT OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_cs')) LIKE '%Blah%' COLLATE Latin1_General_CS_AI;
GO

SELECT COUNT(*) FROM test_like_for_AI_prepare_t13_1_cs WHERE 1=1 AND OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_cs')) LIKE '%AI_prepãr%' COLLATE Latin1_General_CS_AI;
GO

SELECT COUNT(*) FROM test_like_for_AI_prepare_t13_1_cs WHERE 1=1 AND NOT OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_cs')) LIKE 'Blah%' COLLATE Latin1_General_CS_AI;
GO

SELECT COUNT(*) FROM test_like_for_AI_prepare_t13_1_cs WHERE 1=1 AND NOT OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_cs')) LIKE '%Blah' COLLATE Latin1_General_CS_AI;
GO

SELECT COUNT(*) FROM test_like_for_AI_prepare_t13_1_cs WHERE NOT 1>1 AND ((NOT OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_cs')) LIKE '%Blah%' COLLATE Latin1_General_CS_AI) AND (OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_cs')) COLLATE Latin1_General_CS_AI LIKE '%like_for_AI%'))
GO

SELECT COUNT(*) FROM test_like_for_AI_prepare_t13_1_cs WHERE 1>1 OR ((NOT OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_cs')) COLLATE Latin1_General_CS_AI LIKE '%Blah%') AND (NOT OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_cs')) LIKE '%Blâh%' COLLATE Latin1_General_CS_AI))
GO

SELECT COUNT(*) FROM test_like_for_AI_prepare_t13_1_cs WHERE (1=1 AND NOT OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_cs')) COLLATE Latin1_General_CS_AI LIKE '%Blah%') OR ((NOT 2<1) AND (NOT OBJECT_NAME(OBJECT_ID('test_like_for_AI_prepare_t13_1_cs')) COLLATE Latin1_General_CS_AI LIKE '%Blâh%'))
GO

-- CASE 19: ESCAPE WITH LIKE
--15% off using ESCAPE; should return rows 19
SELECT * FROM test_like_for_AI_prepare_escape WHERE string COLLATE Latin1_General_CS_AI LIKE '15/% %' ESCAPE '/' ORDER BY c1
GO

--15% off using a different ESCAPE character; should return rows 19
SELECT * FROM test_like_for_AI_prepare_escape WHERE string COLLATE Latin1_General_CS_AI LIKE '15!% %' ESCAPE '!' ORDER BY c1
GO

--15 % off ; should return rows 21
SELECT * FROM test_like_for_AI_prepare_escape WHERE string COLLATE Latin1_General_CS_AI LIKE '15 /%___' ESCAPE '/' ORDER BY c1
GO

--Searching for the escape character itself; should return rows 23
SELECT * FROM test_like_for_AI_prepare_escape WHERE string COLLATE Latin1_General_CS_AI LIKE '15 [%] //off' ESCAPE '/' ORDER BY c1
GO

--As above, but also allow for "[". Should return 3-18, 24
SELECT * FROM test_like_for_AI_prepare_escape WHERE string COLLATE Latin1_General_CS_AI NOT LIKE '%[^a-zA-ZåÅäÄöÖ.[?[]%' ESCAPE '?' ORDER BY c1
GO

SELECT 1 WHERE 'a[abc]b' COLLATE Latin1_General_CS_AI LIKE 'a\[abc]b' escape '\'  -- 1
GO

declare @v varchar = 'a[bc'
SELECT 1 WHERE @v COLLATE Latin1_General_CS_AI LIKE '%[%' escape '~' OR @v COLLATE Latin1_General_CS_AI LIKE '%]%'                -- no row
GO

declare @v varchar = 'a[bc'
SELECT 1 WHERE @v COLLATE Latin1_General_CS_AI LIKE '%~[%' escape '~' OR @v COLLATE Latin1_General_CS_AI LIKE '%~]%' escape '~'   -- no row
GO

declare @v varchar = 'a[bc'
set @v = 'a]bc'
SELECT 1 WHERE @v COLLATE Latin1_General_CS_AI LIKE '%[%' escape '~' OR @v COLLATE Latin1_General_CS_AI LIKE '%]%'                -- no row
GO


declare @v varchar = 'a[bc'
set @v = 'a]bc'
SELECT 1 WHERE @v LIKE '%~[%' COLLATE Latin1_General_CS_AI escape '~' OR @v LIKE '%~]%' escape '~'  COLLATE Latin1_General_CS_AI -- no row
GO

declare @v varchar(20), @p varchar(20), @esc char(1)
set @v = 'a[abc]b'set @p = 'a\[abc]b' set @esc = '\' -- 1
SELECT 1 WHERE @v COLLATE Latin1_General_CS_AI LIKE @p escape @esc 
GO

SELECT 1 WHERE '_ab' COLLATE Latin1_General_CS_AI LIKE '\_ab'  escape '\'         -- 1 
GO
SELECT 1 WHERE '%AAABBB%' COLLATE Latin1_General_CS_AI LIKE '\%AAA%' escape '\'   -- 1
GO

SELECT 1 WHERE 'AB[C]D' COLLATE Latin1_General_CS_AI LIKE 'AB~[C]D' ESCAPE '~'  -- 1
GO

SELECT 1 WHERE 'AB[C]D' LIKE 'AB\[C]D' COLLATE Latin1_General_CS_AI ESCAPE '\'  -- 1
GO

SELECT 1 WHERE 'AB[C]D' LIKE 'AB\[C]D' ESCAPE '\'  COLLATE Latin1_General_CS_AI  -- 1
GO

SELECT 1 WHERE 'AB[C]D' LIKE 'AB [C]D' COLLATE Latin1_General_CS_AI ESCAPE ' '  -- 1
GO

SELECT 1 WHERE 'AB[C]D' LIKE 'AB[C]D' COLLATE Latin1_General_CS_AI ESCAPE 'B'   -- no row
GO
SELECT 1 WHERE 'AB[C]D' LIKE 'ABB[C]D' COLLATE Latin1_General_CS_AI ESCAPE 'B'  -- no row
GO

SELECT 1 WHERE 'AB[C]D' LIKE 'ABZ[C]D' ESCAPE 'Z' COLLATE Latin1_General_CS_AI -- 1
GO
SELECT 1 WHERE 'AB[C]D' COLLATE Latin1_General_CS_AI LIKE 'ABZ[C]D' ESCAPE 'z'  -- no row! Note: SQL Server treats the escape as case-sensitive!
GO

SELECT 1 WHERE null like null COLLATE Latin1_General_CS_AI escape null -- no row
GO

SELECT 1 WHERE null COLLATE Latin1_General_CS_AI like null escape null -- no row
GO

SELECT 1 WHERE null COLLATE Latin1_General_CS_AI like null COLLATE Latin1_General_CS_AI escape null -- no row
GO

SELECT 1 WHERE null like null escape null COLLATE Latin1_General_CS_AI  -- no row
GO

SELECT 1 WHERE 'ABCD' LIKE 'AB[C]D' COLLATE Latin1_General_CS_AI ESCAPE ''  -- should raise error , BABEL-4271
GO
SELECT 1 WHERE 'ABCD' COLLATE Latin1_General_CS_AI LIKE 'AB[C]D' ESCAPE 'xy'  -- raise error
GO

SELECT 1 WHERE 'ABCD' COLLATE Latin1_General_CS_AI LIKE 'AB[C]D' ESCAPE null;
GO

-- CASE 20: LIKE IN TARGET LIST
SELECT col, CASE WHEN col LIKE 'ch%' THEN 'Prefix Match' ELSE 'No Match' END AS match_status FROM test_like_for_AI_prepare_t1_ci;
GO

SELECT col,
       CASE 
           WHEN col LIKE 'prefix%' THEN 'Prefix Match'
           WHEN col LIKE '%ONO' THEN 'Suffix Match'
           ELSE 'No Match' 
       END AS match_category
FROM test_like_for_AI_prepare_t1_ci;
GO

SELECT col,
       CASE 
           WHEN col LIKE 'prefix%' THEN 'Prefix Match'
           WHEN col LIKE '%suffix' THEN 'Suffix Match'
           WHEN col LIKE '%íc%' THEN 'Match'
           ELSE 'No Match' 
       END AS extracted_substring
FROM test_like_for_AI_prepare_t1_ci;
GO

-- CASE 21: COLUMN LEVEL CONSTRAINT

-- Test the constraint
-- This insert will succeed
INSERT INTO test_like_for_AI_prepare_employee_CS_AI (id, name) VALUES (1, 'Adam');
GO
INSERT INTO test_like_for_AI_prepare_employee_CS_AI (id, name) VALUES (10, 'Ądam');
GO

-- these will fail - CS_AI
INSERT INTO test_like_for_AI_prepare_employee_CS_AI (id, name) VALUES (2, 'ådAm');
GO
INSERT INTO test_like_for_AI_prepare_employee_CS_AI (id, name) VALUES (3, 'ädam');
GO
INSERT INTO test_like_for_AI_prepare_employee_CS_AI (id, name) VALUES (4, 'adam');
GO
INSERT INTO test_like_for_AI_prepare_employee_CS_AI (id, name) VALUES (5, 'ædam');
GO

-- This insert will fail due to the check constraint
INSERT INTO test_like_for_AI_prepare_employee_CS_AI (id, name) VALUES (6, 'Bob');
GO
INSERT INTO test_like_for_AI_prepare_employee_CS_AI (id, name) VALUES (7, 'ôob');
GO

SELECT * FROM test_like_for_AI_prepare_employee_CS_AI;
GO

-- CASE 22: Sublink (with other combinations)
SELECT 1 WHERE 'Götterdämmerung' LIKE (SELECT 'Götterdämmerung' COLLATE Latin1_General_CS_AI);
GO

SELECT 1 WHERE 'Götterdämmerung' LIKE (SELECT 'Götterdämmerung' COLLATE Latin1_General_CS_AI) COLLATE Latin1_General_CS_AI;
GO

SELECT 1 WHERE 'Götterdämmerung' COLLATE Latin1_General_CS_AI LIKE (SELECT 'Götterdämmerung' COLLATE Latin1_General_CS_AI);
GO

SELECT 1 WHERE 'Götterdämmerung' COLLATE Latin1_General_CS_AI LIKE (SELECT 'Götterdämmerung' COLLATE Latin1_General_CS_AI) COLLATE Latin1_General_CS_AI;
GO

SELECT 1 WHERE N'chaptéR' LIKE (SELECT col FROM test_like_for_AI_prepare_t1_cs where col like N'chaptéR');
GO

SELECT 1 WHERE N'chaptéR' COLLATE Latin1_General_CS_AI LIKE (SELECT col FROM test_like_for_AI_prepare_t1_cs where col like N'chaptéR');
GO

SELECT 1 WHERE (SELECT 'Götterdämmerung' COLLATE Latin1_General_CS_AI) LIKE (SELECT 'Götterdämmerung' COLLATE Latin1_General_CS_AI);
GO

SELECT 1 WHERE (SELECT 'chaptéR' COLLATE Latin1_General_CS_AI) LIKE (SELECT col FROM test_like_for_AI_prepare_t1_cs where col like N'chaptéR');
GO

SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE (SELECT a FROM test_like_for_AI_prepare_t6_cs WHERE a LIKE 'Spain') LIKE '%pai%';
GO

SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE 'Spain' LIKE (SELECT a FROM test_like_for_AI_prepare_t6_cs WHERE a LIKE 'Spain');
GO

SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE (SELECT a FROM test_like_for_AI_prepare_t6_cs WHERE a LIKE 'Spain') LIKE (SELECT a FROM test_like_for_AI_prepare_t6_cs WHERE b LIKE 'SPAIn');
GO

SELECT col, (SELECT a FROM test_like_for_AI_prepare_t6_cs WHERE a LIKE 'Spain') AS subquery_result FROM test_like_for_AI_prepare_t1_cs 
WHERE col LIKE (SELECT col FROM test_like_for_AI_prepare_t7_cs WHERE col LIKE 'résumé' COLLATE Latin1_General_CS_AI);
GO

SELECT col, (SELECT a FROM test_like_for_AI_prepare_t6_cs WHERE a LIKE 'Spain') AS subquery_result FROM test_like_for_AI_prepare_t1_cs
WHERE (SELECT col FROM test_like_for_AI_prepare_t7_cs WHERE col LIKE 'résumé' COLLATE Latin1_General_CS_AI) LIKE 'resume' COLLATE Latin1_General_CS_AI;
GO

SELECT col, (SELECT a FROM test_like_for_AI_prepare_t6_cs WHERE a LIKE 'Spain') AS subquery_result FROM test_like_for_AI_prepare_t1_cs
WHERE (SELECT col FROM test_like_for_AI_prepare_t7_cs WHERE col LIKE 'résumé' COLLATE Latin1_General_CS_AI) LIKE 
(SELECT col FROM test_like_for_AI_prepare_t7_cs WHERE col LIKE 'résumé' COLLATE Latin1_General_CS_AI);
GO

SELECT col, 
(SELECT a FROM test_like_for_AI_prepare_t6_cs WHERE a LIKE 'Spain') AS subquery_result1,
(SELECT col FROM test_like_for_AI_prepare_t7_cs WHERE col LIKE 'résumé' COLLATE Latin1_General_CS_AI) AS subquery_result2
FROM test_like_for_AI_prepare_t1_cs
WHERE (SELECT col FROM test_like_for_AI_prepare_t7_cs WHERE col LIKE 'résumé' COLLATE Latin1_General_CS_AI) LIKE 'ré%';
GO

SELECT col, 
(SELECT a FROM test_like_for_AI_prepare_t6_cs WHERE a LIKE 'Spain' COLLATE Latin1_General_CS_AI) AS subquery_result
FROM test_like_for_AI_prepare_t1_cs
WHERE 
(col IS NOT NULL AND EXISTS (SELECT 1 FROM test_like_for_AI_prepare_t7_cs WHERE col_v LIKE 'résumé' COLLATE Latin1_General_CS_AI)) OR
(col IS NULL AND col LIKE 'ré%' COLLATE Latin1_General_CS_AI);
GO

-- CASE 23: T_CoerceViaIO (with other combinations)
SELECT 1 WHERE N'123' collate Latin1_General_CI_AI LIKE CAST(123 as nvarchar(3));
GO

SELECT 1 WHERE N'123' collate Latin1_General_CI_AI LIKE CAST(123 as varchar(3));
GO

SELECT 1 WHERE N'123' collate Latin1_General_CI_AI LIKE CAST(123 as char(3));
GO

SELECT 1 WHERE  CAST(123 as nvarchar(3)) LIKE N'123' collate Latin1_General_CI_AI;
GO

SELECT 1 WHERE  CAST(123 as varchar(3)) LIKE N'123' collate Latin1_General_CI_AI;
GO

SELECT 1 WHERE  CAST(123 as char(3)) LIKE N'123' collate Latin1_General_CI_AI;
GO

SELECT c1, (SELECT CAST(c1 AS NVARCHAR(50)) WHERE CAST(c1 AS NVARCHAR(50)) COLLATE Latin1_General_CS_AI LIKE '1%') FROM test_like_for_AI_prepare_escape;
GO

SELECT c1, (SELECT string WHERE string COLLATE Latin1_General_CS_AI LIKE CAST('451201%' AS NVARCHAR(50))) FROM test_like_for_AI_prepare_escape;
GO

SELECT c1, (SELECT CAST(c1 AS NVARCHAR(50)) WHERE CAST(c1 AS NVARCHAR(50)) COLLATE Latin1_General_CS_AI LIKE CAST('1%' AS NVARCHAR(50))) FROM test_like_for_AI_prepare_escape;
GO

SELECT c1, string, (SELECT CAST(string AS NVARCHAR(50)) WHERE CAST(string AS NVARCHAR(50)) COLLATE Latin1_General_CS_AI LIKE '451201%') FROM test_like_for_AI_prepare_escape;
GO


--- ADDITIONAL CORNER CASE TESTING ---

-- different collation on both arguments
SELECT 1 WHERE 'cantáis' COLLATE Latin1_General_CS_AI LIKE 'Cá%' COLLATE Latin1_General_CI_AI;
GO

SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%a%' COLLATE Latin1_General_CS_AI;
GO

SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col COLLATE Latin1_General_CS_AI LIKE'%a%' COLLATE Latin1_General_CI_AI;
GO

-- NON-Latin based collation 

select 1 where 'cantáis' like 'Cá%' collate Chinese_PRC_CI_AI
GO

-- should throw error as bbf_unicode_cp1258_ci_ai is related with code page 1258 which contains vietnamese chars
select 1 where 'cantáis' like 'Cá%' collate bbf_unicode_cp1258_ci_ai
GO

select 1 where '幸福' like '幸福%' collate Chinese_PRC_CI_AI
GO


SELECT * FROM test_like_for_AI_prepare_chinese WHERE a LIKE '中%' COLLATE Chinese_PRC_CI_AI;
GO

SELECT * FROM test_like_for_AI_prepare_chinese WHERE a LIKE '微笑' COLLATE Chinese_PRC_CI_AI;
GO

SELECT * FROM test_like_for_AI_prepare_chinese WHERE a LIKE '%谢%' COLLATE Chinese_PRC_CI_AI;
GO

SELECT * FROM test_like_for_AI_prepare_chinese WHERE a LIKE '%笑' COLLATE Chinese_PRC_CI_AI;
GO

-- col LIKE NULL
SELECT * FROM test_like_for_AI_prepare_t1_ci WHERE col LIKE NULL;
GO

SELECT * FROM test_like_for_AI_prepare_t1_cs WHERE col LIKE NULL;
GO

SELECT * FROM test_like_for_AI_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE NULL;
GO

SELECT * FROM test_like_for_AI_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE NULL;
GO

-- test cases which would test our restriction on capacity of removing accents
SELECT count(*) FROM test_like_for_AI_prepare_max_test WHERE a LIKE '%ae%' COLLATE Latin1_General_CI_AI;
GO

SELECT count(*) FROM test_like_for_AI_prepare_max_test WHERE a COLLATE Latin1_General_CI_AI LIKE '%Áe%'
GO

-- TESTS FOR INDEX SCAN 
select set_config('enable_seqscan','off','false');
GO

-- psql
ANALYZE master_dbo.test_like_for_AI_prepare_index;
GO

-- tsql
SET babelfish_showplan_all ON;
GO
-- for CI_AI
select c1 from test_like_for_AI_prepare_index where c1 LIKE 'jones'; -- this gets converted to '='
GO

select c1 from test_like_for_AI_prepare_index where c1 LIKE 'Jon%';
GO

select c1 from test_like_for_AI_prepare_index where c1 LIKE 'jone_';
GO

select c1 from test_like_for_AI_prepare_index where c1 LIKE '_one_';
GO

select c1 from test_like_for_AI_prepare_index where c1 LIKE '%on%s';
GO

-- for CS_AI
select c2 from test_like_for_AI_prepare_index where c2 LIKE 'jones'; -- this does not get converted to '=' as we are not using optimization for CS_AI
GO

select c2 from test_like_for_AI_prepare_index where c2 LIKE 'Jon%';
GO

select c2 from test_like_for_AI_prepare_index where c2 LIKE 'jone_';
GO

select c2 from test_like_for_AI_prepare_index where c2 LIKE '_one_';
GO

select c2 from test_like_for_AI_prepare_index where c2 LIKE '%on%s';
GO

SET babelfish_showplan_all OFF;
GO

-- TESTS for remove_accents_internal

-- function
SELECT test_like_for_AI_prepare_function('ǪǞǛ');
GO

SELECT test_like_for_AI_prepare_function('ĵķżƁ');
GO

SELECT test_like_for_AI_prepare_function('ȌÆß');
GO

-- view
SELECT * FROM test_like_for_AI_prepare_view;
GO

-- procedure
EXEC test_like_for_AI_prepare_procedure @input_text = 'ǪǞǛ';
GO

EXEC test_like_for_AI_prepare_procedure @input_text = 'ĵķżƁ';
GO

EXEC test_like_for_AI_prepare_procedure @input_text = 'ȌÆß';
GO

SELECT * FROM test_babel_5006 where str like 'c%' order by str;
GO

SELECT * FROM test_babel_5006 where str like '%Æ%' order by str;
GO

SELECT count(*) FROM test_babel_5006 where str like '%taeiou';
GO

SELECT count(*) FROM test_babel_5006 where str like 'taeiouc';
GO

SELECT count(*) FROM test_babel_5006 where str like '%²%';
GO

SELECT count(*) FROM test_babel_5006 where str like '%taei%';
GO

SELECT count(*) FROM test_babel_5006 where str like '%taeio%';
GO

SELECT count(*) FROM test_babel_5006 where str like 'taeiouc';
GO