--Rowcount in trigger should return 1
DELETE FROM babel_2208_vu_prepare_t1 WHERE c1 = 1
go
--Rowcount in trigger should return 2
DELETE FROM babel_2208_vu_prepare_t1 WHERE c1 IN(2,3)
go


--Rowcount in trigger should return 4
INSERT INTO babel_2208_vu_prepare_t2 VALUES (1, 'string1' ),(2, 'string2' ),(3, 'string3' ),(4, 'string4' )
go

INSERT INTO babel_2208_vu_prepare_t2 VALUES (1, 'string1' ),(2, 'string2' ),(3, 'string3' )
GO

