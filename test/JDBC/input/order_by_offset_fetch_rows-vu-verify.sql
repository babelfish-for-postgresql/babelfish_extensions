declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET (@p*5) ROWS FETCH NEXT (5) ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET (@p*5) ROW FETCH NEXT 5 ROW ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET (@p*5) ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET (@p*5) ROWS FETCH NEXT 1+2 ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET (@p*5) ROWS FETCH NEXT (1+2) ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p ROWS FETCH NEXT +3 ROWS ONLY
go
declare @p int =2,@q int=0 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =0,@q int=1 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET 1+1 ROWS FETCH NEXT 2 ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET 1+1 ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =2,@q int=0 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p*1 ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =2,@q int=1 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p*1 ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =0,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p*1 ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =1,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p*1 ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =3,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p+1 ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =3,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p*2 ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =1,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p*@q ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p*@q ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int=2,@q int=0 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p*@q ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int=1,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p*@q ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int=2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p*@q ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET square(2) ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET square(1)*@p ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET square(@p)+@p ROWS FETCH NEXT @q+1 ROWS ONLY
go
declare @p int=2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p*1 ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET square(1)*@p+1 ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET square(1)*(@p) ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET square(1)*@p ROWS FETCH NEXT @q ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET @p*square(1) ROWS FETCH NEXT @q*square(1) ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET square(1)*@p ROWS FETCH NEXT square(1)+@q ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET square(1)* @p ROWS FETCH NEXT square(@q)*@q+1 ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET square(1)*3+1 ROWS FETCH NEXT @p+1 ROWS ONLY
go
declare @p int =2,@q int=3 SELECT * FROM t1_order_by_offset_fetch ORDER BY b OFFSET (@p*@p) ROWS FETCH NEXT @p*@q ROWS ONLY
go
exec p1_order_by_offset_fetch 1, 3
go
exec p1_order_by_offset_fetch 2, 3
go
p1_order_by_offset_fetch 3, 3
go
select dbo.f1_order_by_offset_fetch(1,1)
go
select * from v1_order_by_offset_fetch
go