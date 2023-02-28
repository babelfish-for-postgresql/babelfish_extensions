SELECT * FROM view_database_principal_id_v1 ORDER BY database_principal_id;
SELECT DATABASE_PRINCIPAL_ID();
GO

SELECT * FROM view_current_principal_id;
GO

EXEC proc_current_principal_id;
GO

SELECT * FROM view_db_owner_principal_id;
GO

EXEC proc_db_owner_principal_id;
GO

SELECT * FROM view_db_owner_principal_id_v1;
GO