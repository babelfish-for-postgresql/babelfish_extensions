-- Failure of these indicates use of wrong collation
-- when init scan keys

CREATE VIEW BABEL4389V_1 as SELECT 1
GO
DROP VIEW BABEL4389V_1
GO

CREATE VIEW BABEL4389V1 as SELECT 1
GO
DROP VIEW BABEL4389V1
GO

CREATE VIEW BABEL4389V1 as SELECT 1
GO
sp_rename 'BABEL4389V1', 'BABEL4389V2', 'OBJECT'
GO
DROP VIEW BABEL4389V2
GO

SELECT object_name FROM sys.babelfish_view_def WHERE object_name IN ('BABEL4389V_1', 'BABEL4389V1', 'BABEL4389V2')
GO

EXEC sys.babelfish_add_domain_mapping_entry 'BABEL4389D_1', 'CollationCheck'
GO
EXEC sys.babelfish_remove_domain_mapping_entry 'BABEL4389D_1'
GO
EXEC sys.babelfish_add_domain_mapping_entry 'BABEL4389D1', 'CollationCheck'
GO
EXEC sys.babelfish_remove_domain_mapping_entry 'BABEL4389D1'
GO

SELECT * FROM sys.babelfish_domain_mapping WHERE netbios_domain_name IN ('BABEL4389D1', 'BABEL4389D_1')
GO
