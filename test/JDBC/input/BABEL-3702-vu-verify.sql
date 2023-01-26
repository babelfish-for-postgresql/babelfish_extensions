SELECT * FROM BABEL_3702_vu_prepare_v1
GO
DROP VIEW BABEL_3702_vu_prepare_v1
GO

EXEC BABEL_3702_vu_prepare_p1
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p1
GO

EXEC BABEL_3702_vu_prepare_p2
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p2
GO

SELECT * FROM BABEL_3702_vu_prepare_v3
GO
DROP VIEW BABEL_3702_vu_prepare_v3
GO

EXEC BABEL_3702_vu_prepare_p3
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p3
GO

EXEC BABEL_3702_vu_prepare_p4
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p4
GO

EXEC BABEL_3702_vu_prepare_p5
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p5
GO

EXEC BABEL_3702_vu_prepare_p6
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p6
GO

EXEC BABEL_3702_vu_prepare_p7
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p7
GO

EXEC BABEL_3702_vu_prepare_p8
GO
DROP PROCEDURE BABEL_3702_vu_prepare_p8
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