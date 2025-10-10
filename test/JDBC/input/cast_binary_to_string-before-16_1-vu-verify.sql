SELECT * FROM test_bin_str_conversion.v_utf8_cast ORDER BY id;
GO

EXEC test_bin_str_conversion.p_utf16_cast;
GO

SELECT * FROM test_bin_str_conversion.v_utf8_try_cast ORDER BY id;
GO

EXEC test_bin_str_conversion.p_utf16_try_cast;
GO

SELECT * FROM test_bin_str_conversion.v_utf8_convert ORDER BY id;
GO

EXEC test_bin_str_conversion.p_utf16_convert;
GO

SELECT * FROM test_bin_str_conversion.v_utf8_try_convert ORDER BY id;
GO

EXEC test_bin_str_conversion.p_utf16_try_convert;
GO

SELECT * FROM test_bin_str_conversion.f_case_char6();
GO

SELECT * FROM test_bin_str_conversion.f_case_varchar6();
GO

SELECT * FROM test_bin_str_conversion.f_edge_truncation_char2();
GO

SELECT * FROM test_bin_str_conversion.f_edge_ascii_char5();
GO

SELECT * FROM test_bin_str_conversion.f_edge_mixed_char5();
GO

SELECT * FROM test_bin_str_conversion.f_edge_empty_char3();
GO

SELECT * FROM test_bin_str_conversion.f_perf_large_char10();
GO
