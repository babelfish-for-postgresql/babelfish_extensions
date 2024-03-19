-- This is the original case from BABEL-4788
-- Test Object ID called on inner proc then examine outer proc. 
CREATE PROCEDURE object_id_inner_proc
AS
    if OBJECT_ID('#tmp') is not null 
    begin
        print 'end inner_proc'
    end
go

CREATE PROCEDURE object_id_outer_proc
AS
    CREATE TABLE #tmp(i INT)    

    EXEC object_id_inner_proc 
    print 'after inner_proc'    

    SELECT * FROM #tmp
     
    print 'dropping #tmp'
    DROP TABLE #tmp
go

-- Test nested calls to sys.babelfish_get_enr_list since that calls get_namedRelList
CREATE PROCEDURE enr_list_inner_proc
as
    CREATE TABLE #tab_nest_level_0(a int)
    SELECT relname FROM sys.babelfish_get_enr_list();
go

-- Ensure to check before and after table is created.
CREATE PROCEDURE enr_list_outer_proc
AS
    EXEC enr_list_inner_proc
    CREATE TABLE #tab_nest_level_1(a int)
    EXEC enr_list_inner_proc
go

CREATE PROCEDURE enr_list_outer_outer_proc
AS
    CREATE TABLE #tab_nest_level_2(a int)
    EXEC enr_list_outer_proc
go

-- This is the case from BABEL-4122, which has the same root cause. 
create proc babel_4122_proc @tabname varchar(30) as
    if object_id(@tabname) is not null
    begin
        execute('select * from ' + @tabname)
    end
go

