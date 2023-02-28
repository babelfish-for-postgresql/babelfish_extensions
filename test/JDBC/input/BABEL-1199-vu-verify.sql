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


SELECT user_name(DATABASE_PRINCIPAL_ID('db_owner'));
SELECT user_name(DATABASE_PRINCIPAL_ID('testuser'));
GO