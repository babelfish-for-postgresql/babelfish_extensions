CREATE TABLE BABEL_3802_vu_prepare_t_1(
		a int,
		b numeric,
		c bigint,
		d smallint,
		e tinyint,
);
GO

INSERT INTO BABEL_3802_vu_prepare_t_1 VALUES (NULL,1, NULL, NULL, NULL);
GO
INSERT INTO BABEL_3802_vu_prepare_t_1 VALUES (2147483647, 1.1, 9223372036854, 32767, 255);
GO
INSERT INTO BABEL_3802_vu_prepare_t_1 VALUES (-2147483648, 1,-9223372036854775808, -32768, 0);
GO
INSERT INTO BABEL_3802_vu_prepare_t_1 VALUES (101.23, 1, 97777.32, 376.466, 120.32);
GO


CREATE VIEW BABEL_3802_vu_prepare_t_2 AS (SELECT (power(80,2)));
GO

CREATE VIEW BABEL_3802_vu_prepare_t_3 AS (SELECT (power(NULL,2)));
GO

CREATE VIEW BABEL_3802_vu_prepare_t_4 AS (SELECT (power(24124,2)));
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p1 AS (
    SELECT
        power(CAST(-9223372036854775808 AS BIGINT),1),
        power(CAST(9223372036854 AS BIGINT),1),
        power(CAST(NULL AS BIGINT),1),
        power(CAST(8969.32 AS BIGINT),1),
        power(CAST(896932 AS BIGINT),1.1),
        power(CAST(896932 AS BIGINT),1.2),
        power(CAST(NULL AS BIGINT),NULL),
        power(CAST(896932 AS BIGINT),NULL),
        power(CAST(2 AS BIGINT), -1),
        power(CAST(0 AS BIGINT),0),
        power(CAST(-2 AS BIGINT),-1),
        power(CAST(2 AS BIGINT),-0.2),
        power(CAST(-922 AS BIGINT),NULL),
        power(CAST(-922 AS BIGINT),0),
        power(CAST(NULL AS BIGINT),-100),
        power(CAST(NULL AS BIGINT),0),
        power(CAST(-8969.32 AS BIGINT),1)
    );
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p2 AS (
    SELECT
        power(CAST(-2147483648 AS INT),1),
        power(CAST(2147483647 AS INT),1),
        power(CAST(NULL AS INT),1),
        power(CAST(8969.32 AS INT),1),
        power(CAST(896932 AS INT),1.1),
        power(CAST(896932 AS INT),1.2),
        power(CAST(NULL as INT),NULL),
        power(CAST(8963 as INT),NULL),
        power(CAST(2 AS INT), -1),
        power(CAST(0 AS INT),0),
        power(CAST(-2 AS INT),-1),
        power(CAST(2 AS INT),-0.2),
        power(CAST(-922 AS INT),NULL),
        power(CAST(-922 AS INT),0),
        power(CAST(NULL AS INT),-10),
        power(CAST(NULL AS INT),0),
        power(CAST(-8969.32 AS INT),1)
    );
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p3 AS (
    SELECT
        power(CAST(-32768 AS SMALLINT),1),
        power(CAST(32767 AS SMALLINT),1),
        power(CAST(NULL AS SMALLINT),1),
        power(CAST(8969.32 AS SMALLINT),1),
        power(CAST(8962 AS SMALLINT),1.1),
        power(CAST(8962 AS SMALLINT),1.2),
        power(CAST(NULL AS SMALLINT),NULL),
        power(CAST(8962 AS SMALLINT),NULL),
        power(CAST(100 AS SMALLINT),3),
        power(CAST(2 AS SMALLINT), -1),
        power(CAST(0 AS SMALLINT),0),
        power(CAST(-2 AS SMALLINT),-1),
        power(CAST(2 AS SMALLINT),-0.2),
        power(CAST(-922 AS SMALLINT),NULL),
        power(CAST(-922 AS SMALLINT),0),
        power(CAST(NULL AS SMALLINT),-10),
        power(CAST(NULL AS SMALLINT),0),
        power(CAST(-8969.32 AS SMALLINT),1)
    );
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p4 AS (
    SELECT
        power(CAST(0 AS TINYINT),1),
        power(CAST(255 AS TINYINT),1),
        power(CAST(NULL AS TINYINT),1),
        power(CAST(100.32 AS TINYINT),1),
        power(CAST(100 AS TINYINT),1.1),
        power(CAST(100 AS TINYINT),1.2),
        power(CAST(NULL AS TINYINT),NULL),
        power(CAST(100 AS TINYINT),NULL),
        power(CAST(100 AS TINYINT),3),
        power(CAST(2 AS TINYINT), -1),
        power(CAST(0 AS TINYINT),0),
        power(CAST(2 AS TINYINT),-0.2),
        power(CAST(NULL AS TINYINT),-10),
        power(CAST(NULL AS TINYINT),0)
    );
