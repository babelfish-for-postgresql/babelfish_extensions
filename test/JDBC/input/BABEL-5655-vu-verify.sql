select 0 as a, 0.0 as b, 0.00 as c, 0.000 as d into babel_5655_t1
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5655_t1' order by COLUMN_NAME
go

select 0.00 * cast(1.23 as numeric(10, 3))
go

select 0.00 * cast(1.23 as numeric(10, 2))
go

select 0.0000 * cast(1.23 as numeric(10, 2))
go

drop table babel_5655_t1
go

