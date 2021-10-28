use master;
go

select $12.4524
go

select +$12.4524
go

select -$12.4524
go

select $+12.4524
go

select $-12.4524
go

select abs($12.4524)
go

select abs(+$12.4524)
go

select abs(-$12.4524)
go

select abs($+12.4524)
go

select abs($-12.4524)
go

-- udf accepting float
create function f719(@a float) returns int as begin return floor(@a) end
go

select f719($12.4524)
go

select f719(+$12.4524)
go

select f719(-$12.4524)
go

select f719($+12.4524)
go

select f719($-12.4524)
go

drop function f719
go
