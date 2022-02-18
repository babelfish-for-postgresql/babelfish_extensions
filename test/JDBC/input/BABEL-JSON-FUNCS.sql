-- ISJSON()
create table valid_json_strings (valid_vc VARCHAR(max), valid_nvc NVARCHAR(max), valid_text text);
create table invalid_json_strings (invalid_vc VARCHAR(max), invalid_nvc NVARCHAR(max), invalid_text text);

-- valid json objects
DECLARE @json VARCHAR(max);
SET @json = '{}';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json, @json, @json);
SET @json = '{"key": "value"}';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);
SET @json = '{"key": 1234}';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);
SET @json = '{"key": null}';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);
SET @json = '{"key": {"key": "value"}}';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);
SET @json = '{"key": [1,2,3]}';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);
SET @json = '{"key": [{"sub_key1": "value1"},{ "sub_key2": "value2"}]}';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);
SET @json = '{"key": [[1],[2]]}';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);
SET @json = '{"key": "value", "key": "value"}';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);
SET @json = '{"key": "value1", "key": "value2"}';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);

-- valid json arrays
SET @json = '[]';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);
SET @json = '[1,2,3]';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);
SET @json = '["1","2","3"]';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);
SET @json = '[null, null]';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);
SET @json = '[{"key": "value"}, {"key":123}]';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);
SET @json = '[[1,2,3], {"key":123}]';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);
SET @json = '[[1,2,3], 3, {"key":123}, "val"]';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);
SET @json = '[{"key": [[1,2,3], {"key":123}]}]';
insert into valid_json_strings (valid_vc, valid_nvc, valid_text) values (@json , @json , @json);

-- invalid json
SET @json = '';
insert into invalid_json_strings (invalid_vc, invalid_nvc, invalid_text) values (@json, @json, @json);
SET @json = '3';
insert into invalid_json_strings (invalid_vc, invalid_nvc, invalid_text) values (@json, @json, @json);
SET @json = '{"value1", "value"}';
insert into invalid_json_strings (invalid_vc, invalid_nvc, invalid_text) values (@json , @json , @json);
SET @json = '["key": "value"]';
insert into invalid_json_strings (invalid_vc, invalid_nvc, invalid_text) values (@json , @json , @json);
SET @json = '"key": "value"';
insert into invalid_json_strings (invalid_vc, invalid_nvc, invalid_text) values (@json , @json , @json);
SET @json = '{"key": [1,2,3]}}';
insert into invalid_json_strings (invalid_vc, invalid_nvc, invalid_text) values (@json , @json , @json);
SET @json = '[}';
insert into invalid_json_strings (invalid_vc, invalid_nvc, invalid_text) values (@json , @json , @json);
go

select ISJSON(valid_vc), ISJSON(valid_nvc), ISJSON(valid_text) from valid_json_strings;
go
select ISJSON(invalid_vc), ISJSON(invalid_nvc), ISJSON(invalid_text) from invalid_json_strings;
go


create table json_value_query_table (vc VARCHAR(max), nvc NVARCHAR(max), t text);
go
DECLARE @jsonInfo NVARCHAR(MAX)

SET @jsonInfo=N'{  
     "info":{    
       "type":1,  
       "address":{    
         "town":"Bristol",  
         "county":"Avon",  
         "country":"England",
         "country":"England Duplicate"
       },  
       "tags":["Sport", "Water polo"]  
      },  
      "what":35,
      "type":"Basic2",
      "type":"Basic",
      "key":12,
      "ext":"yes",
      "type":"Basic3",
      "type":"Basic1"
  }'

insert into json_value_query_table (vc, nvc, t) values (@jsonInfo, @jsonInfo, @jsonInfo)
go

-- JSON_VALUE()
-- lax mode
select JSON_VALUE(vc, '$'), JSON_VALUE(nvc, '$'), JSON_VALUE(t, '$') from json_value_query_table;
go
select JSON_VALUE(vc, '$.info.type'), JSON_VALUE(nvc, '$.info.type'), JSON_VALUE(t, '$.info.type') from json_value_query_table;
go
select JSON_VALUE(vc, '$.type'), JSON_VALUE(nvc, '$.type'), JSON_VALUE(t, '$.type') from json_value_query_table;
go
select JSON_VALUE(vc, '$.nokey'), JSON_VALUE(nvc, '$.nokey'), JSON_VALUE(t, '$.nokey') from json_value_query_table;
go
select JSON_VALUE(vc, '$.ext'), JSON_VALUE(nvc, '$.ext'), JSON_VALUE(t, '$.ext') from json_value_query_table;
go
select JSON_VALUE(vc, '$.info.address.town'), JSON_VALUE(nvc, '$.info.address.town'), JSON_VALUE(t, '$.info.address.town') from json_value_query_table
go
select JSON_VALUE(vc, '$.info."address"'), JSON_VALUE(nvc, '$.info."address"'), JSON_VALUE(t, '$.info."address"') from json_value_query_table
go 
select JSON_VALUE(vc, '$.info.tags'), JSON_VALUE(nvc, '$.info.tags'), JSON_VALUE(t, '$.info.tags') from json_value_query_table
go
select JSON_VALUE(vc, '$.info.type[0]'), JSON_VALUE(nvc, '$.info.type[0]'), JSON_VALUE(t, '$.info.type[0]') from json_value_query_table
go
select JSON_VALUE(vc, 'strict $.info.tags[0]'), JSON_VALUE(nvc, 'strict $.info.tags[0]'), JSON_VALUE(t, 'strict $.info.tags[0]') from json_value_query_table
go
select JSON_VALUE(vc, '$.info.none'), JSON_VALUE(nvc, '$.info.none'), JSON_VALUE(t, '$.info.none') from json_value_query_table
go

