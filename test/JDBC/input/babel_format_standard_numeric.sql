-- TINYINT format testing

CREATE TABLE tinyint_testing(ti TINYINT);
GO
INSERT INTO tinyint_testing VALUES(0);
GO
INSERT INTO tinyint_testing VALUES(31);
GO
INSERT INTO tinyint_testing VALUES(255);
GO

SELECT FORMAT(ti, 'C', 'en-us') from tinyint_testing;
GO
SELECT FORMAT(ti, 'C0', 'en-us') from tinyint_testing;
GO

SELECT FORMAT(ti, 'E', 'en-us') from tinyint_testing;
GO
SELECT FORMAT(ti, 'E0', 'en-us') from tinyint_testing;
GO

SELECT FORMAT(ti, 'F', 'en-us') from tinyint_testing;
GO
SELECT FORMAT(ti, 'F0', 'en-us') from tinyint_testing;
GO

SELECT FORMAT(ti, 'G', 'en-us') from tinyint_testing;
GO
SELECT FORMAT(ti, 'G0', 'en-us') from tinyint_testing;
GO

SELECT FORMAT(ti, 'N', 'en-us') from tinyint_testing;
GO
SELECT FORMAT(ti, 'N0', 'en-us') from tinyint_testing;
GO

SELECT FORMAT(ti, 'P', 'en-us') from tinyint_testing;
GO
SELECT FORMAT(ti, 'P0', 'en-us') from tinyint_testing;
GO

SELECT FORMAT(ti, 'X', 'en-us') from tinyint_testing;
GO
SELECT FORMAT(ti, 'X0', 'en-us') from tinyint_testing;
GO

SELECT FORMAT(ti, 'R', 'en-us') from tinyint_testing;
GO


-- SMALLINT format testing

CREATE TABLE smallint_testing(si SMALLINT);
GO
INSERT INTO smallint_testing VALUES(-2456);
GO
INSERT INTO smallint_testing VALUES(-62);
GO
INSERT INTO smallint_testing VALUES(282);
GO
INSERT INTO smallint_testing VALUES(2456);
GO

SELECT FORMAT(si, 'C', 'aa-DJ') from smallint_testing;
GO
SELECT FORMAT(si, 'C6', 'en-us') from smallint_testing;
GO

SELECT FORMAT(si, 'E', 'en-us') from smallint_testing;
GO
SELECT FORMAT(si, 'E6', 'en-us') from smallint_testing;
GO

SELECT FORMAT(si, 'F', 'en-us') from smallint_testing;
GO
SELECT FORMAT(si, 'F6', 'en-us') from smallint_testing;
GO

SELECT FORMAT(si, 'G', 'en-us') from smallint_testing;
GO
SELECT FORMAT(si, 'G6', 'en-us') from smallint_testing;
GO

SELECT FORMAT(si, 'N', 'en-us') from smallint_testing;
GO
SELECT FORMAT(si, 'N6', 'en-us') from smallint_testing;
GO

SELECT FORMAT(si, 'P', 'en-us') from smallint_testing;
GO
SELECT FORMAT(si, 'P6', 'en-us') from smallint_testing;
GO

SELECT FORMAT(si, 'R', 'en-us') from smallint_testing;
GO


-- INT format testing

CREATE TABLE int_testing(it INT);
GO
INSERT INTO int_testing VALUES(-2147483);
GO
INSERT INTO int_testing VALUES(-586);
GO
INSERT INTO int_testing VALUES(7869);
GO
INSERT INTO int_testing VALUES(2147483);
GO

SELECT FORMAT(it, 'C', 'en-us') from int_testing;
GO
SELECT FORMAT(it, 'C6', 'en-us') from int_testing;
GO

SELECT FORMAT(it, 'D', 'en-us') from int_testing;
GO
SELECT FORMAT(it, 'D6', 'en-us') from int_testing;
GO

SELECT FORMAT(it, 'E', 'en-us') from int_testing;
GO
SELECT FORMAT(it, 'E6', 'en-us') from int_testing;
GO

SELECT FORMAT(it, 'F', 'en-us') from int_testing;
GO
SELECT FORMAT(it, 'F6', 'en-us') from int_testing;
GO

SELECT FORMAT(it, 'G', 'en-us') from int_testing;
GO
SELECT FORMAT(it, 'G6', 'en-us') from int_testing;
GO

SELECT FORMAT(it, 'N', 'en-us') from int_testing;
GO
SELECT FORMAT(it, 'N6', 'en-us') from int_testing;
GO

