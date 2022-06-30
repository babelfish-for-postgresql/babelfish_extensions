CREATE TABLE t1 (
    id int IDENTITY(1,1) NOT NULL,
    c1 int DEFAULT 0,
    c2 int DEFAULT 0,
    c3 int DEFAULT 0
);
GO

INSERT INTO t1 (c1, c2, c3)
VALUES (1, 1, 1);
GO

SELECT * FROM t1;
GO

CREATE TRIGGER trg_t1
ON t1
INSTEAD OF UPDATE
AS
UPDATE t1
SET c3 = c3 + 1
WHERE id IN (SELECT DISTINCT id FROM inserted);
GO

UPDATE t1
SET c1 = c1 + 1 --Trigger should cause c3 to be 2
WHERE id = 1;
GO

SELECT * FROM t1;
GO

drop trigger trg_t1
GO

drop table t1
GO