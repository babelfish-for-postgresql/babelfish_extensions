-- deprecated escape hatch should not throw an error but print a simple message
CREATE TABLE babel_3571_t (id INT)
GO

EXEC sp_babelfish_configure 'escape_hatch_unique_constraint', 'ignore';
INSERT INTO babel_3571_t VALUES (1);
GO

CREATE PROC babel_3571_p
AS
BEGIN
    EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'ignore', 'server';
    INSERT INTO babel_3571_t VALUES (1);
END
GO

EXEC babel_3571_p
GO

SELECT * FROM babel_3571_t
GO

DROP PROC babel_3571_p
GO

DROP TABLE babel_3571_t
GO

INSERT INTO babel_3571_11 VALUES (-1, '-a', 0x0001), (1, '+a', 0x1001), (NULL, '', NULL), (0, NULL, NULL)
GO

INSERT INTO babel_3571_11 VALUES (NULL, 'random', 0x9999)
GO

INSERT INTO babel_3571_11 VALUES (9999, NULL, 0x9999)
GO

INSERT INTO babel_3571_11 VALUES (9999, 'random', NULL)
GO


INSERT INTO babel_3571_12 VALUES (-1, '-a', 0x0001), (1, '+a', 0x1001), (NULL, '', NULL), (0, NULL, NULL)
GO

INSERT INTO babel_3571_12 VALUES (NULL, '', 0x9999)
GO

INSERT INTO babel_3571_12 VALUES (0, NULL, 0x9999)
GO

INSERT INTO babel_3571_12 VALUES (NULL, NULL, NULL)
GO

INSERT INTO babel_3571_12 VALUES (NULL, NULL, 0x9999)
GO


INSERT INTO babel_3571_13 VALUES (-1, '-a', 0x0001), (1, '+a', 0x1001), (NULL, '', NULL), (0, NULL, NULL)
GO

INSERT INTO babel_3571_13 VALUES (NULL, '', 0x9999)
GO

INSERT INTO babel_3571_13 VALUES (0, NULL, 0x9999)
GO

INSERT INTO babel_3571_13 VALUES (NULL, NULL, NULL)
GO

INSERT INTO babel_3571_13 VALUES (NULL, NULL, 0x9999)
GO

SELECT indexdef FROM pg_indexes 
WHERE tablename LIKE '%babel_3571%'
ORDER BY indexdef
GO

DROP TABLE babel_3571_11, babel_3571_12, babel_3571_13
GO

-- Repeat same tests but with more table/column specification
-- columsn with not null specification should reject NULL
INSERT INTO babel_3571_21 VALUES (-1, '-a', 0x0001), (1, '+a', 0x1001), (2, '', 0x0002), (0, 'something', 0x0003)
GO

INSERT INTO babel_3571_21 VALUES (NULL, 'random', 0x9999)
GO

INSERT INTO babel_3571_21 VALUES (9999, NULL, 0x9999)
GO

INSERT INTO babel_3571_21 VALUES (9999, 'random', NULL)
GO

INSERT INTO babel_3571_21 VALUES (9999, 'random', 0x1234)
GO

INSERT INTO babel_3571_21 VALUES (8888, 'random_again', 0x1234)
GO


INSERT INTO babel_3571_22 VALUES (-1, '-a', 0x0001), (1, '+a', 0x1001), (NULL, '', 0x0002), (0, NULL, 0x0003)
GO

INSERT INTO babel_3571_22 VALUES (NULL, '', 0x9999)
GO

INSERT INTO babel_3571_22 VALUES (0, NULL, 0x9999)
GO

INSERT INTO babel_3571_22 VALUES (1234, 'somethingrandom', NULL)
GO

INSERT INTO babel_3571_22 VALUES (1234, 'somethingrandom', 0x1234)
GO

INSERT INTO babel_3571_22 VALUES (4321, 'somethingrandomagain', 0x1234)
GO


INSERT INTO babel_3571_23 VALUES (-1, '-a', 0x0001), (1, '+a', 0x1001), (NULL, '', 0x0002), (0, NULL, 0x0003)
GO

INSERT INTO babel_3571_23 VALUES (NULL, '', 0x9999)
GO

