select c, d, convert(varchar(30), c, 109) as c2, convert(varchar(30), d, 109) as d2 from BABEL_2934_vu_1
go
drop table BABEL_2934_vu_1
go
select c, d, convert(varchar(30), c, 109) as c2, convert(varchar(30), d, 109) as d2 from BABEL_2934_vu_2
go
drop table BABEL_2934_vu_2
go
select c, d, convert(varchar(30), c, 109) as c2, convert(varchar(30), d, 109) as d2 from BABEL_2934_vu_3
go
drop table BABEL_2934_vu_3
go
select * from BABEL_2934_vu_v1
go
drop view BABEL_2934_vu_v1
go
select BABEL_2934_vu_f1(cast('12:15:04.1234567' as TIME(7)))
go
drop function BABEL_2934_vu_f1
go
