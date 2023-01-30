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

