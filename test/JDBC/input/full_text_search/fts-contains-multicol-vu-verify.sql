-- enable FULLTEXT
-- tsql user=jdbc_user password=12345678
SELECT set_config('babelfishpg_tsql.escape_hatch_fulltext', 'ignore', 'false')
GO

-- Basic Multiple Column Tests
SELECT sys.replace_special_chars_fts('one`two', 'three@four', 'five#six');
GO

-- Mixed Single and Multiple Column Tests
SELECT sys.replace_special_chars_fts('"one @ @ @ @ two"');
GO

-- Quoted String Multiple Column Tests
SELECT sys.replace_special_chars_fts('"one @ two"', '"three $ four"', '"five # six"');
GO

-- Apostrophe Multiple Column Tests
SELECT sys.replace_special_chars_fts('Arts '' opening', 'Bob''s place', 'Smith''s store');
GO

-- Empty and NULL Multiple Column Tests
SELECT sys.replace_special_chars_fts('', NULL, 'three');
GO

-- Mixed Content Type Tests
SELECT sys.replace_special_chars_fts('normal text', '"quoted text"', 'special@text');
GO


-- Test cases for the relation test_tb

-- gives error as fulltext index is still not created
SELECT * FROM test_tb WHERE contains(txt1, '"human or quantum')
GO

CREATE FULLTEXT INDEX ON test_tb(txt1, txt2, txt3, txt4) KEY INDEX uid
GO

select * from test_tb where contains((txt1, txt2, txt4), '"Artificial Intelligence"' )
GO

DROP FULLTEXT INDEX ON test_tb
GO

CREATE FULLTEXT INDEX ON test_tb(txt1, txt2) KEY INDEX uid
GO

SELECT * FROM test_tb WHERE contains((txt1, txt2), '"The human genome"' )
GO

-- negative test
-- should throw an error as the column txt3 is not fulltext indexed, BUT DOES NOT
SELECT * FROM test_tb WHERE contains((txt1, txt3), '"The Industrial Revolution"')
GO

-- negative test
-- should throw an error as the columns txt3 and txt4 are not fulltext indexed, BUT DOES NOT
SELECT * FROM test_tb WHERE contains((txt4, txt3), '"The Industrial Revolution"')
GO



-- Test cases for the relation fts_schema.test_tb1

SELECT * FROM fts_schema.test_tb1 WHERE contains((txt, val), 'Product-A123')
GO

-- should throw an error as the previous full text index is not dropped
CREATE FULLTEXT INDEX ON fts_schema.test_tb1(val, chr) KEY INDEX usr
GO

-- negative test
-- should throw an error as chr is not fulltext indexed, BUT DOES NOT
SELECT * FROM fts_schema.test_tb1 WHERE contains((val, chr), 'four')
GO

DROP FULLTEXT INDEX ON fts_schema.test_tb1
GO

CREATE FULLTEXT INDEX ON fts_schema.test_tb1(txt, val, chr) KEY INDEX usr
GO

SELECT * FROM fts_schema.test_tb1 WHERE contains((test_tb1.txt, val), '"The quick brown fox"')
GO

SELECT * FROM fts_schema.test_tb1 WHERE contains((test_tb1.val, test_tb1.chr), 'TEST-999')
GO

SELECT * FROM fts_schema.test_tb1 WHERE contains((fts_schema.test_tb1.txt, test_tb1.chr), 'three')
GO

SELECT * FROM fts_schema.test_tb1 WHERE contains((fts_schema.test_tb1.txt, fts_schema.test_tb1.val, chr), 'Invoice/001')
GO