SELECT FORMAT(it, 'P', 'en-us') from int_testing;
GO
SELECT FORMAT(it, 'P6', 'en-us') from int_testing;
GO
SELECT FORMAT(it, 'X', 'en-us') from int_testing;
GO
SELECT FORMAT(it, 'X6', 'en-us') from int_testing;
GO

SELECT FORMAT(it, 'R', 'en-us') from int_testing;
GO


-- BIGINT format testing

CREATE TABLE bigint_testing(bi BIGINT);
GO
INSERT INTO bigint_testing VALUES(-9223372036854);
GO
INSERT INTO bigint_testing VALUES(-352);
GO
INSERT INTO bigint_testing VALUES(2822);
GO
INSERT INTO bigint_testing VALUES(9223372036854);
GO

SELECT FORMAT(bi, 'C', 'en-us') from bigint_testing;
GO
SELECT FORMAT(bi, 'C6', 'en-us') from bigint_testing;
GO

SELECT FORMAT(bi, 'E', 'en-us') from bigint_testing;
GO
SELECT FORMAT(bi, 'E6', 'en-us') from bigint_testing;
GO

SELECT FORMAT(bi, 'F', 'en-us') from bigint_testing;
GO
SELECT FORMAT(bi, 'F6', 'en-us') from bigint_testing;
GO

SELECT FORMAT(bi, 'G6', 'en-us') from bigint_testing;
GO

SELECT FORMAT(bi, 'N', 'en-us') from bigint_testing;
GO
SELECT FORMAT(bi, 'N6', 'en-us') from bigint_testing;
GO

SELECT FORMAT(bi, 'P', 'en-us') from bigint_testing;
GO
SELECT FORMAT(bi, 'P6', 'en-us') from bigint_testing;
GO

SELECT FORMAT(bi, 'X', 'en-us') from bigint_testing;
GO
SELECT FORMAT(bi, 'X6', 'en-us') from bigint_testing;
GO

SELECT FORMAT(bi, 'R', 'en-us') from bigint_testing;
GO


-- DECIMAL format testing

CREATE TABLE decimal_testing(dt DECIMAL(15, 5));
GO
INSERT INTO decimal_testing VALUES(-8999999999.09909);
GO
INSERT INTO decimal_testing VALUES(-352);
GO
INSERT INTO decimal_testing VALUES(5478);
GO
INSERT INTO decimal_testing VALUES(8999999999.99999);
GO

SELECT FORMAT(dt, 'C', 'en-us') from decimal_testing;
GO
SELECT FORMAT(dt, 'C6', 'en-us') from decimal_testing;
GO

SELECT FORMAT(dt, 'E', 'en-us') from decimal_testing;
GO
SELECT FORMAT(dt, 'E6', 'en-us') from decimal_testing;
GO

SELECT FORMAT(dt, 'F', 'en-us') from decimal_testing;
GO
SELECT FORMAT(dt, 'F6', 'en-us') from decimal_testing;
GO

SELECT FORMAT(dt, 'G6', 'en-us') from decimal_testing;
GO

SELECT FORMAT(dt, 'N', 'en-us') from decimal_testing;
GO
SELECT FORMAT(dt, 'N6', 'en-us') from decimal_testing;
GO

SELECT FORMAT(dt, 'P', 'en-us') from decimal_testing;
GO
SELECT FORMAT(dt, 'P6', 'en-us') from decimal_testing;
GO

SELECT FORMAT(dt, 'X', 'en-us') from decimal_testing;
GO
SELECT FORMAT(dt, 'X6', 'en-us') from decimal_testing;
GO

SELECT FORMAT(dt, 'D', 'en-us') from decimal_testing;
GO
SELECT FORMAT(dt, 'D6', 'en-us') from decimal_testing;
GO

SELECT FORMAT(dt, 'R', 'en-us') from decimal_testing;
GO


-- NUMERIC format testing

CREATE TABLE numeric_testing(nt NUMERIC(15, 4));
GO
INSERT INTO numeric_testing VALUES(-8999999999.0990);
GO
INSERT INTO numeric_testing VALUES(-352);
GO
INSERT INTO numeric_testing VALUES(5478);
GO
INSERT INTO numeric_testing VALUES(8999999999.9999);
GO

SELECT FORMAT(nt, 'C', 'en-us') from numeric_testing;
GO
SELECT FORMAT(nt, 'C6', 'en-us') from numeric_testing;
GO

