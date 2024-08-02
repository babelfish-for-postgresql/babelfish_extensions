CREATE TABLE babelfish_migration_mode_table (id_num INT IDENTITY(1,1), mig_mode VARCHAR(10))
GO
INSERT INTO babelfish_migration_mode_table SELECT current_setting('babelfishpg_tsql.migration_mode')
GO

-- test multi-db mode
SELECT set_config('role', 'jdbc_user', false);
GO
SELECT set_config('babelfishpg_tsql.migration_mode', 'multi-db', false);
GO

-- check if correct schema is present in search path
CREATE DATABASE ["BABEL_5111.db"]
GO

CREATE DATABASE ["龙漫远; 龍漫遠.¢£€¥"]
GO

use ["BABEL_5111.db"]
GO

CREATE TABLE t1(a int)
GO

SELECT current_setting('search_path')
GO

CREATE SCHEMA ["BABEL_5111.scm"]
GO

CREATE TABLE ["BABEL_5111.scm"].t1(a int)
GO

CREATE VIEW ["BABEL_5111.scm"].v1 AS SELECT 1
GO

CREATE PROCEDURE ["BABEL_5111.scm"].p1 AS SELECT 1
GO

CREATE TRIGGER ["BABEL_5111.scm"].BABEL_5111_trgger1 on ["BABEL_5111.scm"].t1 AFTER INSERT AS BEGIN END
GO

ALTER TABLE ["BABEL_5111.scm"].t1 ENABLE TRIGGER BABEL_5111_trgger1
GO

USE ["龙漫远; 龍漫遠.¢£€¥"]
GO

CREATE TABLE t1(a int)
GO

SELECT current_setting('search_path')
GO

CREATE SCHEMA ["BABEL_5111.😃😄😉😊"]
GO

CREATE TABLE ["BABEL_5111.😃😄😉😊"].t1(a int)
GO

CREATE VIEW ["BABEL_5111.😃😄😉😊"].v1 AS SELECT 1
GO

CREATE PROCEDURE ["BABEL_5111.😃😄😉😊"].p1 AS SELECT 1
GO

CREATE TRIGGER ["BABEL_5111.😃😄😉😊"].BABEL_5111_trgger1 on ["BABEL_5111.😃😄😉😊"].t1 AFTER INSERT AS BEGIN END
GO

ALTER TABLE ["BABEL_5111.😃😄😉😊"].t1 ENABLE TRIGGER BABEL_5111_trgger1
GO

USE master
GO

EXEC ["BABEL_5111.db"].["BABEL_5111.scm"].p1
GO

SELECT * from ["BABEL_5111.db"].["BABEL_5111.scm"].t1
GO

SELECT * from ["BABEL_5111.db"].["BABEL_5111.scm"].v1
GO

EXEC ["龙漫远; 龍漫遠.¢£€¥"].["BABEL_5111.😃😄😉😊"].p1
GO

SELECT * from ["龙漫远; 龍漫遠.¢£€¥"].["BABEL_5111.😃😄😉😊"].t1
GO

SELECT * from ["龙漫远; 龍漫遠.¢£€¥"].["BABEL_5111.😃😄😉😊"].v1
GO

use ["BABEL_5111.db"]
GO

DROP PROCEDURE ["BABEL_5111.scm"].p1
GO

DROP TRIGGER ["BABEL_5111.scm"].BABEL_5111_trgger1
GO

DROP VIEW ["BABEL_5111.scm"].v1
GO

DROP TABLE ["BABEL_5111.scm"].t1
GO

DROP SCHEMA ["BABEL_5111.scm"]
GO

DROP TABLE t1
GO

USE ["龙漫远; 龍漫遠.¢£€¥"]
GO

DROP PROCEDURE ["BABEL_5111.😃😄😉😊"].p1
GO

DROP TRIGGER ["BABEL_5111.😃😄😉😊"].BABEL_5111_trgger1
GO

DROP VIEW ["BABEL_5111.😃😄😉😊"].v1
GO

DROP TABLE ["BABEL_5111.😃😄😉😊"].t1
GO

DROP SCHEMA ["BABEL_5111.😃😄😉😊"]
GO

USE master
GO

DROP DATABASE ["BABEL_5111.db"]
GO

DROP DATABASE ["龙漫远; 龍漫遠.¢£€¥"]
GO

SELECT set_config('role', 'jdbc_user', false);
GO

-- Reset migration mode to default
DECLARE @mig_mode VARCHAR(10)
SET @mig_mode = (SELECT mig_mode FROM babelfish_migration_mode_table WHERE id_num = 1)
SELECT CASE WHEN (SELECT set_config('babelfishpg_tsql.migration_mode', @mig_mode, false)) IS NOT NULL THEN 1 ELSE 0 END
GO

Drop Table IF EXISTS babelfish_migration_mode_table
GO