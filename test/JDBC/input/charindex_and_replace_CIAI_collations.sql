/* CHARINDEX WITH CI_AI COLLATIONS */

CREATE TABLE #BABEL_4850_TEMP(id NVARCHAR(100))
GO
CREATE TABLE BABEL_4850_T(id NVARCHAR(100))
GO

INSERT INTO #BABEL_4850_TEMP VALUES ('AAAAAE'), ('AeAAAaE'), ('AeAAAaE'), ('AAAAAABBBBBBBEEEEEEAAAAA')
INSERT INTO BABEL_4850_T VALUES ('AAAAAE'), ('AeAAAaE'), ('AeAAAaE'), ('AAAAAABBBBBBBEEEEEEAAAAA')
GO

/* CI_AS */

/* Cases where single character is equal to two characters */
SELECT CHARINDEX('Æ','AAAAAE' COLLATE Latin1_General_CI_AI)
SELECT CHARINDEX('Æ','AeAAAaE' COLLATE Latin1_General_CI_AI, 2)
SELECT CHARINDEX('Æ','AeAAAaE' COLLATE Latin1_General_CI_AI, 1)
SELECT CHARINDEX('Æ', 'AAAAAABBBBBBBEEEEEEAAAAA' COLLATE Latin1_General_CI_AI);
SELECT CHARINDEX('ÆA','AeAEAAAAaE' COLLATE Latin1_General_CI_AI, 1)
GO

SELECT CHARINDEX('Æ', id COLLATE Latin1_General_CI_AI) FROM #BABEL_4850_TEMP
GO
SELECT CHARINDEX('Æ', id COLLATE Latin1_General_CI_AI) FROM BABEL_4850_T
GO

/* BASIC TEST CASES */
/* These should find a result */
SELECT CHARINDEX('cat', 'The cat is on the mat' COLLATE Latin1_General_CI_AI, 1);
SELECT CHARINDEX('cafe', 'The Café is cozy' COLLATE Latin1_General_CI_AI, 1);
/* These should not find a result */
SELECT CHARINDEX('dog', 'The cat is on the mat' COLLATE Latin1_General_CI_AI, 1);
SELECT CHARINDEX('caé', 'The café is cozy' COLLATE Latin1_General_CI_AI, 1);
GO

/* empty arguments */
SELECT CHARINDEX('', 'The café is cozy' COLLATE Latin1_General_CI_AI, 1);
SELECT CHARINDEX('café', '' COLLATE Latin1_General_CI_AI, 1);
SELECT CHARINDEX('', '' COLLATE Latin1_General_CI_AI, 1)
GO

/* case sensitivity */
SELECT CHARINDEX('tHe Cať', 'Where is The càt ???' COLLATE Latin1_General_CI_AI);
SELECT CHARINDEX('caT', 'The Cat̤ is on the mat' COLLATE Latin1_General_CI_AI);
GO

SELECT CHARINDEX('cat', 'The cat is on the mat cAť' COLLATE Latin1_General_CI_AI, 6)
SELECT CHARINDEX('cat', 'The cat is on the mat' COLLATE Latin1_General_CI_AI, 30)
GO

/* REPLACE WITH CI_AI COLLATIONS */

/* BASIC TEST CASES */
/* These should find a result */
SELECT REPLACE('This café is cozy.', 'café', 'coffee' COLLATE Latin1_General_CI_AI)
SELECT REPLACE('The café is open for business.', 'café is', 'coffee shops are' COLLATE Latin1_General_CI_AI)
SELECT REPLACE('This café is cozy.', 'tea', 'coffee' COLLATE Latin1_General_CI_AI)
SELECT REPLACE('The café serves café au lait.', 'café', 'coffee' COLLATE Latin1_General_CI_AI)
GO

SELECT REPLACE('café is cozy.', 'café', 'coffee' COLLATE Latin1_General_CI_AI)
SELECT REPLACE('The café is good.', 'is', 'was' COLLATE Latin1_General_CI_AI)
GO