SELECT FORMAT(nt, 'E', 'en-us') from numeric_testing;
GO
SELECT FORMAT(nt, 'E6', 'en-us') from numeric_testing;
GO

SELECT FORMAT(nt, 'F', 'en-us') from numeric_testing;
GO
SELECT FORMAT(nt, 'F6', 'en-us') from numeric_testing;
GO

SELECT FORMAT(nt, 'G', 'en-us') from numeric_testing;
GO
SELECT FORMAT(nt, 'G6', 'en-us') from numeric_testing;
GO

SELECT FORMAT(nt, 'N', 'en-us') from numeric_testing;
GO
SELECT FORMAT(nt, 'N6', 'en-us') from numeric_testing;
GO

SELECT FORMAT(nt, 'P', 'en-us') from numeric_testing;
GO
SELECT FORMAT(nt, 'P6', 'en-us') from numeric_testing;
GO

SELECT FORMAT(nt, 'X', 'en-us') from numeric_testing;
GO
SELECT FORMAT(nt, 'X6', 'en-us') from numeric_testing;
GO

SELECT FORMAT(nt, 'R', 'en-us') from numeric_testing;
GO

SELECT FORMAT(nt, 'D', 'en-us') from numeric_testing;
GO
SELECT FORMAT(nt, 'D6', 'en-us') from numeric_testing;
GO



-- REAL format testing

CREATE TABLE real_testing(rt REAL);
GO
INSERT INTO real_testing VALUES(-3.40E+38);
GO
INSERT INTO real_testing VALUES(-3.312346E+38);
GO
INSERT INTO real_testing VALUES(-3.312341234E+38);
GO
INSERT INTO real_testing VALUES(-22.1234);
GO
INSERT INTO real_testing VALUES(22.1234);
GO
INSERT INTO real_testing VALUES(22.12341234);
GO
INSERT INTO real_testing VALUES(3.312346E+38);
GO
INSERT INTO real_testing VALUES(3.4E+38);
GO

SELECT FORMAT(rt, 'C', 'en-us') from real_testing;
GO
SELECT FORMAT(rt, 'C9', 'en-us') from real_testing;
GO

SELECT FORMAT(rt, 'E', 'en-us') from real_testing;
GO
SELECT FORMAT(rt, 'E9', 'en-us') from real_testing;
GO

SELECT FORMAT(rt, 'G', 'en-us') from real_testing;
GO
SELECT FORMAT(rt, 'G9', 'en-us') from real_testing;
GO


SELECT FORMAT(rt, 'F', 'en-us') from real_testing;
GO
SELECT FORMAT(rt, 'F9', 'en-us') from real_testing;
GO

SELECT FORMAT(rt, 'N', 'en-us') from real_testing;
GO
SELECT FORMAT(rt, 'N9', 'en-us') from real_testing;
GO

SELECT FORMAT(rt, 'P', 'en-us') from real_testing;
GO
SELECT FORMAT(rt, 'P9', 'en-us') from real_testing;
GO

SELECT FORMAT(rt, 'X', 'en-us') from real_testing;
GO
SELECT FORMAT(rt, 'X9', 'en-us') from real_testing;
GO

SELECT FORMAT(rt, 'D', 'en-us') from real_testing;
GO
SELECT FORMAT(rt, 'D9', 'en-us') from real_testing;
GO

-- FLOAT format testing

CREATE TABLE float_testing(ft FLOAT);
GO
INSERT INTO float_testing VALUES(-1.79E+308);
GO
INSERT INTO float_testing VALUES(-3.4E+38);
GO
INSERT INTO float_testing VALUES(35.3675);
GO
INSERT INTO float_testing VALUES(3.4E+38);
GO
INSERT INTO float_testing VALUES(1.79E+308);
GO

SELECT FORMAT(ft, 'C', 'en-us') from float_testing;
GO
SELECT FORMAT(ft, 'C9', 'en-us') from float_testing;
GO

SELECT FORMAT(ft, 'D', 'en-us') from float_testing;
GO
SELECT FORMAT(ft, 'D9', 'en-us') from float_testing;
GO

SELECT FORMAT(ft, 'F', 'en-us') from float_testing;
GO
SELECT FORMAT(ft, 'F9', 'en-us') from float_testing;
GO

SELECT FORMAT(ft, 'N', 'en-us') from float_testing;
GO
SELECT FORMAT(ft, 'N9', 'en-us') from float_testing;
GO

SELECT FORMAT(ft, 'P', 'en-us') from float_testing;
GO
SELECT FORMAT(ft, 'P9', 'en-us') from float_testing;
GO

