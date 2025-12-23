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

SELECT * INTO #temptable5605 FROM generate_series(1,100);
GO
EXEC p_nested
GO
SELECT COUNT(*) FROM #temptable5605
GO
EXEC p_nested_2
GO
EXEC p_index_create
GO
EXEC p_drop
GO
SELECT * FROM #temptable5605
GO