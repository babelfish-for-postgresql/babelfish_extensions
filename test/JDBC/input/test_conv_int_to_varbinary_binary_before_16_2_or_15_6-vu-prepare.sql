CREATE VIEW int_to_varbinary_v1
AS SELECT convert(varbinary(2), 38)
GO

CREATE VIEW int_to_varbinary_v2
AS SELECT try_convert(varbinary(3), 38)
GO

CREATE VIEW int_to_varbinary_v3
AS SELECT try_convert(varbinary(max), 38)
GO

CREATE VIEW int_to_binary_v1
AS SELECT convert(binary(2), 38)
GO

CREATE VIEW int_to_binary_v2
AS SELECT try_convert(binary(3), 38)
GO

CREATE FUNCTION int_to_varbinary_f1()
RETURNS sys.varbinary(2)
AS
BEGIN
    RETURN convert(varbinary(2), 38)
END
GO

CREATE FUNCTION int_to_varbinary_f2()
RETURNS sys.varbinary(3)
AS
BEGIN
    RETURN try_convert(varbinary(3), 38)
END
GO

CREATE FUNCTION int_to_varbinary_f3()
RETURNS sys.varbinary(max)
AS
BEGIN
    RETURN try_convert(varbinary(max), 38)
END
GO

CREATE FUNCTION int_to_binary_f1()
RETURNS sys.varbinary(2)
AS
BEGIN
    RETURN convert(binary(2), 38)
END
GO

CREATE FUNCTION int_to_binary_f2()
RETURNS sys.varbinary(3)
AS
BEGIN
    RETURN try_convert(binary(3), 38)
END
GO

CREATE PROCEDURE int_to_varbinary_p1
AS
BEGIN
    SELECT convert(varbinary(2), 38)
END
GO

CREATE PROCEDURE int_to_varbinary_p2
AS
BEGIN
    SELECT try_convert(varbinary(3), 38)
END
GO

CREATE PROCEDURE int_to_varbinary_p3
AS
BEGIN
    SELECT try_convert(varbinary(max), 38)
END
GO

CREATE PROCEDURE int_to_binary_p1
AS
BEGIN
    SELECT convert(binary(2), 38)
END
GO

CREATE PROCEDURE int_to_binary_p2
AS
BEGIN
    SELECT try_convert(binary(3), 38)
END
GO
