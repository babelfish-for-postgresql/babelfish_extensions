-- This covers BABEL-1483 (Support DROP INDEX table.index syntax) and BABEL-1652 (Support DROP INDEX ix ON schema.table syntax)
use master
go

-- tests with '[schema_name.]table_name.index_name' syntax
create table dbo.t1_drop_index(a int)
go
create index ix1 on dbo.t1_drop_index(a)
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go

create table guest.t1_drop_index(a int)
go
create index ix1 on guest.t1_drop_index(a)
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go

drop index guest.t1_drop_index.ix1
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go
drop index guest.t1_drop_index.ix1
go
drop index if exists guest.t1_drop_index.ix1
go
drop index guest.t1_drop_index.ix2
go
drop index if exists guest.t1_drop_index.ix2
go

drop index dbo.t1_drop_index.ix1
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go
drop index dbo.t1_drop_index.ix1
go
drop index if exists dbo.t1_drop_index.ix1
go
drop index dbo.t1_drop_index.ix2
go
drop index if exists dbo.t1_drop_index.ix2
go

create index ix1 on dbo.t1_drop_index(a)
go
create index ix1 on guest.t1_drop_index(a)
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go

drop index t1_drop_index.ix1
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go
drop index t1_drop_index.ix1
go
drop index if exists t1_drop_index.ix1
go

-- dynamic SQL
create index ix1 on dbo.t1_drop_index(a)
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go
execute('drop index guest.t1_drop_index.ix1')
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go
execute('drop index guest.t1_drop_index.ix1')
go
execute('drop index if exists guest.t1_drop_index.ix1')
go

execute('drop index t1_drop_index.ix1')
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go
execute('drop index t1_drop_index.ix1')
go
execute('drop index if exists t1_drop_index.ix1')
go

-- stored proc
create index ix1 on dbo.t1_drop_index(a)
go
create index ix1 on guest.t1_drop_index(a)
go
execute p1_drop_index
go
execute p1_drop_index
go
execute p1_drop_index 1
go

-- non-existing schema/table
drop index nosuchtable.ix1
go
drop index if exists nosuchtable.ix1
go
drop index nosuchschema.nosuchtable.ix1
go
drop index if exists nosuchschema.nosuchtable.ix1
go


use master
go
create index ix1 on guest.t1_drop_index(a)
go

use tempdb
go
create table dbo.t1_drop_index(a int)
go
create index ix1 on dbo.t1_drop_index(a)
go
create table guest.t1_drop_index(a int)
go
create index ix1 on guest.t1_drop_index(a)
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4	
go
drop index guest.t1_drop_index.ix1
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4	
go
use master
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4	
go
drop index dbo.t1_drop_index.ix1
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4	
go
use tempdb
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4	
go
use master
go
drop index guest.t1_drop_index.ix1
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4	
go
use tempdb
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4	
go

-- cross-db reference: always error with 3-part table name
use master
go
drop index tempdb.dbo.sometable.someindex
go
drop index if exists tempdb.dbo.sometable.someindex
go

-- tests with 'index_name ON [schema_name.]table_name' syntax

use master
go
drop table dbo.t1_drop_index
go
drop table guest.t1_drop_index
go

create table dbo.t1_drop_index(a int)
go
create index ix1 on dbo.t1_drop_index(a)
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go

create table guest.t1_drop_index(a int)
go
create index ix1 on guest.t1_drop_index(a)
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go

drop index ix1 on guest.t1_drop_index
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go
drop index ix1 on guest.t1_drop_index
go
drop index if exists ix1 on guest.t1_drop_index
go
drop index ix2 on guest.t1_drop_index
go
drop index if exists ix2 on guest.t1_drop_index
go

drop index ix1 on dbo.t1_drop_index
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go
drop index ix1 on dbo.t1_drop_index
go
drop index if exists ix1 on dbo.t1_drop_index
go
drop index ix2 on dbo.t1_drop_index
go
drop index if exists ix2 on dbo.t1_drop_index
go

create index ix1 on dbo.t1_drop_index(a)
go
create index ix1 on guest.t1_drop_index(a)
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go

drop index ix1 on t1_drop_index
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go
drop index ix1 on t1_drop_index
go
drop index if exists ix1 on t1_drop_index
go

-- dynamic SQL
create index ix1 on dbo.t1_drop_index(a)
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go
execute('drop index ix1 on guest.t1_drop_index')
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go
execute('drop index ix1 on guest.t1_drop_index')
go
execute('drop index if exists ix1 on guest.t1_drop_index')
go

execute('drop index ix1 on t1_drop_index')
go
select db_name(), object_name(id), object_schema_name(id), name from sysindexes where name like 'ix1%' order by 1,2,3,4
go
execute('drop index ix1 on t1_drop_index')
go
execute('drop index if exists ix1 on t1_drop_index')
go

-- stored proc
create index ix1 on dbo.t1_drop_index(a)
go
create index ix1 on guest.t1_drop_index(a)
go
execute p2_drop_index
go
execute p2_drop_index
go
execute p2_drop_index 1
go

-- non-existing schema/table
drop index ix1 on nosuchtable
go
drop index if exists ix1 on nosuchtable
go
drop index ix1 on nosuchschema.nosuchtable
go
drop index if exists ix1 on nosuchschema.nosuchtable
go

-- always error with cross-db syntax (3-part table name) and remote syntax (4-part table name)
use master
go
drop index someindex ON tempdb.dbo.sometable
go
drop index if exists someindex ON tempdb.dbo.sometable
go
drop index someindex ON someserver.tempdb.dbo.sometable
go
drop index if exists someindex ON someserver.tempdb.dbo.sometable
go
