-- Create dependant objects
CREATE VIEW fn_varbintohexstr_vu_prepare_view AS
SELECT sys.fn_varbintohexstr(0x48656c6c6faefaef)
GO

CREATE PROC fn_varbintohexstr_vu_prepare_proc AS
SELECT sys.fn_varbintohexstr(0x48656c6c6faefaef)
GO

CREATE FUNCTION fn_varbintohexstr_vu_prepare_func()
RETURNS nvarchar(128)
AS
BEGIN
RETURN sys.fn_varbintohexstr(0x48656c6c6faefaef)
END
GO

CREATE TABLE BABEL_6216_t1 (
    col1 sys.varbinary(MAX),
    col2 decimal,
    col3 numeric,
    col4 float,
    col5 real,
    col6 money,
    col7 smallmoney,
    col8 bit
);
GO

INSERT INTO BABEL_6216_t1 VALUES (0x48656c6c6f, 123.45, 678.90, 123.456, 78.9, $100.50, $50.25, 1);
GO

INSERT INTO BABEL_6216_t1 VALUES (NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
GO

CREATE TYPE babel_6216_udt FROM sys.varbinary(max);
GO
