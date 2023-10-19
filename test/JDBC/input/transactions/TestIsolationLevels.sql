SELECT set_config('babelfishpg_tsql.repeatable_read_isolation','default',false);
SELECT set_config('babelfishpg_tsql.serializable_isolation','default',false);
GO

set transaction isolation level read uncommitted;
go

set transaction isolation level read committed;
go

set transaction isolation level repeatable read;
go

set transaction isolation level snapshot;
go

set transaction isolation level serializable;
go

select set_config('default_transaction_isolation', 'read uncommitted', false);
go
select set_config('default_transaction_isolation', 'read committed', false);
go
select set_config('default_transaction_isolation', 'repeatable read', false);
go
select set_config('default_transaction_isolation', 'snapshot', false);
go
select set_config('default_transaction_isolation', 'serializable', false);
go

select set_config('transaction_isolation', 'read uncommitted', false);
go
select set_config('transaction_isolation', 'read committed', false);
go
select set_config('transaction_isolation', 'repeatable read', false);
go
select set_config('transaction_isolation', 'snapshot', false);
go
select set_config('transaction_isolation', 'serializable', false);
go
