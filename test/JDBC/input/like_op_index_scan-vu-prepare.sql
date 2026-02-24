CREATE TABLE BABEL_5966_TestLikeIndex (
    Id INT IDENTITY PRIMARY KEY,
    VarcharCol VARCHAR(100),
    NVarcharCol NVARCHAR(100),
    CharCol CHAR(50)
);
GO

CREATE INDEX BABEL_5966_idx_varchar ON BABEL_5966_TestLikeIndex(VarcharCol);
CREATE INDEX BABEL_5966_idx_nvarchar ON BABEL_5966_TestLikeIndex(NVarcharCol);
CREATE INDEX BABEL_5966_idx_char ON BABEL_5966_TestLikeIndex(CharCol);
GO

INSERT INTO BABEL_5966_TestLikeIndex (VarcharCol, NVarcharCol, CharCol)
VALUES 
    ('exact match', N'exact match', 'exact match'),
    ('prefix_abc', N'prefix_abc', 'prefix_abc'),
    ('prefix_def', N'prefix_def', 'prefix_def'),
    ('prefix_ghi', N'prefix_ghi', 'prefix_ghi'),
    ('something else', N'something else', 'something else'),
    ('another value', N'another value', 'another value'),
    ('test data 1', N'test data 1', 'test data 1'),
    ('test data 2', N'test data 2', 'test data 2'),
    ('test data 3', N'test data 3', 'test data 3'),
    ('UPPER CASE', N'UPPER CASE', 'UPPER CASE'),
    ('mixed Case', N'mixed Case', 'mixed Case'),
    ('a', N'a', 'a'),
    ('ab', N'ab', 'ab'),
    ('abc', N'abc', 'abc'),
    ('ABC', N'ABC', 'ABC'),
    ('100%done', N'100%done', '100%done'),
    ('under_score', N'under_score', 'under_score'),
    ('back\slash', N'back\slash', 'back\slash'),
    ('single''quote', N'single''quote', 'single''quote'),
    ('café', N'café', 'café'),
    ('naïve', N'naïve', 'naïve'),
    ('résumé', N'résumé', 'résumé'),
    ('straße', N'straße', 'straße'),
    ('   spaces   ', N'   spaces   ', '   spaces   '),
    ('trailing   ', N'trailing   ', 'trailing   '),
    ('   leading', N'   leading', '   leading'),
    ('aaaaaaaaaa', N'aaaaaaaaaa', 'aaaaaaaaaa'),
    ('AAAAAAAAAA', N'AAAAAAAAAA', 'AAAAAAAAAA'),
    ('aAbBcCdDeE', N'aAbBcCdDeE', 'aAbBcCdDeE');
GO

INSERT INTO BABEL_5966_TestLikeIndex (VarcharCol, NVarcharCol, CharCol)
SELECT 
    'zzz_filler_' + CAST(n AS VARCHAR(10)),
    N'zzz_filler_' + CAST(n AS NVARCHAR(10)),
    'zzz_filler_' + CAST(n AS VARCHAR(10))
FROM generate_series(1, 20000) AS n;
GO

CREATE TABLE BABEL_5966_TestLikeCollation_CI_AS (
    Id INT IDENTITY PRIMARY KEY,
    Col VARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS
);
GO

CREATE TABLE BABEL_5966_TestLikeCollation_CS_AS (
    Id INT IDENTITY PRIMARY KEY,
    Col VARCHAR(100) COLLATE SQL_Latin1_General_CP1_CS_AS
);
GO

CREATE TABLE BABEL_5966_TestLikeCollation_CI_AI (
    Id INT IDENTITY PRIMARY KEY,
    Col VARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AI
);
GO

CREATE TABLE BABEL_5966_TestLikeCollation_CS_AI (
    Id INT IDENTITY PRIMARY KEY,
    Col VARCHAR(100) COLLATE SQL_Latin1_General_CP1_CS_AI
);
GO