SELECT FORMAT(ft, 'X', 'en-us') from float_testing;
GO
SELECT FORMAT(ft, 'X9', 'en-us') from float_testing;
GO

SELECT FORMAT(ft, 'G', 'en-us') from float_testing;
GO
SELECT FORMAT(ft, 'G9', 'en-us') from float_testing;
GO

-- SMALLMONEY format testing

CREATE TABLE smallmoney_testing(sm SMALLMONEY);
GO
INSERT INTO smallmoney_testing VALUES(-214478.3648);
GO
INSERT INTO smallmoney_testing VALUES(0.1435);
GO
INSERT INTO smallmoney_testing VALUES(-0.1435);
GO
INSERT INTO smallmoney_testing VALUES(214478.3647);
GO

SELECT FORMAT(sm, 'C', 'en-us') from smallmoney_testing;
GO
SELECT FORMAT(sm, 'C9', 'en-us') from smallmoney_testing;
GO

SELECT FORMAT(sm, 'D', 'en-us') from smallmoney_testing;
GO
SELECT FORMAT(sm, 'D9', 'en-us') from smallmoney_testing;
GO

SELECT FORMAT(sm, 'E', 'en-us') from smallmoney_testing;
GO
SELECT FORMAT(sm, 'E9', 'en-us') from smallmoney_testing;
GO

SELECT FORMAT(sm, 'F', 'en-us') from smallmoney_testing;
GO
SELECT FORMAT(sm, 'F9', 'en-us') from smallmoney_testing;
GO

SELECT FORMAT(sm, 'G', 'en-us') from smallmoney_testing;
GO
SELECT FORMAT(sm, 'G9', 'en-us') from smallmoney_testing;
GO

SELECT FORMAT(sm, 'N', 'en-us') from smallmoney_testing;
GO
SELECT FORMAT(sm, 'N9', 'en-us') from smallmoney_testing;
GO

SELECT FORMAT(sm, 'P', 'en-us') from smallmoney_testing;
GO
SELECT FORMAT(sm, 'P9', 'en-us') from smallmoney_testing;
GO

SELECT FORMAT(sm, 'X', 'en-us') from smallmoney_testing;
GO
SELECT FORMAT(sm, 'X9', 'en-us') from smallmoney_testing;
GO

SELECT FORMAT(sm, 'R', 'en-us') from smallmoney_testing;
GO


-- MONEY format testing

CREATE TABLE money_testing(mt MONEY);
GO
INSERT INTO money_testing VALUES(-92233720.5808);
GO
INSERT INTO money_testing VALUES(-214478.3648);
GO
INSERT INTO money_testing VALUES(435627.1435);
GO
INSERT INTO money_testing VALUES(214478.3647);
GO
INSERT INTO money_testing VALUES(92233720.5807);
GO

SELECT FORMAT(mt, 'C', 'en-us') from money_testing;
GO
SELECT FORMAT(mt, 'C9', 'en-us') from money_testing;
GO

SELECT FORMAT(mt, 'D', 'en-us') from money_testing;
GO
SELECT FORMAT(mt, 'D9', 'en-us') from money_testing;
GO

SELECT FORMAT(mt, 'E', 'en-us') from money_testing;
GO
SELECT FORMAT(mt, 'E9', 'en-us') from money_testing;
GO

SELECT FORMAT(mt, 'F', 'en-us') from money_testing;
GO
SELECT FORMAT(mt, 'F9', 'en-us') from money_testing;
GO

SELECT FORMAT(mt, 'G', 'en-us') from money_testing;
GO
SELECT FORMAT(mt, 'G9', 'en-us') from money_testing;
GO

SELECT FORMAT(mt, 'N', 'en-us') from money_testing;
GO
SELECT FORMAT(mt, 'N9', 'en-us') from money_testing;
GO

SELECT FORMAT(mt, 'P', 'en-us') from money_testing;
GO
SELECT FORMAT(mt, 'P9', 'en-us') from money_testing;
GO

SELECT FORMAT(mt, 'X', 'en-us') from money_testing;
GO
SELECT FORMAT(mt, 'X9', 'en-us') from money_testing;
GO

SELECT FORMAT(mt, 'R', 'en-us') from money_testing;
GO

-- REAL format testing

