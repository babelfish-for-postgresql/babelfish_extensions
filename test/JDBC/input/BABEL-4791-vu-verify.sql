------------------- CI_AI ----------------------

-- CASE 1: T_Const LIKE T_CollateExpr(T_Const)
select 1 where 'cantáis' like 'Cá%' collate Latin1_General_CI_AI;
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

select 1 where 'BleȘȘing' collate Latin1_General_CI_AI like '%ŝ%nĜ';
GO

-- CASE 3: T_CollateExpr(T_Const) LIKE T_CollateExpr(T_Const)
select 1 where 'cOntáis' collate Latin1_General_CI_AI like 'CŐ%' collate Latin1_General_CI_AI;
GO

select 1 where 'shaEpüD' collate Latin1_General_CI_AI like '%Æ%ú%' collate Latin1_General_CI_AI;
GO

select 1 where 'BleȘȘing' collate Latin1_General_CI_AI like '%ŝ%nĜ' collate Latin1_General_CI_AI;
GO

-- CASE 4: T_ReLabelType (T_Var) LIKE T_Const
-- Simple matches
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'cafe';
GO
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'jalapeno';
GO

-- Wildcards
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 're%';
GO
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE '%n%';
GO

-- Case insensitive
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'TELEFONO';
GO

-- Accents variations 
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'resume';
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'movie';
GO

-- Multiple accented characters
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'naïve';
GO
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'Piñata';
GO

-- Different positions
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE '%é%';
GO
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE '%ñ%';
GO

-- Wildcard start
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'ch%';
GO

-- Wildcard end 
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE '%is';
GO

-- Wildcard middle
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE '%é%';
GO

-- Multiple wildcards 
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE '%ia%s';
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'orange';
GO

-- Diacritic variations
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'jalapen%';
GO

-- Different accented vowels
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'e%ito';
GO

-- babel_4791_vu_prepare_t1_ci with ñ 
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE '%ñ%';
GO

-- babel_4791_vu_prepare_t1_ci with ü
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE '%ú%';
GO

-- CASE 5: T_ReLabelType(T_Var) LIKE T_CollateExpr(T_Const)
-- Simple matches
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'cafe' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'jalapeno' COLLATE Latin1_General_CI_AI;
GO

-- Wildcards
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 're%' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE '%n%' COLLATE Latin1_General_CI_AI;
GO

-- Case insensitive
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'TELEFONO' COLLATE Latin1_General_CI_AI;
GO

-- Accents variations 
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'resume' COLLATE Latin1_General_CI_AI;
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'movie' COLLATE Latin1_General_CI_AI;
GO

-- Multiple accented characters
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'naïve' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'Piñata' COLLATE Latin1_General_CI_AI;
GO

-- Different positions
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE '%é%' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE '%ñ%' COLLATE Latin1_General_CI_AI;
GO

-- Wildcard start
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'ch%' COLLATE Latin1_General_CI_AI;
GO

-- Wildcard end 
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE '%is' COLLATE Latin1_General_CI_AI;
GO

-- Wildcard middle
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE '%é%' COLLATE Latin1_General_CI_AI;
GO

-- Multiple wildcards 
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE '%ia%s' COLLATE Latin1_General_CI_AI;
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'orange' COLLATE Latin1_General_CI_AI;
GO

-- Diacritic variations
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'jalapen%' COLLATE Latin1_General_CI_AI;
GO

-- Different accented vowels
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE 'e%ito' COLLATE Latin1_General_CI_AI;
GO

-- babel_4791_vu_prepare_t1_ci with ñ 
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE '%ñ%' COLLATE Latin1_General_CI_AI;
GO

-- babel_4791_vu_prepare_t1_ci with ü
SELECT * FROM babel_4791_vu_prepare_t1_ci WHERE col LIKE '%ú%' COLLATE Latin1_General_CI_AI;
GO


-- CASE 6: T_ReLabelType(T_Var) LIKE T_ReLabelType(T_Var)
SELECT * FROM babel_4791_vu_prepare_t6_ci WHERE a LIKE b
GO

