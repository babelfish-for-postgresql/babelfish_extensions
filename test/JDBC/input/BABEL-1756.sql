CREATE TABLE foo(test_collation TEXT COLLATE "default")
GO

SELECT colid, name, collation_100 FROM sys.spt_tablecollations_view WHERE object_id = sys.object_id('foo') ORDER BY colid
GO

exec sp_tablecollations_100 'foo'
GO

exec ..sp_tablecollations_100 'foo'
GO

DROP TABLE foo;