GO


----Trigger BigInt Error
CREATE PROCEDURE BABEL_3802_vu_prepare_t_p5 AS (SELECT power(CAST(-9223372036854775808 AS BIGINT),2));
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p8 AS (SELECT power(CAST(9223372036854775807 AS BIGINT),2));
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p9 AS (SELECT power(CAST(9223372036854775808 AS BIGINT),1));
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p10 AS (SELECT power(CAST(-9223372036854775809 AS BIGINT),1));
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p11 AS (SELECT power(CAST(-922337203685477580 AS BIGINT),1.1));
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p12 AS (SELECT power(CAST(-922337203685477580 AS BIGINT),-1.1));
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p13 AS (SELECT power(CAST(0 AS BIGINT),-1));
GO

----Trigger Int Error
CREATE PROCEDURE BABEL_3802_vu_prepare_t_p6 AS SELECT power(CAST(-2147483648 AS INT),2)
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p14 AS SELECT power(CAST(2147483648 AS INT),1)
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p15 AS SELECT power(CAST(-2147483649 AS INT),1)
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p16 AS SELECT power(CAST(2147483647 AS INT),2)
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p17 AS SELECT power(CAST(-214748364 AS INT),1.1)
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p18 AS SELECT power(CAST(-214748364 AS INT),-1.1)
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p19 AS SELECT power(CAST(0 AS INT),-1)
GO

----Trigger SmallInt Error
CREATE PROCEDURE BABEL_3802_vu_prepare_t_p7 AS SELECT power(CAST(-32768 AS SMALLINT),3)
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p20 AS SELECT power(CAST(32768 AS SMALLINT),1)
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p21 AS SELECT power(CAST(32767 AS SMALLINT),4)
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p22 AS SELECT power(CAST(-32769 AS SMALLINT),1)
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p23 AS SELECT power(CAST(-3276 AS SMALLINT),1.1)
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p24 AS SELECT power(CAST(-3276 AS SMALLINT),-1.1)
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p25 AS SELECT power(CAST(0 AS SMALLINT),-1)
GO

---Trigger TinyInt Error

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p26 AS SELECT power(CAST(-1 AS TINYINT),1)
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p27 AS SELECT power(CAST(255 AS TINYINT),5)
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p28 AS SELECT power(CAST(256 AS TINYINT),1)
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p29 AS SELECT power(CAST(0 AS TINYINT),-1)
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v8 AS SELECT power(CAST(1 AS TINYINT),1.1)
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v1 AS (
    SELECT
        power(CAST(-9223372036854775808 AS BIGINT),1) AS res1,
        power(CAST(9223372036854 AS BIGINT),1) AS res2,
        power(CAST(NULL AS BIGINT),1) AS res3,
        power(CAST(8969.32 AS BIGINT),1) AS res4,
        power(CAST(896932 AS BIGINT),1.1) AS res5,
        power(CAST(896932 AS BIGINT),1.2) AS res6,
        power(CAST(NULL AS BIGINT),NULL) AS res7,
        power(CAST(896932 AS BIGINT),NULL) AS res8,
        power(CAST(2 AS BIGINT), -1) AS res9,
        power(CAST(0 AS BIGINT),0) AS res10,
        power(CAST(-2 AS BIGINT),-1) AS res11,
        power(CAST(2 AS BIGINT),-0.2) AS res12,
        power(CAST(-922 AS BIGINT),NULL) AS res13,
        power(CAST(-922 AS BIGINT),0) AS res14,
        power(CAST(NULL AS BIGINT),-100) AS res15,
        power(CAST(NULL AS BIGINT),0) AS res16,
        power(CAST(-8969.32 AS BIGINT),1) AS res17
    );
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v2 AS (
    SELECT
        power(CAST(-2147483648 AS INT),1) AS res1,
        power(CAST(2147483647 AS INT),1) AS res2,
        power(CAST(NULL AS INT),1) AS res3,
        power(CAST(8969.32 AS INT),1) AS res4,
        power(CAST(896932 AS INT),1.1) AS res5,
        power(CAST(896932 AS INT),1.2) AS res6,
        power(CAST(NULL as INT),NULL) AS res7,
        power(CAST(8963 as INT),NULL) AS res8,
        power(CAST(2 AS INT), -1) AS res9,
        power(CAST(0 AS INT),0) AS res10,
        power(CAST(-2 AS INT),-1) AS res11,
        power(CAST(2 AS INT),-0.2) AS res12,
        power(CAST(-922 AS INT),NULL) AS res13,
        power(CAST(-922 AS INT),0) AS res14,
        power(CAST(NULL AS INT),-10) AS res15,
        power(CAST(NULL AS INT),0) AS res16,
        power(CAST(-8969.32 AS INT),1) AS res17
    );
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v3 AS (
    SELECT
        power(CAST(-32768 AS SMALLINT),1) AS res1,
        power(CAST(32767 AS SMALLINT),1) AS res2,
        power(CAST(NULL AS SMALLINT),1) AS res3,
        power(CAST(899.32 AS SMALLINT),1) AS res4,
        power(CAST(8962 AS SMALLINT),1.1) AS res5,
        power(CAST(896 AS SMALLINT),1.2) AS res6,
        power(CAST(NULL AS SMALLINT),NULL) AS res7,
        power(CAST(8962 AS SMALLINT),NULL) AS res8,
        power(CAST(100 AS SMALLINT),3) AS res9,
        power(CAST(2 AS SMALLINT), -1) AS res10,
        power(CAST(0 AS SMALLINT),0) AS res11,
        power(CAST(-2 AS SMALLINT),-1)AS res12,
        power(CAST(2 AS SMALLINT),-0.2) AS res13,
        power(CAST(-922 AS SMALLINT),NULL) AS res14,
        power(CAST(-922 AS SMALLINT),0) AS res15,
        power(CAST(NULL AS SMALLINT),-10) AS res16,
        power(CAST(NULL AS SMALLINT),0) AS res17,
        power(CAST(-8969.32 AS SMALLINT),1) AS res18
    );
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v4 AS (
    SELECT
        power(CAST(0 AS TINYINT),1) AS res1,
        power(CAST(255 AS TINYINT),1) AS res2,
        power(CAST(NULL AS TINYINT),1) AS res3,
        power(CAST(89.32 AS TINYINT),1) AS res4,
        power(CAST(100 AS TINYINT),1.1) AS res5,
        power(CAST(100 AS TINYINT),1.2) AS res6,
        power(CAST(NULL AS TINYINT),NULL) AS res7,
        power(CAST(100 AS TINYINT),NULL) AS res8,
        power(CAST(100 AS TINYINT),3) AS res9,
        power(CAST(2 AS TINYINT), -1) AS res10,
        power(CAST(0 AS TINYINT),0) AS res11,
        power(CAST(2 AS TINYINT),-0.2) AS res12,
        power(CAST(NULL AS TINYINT),-10) AS res13,
        power(CAST(NULL AS TINYINT),0) AS res14
    );
