create view babel_4328_datetimeoffset_v1 as select cast('3-2-4 14:30 -8:00' as datetimeoffset)
go
create procedure babel_4328_datetimeoffset_p1 as select cast('3-2-4 14:30 -8:00' as datetimeoffset)
go
create function babel_4328_datetimeoffset_f1()
returns datetimeoffset as
begin
return (select cast('3-2-4 14:30 -8:00' as datetimeoffset));
end
go

create view babel_4328_datetimeoffset_v2 as select cast('Apr 12,2000 14:30 -8:00' as datetimeoffset)
go
create procedure babel_4328_datetimeoffset_p2 as select cast('Apr 12,2000 14:30 -8:00' as datetimeoffset)
go
create function babel_4328_datetimeoffset_f2()
returns datetimeoffset as
begin
return (select cast('Apr 12,2000 14:30 -8:00' as datetimeoffset));
end
go

create view babel_4328_datetimeoffset_v3 as SELECT cast('2022-10-30T03:00:00Z' as datetimeoffset)
go
create procedure babel_4328_datetimeoffset_p3 as SELECT cast('2022-10-30T03:00:00Z' as datetimeoffset)
go
create function babel_4328_datetimeoffset_f3()
returns datetimeoffset as
begin
return (SELECT cast('2022-10-30T03:00:00Z' as datetimeoffset));
end
go

create view babel_4328_datetimeoffset_v4 as select cast('20240129 03:00:00 -8:00' as datetimeoffset)
go
create procedure babel_4328_datetimeoffset_p4 as select cast('20240129 03:00:00 -8:00' as datetimeoffset)
go
create function babel_4328_datetimeoffset_f4()
returns datetimeoffset as
begin
return (select cast('20240129 03:00:00 -8:00' as datetimeoffset));
end
go

create view babel_4328_datetimeoffset_v5 as select cast('12 2024 Apr 14:30 -8:00' as datetimeoffset)
go
create procedure babel_4328_datetimeoffset_p5 as select cast('12 2024 Apr 14:30 -8:00' as datetimeoffset)
go
create function babel_4328_datetimeoffset_f5()
returns datetimeoffset as
begin
return (select cast('12 2024 Apr 14:30 -8:00' as datetimeoffset));
end
go

create view babel_4328_datetimeoffset_v6 as select cast('04-02-03 14:30 -8:00' as datetimeoffset)
go
create procedure babel_4328_datetimeoffset_p6 as select cast('04-02-03 14:30 -8:00' as datetimeoffset)
go
create function babel_4328_datetimeoffset_f6()
returns datetimeoffset as
begin
return (select cast('04-02-03 14:30 -8:00' as datetimeoffset));
end
go

