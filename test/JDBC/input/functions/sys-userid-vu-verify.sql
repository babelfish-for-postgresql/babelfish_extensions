SELECT * FROM view_current_principal_id;
GO

EXEC proc_current_principal_id;
GO

SELECT * FROM current_user_id_v1;
GO

EXEC current_user_id_p1;
GO

SELECT * FROM current_user_id_v2;
GO

EXEC current_user_id_p2;
GO

SELECT * FROM view_NULL_principal_id;
GO

EXEC proc_NULL_principal_id;
GO

SELECT * FROM view_db_owner_principal_id;
GO

EXEC proc_db_owner_principal_id;
GO

SELECT * FROM view_db_owner_principal_id_v1;
GO


SELECT user_name(DATABASE_PRINCIPAL_ID('db_owner'));
GO

SELECT user_name(DATABASE_PRINCIPAL_ID('dbo'));
GO

SELECT user_name(DATABASE_PRINCIPAL_ID('guest'));
GO

SELECT user_name(DATABASE_PRINCIPAL_ID('testuser'));
GO

SELECT user_name(DATABASE_PRINCIPAL_ID('roletest'));
GO

SELECT (DATABASE_PRINCIPAL_ID(NULL));
GO

SELECT user_name(DATABASE_PRINCIPAL_ID('db_owner '));
GO

SELECT user_name(DATABASE_PRINCIPAL_ID());
GO

SELECT DATABASE_PRINCIPAL_ID('test_me')
GO

SELECT DATABASE_PRINCIPAL_ID(NULL)
GO

SELECT user_name(user_id());
GO
