SELECT set_config('babelfishpg_tsql.escape_hatch_for_replication', 'ignore', 'false')
GO

-- Test 'NOT FOR REPLICATION' syntax
create table testing1(col nvarchar(60));
GO
create trigger notify on testing1 after insert
NOT FOR REPLICATION
as
begin
  PRINT 'trigger invoked'
end
;
GO

insert into testing1 (col) select N'Muffler';
GO

drop trigger notify;
GO

-- clean up
drop table testing1;
GO

SELECT set_config('babelfishpg_tsql.escape_hatch_for_replication', 'strict', 'false')
GO
