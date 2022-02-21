-- CLUSTERED INDEX / NONCLUSTERED IDNEX
create table t1 ( a int, b int);

create nonclustered index t1_idx1 on t1 (a);
create clustered index t1_idx2 on t1(a);

create table t2 ( a int, b int, primary key nonclustered (a));
create table t3 ( a int, b int, primary key clustered (a));
create table t4 ( a int, b int, unique nonclustered (a));
create table t5 ( a int, b int, unique clustered (a));

create table t6 ( a int primary key nonclustered, b int);
create table t7 ( a int primary key clustered, b int);
create table t8 ( a int unique nonclustered, b int);
create table t9 ( a int unique clustered, b int);

set babelfishpg_tsql.sql_dialect = "tsql";

create index t1_idx1 on t1 (a);
create index t1_idx2 on t1(a);

create table t2 ( a int, b int, primary key (a));
create table t3 ( a int, b int, primary key (a));
create table t4 ( a int, b int, unique (a));
create table t5 ( a int, b int, unique (a));

create table t6 ( a int primary key, b int);
create table t7 ( a int primary key, b int);
create table t8 ( a int unique not null, b int);
create table t9 ( a int unique not null, b int);

-- CREATE INDEX ... ON <filegroup> syntax
create index t1_idx3 on t1 (a) on [primary];
create index t1_idx4 on t1 (a) on "default";

-- CREATE TABLE WITH (<table_option> [,...n]) syntax
create table t10 (a int) 
with (fillfactor = 90, FILETABLE_COLLATE_FILENAME = database_default);
create table t11 (a int) 
with (data_compression = row on partitions (2, 4, 6 to 8));
create table t12 (a int)
with (system_versioning = on (history_table = aaa.bbb, data_consistency_check = off));
create table t13 (a int)
with (remote_data_archive = on (filter_predicate = null, migration_state = outbound));
create table t14 (a int)
with (data_deletion = on (filter_column = a, retention_period = 14 day));

-- CREATE INDEX WHERE... WITH (<index_option> [,...n]) syntax
create index t1_idx5 on t1(a) where a is not null 
with (pad_index = off, fillfactor = 90, maxdop = 1, sort_in_tempdb = off, max_duration = 2 minutes);
create index t1_idx6 on t1(a)
with (data_compression = page on partitions (2, 4, 6 to 8));

-- CREATE COLUMNSTORE INDEX
create columnstore index t1_idx7 on t1 (a) with (drop_existing = on);
create clustered columnstore index t1_idx8 on t1 (a) on [primary];

-- CREATE TABLE... WITH FILLFACTOR = num
create table t15 (a int primary key with fillfactor=50);
-- ALTER TABLE... WITH FILLFACTOR = num
create table t16 (a int not null);
alter table t16 add primary key (a) with fillfactor=50;

-- check property of the index
select indexname, indexdef from pg_indexes where tablename like 't_' order by indexname;

-- CREATE TABLE(..., { PRIMARY KEY | UNIQUE } ...
--                   ON { partition_scheme | filegroup | "default" }) syntax
--                   ^
create table t17(a int, primary key clustered (a) on [PRIMARY]);
create table t18(a int, primary key clustered (a) on [PRIMARY]);
create table t19(a int, unique clustered (a) on [PRIMARY]);
create table t20(a int, unique clustered (a) on [PRIMARY]);

-- ALTER TABLE ... ADD [CONSTRAINT ...] DEFAULT ... FOR ...
create table t21 (a int, b int);
alter table t21 add default 99 for a;
insert into t21(b) values (10);
select * from t21;

alter table t21 alter a drop default;
alter table t21 add constraint dflt11 default 11 for a;
insert into t21(b) values (20);
select * from t21;

-- Invalid default value
alter table t21 add default 'test' for a;
-- Invalid column
alter table t21 add default 99 for c;
-- Invalid table
alter table t_invalid add default 99 for a;

