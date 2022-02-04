-- Test LEN() function with BINARY and VARBINARY

-- VARBINARY INPUTS
declare @vb varbinary(10) = NULL
select len(@vb)
go

declare @vb varbinary(5)
set @vb = 0x90a;
select len(@vb)
go

declare @vb varbinary(1)
set @vb = 0x90a;
select len(@vb)
go

declare @vb varbinary(10)
set @vb = 0x90a;
select len(@vb)
go

declare @vb varbinary(7)
set @vb = 0x010a1a1a1a;
select len(@vb)
go

declare @vb varbinary(10)
set @vb = 0x0102030405060708090a021321321a321a3a213a21a;
select len(@vb)
go

declare @vb varbinary(10)
set @vb = 0x0102030405060708090a021a31321a321a321a321a321a3a213a21a;
select len(@vb)
go


declare @vb varbinary(10) = 0x0102030405060708090a021a31321a321a321a321a321a3a213a21a321a321a321a36513a216a03
select len(@vb)
go
