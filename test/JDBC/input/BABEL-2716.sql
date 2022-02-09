use master;
go

select (case when 'a ' like 'a' then 1 else 0 end);
go
select (case when 'a ' like 'a ' then 1 else 0 end);
go
select (case when 'a  ' like 'a ' then 1 else 0 end);
go
select (case when 'a' like 'a ' then 1 else 0 end);
go
select (case when 'a ' like 'a  ' then 1 else 0 end);
go

select (case when 'a ' not like 'a' then 1 else 0 end);
go
select (case when 'a ' not like 'a ' then 1 else 0 end);
go
select (case when 'a  ' not like 'a ' then 1 else 0 end);
go
select (case when 'a' not like 'a ' then 1 else 0 end);
go
select (case when 'a ' not like 'a  ' then 1 else 0 end);
go

select (case when 'a' like 'a_' then 1 else 0 end);
go
select (case when 'a ' like 'a_' then 1 else 0 end);
go
select (case when 'a' like 'a%' then 1 else 0 end);
go
select (case when 'a ' like 'a%' then 1 else 0 end);
go
