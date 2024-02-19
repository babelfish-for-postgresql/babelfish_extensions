CREATE TABLE babel_4566 (id int)
GO
CREATE TABLE bábèl_4566 (id int)
GO
INSERT INTO babel_4566 VALUES (OBJECT_ID('babel_4566')), (OBJECT_ID('bábèl_4566'))
GO

SELECT COUNT(*) FROM babel_4566
WHERE 1=1
    AND NOT OBJECT_NAME(id) LIKE '%Blah%'
GO

SELECT COUNT(*) FROM babel_4566
WHERE 
    NOT 1>1 AND ((NOT OBJECT_NAME(id) LIKE '%Blah%') AND (OBJECT_NAME(id) LIKE '%4566%'))
GO

SELECT COUNT(*) FROM babel_4566
WHERE 
    1>1 OR ((NOT OBJECT_NAME(id) LIKE '%Blah%') AND (NOT OBJECT_NAME(id) LIKE '%Blâh%'))
GO

SELECT COUNT(*) FROM babel_4566
WHERE 
    (1=1 AND NOT OBJECT_NAME(id) LIKE '%Blah%') OR ((NOT 2<1) AND (NOT OBJECT_NAME(id) LIKE '%Blâh%'))
GO

CREATE FUNCTION like_in_function (@id INT, @cmp_string VARCHAR(30))
RETURNS INT
AS
BEGIN
    DECLARE @result INT
    SELECT @result = CASE 
            WHEN ( OBJECT_NAME(@id) LIKE @cmp_string ) THEN 1
            ELSE 0
            END
    RETURN @result;
END;
GO

SELECT COUNT(*) FROM babel_4566
WHERE 1=1
    AND NOT like_in_function(id, CAST('%Blah%' AS VARCHAR(30))) = 1
GO

SELECT COUNT(*) FROM babel_4566
WHERE 
    NOT 1>1 AND ((NOT like_in_function(id, CAST('%Blah%' AS VARCHAR(30))) = 1) AND like_in_function(id, CAST('%4566%' AS VARCHAR(30))) = 1)
GO

SELECT COUNT(*) FROM babel_4566
WHERE 
    1>1 OR ((NOT like_in_function(id, CAST('%Blah%' AS VARCHAR(30))) = 1) AND (NOT like_in_function(id, CAST('%Blah%' AS VARCHAR(30))) = 1))
GO

SELECT COUNT(*) FROM babel_4566
WHERE 
    (1=1 AND (NOT like_in_function(id, CAST('%Blah%' AS VARCHAR(30))) = 1)) OR ((NOT 2<1) AND (NOT like_in_function(id, CAST('%Blah%' AS VARCHAR(30))) = 1))
GO

DROP TABLE babel_4566, bábèl_4566
GO

DROP FUNCTION like_in_function
GO