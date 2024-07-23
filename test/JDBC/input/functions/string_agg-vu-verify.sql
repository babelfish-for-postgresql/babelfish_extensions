-- expression as column
SELECT STRING_AGG(a,'-') FROM string_agg_t
GO

SELECT STRING_AGG(a,'-') FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY sbid) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY sbid ASC) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY sbid DESC) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY id, sbid ASC) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(a,'-') WITHIN GROUP (ORDER BY id, sbid DESC) FROM string_agg_t GROUP BY g
GO

-- expression as expression of multiple columns
SELECT STRING_AGG(a+b,'-') FROM string_agg_t
GO

SELECT STRING_AGG(a+b,'-') FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(a+b,'-') WITHIN GROUP (ORDER BY sbid) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(a+b,'-') WITHIN GROUP (ORDER BY sbid ASC) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(a+b,'-') WITHIN GROUP (ORDER BY sbid DESC) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(a+b,'-') WITHIN GROUP (ORDER BY id, sbid ASC) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(a+b,'-') WITHIN GROUP (ORDER BY id, sbid DESC) FROM string_agg_t GROUP BY g
GO

-- expression as function
SELECT STRING_AGG(concat(a,b),'-') FROM string_agg_t
GO

SELECT STRING_AGG(concat(a,b),'-') FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(concat(a,b),'-') WITHIN GROUP (ORDER BY sbid) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(concat(a,b),'-') WITHIN GROUP (ORDER BY sbid ASC) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(concat(a,b),'-') WITHIN GROUP (ORDER BY sbid DESC) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(concat(a,b),'-') WITHIN GROUP (ORDER BY id, sbid ASC) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(concat(a,b),'-') WITHIN GROUP (ORDER BY id, sbid DESC) FROM string_agg_t GROUP BY g
GO

-- Delimeter as a function
SELECT STRING_AGG(a, char(10)) FROM string_agg_t
GO

SELECT STRING_AGG(a, char(10)) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY sbid) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY sbid ASC) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY sbid DESC) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY id, sbid ASC) FROM string_agg_t GROUP BY g
GO

SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY id, sbid DESC) FROM string_agg_t GROUP BY g
GO

-- Batch statements
SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY sbid) FROM string_agg_t GROUP BY g
SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY sbid ASC) FROM string_agg_t GROUP BY g
SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY sbid DESC) FROM string_agg_t GROUP BY g
SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY id, sbid ASC) FROM string_agg_t GROUP BY g
SELECT STRING_AGG(a, char(10)) WITHIN GROUP (ORDER BY id, sbid DESC) FROM string_agg_t GROUP BY g
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
INSERT INTO string_agg_order_school (classID, rollID, studentName)
VALUES (2, 3, 'StudentF');
GO

UPDATE string_agg_order_school
SET studentName = 'StudentG'
WHERE classID = 2 AND rollID = 3;
GO

DELETE FROM string_agg_order_school
WHERE classID = 1 AND rollID = 2;
GO
