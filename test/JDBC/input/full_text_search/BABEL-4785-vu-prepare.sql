-- Tests for database, schema and object name containing spaces and dots
CREATE SCHEMA [fts.test]
GO

CREATE TABLE [fts.test].[table.test](id int not null, name text)
GO

CREATE UNIQUE INDEX fti_schema_test1 ON [fts.test].[table.test](id);
GO

CREATE FULLTEXT INDEX ON [fts.test].[table.test](name) KEY INDEX fti_schema_test1;
GO

CREATE TABLE [fts.test].test_table(id int not null, name text)
GO

CREATE UNIQUE INDEX fti_schema_test2 ON [fts.test].test_table(id);
GO

CREATE FULLTEXT INDEX ON [fts.test].test_table(name) KEY INDEX fti_schema_test2;
GO

CREATE TABLE [fts.test]."fts object with dots and spaces in quotes"(id int not null, name text)
GO

CREATE UNIQUE INDEX fti_schema_test3 ON [fts.test]."fts object with dots and spaces in quotes"(id);
GO

CREATE FULLTEXT INDEX ON [fts.test]."fts object with dots and spaces in quotes"(name) KEY INDEX fti_schema_test3;
GO

CREATE SCHEMA "fts .schema with dots .and spaces"
GO

CREATE TABLE "fts .schema with dots .and spaces".[table.test](id int not null, name text)
GO

CREATE UNIQUE INDEX fti_schema_test4 ON "fts .schema with dots .and spaces".[table.test](id);
GO

CREATE FULLTEXT INDEX ON "fts .schema with dots .and spaces".[table.test](name) KEY INDEX fti_schema_test4;
GO

CREATE TABLE "fts .schema with dots .and spaces"."fts object with dots and spaces in quotes"(id int not null, name text)
GO

CREATE UNIQUE INDEX fti_schema_test5 ON "fts .schema with dots .and spaces"."fts object with dots and spaces in quotes"(id);
GO

CREATE FULLTEXT INDEX ON "fts .schema with dots .and spaces"."fts object with dots and spaces in quotes"(name) KEY INDEX fti_schema_test5;
GO

CREATE TABLE "fts .schema with dots .and spaces".test_table(id int not null, name text)
GO

CREATE UNIQUE INDEX fti_schema_test6 ON "fts .schema with dots .and spaces".test_table(id);
GO

CREATE FULLTEXT INDEX ON "fts .schema with dots .and spaces".test_table(name) KEY INDEX fti_schema_test6;
GO

CREATE SCHEMA fts_schema_test
GO

CREATE TABLE fts_schema_test.[table.test](id int not null, name text)
GO

CREATE UNIQUE INDEX fti_schema_test8 ON fts_schema_test.[table.test](id);
GO

CREATE FULLTEXT INDEX ON fts_schema_test.[table.test](name) KEY INDEX fti_schema_test8;
GO

CREATE TABLE fts_schema_test."fts object with dots and spaces in quotes"(id int not null, name text)
GO

CREATE UNIQUE INDEX fti_schema_test9 ON fts_schema_test."fts object with dots and spaces in quotes"(id);
GO

CREATE FULLTEXT INDEX ON fts_schema_test."fts object with dots and spaces in quotes"(name) KEY INDEX fti_schema_test9;
GO

CREATE DATABASE "fts_test .db";
GO

USE "fts_test .db"
GO

CREATE SCHEMA [fts_test  .schema]
GO

CREATE TABLE "fts_test .db".[fts_test  .schema].fts_test_table(id int not null constraint pk_mytexts primary key, name text)
GO

CREATE FULLTEXT INDEX ON "fts_test .db".[fts_test  .schema].fts_test_table(name) KEY INDEX pk_mytexts;
GO