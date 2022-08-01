CREATE TABLE BABEL_3147_before_14_5_vu_prepare_t_1 (
        c [int] NULL,
        c_comp AS ISNULL(CONVERT(CHAR(1), 'A'), 'B')
)
GO

CREATE TABLE BABEL_3147_before_14_5_vu_prepare_t_2 (
        a numeric(6, 4),
        b numeric(6, 3)
)
GO

INSERT INTO BABEL_3147_before_14_5_vu_prepare_t_2 VALUES (10.1234, 10.123);
INSERT INTO BABEL_3147_before_14_5_vu_prepare_t_2 VALUES (NULL, 101.123);
GO

CREATE TABLE BABEL_3147_before_14_5_vu_prepare_t_3 (
        a decimal(6, 4),
        b decimal(6, 3)
)
GO

INSERT INTO BABEL_3147_before_14_5_vu_prepare_t_3 VALUES (10.1234, 10.123);
INSERT INTO BABEL_3147_before_14_5_vu_prepare_t_3 VALUES (NULL, 101.123);
GO