-- Create dependant objects
CREATE VIEW fn_varbintohexsubstring_vu_prepare_view AS
SELECT sys.fn_varbintohexsubstring(1,0x1234, 1, 4)
GO

CREATE PROC fn_varbintohexsubstring_vu_prepare_proc AS
SELECT sys.fn_varbintohexsubstring(1,0x1234, 1, 4)
GO

CREATE FUNCTION fn_varbintohexsubstring_vu_prepare_func()
RETURNS nvarchar(128)
AS
BEGIN
RETURN sys.fn_varbintohexsubstring(1,0x1234, 1, 4)
END
GO

CREATE TABLE babel_5654_t1 (set_prefix INT,
                            expression sys.varbinary(MAX),
                            start_offset INT,
                            substr_length INT,
                            CHECK (sys.fn_varbintohexsubstring(set_prefix, expression, start_offset, substr_length) != NULL));
GO

INSERT INTO babel_5654_t1 VALUES (0,0x123486534659789876435656,1,4)
GO

CREATE TABLE babel_5654_t2 (setprefix INT,
                            expression sys.varbinary(MAX),
                            startoffset INT,
                            substrlength INT,
                            [varbintohexsubstring] AS sys.fn_varbintohexsubstring(setprefix, expression, startoffset, substrlength));
GO

INSERT INTO babel_5654_t2 VALUES (0,0x3486534659789876435656,1,4)
GO
