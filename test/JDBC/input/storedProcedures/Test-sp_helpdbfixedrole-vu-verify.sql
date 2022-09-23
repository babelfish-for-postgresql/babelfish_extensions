INSERT INTO test_sp_helpdbfixedrole_tbl (DbFixedRole, Description) EXEC sp_helpdbfixedrole
GO

SELECT DbFixedRole, Description FROM test_sp_helpdbfixedrole_tbl
GO

TRUNCATE TABLE test_sp_helpdbfixedrole_tbl
GO

INSERT INTO test_sp_helpdbfixedrole_tbl (DbFixedRole, Description) EXEC sp_helpdbfixedrole 'db_owner'
GO

SELECT DbFixedRole, Description FROM test_sp_helpdbfixedrole_tbl
GO

TRUNCATE TABLE test_sp_helpdbfixedrole_tbl
GO

INSERT INTO test_sp_helpdbfixedrole_tbl (DbFixedRole, Description) EXEC sp_helpdbfixedrole 'DB_OWNER    '
GO

SELECT DbFixedRole, Description FROM test_sp_helpdbfixedrole_tbl
GO

TRUNCATE TABLE test_sp_helpdbfixedrole_tbl
GO

INSERT INTO test_sp_helpdbfixedrole_tbl (DbFixedRole, Description) EXEC sp_helpdbfixedrole 'db_accessadmin'
GO
INSERT INTO test_sp_helpdbfixedrole_tbl (DbFixedRole, Description) EXEC sp_helpdbfixedrole 'DB_securityadmin'
GO
INSERT INTO test_sp_helpdbfixedrole_tbl (DbFixedRole, Description) EXEC sp_helpdbfixedrole 'db_ddladmin   '
GO
INSERT INTO test_sp_helpdbfixedrole_tbl (DbFixedRole, Description) EXEC sp_helpdbfixedrole 'DB_backupoperator     '
GO
INSERT INTO test_sp_helpdbfixedrole_tbl (DbFixedRole, Description) EXEC sp_helpdbfixedrole 'db_datareader'
GO
INSERT INTO test_sp_helpdbfixedrole_tbl (DbFixedRole, Description) EXEC sp_helpdbfixedrole 'db_datawriter'
GO
INSERT INTO test_sp_helpdbfixedrole_tbl (DbFixedRole, Description) EXEC sp_helpdbfixedrole 'db_denydatareader'
GO
INSERT INTO test_sp_helpdbfixedrole_tbl (DbFixedRole, Description) EXEC sp_helpdbfixedrole 'db_denydatawriter'
GO

SELECT DbFixedRole, Description FROM test_sp_helpdbfixedrole_tbl
GO

EXEC sp_helpdbfixedrole ''
GO

EXEC sp_helpdbfixedrole '   Db_owner    '
GO

EXEC sp_helpdbfixedrole 'error'
GO