CREATE INDEX BABEL_5966_idx_ci_as ON BABEL_5966_TestLikeCollation_CI_AS(Col);
CREATE INDEX BABEL_5966_idx_cs_as ON BABEL_5966_TestLikeCollation_CS_AS(Col);
CREATE INDEX BABEL_5966_idx_ci_ai ON BABEL_5966_TestLikeCollation_CI_AI(Col);
CREATE INDEX BABEL_5966_idx_cs_ai ON BABEL_5966_TestLikeCollation_CS_AI(Col);
GO

INSERT INTO BABEL_5966_TestLikeCollation_CI_AS (Col)
VALUES ('exact match'), ('EXACT MATCH'), ('Exact Match'),
       ('prefix_abc'), ('PREFIX_ABC'), ('Prefix_Abc'),
       ('café'), ('CAFÉ'), ('Café'),
       ('résumé'), ('RÉSUMÉ'), ('Résumé'),
       ('naïve'), ('NAÏVE'), ('Naïve'),
       ('resume'), ('RESUME'), ('Resume'),
       ('naive'), ('NAIVE'), ('Naive'),
       ('straße'), ('STRASSE'), ('Straße'),
       ('a'), ('A'), ('abc'), ('ABC');
GO

INSERT INTO BABEL_5966_TestLikeCollation_CI_AS (Col)
SELECT 'zzz_filler_' + CAST(n AS VARCHAR(10))
FROM generate_series(1, 20000) AS n;
GO

INSERT INTO BABEL_5966_TestLikeCollation_CS_AS (Col)
SELECT Col FROM BABEL_5966_TestLikeCollation_CI_AS;
GO

INSERT INTO BABEL_5966_TestLikeCollation_CI_AI (Col)
SELECT Col FROM BABEL_5966_TestLikeCollation_CI_AS;
GO

INSERT INTO BABEL_5966_TestLikeCollation_CS_AI (Col)
SELECT Col FROM BABEL_5966_TestLikeCollation_CI_AS;
GO

CREATE TABLE BABEL_5966_TestLikeNVarCollation_CI_AS (
    Id INT IDENTITY PRIMARY KEY,
    Col NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS
);
GO

CREATE TABLE BABEL_5966_TestLikeNVarCollation_CS_AS (
    Id INT IDENTITY PRIMARY KEY,
    Col NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CS_AS
);
GO

CREATE TABLE BABEL_5966_TestLikeNVarCollation_CI_AI (
    Id INT IDENTITY PRIMARY KEY,
    Col NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AI
);
GO

CREATE TABLE BABEL_5966_TestLikeNVarCollation_CS_AI (
    Id INT IDENTITY PRIMARY KEY,
    Col NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CS_AI
);
GO

CREATE INDEX BABEL_5966_idx_nvar_ci_as ON BABEL_5966_TestLikeNVarCollation_CI_AS(Col);
CREATE INDEX BABEL_5966_idx_nvar_cs_as ON BABEL_5966_TestLikeNVarCollation_CS_AS(Col);
CREATE INDEX BABEL_5966_idx_nvar_ci_ai ON BABEL_5966_TestLikeNVarCollation_CI_AI(Col);
CREATE INDEX BABEL_5966_idx_nvar_cs_ai ON BABEL_5966_TestLikeNVarCollation_CS_AI(Col);
GO

INSERT INTO BABEL_5966_TestLikeNVarCollation_CI_AS (Col)
VALUES (N'exact match'), (N'EXACT MATCH'), (N'Exact Match'),
       (N'prefix_abc'), (N'PREFIX_ABC'),
       (N'café'), (N'CAFÉ'),
       (N'résumé'), (N'RÉSUMÉ'), (N'resume'), (N'RESUME'),
       (N'naïve'), (N'NAÏVE'), (N'naive'), (N'NAIVE');
GO

INSERT INTO BABEL_5966_TestLikeNVarCollation_CI_AS (Col)
SELECT N'zzz_filler_' + CAST(n AS NVARCHAR(10))
FROM generate_series(1, 20000) AS n;
GO

INSERT INTO BABEL_5966_TestLikeNVarCollation_CS_AS (Col) SELECT Col FROM BABEL_5966_TestLikeNVarCollation_CI_AS;
INSERT INTO BABEL_5966_TestLikeNVarCollation_CI_AI (Col) SELECT Col FROM BABEL_5966_TestLikeNVarCollation_CI_AS;
INSERT INTO BABEL_5966_TestLikeNVarCollation_CS_AI (Col) SELECT Col FROM BABEL_5966_TestLikeNVarCollation_CI_AS;
GO

