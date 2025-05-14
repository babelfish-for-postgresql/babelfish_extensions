-- Drop Tables
DROP TABLE IF EXISTS babel_5512_t1;
DROP TABLE IF EXISTS babel_5512_t2;
DROP TABLE IF EXISTS babel_5512_t3;
DROP TABLE IF EXISTS babel_5512_t4;
GO

-- Drop Functions
DROP FUNCTION IF EXISTS babel_5512_f1;
DROP FUNCTION IF EXISTS babel_5512_f2;
GO

-- Drop Procedures
DROP PROCEDURE IF EXISTS babel_5512_p1;
DROP PROCEDURE IF EXISTS babel_5512_p2;
DROP PROCEDURE IF EXISTS babel_5512_p3;
DROP PROCEDURE IF EXISTS babel_5512_p4;
DROP PROCEDURE IF EXISTS babel_5512_p5;
GO

Drop procedure babel_5512_p4_varchar;
GO
drop procedure babel_5512_p4_dec;
GO

-- Drop User-Defined Types
DROP TYPE IF EXISTS SmallMoneyType;
DROP TYPE IF EXISTS MoneyType;
Drop TYPE varcharudt;
Drop type decimaludt;
GO

