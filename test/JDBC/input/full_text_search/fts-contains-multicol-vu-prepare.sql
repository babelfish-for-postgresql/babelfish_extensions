-- enable FULLTEXT
-- tsql user=jdbc_user password=12345678
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'ignore', 'false')
GO
-- Create the test table
CREATE TABLE test_tb (
    id INT NOT NULL,
    txt1 text,
    txt2 text,
    txt3 text,
    txt4 text
);
GO

-- Direct insert of 1000 rows using recursive CTE and predefined content
WITH NumberSequence AS (
    -- Generate numbers 1 to 1000 using recursive CTE
    SELECT 1 AS id
    UNION ALL
    SELECT id + 1
    FROM NumberSequence
    WHERE id < 1000
),
ContentSet AS (
    -- Define all possible content for each topic
    SELECT 1 as topic_id, 1 as content_id, 'The human genome contains approximately 3 billion DNA base pairs.' as content UNION ALL
    SELECT 1, 2, 'Quantum computing leverages superposition to perform complex calculations.' UNION ALL
    SELECT 1, 3, 'Photosynthesis converts light energy into chemical energy in plants.' UNION ALL
    SELECT 1, 4, 'Black holes are regions where gravity''s pull is so strong that nothing can escape.' UNION ALL
    SELECT 1, 5, 'The periodic table organizes elements based on their atomic structure.' UNION ALL
    
    SELECT 2, 1, 'The Renaissance period marked Europe''s cultural rebirth in the 14th century.' UNION ALL
    SELECT 2, 2, 'Ancient Egyptians built the pyramids as tombs for their pharaohs.' UNION ALL
    SELECT 2, 3, 'The Industrial Revolution transformed manufacturing processes globally.' UNION ALL
    SELECT 2, 4, 'World War II ended in 1945 with significant global changes.' UNION ALL
    SELECT 2, 5, 'The American Revolution established independence from British rule.' UNION ALL
    
    SELECT 3, 1, 'Vincent van Gogh''s "Starry Night" exemplifies post-impressionist style.' UNION ALL
    SELECT 3, 2, 'Mozart composed his first symphony at age eight.' UNION ALL
    SELECT 3, 3, 'Shakespeare wrote 37 plays and 154 sonnets during his lifetime.' UNION ALL
    SELECT 3, 4, 'Pablo Picasso''s work defined the Cubist movement in modern art.' UNION ALL
    SELECT 3, 5, 'Ballet originated in the Italian Renaissance courts.' UNION ALL
    
    SELECT 4, 1, 'Artificial Intelligence is transforming various industries today.' UNION ALL
    SELECT 4, 2, 'Blockchain technology enables secure, decentralized transactions.' UNION ALL
    SELECT 4, 3, 'The Internet of Things connects everyday devices to the network.' UNION ALL
    SELECT 4, 4, 'Cloud computing provides scalable computing resources on demand.' UNION ALL
    SELECT 4, 5, '5G networks promise faster and more reliable connectivity.'
),
Combinations AS (
    -- Define all 24 possible combinations of topic positions
    SELECT 1 as combo_id, 1 as txt1_topic, 2 as txt2_topic, 3 as txt3_topic, 4 as txt4_topic UNION ALL
    SELECT 2, 1, 2, 4, 3 UNION ALL
    SELECT 3, 1, 3, 2, 4 UNION ALL
    SELECT 4, 1, 3, 4, 2 UNION ALL
    SELECT 5, 1, 4, 2, 3 UNION ALL
    SELECT 6, 1, 4, 3, 2 UNION ALL
    SELECT 7, 2, 1, 3, 4 UNION ALL
    SELECT 8, 2, 1, 4, 3 UNION ALL
    SELECT 9, 2, 3, 1, 4 UNION ALL
    SELECT 10, 2, 3, 4, 1 UNION ALL
    SELECT 11, 2, 4, 1, 3 UNION ALL
    SELECT 12, 2, 4, 3, 1 UNION ALL
    SELECT 13, 3, 1, 2, 4 UNION ALL
    SELECT 14, 3, 1, 4, 2 UNION ALL
    SELECT 15, 3, 2, 1, 4 UNION ALL
    SELECT 16, 3, 2, 4, 1 UNION ALL
    SELECT 17, 3, 4, 1, 2 UNION ALL
    SELECT 18, 3, 4, 2, 1 UNION ALL
    SELECT 19, 4, 1, 2, 3 UNION ALL
    SELECT 20, 4, 1, 3, 2 UNION ALL
    SELECT 21, 4, 2, 1, 3 UNION ALL
    SELECT 22, 4, 2, 3, 1 UNION ALL
    SELECT 23, 4, 3, 1, 2 UNION ALL
    SELECT 24, 4, 3, 2, 1
)
INSERT INTO test_tb (id, txt1, txt2, txt3, txt4)
SELECT 
    n.id,
    c1.content,
    c2.content,
    c3.content,
    c4.content
FROM NumberSequence n
CROSS APPLY (
    SELECT *
    FROM Combinations
    WHERE combo_id = ((n.id - 1) % 24) + 1
) combo
JOIN ContentSet c1 ON c1.topic_id = combo.txt1_topic 
    AND c1.content_id = (((n.id - 1) / 24) % 5) + 1
JOIN ContentSet c2 ON c2.topic_id = combo.txt2_topic 
    AND c2.content_id = (((n.id - 1) / 24) % 5) + 1
