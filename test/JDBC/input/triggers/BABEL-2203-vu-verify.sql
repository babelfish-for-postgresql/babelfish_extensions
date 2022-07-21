EXEC babel_2203_f
GO

DECLARE @ret INT
EXEC @ret = babel_2203_f_2
SELECT @ret
GO

INSERT INTO babel_2203_t_2 VALUES (2);
GO

SELECT * FROM babel_2203_t_2;
GO

-- value should be inserted by proc triggered by trigger.
SELECT * FROM babel_2203_t_inserted_by_proc;
GO