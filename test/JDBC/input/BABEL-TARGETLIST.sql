CREATE SCHEMA ts;
CREATE TABLE ts.t1 (ABC text, b varchar(20), c char(4), Xyz int, [Delimited] int, [Square Brackets] bigint);
GO

SELECT * from ts.t1;
SELECT xyz, XYZ, xYz, xyz ColName, xYz AS ColName, [Square Brackets], [Delimited], [DeLIMITed] from ts.t1;
GO

SELECT xyz AS [WOW! This is a very very long identifier that will get truncated with a uniquifying suffix by Babelfish] from ts.t1;
GO
SELECT xyz AS [WOW! This is a very very long identifier that will get truncated with a uniquifying suffix by Babelfish - with extra stuff at the end] from ts.t1;
GO

DROP TABLE ts.t1;
DROP SCHEMA ts;
GO