-- CASE 7: T_CollateExpr(T_ReLabel(T_Var)) LIKE T_Const
-- Simple matches
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'cafe';
GO
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'jalapeno';
GO

-- Wildcards
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 're%';
GO
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%n%';
GO

-- Case insensitive
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'TELEFONO';
GO

-- Accents variations 
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'resume';
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'movie';
GO

-- Multiple accented characters
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'naïve';
GO
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'Piñata';
GO

-- Wildcard start
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'ch%';
GO

-- Wildcard end 
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%is';
GO

-- Wildcard middle
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%é%';
GO

-- Multiple wildcards 
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%ia%s';
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'orange';
GO

-- Diacritic variations
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'jalapen%';
GO

-- Different accented vowels
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'e%ito';
GO

-- babel_4791_vu_prepare_t7_ci with ñ 
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%ñ%';
GO

-- babel_4791_vu_prepare_t7_ci with ü
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%ú%';
GO


-- CASE 8: T_CollateExpr(T_ReLabel(T_Var)) LIKE T_CollateExpr(T_Const)
-- Simple matches
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'cafe' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'jalapeno' COLLATE Latin1_General_CI_AI;
GO

-- Wildcards
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 're%' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%n%' COLLATE Latin1_General_CI_AI;
GO

-- Case insensitive
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'TELEFONO' COLLATE Latin1_General_CI_AI;
GO

-- Accents variations 
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'resume' COLLATE Latin1_General_CI_AI;
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'movie' COLLATE Latin1_General_CI_AI;
GO

-- Multiple accented characters
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'naïve' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'Piñata' COLLATE Latin1_General_CI_AI;
GO

-- Different positions
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%é%' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%ñ%' COLLATE Latin1_General_CI_AI;
GO

-- Wildcard start
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'ch%' COLLATE Latin1_General_CI_AI;
GO

-- Wildcard end 
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%is' COLLATE Latin1_General_CI_AI;
GO

-- Wildcard middle
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%é%' COLLATE Latin1_General_CI_AI;
GO

-- Multiple wildcards 
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%ia%s' COLLATE Latin1_General_CI_AI;
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'orange' COLLATE Latin1_General_CI_AI;
GO

-- Diacritic variations
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'jalapen%' COLLATE Latin1_General_CI_AI;
GO

-- Different accented vowels
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE 'e%ito' COLLATE Latin1_General_CI_AI;
GO

-- babel_4791_vu_prepare_t7_ci with ñ 
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%ñ%' COLLATE Latin1_General_CI_AI;
GO

-- babel_4791_vu_prepare_t7_ci with ü
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE '%ú%' COLLATE Latin1_General_CI_AI;
GO


-- CASE 9: T_FuncExpr LIKE T_CollateExpr(T_Const)
-- Simple matches
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE UPPER(col) COLLATE Latin1_General_CI_AI LIKE 'cafe' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE UPPER(col) COLLATE Latin1_General_CI_AI LIKE 'jalapeno' COLLATE Latin1_General_CI_AI;
GO

-- Wildcards
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE SUBSTRING(col, 1, 3) COLLATE Latin1_General_CI_AI LIKE 're%' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE LOWER(col) COLLATE Latin1_General_CI_AI LIKE '%n%' COLLATE Latin1_General_CI_AI;
GO

-- Case insensitive
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE LOWER(col) COLLATE Latin1_General_CI_AI LIKE 'TELEFONO' COLLATE Latin1_General_CI_AI;
GO

-- Accents variations 
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE UPPER(col) COLLATE Latin1_General_CI_AI LIKE 'resume' COLLATE Latin1_General_CI_AI;
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE UPPER(LOWER(col)) COLLATE Latin1_General_CI_AI LIKE 'movie' COLLATE Latin1_General_CI_AI;
GO

