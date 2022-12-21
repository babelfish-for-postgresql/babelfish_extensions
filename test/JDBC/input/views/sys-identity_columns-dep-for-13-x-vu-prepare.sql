DROP TABLE IF EXISTS sys_identity_columns_dep_vu_prepare
go

CREATE TABLE sys_identity_columns_dep_vu_prepare (c1 int, c3 int IDENTITY(1,1))
go

CREATE DATABASE sys_identity_columns_dep_vu_prepare_db1
go

CREATE PROCEDURE sys_identity_columns_dep_vu_prepare_p1 AS
    SELECT seed_value, increment_value, last_value FROM sys.identity_columns WHERE object_id = object_id('sys_identity_columns_dep_vu_prepare')
go

CREATE FUNCTION sys_identity_columns_dep_vu_prepare_f1()
RETURNS INT 
AS
BEGIN 
    RETURN (SELECT COUNT(*) FROM sys.identity_columns WHERE object_id = object_id('sys_identity_columns_dep_vu_prepare'))
END
go

USE sys_identity_columns_dep_vu_prepare_db1
go

CREATE VIEW sys_identity_columns_dep_vu_prepare_v1 AS
    SELECT COUNT(*) FROM sys.identity_columns WHERE object_id = object_id('sys_identity_columns_dep_vu_prepare')
go
