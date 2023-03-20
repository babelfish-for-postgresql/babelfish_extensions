SELECT babelfish_integrity_checker_vu_prepare_func();
GO

SELECT * FROM babelfish_integrity_checker_vu_prepare_view;
GO

EXEC babelfish_integrity_checker_vu_prepare_proc;
GO

-- List down all configuration tables of babelfishpg_tsql extension
SELECT relname FROM pg_class WHERE oid IN
	(SELECT unnest(extconfig) FROM pg_extension WHERE extname = 'babelfishpg_tsql')
	ORDER BY relname;
GO
