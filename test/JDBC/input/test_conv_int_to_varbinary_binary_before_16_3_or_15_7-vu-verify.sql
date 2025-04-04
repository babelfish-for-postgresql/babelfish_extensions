SELECT * from int_to_varbinary_v1
GO

SELECT * from int_to_varbinary_v2
GO

SELECT * from int_to_varbinary_v3
GO

SELECT * from int_to_binary_v1
GO

SELECT * from int_to_binary_v2
GO


SELECT int_to_varbinary_f1()
GO

SELECT int_to_varbinary_f2()
GO

SELECT int_to_varbinary_f3()
GO

SELECT int_to_binary_f1()
GO

SELECT int_to_binary_f2()
GO

EXEC int_to_varbinary_p1
GO

EXEC int_to_varbinary_p2
GO

EXEC int_to_varbinary_p3
GO

EXEC int_to_binary_p1
GO

EXEC int_to_binary_p2
GO

select convert(binary(2), 38)
go

select convert(binary(3), 38)
go                       

select convert(varbinary(2), 38)
GO                            

select convert(varbinary(3), 38)
go

select convert(varbinary(max), 38)
go

select try_convert(binary(2), 38)
go

select try_convert(binary(3), 38)
go                       

select try_convert(varbinary(2), 38)
GO                            

select try_convert(varbinary(3), 38)
go

select try_convert(varbinary(max), 38)
go