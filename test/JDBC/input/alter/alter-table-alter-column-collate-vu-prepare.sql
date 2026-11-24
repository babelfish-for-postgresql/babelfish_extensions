-- ALTER TABLE ... ALTER COLUMN ... COLLATE
-- The columns use explicit collations so that the results do not depend on
-- the server or database collation. Column ref has none: it shows the
-- database default collation.
CREATE TABLE alter_col_collate_t1 (
    id int,
    ref varchar(10),
    same_coll varchar(10) COLLATE Latin1_General_CI_AS,
    cs_to_ci varchar(10) COLLATE Latin1_General_CS_AS,
    ai_to_cs nvarchar(10) COLLATE Latin1_General_CI_AI,
    bracketed varchar(10) COLLATE Latin1_General_CS_AS,
    in_proc varchar(10) COLLATE Latin1_General_CI_AS,
    to_db_default varchar(10) COLLATE Latin1_General_CS_AS,
    no_collate varchar(10) COLLATE Latin1_General_CS_AS,
    num int
);
GO

INSERT INTO alter_col_collate_t1 VALUES (1, 'a', 'a', 'a', N'a', 'a', 'a', 'a', 'a', 1);
GO

CREATE TABLE alter_col_collate_t2 (
    id int,
    widen varchar(10) COLLATE Latin1_General_CS_AS,
    cs_to_ci varchar(10) COLLATE Latin1_General_CS_AS
);
GO

CREATE INDEX alter_col_collate_t2_widen ON alter_col_collate_t2 (widen);
GO

CREATE INDEX alter_col_collate_t2_cs_to_ci ON alter_col_collate_t2 (cs_to_ci);
GO

INSERT INTO alter_col_collate_t2 VALUES (1, 'a', 'a'), (2, 'A', 'A'), (3, 'b', 'b');
GO
