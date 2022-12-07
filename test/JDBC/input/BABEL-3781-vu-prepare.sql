CREATE TABLE BABEL_3781_vu_prepare_t_1(
		a int,
		b float,
		c bigint,
		d smallint,
		e tinyint,
);
GO


INSERT INTO BABEL_3781_vu_prepare_t_1 VALUES (NULL, 10.1234, 3409, 90, NULL);
GO
INSERT INTO BABEL_3781_vu_prepare_t_1 VALUES (1990, NULL, 37272, -340, 58);
GO
INSERT INTO BABEL_3781_vu_prepare_t_1 VALUES (621, 200.1, 64213, NULL, 220);
GO
INSERT INTO BABEL_3781_vu_prepare_t_1 VALUES (333.2, 231.1, NULL, 59, 193);
GO
INSERT INTO BABEL_3781_vu_prepare_t_1 VALUES (201, 210.1, 64213, NULL, 220);
GO
INSERT INTO BABEL_3781_vu_prepare_t_1 VALUES (1310.1234, 0.101, NULL, 84, NULL);
GO
INSERT INTO BABEL_3781_vu_prepare_t_1 VALUES (101, 20.1, 97777, NULL, 80);
GO
INSERT INTO BABEL_3781_vu_prepare_t_1 VALUES (243.2, 451.1, NULL, 904, 80);
GO


CREATE VIEW BABEL_3781_vu_prepare_t_2 AS (SELECT radians(80));
GO

CREATE VIEW BABEL_3781_vu_prepare_t_3 AS (SELECT radians(NULL));
GO

CREATE VIEW BABEL_3781_vu_prepare_t_4 AS (SELECT radians(32738));
GO

CREATE PROCEDURE BABEL_3781_vu_prepare_t_p1 AS (
	SELECT
	 radians(CAST(58 AS TINYINT)),
	 radians(CAST(255 AS TINYINT)),
	 radians(CAST(150 AS TINYINT)),
	 radians(CAST(NULL AS TINYINT))
	);
GO

CREATE PROCEDURE BABEL_3781_vu_prepare_t_p2 AS (
	SELECT
	 radians(CAST(125 AS SMALLINT)),
	 radians(CAST(-32768 AS SMALLINT)),
	 radians(CAST(5680 AS SMALLINT)),
	 radians(CAST(32767 AS SMALLINT))
	);
GO

CREATE PROCEDURE BABEL_3781_vu_prepare_t_p3 AS (
	SELECT
	 radians(CAST(220 AS BIGINT)),
	 radians(CAST(-220 AS BIGINT)),
	 radians(CAST(37272900 AS BIGINT)),
	 radians(CAST(8764210 AS BIGINT)),
	 radians(CAST(NULL AS BIGINT)),
	 radians(CAST(88.6 AS BIGINT))
	);
GO

CREATE PROCEDURE BABEL_3781_vu_prepare_t_p4 AS (
	SELECT
	 radians(CAST(220 AS INT)),
	 radians(CAST(-2147483648 AS INT)),
	 radians(CAST(250 AS INT)),
	 radians(CAST(893 AS INT)),
	 radians(CAST(NULL AS INT))
	);
GO

CREATE VIEW BABEL_3781_vu_prepare_t_v1 AS (
	SELECT
		radians(CAST(80 AS TINYINT)) AS res1,
	 	radians(CAST(58 AS TINYINT)) AS res2,
	 	radians(CAST(255 AS TINYINT)) AS res3,
		radians(CAST(NULL AS TINYINT)) AS res4
	);
GO

CREATE VIEW BABEL_3781_vu_prepare_t_v2 AS (
	SELECT
	 radians(CAST(904 AS SMALLINT)) AS res1,
	 radians(CAST(-100 AS SMALLINT)) AS res2,
	 radians(CAST(5680 AS SMALLINT)) AS res3,
	 radians(CAST(32767 AS SMALLINT)) AS res4
	);
GO

CREATE VIEW BABEL_3781_vu_prepare_t_v3 AS (
	SELECT
	 radians(CAST(210 AS BIGINT)) AS res1,
	 radians(CAST(-190 AS BIGINT)) AS res2,
	 radians(CAST(37272900 AS BIGINT)) AS res3,
	 radians(CAST(8764210 AS BIGINT)) AS res4,
	 radians(CAST(NULL AS BIGINT)) AS res5,
	 radians(CAST(88.6 AS BIGINT)) AS res6
	);
GO

CREATE VIEW BABEL_3781_vu_prepare_t_v4 AS (
	SELECT
	 radians(CAST(1220 AS INT)) AS res1,
	 radians(CAST(-1210 AS INT)) AS res2,
	 radians(CAST(2250 AS INT)) AS res3,
	 radians(CAST(893 AS INT)) AS res4,
	 radians(CAST(NULL AS INT))
	);
GO