-- Multiple accented characters
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE UPPER(LOWER(col)) COLLATE Latin1_General_CI_AI LIKE 'naïve' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE LOWER(UPPER(col)) COLLATE Latin1_General_CI_AI LIKE 'Piñata' COLLATE Latin1_General_CI_AI;
GO

-- Different positions
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE SUBSTRING(UPPER(LOWER(col)), 1, 3) COLLATE Latin1_General_CI_AI LIKE '%é%' COLLATE Latin1_General_CI_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE UPPER(col) COLLATE Latin1_General_CI_AI LIKE '%ñ%' COLLATE Latin1_General_CI_AI;
GO


-- Wildcard start
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE SUBSTRING(col, 1, 3) COLLATE Latin1_General_CI_AI LIKE 'ch%' COLLATE Latin1_General_CI_AI;
GO

-- Wildcard end 
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE UPPER(col) COLLATE Latin1_General_CI_AI LIKE '%is' COLLATE Latin1_General_CI_AI;
GO

-- Wildcard middle
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE UPPER(col) COLLATE Latin1_General_CI_AI LIKE '%é%' COLLATE Latin1_General_CI_AI;
GO

-- Multiple wildcards 
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE UPPER(col) COLLATE Latin1_General_CI_AI LIKE '%ia%s' COLLATE Latin1_General_CI_AI;
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE UPPER(col) COLLATE Latin1_General_CI_AI LIKE 'orange' COLLATE Latin1_General_CI_AI;
GO

-- Diacritic variations
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE LOWER(col) COLLATE Latin1_General_CI_AI LIKE 'jalapen%' COLLATE Latin1_General_CI_AI;
GO

-- Different accented vowels
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE LOWER(col) COLLATE Latin1_General_CI_AI LIKE 'e%ito' COLLATE Latin1_General_CI_AI;
GO

-- babel_4791_vu_prepare_t7_ci with ñ 
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE LOWER(col) COLLATE Latin1_General_CI_AI LIKE '%ñ%' COLLATE Latin1_General_CI_AI;
GO

-- babel_4791_vu_prepare_t7_ci with ü
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE LOWER(col) COLLATE Latin1_General_CI_AI LIKE '%ú%' COLLATE Latin1_General_CI_AI;
GO


-- CASE 10: T_ReLabelType(T_Param) LIKE T_ReLabelType(T_Param)
declare @a varchar='RaŊdom';
declare @b varchar='Ra%';
SELECT 1 WHERE @a LIKE @b COLLATE Latin1_General_CI_AI;
GO

-- CASE 11: T_ReLabelType(T_Var) LIKE T_ReLabelType(T_Param)
declare @c varchar='e%ito';
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col COLLATE Latin1_General_CI_AI LIKE @c;
GO

declare @d varchar='%ú%';
SELECT * FROM babel_4791_vu_prepare_t7_ci WHERE col LIKE @d COLLATE Latin1_General_CI_AI;
GO

-- CASE 12: LIKE inside CASE
SELECT CASE WHEN col COLLATE Latin1_General_CI_AI LIKE 'jalapen%' THEN 1 ELSE 2 END FROM babel_4791_vu_prepare_t7_ci;
GO

SELECT CASE WHEN col LIKE '%is' COLLATE Latin1_General_CI_AI THEN 1 ELSE 2 END FROM babel_4791_vu_prepare_t7_ci;
GO

-- CASE 13: SUBQUERY

-- SIMPLE SUBQUERY (LIKE OPERATOR AS SUBQUERY)
-- returns 1 row
SELECT col1 FROM babel_4791_vu_prepare_t13_1_ci WHERE col2 IN (SELECT col FROM babel_4791_vu_prepare_t13_2_ci WHERE col LIKE 'Àb%');
GO

-- returns 2 rows
SELECT col1 FROM babel_4791_vu_prepare_t13_1_ci WHERE col2 IN (SELECT col FROM babel_4791_vu_prepare_t13_2_ci WHERE col LIKE '%aŖ%l%');
GO

