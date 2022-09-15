CREATE FUNCTION sys_all_objects_dep_vu_prepare_1_1 (@arg1 varchar(5), @arg2 varchar(10))
RETURNS TABLE AS RETURN
(SELECT @arg1 as a, @arg2 as b)
GO

CREATE PROCEDURE sys_all_objects_dep_vu_prepare_proc1
AS
    SELECT type, type_desc from sys.all_objects  where name like 'sys_all_objects_dep_vu_prepare_1_%' order by type;
GO

CREATE FUNCTION sys_all_objects_dep_vu_prepare_func1()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) from sys.all_objects  where name like 'sys_all_objects_dep_vu_prepare_1_%');
END
GO

CREATE VIEW sys_all_objects_dep_vu_prepare_view1
AS
    SELECT type, type_desc from sys.all_objects  where name like 'sys_all_objects_dep_vu_prepare_1_%' order by type;
GO
