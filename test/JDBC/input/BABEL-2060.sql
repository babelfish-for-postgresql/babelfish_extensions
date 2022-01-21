use master;
go

declare @a int;
select @a=1 union all select 1;
go

declare @a int;
select @a=1 union all select @a=2;
go

declare @a int;
select 1 union all select @a=2;
go

declare @a int;
select @a=1 except select 1;
go

declare @a int;
select @a=1 except select @a=2;
go

declare @a int;
select 1 except select @a=2;
go

declare @a int;
select @a=1 intersect select 1;
go

declare @a int;
select @a=1 intersect select @a=2;
go

declare @a int;
select 1 intersect select @a=2;
go

-- derived table
declare @a int;
select @a=a from (select 1 as a) T;
select case when @a = 1 then 'ok' else 'wrong' end as result;
go

declare @a int;
select 1 from (select @a=1) T;
go

declare @a int;
select 1 from (select @a=1 union all select 1) T;
go

declare @a int;
select 1 from (select 1 union all select @a=1) T;
go

declare @a int, @b int;
select @b=1 from (select @a=1) T;
go

declare @a int, @b int;
select @b=1 from (select @a=1 union all select 1) T;
go

declare @a int, @b int;
select @b=1 from (select 1 union all select @a=1) T;
go

-- subquery
declare @a int;
select @a=(select 1);
select case when @a = 1 then 'ok' else 'wrong' end as result;
go

declare @a int;
select (select @a=1);
go

declare @a int;
select (select @a=1 union all select 1);
go

declare @a int;
select (select 1 union all select @a=1);
go

-- cte
declare @a int;
with T as (select 1 as a) select @a=a from T;
select case when @a = 1 then 'ok' else 'wrong' end as result;
go

declare @a int;
with T as (select @a=1) select * from T;
go

declare @a int;
with T as (select @a=1 union all select 1) select * from T;
go

declare @a int;
with T as (select 1 union all select @a=1) select * from T;
go
