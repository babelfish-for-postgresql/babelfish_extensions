-- issue 1: RETURN SELECT without parenthesis
CREATE PROCEDURE babel_1161_proc_1
AS
BEGIN
  declare @a int
  declare @b int
  set @a = 1
  return
  select @b=@a+1
END
GO

CREATE PROCEDURE babel_1161_proc_1_wrapper
AS
BEGIN
  DECLARE @ret int;
  EXEC @ret = babel_1161_proc_1
  -- note: should show 0 since procedure succeeded.
  PRINT '@ret: ' + cast(@ret as varchar(10));
END
GO

EXEC babel_1161_proc_1_wrapper
GO

CREATE PROCEDURE babel_1161_proc_1_2
AS
BEGIN
  RETURN SELECT 1
END
GO

CREATE PROCEDURE babel_1161_proc_1_2_wrapper
AS
BEGIN
  DECLARE @ret int;
  EXEC @ret = babel_1161_proc_1_2
  PRINT '@ret: ' + cast(@ret as varchar(10));
END
GO

EXEC babel_1161_proc_1_2_wrapper
GO

CREATE PROCEDURE babel_1161_proc_1_3
AS
BEGIN
  RETURN (SELECT 1)
END
GO

CREATE PROCEDURE babel_1161_proc_1_3_wrapper
AS
BEGIN
  DECLARE @ret int;
  EXEC @ret = babel_1161_proc_1_3
  PRINT '@ret: ' + cast(@ret as varchar(10));
END
GO

EXEC babel_1161_proc_1_3_wrapper
GO

-- issue 2: INSERT INTO ... (SELECT ...) SELECT
CREATE TABLE babel_1161_t21(a int);
INSERT INTO babel_1161_t21 values(1);
CREATE TABLE babel_1161_t22(a int);
GO

CREATE PROCEDURE babel_1161_proc_2
AS
  DECLARE @inserted INT

  INSERT  INTO babel_1161_t22
              (SELECT  * FROM babel_1161_t21)
  SELECT  @inserted = @@ROWCOUNT
GO

EXEC babel_1161_proc_2;
GO

SELECT * FROM babel_1161_t22;
GO

-- issue 3: support SELECT TOP (<scalr subq>) ...

create table babel_1161_t31(a int, a2 char);
insert into babel_1161_t31 values (1, 'a'), (2, 'b');
create table babel_1161_t32(b int);
insert into babel_1161_t32 values (1), (2), (3), (4);
GO

select top (select a from babel_1161_t31 where a2 = 'a') * from babel_1161_t32 order by b;
GO

select top (select a from babel_1161_t31 where a2 = 'b') * from babel_1161_t32 order by b;
GO

-- empty scalar subquery
-- SELECT TOP (NULL) should throw error
select top (select a from babel_1161_t31 where a2 = 'c') * from babel_1161_t32 order by b;
GO

-- not a single row
select top (select a from babel_1161_t31) * from babel_1161_t32 order by b;
GO

-- not a single column
select top (select a, a2 from babel_1161_t31 where a2 = 'a') * from babel_1161_t32 order by b;
GO

DROP PROCEDURE babel_1161_proc_1_wrapper;
GO
DROP PROCEDURE babel_1161_proc_1;
GO
DROP PROCEDURE babel_1161_proc_1_2_wrapper;
GO
DROP PROCEDURE babel_1161_proc_1_2;
GO
DROP PROCEDURE babel_1161_proc_1_3_wrapper;
GO
DROP PROCEDURE babel_1161_proc_1_3;
GO
DROP PROCEDURE babel_1161_proc_2;
GO
DROP TABLE babel_1161_t21;
GO
DROP TABLE babel_1161_t22;
GO
DROP TABLE babel_1161_t31;
GO
DROP TABLE babel_1161_t32;
GO
