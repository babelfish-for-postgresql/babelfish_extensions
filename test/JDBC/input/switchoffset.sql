Select switchoffset('2001-04-22 ', -120)
GO

Select switchoffset('2001-04-22 ', 120)
GO

Select switchoffset('2001-04-22 17:34:56', 120)
GO

Select switchoffset('2001-04-22 17:34:56.345', 120)
GO

Select switchoffset('2001-04-22 17:34:56.345', 0)
go

Select switchoffset('2001-04-22 17:34:56.345', -0)
go

Select switchoffset('2001-04-22 17:34:56.345', 0x12)
go

Select switchoffset('2001-04-22 ', '+12:00')
GO

Select switchoffset('2001-04-22 ', '-12:00')
GO

Select switchoffset('2001-04-22 17:34:56', '-12:00')
GO

Select switchoffset('2001-04-22 17:34:56.345', '-11:00')
GO

Select switchoffset('2001-04-22 17:34:56.345', '+00:00')
go

Select switchoffset('2001-04-22 17:34:56.345', '-00:00')
go

Select switchoffset('2001-04-22 10:34:56.345', '-11:00')
go
