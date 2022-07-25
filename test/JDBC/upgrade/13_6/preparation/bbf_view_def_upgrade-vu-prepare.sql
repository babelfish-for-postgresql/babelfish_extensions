CREATE VIEW view_3135_upd AS SELECT 1;
GO

CREATE VIEW dep_view_3135 AS SELECT * FROM sys.babelfish_view_def;
GO

-- Will fail because isc.views(TSQL version) is not implemented
CREATE VIEW dep_view_3135_2 AS SELECT * FROM information_schema.views;
GO

