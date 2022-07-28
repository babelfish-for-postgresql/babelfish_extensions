CREATE TABLE sys_default_definitions
(
column_a varchar(2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL DEFAULT ('12'),
column_b datetime NOT NULL DEFAULT getdate(),
column_c int NOT NULL DEFAULT 0,
column_d bit DEFAULT 1,
column_e int
)
GO

ALTER TABLE sys_default_definitions ADD CONSTRAINT default_column_e_int DEFAULT 50 FOR column_e
GO

CREATE PROC sys_default_definitions_proc AS
    SELECT definition FROM sys.default_constraints WHERE name LIKE '%sys_default_definitions%'
GO

CREATE FUNCTION sys_default_definitions_func()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM sys.default_constraints WHERE name LIKE '%sys_default_definitions%' )
END
GO

CREATE VIEW sys_default_definitions_view AS
    SELECT definition FROM sys.default_constraints WHERE name LIKE '%sys_default_definitions%'
GO
