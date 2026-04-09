-- tsql
USE master;
GO

IF OBJECT_ID('dbo.rp_basic', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_basic;
GO

IF OBJECT_ID('dbo.rp_out', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_out;
GO

IF OBJECT_ID('dbo.rp_status', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_status;
GO

IF OBJECT_ID('dbo.rp_multi', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_multi;
GO

IF OBJECT_ID('dbo.rp_multi_mismatch', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_multi_mismatch;
GO

IF OBJECT_ID('dbo.rp_multi_out_status', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_multi_out_status;
GO

IF OBJECT_ID('dbo.rp_insert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_insert;
GO

IF OBJECT_ID('dbo.rp_bit', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_bit;
GO

IF OBJECT_ID('dbo.rp_varchar_param', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_varchar_param;
GO

IF OBJECT_ID('dbo.rp_datetime_param', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_datetime_param;
GO

IF OBJECT_ID('dbo.rp_float_param', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_float_param;
GO

IF OBJECT_ID('dbo.rp_null_param', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_null_param;
GO

IF OBJECT_ID('dbo.rp_large_string', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_large_string;
GO

IF OBJECT_ID('dbo.rp_bin', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_bin;
GO

IF OBJECT_ID('dbo.rp_txn_insert', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_txn_insert;
GO

IF OBJECT_ID('dbo.rp_sleep', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_sleep;
GO

IF OBJECT_ID('dbo.rp_stress', 'P') IS NOT NULL
    DROP PROCEDURE dbo.rp_stress;
GO

IF OBJECT_ID('dbo.rp_txn_log', 'U') IS NOT NULL
    DROP TABLE dbo.rp_txn_log;
GO

IF EXISTS (SELECT 1 FROM sys.servers WHERE name = 'ls_svr')
    EXEC sp_dropserver @server = 'ls_svr', @droplogins = 'droplogins';
GO