CREATE TABLE BABEL_5966_TestLikeCharCollation_CI_AS (
    Id INT IDENTITY PRIMARY KEY,
    Col CHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS
);
GO

CREATE TABLE BABEL_5966_TestLikeCharCollation_CS_AS (
    Id INT IDENTITY PRIMARY KEY,
    Col CHAR(100) COLLATE SQL_Latin1_General_CP1_CS_AS
);
GO

CREATE TABLE BABEL_5966_TestLikeCharCollation_CI_AI (
    Id INT IDENTITY PRIMARY KEY,
    Col CHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AI
);
GO

CREATE TABLE BABEL_5966_TestLikeCharCollation_CS_AI (
    Id INT IDENTITY PRIMARY KEY,
    Col CHAR(100) COLLATE SQL_Latin1_General_CP1_CS_AI
);
GO

CREATE INDEX BABEL_5966_idx_char_ci_as ON BABEL_5966_TestLikeCharCollation_CI_AS(Col);
CREATE INDEX BABEL_5966_idx_char_cs_as ON BABEL_5966_TestLikeCharCollation_CS_AS(Col);
CREATE INDEX BABEL_5966_idx_char_ci_ai ON BABEL_5966_TestLikeCharCollation_CI_AI(Col);
CREATE INDEX BABEL_5966_idx_char_cs_ai ON BABEL_5966_TestLikeCharCollation_CS_AI(Col);
GO

INSERT INTO BABEL_5966_TestLikeCharCollation_CI_AS (Col)
VALUES ('exact match'), ('EXACT MATCH'), ('Exact Match'),
       ('prefix_abc'), ('PREFIX_ABC'), ('Prefix_Abc'),
       ('café'), ('CAFÉ'), ('Café'),
       ('résumé'), ('RÉSUMÉ'), ('Résumé'),
       ('naïve'), ('NAÏVE'), ('Naïve'),
       ('resume'), ('RESUME'), ('Resume'),
       ('naive'), ('NAIVE'), ('Naive'),
       ('straße'), ('STRASSE'), ('Straße'),
       ('a'), ('A'), ('abc'), ('ABC');
GO

INSERT INTO BABEL_5966_TestLikeCharCollation_CI_AS (Col)
SELECT 'zzz_filler_' + CAST(n AS VARCHAR(10))
FROM generate_series(1, 20000) AS n;
GO

INSERT INTO BABEL_5966_TestLikeCharCollation_CS_AS (Col) SELECT Col FROM BABEL_5966_TestLikeCharCollation_CI_AS;
INSERT INTO BABEL_5966_TestLikeCharCollation_CI_AI (Col) SELECT Col FROM BABEL_5966_TestLikeCharCollation_CI_AS;
INSERT INTO BABEL_5966_TestLikeCharCollation_CS_AI (Col) SELECT Col FROM BABEL_5966_TestLikeCharCollation_CI_AS;
GO

-- Views

CREATE VIEW BABEL_5966_vw_like_exact_varchar AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE N'exact match';
GO

CREATE VIEW BABEL_5966_vw_like_prefix_varchar AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE N'prefix%';
GO

CREATE VIEW BABEL_5966_vw_like_suffix_varchar AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE N'%match';
GO

CREATE VIEW BABEL_5966_vw_like_contains_varchar AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE N'%data%';
GO

CREATE VIEW BABEL_5966_vw_like_single_char_varchar AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE N'_';
GO

CREATE VIEW BABEL_5966_vw_not_like_varchar AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex WHERE VarcharCol NOT LIKE N'zzz%';
GO

CREATE VIEW BABEL_5966_vw_not_like_exact_varchar AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex WHERE VarcharCol NOT LIKE N'exact match';
GO

CREATE VIEW BABEL_5966_vw_like_exact_nvarchar AS
SELECT Id, NVarcharCol FROM BABEL_5966_TestLikeIndex WHERE NVarcharCol LIKE N'exact match';
GO

