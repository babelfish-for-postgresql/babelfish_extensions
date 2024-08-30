-- expression as column
SELECT STRING_AGG(a,'-') FROM string_agg_t
GO

SELECT STRING_AGG(a,'-') FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY sbid) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY sbid ASC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY sbid DESC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY id, sbid ASC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY id, sbid DESC) FROM string_agg_t GROUP BY g ORDER BY g
GO

-- expression as expression of multiple columns
SELECT STRING_AGG(a+b,'-') FROM string_agg_t
GO

SELECT STRING_AGG(a+b,'-') FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a+b,'-') WITHIN GROUP (ORDER BY sbid) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a+b,'-') WITHIN GROUP (ORDER BY sbid ASC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a+b,'-') WITHIN GROUP (ORDER BY sbid DESC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a+b,'-') WITHIN GROUP (ORDER BY id, sbid ASC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a+b,'-') WITHIN GROUP (ORDER BY id, sbid DESC) FROM string_agg_t GROUP BY g ORDER BY g
GO

-- expression as function
SELECT STRING_AGG(concat(a,b),'-') FROM string_agg_t
GO

SELECT STRING_AGG(concat(a,b),'-') FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(concat(a,b),'-') WITHIN GROUP (ORDER BY sbid) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(concat(a,b),'-') WITHIN GROUP (ORDER BY sbid ASC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(concat(a,b),'-') WITHIN GROUP (ORDER BY sbid DESC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(concat(a,b),'-') WITHIN GROUP (ORDER BY id, sbid ASC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(concat(a,b),'-') WITHIN GROUP (ORDER BY id, sbid DESC) FROM string_agg_t GROUP BY g ORDER BY g
GO

-- Delimeter as a function
SELECT STRING_AGG(a, char(10)) FROM string_agg_t
GO

SELECT STRING_AGG(a, char(10)) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY sbid) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY sbid ASC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY sbid DESC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY id, sbid ASC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY id, sbid DESC) FROM string_agg_t GROUP BY g ORDER BY g
GO

-- order by clause on string column
SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY a ASC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY a DESC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a+b,'-') WITHIN GROUP (ORDER BY a+b ASC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a+b,'-') WITHIN GROUP (ORDER BY a+b DESC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(concat(a,b),'-') WITHIN GROUP (ORDER BY concat(a,b) ASC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(concat(a,b),'-') WITHIN GROUP (ORDER BY concat(a,b) DESC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY a ASC) FROM string_agg_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY a DESC) FROM string_agg_t GROUP BY g ORDER BY g
GO

-- Batch statements
SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY sbid) FROM string_agg_t GROUP BY g ORDER BY g
SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY sbid ASC) FROM string_agg_t GROUP BY g ORDER BY g
SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY sbid DESC) FROM string_agg_t GROUP BY g ORDER BY g
SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY id, sbid ASC) FROM string_agg_t GROUP BY g ORDER BY g
SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY id, sbid DESC) FROM string_agg_t GROUP BY g ORDER BY g
GO

-- expression as column with multibyte characters
SELECT STRING_AGG(a,'-') FROM string_agg_multibyte_t
GO

SELECT STRING_AGG(a,'-') FROM string_agg_multibyte_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY sbid) FROM string_agg_multibyte_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY sbid ASC) FROM string_agg_multibyte_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY sbid DESC) FROM string_agg_multibyte_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY id, sbid ASC) FROM string_agg_multibyte_t GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY id, sbid DESC) FROM string_agg_multibyte_t GROUP BY g ORDER BY g
GO

-- casting result to NVARCHAR to verify the output
SELECT CAST(STRING_AGG(a,'-') AS sys.NVARCHAR(100)) FROM string_agg_multibyte_t
GO

SELECT CAST(STRING_AGG(a,'-') AS sys.NVARCHAR(100)) FROM string_agg_multibyte_t GROUP BY g ORDER BY g
GO

SELECT CAST(STRING_AGG(a,'-') WITHIN GROUP (ORDER BY sbid) AS sys.NVARCHAR(100)) FROM string_agg_multibyte_t GROUP BY g ORDER BY g
GO

SELECT CAST(STRING_AGG(a,'-') WITHIN GROUP (ORDER BY sbid ASC) AS sys.NVARCHAR(100)) FROM string_agg_multibyte_t GROUP BY g ORDER BY g
GO

SELECT CAST(STRING_AGG(a,'-') WITHIN GROUP (ORDER BY sbid DESC) AS sys.NVARCHAR(100)) FROM string_agg_multibyte_t GROUP BY g ORDER BY g
GO

SELECT CAST(STRING_AGG(a,'-') WITHIN GROUP (ORDER BY id, sbid ASC) AS sys.NVARCHAR(100)) FROM string_agg_multibyte_t GROUP BY g ORDER BY g
GO

SELECT CAST(STRING_AGG(a,'-') WITHIN GROUP (ORDER BY id, sbid DESC) AS sys.NVARCHAR(100)) FROM string_agg_multibyte_t GROUP BY g ORDER BY g
GO

-- expression as column with chinese characters
SELECT STRING_AGG(a,'-') FROM string_agg_chinese_prc_ci_as
GO

SELECT STRING_AGG(a,'-') FROM string_agg_chinese_prc_ci_as GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY sbid) FROM string_agg_chinese_prc_ci_as GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY sbid ASC) FROM string_agg_chinese_prc_ci_as GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY sbid DESC) FROM string_agg_chinese_prc_ci_as GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY id, sbid ASC) FROM string_agg_chinese_prc_ci_as GROUP BY g ORDER BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY id, sbid DESC) FROM string_agg_chinese_prc_ci_as GROUP BY g ORDER BY g
GO

-- expression from a column of a subquery
SELECT STRING_AGG(sbq.b,'-') WITHIN GROUP (ORDER BY g1) FROM (SELECT g1, g2, STRING_AGG(a,'-') WITHIN GROUP (ORDER BY id) as 'b' FROM string_agg_t2 GROUP BY g1, g2) as sbq GROUP BY g2 ORDER BY g2
GO

SELECT STRING_AGG(sbq.b,'-') WITHIN GROUP (ORDER BY g1 ASC) FROM (SELECT g1, g2, STRING_AGG(a,'-') WITHIN GROUP (ORDER BY id ASC) as 'b' FROM string_agg_t2 GROUP BY g1, g2) as sbq GROUP BY g2 ORDER BY g2
GO

SELECT STRING_AGG(sbq.b,'-') WITHIN GROUP (ORDER BY g1 DESC) FROM (SELECT g1, g2, STRING_AGG(a,'-') WITHIN GROUP (ORDER BY id DESC) as 'b' FROM string_agg_t2 GROUP BY g1, g2) as sbq GROUP BY g2 ORDER BY g2
GO

-- Dependent objects
SELECT * FROM string_agg_dep_v1
GO

EXEC string_agg_dep_p1
GO

SELECT dbo.string_agg_dep_f1()
GO

SELECT * FROM string_agg_dep_v2
GO

EXEC string_agg_dep_p2
GO

SELECT * FROM dbo.string_agg_dep_f2()
GO

SELECT * FROM string_agg_dep_v3
GO

EXEC string_agg_dep_p3
GO

SELECT * FROM dbo.string_agg_dep_f3()
GO

-- dependent object trigger
INSERT INTO string_agg_school_details (classID, rollID, studentName)
VALUES (2, 3, 'StudentF');
GO

UPDATE string_agg_school_details
SET studentName = 'StudentG'
WHERE classID = 2 AND rollID = 3;
GO

DELETE FROM string_agg_school_details
WHERE classID = 1 AND rollID = 2;
GO
