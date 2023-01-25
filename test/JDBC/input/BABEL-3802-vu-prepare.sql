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
        power(CAST(896932 AS BIGINT),1.2)
    );
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p2 AS (
    SELECT
        power(CAST(-2147483648 AS INT),1),
        power(CAST(2147483647 AS INT),1),
        power(CAST(NULL AS INT),1),
        power(CAST(8969.32 AS INT),1),
        power(CAST(896932 AS INT),1.1),
        power(CAST(896932 AS INT),1.2)
    );
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p3 AS (
    SELECT
        power(CAST(-32768 AS SMALLINT),1),
        power(CAST(32767 AS SMALLINT),1),
        power(CAST(NULL AS SMALLINT),1),
        power(CAST(8969.32 AS SMALLINT),1),
        power(CAST(8962 AS SMALLINT),1.1),
        power(CAST(8962 AS SMALLINT),1.2)
    );
GO

CREATE PROCEDURE BABEL_3802_vu_prepare_t_p4 AS (
    SELECT
        power(CAST(0 AS TINYINT),1),
        power(CAST(255 AS TINYINT),1),
        power(CAST(NULL AS TINYINT),1),
        power(CAST(100.32 AS TINYINT),1),
        power(CAST(100 AS TINYINT),1.1),
        power(CAST(100 AS TINYINT),1.2)
    );
GO


----Trigger BigInt Error
CREATE PROCEDURE BABEL_3802_vu_prepare_t_p5 AS (SELECT power(CAST(-9223372036854775808 AS BIGINT),2));
GO

----Trigger Int Error
CREATE PROCEDURE BABEL_3802_vu_prepare_t_p6 AS SELECT power(CAST(-2147483648 AS INT),2)
GO

----Trigger SmallInt Error
CREATE PROCEDURE BABEL_3802_vu_prepare_t_p7 AS SELECT power(CAST(-32768 AS SMALLINT),3)
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
        power(CAST(896932 AS BIGINT),1.2) AS res6
    );
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v2 AS (
    SELECT
        power(CAST(-2147483648 AS INT),1) AS res1,
        power(CAST(2147483647 AS INT),1) AS res2,
        power(CAST(NULL AS INT),1) AS res3,
        power(CAST(8969.32 AS INT),1) AS res4,
        power(CAST(896932 AS INT),1.1) AS res5,
        power(CAST(896932 AS INT),1.2) AS res6
    );
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v3 AS (
    SELECT
        power(CAST(-32768 AS SMALLINT),1) AS res1,
        power(CAST(32767 AS SMALLINT),1) AS res2,
        power(CAST(NULL AS SMALLINT),1) AS res3,
        power(CAST(899.32 AS SMALLINT),1) AS res4,
        power(CAST(8962 AS SMALLINT),1.1) AS res5,
        power(CAST(896 AS SMALLINT),1.2) AS res6
    );
GO

CREATE VIEW BABEL_3802_vu_prepare_t_v4 AS (
    SELECT
        power(CAST(0 AS TINYINT),1) AS res1,
        power(CAST(255 AS TINYINT),1) AS res2,
        power(CAST(NULL AS TINYINT),1) AS res3,
        power(CAST(89.32 AS TINYINT),1) AS res4,
        power(CAST(100 AS TINYINT),1.1) AS res5,
        power(CAST(100 AS TINYINT),1.2) AS res6
    );
GO