GO

--Trigger BigInt Error

CREATE VIEW BABEL_3802_vu_prepare_t_v5 AS ( SELECT power(CAST(-9223372036854775808 AS BIGINT),2) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v6 AS ( SELECT power(CAST(9223372036854775807 AS BIGINT),2) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v7 AS ( SELECT power(CAST(9223372036854775808 AS BIGINT),1) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v9 AS ( SELECT power(CAST(-9223372036854775809 AS BIGINT),1) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v10 AS (SELECT power(CAST(-922337203685477580 AS BIGINT),1.1) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v11 AS (SELECT power(CAST(-922337203685477580 AS BIGINT),-1.1) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v12 AS (SELECT power(CAST(0 AS BIGINT),-1) AS res1);
GO

--Trigger Int Error
CREATE VIEW BABEL_3802_vu_prepare_t_v13 AS ( SELECT power(CAST(-2147483648 AS INT),2) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v14 AS ( SELECT power(CAST(2147483648 AS INT),1) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v15 AS ( SELECT power(CAST(-2147483649 AS INT),1) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v16 AS ( SELECT power(CAST(2147483647 AS INT),2) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v17 AS ( SELECT power(CAST(-214748364 AS INT),1.1) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v18 AS ( SELECT power(CAST(-214748364 AS INT),-1.1) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v19 AS ( SELECT power(CAST(0 AS INT),-1) AS res1);
GO

--Trigger Small Int Error
CREATE VIEW BABEL_3802_vu_prepare_t_v20 AS ( SELECT power(CAST(-32768 AS SMALLINT),3) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v21 AS ( SELECT power(CAST(32768 AS SMALLINT),1) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v22 AS ( SELECT power(CAST(32767 AS SMALLINT),4) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v23 AS ( SELECT power(CAST(-32769 AS SMALLINT),1) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v24 AS ( SELECT power(CAST(-3276 AS SMALLINT),1.1) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v25 AS ( SELECT power(CAST(-3276 AS SMALLINT),-1.1) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v26 AS ( SELECT power(CAST(0 AS SMALLINT),-1) AS res1);
GO


--Trigger Tiny Int Error
CREATE VIEW BABEL_3802_vu_prepare_t_v27 AS ( SELECT power(CAST(-1 AS TINYINT),1) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v28 AS ( SELECT power(CAST(255 AS TINYINT),5) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v29 AS ( SELECT power(CAST(256 AS TINYINT),1) AS res1);
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v30 AS ( SELECT power(CAST(0 AS TINYINT),-1) AS res1);
GO
