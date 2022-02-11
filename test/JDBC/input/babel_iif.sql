select iif (2 < 1, cast('2020-10-20 09:00:00' as datetime), cast('2020-10-21' as date));
go
select iif (2 > 1, cast('abc' as varchar(3)), cast('cba' as char(3)));
go
select iif (2 > 1, cast(3.14 as float), cast(31.4 as numeric(3, 1)));
go
select iif (2 > 1, cast(3.14 as float), cast(1 as int));
go
select iif (2 > 1, cast('$123.123' as money), cast(1 as int));
go
select iif (2 > 1, cast('$123.123' as money), cast(3.14 as float));
go
select iif (2 > 1, cast('2020-10-20 09:00:00' as datetime), cast('09:00:00' as time));
go
select iif (2 > 1, cast('$123.123' as money), cast(321 as bigint));
go
select iif (2 > 1, cast(3.14 as float), cast('$123.123' as money));
go

-- Error, unknown literal cannot fit target type typinput func
select iif (2 > 1, 1, 'abc');
go
-- Error, different categories
select iif (2 > 1, cast(1 as int), cast('abc' as varchar(3)));
go
select iif (2 > 1, cast(0 as bit), cast(1 as int));
go

-- Null handling
select iif (2 > 1, null, 0);
go
select iif (null, 1, 0);
go
select iif (null, null, null);
go