-- returns 1 rows
SELECT col1 FROM babel_4791_vu_prepare_t13_1_ci WHERE col2 IN (SELECT col FROM babel_4791_vu_prepare_t13_2_ci WHERE col LIKE '%ţÕ');
GO

-- COMPLEX SUBQUERY (LIKE OOPERATOR CONRTAINING SUBQUERY)
-- returns 1 row
SELECT * FROM babel_4791_vu_prepare_t13_1_ci WHERE col1 LIKE (CASE WHEN (SELECT 1 WHERE 'shaEpéD' LIKE 'Ș%' COLLATE Latin1_General_CI_AI) = 1 THEN 'TEñ%' ELSE 'ár%' END);
GO

SELECT * FROM babel_4791_vu_prepare_t13_1_ci WHERE col1 LIKE (CASE WHEN (SELECT 1 WHERE 'naïve' LIKE 'Ș%' COLLATE Latin1_General_CI_AI) = 1 THEN 'TEñ%' ELSE 'ár%' END);
GO

-- returns 4 rows
SELECT * FROM babel_4791_vu_prepare_t13_1_ci WHERE col1 LIKE (CASE WHEN 1 = 1 THEN '%I%' ELSE '%t%' END);
GO

-- rerurns 4 rows
SELECT * FROM babel_4791_vu_prepare_t13_1_ci WHERE col1 LIKE (CASE WHEN 2 = 1 THEN '%I%' ELSE '%t%' END);
GO

-- returns 2 rows
SELECT * FROM babel_4791_vu_prepare_t13_1_ci WHERE col1 LIKE (CASE WHEN (SELECT 1 WHERE 'shaEpéD' LIKE 'Ș%' COLLATE Latin1_General_CI_AI) = 1 THEN '%a' ELSE '%é' END);
GO

-- returns 4 rows
SELECT * FROM babel_4791_vu_prepare_t13_1_ci WHERE col1 LIKE (CASE WHEN (SELECT 1 WHERE 'naïve' LIKE 'Ș%' COLLATE Latin1_General_CI_AI) = 1 THEN '%a' ELSE '%é' END);
GO


------------------- CS_AI ----------------------
-- CASE 1: T_Const LIKE T_CollateExpr(T_Const)
select 1 where 'cantáis' like 'cá%' collate Latin1_General_CS_AI;
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

select 1 where 'BlesȘing' collate Latin1_General_CS_AI like '%ŝ%nĝ';
GO

-- CASE 3: T_CollateExpr(T_Const) LIKE T_CollateExpr(T_Const)
select 1 where 'cOntáis' collate Latin1_General_CS_AI like 'cŐ%' collate Latin1_General_CS_AI;
GO

select 1 where 'shaEpüD' collate Latin1_General_CS_AI like '%ǣ%ú%' collate Latin1_General_CS_AI;
GO

select 1 where 'BleȘsing' collate Latin1_General_CS_AI like '%ŝ%ng' collate Latin1_General_CS_AI;
GO

-- CASE 4: T_ReLabelType (T_Var) LIKE T_Const
-- Simple matches
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'cafe';
GO
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'jalapeno';
GO

-- Wildcards
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 're%';
GO
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE '%n%';
GO

-- Case insensitive
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'TELEFONO';
GO

-- Accents variations 
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'resume';
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'movie';
GO

-- Multiple accented characters
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'naïve';
GO
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'Piñata';
GO

-- Different positions
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE '%é%';
GO
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE '%ñ%';
GO

-- Wildcard start
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'ch%';
GO

-- Wildcard end 
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE '%is';
GO

-- Wildcard middle
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE '%é%';
GO

-- Multiple wildcards 
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE '%ia%s';
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'orange';
GO

-- Diacritic variations
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'jalapen%';
GO

-- Different accented vowels
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'e%ito';
GO

-- babel_4791_vu_prepare_t1_cs with ñ 
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE '%ñ%';
GO

-- babel_4791_vu_prepare_t1_cs with ü
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE '%ú%';
GO

