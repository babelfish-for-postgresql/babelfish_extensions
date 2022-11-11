-- DIFFERENT CASES TO CHECK DATATYPES
-- EXACT NUMERICS
select a, b, c, d, f, g, i from dt01 for json path
go

select e from dt01 for json path
go

select h from dt01 for json path
go

-- Approximate numerics
select * from dt02 for json path
go

-- Date and time
select * from dt03 for json path
go

-- Character strings
select * from dt04 for json path
go

-- Unicode character strings
select * from dt05 for json path
go

-- Binary strings
select a from dt06 for json path
go

select b from dt06 for json path
go

-- Return null string
select * from t01 for json path
go
