-- CHECK the GUC setting for weak view binding
EXEC sp_babelfish_configure;
GO

DROP TABLE TV1;
GO

DROP VIEW V1;
GO

-- Turn on GUC for weak view binding
EXEC sp_babelfish_configure 'babelfishpg_tsql.weak_view_binding', 'on';
GO

ALTER VIEW V1 AS SELECT a, b FROM TV1;
GO

ALTER VIEW V3 AS SELECT a FROM TV1 JOIN TV2 ON TV1.a = TV2.id;
GO

DROP TABLE TV1;
GO

CREATE TABLE TV1 (a int, b int);
GO

SELECT * FROM V1;
GO

SELECT * FROM V2;
GO

-- Turn off GUC for weak view binding
EXEC sp_babelfish_configure 'babelfishpg_tsql.weak_view_binding', 'off';
GO

CREATE VIEW V4 AS SELECT a, b FROM TV1;
GO

DROP TABLE TV1;
GO