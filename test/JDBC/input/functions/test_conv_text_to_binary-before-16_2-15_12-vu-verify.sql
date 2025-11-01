SELECT * FROM cast_text_to_varbinary_1;
GO
SELECT * FROM conv_text_to_varbinary_1;
GO
SELECT * FROM cast_text_to_varbinary_2;
GO
SELECT * FROM conv_text_to_varbinary_2;
GO

SELECT * FROM cast_text_to_binary_1;
GO
SELECT * FROM conv_text_to_binary_1;
GO
SELECT * FROM cast_text_to_binary_2;
GO
SELECT * FROM conv_text_to_binary_2;
GO

EXEC p_text_to_varbinary_reg;
GO
EXEC p_text_to_varbinary_uni;
GO
EXEC p_text_to_binary_reg;
GO
EXEC p_text_to_binary_uni;
GO

SELECT * FROM f_text_to_varbinary_reg();
GO
SELECT * FROM f_text_to_varbinary_uni();
GO
SELECT * FROM f_text_to_binary_reg();
GO
SELECT * FROM f_text_to_binary_uni();
GO

SELECT * FROM cast_text_to_varbinary_hw_1;
GO
SELECT * FROM conv_text_to_varbinary_hw_1;
GO
SELECT * FROM cast_text_to_varbinary_hw_2;
GO
SELECT * FROM conv_text_to_varbinary_hw_2;
GO
SELECT * FROM cast_text_to_binary_hw_1;
GO
SELECT * FROM conv_text_to_binary_hw_1;
GO
SELECT * FROM cast_text_to_binary_hw_2;
GO
SELECT * FROM conv_text_to_binary_hw_2;
GO

EXEC p_text_to_varbinary_reg_hw;
GO
EXEC p_text_to_varbinary_uni_hw;
GO
EXEC p_text_to_binary_reg_hw;
GO
EXEC p_text_to_binary_uni_hw;
GO

SELECT * FROM f_text_to_varbinary_reg_hw();
GO
SELECT * FROM f_text_to_varbinary_uni_hw();
GO
SELECT * FROM f_text_to_binary_reg_hw();
GO
SELECT * FROM f_text_to_binary_uni_hw();
GO
