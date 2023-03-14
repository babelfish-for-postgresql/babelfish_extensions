create view babel_3696_before_15_3_1 as
SELECT json_modify('{"Brand":"HP","Product":"Laptop","Accessories":["Keyboard","Mouse","Monitor"]}', '$.Accessories', JSON_QUERY('["Mouse","Monitor"]'))
go

create view babel_3696_before_15_3_2 as
SELECT json_modify('{"Brand":"HP","Product":"Laptop"}', '$.Accessories', JSON_Query('["Keyboard","Mouse","Monitor"]'))
go

create view babel_3696_before_15_3_3 as
select JSON_MODIFY(JSON_MODIFY('{"Brand":"HP","Product":"Laptop"}', '$.Parts', JSON_VALUE('{"Brand":"HP","Product":"Laptop"}','$.Product')), '$.Product',NULL)
go

create view babel_3696_before_15_3_4 as
select JSON_MODIFY(JSON_MODIFY('{"Brand":"HP","Product":"Laptop","Accessories":["Keyboard","Mouse","Monitor"]}', '$.Accessories', JSON_QUERY('["HDMI","USB"]')), '$.Brand', 'Lenovo')
go


create view babel_3696_before_15_3_5 as
select JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.skills',JSON_QUERY('["C#","T-SQL","Azure"]')) 
go


create table t1 (x nvarchar(20))
insert into t1 values ('some string')
go

create view babel_3696_before_15_3_6 as
select json_modify('{"a":"b"}', '$.a', x) from (select * from t1 for json path) a ([x])
go

create view babel_3696_before_15_3_7 as
select json_modify('{"a":"b"}', '$.a', x) from (select * from t1 for json path, without_array_wrapper) a ([x])
go

create view babel_3696_before_15_3_8 as
select json_modify('{"a":"b"}', '$.a', json_modify('{"a":"b"}', '$.a', 'c'))
go


create view babel_3696_before_15_3_9 as
select json_modify('{"a":"b"}', '$.a', json_modify('{"a":"b"}', 'STRICT $.a', 'c'))
go

create procedure babel_3696_before_15_3_10
as
begin
DECLARE @data NVARCHAR(4000)
SET @data=N'{  
    "Suspect": {    
       "Name": "Homer Simpson",  
       "Address": {    
         "City": "Dunedin",  
         "Region": "Otago",  
         "Country": "New Zealand"  
       },  
       "Hobbies": ["Eating", "Sleeping", "Base Jumping"]  
    }
 }'
select JSON_MODIFY(@data,'$.Suspect.Address.City', 'Timaru') AS 'Modified Array';
end;
go

create procedure babel_3696_before_15_3_11
as
begin
DECLARE @data NVARCHAR(4000)
SET @data=N'{  
    "Suspect": {    
       "Name": "Homer Simpson",  
       "Address": {    
         "City": "Dunedin",  
         "Region": "Otago",  
         "Country": "New Zealand"  
       },  
       "Hobbies": ["Eating", "Sleeping", "Base Jumping"]  
    }
 }'
select JSON_MODIFY(@data,'$.Suspect.Hobbies', JSON_QUERY('["Chess", "Brain Surgery"]')) AS 'Updated Hobbies';
end;
go
