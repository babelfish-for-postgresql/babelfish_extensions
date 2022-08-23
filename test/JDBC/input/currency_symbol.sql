-- Supported currency symbol by SQL it should also work with BABEL

-- dollar
select CAST($100.123 AS money);
GO
-- cent
select CAST(¢100.123 AS money);
GO
-- currency
select CAST(¤100.123 AS money);
GO
-- pound
select CAST(£100.123 AS money);
GO
-- yen
select CAST(¥100.123 AS money);
GO
-- bengali rupee mark
select CAST(৲100.123 AS money);
GO
-- bengali rupee sign
select CAST(৳100.123 AS money);
GO
-- thai baht
select CAST(฿100.123 AS money);
GO
-- khmer riel 
select CAST(៛100.123 AS money);
GO
-- euro currency
select CAST(₠100.123 AS money);
GO
-- colon sign 
select CAST(₡100.123 AS money);
GO
-- cruzeiro 
select CAST(₢100.123 AS money);
GO
-- french franc
select CAST(₣100.123 AS money);
GO
-- lira 
select CAST(₤100.123 AS money);
GO
-- mill
select CAST(₥100.123 AS money);
GO
-- naira
select CAST(₦100.123 AS money);
GO
-- peseta 
select CAST(₧100.123 AS money);
GO
-- rupee
select CAST(₨100.123 AS money);
GO
-- won
select CAST(₩100.123 AS money);
GO
-- new sheqel
select CAST(₪100.123 AS money);
GO
-- dong
select CAST(₫100.123 AS money);
GO
-- euro
select CAST(€100.123 AS money);
GO
-- kip
select CAST(₭100.123 AS money);
GO
-- tugrik
select CAST(₮100.123 AS money);
GO
-- drachma
select CAST(₯100.123 AS money);
GO
-- german penny
select CAST(₰100.123 AS money);
GO
-- peso 
select CAST(₱100.123 AS money);
GO
-- rial
select CAST(﷼100.123 AS money);
GO
-- small dollar 
select CAST(﹩100.123 AS money);
GO
-- fullwidth cent
select CAST(￠100.123 AS money);
GO
-- fullwidth dollar
select CAST(＄100.123 AS money);
GO
-- fullwidth pound
select CAST(￡100.123 AS money);
GO
-- fullwidth yen
select CAST(￥100.123 AS money);
GO
-- fullwidth won 
select CAST(￦100.123 AS money);
GO


-- Unsupported currency symbol by SQL it should throw error with BABEL

-- Indian Rupee
select CAST(₹100.123 AS money);
GO
-- Bitcoin
select CAST(₿100.123 AS money);
GO
-- gujarati rupee
select CAST(૱100.123 AS money);
GO
-- tamil rupee
select CAST(௹100.123 AS money);
GO
-- Azerbaijani manat
select CAST(₼100.123 AS money);
GO
-- SPESMILO
select CAST(₷100.123 AS money);
GO
-- AUSTRAL
select CAST(₳100.123 AS money);
GO
-- GUARANI
select CAST(₲100.123 AS money);
GO
-- Lari
select CAST(₾100.123 AS money);
GO


-- Currency symbol with qoute
select CAST('$100.123' AS money);
GO
-- cent
select CAST('¢100.123' AS money);
GO
-- currency
select CAST('¤100.123' AS money);
GO
-- pound
select CAST('£100.123' AS money);
GO
-- yen
select CAST('¥100.123' AS money);
GO
-- bengali rupee mark
select CAST('৲100.123' AS money);
GO
-- bengali rupee sign
select CAST('৳100.123' AS money);
GO
-- thai baht
select CAST('฿100.123' AS money);
GO
-- khmer riel 
select CAST('៛100.123' AS money);
GO
-- euro currency
select CAST('₠100.123' AS money);
GO
-- colon sign 
select CAST('₡100.123' AS money);
GO
-- cruzeiro 
select CAST('₢100.123' AS money);
GO
-- french franc
select CAST('₣100.123' AS money);
GO
-- lira 
select CAST('₤100.123' AS money);
GO
-- mill
select CAST('₥100.123' AS money);
GO
-- naira
select CAST('₦100.123' AS money);
GO
-- peseta 
select CAST('₧100.123' AS money);
GO
-- rupee
select CAST('₨100.123' AS money);
GO
-- won
select CAST('₩100.123' AS money);
GO
-- new sheqel
select CAST('₪100.123' AS money);
GO
-- dong
select CAST('₫100.123' AS money);
GO
-- euro
select CAST('€100.123' AS money);
GO
-- kip
select CAST('₭100.123' AS money);
GO
-- tugrik
select CAST('₮100.123' AS money);
GO
-- drachma
select CAST('₯100.123' AS money);
GO
-- german penny
select CAST('₰100.123' AS money);
GO
-- peso 
select CAST('₱100.123' AS money);
GO
-- rial
select CAST('﷼100.123' AS money);
GO
-- small dollar 
select CAST('﹩100.123' AS money);
GO
-- fullwidth cent
select CAST('￠100.123' AS money);
GO
-- fullwidth dollar
select CAST('＄100.123' AS money);
GO
-- fullwidth pound
select CAST('￡100.123' AS money);
GO
-- fullwidth yen
select CAST('￥100.123' AS money);
GO
-- fullwidth won 
select CAST('￦100.123' AS money);
GO

-- TODO: fix BABEL-704
-- Note: inside qoute it will treat any character as a currency symbol
-- if character is not a letter, digit and not equal to '+', '-', '.', '\0' 
-- Unsupported currency symbol by SQL it should throw error with BABEL
-- Indian Rupee
select CAST('₹100.123' AS money);
GO
-- Bitcoin
select CAST('₿100.123' AS money);
GO
-- gujarati rupee
select CAST('૱100.123' AS money);
GO
-- tamil rupee
select CAST('௹100.123' AS money);
GO
-- Azerbaijani manat
select CAST('₼100.123' AS money);
GO
-- SPESMILO
select CAST('₷100.123' AS money);
GO
-- AUSTRAL
select CAST('₳100.123' AS money);
GO
-- GUARANI
select CAST('₲100.123' AS money);
GO
-- Lari
select CAST('₾100.123' AS money);
GO

-- Currency Symbols as a datatype 
CREATE TABLE currency_symbol_t1(a money);
GO

INSERT INTO currency_symbol_t1 VALUES($111.123);
GO
INSERT INTO currency_symbol_t1 VALUES(¢112.123);
GO
INSERT INTO currency_symbol_t1 VALUES(¤113.123);
GO
INSERT INTO currency_symbol_t1 VALUES(฿114.123);
GO
INSERT INTO currency_symbol_t1 VALUES(₠115.123);
GO
INSERT INTO currency_symbol_t1 VALUES(₨116.123);
GO

SELECT * FROM currency_symbol_t1;
GO

-- following insert should throw error
INSERT INTO currency_symbol_t1 VALUES(₿118.123);
GO

DROP TABLE currency_symbol_t1;
GO


