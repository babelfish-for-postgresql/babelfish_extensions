-- 14431 (本地)
EXEC sys.sp_addlinkedserver @server = N'mssql14332', @srvproduct = N'', @provider = N'MSOLEDBSQL', @datasrc = N'host.docker.internal,14332';
GO

EXEC sys.sp_addlinkedsrvlogin @rmtsrvname = N'mssql14332', @useself    = N'False', @locallogin = NULL, @rmtuser    = N'sa', @rmtpassword= N'sqlserver@eva000';
GO

-- 允许执行远程存储过程
EXEC sys.sp_serveroption @server = N'mssql14332', @optname = N'rpc', @optvalue = N'true';
GO

EXEC sys.sp_serveroption @server = N'mssql14332', @optname = N'rpc out', @optvalue = N'true';
GO

-- 测试连通性
EXEC sys.sp_testlinkedserver N'mssql14332';
GO

EXEC sys.sp_dropserver
    @server = N'mssql14332',
    @droplogins = 'droplogins';
GO

-- dropserver
EXEC sys.sp_dropserver
    @server = N'mssql14331',
    @droplogins = 'droplogins';
GO

-- 14432 (远端)
EXEC sys.sp_addlinkedserver @server = N'mssql14331', @srvproduct = N'', @provider = N'MSOLEDBSQL', @datasrc = N'host.docker.internal,14331';
GO

EXEC sys.sp_addlinkedsrvlogin @rmtsrvname = N'mssql14331', @useself    = N'False', @locallogin = NULL, @rmtuser    = N'sa', @rmtpassword= N'sqlserver@eva000';
GO

-- 允许执行远程存储过程
EXEC sys.sp_serveroption @server = N'mssql14331', @optname = N'rpc', @optvalue = N'true';
GO

EXEC sys.sp_serveroption @server = N'mssql14331', @optname = N'rpc out', @optvalue = N'true';
GO

-- 测试连通性
EXEC sys.sp_testlinkedserver N'mssql14331';
GO


-- 远端
-- 创建标量函数
CREATE FUNCTION dbo.fn_add_one (@x INT)
RETURNS INT
AS
BEGIN
    RETURN @x + 1;
END;
GO

-- 测试远端标量函数
SELECT mssql14332.master.dbo.fn_add_one(41);
GO

-- 创建表值函数
CREATE FUNCTION dbo.fn_range (@n INT)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (@n)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS v
    FROM sys.objects
);
GO

-- 创建存储过程
CREATE PROCEDURE dbo.my_sp_add_one
    @x INT,
    @y INT OUTPUT
AS
BEGIN
    SET @y = @x + 1;
END;
GO

-- 测试调用远端存储过程
DECLARE @y INT;
EXEC mssql14332.master.dbo.my_sp_add_one @x = 41, @y = @y OUTPUT;
SELECT @y AS result;
GO

-- 远端：
-- 创建全局临时存储过程
CREATE PROCEDURE ##global_tmp_proc
    @msg NVARCHAR(100)
AS
BEGIN
    PRINT 'Hello from global temp procedure!';
    PRINT @msg;
END;
GO

-- 本地：
-- 调用远端全局临时存储过程
EXEC mssql14332.master.dbo.##global_tmp_proc N'called from another session';
GO

-- 本地：
-- 调用远端 sp_ 系统存储过程
EXEC mssql14332.master.sys.sp_helpdb;
GO

-- 调用远端 xp_ 系统存储过程
EXEC mssql14332.master.dbo.xp_msver;
GO

-- 本地：
-- 调用远端 sp_helptext 查看远端存储过程定义
EXEC ('sp_helptext ''dbo.my_sp_add_one''') AT mssql14332;
GO

-- 本地：
-- ALTER PROCEDURE 修改远端存储过程
-- 预期失败
ALTER PROCEDURE mssql14332.master.dbo.my_sp_add_one
AS
BEGIN
    SELECT 100;
END;
GO

-- 预期成功
EXEC ('
ALTER PROCEDURE dbo.my_sp_add_one
    @x INT,
    @y INT OUTPUT
AS
BEGIN
    SET @y = @x + 2;
END
') AT mssql14332;


-- 本地：
-- DROP PROCEDURE 删除远端存储过程
DROP PROCEDURE mssql14332.master.dbo.my_sp_add_one;
GO

-- 本地：
-- 重命名远端存储过程
EXEC ('EXEC sys.sp_rename
    ''dbo.my_sp_add_one'',
    ''sp_add_two'';
') AT mssql14332;
GO

EXEC ('EXEC sys.sp_rename
    ''dbo.sp_add_two'',
    ''dbo.my_sp_add_one'';
') AT mssql14332;
GO

-- 本地：
-- EXEC AT 创建存储过程
-- 成功
EXEC ('
CREATE PROCEDURE master.dbo.test_proc
AS
BEGIN
    SELECT 1 AS value;
END;
') AT mssql14332;
GO

-- 本地
-- 授予 test_user 执行权限
EXEC ('
GRANT EXECUTE ON dbo.my_sp_add_one TO test_user;
') AT mssql14332;
GO

-- 远端：
-- 创建存储过程
CREATE PROCEDURE dbo.p AS BEGIN SELECT 1 AS v; SELECT 2 AS v; END; 
GO

-- 本地：
-- 调用远端存储过程
EXEC mssql14332.master.dbo.p;
GO

-- 交叉调用测试
-- 本地: p1 创建存储过程 p1
CREATE OR ALTER PROCEDURE dbo.p1
    @x INT,
    @y INT OUTPUT
AS
BEGIN
    SET @y = @x + 100;
END;
GO

-- 远端: p2 远端调用 p1
CREATE OR ALTER PROCEDURE dbo.p2
    @x INT,
    @y INT OUTPUT
AS
BEGIN
    DECLARE @tmp INT;

    EXEC mssql14331.master.dbo.p1
         @x = @x,
         @y = @tmp OUTPUT;

    SET @y = @tmp + 1000;
END;
GO

-- 本地：远程调用 p2
DECLARE @y INT;
EXEC mssql14332.master.dbo.p2 41, @y OUTPUT;
SELECT @y AS result;
GO

-- 循环递归调用
-- 本地：
-- 创建 p1
CREATE OR ALTER PROCEDURE dbo.p1
    @depth INT
AS
BEGIN
    PRINT 'Enter p1, depth=' + CAST(@depth AS VARCHAR(10));

    IF @depth > 0
    BEGIN
        DECLARE @next INT;
        SET @next = @depth - 1;

        EXEC mssql14332.master.dbo.p2
             @depth = @next;
    END
END;
GO

-- 远端：
-- 创建 p2
CREATE OR ALTER PROCEDURE dbo.p2
    @depth INT
AS
BEGIN
    PRINT 'Enter p2, depth=' + CAST(@depth AS VARCHAR(10));

    IF @depth > 0
    BEGIN
        DECLARE @next INT;
        SET @next = @depth - 1;

        EXEC mssql14331.master.dbo.p1
             @depth = @next;
    END
END;
GO

-- 调用
EXEC dbo.p1 5;
