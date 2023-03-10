create view babel_3697_1 as
SELECT JSON_MODIFY('{"click_count": 173}', '$.click_count', CAST(JSON_VALUE('{"click_count": 173}','$.click_count') AS INT)+1)
go

create view babel_3697_2 as
SELECT JSON_MODIFY('{"click_count": 173.12345342}', '$.click_count', CAST(JSON_VALUE('{"click_count": 173.12345342}','$.click_count') AS NUMERIC(7, 3)))
go

create view babel_3697_3 as
SELECT JSON_MODIFY('{"click_count": 173}', '$.click_count', 25)
go

create view babel_3697_4 as
SELECT JSON_MODIFY('{"click_count": 1900-01-01}', '$.click_count', CAST('1900-02-02' as DATE))
go

create view babel_3697_5 as
SELECT JSON_MODIFY('{"click_count": 04:05:06}', '$.click_count', CAST('04:05:06' as TIME))
go


create procedure babel_3697_6
as begin
DECLARE @data NVARCHAR(100)='{"click_count": 12345}'
SELECT JSON_MODIFY(@data, '$.click_count', CAST(JSON_VALUE(@data,'$.click_count') AS CHAR(2)))
end;
go

create procedure babel_3697_7
as begin
DECLARE @data NVARCHAR(100)='{"click_count": 12345}'
SELECT JSON_MODIFY(@data, '$.click_count', 0)
end;
go

create procedure babel_3697_8
as begin
DECLARE @data NVARCHAR(100)='{"click_count": 12345}'
SELECT JSON_MODIFY(@data, '$.click_count', 6 + 235)
end;
go

-- To check multi function call query
create view babel_3697_multi_function as
SELECT JSON_MODIFY(JSON_MODIFY(JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.name','Mike'),'$.surname','Smith'),'append $.skills','Azure') AS mf_1, 
       JSON_MODIFY(JSON_MODIFY('{"price":49.99}','$.Price',CAST(JSON_VALUE('{"price":49.99}','$.price') AS NUMERIC(4,2))),'$.price',NULL) AS mf_2;
go
