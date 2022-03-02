-- Test string parameters
DECLARE @retVal INT

EXECUTE @retVal = xp_qv N'87651903210', N'SERVICENAME'
select @retVal;
go

-- Test string variables
DECLARE @param1 NVARCHAR(256)
DECLARE @param2 NVARCHAR(256)
DECLARE @retVal INT
set @param1 = N'87651903210'
set @param1 = N'NameofService'

EXECUTE @retVal = xp_qv @param1, @param2
select @retVal;
go

-- Test master.dbo access
DECLARE @retVal INT

EXECUTE @retVal = master.dbo.xp_qv N'87651903210', N'SERVICENAME'
select @retVal;
go

-- Test dbo access
DECLARE @retVal INT

EXECUTE @retVal = dbo.xp_qv N'87651903210', N'SERVICENAME'
select @retVal;
go