SELECT REPLACE(REPLACE('The café is open.', 'café', 'coffee' COLLATE Latin1_General_CI_AI), 'open', 'closed' COLLATE Latin1_General_CI_AI)
GO

SELECT REPLACE('The café is great.', 'gřeat', N'>>>>>>' COLLATE Latin1_General_CI_AI)
SELECT REPLACE('This café is cozy.', 'café', N'cAfë' COLLATE Latin1_General_CI_AI)
GO

SELECT REPLACE('This café is cozy.', '', 'coffee' COLLATE Latin1_General_CI_AI)
SELECT REPLACE('', '', 'coffee' COLLATE Latin1_General_CI_AI)
SELECT REPLACE('This café is cozy.', 'café', '' COLLATE Latin1_General_CI_AI)
GO

SELECT REPLACE('This café is cozy.', 'CAFÉ', 'coffee' COLLATE Latin1_General_CI_AI)
GO

SELECT REPLACE('This café is café.', 'café', 'coffee' COLLATE Latin1_General_CI_AI)
GO

SELECT REPLACE('This café is !.', '!', 'coffee' COLLATE Latin1_General_CI_AI)
GO

SELECT REPLACE('This café is cozy.', ' ', ' ' COLLATE Latin1_General_CI_AI)
SELECT REPLACE(N'The café is!.', '!', '@@' COLLATE Latin1_General_CI_AI)
GO

/* overlapping case */
SELECT REPLACE ('ABCABCABCABCABC','abcÀBć' collate Latin1_General_CI_AI, 'abcabc')
GO

/* Cases where single character is equal to two characters */
SELECT REPLACE ('aaaaaaÆaaaaaaÆaaaa','AE' collate Latin1_General_CI_AI, '!---!')
SELECT REPLACE ('ÆAEaaaaaaÆ','AE' collate Latin1_General_CI_AI, '!---!')
SELECT REPLACE ('eeeeeeeeeAAAAAA','AE' collate Latin1_General_CI_AI, '!---!')
GO

SELECT REPLACE(id, 'Æ' COLLATE Latin1_General_CI_AI, '!---!') FROM #BABEL_4850_TEMP
GO
SELECT REPLACE(id, 'Æ' COLLATE Latin1_General_CI_AI, '!---!') FROM BABEL_4850_T
GO




/* CS_AS */

/* CHARINDEX WITH CS_AI COLLATIONS */

SELECT CHARINDEX('Æ', id COLLATE Latin1_General_CS_AI) FROM #BABEL_4850_TEMP
GO
SELECT CHARINDEX('Æ', id COLLATE Latin1_General_CS_AI) FROM BABEL_4850_T
GO

/* Cases where single character is equal to two characters */
SELECT CHARINDEX('Æ','AAAAAE' COLLATE Latin1_General_CS_AI)
SELECT CHARINDEX('Æ','AeAAAaE' COLLATE Latin1_General_CS_AI, 2)
SELECT CHARINDEX('Æ','AeAAAaE' COLLATE Latin1_General_CS_AI, 1)
SELECT CHARINDEX('Æ', 'AAAAAABBBBBBBEEEEEEAAAAA' COLLATE Latin1_General_CS_AI);
SELECT CHARINDEX('ÆA','AeAEAAAAaE' COLLATE Latin1_General_CS_AI, 1)
GO

/* BASIC TEST CASES */
/* These should find a result */
SELECT CHARINDEX('cat', 'The cat is on the mat' COLLATE Latin1_General_CS_AI, 1);
SELECT CHARINDEX('cafe', 'The Café is cozy' COLLATE Latin1_General_CS_AI, 1);
/* These should not find a result */
SELECT CHARINDEX('dog', 'The cat is on the mat' COLLATE Latin1_General_CS_AI, 1);
SELECT CHARINDEX('caé', 'The café is cozy' COLLATE Latin1_General_CS_AI, 1);
GO

