-- BABEL-911: make sure table column constraints don't get confused as variable
-- constraints.
declare @tableVar1 table (a int not null, b int default 0, c nvarchar(60) collate Arabic_CS_AS);
select * from @tableVar1;
GO

-- NOT NULL after ')' should be parsed as variable constraint and should report
-- error.
declare @tableVar1 table (a int) not null;
end;
GO
