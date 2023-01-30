create login [xyz\admin] from windows;
GO

-- TODO: Fix this test once BABEL-3863 is resolved.
exec babelfish_add_domain_mapping_entry 'abc', 'abc.internal'
GO

create login [abc\test] from windows;
GO
