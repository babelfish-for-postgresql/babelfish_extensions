CREATE PROCEDURE get_tds_id_proc
AS 
    SELECT get_tds_id('timestamp') as rv;
GO

CREATE FUNCTION get_tds_id_func(@a sys.varchar(50))
RETURNS INT
AS
BEGIN
    DECLARE @b int;
    SET @b = (SELECT get_tds_id(@a) as rv);
    RETURN @b;
END
GO

CREATE VIEW get_tds_id_view AS
    SELECT * FROM get_tds_id('timestamp') AS rv
GO
