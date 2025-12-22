CREATE PROCEDURE sp_datatype_info_100_vu_prepare_p1
AS
BEGIN
    EXEC sys.sp_datatype_info_100;
END;
GO

CREATE PROCEDURE sp_datatype_info_100_vu_prepare_p2
    @data_type int = 0
AS
BEGIN
    EXEC sys.sp_datatype_info_100 @data_type = @data_type;
END;
GO

CREATE PROCEDURE sp_datatype_info_100_vu_prepare_p3
    @data_type int = 0,
    @odbcver smallint = 2
AS
BEGIN
    EXEC sys.sp_datatype_info_100 @data_type = @data_type, @odbcver = @odbcver;
END;
GO

CREATE PROCEDURE sp_datatype_info_100_vu_prepare_int_types
AS
BEGIN
    EXEC sys.sp_datatype_info_100 @data_type = 4;
    EXEC sys.sp_datatype_info_100 @data_type = -5;
    EXEC sys.sp_datatype_info_100 @data_type = 5;
    EXEC sys.sp_datatype_info_100 @data_type = -6;
END;
GO

CREATE PROCEDURE sp_datatype_info_100_vu_prepare_string_types
AS
BEGIN
    EXEC sys.sp_datatype_info_100 @data_type = 1;
    EXEC sys.sp_datatype_info_100 @data_type = 12;
    EXEC sys.sp_datatype_info_100 @data_type = -1;
    EXEC sys.sp_datatype_info_100 @data_type = -8;
    EXEC sys.sp_datatype_info_100 @data_type = -9;
    EXEC sys.sp_datatype_info_100 @data_type = -10;
END;
GO

CREATE PROCEDURE sp_datatype_info_100_vu_prepare_binary_types
AS
BEGIN
    EXEC sys.sp_datatype_info_100 @data_type = -2;
    EXEC sys.sp_datatype_info_100 @data_type = -3;
    EXEC sys.sp_datatype_info_100 @data_type = -4;
END;
GO

CREATE PROCEDURE sp_datatype_info_100_vu_prepare_datetime_types
AS
BEGIN
    EXEC sys.sp_datatype_info_100 @data_type = 9;
    EXEC sys.sp_datatype_info_100 @data_type = 11;
    EXEC sys.sp_datatype_info_100 @data_type = -154;
    EXEC sys.sp_datatype_info_100 @data_type = -155;
END;
GO

CREATE PROCEDURE sp_datatype_info_100_vu_prepare_decimal_types
AS
BEGIN
    EXEC sys.sp_datatype_info_100 @data_type = 3;
    EXEC sys.sp_datatype_info_100 @data_type = 2;
END;
GO

CREATE PROCEDURE sp_datatype_info_100_vu_prepare_float_types
AS
BEGIN
    EXEC sys.sp_datatype_info_100 @data_type = 6;
    EXEC sys.sp_datatype_info_100 @data_type = 7;
END;
GO

CREATE PROCEDURE sp_datatype_info_100_vu_prepare_special_types
AS
BEGIN
    EXEC sys.sp_datatype_info_100 @data_type = -7;
    EXEC sys.sp_datatype_info_100 @data_type = -11;
    EXEC sys.sp_datatype_info_100 @data_type = -150;
    EXEC sys.sp_datatype_info_100 @data_type = -152;
END;
GO

CREATE PROCEDURE sp_datatype_info_100_vu_prepare_odbcver
AS
BEGIN
    EXEC sys.sp_datatype_info_100 @data_type = 0, @odbcver = 2;
    EXEC sys.sp_datatype_info_100 @data_type = 4, @odbcver = 2;
END;
GO

CREATE PROCEDURE sp_datatype_info_100_vu_prepare_edge_cases
AS
BEGIN
    EXEC sys.sp_datatype_info_100 @data_type = 9999;
    EXEC sys.sp_datatype_info_100 @data_type = -9999;
    EXEC sys.sp_datatype_info_100 @data_type = 0;
END;
GO

CREATE PROCEDURE sp_datatype_info_vu_prepare_p1
AS
BEGIN
    EXEC sys.sp_datatype_info;
END;
GO

CREATE PROCEDURE sp_datatype_info_vu_prepare_p2
    @data_type int = 0
AS
BEGIN
    EXEC sys.sp_datatype_info @data_type = @data_type;
END;
GO

CREATE PROCEDURE sp_datatype_info_vu_prepare_p3
    @data_type int = 0,
    @odbcver smallint = 2
AS
BEGIN
    EXEC sys.sp_datatype_info @data_type = @data_type, @odbcver = @odbcver;
END;
GO

CREATE PROCEDURE sp_datatype_info_vu_prepare_int_types
AS
BEGIN
    EXEC sys.sp_datatype_info @data_type = 4;
    EXEC sys.sp_datatype_info @data_type = -5;
    EXEC sys.sp_datatype_info @data_type = 5;
    EXEC sys.sp_datatype_info @data_type = -6;
END;
GO

CREATE PROCEDURE sp_datatype_info_vu_prepare_string_types
AS
BEGIN
    EXEC sys.sp_datatype_info @data_type = 1;
    EXEC sys.sp_datatype_info @data_type = 12;
    EXEC sys.sp_datatype_info @data_type = -1;
    EXEC sys.sp_datatype_info @data_type = -8;
    EXEC sys.sp_datatype_info @data_type = -9;
    EXEC sys.sp_datatype_info @data_type = -10;
END;
GO

CREATE PROCEDURE sp_datatype_info_vu_prepare_binary_types
AS
BEGIN
    EXEC sys.sp_datatype_info @data_type = -2;
    EXEC sys.sp_datatype_info @data_type = -3;
    EXEC sys.sp_datatype_info @data_type = -4;
END;
GO

CREATE PROCEDURE sp_datatype_info_vu_prepare_datetime_types
AS
BEGIN
    EXEC sys.sp_datatype_info @data_type = 9;
    EXEC sys.sp_datatype_info @data_type = 11;
    EXEC sys.sp_datatype_info @data_type = -154;
    EXEC sys.sp_datatype_info @data_type = -155;
END;
GO

CREATE PROCEDURE sp_datatype_info_vu_prepare_decimal_types
AS
BEGIN
    EXEC sys.sp_datatype_info @data_type = 3;
    EXEC sys.sp_datatype_info @data_type = 2;
END;
GO

CREATE PROCEDURE sp_datatype_info_vu_prepare_float_types
AS
BEGIN
    EXEC sys.sp_datatype_info @data_type = 6;
    EXEC sys.sp_datatype_info @data_type = 7;
END;
GO

CREATE PROCEDURE sp_datatype_info_vu_prepare_special_types
AS
BEGIN
    EXEC sys.sp_datatype_info @data_type = -7;
    EXEC sys.sp_datatype_info @data_type = -11;
    EXEC sys.sp_datatype_info @data_type = -150;
    EXEC sys.sp_datatype_info @data_type = -152;
END;
GO

CREATE PROCEDURE sp_datatype_info_vu_prepare_odbcver
AS
BEGIN
    EXEC sys.sp_datatype_info @data_type = 0, @odbcver = 2;
    EXEC sys.sp_datatype_info @data_type = 4, @odbcver = 2;
END;
GO

CREATE PROCEDURE sp_datatype_info_vu_prepare_edge_cases
AS
BEGIN
    EXEC sys.sp_datatype_info @data_type = 9999;
    EXEC sys.sp_datatype_info @data_type = -9999;
    EXEC sys.sp_datatype_info @data_type = 0;
END;
GO