-- ALTER TABLE ... WITH [NO]CHECK ADD CONSTRAINT ...
alter table t21 with check add constraint chk1 check (a > 0);  -- add chk1 and enable it
alter table t21 with nocheck add constraint chk2 check (b > 0);  -- add chk2 and disable it
insert into t21 values (1, 1);
-- error, not fulfilling constraint chk1
insert into t21 values (0, 1);
-- should pass after CHECK/NOCHECK is fully supported
insert into t21 values (1, 0);
select * from t21;

-- ALTER TABLE ... [NO]CHECK CONSTRAINT ...
-- should pass after CHECK/NOCHECK is fully supported
alter table t21 nocheck constraint chk1;  -- disable chk1
alter table t21 check constraint chk2;  -- enable chk2

-- CREATE TABLE ... ( a int identity(...) NOT FOR REPLICATION)
create table t22 (a int identity(1,1) NOT FOR REPLICATION);
create table t23 (a int identity(1,1) NOT FOR REPLICATION NOT NULL);
-- ROWGUIDCOL syntax support
create table t24 (a uniqueidentifier ROWGUIDCOL);
create table t25 (a int);
alter table t25 add b uniqueidentifier ROWGUIDCOL;

-- computed columns
-- CREATE TABLE(..., <column_name> AS <computed_column_expression>
--								   ^	[ PERSISTED ] <column constraints>)
create table computed_column_t1 (a nvarchar(10), b  AS substring(a,1,3) UNIQUE NOT NULL);
insert into computed_column_t1 values('abcd');
select * from computed_column_t1;

-- test whether other constraints are working with computed columns
insert into computed_column_t1 values('abcd'); -- throws error

-- check PERSISTED keyword
-- should be able to use columns from left and right in the expression
create table computed_column_t2 (a int, b  AS (a + c) / 4 PERSISTED, c int);
insert into computed_column_t2 (a,c) values (12, 12);
select * from computed_column_t2;

-- should throw error - order matters
create table computed_column_error (a int, b  AS a/4 NOT NULL PERSISTED);

-- should throw error if postgres syntax is used in TSQL dialect
create table computed_column_error (a int, b numeric generated always as (a/4) stored);

-- should throw error if there is any error in computed column expression
create table computed_column_error (a nvarchar(10), b  AS non_existant_function(a,1,3) UNIQUE NOT NULL);

-- should throw error in case of nested computed columns
create table computed_column_error (a int, b as c, c as a);
create table computed_column_error (a int, b as b + 1);

-- in case of multiple computed column, the entire statement should be rolled
-- back even when the last one throws error
create table computed_column_error (a int, b as a, c as b);
select * from computed_column_error;

-- ALTER TABLE... ADD <column_name> AS <computed_column_expression>
--							  	    ^	[ PERSISTED ] <column constraints>)
alter table computed_column_t1 add c int;
alter table computed_column_t1 add d as c / 4;
insert into computed_column_t1(a, c) VALUES ('efgh', 12);
select * from computed_column_t1;

--should thow error in case of nested computed columns
 alter table computed_column_t1 add e as d;
 alter table computed_column_t1 add e as e + 1;

-- should throw error if any of the dependant columns is modified or dropped.
alter table computed_column_t1 drop column a;
alter table computed_column_t1 alter column a varchar;

-- should throw error as rand is non-deterministic
alter table computed_column_t1 add e as rand() persisted;

-- but rand[seed] should succeed
alter table computed_column_t1 add e as rand(1) persisted;

-- should throw error in postgres dialect
select set_config('babelfishpg_tsql.sql_dialect', 'postgres', null);
create table computed_column_error (a int, b  AS (a/4) PERSISTED NOT NULL);

-- since we're in postgres dialect, also check the table definition whether
-- the computed column got resolved to correct datatype
\d computed_column_t1

set babelfishpg_tsql.sql_dialect = "tsql";

drop table t1;
drop table t2;
drop table t3;
drop table t4;
drop table t5;
drop table t6;
drop table t7;
drop table t8;
drop table t9;
drop table t10;
drop table t11;
drop table t12;
drop table t13;
drop table t14;
drop table t15;
drop table t16;
drop table t17;
drop table t18;
drop table t19;
drop table t20;
drop table t21;
drop table t22;
drop table t23;
drop table t24;
drop table t25;
drop table computed_column_t1;
drop table computed_column_t2;
