EXEC sp_addlinkedserver  @server = N'mssql14332', @srvproduct=N'', @provider=N'tds_fdw', @datasrc=N'docker_mssql2', @catalog=N'master';
EXEC sp_addlinkedsrvlogin @rmtsrvname = 'mssql14332', @useself = 'FALSE', @rmtuser = 'sa', @rmtpassword = 'sqlserver@eva000';

-- 测试连通性
EXEC sys.sp_testlinkedserver N'mssql14332';
GO

-- 允许执行远程存储过程
EXEC sys.sp_serveroption @server = N'mssql14332', @optname = N'rpc', @optvalue = N'true';
GO

EXEC sys.sp_serveroption @server = N'mssql14332', @optname = N'rpc out', @optvalue = N'true';
GO

-- 测试远端标量函数
SELECT mssql14332.master.dbo.fn_add_one(41);
GO

-- 测试调用远端存储过程
DECLARE @y INT;
EXEC mssql14332.master.dbo.my_sp_add_one @x = 41, @y = @y OUTPUT;
SELECT @y AS result;
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

-- 本地：
-- DROP PROCEDURE 删除远端存储过程
DROP PROCEDURE mssql14332.master.dbo.my_sp_add_one;
GO

-- 本地：
-- 调用远端存储过程
EXEC mssql14332.master.dbo.p;
GO

EXEC sp_dropserver @server = N'mssql14332', @droplogins = 'droplogins';