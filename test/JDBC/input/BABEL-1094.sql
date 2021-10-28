CREATE PROCEDURE babel_1094_proc(@p0 VARCHAR(32))
AS
BEGIN
  UPDATE T set id = @id + 1
  BEGIN TRANSACTION
    UPDATE T SET col1 = s.col2 FROM @tab_var s WHERE T.col3 = s.col4
  COMMIT
  SELECT * FROM T WHERE col1 = @id
END
GO

CREATE PROCEDURE babel_1094_proc_2(@p0 VARCHAR(32))
AS
BEGIN
  UPDATE T set id = @id + 1
  BEGIN TRANSACTION
    UPDATE T SET col1 = s.col2 FROM @tab_var s WHERE T.col3 = s.col4
  ROLLBACK
  SELECT * FROM T WHERE col1 = @id
END
GO

DROP PROCEDURE babel_1094_proc
GO

DROP PROCEDURE babel_1094_proc_2
GO

