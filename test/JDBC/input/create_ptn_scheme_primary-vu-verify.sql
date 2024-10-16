EXECUTE('CREATE PARTITION SCHEME ps4_create_ptn_scheme_primary AS PARTITION pf1_create_ptn_scheme_primary  ALL TO (''PRIMARY'') ')
go

EXECUTE p1_create_ptn_scheme_primary
go

SELECT name, type, type_desc, is_default, is_system FROM sys.partition_schemes ORDER BY name
go
