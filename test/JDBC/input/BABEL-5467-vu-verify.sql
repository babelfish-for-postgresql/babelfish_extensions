-- Client Tests
select count_avg = avg(convert(decimal(38,6), 10) + (convert(decimal(38,6), 2)/convert(decimal(38,6), 3)))
 , count_val = avg(cast(18 as decimal)) 
into babel_5467_avgdata_1
go

select cast(count_avg as decimal(38,6)), cast(count_val as decimal(38,6))
 ,PercentSpike = ((count_val-count_avg)/count_avg)*100
from babel_5467_avgdata_1
go

select cast(count_avg as decimal(38,6)), cast(count_val as decimal(38,6))
 ,PercentSpike = cast(((count_val-count_avg)/count_avg)*100 as decimal(38,6))
from babel_5467_avgdata_1
go

select count_avg = avg((convert(decimal(38,6), 32)/convert(decimal(38,6), 3)))
 ,count_val = avg(cast(18 as decimal))
into babel_5467_avgdata_2
go

select cast(count_avg as decimal(38,6)), cast(count_val as decimal(38,6))
 ,PercentSpike = ((count_val-count_avg)/count_avg)*100
from babel_5467_avgdata_2
go

select cast(count_avg as decimal(38,6)), cast(count_val as decimal(38,6))
 ,PercentSpike = cast(((count_val-count_avg)/count_avg)*100 as decimal(38,6))
from babel_5467_avgdata_2
go

create table babel_5467_avgdata_3_setup ( CountData int )
insert into babel_5467_avgdata_3_setup (CountData) values (10), (11), (11)
go

select avg(convert(decimal, CountData)) as count_avg
 ,avg(cast(18 as decimal)) as count_val 
into babel_5467_avgdata_3 
from babel_5467_avgdata_3_setup
go

select cast(count_avg as decimal(38,6)), cast(count_val as decimal(38,6))
 ,PercentSpike = ((count_val-count_avg)/count_avg)*100
from babel_5467_avgdata_3
go

select cast(count_avg as decimal(38,6)), cast(count_val as decimal(38,6))
 ,PercentSpike = cast(((count_val-count_avg)/count_avg)*100 as decimal(38,6)) 
from babel_5467_avgdata_3
go

-- constant expression
select cast(((cast(18 as decimal) - cast(10.666666 as decimal(38,6)))/cast(10.666666 as decimal(38,6)))*100 as decimal(38,6))
go

-- result should be upto correct scale
select convert(decimal(38,6), 32)/convert(decimal(38,6), 3)
go

select avg((convert(decimal(38,6), 32)/convert(decimal(38,6), 3)))
go

select count_avg = avg(convert(decimal(38,6), 10) + (convert(decimal(38,6), 2)/convert(decimal(38,6), 3))) 
 ,count_val = avg(cast(18 as decimal))
go

select count_avg = avg((convert(decimal(38,6), 32)/convert(decimal(38,6), 3))) 
 ,count_val = avg(cast(18 as decimal))
go

SELECT a = 10.12345678, b = 10.0/3.0, c = cast(10.2345 as decimal(38,6)) 
 , d = (cast(32 as decimal(38,6)) / cast(3 as decimal(38,6))), e = avg(10.0/3.0) 
 , f = avg(cast(10.2345 as decimal(38,6))) 
 into babel_5467_t1
go

-- Precision and scale details should be stored correctly
select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_1' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_2' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_3' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_t1' order by COLUMN_NAME
go

-- tables with computed columns having expression which results in numeric
create table babel_5467_t2(a decimal(38,6), b decimal(38,6), c as a / b)
insert into babel_5467_t2 values(32,3)
go

select * from babel_5467_t2
go

-- non-constant expression
select c = (a/b) into babel_5467_t3 from babel_5467_t2
go
select * from babel_5467_t3
go

-- Testing on UDT
CREATE TYPE DECIMALUDT_38_6 FROM decimal(38,6)
GO

CREATE TYPE DECIMALUDT FROM decimal
GO

select count_avg = avg(convert(DECIMALUDT_38_6, 10) + (convert(DECIMALUDT_38_6, 2)/convert(DECIMALUDT_38_6, 3)))
 , count_val = avg(cast(18 as DECIMALUDT)) 
