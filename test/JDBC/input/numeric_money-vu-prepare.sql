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
-- TODO : failing after UDT fix
-- CREATE PROCEDURE babel_5512_p2  @sm1 SmallMoneyType, @sm2 SmallMoneyType, @m1 MoneyType, @m2 MoneyType, @resultSm SmallMoneyType OUTPUT, @resultM MoneyType OUTPUT AS BEGIN SET @resultSm = @sm1 + @sm2 SET @resultM = @m1 + @m2 END
-- GO

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
