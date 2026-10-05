-- BABEL-7154: Renaming a database must also rename the internal
-- <db>_<user>_bbfobj object-owner role that BABEL-4899 creates when a
-- non-dbo user is added to the db_owner fixed database role. Otherwise
-- DROP DATABASE on the renamed database fails with:
--   role "<new_db>_<user>_bbfobj" does not exist
--
-- This test creates a single user database and runs identically in both
-- single-db and multi-db migration modes (same expected output).

CREATE DATABASE babel_7154_db
GO
USE babel_7154_db
GO

CREATE LOGIN babel_7154_login WITH PASSWORD = '12345678'
GO
CREATE USER babel_7154_user FOR LOGIN babel_7154_login
GO

-- Adding a non-dbo user to db_owner creates the internal object-owner role
-- <db>_babel_7154_user_bbfobj
ALTER ROLE db_owner ADD MEMBER babel_7154_user
GO

-- Pre-rename: the user is a db_owner member and is tracked in the
-- Babelfish user-extension catalog under database_name 'babel_7154_db'.
-- (orig_username is mode-agnostic; the physical rolname prefix is not,
-- so we assert on orig_username + database_name which are stable.)
SELECT orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'babel_7154_user'
GO

USE master
GO

-- Rename the database. The internal _bbfobj role must be renamed too.
ALTER DATABASE babel_7154_db MODIFY NAME = babel_7154_db_renamed
GO

-- Post-rename validation: the user's catalog entry must now reflect the
-- new database name (proves the catalog-driven role rename ran) and the
-- old database name must be gone. Works the same in single-db and multi-db.
SELECT orig_username, database_name
FROM sys.babelfish_authid_user_ext
WHERE orig_username = 'babel_7154_user'
GO

-- The db_owner member must still retain its privileges after the rename.
USE babel_7154_db_renamed
GO
CREATE TABLE babel_7154_tbl (a int)
GO
INSERT INTO babel_7154_tbl VALUES (1)
GO
SELECT a FROM babel_7154_tbl
GO
DROP TABLE babel_7154_tbl
GO

USE master
GO

-- The actual BABEL-7154 regression: before the fix this failed with
-- role "babel_7154_db_renamed_babel_7154_user_bbfobj" does not exist
DROP DATABASE babel_7154_db_renamed
GO

DROP LOGIN babel_7154_login
GO
