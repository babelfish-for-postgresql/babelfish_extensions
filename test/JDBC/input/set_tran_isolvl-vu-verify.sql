set transaction isolation level serializable
go

set tran isolation level serializable
go

set transaction isolation level read committed
go

set tran isolation level read committed
go

EXECUTE p1_set_tran_isolvl
go

EXECUTE p2_set_tran_isolvl 
go

EXECUTE('set transaction isolation level repeatable read')
go

EXECUTE('set tran isolation level repeatable read')
go

set transaction isolation level read committed
go
