CREATE TABLE babel_5899_babel_5899_t1(
        numeric_col NUMERIC(15,5),
        money_col MONEY,
        smallmoney_col SMALLMONEY,
        bigint_col BIGINT,
        int_col INT,
        smallint_col SMALLINT,
        tinyint_col TINYINT,
        bit_col BIT,
        char_col CHAR(10),
        varchar_col VARCHAR(50),
        nvarchar_col NVARCHAR(50),
        text_col TEXT,
        ntext_col NTEXT,
        binary_col BINARY(10),
        varbinary_col VARBINARY(50)
)
GO

INSERT INTO babel_5899_t1 VALUES
(123.45678, 922337203685477.5807, 214748.3647, 9223372036854775807,  2147483647, 32767, 255, 1, 'CHAR10', 'Variable text', N'Unicode text', 'Large text field', N'Large unicode text', 0x0123456789, 0x0123456789AB);
GO
INSERT INTO babel_5899_t1 VALUES
(987.65432, -922337203685477.5808, -214748.3648, -9223372036854775808, -2147483648, -32768, 0, 0, 'CHAR20', 'Another variable text', N'Another unicode text', 'Another large text field', N'Another large unicode text', 0xABCDEF1234, 0xABCDEF1234567890);
GO

INSERT INTO babel_5899_t1 VALUES
(0.00001, 0.01, 0.01, 1, 1, 1, 1, 0, 'CHAR30', 'Short text', N'Short unicode text', 'Short large text field', N'Short large unicode text', 0x0000000000, 0x000000);
GO

INSERT INTO babel_5899_t1 VALUES
(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
GO

CREATE TYPE babel_5899_MoneyUDT FROM MONEY;
GO
CREATE TYPE babel_5899_SmallMoneyUDT FROM SMALLMONEY;
GO