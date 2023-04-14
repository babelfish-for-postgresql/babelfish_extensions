CREATE VIEW dbo.current_user_id_v1 AS
SELECT user_name(user_id());
GO

CREATE PROCEDURE dbo.current_user_id_p1
AS
BEGIN
    SELECT user_name(user_id());
END;
GO

CREATE VIEW dbo.current_user_id_v2 AS
SELECT user_name(user_id('dbo'));
GO

CREATE PROCEDURE dbo.current_user_id_p2
AS
BEGIN
    SELECT user_name(user_id('dbo'));
END;
GO