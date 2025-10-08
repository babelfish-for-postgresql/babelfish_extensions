SELECT * FROM test_str_bin_conversion.v_varbinary_cast ORDER BY id;
GO

SELECT * FROM test_str_bin_conversion.v_binary_cast ORDER BY id;
GO

EXEC test_str_bin_conversion.p_varbinary_try_cast;
GO

EXEC test_str_bin_conversion.p_binary_try_cast;
GO

SELECT * FROM test_str_bin_conversion.v_varbinary_convert ORDER BY id;
GO

SELECT * FROM test_str_bin_conversion.v_binary_convert ORDER BY id;
GO

EXEC test_str_bin_conversion.p_varbinary_try_convert;
GO

EXEC test_str_bin_conversion.p_binary_try_convert;
GO

SELECT * FROM test_str_bin_conversion.f_s2vb_nvarchar_emoji();
GO

SELECT * FROM test_str_bin_conversion.f_s2vb_char13_spaces();
GO

SELECT * FROM test_str_bin_conversion.f_s2bin_nchar13_bin32();
GO

SELECT * FROM test_str_bin_conversion.f_s2bin_varchar_overflow8();
GO

SELECT * FROM test_str_bin_conversion.f_s2bin_nvarchar_overflow3();
GO

SELECT * FROM test_str_bin_conversion.f_s2bin_try_compare();
GO
