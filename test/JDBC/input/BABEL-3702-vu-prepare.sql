-- Returns TABLE (simple) or SETOF RECORD (with)
CREATE VIEW BABEL_3702_vu_prepare_v1 as (select * from OPENJSON(N'{"a":null,"b":"a","c":1,"d":true,"e":[1,2],"f":{"name":"John"}}'));
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p1 as (select * from OPENJSON(N'{"a":null,"b":"a","c":1,"d":true,"e":[1,2],"f":{"name":"John"}}'));
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p2
AS
BEGIN
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
    SELECT * FROM OpenJson(@jsonvar)
END;
GO

CREATE VIEW BABEL_3702_vu_prepare_v3 as (SELECT [key], value FROM OPENJSON(N'{"path":{"to":{"sub-object":["en-GB", "en-UK","de-AT","es-AR","sr-Cyrl"]}}}','$.path.to."sub-object"'));
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p3 as (SELECT [key], value FROM OPENJSON(N'{"path":{"to":{"sub-object":["en-GB", "en-UK","de-AT","es-AR","sr-Cyrl"]}}}','$.path.to."sub-object"'));
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p4 as (select * from openjson(N'{"obj":{"a":1}}', 'lax $.a'));
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p5 as (select * from openjson(N'{"obj":{"a":1}}', 'strict $.a'));
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p6
AS
BEGIN
    DECLARE @json NVARCHAR(MAX) = N'{"obj":{"a":1}}'
    DECLARE @path NVARCHAR(MAX) = N'$.obj'
    SELECT * FROM OPENJSON(@json, @path) with (a nvarchar(20))
END;
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p7 as (select * from openjson(N'{"a":"long string"}') with (a nvarchar(5)));
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p8
AS
BEGIN
    DECLARE @json NVARCHAR(MAX);
    SET @json=N'[{"a":1},[1,2],"a"]';
    SELECT * FROM OPENJSON(@json, '$') with (name nvarchar(max) '$' AS JSON)
END;
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p9 as (SELECT * FROM OPENJSON(N'{"a":1}') WITH (obj nvarchar(20) '$' AS JSON));
GO

CREATE PROCEDURE BABEL_3702_vu_prepare_p10
AS
BEGIN
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
        )
END;
GO