JOIN ContentSet c3 ON c3.topic_id = combo.txt3_topic 
    AND c3.content_id = (((n.id - 1) / 24) % 5) + 1
JOIN ContentSet c4 ON c4.topic_id = combo.txt4_topic 
    AND c4.content_id = (((n.id - 1) / 24) % 5) + 1
OPTION (MAXRECURSION 1000);
GO


-- gives error as fulltext index is still not created
SELECT * FROM test_tb WHERE contains(txt1, '"human or quantum')
GO

CREATE UNIQUE INDEX uid ON test_tb(id)
GO

CREATE FULLTEXT INDEX ON test_tb(txt1, txt2) KEY INDEX uid
GO

SELECT * FROM test_tb WHERE contains((txt1, txt2), '"The human genome"' )
GO

-- throws an error as the txt3 is not fulltext indexed
SELECT * FROM test_tb WHERE contains((txt1, txt3), '"The Industrial Revolution"')
GO

-- throws an error as txt3 and txt4 is not fulltext indexed
SELECT * FROM test_tb WHERE contains((txt4, txt3), '"The Industrial Revolution"')
GO

DROP FULLTEXT INDEX ON test_tb
GO

CREATE FULLTEXT INDEX ON test_tb(txt1, txt2, txt3, txt4) KEY INDEX uid
GO

select * from test_tb where contains((txt1, txt2, txt4), '"Artificial Intelligence"' )
GO

CREATE TABLE test_tb1 (
    sr INT NOT NULL,
    txt TEXT,
    val INT,
    small_int SMALLINT,
    mon MONEY,
	num NUMERIC(6, 3)
);
GO

-- Create table if not exists
IF OBJECT_ID('test_tb1', 'U') IS NOT NULL
    DROP TABLE test_tb1;
GO

CREATE TABLE test_tb1 (
    sr INT NOT NULL,
    txt TEXT,
    val INT,
    small_int SMALLINT,
    mon MONEY,
    num NUMERIC(6, 3)
);
GO

-- Insert 1000 records using recursive CTE with varied mock data
WITH NumberSequence AS (
    SELECT 1 AS sr
    UNION ALL
    SELECT sr + 1
    FROM NumberSequence
    WHERE sr < 1000
),
MockData AS (
    -- Sample text data
    SELECT n as id, txt FROM (VALUES
        (1, 'Monthly Revenue Report'),
        (2, 'Customer Feedback Analysis'),
        (3, 'Inventory Status Update'),
        (4, 'Employee Performance Review'),
        (5, 'Sales Forecast Summary'),
        (6, 'Quality Control Metrics'),
        (7, 'Project Timeline Status'),
        (8, 'Budget Analysis Report'),
        (9, 'Market Research Data'),
        (10, 'Operations Overview')
    ) AS SampleText(n, txt)
)
INSERT INTO test_tb1 (sr, txt, val, small_int, mon, num)
SELECT 
    n.sr,
    -- Text: Rotate through sample texts
    md.txt,
    -- Val: Generate numbers between 1000 and 100000
    ABS(CHECKSUM(NEWID())) % 99001 + 1000,
    -- Small_int: Generate numbers between -32000 and 32000
    CAST((ABS(CHECKSUM(NEWID())) % 64001) - 32000 AS SMALLINT),
    -- Money: Generate amounts between 10.00 and 9999.99
    CAST(((ABS(CHECKSUM(NEWID())) % 999000) + 1000) / 100.0 AS MONEY),
    -- Numeric: Generate numbers between 0.001 and 999.999
    CAST(((ABS(CHECKSUM(NEWID())) % 999999) + 1) / 1000.0 AS NUMERIC(6,3))
FROM 
    NumberSequence n
    CROSS APPLY (
        SELECT txt 
        FROM MockData 
        WHERE id = ((n.sr - 1) % 10) + 1
    ) md
OPTION (MAXRECURSION 1000);
GO

CREATE UNIQUE INDEX usr ON test_tb1(sr);
GO

CREATE FULLTEXT INDEX ON test_tb1(txt, val) KEY INDEX usr
GO

SELECT * FROM test_tb1 WHERE contains((txt, val), '"Monthly Revenue"')
GO

-- DROP FULLTEXT INDEX ON test_tb1
-- GO

-- should throw an error as the previous full text index is not dropped
CREATE FULLTEXT INDEX ON test_tb1(val, small_int) KEY INDEX usr
GO

-- should throw an error as small_int is not fulltext indexed
SELECT * FROM test_tb1 WHERE contains((val, small_int), '-15121')
GO

DROP FULLTEXT INDEX ON test_tb1
GO

CREATE FULLTEXT INDEX ON test_tb1(txt, mon) KEY INDEX usr
GO

SELECT * FROM test_tb1 WHERE contains((txt, val), '27802')
GO

DROP FULLTEXT INDEX ON test_tb1
GO

CREATE FULLTEXT INDEX ON test_tb1(val, small_int, mon, num) KEY INDEX usr
GO

SELECT * FROM test_tb1 WHERE contains((val, small_int, num), '481.530')
GO

DROP FULLTEXT INDEX ON test_tb1
GO

CREATE FULLTEXT INDEX ON test_tb1(txt, val, small_int, mon, num) KEY INDEX usr
GO

SELECT * FROM test_tb1 WHERE contains((txt, val), '"Customer Feedback"')
GO