-- NOT APPEND
--NOT NULL, LAX, KP  
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.name','Mike');
GO

--NOT NULL, STRICT, KP
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','strict       $.name     ','Mike');
GO

--NOT NULL, LAX, KNP  
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"]}','$.surname','Smith');
GO
--NOT NULL, STRICT, KNP
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"]}','strict $.surname','Smith');
GO
--NULL, LAX, KP
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','$.skills',NULL);
GO
--NULL, STRICT, KP
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','strict $.name',NULL);
GO
--NULL, LAX, KNP
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','$.k',NULL);
GO
--NULL, STRICT, KNP
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','strict $.k',NULL);
GO

--APPEND
--NOT NULL, LAX, KP  
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append $.name','Mike');
GO
--NOT NULL, STRICT, KP
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append strict $.name','Mike');
GO
--NOT NULL, LAX, KNP  
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"]}','append $.surname','Smith');
GO
--NOT NULL, STRICT, KNP
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"]}','append strict $.surname','Smith');
GO

--NOT NULL, LAX, KP, ARRAY 
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append $.skills','Azure');
GO

--NOT NULL, STRICT, KP, ARRAY 
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append strict $.skills','Azure');
GO

--NULL, LAX, KP
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','append $.skills',NULL);
GO
--NULL, STRICT, KP
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','append strict $.skills',NULL);
GO
--NULL, LAX, KNP
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','append $.k',NULL);
GO
--NULL, STRICT, KNP
SELECT JSON_MODIFY('{"name":"Mike","skills":["C#","SQL"],"surname":"Smith"}','append strict $.k',NULL);
GO

--NULL, LAX, KP, NOT ARRAY 
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append $.name',NULL);
GO

--NULL, STRICT, KP, NOT ARRAY 
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append strict $.name',NULL);
GO


--Cases to test Case-sensitive and extra spaces

-- Leading and trailing spaces
SELECT JSON_MODIFY('{"id": 1,"tags": [
      "sint",
      "sit",
      "nisi",
      "ullamco",
      "consectetur",
      "eu",
      "voluptate"
    ],
    "friends": [
      {
        "id": 0,
        "name": "Kasey Oneil"
      },
      {
        "id": 1,
        "name": "Guerrero Leon"
      },
      {
        "id": 2,
        "name": "Meadows Schneider"
      }
    ]}','    append     strict     $.friends    ',NULL);
GO

-- Case-sensitive 
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','strIct $.name','James');
GO

SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','  aPpend    Strict    $.skills   ',NULL);
GO

SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','  and    strict    $.skills   ',NULL);
GO


--To test Multi-function call query
SELECT JSON_MODIFY(JSON_MODIFY(JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.name','Mike'),'$.surname','Smith'),'append $.skills','Azure');
GO

SELECT JSON_MODIFY(JSON_MODIFY('{"price":49.99}','$.Price',CAST(JSON_VALUE('{"price":49.99}','$.price') AS NUMERIC(4,2))),'$.price',NULL);
GO

--To test on array
SELECT JSON_MODIFY('[{"name":"John","skills":["C#","SQL"]},"b","temp"]','strict $[0].skills[1]',NULL);
GO

SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.skills[0]','Azure');
GO
