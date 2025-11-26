SELECT * FROM cast_text_to_char_1;
GO
SELECT * FROM conv_text_to_char_1;
GO
SELECT * FROM cast_text_to_char_2;
GO
SELECT * FROM conv_text_to_char_2;
GO
SELECT * FROM cast_text_to_char_3;
GO
SELECT * FROM conv_text_to_char_3;
GO
SELECT * FROM cast_text_to_char_4;
GO
SELECT * FROM conv_text_to_char_4;
GO
SELECT * FROM cast_text_to_char_5;
GO
SELECT * FROM conv_text_to_char_5;
GO
SELECT * FROM cast_text_to_char_6;
GO
SELECT * FROM conv_text_to_char_6;
GO

SELECT * FROM cast_text_to_nchar_1;
GO
SELECT * FROM conv_text_to_nchar_1;
GO
SELECT * FROM cast_text_to_nchar_2;
GO
SELECT * FROM conv_text_to_nchar_2;
GO
SELECT * FROM cast_text_to_nchar_3;
GO
SELECT * FROM conv_text_to_nchar_3;
GO
SELECT * FROM cast_text_to_nchar_4;
GO
SELECT * FROM conv_text_to_nchar_4;
GO
SELECT * FROM cast_text_to_nchar_5;
GO
SELECT * FROM conv_text_to_nchar_5;
GO
SELECT * FROM cast_text_to_nchar_6;
GO
SELECT * FROM conv_text_to_nchar_6;
GO

SELECT * FROM cast_text_to_varchar_1;
GO
SELECT * FROM conv_text_to_varchar_1;
GO
SELECT * FROM cast_text_to_varchar_2;
GO
SELECT * FROM conv_text_to_varchar_2;
GO
SELECT * FROM cast_text_to_varchar_3;
GO
SELECT * FROM conv_text_to_varchar_3;
GO
SELECT * FROM cast_text_to_varchar_4;
GO
SELECT * FROM conv_text_to_varchar_4;
GO
SELECT * FROM cast_text_to_varchar_5;
GO
SELECT * FROM conv_text_to_varchar_5;
GO
SELECT * FROM cast_text_to_varchar_6;
GO
SELECT * FROM conv_text_to_varchar_6;
GO

SELECT * FROM cast_text_to_nvarchar_1;
GO
SELECT * FROM conv_text_to_nvarchar_1;
GO
SELECT * FROM cast_text_to_nvarchar_2;
GO
SELECT * FROM conv_text_to_nvarchar_2;
GO
SELECT * FROM cast_text_to_nvarchar_3;
GO
SELECT * FROM conv_text_to_nvarchar_3;
GO
SELECT * FROM cast_text_to_nvarchar_4;
GO
SELECT * FROM conv_text_to_nvarchar_4;
GO
SELECT * FROM cast_text_to_nvarchar_5;
GO
SELECT * FROM conv_text_to_nvarchar_5;
GO
SELECT * FROM cast_text_to_nvarchar_6;
GO
SELECT * FROM conv_text_to_nvarchar_6;
GO

EXEC p_text_to_char_reg;
GO
EXEC p_text_to_char_uni;
GO
EXEC p_text_to_nchar_reg;
GO
EXEC p_text_to_nchar_uni;
GO
EXEC p_text_to_varchar_reg;
GO
EXEC p_text_to_varchar_uni;
GO
EXEC p_text_to_nvarchar_reg;
GO
EXEC p_text_to_nvarchar_uni;
GO

SELECT * FROM f_text_to_char_reg();
GO
SELECT * FROM f_text_to_char_uni();
GO
SELECT * FROM f_text_to_nchar_reg();
GO
SELECT * FROM f_text_to_nchar_uni();
GO
SELECT * FROM f_text_to_varchar_reg();
GO
SELECT * FROM f_text_to_varchar_uni();
GO
SELECT * FROM f_text_to_nvarchar_reg();
GO
SELECT * FROM f_text_to_nvarchar_uni();
GO
