EXEC sp_babelfish_configure 'enable_pg_hint', 'on'
GO

CREATE TABLE BABEL_3759_t1(
    c1_INT  INT PRIMARY KEY
    , c2_VARCHAR VARCHAR(300) NULL
    , c3_BINARY BINARY(100) NOT NULL
    , c4_DATETIME DATETIME NULL
    , c5_MONEY MONEY NOT NULL
)
GO

CREATE INDEX BABEL_3759_idx_t1_VARCHAR ON BABEL_3759_t1( c2_VARCHAR )
GO

SET babelfish_showplan_all ON
GO

SELECT c1_INT FROM BABEL_3759_t1 (INDEX(BABEL_3759_idx_t1_VARCHAR)) WHERE c2_VARCHAR = 'S'
GO

SET babelfish_showplan_all OFF
GO

DROP TABLE BABEL_3759_t1
GO

CREATE TABLE babel_3759_t1(
    c1_INT  INT PRIMARY KEY
    , c2_varchar VARCHAR(300) NULL
    , c3_BINARY BINARY(100) NOT NULL
    , c4_DATETIME DATETIME NULL
    , c5_MONEY MONEY NOT NULL
)
GO

CREATE INDEX babel_3759_idx_t1_varchar ON babel_3759_t1( c2_varchar )
GO

SET babelfish_showplan_all ON
GO

SELECT c1_INT FROM babel_3759_t1 (INDEX(babel_3759_idx_t1_varchar)) WHERE c2_varchar = 'S'
GO

SET babelfish_showplan_all OFF
GO

DROP TABLE babel_3759_t1
GO