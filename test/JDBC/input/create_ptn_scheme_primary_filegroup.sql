USE master
go
CREATE DATABASE create_ptn_schema_db
go
USE create_ptn_schema_db
go

CREATE PARTITION FUNCTION pf1_create_ptn_scheme_primary (INT) AS RANGE RIGHT FOR VALUES (100, 200, 300) ;
go

CREATE PARTITION SCHEME ps1_create_ptn_scheme_primary AS PARTITION pf1_create_ptn_scheme_primary ALL TO ('PRIMARY') ;
go

SET QUOTED_IDENTIFIER ON
go

CREATE PARTITION SCHEME ps2_create_ptn_scheme_primary AS PARTITION pf1_create_ptn_scheme_primary ALL TO ("PRIMARY") ;
go

CREATE PARTITION SCHEME ps3_create_ptn_scheme_primary AS PARTITION pf1_create_ptn_scheme_primary TO ('PRIMARY', "PRIMARY", [PRIMARY], 'primary', "primary", [primary], somename, 'somename', "somename") ;
go

SET QUOTED_IDENTIFIER OFF
go

CREATE PROCEDURE p1_create_ptn_scheme_primary
as
CREATE PARTITION SCHEME ps5_create_ptn_scheme_primary AS 
PARTITION pf1_create_ptn_scheme_primary 
TO ('PRIMARY', "PRIMARY", [PRIMARY], 'primary', "primary", [primary]) ;
go

EXECUTE('CREATE PARTITION SCHEME ps4_create_ptn_scheme_primary AS PARTITION pf1_create_ptn_scheme_primary  ALL TO (''PRIMARY'') ')
go

EXECUTE p1_create_ptn_scheme_primary
go

SELECT name, type, type_desc, is_default, is_system FROM sys.partition_schemes ORDER BY name
go

-- named file groups should raise an error when name != PRIMARY
EXECUTE sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_storage_options', 'strict'
go

CREATE PARTITION SCHEME ps10_create_ptn_scheme_primary AS PARTITION pf1_create_ptn_scheme_primary ALL TO (some_name) ;
go

CREATE PARTITION SCHEME ps11_create_ptn_scheme_primary AS PARTITION pf1_create_ptn_scheme_primary ALL TO ('some_name') ;
go

SET QUOTED_IDENTIFIER ON
go
CREATE PARTITION SCHEME ps12_create_ptn_scheme_primary AS PARTITION pf1_create_ptn_scheme_primary ALL TO ("some_name") ;
go
SET QUOTED_IDENTIFIER OFF
go

EXECUTE sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_storage_options', 'ignore'
go

USE master
go
DROP DATABASE create_ptn_schema_db
go
