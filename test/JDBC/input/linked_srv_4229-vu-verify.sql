-- Call OPENQUERY() / four-part-object name from a database other than master
USE tempdb
CREATE TABLE t_tempdb_babel_4229 (a int)
INSERT INTO t_tempdb_babel_4229 VALUES (42290)
SELECT * FROM OPENQUERY(server_4229, 'SELECT ''Called from tempdb''')
SELECT * FROM server_4229.tempdb.dbo.t_tempdb_babel_4229
DROP TABLE t_tempdb_babel_4229
GO

CREATE DATABASE openquery_db
USE openquery_db
CREATE TABLE t_openquerydb_babel_4229 (b int)
INSERT INTO t_openquerydb_babel_4229 VALUES (42291)
SELECT * FROM OPENQUERY(server_4229, 'SELECT ''Called from openquery_db''')
SELECT * FROM server_4229.openquery_db.dbo.t_openquerydb_babel_4229
DROP TABLE t_openquerydb_babel_4229
GO

USE master
DROP DATABASE openquery_db
GO

-- Tests for db level collation
CREATE DATABASE openquery_db COLLATE BBF_Unicode_CP1_CI_AI
USE openquery_db
CREATE TABLE t_openquerydb_babel_4229 (b int)
INSERT INTO t_openquerydb_babel_4229 VALUES (42291)
SELECT * FROM OPENQUERY(server_4229, 'SELECT ''Called from openquery_db''')
SELECT * FROM server_4229.openquery_db.dbo.t_openquerydb_babel_4229
DROP TABLE t_openquerydb_babel_4229
GO

USE master
DROP DATABASE openquery_db
GO
