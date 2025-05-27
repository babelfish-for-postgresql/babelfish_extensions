-- Drop Views first (dependent on tables)
DROP VIEW babel_5512_upgrade_v1;
DROP VIEW babel_5512_upgrade_v2;
DROP VIEW babel_5512_upgrade_v3;
DROP VIEW babel_5512_upgrade_v6;
DROP VIEW babel_5512_upgrade_v7;
DROP VIEW babel_5512_upgrade_v8;
DROP VIEW babel_5512_upgrade_v9;
DROP VIEW babel_5512_upgrade_v10;
GO

-- Drop Indexes
DROP INDEX babel_5512_upgrade_idx1 ON babel_5512_upgrade_t3;
GO

-- Drop Functions (ITVF, MSTVF, and regular functions)
DROP FUNCTION babel_5512_upgrade_f1;
DROP FUNCTION babel_5512_upgrade_f2;
DROP FUNCTION babel_5512_upgrade_f3;
DROP FUNCTION babel_5512_upgrade_f4;
DROP FUNCTION babel_5512_upgrade_f5;
DROP FUNCTION babel_5512_upgrade_f6;
DROP FUNCTION babel_5512_upgrade_f7;
DROP FUNCTION babel_5512_upgrade_f8;
DROP FUNCTION babel_5512_upgrade_f9;
DROP FUNCTION babel_5512_upgrade_f10;
DROP FUNCTION babel_5512_upgrade_itvf1;
DROP FUNCTION babel_5512_upgrade_itvf2;
DROP FUNCTION babel_5512_upgrade_mstvf1;
DROP FUNCTION babel_5512_upgrade_mstvf2;
GO

-- Drop Procedures
DROP PROCEDURE babel_5512_upgrade_p1;
DROP PROCEDURE babel_5512_upgrade_p2;
DROP PROCEDURE babel_5512_upgrade_p3;
DROP PROCEDURE babel_5512_upgrade_p4;
DROP PROCEDURE babel_5512_upgrade_p5;
DROP PROCEDURE babel_5512_upgrade_p6;
DROP PROCEDURE babel_5512_upgrade_p7;
DROP PROCEDURE babel_5512_upgrade_p8;
DROP PROCEDURE babel_5512_upgrade_p9;
DROP PROCEDURE babel_5512_get_column_info_p10;
DROP PROCEDURE babel_5512_upgrade_p10;
DROP PROCEDURE babel_5512_upgrade_p11;
GO

-- Drop Tables
DROP TABLE babel_5512_upgrade_t1;
DROP TABLE babel_5512_upgrade_t2;
DROP TABLE babel_5512_upgrade_t3;
DROP TABLE babel_5512_upgrade_t5;
DROP TABLE babel_5512_upgrade_t9;
DROP TABLE babel_5512_upgrade_t10;
DROP TABLE babel_5512_upgrade_t11;
GO

-- Drop User-Defined Types (drop last as they might be used by other objects)
DROP TYPE babel_5512_upgrade_type1;
DROP TYPE babel_5512_upgrade_type2;
GO

