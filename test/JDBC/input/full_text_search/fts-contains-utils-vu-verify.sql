SELECT * FROM fts_rewrite_prepare_v1;
GO

EXEC fts_rewrite_prepare_p1;
GO

SELECT fts_rewrite_prepare_f1();
GO

SELECT * FROM replace_special_chars_fts_prepare_v1;
GO

EXEC replace_special_chars_fts_prepare_p1;
GO

SELECT replace_special_chars_fts_prepare_f1();
GO
