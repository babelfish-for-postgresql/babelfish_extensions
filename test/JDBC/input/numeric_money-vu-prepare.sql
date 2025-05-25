-- implicite casting
create table babel_5512_t1 (a smallmoney)
GO
insert into babel_5512_t1 values(6.43)
GO

CREATE TABLE babel_5512_t2 (Price SMALLMONEY)
INSERT INTO babel_5512_t2 VALUES (100.50), (200.75), (300.25)
GO

CREATE TABLE babel_5512_t3 (
    OrderID INT,
    Amount SMALLMONEY,
    CustomerType VARCHAR(10)
)
GO

INSERT INTO babel_5512_t3 VALUES 
(1, 100.50, 'PREMIUM'),
(2, 200.75, 'REGULAR'),
(3, 300.25, 'PREMIUM')
GO

-- Functions with smallmoney
CREATE FUNCTION babel_5512_f1
(
    @amount SMALLMONEY,
    @multiplier DECIMAL(10,2)
)
RETURNS SMALLMONEY
AS
BEGIN
    RETURN @amount * @multiplier
END
GO

-- Function with Multiple CASE statements
CREATE FUNCTION babel_5512_f2
(
    @price SMALLMONEY,
    @customerType VARCHAR(10)
)
RETURNS SMALLMONEY
AS
BEGIN
    RETURN CASE @customerType
        WHEN 'PREMIUM' THEN @price * CAST(0.8 AS SMALLMONEY)
        WHEN 'REGULAR' THEN @price * CAST(0.9 AS SMALLMONEY)
        ELSE @price
    END
END
GO

-- More Complex Stored Procedures
CREATE PROCEDURE babel_5512_p1
    @basePrice SMALLMONEY,
    @quantity INT,
    @discountPercent SMALLMONEY,
    @taxRate SMALLMONEY,
    @totalPrice SMALLMONEY OUTPUT
AS
BEGIN
    DECLARE @subtotal SMALLMONEY
    DECLARE @discount SMALLMONEY
    DECLARE @tax SMALLMONEY

    SET @subtotal = @basePrice * @quantity
    SET @discount = @subtotal * (@discountPercent / 100)
    SET @subtotal = @subtotal - @discount
    SET @tax = @subtotal * (@taxRate / 100)
    SET @totalPrice = @subtotal + @tax
END
GO

CREATE TYPE SmallMoneyType FROM SMALLMONEY
GO
CREATE TYPE MoneyType FROM MONEY
GO

-- Procedure with multiple UDT parameters
CREATE PROCEDURE babel_5512_p2  @sm1 SmallMoneyType, @sm2 SmallMoneyType, @m1 MoneyType, @m2 MoneyType, @resultSm SmallMoneyType OUTPUT, @resultM MoneyType OUTPUT AS BEGIN SET @resultSm = @sm1 + @sm2 SET @resultM = @m1 + @m2 END
GO

-- Tables with UDT Columns
CREATE TABLE babel_5512_t4
(
    ID INT PRIMARY KEY,
    SmallMoneyCol SmallMoneyType,
    MoneyCol MoneyType
)
GO

INSERT INTO babel_5512_t4 VALUES
(1, 100.50, 1000.5678),
(2, 200.75, 2000.1234),
(3, 300.25, 3000.9876)
GO

-- Stored Procedures
CREATE PROCEDURE babel_5512_p3 @basePrice money, @quantity money, @totalPrice money OUTPUT AS BEGIN SET @totalPrice = @basePrice + @quantity END
GO

CREATE PROCEDURE babel_5512_p4 @basePrice money, @quantity money, @totalPrice MoneyType OUTPUT AS BEGIN SET @totalPrice = @basePrice + @quantity END
GO

CREATE PROCEDURE babel_5512_p5 @basePrice MoneyType, @quantity MoneyType, @totalPrice MoneyType OUTPUT AS BEGIN SET @totalPrice = @basePrice + @quantity END
GO

CREATE TYPE babel_5512_varcharudt FROM varchar
GO

-- varchar
CREATE PROCEDURE babel_5512_p4_varchar @basePrice varchar, @quantity varchar, @totalPrice babel_5512_varcharudt OUTPUT AS BEGIN SET @totalPrice = @basePrice + @quantity END
GO

create type babel_5512_decimaludt FROM decimal
GO

-- decimal
CREATE PROCEDURE babel_5512_p4_dec @basePrice decimal, @quantity decimal, @totalPrice babel_5512_decimaludt OUTPUT AS BEGIN SET @totalPrice = @basePrice + @quantity END
GO

-- scale/precision in case of aggregate
CREATE PROCEDURE babel_5512_get_column_info_p1 @table_name text AS BEGIN SELECT c.[name] AS column_name, t.[name] AS [type_name], c.[max_length], c.[precision],c.[scale] FROM sys.columns c INNER JOIN sys.types t ON c.user_type_id = t.user_type_id WHERE object_id = object_id(@table_name) ORDER BY c.[name];
END
GO

CREATE TABLE babel_5512_t5 ( ID INT IDENTITY(1,1), Amount Int, a_tiny tinyint, b_smallint smallint, c_big bigint, d_fl float, e_real real, f_mon money, g_smallmoney smallmoney, h_smallmoneyUDT SmallMoneyType, i_moneyudt MoneyType);
GO

SELECT SUM(Amount) * 1.1 AS TotalWithMarkup, sum(a_tiny) * 1.1 as mul1, sum(b_smallint) * 1.1 as mul2, sum(c_big) * 1.1 as mul3, sum(d_fl) * 1.1 as mul4, sum(e_real) * 1.1 as mul5, sum(f_mon) * 1.1 as mul6, sum(g_smallmoney) * 1.1 as mul7 , sum(h_smallmoneyUDT) * 1.1 as mul8udtsmallmoney, sum(i_moneyudt) * 1.1 as mul8moneyudt INTO babel_5512_t6 FROM babel_5512_t5;
GO
