-- BABEL-381 Test numeric constant can be correctly processed through
-- TDS protocol.
select 2.0;
go

select 2.0/1.5;
go

select 2.0, 2.0/1.5, 1.0/1.5;
go
