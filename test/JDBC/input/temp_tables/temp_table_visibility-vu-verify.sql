EXEC object_id_outer_proc
go

EXEC enr_list_outer_outer_proc
go


-- 4122 test case
create table #t4122 (a int)
insert #t4122 values(123)
insert #t4122 values(456)
go

-- Sanity check to ensure object_id is able to return an OID.
if object_id('#t4122') is null
    print 'fail'
go

exec babel_4122_proc '#t4122'
go
