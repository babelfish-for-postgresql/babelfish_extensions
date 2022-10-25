CREATE PROCEDURE sys_all_objects_vu_prepare_1 (@arg1 VARCHAR(MAX) OUTPUT)
AS
BEGIN
    print 'body removed'
END;
GO

CREATE PROCEDURE sys_all_objects_vu_prepare_1_2 (@arg1 VARCHAR(MAX))
AS
BEGIN
    print 'body removed'
END;
GO

CREATE TABLE sys_all_objects_vu_prepare_t1(c1 int);
GO

CREATE TRIGGER sys_all_objects_vu_prepare_1_3 ON sys_all_objects_vu_prepare_t1
AFTER INSERT
AS
BEGIN
    INSERT INTO sys_all_objects_vu_prepare_t1(c1) VALUES (1);
END;
GO

-- Scalar function
CREATE FUNCTION sys_all_objects_vu_prepare_1_4_fn(@arg1 varchar(5), @arg2 varchar(10))
RETURNS INT
BEGIN
RETURN 1
END
GO

-- Table-valued function
CREATE FUNCTION sys_all_objects_vu_prepare_1_5_tf(@arg1 varchar(5), @arg2 varchar(10))
RETURNS @t TABLE (
    c1 int,
    c2 int
)
AS
BEGIN
    INSERT INTO @t
    SELECT @arg1 as c1, @arg2 as c2;
    RETURN;
END
GO

-- Inline table-valued function that returns an int (from pg_type)
CREATE FUNCTION sys_all_objects_vu_prepare_1_6_if_1(@arg1 INT)
RETURNS TABLE AS
RETURN (SELECT @arg1 + 1 AS col);
GO

-- Inline table-valued function that returns a record (from pg_type)
CREATE FUNCTION sys_all_objects_vu_prepare_1_7_if_2(@arg1 varchar(5), @arg2 varchar(10))
RETURNS TABLE AS RETURN
(SELECT @arg1 as a, @arg2 as b)
GO
