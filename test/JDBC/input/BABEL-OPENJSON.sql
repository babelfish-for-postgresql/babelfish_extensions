

-- OPENJSON()
-- OPENJSON without WITH clause
select * from OPENJSON(N'{"a":null,"b":"a","c":1,"d":true,"e":[1,2],"f":{"name":"John"}}');
go
DECLARE @jsonvar NVARCHAR(2048) = N'{
   "String_value": "John",
   "DoublePrecisionFloatingPoint_value": 45,
   "DoublePrecisionFloatingPoint_value": 2.3456,
   "BooleanTrue_value": true,
   "BooleanFalse_value": false,
   "Null_value": null,
   "Array_value": ["a","r","r","a","y"],
   "Object_value": {"obj":"ect"}
}';
SELECT * FROM OpenJson(@jsonvar);
go
SELECT [key], value FROM OPENJSON(N'{"path":{"to":{"sub-object":["en-GB", "en-UK","de-AT","es-AR","sr-Cyrl"]}}}','$.path.to."sub-object"');
go
-- check that value is an object
select * from openjson(N'{"a":1}', 'strict $.a')
GO
-- check lax/strict path
select * from openjson(N'{"obj":{"a":1}}', 'lax $.a')
go
select * from openjson(N'{"obj":{"a":1}}', 'strict $.a')
go
-- check non-ascii characters
select * from openjson(N'{"nonascii":"ちょまど@初詣おみくじ凶\n - description: ( *ﾟ▽ﾟ* っ)З腐女子！絵描き！| H26新卒文系SE (入社して4ヶ月目の8月にSIer(適応障害になった)を辞職し開発者に転職) | H26秋応用情報合格！| 自作bot (in PHP) chomado_bot | プログラミングガチ初心者\n"}')
go

-- OPENJSON with WITH clause
DECLARE @json NVARCHAR(MAX) = N'{"obj":{"a":1}}'
DECLARE @path NVARCHAR(MAX) = N'$.obj'
SELECT * FROM OPENJSON(@json, @path) with (a nvarchar(20))
GO
-- invalid json input
SELECT * FROM OPENJSON(N'{"a"') with (a nvarchar(20))
GO
-- test cases with invalid path params
select * from openjson(N'{"a":1}', 'strict $.a') with (a nvarchar(20))
go
select * from openjson(N'{"a":1}', '$.a') with (a nvarchar(20))
go
-- test array with WITH clause
select * from openjson(N'[1,2,3,4,null]') WITH (a_col varchar(20) '$');
GO
DECLARE @json NVARCHAR(MAX);
SET @json=N'[{"a":1},{"a":2}]';
SELECT * FROM OPENJSON(@json) with (name nvarchar(max) '$.a');
GO
DECLARE @json NVARCHAR(MAX);
SET @json=N'[{"a":1},{"a":2}]';
SELECT * FROM OPENJSON(@json, '$[0]') with (name nvarchar(max) '$.a');
GO
-- test case where with clause is split into multiple lines
select * from openjson(N'{"a":1}') with (
  a integer
);
GO
-- test output truncation
select * from openjson(N'{"a":"long string"}') with (a nvarchar(5));
GO
select * from openjson(N'{"a":123456}') with (a nvarchar(5));
GO
select * from openjson(N'{"a":null}') with (a nvarchar(2)); -- should return NULL
go
-- AS JSON
DECLARE @json NVARCHAR(MAX);
SET @json=N'[{"a":1},[1,2],"a"]';
SELECT * FROM OPENJSON(@json, '$') with (name nvarchar(max) '$' AS JSON);
GO
DECLARE @json NVARCHAR(MAX);
SET @json=N'[{"a":1},[1,2],"a"]';
SELECT * FROM OPENJSON(@json) with (name nvarchar(max) '$');
GO
-- Test invalid column type with AS JSON
SELECT * FROM OPENJSON(N'{"a":1}') WITH (obj nvarchar(20) '$' AS JSON);
GO
-- TODO fix case with no length specification
SELECT * from OPENJSON(N'{"a":1}') with (obj nvarchar '$' AS JSON);
GO
-- check lax/strict path
DECLARE @json NVARCHAR(MAX) = N'{"obj":{"a":1}}'
DECLARE @path NVARCHAR(MAX) = N'$.obj'
SELECT * FROM OPENJSON(@json, @path) with (a nvarchar(20), b nvarchar(20) 'lax $.b')
GO
DECLARE @json NVARCHAR(MAX) = N'{"obj":{"a":1}}'
DECLARE @path NVARCHAR(MAX) = N'$.obj'
SELECT * FROM OPENJSON(@json, @path) with (a nvarchar(20), b nvarchar(20) 'strict $.b')
GO
-- check non-ascii characters
select * from openjson(N'{"nonascii":"ちょまど@初詣おみくじ凶\n - description: ( *ﾟ▽ﾟ* っ)З腐女子！絵描き！| H26新卒文系SE (入社して4ヶ月目の8月にSIer(適応障害になった)を辞職し開発者に転職) | H26秋応用情報合格！| 自作bot (in PHP) chomado_bot | プログラミングガチ初心者\n"}') with 
(
  nonascii nvarchar(max)
)
go
-- check 2-byte characters
select * from openjson(N'{"a":"հձղճմ"}') with (a nvarchar(3));
go
-- test gaps in data
DECLARE @json NVARCHAR(MAX) = N'[{"b":1},{"a":2},{"a":3,"b":3},{}]'
SELECT * FROM OPENJSON(@json) WITH (a int, b int, o nvarchar(max) '$' AS JSON)
GO

-- comprehensive testing
DECLARE @json NVARCHAR(4000) = N'{ 
    "pets" : {
            "cats" : [
            { "id" : 1, "name" : "Fluffy", "sex" : "Female" },
            { "id" : 2, "name" : "Long Tail", "sex" : "Female" },
            { "id" : 3, "name" : "Scratch", "sex" : "Male" }
        ],
            "dogs" : [
            { "name" : "Fetch", "sex" : "Male" },
            { "name" : "Fluffy", "sex" : "Male" },
            { "name" : "Wag", "sex" : "Female" }
        ]
    }
}';

SELECT * FROM OPENJSON(@json, '$.pets.cats')
WITH  (
        [Cat Id]    int             '$.id',  
        "Cat Name"  varchar(60)     '$.name', 
        [Sex]       varchar(6)      '$.sex', 
        [Cats]      nvarchar(max)   '$' AS JSON   
    );
GO

DECLARE @json NVARCHAR(MAX);
SET @json = N'[
  {"id": 2, "info": {"name": "John", "surname": "Smith"}, "age": 25},
  {"id": 5, "info": {"name": "Jane", "surname": "Smith"}, "dob": "2005-11-04T12:00:00"}
]';

SELECT *
FROM OPENJSON(@json)
  WITH ( id INT 'strict $.id', firstName NVARCHAR(50) '$.info.name', lastName NVARCHAR(50) '$.info.surname', age INT, dateOfBirth DATETIME2 '$.dob' );
go
