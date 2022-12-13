CREATE TABLE BABEL_3747_vu_prepare_t_1(
	 	a int,
	 	b float,
	 	c bigint,
	 	d smallint,
	 	e tinyint,
	);
GO
	 
	 
INSERT INTO BABEL_3747_vu_prepare_t_1 VALUES (NULL, NULL, NULL, NULL, NULL);
GO
INSERT INTO BABEL_3747_vu_prepare_t_1 VALUES (21474835, 1.79E+38, 92233720368547749, 32767, 255);	
GO
INSERT INTO BABEL_3747_vu_prepare_t_1 VALUES (-21474836, - 1.79E+38,-92233720368547750, -32768, 0);
GO
INSERT INTO BABEL_3747_vu_prepare_t_1 VALUES (101.23, 20.1, 97777.32, 376.466, 120.32);
GO
	 
	 
CREATE VIEW BABEL_3747_vu_prepare_t_2 AS (SELECT degrees(80));
GO
	 
CREATE VIEW BABEL_3747_vu_prepare_t_3 AS (SELECT degrees(NULL));
GO
	 
CREATE VIEW BABEL_3747_vu_prepare_t_4 AS (SELECT degrees(32738));
GO
	 
CREATE PROCEDURE BABEL_3747_vu_prepare_t_p1 AS (
	SELECT
		degrees(CAST(-92233720368547750 AS BIGINT)),
		degrees(CAST(92233720368547749 AS BIGINT)),
		degrees(CAST(NULL AS BIGINT)),
		degrees(CAST(8969.32 AS BIGINT))
	);
GO
	 
CREATE PROCEDURE BABEL_3747_vu_prepare_t_p2 AS (
	SELECT
		degrees(CAST(-21474836 AS INT)),
		degrees(CAST(21474835 AS INT)),
		degrees(CAST(NULL AS INT)),
		degrees(CAST(8969.32 AS INT))
	);
GO
	 
CREATE PROCEDURE BABEL_3747_vu_prepare_t_p3 AS (
	SELECT
	 	degrees(CAST(-32768 AS SMALLINT)),
	 	degrees(CAST(32767 AS SMALLINT)),
	 	degrees(CAST(NULL AS SMALLINT)),
	 	degrees(CAST(8969.32 AS SMALLINT))
	);
GO
	 
CREATE PROCEDURE BABEL_3747_vu_prepare_t_p4 AS (
	SELECT
	 	degrees(CAST(0 AS TINYINT)),
	 	degrees(CAST(255 AS TINYINT)),
	 	degrees(CAST(NULL AS TINYINT)),
	 	degrees(CAST(100.32 AS TINYINT))
	);
GO
	 
CREATE VIEW BABEL_3747_vu_prepare_t_v1 AS (
	SELECT
	 	degrees(CAST(-92233720368547750 AS BIGINT)) AS res1,
	 	degrees(CAST(92233720368547749 AS BIGINT)) AS res2,
	 	degrees(CAST(NULL AS BIGINT)) AS res3,
	 	degrees(CAST(8969.32 AS BIGINT)) AS res4
	);
GO
	 
CREATE VIEW BABEL_3747_vu_prepare_t_v2 AS (
	SELECT
	 	degrees(CAST(-21474836 AS INT)) AS res1,
	 	degrees(CAST(21474835 AS INT)) AS res2,
	 	degrees(CAST(NULL AS INT)) AS res3,
	 	degrees(CAST(8969.32 AS INT)) AS res4
	);
GO
	 
CREATE VIEW BABEL_3747_vu_prepare_t_v3 AS (
	SELECT
	 	degrees(CAST(-32768 AS SMALLINT)) AS res1,
	 	degrees(CAST(32767 AS SMALLINT)) AS res2,
	 	degrees(CAST(NULL AS SMALLINT)) AS res3,
	 	degrees(CAST(899.32 AS SMALLINT)) AS res4
	);
GO
	 
CREATE VIEW BABEL_3747_vu_prepare_t_v4 AS (
	SELECT
	 	degrees(CAST(0 AS TINYINT)) AS res1,
	 	degrees(CAST(255 AS TINYINT)) AS res2,
	 	degrees(CAST(NULL AS TINYINT)) AS res3,
	 	degrees(CAST(89.32 AS TINYINT)) AS res4
	);
=======
		a int,
		b float,
		c bigint,
		d smallint,
		e tinyint,
);
GO


