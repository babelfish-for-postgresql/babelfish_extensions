CREATE TABLE upper_lower_dt (a VARCHAR(20), b NVARCHAR(24), c CHAR(20), d NCHAR(24))
GO
INSERT INTO upper_lower_dt(a,b,c,d) values(UPPER('Anikait '), LOWER('Agrawal '), LOWER('Anikait '), UPPER('Agrawal '))
GO
INSERT INTO upper_lower_dt(a,b,c,d) values(UPPER(' Anikait'), LOWER(' Agrawal'), LOWER(' Anikait'), UPPER(' Agrawal'))
GO
INSERT INTO upper_lower_dt(a,b,c,d) values(UPPER('   A'),LOWER(N'   🤣😃'),LOWER('   A'),UPPER(N'   🤣😃'))
GO
INSERT INTO upper_lower_dt(a,b,c,d) values(LOWER(' '),UPPER(' '),UPPER(' '),LOWER(' '))
GO
INSERT INTO upper_lower_dt(a,b,c,d) values(LOWER(' '),UPPER(N'😊😋😎😍😅😆'),UPPER(' '),LOWER(N'😊😋😎😍😅😆'))
GO
INSERT INTO upper_lower_dt(a,b,c,d) values(LOWER(''),UPPER(''),UPPER(''),LOWER(''))
GO
INSERT INTO upper_lower_dt(a,b,c,d) values(UPPER('a'),LOWER('A'),UPPER('a'),LOWER('A'))
GO
INSERT INTO upper_lower_dt(a,b,c,d) values(UPPER(NULL),LOWER(NULL),UPPER(NULL),LOWER(NULL))
GO
INSERT INTO upper_lower_dt(a, b, c, d) values(UPPER(N'比尔·拉'), LOWER(N'比尔·拉'), LOWER(N'比尔·拉'), UPPER(N'比尔·拉'))
GO
