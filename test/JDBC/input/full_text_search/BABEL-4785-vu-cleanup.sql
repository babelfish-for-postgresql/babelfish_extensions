DROP FULLTEXT INDEX ON [fts.test].[table.test];
GO

DROP TABLE IF EXISTS [fts.test].[table.test];
GO

DROP FULLTEXT INDEX ON [fts.test].test_table;
GO

DROP TABLE IF EXISTS [fts.test].test_table;
GO

DROP FULLTEXT INDEX ON [fts.test]."fts object with dots and spaces in quotes";
GO

DROP TABLE IF EXISTS [fts.test]."fts object with dots and spaces in quotes";
GO

DROP FULLTEXT INDEX ON fts_schema_test.[table.test];
GO

DROP TABLE IF EXISTS fts_schema_test.[table.test];
GO

DROP FULLTEXT INDEX ON "fts .schema with dots .and spaces".[table.test];
GO

DROP TABLE IF EXISTS "fts .schema with dots .and spaces".[table.test];
GO

DROP FULLTEXT INDEX ON "fts .schema with dots .and spaces"."fts object with dots and spaces in quotes";
GO

DROP TABLE IF EXISTS "fts .schema with dots .and spaces"."fts object with dots and spaces in quotes";
GO

DROP FULLTEXT INDEX ON "fts .schema with dots .and spaces".test_table;
GO

DROP TABLE IF EXISTS "fts .schema with dots .and spaces".test_table;
GO

DROP FULLTEXT INDEX ON fts_schema_test."fts object with dots and spaces in quotes";
GO

DROP TABLE IF EXISTS fts_schema_test."fts object with dots and spaces in quotes";
GO

DROP SCHEMA IF EXISTS [fts.test];
GO

DROP SCHEMA IF EXISTS fts_schema_test;
GO

DROP SCHEMA IF EXISTS "fts .schema with dots .and spaces";
GO

USE "fts_test .db";
GO

DROP FULLTEXT INDEX ON "fts_test .db".[fts_test  .schema].fts_test_table;
GO

DROP TABLE IF EXISTS "fts_test .db".[fts_test  .schema].fts_test_table;
GO

DROP SCHEMA IF EXISTS [fts_test  .schema];
GO

USE master;
GO

DROP DATABASE IF EXISTS "fts_test .db";
GO