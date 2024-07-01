CREATE PROCEDURE babel_4390_prepare_p1 AS
BEGIN
    EXEC('DROP PROCEDURE xp_qv');
END
GO

CREATE PROCEDURE babel_4390_test_proc AS
BEGIN
    SELECT 'This is a test proc to test drop procedure';
END
GO

CREATE PROCEDURE babel_4390_prepare_p2 AS
BEGIN
    EXEC('DROP PROCEDURE babel_4390_test_proc');
END
GO

CREATE PROCEDURE babel_4390_prepare_p3 AS
BEGIN
    EXEC('DROP PROCEDURE xp_instance_regread(sys.nvarchar, sys.sysname, sys.nvarchar, int)');
END
GO

CREATE PROCEDURE babel_4390_prepare_p4 AS
BEGIN
    EXEC('DROP PROCEDURE xp_instance_regread(sys.nvarchar, sys.sysname, sys.nvarchar, sys.nvarchar)');
END
GO

CREATE PROCEDURE babel_4390_prepare_p5 AS
BEGIN
    EXEC('DROP PROCEDURE sp_addlinkedsrvlogin');
END
GO

CREATE PROCEDURE babel_4390_prepare_p6 AS
BEGIN
    EXEC('DROP PROCEDURE sp_droplinkedsrvlogin');
END
GO

CREATE PROCEDURE babel_4390_prepare_p7 AS
BEGIN
    EXEC('DROP PROCEDURE sp_dropserver');
END
GO

CREATE PROCEDURE babel_4390_prepare_p8 AS
BEGIN
    EXEC('DROP PROCEDURE sp_enum_oledb_providers');
END
GO

CREATE PROCEDURE babel_4390_prepare_p9 AS
BEGIN
    EXEC('DROP PROCEDURE sp_testlinkedserver');
END
GO