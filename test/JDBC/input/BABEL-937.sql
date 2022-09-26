-- Not Append
--NOT NULL, LAX, KP  
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.name','Mike');
GO

--NOT NULL, STRICT, KP
SELECT JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','strict $.name','Mike');
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

--Append
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


-- Temporary

-- select JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.name','Smith');
-- go

-- select JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.skills[0]','Azure');
-- go

-- select JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','strict $.name','Smith');
-- go

-- select JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append strict $.skills','Azure');
-- go

-- select JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','append $.skills','Azure');
-- go

-- select JSON_MODIFY('{"name":"John","skills":["C#","SQL"]}','$.skills[0]',NULL);
-- go

