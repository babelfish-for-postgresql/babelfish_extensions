drop table if exists babel_2202_t1
go

create table babel_2202_t1(a1 int PRIMARY KEY)
go

insert into babel_2202_t1 values(1)
go

insert into babel_2202_t1 values(2)
go

select set_config('babelfishpg_tsql.max_recursion_depth', '-1', false)
go

select set_config('babelfishpg_tsql.max_recursion_depth', '32768', false)
go

select set_config('babelfishpg_tsql.max_recursion_depth', '3', false)
go

-- Test an infinite recursive CTE with each cycle resulting in one row
with babel_2202_cte(a1) as
(
    select 1 as a1 
    union all
    select * from babel_2202_cte
)
select * from babel_2202_cte
go

-- Test an infinite recursive CTE with each cycle resulting in multiple rows
with babel_2202_cte as
(
    select *, 1 as number from babel_2202_t1
    union all
    select 1, number + 1 from babel_2202_cte
)
select * from babel_2202_cte
go

-- Test a query having a select statement resulting in a few rows union with an infinite recursive CTE
with babel_2202_cte as
(
    select *, 1 as number from babel_2202_t1
    union all
    select 1, number + 1 from babel_2202_cte
)
select *, 1 from babel_2202_t1
union all
select * from babel_2202_cte
go

-- Test query having multiple CTE's
with babel_2202_cte_1 as
(
    select *, 1 as number from babel_2202_t1
    union all
    select 1, number + 1 from babel_2202_cte_1
),
babel_2202_cte_2 as
(
    select *, 1 as number from babel_2202_t1
    union all
    select 1, number + 1 from babel_2202_cte_2
)
select * from babel_2202_cte_1
union all
select * from babel_2202_cte_2
go

with babel_2202_cte_1 as
(
    select *, 1 as number from babel_2202_t1
    union all
    select 1, number + 1 from babel_2202_cte_1
),
babel_2202_cte_2 as
(
    select *, 1 as number from babel_2202_t1
    union all
    select 1, number + 1 from babel_2202_cte_2
)
select *, 1 from babel_2202_t1
union all
select * from babel_2202_cte_1
union all
select * from babel_2202_cte_2
go

with babel_2202_cte_1 as
(
    select *, 1 as number from babel_2202_t1
    union all
    select 1, number + 1 from babel_2202_cte_1
    where number < 3
),
babel_2202_cte_2 as
(
    select *, 1 as number from babel_2202_t1
    union all
    select 1, number + 1 from babel_2202_cte_2
)
select * from babel_2202_cte_1
union all
select * from babel_2202_cte_2
go

with babel_2202_cte_1 as
(
    select *, 1 as number from babel_2202_t1
    union all
    select 1, number + 1 from babel_2202_cte_1
    where number < 3
),
babel_2202_cte_2 as
(
    select *, 1 as number from babel_2202_t1
    union all
    select 1, number + 1 from babel_2202_cte_2
)
select *, 1 from babel_2202_t1
union all
select * from babel_2202_cte_1
union all
select * from babel_2202_cte_2
go

-- Test query having nested CTE's
with babel_2202_cte_1 as
(
    select 1 as number
    union all
    select number + 1 from babel_2202_cte_1
),
babel_2202_cte_2 as
(
    select 2 as number
    union all
    select * from babel_2202_cte_1
)
select * from babel_2202_cte_2
go

-- cleanup
select set_config('babelfishpg_tsql.max_recursion_depth', '100', false)
go

drop table babel_2202_t1
go