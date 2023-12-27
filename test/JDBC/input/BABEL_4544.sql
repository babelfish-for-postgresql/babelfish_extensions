SELECT DATALENGTH(CAST(0X61626364 AS BINARY(3)))
GO
SELECT DATALENGTH(CAST(0X6162 AS BINARY(3)))
GO
SELECT CAST(0x6161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161 AS BINARY)
GO
SELECT CAST(0x6161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161 AS BINARY(51))
GO
SELECT DATALENGTH(CAST(CAST(0x11 AS VARBINARY(5)) AS BINARY(5))), CAST(CAST(0x11 AS VARBINARY(5)) AS BINARY(5))
GO
SELECT DATALENGTH(CAST(CAST(0x111213141516 AS VARBINARY(5)) AS BINARY(5))), CAST(CAST(0x111213141516 AS VARBINARY(5)) AS BINARY(5))
GO
SELECT DATALENGTH(CAST(CAST(0x11 AS BINARY(5)) AS VARBINARY(5))), CAST(CAST(0x11 AS BINARY(5)) AS VARBINARY(5))
GO
SELECT DATALENGTH(CAST(CAST(0x111213141516 AS BINARY(5)) AS VARBINARY(5))), CAST(CAST(0x111213141516 AS BINARY(5)) AS VARBINARY(5))
GO

CREATE TABLE babel_4544_t (id BINARY(5))
GO

INSERT INTO babel_4544_t VALUES (0x65), (0x656667)
GO
INSERT INTO babel_4544_t VALUES (0x6566676869707172)
GO
INSERT INTO babel_4544_t VALUES (CAST(0x6566676869707172 AS VARBINARY(6)))
GO
INSERT INTO babel_4544_t VALUES ('aa')
GO
INSERT INTO babel_4544_t VALUES (CAST('aaaaaa' AS VARBINARY))
GO
INSERT INTO babel_4544_t VALUES (CAST('aaa' AS VARBINARY))
GO
INSERT INTO babel_4544_t VALUES (CAST(0x65 AS VARBINARY)), (CAST(0x6564 AS VARBINARY(5))), (CAST(0x6566676869707172 AS VARBINARY(4))), (CAST(0x65666768 AS VARBINARY(6)))
GO

SELECT *, DATALENGTH(id) FROM babel_4544_t
GO

DROP TABLE babel_4544_t
GO

-- default length should be 1
DECLARE @A VARBINARY = 0x0123456789012345678901234567890123456789
SELECT @A, DATALENGTH(@A)
SELECT DATALENGTH(CAST(@A as BINARY(50))), CAST(@A as BINARY(50)), CAST(@A as VARBINARY(60))
GO

DECLARE @A BINARY = 0x0123456789012345678901234567890123456789
SELECT @A, DATALENGTH(@A)
SELECT DATALENGTH(CAST(@A as BINARY(50))), CAST(@A as BINARY(50))
GO

DECLARE @A BINARY = 0x012345678901234567890123456789012345678901234567890123456789
SELECT DATALENGTH(@A), @A
SELECT DATALENGTH(CAST(@A as BINARY(50))), CAST(@A as BINARY(50))
GO

DECLARE @A BINARY = 0x01234567890123456789012345678901234567890123456789012345678901234567890123456789
SELECT DATALENGTH(@A), @A
SELECT DATALENGTH(CAST(@A as BINARY(50))), CAST(@A as BINARY(50))
GO

DECLARE @A BINARY(10) = 0x012345678901234567890123456789
SELECT DATALENGTH(@A), @A
SELECT DATALENGTH(CAST(@A as BINARY(50))), CAST(@A as BINARY(50))
GO

DECLARE @A BINARY(10) = 0x01234567890123456789
SELECT DATALENGTH(@A), @A
SELECT DATALENGTH(CAST(@A as BINARY(50))), CAST(@A as BINARY(50))
GO

DECLARE @A BINARY(10) = 0x0123456789012345678901234567890123456789
SELECT DATALENGTH(@A), @A
SELECT DATALENGTH(CAST(@A as BINARY(50))), CAST(@A as BINARY(50))
GO

SELECT DATALENGTH(CAST(CAST(0x11 AS VARBINARY(MAX)) AS BINARY(5))), CAST(CAST(0x11 AS VARBINARY(MAX)) AS BINARY(5))
GO
SELECT DATALENGTH(CAST(CAST(0x111213141516 AS VARBINARY(MAX)) AS BINARY(5))), CAST(CAST(0x111213141516 AS VARBINARY(MAX)) AS BINARY(5))
GO
SELECT DATALENGTH(CAST(CAST(0x11 AS BINARY(5)) AS VARBINARY(MAX))), CAST(CAST(0x11 AS BINARY(5)) AS VARBINARY(MAX))
GO
SELECT DATALENGTH(CAST(CAST(0x111213141516 AS BINARY(5)) AS VARBINARY(MAX))), CAST(CAST(0x111213141516 AS BINARY(5)) AS VARBINARY(MAX))
GO

SELECT DATALENGTH(CAST(CAST(NULL AS VARBINARY(MAX)) AS BINARY(5))), CAST(CAST(NULL AS VARBINARY(MAX)) AS BINARY(5))
GO
SELECT DATALENGTH(CAST(CAST(NULL AS VARBINARY(MAX)) AS BINARY(5))), CAST(CAST(NULL AS VARBINARY(MAX)) AS BINARY(5))
GO
SELECT DATALENGTH(CAST(CAST(NULL AS BINARY(5)) AS VARBINARY(MAX))), CAST(CAST(NULL AS BINARY(5)) AS VARBINARY(MAX))
GO
SELECT DATALENGTH(CAST(CAST(NULL AS BINARY(5)) AS VARBINARY(MAX))), CAST(CAST(NULL AS BINARY(5)) AS VARBINARY(MAX))
GO
