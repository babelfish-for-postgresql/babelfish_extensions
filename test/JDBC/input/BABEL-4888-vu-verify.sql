-- table 1 id1 & id2 should be individually unique

INSERT INTO babel_4888_t1 VALUES (-1, '-a', 0x0001), (1, '+a', 0x1001), (NULL, '', NULL), (0, NULL, NULL)
GO

INSERT INTO babel_4888_t1 VALUES (NULL, 'random', 0x9999)
GO

INSERT INTO babel_4888_t1 VALUES (9999, NULL, 0x9999)
GO

INSERT INTO babel_4888_t1 VALUES (9999, 'random', NULL)
GO

-- table 2 Combination of id1 & id2 should be unique

INSERT INTO babel_4888_t2 VALUES (-1, '-a', 0x0001), (1, '+a', 0x1001), (NULL, '', NULL), (0, NULL, NULL)
GO

INSERT INTO babel_4888_t2 VALUES (NULL, '', 0x9999)
GO

INSERT INTO babel_4888_t2 VALUES (0, NULL, 0x9999)
GO

INSERT INTO babel_4888_t2 VALUES (NULL, NULL, NULL)
GO

INSERT INTO babel_4888_t2 VALUES (NULL, NULL, 0x9999)
GO

-- table 3 id1 & id2 should be individually unique

INSERT INTO babel_4888_t3 VALUES (-1, '-a', 0x0001), (1, '+a', 0x1001), (NULL, '', NULL), (0, NULL, NULL)
GO

INSERT INTO babel_4888_t3 VALUES (NULL, '', 0x9999)
GO

INSERT INTO babel_4888_t3 VALUES (0, NULL, 0x9999)
GO

INSERT INTO babel_4888_t3 VALUES (NULL, NULL, NULL)
GO

INSERT INTO babel_4888_t3 VALUES (NULL, NULL, 0x9999)
GO

-- table 4 Combination of id1 & id2 should be unique

INSERT INTO babel_4888_t4 VALUES (-1, '-a', 0x0001), (1, '+a', 0x1001), (NULL, '', NULL), (0, NULL, NULL)
GO

INSERT INTO babel_4888_t4 VALUES (NULL, '', 0x9999)
GO

INSERT INTO babel_4888_t4 VALUES (0, NULL, 0x9999)
GO

INSERT INTO babel_4888_t4 VALUES (NULL, NULL, NULL)
GO

INSERT INTO babel_4888_t4 VALUES (NULL, NULL, 0x9999)
GO

SELECT indexdef FROM pg_indexes 
WHERE tablename LIKE '%babel_4888%'
ORDER BY indexdef
GO
