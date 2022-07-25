-- procedure in function
CREATE PROCEDURE babel_2203_vu_prepare_p_inner AS
  SELECT 1
GO

CREATE FUNCTION babel_2203_vu_prepare_f() RETURNS INT AS
BEGIN
  DECLARE @return INT
  SET @return = 42
  EXEC babel_2203_vu_prepare_p_inner -- should throw runtime error
  RETURN @return
END
GO

-- EXEC function in function -> should be allowed
CREATE FUNCTION babel_2203_vu_prepare_f_inner() RETURNS INT AS
BEGIN
  RETURN 42;
END
GO

CREATE FUNCTION babel_2203_vu_prepare_f_2() RETURNS INT AS
BEGIN
  DECLARE @return INT
  EXEC @return = babel_2203_vu_prepare_f_inner
  RETURN @return
END
GO

CREATE TABLE babel_2203_vu_prepare_t(a int);
INSERT INTO babel_2203_vu_prepare_t VALUES (1);
GO

CREATE FUNCTION babel_2203_vu_prepare_f_ie() RETURNS INT AS
BEGIN
  INSERT INTO babel_2203_vu_prepare_t EXEC babel_2203_vu_prepare_p_inner;
  RETURN 0;
END
GO

CREATE FUNCTION babel_2203_vu_prepare_f_i() RETURNS INT AS
BEGIN
  INSERT INTO babel_2203_vu_prepare_t VALUES (2);
  RETURN 0;
END
GO

CREATE FUNCTION babel_2203_vu_prepare_f_u() RETURNS INT AS
BEGIN
  UPDATE babel_2203_vu_prepare_t SET a = 2;
  RETURN 0;
END
GO

CREATE FUNCTION babel_2203_vu_prepare_f_d() RETURNS INT AS
BEGIN
  DELETE FROM babel_2203_vu_prepare_t;
  RETURN 0;
END
GO

CREATE FUNCTION babel_2203_vu_prepare_f_cv() RETURNS INT AS
BEGIN
  CREATE INDEX babel_2203_vu_prepare_i on babel_2203_vu_prepare_t(a);
  RETURN 0;
END
GO

CREATE FUNCTION babel_2203_vu_prepare_f_dt() RETURNS INT AS
BEGIN
  DROP TABLE babel_2203_vu_prepare_t;
  RETURN 0;
END
GO

-- exec in trigger should be allowed
CREATE TABLE babel_2203_vu_prepare_t_inserted_by_proc(a int);
GO

CREATE PROCEDURE babel_2203_vu_prepare_p_2_inner AS
  INSERT INTO babel_2203_vu_prepare_t_inserted_by_proc VALUES (42);
GO

CREATE TABLE babel_2203_vu_prepare_t_2(a int);
INSERT INTO babel_2203_vu_prepare_t_2 VALUES (1);
GO

CREATE TRIGGER babel_2203_vu_prepare_tr_2 on babel_2203_vu_prepare_t_2 FOR INSERT AS
BEGIN
  exec babel_2203_vu_prepare_p_2_inner;
END
GO

