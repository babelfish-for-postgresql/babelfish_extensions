-- single_db_mode_expected
USE master
go

CREATE DATABASE babel_2418_db
go

USE babel_2418_db
go

CREATE SCHEMA babel_2418_schema1
go

CREATE SCHEMA babel_2418_schema2
go

SELECT nspname FROM sys.babelfish_namespace_ext ORDER BY nspname;
go

USE master
go

DROP DATABASE babel_2418_db
go

-- Tests for db level collation
CREATE DATABASE babel_2418_db COLLATE BBF_Unicode_CP1_CI_AI
go

USE babel_2418_db
go

CREATE SCHEMA babel_2418_schema1
go

CREATE SCHEMA babel_2418_schema2
go

SELECT nspname FROM sys.babelfish_namespace_ext ORDER BY nspname;
go

USE master
go

DROP DATABASE babel_2418_db
go

SELECT nspname FROM sys.babelfish_namespace_ext ORDER BY nspname;
go