INSERT INTO BABEL_3747_vu_prepare_t_1 VALUES (NULL, 10.1234, 10, 20, NULL);
GO
INSERT INTO BABEL_3747_vu_prepare_t_1 VALUES (1990, NULL, 37272, -10, 1);
GO
INSERT INTO BABEL_3747_vu_prepare_t_1 VALUES (61, 20.1, 64213, NULL, 20);
GO
INSERT INTO BABEL_3747_vu_prepare_t_1 VALUES (3.2, 1.1, NULL, 8, 43);
GO
INSERT INTO BABEL_3747_vu_prepare_t_1 VALUES (201, 20.1, 64213, NULL, 20);
GO
INSERT INTO BABEL_3747_vu_prepare_t_1 VALUES (1310.1234, 0.101, NULL, 3984, NULL);
GO
INSERT INTO BABEL_3747_vu_prepare_t_1 VALUES (101, 20.1, 97777, NULL, 20);
GO
INSERT INTO BABEL_3747_vu_prepare_t_1 VALUES (3.2, 1.1, NULL, 904, 50);
GO




CREATE VIEW BABEL_3747_vu_prepare_t_2 AS (SELECT degrees(10));
GO

CREATE VIEW BABEL_3747_vu_prepare_t_3 AS (SELECT degrees(NULL));
GO

CREATE VIEW BABEL_3747_vu_prepare_t_4 AS (SELECT degrees(9999*9999));
GO

CREATE PROCEDURE BABEL_3747_vu_prepare_t_p1 AS (
	SELECT
	 degrees(CAST(1 AS TINYINT)),
	 degrees(CAST(4 AS TINYINT)),
	 degrees(CAST(255 AS TINYINT)),
	 degrees(CAST(NULL AS TINYINT))
	 );
GO

CREATE PROCEDURE BABEL_3747_vu_prepare_t_p2 AS (
	SELECT
	 degrees(CAST(10 AS SMALLINT)),
	 degrees(CAST(-10 AS SMALLINT)),
	 degrees(CAST(5680 AS SMALLINT)),
	 degrees(CAST(32767 AS SMALLINT))
	 );
GO

CREATE PROCEDURE BABEL_3747_vu_prepare_t_p3 AS (
	SELECT
	 degrees(CAST(10 AS BIGINT)),
	 degrees(CAST(-10 AS BIGINT)),
	 degrees(CAST(37272900 AS BIGINT)),
	 degrees(CAST(8764210 AS BIGINT)),
	 degrees(CAST(NULL AS BIGINT)),
	 degrees(CAST(88.6 AS BIGINT))
	 );
GO

CREATE PROCEDURE BABEL_3747_vu_prepare_t_p4 AS (
	SELECT
	 degrees(CAST(10 AS INT)),
	 degrees(CAST(-10 AS INT)),
	 degrees(CAST(250 AS INT)),
	 degrees(CAST(893 AS INT)),
	 degrees(CAST(NULL AS INT))
	 );
GO

----Trigger Bigint error
CREATE PROCEDURE BABEL_3747_vu_prepare_t_p5 AS (SELECT degrees(CAST(9223372036854775807 AS BIGINT)));
GO

----Trigger Int error
CREATE PROCEDURE BABEL_3747_vu_prepare_t_p6 AS (SELECT degrees(CAST(9999*9999 AS INT)));
GO

CREATE VIEW BABEL_3747_vu_prepare_t_v1 AS (
	SELECT
		degrees(CAST(1 AS TINYINT)) AS res1,
	 	degrees(CAST(4 AS TINYINT)) AS res2,
	 	degrees(CAST(255 AS TINYINT)) AS res3,
		degrees(CAST(NULL AS TINYINT)) AS res4
	);
GO

CREATE VIEW BABEL_3747_vu_prepare_t_v2 AS (
	SELECT
	 degrees(CAST(10 AS SMALLINT)) AS res1,
	 degrees(CAST(-10 AS SMALLINT)) AS res2,
	 degrees(CAST(5680 AS SMALLINT)) AS res3,
	 degrees(CAST(32767 AS SMALLINT)) AS res4
	 );
GO

CREATE VIEW BABEL_3747_vu_prepare_t_v3 AS (
	SELECT
	 degrees(CAST(10 AS BIGINT)) AS res1,
	 degrees(CAST(-10 AS BIGINT)) AS res2,
	 degrees(CAST(37272900 AS BIGINT)) AS res3,
	 degrees(CAST(8764210 AS BIGINT)) AS res4,
	 degrees(CAST(NULL AS BIGINT)) AS res5,
	 degrees(CAST(88.6 AS BIGINT)) AS res6
	 );
GO

CREATE VIEW BABEL_3747_vu_prepare_t_v4 AS (
	SELECT
	 degrees(CAST(10 AS INT)) AS res1,
	 degrees(CAST(-10 AS INT)) AS res2,
	 degrees(CAST(250 AS INT)) AS res3,
	 degrees(CAST(893 AS INT)) AS res4,
	 degrees(CAST(NULL AS INT))
	 );
GO