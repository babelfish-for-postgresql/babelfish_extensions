-- Expect error
CREATE PROCEDURE openjson_3820_p1
AS
BEGIN
    SELECT * FROM OPENJSON('{}') WITH(field int 'strict$.field')
END;
GO

-- Expect empty result and no error
CREATE PROCEDURE openjson_3820_p2
AS
BEGIN
    DECLARE @json_p2 NVarChar(max)=N'{"someKey" : "someValue"}';
    SELECT * from OPENJSON(@json_p2,'$.somePathWhichDoesNotExists') WITH (id VARCHAR(100) '$')
END;
GO

-- Expect an error for no path
CREATE PROCEDURE openjson_3820_p3
AS
BEGIN
    DECLARE @json_p3 NVarChar(max)=N'{"someKey" : "someValue"}';
    SELECT * from OPENJSON(@json_p3,'strict $.somePathWhichDoesNotExists') WITH (id VARCHAR(100) '$')
END;
GO

-- Expect result
CREATE PROCEDURE openjson_3820_p4
AS
BEGIN
    DECLARE @json_p4 NVarChar(max)=N'{"obj":{"a":1}}';
    SELECT * FROM OPENJSON(@json_p4, 'strict $.obj') WITH (a char(20))
END;
GO

-- Expect error in strict mode
CREATE PROCEDURE openjson_3820_p5
AS
BEGIN
    SELECT * FROM OPENJSON(N'[{"Item": {"Price":2024.9940}}]') WITH(field int 'strict $.field')
END;
GO

-- Expect empty result because path does not exist
CREATE PROCEDURE openjson_3820_p6
AS
BEGIN
    DECLARE @json_p6 NVARCHAR(4000) = N'{"to":{"sub-object":["en-GB", "en-UK","de-AT","es-AR","sr-Cyrl"]}}';
    SELECT [key], value FROM OPENJSON(@json_p6,'lax$.path.to."sub-object"')
END;
GO

-- Expect proper json result
CREATE PROCEDURE openjson_3820_p7
AS
BEGIN
    DECLARE @json_p7 NVARCHAR(4000) = N'{"path": {"to":{"sub-object":["en-GB", "en-UK","de-AT","es-AR","sr-Cyrl"]}}}'; 
    SELECT [key], value FROM OPENJSON(@json_p7,'strict $.path.to."sub-object"')
END;
GO

-- Expect proper json result
CREATE PROCEDURE openjson_3820_p8
AS
BEGIN
    DECLARE @json_p8 NVARCHAR(4000) = N'{"path": {"to":{"sub-object":["en-GB", "en-UK","de-AT","es-AR","sr-Cyrl"]}}}'; 
    SELECT [key], value FROM OPENJSON(@json_p8,'strict$.path.to."sub-object"')
END;
GO

-- Expect error for incorrect path
CREATE PROCEDURE openjson_3820_p9
AS
BEGIN
    DECLARE @json_p9 NVARCHAR(4000) = N'{"to":{"sub-object":["en-GB", "en-UK","de-AT","es-AR","sr-Cyrl"]}}'; 
    SELECT [key], value FROM OPENJSON(@json_p9,'strict $.path.to."sub-object"')
END;
GO

-- Expect empty result for non existent path
CREATE PROCEDURE openjson_3820_p10
AS
BEGIN
    DECLARE @json_p10 NVARCHAR(4000) = N'{"to":{"sub-object":["en-GB", "en-UK","de-AT","es-AR","sr-Cyrl"]}}'; 
    SELECT [key], value FROM OPENJSON(@json_p10,'$.path.to."sub-object"')
END;
GO

-- Expect error in strict mode
CREATE PROCEDURE openjson_3820_p11
AS
BEGIN
    SELECT * FROM OPENJSON(N'{}') WITH(field int 'strict $.field')
END;
GO