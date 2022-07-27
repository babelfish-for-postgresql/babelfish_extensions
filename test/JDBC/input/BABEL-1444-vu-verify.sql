USE MASTER
GO

DECLARE @usr CHAR(30)
DECLARE @cur_usr CHAR(30)
SET @usr = user
SET @cur_usr = current_user
SELECT 'user: '+ @usr
SELECT 'current_user: '+ @cur_usr
GO

SELECT * FROM dbo.babel_1444_vu_prepare_t1 ORDER BY id;  
GO

CREATE DATABASE babel_1444_db1;
GO

SELECT current_setting('role');
GO
SELECT current_setting('search_path');
GO
SELECT session_user, current_user, user;
GO
SELECT user_name();
GO

USE babel_1444_db1;
GO

SELECT current_setting('role');
GO
SELECT current_setting('search_path');
GO
SELECT session_user, current_user, user;
GO
SELECT user_name();
GO

-- Error: Test DROP
DROP DATABASE babel_1444_db1;
GO

SELECT current_setting('role');
GO
SELECT current_setting('search_path');
GO
SELECT session_user, current_user, user;
GO
SELECT user_name();
GO

-- Test DROP when using another database
USE MASTER;
GO

SELECT current_setting('role');
GO
SELECT current_setting('search_path');
GO
SELECT session_user, current_user, user;
GO
SELECT user_name();
GO

DROP DATABASE babel_1444_db1;
GO

SELECT current_setting('role');
GO
SELECT current_setting('search_path');
GO
SELECT session_user, current_user, user;
GO
SELECT user_name();
GO

-- Test CREATE
CREATE DATABASE babel_1444_db1;
GO

SELECT current_setting('role');
GO
SELECT current_setting('search_path');
GO
SELECT session_user, current_user, user;
GO
SELECT user_name();
GO
