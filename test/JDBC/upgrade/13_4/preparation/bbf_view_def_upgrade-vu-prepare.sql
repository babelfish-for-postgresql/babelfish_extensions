CREATE VIEW view_3135_upd AS SELECT 1;
GO

CREATE VIEW dep_view_3135 AS SELECT * FROM sys.babelfish_view_def;
GO

-- Won't fail because it will refer PG's information_schema
CREATE VIEW dep_view_3135_2 AS SELECT * FROM information_schema.views;
GO

