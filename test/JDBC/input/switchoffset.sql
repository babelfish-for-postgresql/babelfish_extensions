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

Select switchoffset('200a-0b-22 17:34:56.345', 1)
GO

Select switchoffset('2001-04-22 17:34:56.345', 0x12)
go

Select switchoffset('2001-04-22 17:34:56.345', 'abcd')
GO

Select switchoffset('2001-04-22 ', '+12:00')
GO

Select switchoffset('2001-04-22 ', '-12:00')
GO

Select switchoffset('2001-04-22 17:34:56', '-12:00')
GO

Select switchoffset('2001-04-22 17:34:56.345', '-11:00')
GO

Select switchoffset('2001-04-22 17:34:56.345', '+00:00')
GO

Select switchoffset('2001-04-22 17:34:56.345', '-00:00')
go

Select switchoffset('2001-04-22 10:34:56.345', '-11:00')
go

Select switchoffset('2001-04-22 17:34:56.345', '-101:00')
GO

Select switchoffset('2001-04-22 17:34:56.345', '-011:00')
GO

Select switchoffset('200a-0b-22 17:34:56.345', '-011:00')
GO

Select switchoffset('2001-04-22 17:34:56.345', '+14:01')
GO

Select switchoffset('2001-04-22 17:34:56.345', '-14:01')
GO

Select switchoffset('2001-04-22 17:34:56.345', '-1a:00')
GO

Select switchoffset('2001-04-22 17:34:56.345', '14:00')
GO

-- Currently these inputs are giving wrong output due to casting issues .(BABEL-4321) 

Select switchoffset(convert(datetime,'2001-04-22'),'-13:00')
GO

Select switchoffset(convert(date,'2001-04-22'),'-13:00')
GO

Select switchoffset(convert(datetime2,'2001-04-22'),'-13:00')
GO

Select switchoffset(convert(smalldatetime,'2001-04-22'),'-13:00')
GO

Select switchoffset('0001-01-00 00:00:00.00', '-10:00')
GO

Select switchoffset('0001-01-01 00:00:00.00', '+13:00')
GO

Select switchoffset('9999-12-31 11:59:59.59', '+12:00')
GO

Select switchoffset('9999-12-31 24:59:59.59', 130)
GO

Select switchoffset('10000-12-31 23:59:59.59', 120)
GO