CREATE VIEW BABEL_5966_vw_like_prefix_nvarchar AS
SELECT Id, NVarcharCol FROM BABEL_5966_TestLikeIndex WHERE NVarcharCol LIKE N'prefix%';
GO

CREATE VIEW BABEL_5966_vw_like_suffix_nvarchar AS
SELECT Id, NVarcharCol FROM BABEL_5966_TestLikeIndex WHERE NVarcharCol LIKE N'%match';
GO

CREATE VIEW BABEL_5966_vw_like_exact_char AS
SELECT Id, CharCol FROM BABEL_5966_TestLikeIndex WHERE CharCol LIKE N'exact match';
GO

CREATE VIEW BABEL_5966_vw_like_prefix_char AS
SELECT Id, CharCol FROM BABEL_5966_TestLikeIndex WHERE CharCol LIKE N'prefix%';
GO

CREATE VIEW BABEL_5966_vw_like_suffix_char AS
SELECT Id, CharCol FROM BABEL_5966_TestLikeIndex WHERE CharCol LIKE N'%match';
GO

CREATE VIEW BABEL_5966_vw_like_or AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex
WHERE VarcharCol LIKE N'prefix%' OR VarcharCol LIKE N'test%';
GO

CREATE VIEW BABEL_5966_vw_like_and AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex
WHERE VarcharCol LIKE N'prefix%' AND VarcharCol LIKE N'%abc';
GO

CREATE VIEW BABEL_5966_vw_like_mixed AS
SELECT Id, VarcharCol, NVarcharCol FROM BABEL_5966_TestLikeIndex
WHERE VarcharCol LIKE N'prefix%' AND NVarcharCol LIKE N'prefix%';
GO

CREATE VIEW BABEL_5966_vw_like_escape_pct AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE N'100!%done' ESCAPE '!';
GO

CREATE VIEW BABEL_5966_vw_like_escape_underscore AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE N'under!_score' ESCAPE '!';
GO

CREATE VIEW BABEL_5966_vw_like_unicode AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE N'café';
GO

CREATE VIEW BABEL_5966_vw_like_unicode_prefix AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE N'caf%';
GO

CREATE VIEW BABEL_5966_vw_like_cast_varchar AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE CAST(N'exact match' AS VARCHAR(50));
GO

CREATE VIEW BABEL_5966_vw_like_cast_nvarchar AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE CAST(N'prefix%' AS NVARCHAR(50));
GO

CREATE VIEW BABEL_5966_vw_like_cast_char AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE CAST('exact match' AS CHAR(20));
GO

CREATE VIEW BABEL_5966_vw_like_ci_as AS
SELECT Id, Col FROM BABEL_5966_TestLikeCollation_CI_AS WHERE Col LIKE N'exact match';
GO

CREATE VIEW BABEL_5966_vw_like_cs_as AS
SELECT Id, Col FROM BABEL_5966_TestLikeCollation_CS_AS WHERE Col LIKE N'exact match';
GO

CREATE VIEW BABEL_5966_vw_like_ci_ai AS
SELECT Id, Col FROM BABEL_5966_TestLikeCollation_CI_AI WHERE Col LIKE N'exact match';
GO

CREATE VIEW BABEL_5966_vw_like_cs_ai AS
SELECT Id, Col FROM BABEL_5966_TestLikeCollation_CS_AI WHERE Col LIKE N'exact match';
GO

CREATE VIEW BABEL_5966_vw_like_ci_as_prefix AS
SELECT Id, Col FROM BABEL_5966_TestLikeCollation_CI_AS WHERE Col LIKE N'prefix%';
GO

CREATE VIEW BABEL_5966_vw_like_cs_as_prefix AS
SELECT Id, Col FROM BABEL_5966_TestLikeCollation_CS_AS WHERE Col LIKE N'prefix%';
GO

CREATE VIEW BABEL_5966_vw_like_ci_ai_prefix AS
SELECT Id, Col FROM BABEL_5966_TestLikeCollation_CI_AI WHERE Col LIKE N'prefix%';
GO