-- CASE 5: T_ReLabelType(T_Var) LIKE T_CollateExpr(T_Const)
-- Simple matches
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'cafe' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'jalapeno' COLLATE Latin1_General_CS_AI;
GO

-- Wildcards
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 're%' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE '%n%' COLLATE Latin1_General_CS_AI;
GO

-- Case insensitive
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'TELEFONO' COLLATE Latin1_General_CS_AI;
GO

-- Accents variations 
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'resume' COLLATE Latin1_General_CS_AI;
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'movie' COLLATE Latin1_General_CS_AI;
GO

-- Multiple accented characters
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'naïve' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'Piñata' COLLATE Latin1_General_CS_AI;
GO

-- Different positions
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE '%é%' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE '%ñ%' COLLATE Latin1_General_CS_AI;
GO

-- Wildcard start
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'ch%' COLLATE Latin1_General_CS_AI;
GO

-- Wildcard end 
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE '%is' COLLATE Latin1_General_CS_AI;
GO

-- Wildcard middle
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE '%é%' COLLATE Latin1_General_CS_AI;
GO

-- Multiple wildcards 
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE '%ia%s' COLLATE Latin1_General_CS_AI;
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'orange' COLLATE Latin1_General_CS_AI;
GO

-- Diacritic variations
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'jalapen%' COLLATE Latin1_General_CS_AI;
GO

-- Different accented vowels
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE 'e%ito' COLLATE Latin1_General_CS_AI;
GO

-- babel_4791_vu_prepare_t1_cs with ñ 
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE '%ñ%' COLLATE Latin1_General_CS_AI;
GO

-- babel_4791_vu_prepare_t1_cs with ü
SELECT * FROM babel_4791_vu_prepare_t1_cs WHERE col LIKE '%ú%' COLLATE Latin1_General_CS_AI;
GO


-- CASE 6: T_ReLabelType(T_Var) LIKE T_ReLabelType(T_Var)
SELECT * FROM babel_4791_vu_prepare_t6_cs WHERE a LIKE b
GO

-- CASE 7: T_CollateExpr(T_ReLabel(T_Var)) LIKE T_Const
-- Simple matches
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'cafe';
GO
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'jalapeno';
GO

-- Wildcards
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 're%';
GO
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%n%';
GO

-- Case insensitive
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'TELEFONO';
GO

-- Accents variations 
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'resume';
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'movie';
GO

-- Multiple accented characters
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'naïve';
GO
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'Piñata';
GO

-- Wildcard start
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'ch%';
GO

-- Wildcard end 
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%is';
GO

-- Wildcard middle
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%é%';
GO

-- Multiple wildcards 
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%ia%s';
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'orange';
GO

-- Diacritic variations
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'jalapen%';
GO

-- Different accented vowels
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'e%ito';
GO

-- babel_4791_vu_prepare_t7_cs with ñ 
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%ñ%';
GO

-- babel_4791_vu_prepare_t7_cs with ü
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%ú%';
GO


-- CASE 8: T_CollateExpr(T_ReLabel(T_Var)) LIKE T_CollateExpr(T_Const)
-- Simple matches
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'cafe' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'jalapeno' COLLATE Latin1_General_CS_AI;
GO

-- Wildcards
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 're%' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%n%' COLLATE Latin1_General_CS_AI;
GO

-- Case insensitive
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'TELEFONO' COLLATE Latin1_General_CS_AI;
GO

-- Accents variations 
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'resume' COLLATE Latin1_General_CS_AI;
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'movie' COLLATE Latin1_General_CS_AI;
GO

-- Multiple accented characters
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'naïve' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'Piñata' COLLATE Latin1_General_CS_AI;
GO

-- Different positions
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%é%' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%ñ%' COLLATE Latin1_General_CS_AI;
GO

-- Wildcard start
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'ch%' COLLATE Latin1_General_CS_AI;
GO

-- Wildcard end 
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%is' COLLATE Latin1_General_CS_AI;
GO

-- Wildcard middle
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%é%' COLLATE Latin1_General_CS_AI;
GO