into babel_5467_avgdata_udt_1
go

select cast(count_avg as DECIMALUDT_38_6), cast(count_val as DECIMALUDT_38_6)
 ,PercentSpike = ((count_val-count_avg)/count_avg)*100
from babel_5467_avgdata_udt_1
go

select cast(count_avg as DECIMALUDT_38_6), cast(count_val as DECIMALUDT_38_6)
 ,PercentSpike = cast(((count_val-count_avg)/count_avg)*100 as DECIMALUDT_38_6)
from babel_5467_avgdata_udt_1
go

select count_avg = avg((convert(DECIMALUDT_38_6, 32)/convert(DECIMALUDT_38_6, 3)))
 ,count_val = avg(cast(18 as DECIMALUDT))
into babel_5467_avgdata_udt_2
go

select cast(count_avg as DECIMALUDT_38_6), cast(count_val as DECIMALUDT_38_6)
 ,PercentSpike = ((count_val-count_avg)/count_avg)*100
from babel_5467_avgdata_udt_2
go

select cast(count_avg as DECIMALUDT_38_6), cast(count_val as DECIMALUDT_38_6)
 ,PercentSpike = cast(((count_val-count_avg)/count_avg)*100 as DECIMALUDT_38_6)
from babel_5467_avgdata_udt_2
go

select avg(convert(DECIMALUDT, CountData)) as count_avg
 ,avg(cast(18 as DECIMALUDT)) as count_val 
into babel_5467_avgdata_udt_3 
from babel_5467_avgdata_3_setup
go

select cast(count_avg as DECIMALUDT), cast(count_val as DECIMALUDT)
 ,PercentSpike = ((count_val-count_avg)/count_avg)*100
from babel_5467_avgdata_udt_3
go

select cast(count_avg as DECIMALUDT), cast(count_val as DECIMALUDT)
 ,PercentSpike = cast(((count_val-count_avg)/count_avg)*100 as DECIMALUDT) 
from babel_5467_avgdata_udt_3
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_udt_3' order by COLUMN_NAME
go

create table babel_5467_t4(a decimal(10,2), b decimal(15, 6), c decimal(8, 5))
go

insert into babel_5467_t4 values(12345678.12, 123456789.666666, 123.66666), (11111111.33, 123456789.666666, 321.444444)
go

select avg(a) as p, avg(b) as q, avg(c) as r, avg(a+c) as s into babel_5467_avgdata_4 from babel_5467_t4
go

select min(a) as p, min(b) as q, min(c) as r, min(a+c) as s into babel_5467_avgdata_5 from babel_5467_t4
go

select max(a) as p, max(b) as q, max(c) as r, max(a+c) as s into babel_5467_avgdata_6 from babel_5467_t4
go

select sum(a) as p, sum(b) as q, sum(c) as r, sum(a+c) as s into babel_5467_avgdata_7 from babel_5467_t4
go

select count(a) as p, count(b) as q, count(c) as r, count(a+c) as s into babel_5467_avgdata_8 from babel_5467_t4
go

select * from babel_5467_avgdata_4
go

select * from babel_5467_avgdata_5
go

select * from babel_5467_avgdata_6
go

select * from babel_5467_avgdata_7
go

select * from babel_5467_avgdata_8
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_4' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_5' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_6' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_7' order by COLUMN_NAME
go

select TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, NUMERIC_PRECISION, NUMERIC_PRECISION_RADIX, NUMERIC_SCALE
from information_schema.columns 
where TABLE_NAME = 'babel_5467_avgdata_8' order by COLUMN_NAME
go

-- cleanup
drop table babel_5467_avgdata_1
drop table babel_5467_avgdata_2
drop table babel_5467_avgdata_udt_1
drop table babel_5467_avgdata_udt_2
drop table babel_5467_avgdata_udt_3
drop table babel_5467_avgdata_3_setup
drop table babel_5467_avgdata_3
drop table babel_5467_avgdata_4
drop table babel_5467_avgdata_5
drop table babel_5467_avgdata_6
drop table babel_5467_avgdata_7
drop table babel_5467_avgdata_8
drop table babel_5467_t1
drop table babel_5467_t2
drop table babel_5467_t3
drop table babel_5467_t4
go

drop type DECIMALUDT_38_6
drop type DECIMALUDT
GO