CREATE TABLE real_testing2(rt REAL);
GO
INSERT INTO real_testing2 VALUES(-3.4E+1);
GO
INSERT INTO real_testing2 VALUES(-34);
GO
INSERT INTO real_testing2 VALUES(-3.312346789E+38);
GO
INSERT INTO real_testing2 VALUES(22.1234565656565E+3);
GO
INSERT INTO real_testing2 VALUES(22.1234123412341234);
GO
INSERT INTO real_testing2 VALUES(3.312346E+38);
GO
INSERT INTO real_testing2 VALUES(3.40E+38);
GO

SELECT FORMAT(rt, 'C', 'en-us') from real_testing2;
GO
SELECT FORMAT(rt, 'C9', 'en-us') from real_testing2;
GO

SELECT FORMAT(rt, 'E', 'en-us') from real_testing2;
GO
SELECT FORMAT(rt, 'E9', 'en-us') from real_testing2;
GO

SELECT FORMAT(rt, 'F', 'en-us') from real_testing2;
GO
SELECT FORMAT(rt, 'F9', 'en-us') from real_testing2;
GO

SELECT FORMAT(rt, 'G', 'en-us') from real_testing2;
GO
SELECT FORMAT(rt, 'G9', 'en-us') from real_testing2;
GO

SELECT FORMAT(rt, 'N', 'en-us') from real_testing2;
GO
SELECT FORMAT(rt, 'N9', 'en-us') from real_testing2;
GO

SELECT FORMAT(rt, 'P', 'en-us') from real_testing2;
GO
SELECT FORMAT(rt, 'P9', 'en-us') from real_testing2;
GO

SELECT FORMAT(rt, 'X', 'en-us') from real_testing2;
GO
SELECT FORMAT(rt, 'X9', 'en-us') from real_testing2;
GO

SELECT FORMAT(rt, 'D', 'en-us') from real_testing2;
GO
SELECT FORMAT(rt, 'D9', 'en-us') from real_testing2;
GO



-- FLOAT format testing

CREATE TABLE float_testing2(ft FLOAT);
GO
INSERT INTO float_testing2 VALUES(-3.312346789123456789E+38);
GO

INSERT INTO float_testing2 VALUES(3.3123489656565789);
GO
INSERT INTO float_testing2 VALUES(3.3123489656565);
GO
INSERT INTO float_testing2 VALUES(3.31234896565651);
GO
INSERT INTO float_testing2 VALUES(3.312348965656512);
GO
INSERT INTO float_testing2 VALUES(3.3123489656565123);
GO
INSERT INTO float_testing2 VALUES(33123489656565123.34);
GO
INSERT INTO float_testing2 VALUES(3.312348965656512345);
GO
INSERT INTO float_testing2 VALUES(3.3123489656565123456);
GO
INSERT INTO float_testing2 VALUES(351234567891025621.1);
GO

SELECT FORMAT(ft, 'C', 'en-us') from float_testing2;
GO
SELECT FORMAT(ft, 'C9', 'en-us') from float_testing2;
GO

SELECT FORMAT(ft, 'D', 'en-us') from float_testing2;
GO
SELECT FORMAT(ft, 'D9', 'en-us') from float_testing2;
GO

SELECT FORMAT(ft, 'E', 'en-us') from float_testing2;
GO
SELECT FORMAT(ft, 'E9', 'en-us') from float_testing2;
GO

SELECT FORMAT(ft, 'F', 'en-us') from float_testing2;
GO
SELECT FORMAT(ft, 'F9', 'en-us') from float_testing2;
GO

SELECT FORMAT(ft, 'N', 'en-us') from float_testing2;
GO
SELECT FORMAT(ft, 'N9', 'en-us') from float_testing2;
GO

SELECT FORMAT(ft, 'P', 'en-us') from float_testing2;
GO
SELECT FORMAT(ft, 'P9', 'en-us') from float_testing2;
GO

SELECT FORMAT(ft, 'X', 'en-us') from float_testing2;
GO
SELECT FORMAT(ft, 'X9', 'en-us') from float_testing2;
GO

SELECT FORMAT(ft, 'G', 'en-us') from float_testing2;
GO
SELECT FORMAT(ft, 'G9', 'en-us') from float_testing2;
GO

SELECT FORMAT(ft, 'R', 'en-us') from float_testing2;
GO

drop table real_testing2;
GO
drop table float_testing2;
GO

drop table smallint_testing;
GO

drop table tinyint_testing;
GO

drop table int_testing;
GO

drop table bigint_testing;
GO

drop table decimal_testing;
GO

drop table numeric_testing;
GO

drop table real_testing;
GO

drop table float_testing;
GO

drop table smallmoney_testing;
GO

drop table money_testing;
GO