-- Multiple wildcards 
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%ia%s' COLLATE Latin1_General_CS_AI;
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'orange' COLLATE Latin1_General_CS_AI;
GO

-- Diacritic variations
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'jalapen%' COLLATE Latin1_General_CS_AI;
GO

-- Different accented vowels
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE 'e%ito' COLLATE Latin1_General_CS_AI;
GO

-- babel_4791_vu_prepare_t7_cs with ñ 
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%ñ%' COLLATE Latin1_General_CS_AI;
GO

-- babel_4791_vu_prepare_t7_cs with ü
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE '%ú%' COLLATE Latin1_General_CS_AI;
GO


-- CASE 9: T_FuncExpr LIKE T_CollateExpr(T_Const)
-- Simple matches
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE UPPER(col) COLLATE Latin1_General_CS_AI LIKE 'cafe' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE UPPER(col) COLLATE Latin1_General_CS_AI LIKE 'jalapeno' COLLATE Latin1_General_CS_AI;
GO

-- Wildcards
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE SUBSTRING(col, 1, 3) COLLATE Latin1_General_CS_AI LIKE 're%' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE LOWER(col) COLLATE Latin1_General_CS_AI LIKE '%n%' COLLATE Latin1_General_CS_AI;
GO

-- Case insensitive
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE LOWER(col) COLLATE Latin1_General_CS_AI LIKE 'TELEFONO' COLLATE Latin1_General_CS_AI;
GO

-- Accents variations 
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE UPPER(col) COLLATE Latin1_General_CS_AI LIKE 'resume' COLLATE Latin1_General_CS_AI;
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE UPPER(LOWER(col)) COLLATE Latin1_General_CS_AI LIKE 'movie' COLLATE Latin1_General_CS_AI;
GO

-- Multiple accented characters
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE UPPER(LOWER(col)) COLLATE Latin1_General_CS_AI LIKE 'naïve' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE LOWER(UPPER(col)) COLLATE Latin1_General_CS_AI LIKE 'Piñata' COLLATE Latin1_General_CS_AI;
GO

-- Different positions
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE SUBSTRING(UPPER(LOWER(col)), 1, 3) COLLATE Latin1_General_CS_AI LIKE '%é%' COLLATE Latin1_General_CS_AI;
GO
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE UPPER(col) COLLATE Latin1_General_CS_AI LIKE '%ñ%' COLLATE Latin1_General_CS_AI;
GO


-- Wildcard start
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE SUBSTRING(col, 1, 3) COLLATE Latin1_General_CS_AI LIKE 'ch%' COLLATE Latin1_General_CS_AI;
GO

-- Wildcard end 
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE UPPER(col) COLLATE Latin1_General_CS_AI LIKE '%is' COLLATE Latin1_General_CS_AI;
GO

-- Wildcard middle
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE UPPER(col) COLLATE Latin1_General_CS_AI LIKE '%é%' COLLATE Latin1_General_CS_AI;
GO

-- Multiple wildcards 
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE UPPER(col) COLLATE Latin1_General_CS_AI LIKE '%ia%s' COLLATE Latin1_General_CS_AI;
GO

-- No match
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE UPPER(col) COLLATE Latin1_General_CS_AI LIKE 'orange' COLLATE Latin1_General_CS_AI;
GO

-- Diacritic variations
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE LOWER(col) COLLATE Latin1_General_CS_AI LIKE 'jalapen%' COLLATE Latin1_General_CS_AI;
GO

-- Different accented vowels
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE LOWER(col) COLLATE Latin1_General_CS_AI LIKE 'e%ito' COLLATE Latin1_General_CS_AI;
GO

-- babel_4791_vu_prepare_t7_cs with ñ 
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE LOWER(col) COLLATE Latin1_General_CS_AI LIKE '%ñ%' COLLATE Latin1_General_CS_AI;
GO

