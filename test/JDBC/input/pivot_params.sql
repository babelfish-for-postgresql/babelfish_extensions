-- PIVOT whose source query refers to T-SQL variables or parameters
CREATE TABLE pivot_param_sales (product VARCHAR(50), yr INT, sales INT);
INSERT INTO pivot_param_sales VALUES ('Apple', 2023, 100), ('Orange', 2023, 150), ('Apple', 2024, 120), ('Orange', 2024, 130), ('Pear', 2024, 7);
CREATE TABLE pivot_param_os (id INT, idtab INT, idcli INT);
INSERT INTO pivot_param_os VALUES (10, 1, 5), (11, 2, 19);
CREATE TABLE pivot_param_price (idtab INT, iditem INT, vlr NUMERIC(10,2));
INSERT INTO pivot_param_price VALUES (1, 1, 10.5), (1, 2, 20), (2, 1, 11), (2, 3, 33), (4, 1, 99), (4, 2, 98);
GO
-- no parameter
SELECT product, [2023], [2024] FROM (SELECT product, yr, sales FROM pivot_param_sales) AS s PIVOT (SUM(sales) FOR yr IN ([2023], [2024])) AS p ORDER BY product;
GO
-- sp_executesql parameter in the source query (#3532)
EXEC sp_executesql N'SELECT product, [2023], [2024] FROM (SELECT product, yr, sales FROM pivot_param_sales WHERE product = @product) AS s PIVOT (SUM(sales) FOR yr IN ([2023], [2024])) AS p', N'@product VARCHAR(50)', @product = 'Apple';
GO
-- parameter in the WHERE of a source query with JOIN and CASE, two executions
EXEC sp_executesql N'SELECT MAX(p.[1]) AS c1, MAX(p.[2]) AS c2, MAX(p.[3]) AS c3 FROM (SELECT pr.iditem, pr.vlr FROM pivot_param_os o JOIN pivot_param_price pr ON pr.idtab = CASE WHEN o.idcli IN (19, 42) THEN 4 ELSE o.idtab END WHERE o.id = @P1) AS res PIVOT (MAX(vlr) FOR res.iditem IN ([1],[2],[3])) AS p', N'@P1 INT', @P1 = 10;
GO
EXEC sp_executesql N'SELECT MAX(p.[1]) AS c1, MAX(p.[2]) AS c2, MAX(p.[3]) AS c3 FROM (SELECT pr.iditem, pr.vlr FROM pivot_param_os o JOIN pivot_param_price pr ON pr.idtab = CASE WHEN o.idcli IN (19, 42) THEN 4 ELSE o.idtab END WHERE o.id = @P1) AS res PIVOT (MAX(vlr) FOR res.iditem IN ([1],[2],[3])) AS p', N'@P1 INT', @P1 = 11;
GO
-- local variables, one of them used twice
DECLARE @lo INT = 2023, @min INT = 100;
SELECT product, [2023], [2024] FROM (SELECT product, yr, sales FROM pivot_param_sales WHERE yr >= @lo AND sales >= @min AND (sales > @min OR yr = @lo)) AS s PIVOT (SUM(sales) FOR yr IN ([2023], [2024])) AS p ORDER BY product;
GO
-- NULL parameter
EXEC sp_executesql N'SELECT product, [2023], [2024] FROM (SELECT product, yr, sales FROM pivot_param_sales WHERE product = @p OR @p IS NULL) AS s PIVOT (SUM(sales) FOR yr IN ([2023], [2024])) AS p ORDER BY product', N'@p VARCHAR(50)', @p = NULL;
GO
-- parameter inside a subquery of the source query
EXEC sp_executesql N'SELECT product, [2023], [2024] FROM (SELECT product, yr, sales FROM pivot_param_sales WHERE yr IN (SELECT yr FROM pivot_param_sales WHERE sales = @s)) AS s PIVOT (COUNT(sales) FOR yr IN ([2023], [2024])) AS p ORDER BY product', N'@s INT', @s = 7;
GO
-- procedure parameter, executed twice (cached plan)
CREATE PROCEDURE pivot_param_proc @y INT AS
SELECT product, [2023], [2024] FROM (SELECT product, yr, sales FROM pivot_param_sales WHERE yr = @y) AS s PIVOT (SUM(sales) FOR yr IN ([2023], [2024])) AS p ORDER BY product;
GO
EXEC pivot_param_proc 2023;
GO
EXEC pivot_param_proc 2024;
GO
DROP PROCEDURE pivot_param_proc;
GO
-- undeclared variable in the source query
SELECT product, [2023], [2024] FROM (SELECT product, yr, sales FROM pivot_param_sales WHERE yr = @undeclared) AS s PIVOT (SUM(sales) FOR yr IN ([2023], [2024])) AS p ORDER BY product;
GO
-- parameters of other data types
CREATE TABLE pivot_param_types (k INT, n NVARCHAR(20), d DATE, dt DATETIME, m DECIMAL(10,2), b BIT, v INT);
INSERT INTO pivot_param_types VALUES
    (1, N'ação', '2024-01-15', '2024-01-15 10:30:00', 10.25, 1, 5),
    (2, N'ação', '2024-02-20', '2024-02-20 08:00:00', 20.50, 0, 7),
    (1, N'outro', '2024-03-10', '2024-03-10 23:59:59', 30.75, 1, 11),
    (2, N'outro', '2024-03-11', '2024-03-11 00:00:00', 40.00, NULL, 13);
GO
EXEC sp_executesql N'SELECT [1], [2] FROM (SELECT k, v FROM pivot_param_types WHERE n = @n) AS s PIVOT (SUM(v) FOR k IN ([1], [2])) AS p', N'@n NVARCHAR(20)', @n = N'ação';
GO
EXEC sp_executesql N'SELECT [1], [2] FROM (SELECT k, v FROM pivot_param_types WHERE d >= @d) AS s PIVOT (SUM(v) FOR k IN ([1], [2])) AS p', N'@d DATE', @d = '2024-02-20';
GO
EXEC sp_executesql N'SELECT [1], [2] FROM (SELECT k, v FROM pivot_param_types WHERE dt < @dt) AS s PIVOT (SUM(v) FOR k IN ([1], [2])) AS p', N'@dt DATETIME', @dt = '2024-03-10 23:59:59';
GO
EXEC sp_executesql N'SELECT [1], [2] FROM (SELECT k, v FROM pivot_param_types WHERE m > @m) AS s PIVOT (SUM(v) FOR k IN ([1], [2])) AS p', N'@m DECIMAL(10,2)', @m = 20.50;
GO
EXEC sp_executesql N'SELECT [1], [2] FROM (SELECT k, v FROM pivot_param_types WHERE b = @b) AS s PIVOT (SUM(v) FOR k IN ([1], [2])) AS p', N'@b BIT', @b = 1;
GO
DECLARE @n NVARCHAR(20) = N'outro', @m DECIMAL(10,2) = 35, @b BIT = 1;
SELECT [1], [2] FROM (SELECT k, v FROM pivot_param_types WHERE n = @n AND (m < @m OR b = @b)) AS s PIVOT (SUM(v) FOR k IN ([1], [2])) AS p;
GO
-- parameter compared against columns with case-sensitive and case-insensitive collations
CREATE TABLE pivot_param_coll (k INT, cs VARCHAR(20) COLLATE Latin1_General_CS_AS, ci VARCHAR(20) COLLATE Latin1_General_CI_AS, v INT);
INSERT INTO pivot_param_coll VALUES (1, 'Apple', 'Apple', 1), (2, 'apple', 'apple', 2), (1, 'APPLE', 'APPLE', 4);
GO
EXEC sp_executesql N'SELECT [1], [2] FROM (SELECT k, v FROM pivot_param_coll WHERE cs = @p) AS s PIVOT (SUM(v) FOR k IN ([1], [2])) AS p', N'@p VARCHAR(20)', @p = 'apple';
GO
EXEC sp_executesql N'SELECT [1], [2] FROM (SELECT k, v FROM pivot_param_coll WHERE ci = @p) AS s PIVOT (SUM(v) FOR k IN ([1], [2])) AS p', N'@p VARCHAR(20)', @p = 'apple';
GO
-- inline table-valued function, called twice with different values
CREATE FUNCTION pivot_param_itvf (@y INT) RETURNS TABLE AS RETURN
    SELECT product, [2023], [2024] FROM (SELECT product, yr, sales FROM pivot_param_sales WHERE yr = @y) AS s PIVOT (SUM(sales) FOR yr IN ([2023], [2024])) AS p;
GO
SELECT * FROM pivot_param_itvf(2023) ORDER BY product;
GO
SELECT * FROM pivot_param_itvf(2024) ORDER BY product;
GO
-- multi-statement table-valued function, called twice with different values
CREATE FUNCTION pivot_param_mstvf (@min INT) RETURNS @r TABLE (product VARCHAR(50), y2023 INT, y2024 INT) AS
BEGIN
    INSERT INTO @r SELECT product, [2023], [2024] FROM (SELECT product, yr, sales FROM pivot_param_sales WHERE sales >= @min) AS s PIVOT (SUM(sales) FOR yr IN ([2023], [2024])) AS p;
    RETURN;
END;
GO
SELECT * FROM pivot_param_mstvf(100) ORDER BY product;
GO
SELECT * FROM pivot_param_mstvf(130) ORDER BY product;
GO
-- variable that changes between executions of the same statement in a loop
CREATE TABLE pivot_param_log (yr_filter INT, product VARCHAR(50), y2023 INT, y2024 INT);
GO
DECLARE @y INT = 2023;
WHILE @y <= 2024
BEGIN
    INSERT INTO pivot_param_log SELECT @y, product, [2023], [2024] FROM (SELECT product, yr, sales FROM pivot_param_sales WHERE yr = @y) AS s PIVOT (SUM(sales) FOR yr IN ([2023], [2024])) AS p;
    SET @y = @y + 1;
END;
SELECT * FROM pivot_param_log ORDER BY yr_filter, product;
GO
-- variable inside a trigger, fired twice
TRUNCATE TABLE pivot_param_log;
GO
CREATE TRIGGER pivot_param_trg ON pivot_param_sales AFTER INSERT AS
BEGIN
    DECLARE @y INT;
    SELECT @y = MAX(yr) FROM inserted;
    INSERT INTO pivot_param_log SELECT @y, product, [2023], [2024] FROM (SELECT product, yr, sales FROM pivot_param_sales WHERE yr = @y) AS s PIVOT (SUM(sales) FOR yr IN ([2023], [2024])) AS p;
END;
GO
INSERT INTO pivot_param_sales VALUES ('Kiwi', 2023, 3);
GO
INSERT INTO pivot_param_sales VALUES ('Kiwi', 2024, 4);
GO
SELECT * FROM pivot_param_log ORDER BY yr_filter, product;
GO
DROP TRIGGER pivot_param_trg;
GO
DROP FUNCTION pivot_param_itvf;
GO
DROP FUNCTION pivot_param_mstvf;
GO
DROP TABLE pivot_param_sales, pivot_param_os, pivot_param_price, pivot_param_types, pivot_param_coll, pivot_param_log;
GO
