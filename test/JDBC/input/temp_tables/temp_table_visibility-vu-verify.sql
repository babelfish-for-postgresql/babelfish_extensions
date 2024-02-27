EXEC object_id_outer_proc
go

EXEC enr_list_outer_outer_proc
go


-- 4122 test case
create table #t (a int)
insert #t values(123)
insert #t values(456)
go

if object_id('#t') is null
    print 'fail'
go

exec babel_4122_proc 