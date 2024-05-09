-- check if primary key index is used for query with order by clause
SET NOCOUNT ON
GO
-- column constraint
CREATE TABLE babel_4940_t1(id INT PRIMARY KEY)
GO
INSERT INTO babel_4940_t1 VALUES(generate_series(1,100000))
GO

-- table constraint
CREATE TABLE babel_4940_t2(id INT, PRIMARY KEY(id))
GO
INSERT INTO babel_4940_t2 VALUES(generate_series(1,100000))
GO

-- table constraint multiple column
CREATE TABLE babel_4940_t3(id INT, id1 INT, PRIMARY KEY(id, id1))
GO
SET NOCOUNT ON
DECLARE @i INT=0;
WHILE (@i<1000)
BEGIN
    INSERT INTO babel_4940_t3 VALUES(@i,@i+1)
    INSERT INTO babel_4940_t3 VALUES(@i,@i+2)
    INSERT INTO babel_4940_t3 VALUES(@i,@i+3)
    SET @i = @i + 1;
END
GO


-- same test as above but create primary key using alter table add constraints
-- column constraint
CREATE TABLE babel_4940_t4(id INT PRIMARY KEY)
GO
ALTER TABLE babel_4940_t4 DROP COLUMN id
GO
ALTER TABLE babel_4940_t4 ADD id INT PRIMARY KEY
GO
INSERT INTO babel_4940_t4 VALUES(generate_series(1,100000))
GO

-- table constraint
CREATE TABLE babel_4940_t5(id INT)
GO
ALTER TABLE babel_4940_t5 ADD CONSTRAINT c PRIMARY KEY (id)
GO
INSERT INTO babel_4940_t5 VALUES(generate_series(1,100000))
GO

-- table constraint multiple column
CREATE TABLE babel_4940_t6(id INT, id1 INT)
GO
ALTER TABLE babel_4940_t6 ADD CONSTRAINT c PRIMARY KEY(id, id1 DESC)
GO
DECLARE @i INT=0;
WHILE (@i<1000)
BEGIN
    INSERT INTO babel_4940_t6 VALUES(@i,@i+1)
    INSERT INTO babel_4940_t6 VALUES(@i,@i+2)
    INSERT INTO babel_4940_t6 VALUES(@i,@i+3)
    SET @i = @i + 1;
END
GO

-- All these queries should use primary key index
SELECT set_config('babelfishpg_tsql.explain_costs', 'off', false)
SELECT set_config('babelfishpg_tsql.explain_timing', 'off', false)
SELECT set_config('babelfishpg_tsql.explain_summary', 'off', false)
SET BABELFISH_STATISTICS PROFILE ON;
GO

SELECT TOP 10 * FROM babel_4940_t1 ORDER BY id
GO
SELECT TOP 10 * FROM babel_4940_t1 ORDER BY id DESC
GO
SELECT TOP 10 * FROM babel_4940_t2 ORDER BY id 
GO
SELECT TOP 10 * FROM babel_4940_t2 ORDER BY id DESC
GO
SELECT TOP 10 * FROM babel_4940_t3 ORDER BY id, id1
GO
SELECT TOP 10 * FROM babel_4940_t3 ORDER BY id DESC, id1 DESC
GO
SELECT TOP 10 * FROM babel_4940_t4 ORDER BY id
GO
SELECT TOP 10 * FROM babel_4940_t4 ORDER BY id DESC
GO
SELECT TOP 10 * FROM babel_4940_t5 ORDER BY id 
GO
SELECT TOP 10 * FROM babel_4940_t5 ORDER BY id DESC
GO
SELECT TOP 10 * FROM babel_4940_t6 ORDER BY id, id1 DESC
GO
SELECT TOP 10 * FROM babel_4940_t6 ORDER BY id DESC, id1 ASC
GO

SET BABELFISH_STATISTICS PROFILE OFF;

DROP TABLE babel_4940_t1, babel_4940_t2, babel_4940_t3, babel_4940_t4, babel_4940_t5, babel_4940_t6
GO
