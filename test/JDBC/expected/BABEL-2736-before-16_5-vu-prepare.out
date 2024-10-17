-- View to test binary conversion with style 0 (default)
CREATE VIEW BABEL_BINARY_vu_prepare_v1 AS 
(SELECT CONVERT(BINARY(10), '0904D00034', 0));
GO

-- Procedure to test binary conversion with style 0 (default)
CREATE PROCEDURE BABEL_BINARY_vu_prepare_p1 AS 
(SELECT CONVERT(BINARY(10), '0904D00034', 0));
GO

-- Function to test binary conversion with style 0 (default)
CREATE FUNCTION BABEL_BINARY_vu_prepare_f1()
RETURNS VARBINARY(10) AS
BEGIN
    RETURN (SELECT CONVERT(BINARY(10), '0904D00034', 0));
END
GO

-- View to test binary conversion with style 1 (with '0x' prefix)
CREATE VIEW BABEL_BINARY_vu_prepare_v2 AS 
(SELECT CONVERT(BINARY(10), '0x0904D00034', 1));
GO

-- Procedure to test binary conversion with style 1 (with '0x' prefix)
CREATE PROCEDURE BABEL_BINARY_vu_prepare_p2 AS 
(SELECT CONVERT(BINARY(10), '0x0904D00034', 1));
GO

-- Function to test binary conversion with style 1 (with '0x' prefix)
CREATE FUNCTION BABEL_BINARY_vu_prepare_f2()
RETURNS VARBINARY(10) AS
BEGIN
    RETURN (SELECT CONVERT(BINARY(10), '0x0904D00034', 1));
END
GO

-- View to test binary conversion with style 2 
CREATE VIEW BABEL_BINARY_vu_prepare_v3 AS 
(SELECT CONVERT(BINARY(10), '0904D00034', 2));
GO

-- Procedure to test binary conversion with style 2 
CREATE PROCEDURE BABEL_BINARY_vu_prepare_p3 AS 
(SELECT CONVERT(BINARY(10), '0904D00034', 2));
GO

-- Function to test binary conversion with style 2 
CREATE FUNCTION BABEL_BINARY_vu_prepare_f3()
RETURNS VARBINARY(10) AS
BEGIN
    RETURN (SELECT CONVERT(BINARY(10), '0904D00034', 2));
END
GO

-- View to test VARBINARY conversion
CREATE VIEW BABEL_BINARY_vu_prepare_v4 AS 
(SELECT CONVERT(VARBINARY(10), '0904D00034', 0));
GO

-- Procedure to test VARBINARY conversion
CREATE PROCEDURE BABEL_BINARY_vu_prepare_p4 AS 
(SELECT CONVERT(VARBINARY(10), '0904D00034', 0));
GO

-- Function to test VARBINARY conversion
CREATE FUNCTION BABEL_BINARY_vu_prepare_f4()
RETURNS VARBINARY(10) AS
BEGIN
    RETURN (SELECT CONVERT(VARBINARY(10), '0904D00034', 0));
END
GO

-- Procedure to test invalid style (should cause an error)
CREATE PROCEDURE BABEL_BINARY_vu_prepare_p5 AS 
(SELECT CONVERT(BINARY(10), '0904D00034', 3));
GO

-- Function to test NULL input
CREATE FUNCTION BABEL_BINARY_vu_prepare_f5()
RETURNS VARBINARY(10) AS
BEGIN
    RETURN (SELECT CONVERT(BINARY(10), NULL, 0));
END
GO