INSERT INTO babel_3571_23 VALUES (9999, NULL, 0x9999)
GO

INSERT INTO babel_3571_23 VALUES (0, 'somethingagain', NULL)
GO

INSERT INTO babel_3571_23 VALUES (0, 'somethingagain', 0x1234)
GO

INSERT INTO babel_3571_23 VALUES (8888, 'newsomething', 0x1234)
GO


-- drop constraint
ALTER TABLE babel_3571_23 DROP CONSTRAINT babel_3571_23_unique_idxbabel_31d1688ab21096b897da1cf1ce0e5d29b
GO

INSERT INTO babel_3571_23 VALUES (NULL, NULL, 0X91)
INSERT INTO babel_3571_23 VALUES (1, '+a', 0X92)
GO

INSERT INTO babel_3571_23 VALUES (NULL, NULL, 0X0001)
GO



ALTER TABLE babel_3571_23 DROP CONSTRAINT babel_3571_23_pkeybabel_3571_23255e6842fcddf74ed00701a8a0eedc5c
INSERT INTO babel_3571_23 VALUES (NULL, NULL, 0X0001)
GO

SELECT indexdef FROM pg_indexes 
WHERE tablename LIKE '%babel_3571%'
ORDER BY indexdef
GO

DROP TABLE babel_3571_21, babel_3571_22, babel_3571_23
GO


-- CREATE TABLE WITH CONSTRAINT -- DROP COLUMN -- ADD COLUMN WITHOUT CONTRAINT
INSERT INTO babel_3571_31 VALUES (1,1), (1,1), (NULL, NULL), (NULL, NULL);
INSERT INTO babel_3571_32 VALUES (1,1), (1,1), (NULL, NULL), (NULL, NULL);
INSERT INTO babel_3571_33 VALUES (1,1), (1,1), (NULL, NULL), (NULL, NULL);
GO

SELECT indexdef FROM pg_indexes 
WHERE tablename LIKE '%babel_3571%'
ORDER BY indexdef
GO

DROP TABLE babel_3571_31, babel_3571_32, babel_3571_33
GO

-- Test with identity column
INSERT INTO babel_3571_41 VALUES (1), (2), (3)
INSERT INTO babel_3571_42 VALUES (1), (2), (3)
INSERT INTO babel_3571_43 VALUES (1), (2), (3)
GO

SET IDENTITY_INSERT dbo.babel_3571_41 ON;
GO

INSERT INTO babel_3571_41 (id1, id2) VALUES (1,10)
GO
INSERT INTO babel_3571_41 (id1, id2) VALUES (NULL,10)
GO

INSERT INTO babel_3571_41 (id1, id2) VALUES (4,10)
INSERT INTO babel_3571_41 (id1, id2) VALUES (5, NULL)
GO

SET IDENTITY_INSERT dbo.babel_3571_41 OFF;
GO

SET IDENTITY_INSERT dbo.babel_3571_42 ON;
GO

INSERT INTO babel_3571_42 (id1, id2) VALUES (1,10)
GO
INSERT INTO babel_3571_42 (id1, id2) VALUES (NULL,10)
GO

INSERT INTO babel_3571_42 (id1, id2) VALUES (4,10)
INSERT INTO babel_3571_42 (id1, id2) VALUES (5, NULL)
GO

SET IDENTITY_INSERT dbo.babel_3571_42 OFF;
GO

SET IDENTITY_INSERT dbo.babel_3571_43 ON;
GO

INSERT INTO babel_3571_43 (id1, id2) VALUES (1,10)
GO
INSERT INTO babel_3571_43 (id1, id2) VALUES (NULL,10)
GO

INSERT INTO babel_3571_43 (id1, id2) VALUES (4,10)
INSERT INTO babel_3571_43 (id1, id2) VALUES (5, NULL)
GO

SET IDENTITY_INSERT dbo.babel_3571_43 OFF;
GO

SELECT indexdef FROM pg_indexes 
WHERE tablename LIKE '%babel_3571%'
ORDER BY indexdef
GO

DROP TABLE babel_3571_41, babel_3571_42, babel_3571_43
GO