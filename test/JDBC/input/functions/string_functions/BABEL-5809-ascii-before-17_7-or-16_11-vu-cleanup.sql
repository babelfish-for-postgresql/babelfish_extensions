/*
===========================================
BABEL-5809: ASCII Function Testing - Cleanup
===========================================
*/

-- 1. Drop Views
DROP VIEW babel_5809_v2_binary;
GO

DROP VIEW babel_5809_v1_datatypes;
GO

-- 2. Drop Procedures
DROP PROCEDURE babel_5809_sp_validate_string;
GO

DROP PROCEDURE babel_5809_ascii_sp_analyzestring;
GO

DROP PROCEDURE babel_5809_ascii_sp_validateascii;
GO

-- 3. Drop Functions
DROP FUNCTION babel_5809_fn_validate_ascii_range;
GO

DROP FUNCTION babel_5809_fn_ascii_category;
GO

-- 4. Drop Tables
DROP TABLE babel_5809_constrained_ascii;
GO

DROP TABLE babel_5809_computed_ascii;
GO

DROP TABLE babel_5809_t7_edge;
GO

DROP TABLE babel_5809_t6_numeric;
GO

DROP TABLE babel_5809_t5_edge;
GO

DROP TABLE babel_5809_t4_convert;
GO

DROP TABLE babel_5809_t3_hex;
GO

DROP TABLE babel_5809_t2;
GO

DROP TABLE babel_5809_t1;
GO

-- 5. Drop User Defined Types
DROP TYPE babel_5809_type_nvarchar;
GO

DROP TYPE babel_5809_type_nchar;
GO

DROP TYPE babel_5809_type_varchar;
GO

DROP TYPE babel_5809_type_char;
GO