CREATE VIEW BABEL_5966_vw_like_cs_ai_prefix AS
SELECT Id, Col FROM BABEL_5966_TestLikeCollation_CS_AI WHERE Col LIKE N'prefix%';
GO

CREATE VIEW BABEL_5966_vw_like_nested AS
SELECT * FROM BABEL_5966_vw_like_prefix_varchar WHERE VarcharCol LIKE N'prefix_a%';
GO

CREATE VIEW BABEL_5966_vw_like_with_id AS
SELECT Id, VarcharCol FROM BABEL_5966_TestLikeIndex
WHERE VarcharCol LIKE N'prefix%' AND Id > 0;
GO

-- Stored Procedures

CREATE PROCEDURE BABEL_5966_sp_like_exact_const AS
BEGIN
    SELECT COUNT(*) AS cnt FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE N'exact match';
END;
GO

CREATE PROCEDURE BABEL_5966_sp_like_prefix_const AS
BEGIN
    SELECT COUNT(*) AS cnt FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE N'prefix%';
END;
GO

CREATE PROCEDURE BABEL_5966_sp_like_suffix_const AS
BEGIN
    SELECT COUNT(*) AS cnt FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE N'%match';
END;
GO

CREATE PROCEDURE BABEL_5966_sp_like_varchar_param @pattern VARCHAR(50) AS
BEGIN
    SELECT COUNT(*) AS cnt FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE @pattern;
END;
GO

CREATE PROCEDURE BABEL_5966_sp_like_nvarchar_param @pattern NVARCHAR(50) AS
BEGIN
    SELECT COUNT(*) AS cnt FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE @pattern;
END;
GO

CREATE PROCEDURE BABEL_5966_sp_like_all_columns @pattern NVARCHAR(50) AS
BEGIN
    SELECT COUNT(*) AS varchar_cnt FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE @pattern;
    SELECT COUNT(*) AS nvarchar_cnt FROM BABEL_5966_TestLikeIndex WHERE NVarcharCol LIKE @pattern;
    SELECT COUNT(*) AS char_cnt FROM BABEL_5966_TestLikeIndex WHERE CharCol LIKE @pattern;
END;
GO

CREATE PROCEDURE BABEL_5966_sp_not_like_param @pattern NVARCHAR(50) AS
BEGIN
    SELECT COUNT(*) AS cnt FROM BABEL_5966_TestLikeIndex WHERE VarcharCol NOT LIKE @pattern;
END;
GO

CREATE PROCEDURE BABEL_5966_sp_like_escape @pattern NVARCHAR(50), @esc CHAR(1) AS
BEGIN
    SELECT COUNT(*) AS cnt FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE @pattern ESCAPE @esc;
END;
GO

CREATE PROCEDURE BABEL_5966_sp_like_dynamic @prefix VARCHAR(50) AS
BEGIN
    SELECT COUNT(*) AS cnt FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE @prefix + '%';
END;
GO

CREATE PROCEDURE BABEL_5966_sp_like_output @pattern NVARCHAR(50), @cnt INT OUTPUT AS
BEGIN
    SELECT @cnt = COUNT(*) FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE @pattern;
END;
GO

CREATE PROCEDURE BABEL_5966_sp_like_all_collations @pattern NVARCHAR(50) AS
BEGIN
    SELECT COUNT(*) AS ci_as FROM BABEL_5966_TestLikeCollation_CI_AS WHERE Col LIKE @pattern;
    SELECT COUNT(*) AS cs_as FROM BABEL_5966_TestLikeCollation_CS_AS WHERE Col LIKE @pattern;
    SELECT COUNT(*) AS ci_ai FROM BABEL_5966_TestLikeCollation_CI_AI WHERE Col LIKE @pattern;
    SELECT COUNT(*) AS cs_ai FROM BABEL_5966_TestLikeCollation_CS_AI WHERE Col LIKE @pattern;
END;
GO