-- babel_4791_vu_prepare_t7_cs with ü
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE LOWER(col) COLLATE Latin1_General_CS_AI LIKE '%ú%' COLLATE Latin1_General_CS_AI;
GO


-- CASE 10: T_ReLabelType(T_Param) LIKE T_ReLabelType(T_Param)
declare @a varchar='RaŊdom';
declare @b varchar='ra%';
SELECT 1 WHERE @a LIKE @b COLLATE Latin1_General_CS_AI;
GO

-- CASE 11: T_ReLabelType(T_Var) LIKE T_ReLabelType(T_Param)
declare @c varchar='e%ito';
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col COLLATE Latin1_General_CS_AI LIKE @c;
GO

declare @d varchar='%ú%';
SELECT * FROM babel_4791_vu_prepare_t7_cs WHERE col LIKE @d COLLATE Latin1_General_CS_AI;
GO

-- CASE 12: LIKE inside CASE
SELECT CASE WHEN col COLLATE Latin1_General_CS_AI LIKE 'jalapen%' THEN 1 ELSE 2 END FROM babel_4791_vu_prepare_t7_cs;
GO

SELECT CASE WHEN col LIKE '%is' COLLATE Latin1_General_CS_AI THEN 1 ELSE 2 END FROM babel_4791_vu_prepare_t7_cs;
GO

-- CASE 13: SUBQUERY

-- SIMPLE SUBQUERY (LIKE OPERATOR AS SUBQUERY)
-- returns 1 row
SELECT col1 FROM babel_4791_vu_prepare_t13_1_cs WHERE col2 IN (SELECT col FROM babel_4791_vu_prepare_t13_2_cs WHERE col LIKE 'áb%');
GO

-- returns 2 rows
SELECT col1 FROM babel_4791_vu_prepare_t13_1_cs WHERE col2 IN (SELECT col FROM babel_4791_vu_prepare_t13_2_cs WHERE col LIKE '%ar%l%');
GO

-- returns 1 rows
SELECT col1 FROM babel_4791_vu_prepare_t13_1_cs WHERE col2 IN (SELECT col FROM babel_4791_vu_prepare_t13_2_cs WHERE col LIKE '%ţö');
GO

-- COMPLEX SUBQUERY (LIKE OOPERATOR CONRTAINING SUBQUERY)
-- returns 1 row
SELECT * FROM babel_4791_vu_prepare_t13_1_cs WHERE col1 LIKE (CASE WHEN (SELECT 1 WHERE 'ShaEpéD' LIKE 'Ș%' COLLATE Latin1_General_CS_AI) = 1 THEN 'TEñ%' ELSE 'ár%' END);
GO

SELECT * FROM babel_4791_vu_prepare_t13_1_cs WHERE col1 LIKE (CASE WHEN (SELECT 1 WHERE 'naïve' LIKE 'Ș%' COLLATE Latin1_General_CS_AI) = 1 THEN 'TEñ%' ELSE 'ár%' END);
GO

-- returns 4 rows
SELECT * FROM babel_4791_vu_prepare_t13_1_cs WHERE col1 LIKE (CASE WHEN 1 = 1 THEN '%i%' ELSE '%t%' END);
GO

-- rerurns 2 rows
SELECT * FROM babel_4791_vu_prepare_t13_1_cs WHERE col1 LIKE (CASE WHEN 2 = 1 THEN '%i%' ELSE '%t%' END);
GO

-- returns 2 rows
SELECT * FROM babel_4791_vu_prepare_t13_1_cs WHERE col1 LIKE (CASE WHEN (SELECT 1 WHERE 'ShaEpéD' LIKE 'Ș%' COLLATE Latin1_General_CS_AI) = 1 THEN '%a' ELSE '%é' END);
GO

-- returns 4 rows
SELECT * FROM babel_4791_vu_prepare_t13_1_cs WHERE col1 LIKE (CASE WHEN (SELECT 1 WHERE 'naïve' LIKE 'Ș%' COLLATE Latin1_General_CS_AI) = 1 THEN '%a' ELSE '%é' END);
GO