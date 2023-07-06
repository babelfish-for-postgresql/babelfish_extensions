CREATE TABLE delete_test (
    id SERIAL PRIMARY KEY,
    a INT,
    b text
);
GO

INSERT INTO delete_test (a) VALUES (10);
GO
INSERT INTO delete_test (a, b) VALUES (50, repeat('x', 10000));
GO
INSERT INTO delete_test (a) VALUES (100);
GO

-- allow an alias to be specified for DELETE's target table
DELETE dt FROM delete_test dt WHERE dt.a > 75;
GO

-- if an alias is specified, don't allow the original table name
-- to be referenced
DELETE dt FROM delete_test dt WHERE delete_test.a > 25;
GO

SELECT id, a, char_length(b) FROM delete_test;
GO

-- delete a row with a TOASTed value
DELETE FROM delete_test WHERE a > 25;
GO

SELECT id, a, char_length(b) FROM delete_test;
GO

DROP TABLE delete_test;
GO
