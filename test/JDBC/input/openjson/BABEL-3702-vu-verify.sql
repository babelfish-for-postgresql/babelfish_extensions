EXEC BABEL_3702_vu_prepare_p6
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p6
GO

EXEC BABEL_3702_vu_prepare_p6_2
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p6_2
GO

EXEC BABEL_3702_vu_prepare_p6_3
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p6_3
GO

EXEC BABEL_3702_vu_prepare_p7
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p7
GO

EXEC BABEL_3702_vu_prepare_p8
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p8
GO

EXEC BABEL_3702_vu_prepare_p8_2
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p8_2
GO

EXEC BABEL_3702_vu_prepare_p8_3
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p8_3
GO

EXEC BABEL_3702_vu_prepare_p8_4
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p8_4
GO

EXEC BABEL_3702_vu_prepare_p8_5
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p8_5
GO

EXEC BABEL_3702_vu_prepare_p9
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p9
GO

EXEC BABEL_3702_vu_prepare_p10
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p10
GO

EXEC BABEL_3702_vu_prepare_p11
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p11
GO

declare @json nvarchar(max) = '{"udfs":[{"name":"alpha","value":"value1"},{"name":"bravo","value":"value2"}]}'

exec BABEL_3702_vu_prepare_p12 @json
go

drop table fdefs
drop table ftypes
drop procedure BABEL_3702_vu_prepare_p12
go

EXEC BABEL_3702_vu_prepare_p13
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p13
GO

EXEC BABEL_3702_vu_prepare_p14
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p14
GO

EXEC BABEL_3702_vu_prepare_p15
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p15
GO

EXEC BABEL_3702_vu_prepare_p16
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p16
GO