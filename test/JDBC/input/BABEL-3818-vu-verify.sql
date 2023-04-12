-- Should throw unsupported feature error instead of crashing
alter table cities alter column region drop default defRegion
GO

-- Should throw unsupported feature error
alter table cities alter column region varchar(50) drop default defRegion
GO

-- Should throw syntax error
alter table cities alter region varchar(50) drop default defRegion
GO

-- Should throw syntax error
alter table cities alter region drop default defRegion
GO

-- Ensure alter table alter column: collate, not null, and null
-- still throw unsupported feature error

alter table cities alter column region varchar(25) collate test
go

alter table cities alter column region varchar(50) not null
go

alter table cities alter column region varchar(50) null
go


