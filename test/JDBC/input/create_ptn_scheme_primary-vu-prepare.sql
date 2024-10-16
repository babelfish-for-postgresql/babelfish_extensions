CREATE PARTITION FUNCTION pf1_create_ptn_scheme_primary (INT) AS RANGE RIGHT FOR VALUES (100, 200, 300) ;
GO

CREATE PARTITION SCHEME ps1_create_ptn_scheme_primary AS PARTITION pf1_create_ptn_scheme_primary ALL TO ('PRIMARY') ;
GO

SET QUOTED_IDENTIFIER ON
go

CREATE PARTITION SCHEME ps2_create_ptn_scheme_primary AS PARTITION pf1_create_ptn_scheme_primary ALL TO ("PRIMARY") ;
GO

CREATE PARTITION SCHEME ps3_create_ptn_scheme_primary AS PARTITION pf1_create_ptn_scheme_primary TO ('PRIMARY', "PRIMARY", [PRIMARY], 'primary', "primary", [primary]) ;
GO

SET QUOTED_IDENTIFIER OFF
go

CREATE PROCEDURE p1_create_ptn_scheme_primary
as
CREATE PARTITION SCHEME ps5_create_ptn_scheme_primary AS 
PARTITION pf1_create_ptn_scheme_primary 
TO ('PRIMARY', "PRIMARY", [PRIMARY], 'primary', "primary", [primary]) ;
go