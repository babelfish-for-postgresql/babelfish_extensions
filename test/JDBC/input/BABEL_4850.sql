SELECT CHARINDEX('Æ','AAAAAE' COLLATE Latin1_General_CI_AI)
SELECT CHARINDEX('Æ','AeAAAaE' COLLATE Latin1_General_CI_AI, 2)
SELECT CHARINDEX('Æ', 'AAAAAABBBBBBBEEEEEEAAAAA' COLLATE Latin1_General_CI_AI);
GO

SELECT REPLACE ('aaaaaaÆaaaaaaÆaaaa','AE' collate Latin1_General_CI_AI, '!---!')
SELECT REPLACE ('ÆAEaaaaaaÆ','AE' collate Latin1_General_CI_AI, '!---!')
SELECT REPLACE ('eeeeeeeeeAAAAAA','AE' collate Latin1_General_CI_AI, '!---!')
GO
