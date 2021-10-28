-- Test unexist db, expecting null
SELECT db_id('hello');
SELECT db_name(1234);
GO

-- Test master and tempdb
SELECT db_id('master');
SELECT db_name(1);
GO

USE master;
GO

SELECT db_id();
SELECT db_name();
GO

SELECT db_id('tempdb')
SELECT db_name(2);
GO

USE tempdb;
GO
SELECT db_id();
SELECT db_name();
GO

-- Test custom database
CREATE DATABASE babel_1437_db;
GO
USE babel_1437_db;
GO

SELECT (case when db_name() = 'babel_1437_db' then 'true' else 'false' end) result;
SELECT (case when db_name(db_id()) = 'babel_1437_db' then 'true' else 'false' end) result;
SELECT (case when db_id('babel_1437_db') = db_id() then 'true' else 'false' end) result;
GO

-- test dropped database, expecting db_id to return null
USE MASTER;
GO

DROP DATABASE babel_1437_db;
GO
SELECT db_id('babel_1437_db');
GO
