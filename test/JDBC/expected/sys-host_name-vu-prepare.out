CREATE VIEW host_name_view AS SELECT DISTINCT hostname FROM sys.sysprocesses WHERE spid = @@SPID
GO

CREATE FUNCTION host_name_func() 
RETURNS NCHAR(128)
AS
BEGIN
        DECLARE @hostname NCHAR(128);
        SELECT @hostname = hostname FROM sys.sysprocesses WHERE spid = @@SPID;
        RETURN @hostname;
END
GO
