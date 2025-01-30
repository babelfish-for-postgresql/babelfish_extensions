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

-- Create a unique index on test_tb
CREATE UNIQUE INDEX uid ON test_tb(id)
GO

-- Create schema
CREATE SCHEMA fts_schema
GO

-- Create a table over that schema

CREATE TABLE fts_schema.test_tb1 (
    sr INT NOT NULL,
    txt TEXT,
    chr CHAR(5),
    val VARCHAR(100)
);
GO

-- Insert 1000 records using recursive CTE
WITH NumberSequence AS (
    SELECT 1 AS sr
    UNION ALL
    SELECT sr + 1
    FROM NumberSequence
    WHERE sr < 1000
),
SampleData AS (
    -- Sample text data for txt column
    SELECT n, long_text FROM (VALUES
        (1, 'The quick brown fox jumps over the lazy dog'),
        (2, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit'),
        (3, 'To be or not to be, that is the question'),
        (4, 'All work and no play makes Jack a dull boy'),
        (5, 'The only way to do great work is to love what you do')
    ) AS LongText(n, long_text)
),
CharData AS (
    -- Sample data for chr column
    SELECT n, char_val FROM (VALUES
        (1, 'hi'),
        (2, 'you'),
        (3, 'us'),
        (4, 'two'),
        (5, 'four'),
        (6, 'six'),
        (7, 'three'),
        (8, 'why'),
        (9, 'ok'),
        (10, 'nope')
    ) AS Chars(n, char_val)
),
VarcharData AS (
    -- Sample data for val column
    SELECT n, var_text FROM (VALUES
        (1, 'Product-A123'),
        (2, 'Customer#456'),
        (3, 'Order_789'),
        (4, 'Invoice/001'),
        (5, 'REF-2024-001'),
        (6, 'CODE:ABC123'),
        (7, 'ID#12345'),
        (8, 'TEST-999'),
        (9, 'SAMPLE@001'),
        (10, 'DOC#2024')
    ) AS VarText(n, var_text)
)
INSERT INTO fts_schema.test_tb1 (sr, txt, chr, val)
SELECT 
    n.sr,
    -- txt: Rotate through sample texts
    sd.long_text,
    -- chr: Rotate through single characters
    cd.char_val,
    -- val: Rotate through varchar values
    vd.var_text
FROM 
    NumberSequence n
    CROSS APPLY (
        SELECT long_text 
        FROM SampleData 
        WHERE n = ((n.sr - 1) % 5) + 1
    ) sd
    CROSS APPLY (
        SELECT char_val 
        FROM CharData 
        WHERE n = ((n.sr - 1) % 10) + 1
    ) cd
    CROSS APPLY (
        SELECT var_text 
        FROM VarcharData 
        WHERE n = ((n.sr - 1) % 10) + 1
    ) vd
OPTION (MAXRECURSION 1000);
GO

CREATE UNIQUE INDEX usr ON fts_schema.test_tb1(sr);
GO

CREATE FULLTEXT INDEX ON fts_schema.test_tb1(txt, val) KEY INDEX usr
GO