-- Failure of these indicates use of wrong collation
-- when init scan keys
USE master
GO

SELECT object_name FROM sys.babelfish_view_def WHERE object_name LIKE 'BABEL4389%'
GO

DROP TABLE BABEL4389V1
GO

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

CREATE SCHEMA babel_4389_schema1
GO

CREATE VIEW babel_4389_schema1.BABEL4389V_1 as SELECT 1
GO
DROP VIEW babel_4389_schema1.BABEL4389V_1
GO

CREATE VIEW babel_4389_schema1.BABEL4389V1 as SELECT 1
GO
DROP VIEW babel_4389_schema1.BABEL4389V1
GO

DROP SCHEMA babel_4389_schema1
GO

USE babel_4389_db1
GO

DROP TABLE babel_4389_schema2.BABEL4389V1
GO

CREATE SCHEMA babel_4389_schema3
GO

CREATE VIEW babel_4389_schema2.BABEL4389V_1 as SELECT 1
GO
DROP VIEW babel_4389_schema2.BABEL4389V_1
GO

DROP VIEW babel_4389_schema2.BABEL4389V_3, babel_4389_schema2.BABEL4389V3
GO

CREATE VIEW babel_4389_schema2.BABEL4389V1 as SELECT 1
GO
DROP VIEW babel_4389_schema2.BABEL4389V1
GO

CREATE VIEW babel_4389_schema3.BABEL4389V_1 as SELECT 1
GO
DROP VIEW babel_4389_schema3.BABEL4389V_1
GO

CREATE VIEW babel_4389_schema3.BABEL4389V1 as SELECT 1
GO
DROP VIEW babel_4389_schema3.BABEL4389V1
GO

DROP SCHEMA babel_4389_schema2
GO

DROP SCHEMA babel_4389_schema3
GO

USE master
GO

DROP VIEW BABEL4389V_3, BABEL4389V3, babel_4389_schema4.BABEL4389V_3, babel_4389_schema4.BABEL4389V3
GO

DROP SCHEMA babel_4389_schema4
GO

SELECT object_name FROM sys.babelfish_view_def WHERE object_name LIKE 'BABEL4389%'
GO

DROP DATABASE babel_4389_db1
GO
