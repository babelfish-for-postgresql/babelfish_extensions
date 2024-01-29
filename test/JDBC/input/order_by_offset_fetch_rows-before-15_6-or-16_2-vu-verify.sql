insert t1_upgr_order_by_offset_fetch select generate_series, 0 from generate_series(1,100)
go
update t1_upgr_order_by_offset_fetch set b=a
go
exec p1_upgr_order_by_offset_fetch 1, 3
go
exec p1_upgr_order_by_offset_fetch 2, 3
go
p1_upgr_order_by_offset_fetch 3, 3
go
select dbo.f1_upgr_order_by_offset_fetch(1,1)
go
select * from v1_upgr_order_by_offset_fetch
go

