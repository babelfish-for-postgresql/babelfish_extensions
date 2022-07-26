CREATE TABLE babel_3116_vu_prepare_t1 (
    id int IDENTITY(1,1) NOT NULL,
    c1 int DEFAULT 0,
    c2 int DEFAULT 0,
    c3 int DEFAULT 0
);
GO

CREATE TRIGGER babel_3116_vu_prepare_trg_t1
ON babel_3116_vu_prepare_t1
INSTEAD OF UPDATE
AS
UPDATE babel_3116_vu_prepare_t1
SET c3 = c3 + 1
WHERE id IN (SELECT DISTINCT id FROM inserted);
GO