create view babel_3696_1 as
SELECT json_modify('{"Brand":"HP","Product":"Laptop","Accessories":["Keyboard","Mouse","Monitor"]}', '$.Accessories', JSON_QUERY('["Mouse","Monitor"]'))
go

create view babel_3696_2 as
SELECT json_modify('{"Brand":"HP","Product":"Laptop"}', '$.Accessories', JSON_Query('["Keyboard","Mouse","Monitor"]'))
go

create view babel_3696_3 as
select JSON_MODIFY(JSON_MODIFY('{"Brand":"HP","Product":"Laptop"}', '$.Parts', JSON_VALUE('{"Brand":"HP","Product":"Laptop"}','$.Product')), '$.Product',NULL)
go

create view babel_3696_4 as
select JSON_MODIFY(JSON_MODIFY('{"Brand":"HP","Product":"Laptop","Accessories":["Keyboard","Mouse","Monitor"]}', '$.Accessories', JSON_QUERY('["HDMI","USB"]')), '$.Brand', 'Lenovo')
go


create view babel_3696_5 as
select JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.skills',JSON_QUERY('["C#","T-SQL","Azure"]')) 
go


create table t1 (x nvarchar(20))
insert into t1 values ('some string')
go

create view babel_3696_6 as
select json_modify('{"a":"b"}', '$.a', x) from (select * from t1 for json path) a ([x])
go

create view babel_3696_7 as
select json_modify('{"a":"b"}', '$.a', x) from (select * from t1 for json path, without_array_wrapper) a ([x])
go

create view babel_3696_8 as
select json_modify('{"a":"b"}', '$.a', json_modify('{"a":"b"}', '$.a', 'c'))
go
