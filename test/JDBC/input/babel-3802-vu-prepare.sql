CREATE PROCEDURE babel_3802_vu_prepare_t_p1 AS (SELECT power(CAST(100 AS SMALLINT),3));
GO


CREATE PROCEDURE babel_3802_vu_prepare_t_p2 AS (
    SELECT
        power(CAST(-32768 AS SMALLINT),1),
        power(CAST(32767 AS SMALLINT),1),
        power(CAST(NULL AS SMALLINT),1)
    );
GO
 
CREATE PROCEDURE babel_3802_vu_prepare_t_p3 AS (
    SELECT
        power(CAST(0 AS TINYINT),1),
        power(CAST(255 AS TINYINT),1),
        power(CAST(NULL AS TINYINT),1)
    );
GO


CREATE VIEW babel_3802_vu_prepare_t_v1 AS (
    SELECT
        power(CAST(-32768 AS SMALLINT),1) AS res1,
        power(CAST(32767 AS SMALLINT),1) AS res2,
        power(CAST(NULL AS SMALLINT),1) AS res3
    );
GO
 
CREATE VIEW babel_3802_vu_prepare_t_v2 AS (
    SELECT
        power(CAST(0 AS TINYINT),1) AS res1,
        power(CAST(255 AS TINYINT),1) AS res2,
        power(CAST(NULL AS TINYINT),1) AS res3
    );
GO