CREATE PROCEDURE BABEL_5966_sp_like_nvar_collations @pattern NVARCHAR(50) AS
BEGIN
    SELECT COUNT(*) AS ci_as FROM BABEL_5966_TestLikeNVarCollation_CI_AS WHERE Col LIKE @pattern;
    SELECT COUNT(*) AS cs_as FROM BABEL_5966_TestLikeNVarCollation_CS_AS WHERE Col LIKE @pattern;
    SELECT COUNT(*) AS ci_ai FROM BABEL_5966_TestLikeNVarCollation_CI_AI WHERE Col LIKE @pattern;
    SELECT COUNT(*) AS cs_ai FROM BABEL_5966_TestLikeNVarCollation_CS_AI WHERE Col LIKE @pattern;
END;
GO

CREATE PROCEDURE BABEL_5966_sp_like_char_collations @pattern NVARCHAR(50) AS
BEGIN
    SELECT COUNT(*) AS ci_as FROM BABEL_5966_TestLikeCharCollation_CI_AS WHERE Col LIKE @pattern;
    SELECT COUNT(*) AS cs_as FROM BABEL_5966_TestLikeCharCollation_CS_AS WHERE Col LIKE @pattern;
    SELECT COUNT(*) AS ci_ai FROM BABEL_5966_TestLikeCharCollation_CI_AI WHERE Col LIKE @pattern;
    SELECT COUNT(*) AS cs_ai FROM BABEL_5966_TestLikeCharCollation_CS_AI WHERE Col LIKE @pattern;
END;
GO

CREATE PROCEDURE BABEL_5966_sp_like_with_cast @val VARCHAR(50) AS
BEGIN
    SELECT COUNT(*) AS cast_varchar FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE CAST(@val AS VARCHAR(50));
    SELECT COUNT(*) AS cast_nvarchar FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE CAST(@val AS NVARCHAR(50));
END;
GO

CREATE PROCEDURE BABEL_5966_sp_like_multi_condition @p1 NVARCHAR(50), @p2 NVARCHAR(50) AS
BEGIN
    SELECT COUNT(*) AS and_cnt FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE @p1 AND NVarcharCol LIKE @p2;
    SELECT COUNT(*) AS or_cnt FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE @p1 OR VarcharCol LIKE @p2;
END;
GO

CREATE PROCEDURE BABEL_5966_sp_like_subquery @pattern NVARCHAR(50) AS
BEGIN
    SELECT COUNT(*) AS cnt FROM BABEL_5966_TestLikeIndex
    WHERE Id IN (SELECT Id FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE @pattern);
END;
GO

CREATE PROCEDURE BABEL_5966_sp_like_exists @pattern NVARCHAR(50) AS
BEGIN
    SELECT COUNT(*) AS cnt FROM BABEL_5966_TestLikeIndex t1
    WHERE EXISTS (SELECT 1 FROM BABEL_5966_TestLikeIndex t2 WHERE t2.VarcharCol LIKE @pattern AND t2.Id = t1.Id);
END;
GO

CREATE PROCEDURE BABEL_5966_sp_like_top @pattern NVARCHAR(50), @top INT AS
BEGIN
    SELECT TOP(@top) VarcharCol FROM BABEL_5966_TestLikeIndex WHERE VarcharCol LIKE @pattern ORDER BY VarcharCol;
END;
GO

-- CHECK Constraints

CREATE TABLE BABEL_5966_TestLikeCheck_prefix (
    Id INT IDENTITY PRIMARY KEY,
    Col VARCHAR(50) CHECK (Col LIKE 'valid%')
);
GO

CREATE TABLE BABEL_5966_TestLikeCheck_nprefix (
    Id INT IDENTITY PRIMARY KEY,
    Col VARCHAR(50) CHECK (Col LIKE N'valid%')
);
GO

CREATE TABLE BABEL_5966_TestLikeCheck_not_like (
    Id INT IDENTITY PRIMARY KEY,
    Col VARCHAR(50) CHECK (Col NOT LIKE 'bad%')
);
GO

CREATE TABLE BABEL_5966_TestLikeCheck_escape (
    Id INT IDENTITY PRIMARY KEY,
    Col VARCHAR(50) CHECK (Col LIKE '100!%%' ESCAPE '!')
);
GO

CREATE TABLE BABEL_5966_TestLikeCheck_suffix (
    Id INT IDENTITY PRIMARY KEY,
    Col VARCHAR(50) CHECK (Col LIKE '%_valid')
);
GO