-- strict mode
select JSON_VALUE(vc, 'strict $'), JSON_VALUE(nvc, 'strict $'), JSON_VALUE(t, 'strict $') from json_value_query_table;
go
select JSON_VALUE(vc, 'strict $.info.type'), JSON_VALUE(nvc, 'strict $.info.type'), JSON_VALUE(t, 'strict $.info.type') from json_value_query_table;
go
select JSON_VALUE(vc, 'strict $.info.address.town'), JSON_VALUE(nvc, 'strict $.info.address.town'), JSON_VALUE(t, 'strict $.info.address.town') from json_value_query_table
go
select JSON_VALUE(vc, 'strict $.info."address"'), JSON_VALUE(nvc, 'strict $.info."address"'), JSON_VALUE(t, 'strict $.info."address"') from json_value_query_table
go
select JSON_VALUE(vc, 'strict $.info.tags'), JSON_VALUE(nvc, 'strict $.info.tags'), JSON_VALUE(t, 'strict $.info.tags') from json_value_query_table
go
select JSON_VALUE(vc, 'strict $.info.type[0]'), JSON_VALUE(nvc, 'strict $.info.type[0]'), JSON_VALUE(t, 'strict $.info.type[0]') from json_value_query_table
go
select JSON_VALUE(vc, 'strict $.info.tags[0]'), JSON_VALUE(nvc, 'strict $.info.tags[0]'), JSON_VALUE(t, 'strict $.info.tags[0]') from json_value_query_table
go
select JSON_VALUE(vc, 'strict $.info.none'), JSON_VALUE(nvc, 'strict $.info.none'), JSON_VALUE(t, 'strict $.info.none') from json_value_query_table
go

-- JSON_QUERY()
-- lax mode
select JSON_QUERY(vc), JSON_QUERY(nvc), JSON_QUERY(t) from json_value_query_table;
go
select JSON_QUERY(vc, '$'), JSON_QUERY(nvc, '$'), JSON_QUERY(t, '$') from json_value_query_table;
go
select JSON_QUERY(vc, '$.info.type'), JSON_QUERY(nvc, '$.info.type'), JSON_QUERY(t, '$.info.type') from json_value_query_table;
go
select JSON_QUERY(vc, '$.info.address.town'), JSON_QUERY(nvc, '$.info.address.town'), JSON_QUERY(t, '$.info.address.town') from json_value_query_table
go
select JSON_QUERY(vc, '$.info."address"'), JSON_QUERY(nvc, '$.info."address"'), JSON_QUERY(t, '$.info."address"') from json_value_query_table
go
select JSON_QUERY(vc, '$.info.tags'), JSON_QUERY(nvc, '$.info.tags'), JSON_QUERY(t, '$.info.tags') from json_value_query_table
go
select JSON_QUERY(vc, '$.info.type[0]'), JSON_QUERY(nvc, '$.info.type[0]'), JSON_QUERY(t, '$.info.type[0]') from json_value_query_table
go
select JSON_QUERY(vc, 'strict $.info.tags[0]'), JSON_QUERY(nvc, 'strict $.info.tags[0]'), JSON_QUERY(t, 'strict $.info.tags[0]') from json_value_query_table
go
select JSON_QUERY(vc, '$.info.none'), JSON_QUERY(nvc, '$.info.none'), JSON_QUERY(t, '$.info.none') from json_value_query_table
go

-- strict mode
select JSON_QUERY(vc), JSON_QUERY(nvc), JSON_QUERY(t) from json_value_query_table;
go
select JSON_QUERY(vc, 'strict $'), JSON_QUERY(nvc, 'strict $'), JSON_QUERY(t, 'strict $') from json_value_query_table;
go
select JSON_QUERY(vc, 'strict $.info.type'), JSON_QUERY(nvc, 'strict $.info.type'), JSON_QUERY(t, 'strict $.info.type') from json_value_query_table;
go
select JSON_QUERY(vc, 'strict $.info.address.town'), JSON_QUERY(nvc, 'strict $.info.address.town'), JSON_QUERY(t, 'strict $.info.address.town') from json_value_query_table
go
select JSON_QUERY(vc, 'strict $.info."address"'), JSON_QUERY(nvc, 'strict $.info."address"'), JSON_QUERY(t, 'strict $.info."address"') from json_value_query_table
go
select JSON_QUERY(vc, 'strict $.info.tags'), JSON_QUERY(nvc, 'strict $.info.tags'), JSON_QUERY(t, 'strict $.info.tags') from json_value_query_table
go
select JSON_QUERY(vc, 'strict $.info.type[0]'), JSON_QUERY(nvc, 'strict $.info.type[0]'), JSON_QUERY(t, 'strict $.info.type[0]') from json_value_query_table
go
select JSON_QUERY(vc, 'strict $.info.tags[0]'), JSON_QUERY(nvc, 'strict $.info.tags[0]'), JSON_QUERY(t, 'strict $.info.tags[0]') from json_value_query_table
go
select JSON_QUERY(vc, 'strict $.info.none'), JSON_QUERY(nvc, 'strict $.info.none'), JSON_QUERY(t, 'strict $.info.none') from json_value_query_table
go

DROP TABLE valid_json_strings
DROP TABLE invalid_json_strings
DROP TABLE json_value_query_table
go
