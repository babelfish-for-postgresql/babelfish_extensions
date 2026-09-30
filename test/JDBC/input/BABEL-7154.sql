-- BABEL-7154: Renaming a database must also rename the internal
-- <db>_<user>_bbfobj object-owner role that BABEL-4899 creates when a
-- non-dbo user is added to the db_owner fixed database role. Otherwise
-- DROP DATABASE on the renamed database fails with:
--   role "<new_db>_<user>_bbfobj" does not exist

CREATE DATABASE babel_7154_db
GO
USE babel_7154_db
GO

CREATE LOGIN babel_7154_login WITH PASSWORD = '12345678'
GO
CREATE USER babel_7154_user FOR LOGIN babel_7154_login
GO

-- Adding a non-dbo user to db_owner creates the internal object-owner role
-- babel_7154_db_babel_7154_user_bbfobj
ALTER ROLE db_owner ADD MEMBER babel_7154_user
GO

USE master
GO

-- Rename the database. The internal _bbfobj role must be renamed too.
ALTER DATABASE babel_7154_db MODIFY NAME = babel_7154_db_renamed
GO

-- Before the fix this failed: role "babel_7154_db_renamed_babel_7154_user_bbfobj" does not exist
DROP DATABASE babel_7154_db_renamed
GO

DROP LOGIN babel_7154_login
GO
