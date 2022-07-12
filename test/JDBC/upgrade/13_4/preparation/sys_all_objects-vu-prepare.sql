CREATE PROCEDURE sysall_objects (@arg1 VARCHAR(MAX) OUTPUT)
AS
BEGIN
    print 'body removed'
END;
GO

CREATE PROCEDURE sysall_objects_2 (@arg1 VARCHAR(MAX))
AS
BEGIN
    print 'body removed'
END;
GO

CREATE FUNCTION sysall_objects_3 (@arg1 varchar(5), @arg2 varchar(10))
RETURNS TABLE AS RETURN
(SELECT @arg1 as a, @arg2 as b)
GO

CREATE TABLE t1_sysall_objects(c1 int);
GO

CREATE TRIGGER sysall_objects_4 ON t1_sysall_objects
AFTER INSERT
AS
BEGIN
    INSERT INTO t1_sysall_objects(c1) VALUES (1);
END;
GO