/* empty arguments */
SELECT CHARINDEX('', 'The café is cozy' COLLATE Latin1_General_CS_AI, 1);
SELECT CHARINDEX('café', '' COLLATE Latin1_General_CS_AI, 1);
SELECT CHARINDEX('', '' COLLATE Latin1_General_CS_AI, 1)
GO

/* case sensitivity */
SELECT CHARINDEX('tHe Cať', 'Where is The càt ???' COLLATE Latin1_General_CS_AI);
SELECT CHARINDEX('caT', 'The Cat̤ is on the mat' COLLATE Latin1_General_CS_AI);
GO

SELECT CHARINDEX('cat', 'The cat is on the mat cAť' COLLATE Latin1_General_CS_AI, 6)
SELECT CHARINDEX('cat', 'The cat is on the mat' COLLATE Latin1_General_CS_AI, 30)
GO

/* REPLACE WITH CS_AI COLLATIONS */

/* BASIC TEST CASES */
/* These should find a result */
SELECT REPLACE('This café is cozy.', 'café', 'coffee' COLLATE Latin1_General_CS_AI)
SELECT REPLACE('The café is open for business.', 'café is', 'coffee shops are' COLLATE Latin1_General_CS_AI)
SELECT REPLACE('This café is cozy.', 'tea', 'coffee' COLLATE Latin1_General_CS_AI)
SELECT REPLACE('The café serves café au lait.', 'café', 'coffee' COLLATE Latin1_General_CS_AI)
GO

SELECT REPLACE('café is cozy.', 'café', 'coffee' COLLATE Latin1_General_CS_AI)
SELECT REPLACE('The café is good.', 'is', 'was' COLLATE Latin1_General_CS_AI)
GO

SELECT REPLACE(REPLACE('The café is open.', 'café', 'coffee' COLLATE Latin1_General_CS_AI), 'open', 'closed' COLLATE Latin1_General_CS_AI)
GO

SELECT REPLACE('The café is great.', 'gřeat', N'>>>>>>' COLLATE Latin1_General_CS_AI)
SELECT REPLACE('This café is cozy.', 'café', N'cAfë' COLLATE Latin1_General_CS_AI)
GO

SELECT REPLACE('This café is cozy.', '', 'coffee' COLLATE Latin1_General_CS_AI)
SELECT REPLACE('', '', 'coffee' COLLATE Latin1_General_CS_AI)
SELECT REPLACE('This café is cozy.', 'café', '' COLLATE Latin1_General_CS_AI)
GO

SELECT REPLACE('This café is cozy.', 'CAFÉ', 'coffee' COLLATE Latin1_General_CS_AI)
GO

SELECT REPLACE('This café is café.', 'café', 'coffee' COLLATE Latin1_General_CS_AI)
GO

SELECT REPLACE('This café is !.', '!', 'coffee' COLLATE Latin1_General_CS_AI)
GO

SELECT REPLACE('This café is cozy.', ' ', ' ' COLLATE Latin1_General_CS_AI)
SELECT REPLACE(N'The café is!.', '!', '@@' COLLATE Latin1_General_CS_AI)
GO

/* overlapping case */
SELECT REPLACE ('ABCABCABCABCABC','abcÀBć' collate Latin1_General_CS_AI, 'abcabc')
GO

/* Cases where single character is equal to two characters */
SELECT REPLACE ('aaaaaaÆaaaaaaÆaaaa','AE' collate Latin1_General_CS_AI, '!---!')
SELECT REPLACE ('ÆAEaaaaaaÆ','AE' collate Latin1_General_CS_AI, '!---!')
SELECT REPLACE ('eeeeeeeeeAAAAAA','AE' collate Latin1_General_CS_AI, '!---!')
GO

SELECT REPLACE(id, 'Æ' COLLATE Latin1_General_CS_AI, '!---!') FROM #BABEL_4850_TEMP
GO
SELECT REPLACE(id, 'Æ' COLLATE Latin1_General_CS_AI, '!---!') FROM BABEL_4850_T
GO

DROP TABLE BABEL_4850_T
GO