create function f1() returns int begin declare @a int; set @a = 1; return @a; end
go

create schema a
go

create function a.f1() returns int begin declare @a int; set @a = 1; return @a; end
go


