SELECT * FROM current_user_id_v1;
GO

EXEC current_user_id_p1;
GO


SELECT * FROM current_user_id_v2;
GO

EXEC current_user_id_p2;
GO

SELECT user_name(user_id());
GO