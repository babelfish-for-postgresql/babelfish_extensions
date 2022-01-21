-- Test all numeric datatypes
SELECT square(CAST(12 AS int));
GO
SELECT square(CAST(12.4 AS float));
GO
SELECT square(CAST(12.4 AS real));
GO
SELECT square(CAST(12.4 AS bigint));
GO
SELECT square(CAST(12.4 AS smallint));
GO
SELECT square(CAST(12.4 AS tinyint));
GO
SELECT square(CAST('$12.4' AS money));
GO
SELECT square(CAST('$12.4' AS smallmoney));
GO
SELECT square(CAST(12.4 AS decimal));
GO
SELECT square(CAST(12.4 AS numeric));
GO

-- Test select from table
CREATE TABLE cubes(id int, side_length float(24));
GO
INSERT INTO cubes VALUES (1, 24.22);
INSERT INTO cubes VALUES (1, 145.76);
GO
SELECT id, square(side_length)*side_length AS volume FROM cubes;
GO
DROP TABLE cubes;
GO

-- Float overflow: expect error
SELECT square(CAST('-1.79E+308' AS float));
GO
SELECT square(CAST('-1.79E+153' AS float));
GO
SELECT square(NULL);
GO
