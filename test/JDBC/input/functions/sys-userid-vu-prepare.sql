CREATE VIEW dbo.view_current_principal_id AS
SELECT user_name(DATABASE_PRINCIPAL_ID());
GO

CREATE PROCEDURE dbo.proc_current_principal_id
AS
BEGIN
    SELECT user_name(DATABASE_PRINCIPAL_ID());
END;
GO

CREATE VIEW dbo.view_NULL_principal_id AS
SELECT (DATABASE_PRINCIPAL_ID(NULL));
GO

CREATE PROCEDURE dbo.proc_NULL_principal_id
AS
BEGIN
    SELECT (DATABASE_PRINCIPAL_ID(NULL));
END;
GO

CREATE VIEW dbo.view_db_owner_principal_id AS
SELECT user_name(DATABASE_PRINCIPAL_ID('db_owner'));
GO

CREATE PROCEDURE dbo.proc_db_owner_principal_id
AS
BEGIN
    SELECT user_name(DATABASE_PRINCIPAL_ID('db_owner'));
END;
GO

CREATE VIEW dbo.view_db_owner_principal_id_v1 AS
SELECT (DATABASE_PRINCIPAL_ID('db_temp'));
GO

CREATE LOGIN testuser WITH PASSWORD = 'testpassword';
CREATE USER testuser FOR LOGIN testuser;
CREATE ROLE roletest;
GO