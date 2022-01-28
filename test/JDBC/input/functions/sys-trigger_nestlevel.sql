SELECT * FROM trigger_nestlevel()
GO

SET trigger_nestlevel 3
GO

DROP TABLE IF EXISTS t1
GO

CREATE TABLE t1(c1 int)
GO

CREATE TRIGGER trigger1 ON t1
AFTER INSERT
AS
BEGIN
   IF (trigger_nestlevel()) = 1
     BEGIN
        INSERT INTO t1(c1) VALUES (1); -- trigger_nestlevel should be 1 on first trigger call, so this should execute once & only once
     END
END
GO

INSERT INTO t1(c1) VALUES (0);
GO

SELECT * FROM t1
GO

DROP TABLE t1
GO

SELECT trigger_nestlevel()
GO
