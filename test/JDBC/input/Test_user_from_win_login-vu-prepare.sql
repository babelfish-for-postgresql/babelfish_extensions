create login [xyz\admin] from windows;
GO

exec babelfish_add_domain_mapping_entry 'def', 'def.internal'
GO

create login [def\test] from windows;
GO
