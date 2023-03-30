-- CLUSTERED INDEX / NONCLUSTERED IDNEX
create table t1 ( a int, b int);
GO

create nonclustered index t1_idx1 on t1 (a);
GO

create clustered index t1_idx2 on t1(a);
GO

create table t2 ( a int, b int, primary key nonclustered (a));
GO
create table t3 ( a int, b int, primary key clustered (a));
GO
create table t4 ( a int, b int, unique nonclustered (a));
GO
create table t5 ( a int, b int, unique clustered (a));
GO

create table t6 ( a int primary key nonclustered, b int);
GO
create table t7 ( a int primary key clustered, b int);
GO

create table t8 ( a int unique not null, b int);
GO
create table t9 ( a int unique not null, b int);
GO

-- CREATE INDEX ... ON <filegroup> syntax
create index t1_idx3 on t1 (a) on [primary];
GO
create index t1_idx4 on t1 (a) on "default";
GO

-- CREATE TABLE WITH (<table_option> [,...n]) syntax
create table t12 (a int)
with (system_versioning = on (history_table = aaa.bbb, data_consistency_check = off));
GO
create table t13 (a int)
with (remote_data_archive = on (filter_predicate = null, migration_state = outbound));
GO
create table t14 (a int)
with (data_deletion = on (filter_column = a, retention_period = 14 day));
GO


-- CREATE TABLE... WITH FILLFACTOR = num
create table t15 (a int primary key with fillfactor=50);
GO
-- ALTER TABLE... WITH FILLFACTOR = num
create table t16 (a int not null);
GO
alter table t16 add primary key (a) with fillfactor=50;
GO

-- check property of the index
select indexname, indexdef from pg_indexes where tablename like 't_' order by indexname;
GO

-- CREATE TABLE(..., { PRIMARY KEY | UNIQUE } ...
--                   ON { partition_scheme | filegroup | "default" }) syntax
--                   ^
create table t17(a int, primary key clustered (a) on [PRIMARY]);
GO
create table t18(a int, primary key clustered (a) on [PRIMARY]);
GO
create table t19(a int, unique clustered (a) on [PRIMARY]);
GO
create table t20(a int, unique clustered (a) on [PRIMARY]);
GO

-- ALTER TABLE ... ADD [CONSTRAINT ...] DEFAULT ... FOR ...
create table t21 (a int, b int);
GO
alter table t21 add default 99 for a;
GO
insert into t21(b) values (10);
GO
select * from t21;
GO

alter table t21 add constraint dflt11 default 11 for a;
GO
insert into t21(b) values (20);
GO
select * from t21;
GO

-- Invalid default value
alter table t21 add default 'test' for a;
GO
-- Invalid column
alter table t21 add default 99 for c;
GO
-- Invalid table
alter table t_invalid add default 99 for a;
GO

-- ALTER TABLE ... WITH [NO]CHECK ADD CONSTRAINT ...
insert into t21 values (1, 1);
GO
-- error, not fulfilling constraint chk1
insert into t21 values (0, 1);
GO
-- should pass after CHECK/NOCHECK is fully supported
insert into t21 values (1, 0);
GO
select * from t21;
GO


-- ROWGUIDCOL syntax support
create table t24 (a uniqueidentifier ROWGUIDCOL);
GO
create table t25 (a int);
GO
alter table t25 add b uniqueidentifier ROWGUIDCOL;
GO

-- computed columns
-- CREATE TABLE(..., <column_name> AS <computed_column_expression>
--								   ^	[ PERSISTED ] <column constraints>)
create table computed_column_t1 (a nvarchar(10), b  AS substring(a,1,3) UNIQUE NOT NULL);
GO
insert into computed_column_t1 values('abcd');
GO
select * from computed_column_t1;
GO

-- test whether other constraints are working with computed columns
insert into computed_column_t1 values('abcd'); -- throws error
GO

-- check PERSISTED keyword
-- should be able to use columns from left and right in the expression
create table computed_column_t2 (a int, b  AS (a + c) / 4 PERSISTED, c int);
GO
insert into computed_column_t2 (a,c) values (12, 12);
GO
select * from computed_column_t2;
GO

-- should throw error - order matters
create table computed_column_error (a int, b  AS a/4 NOT NULL PERSISTED);
GO

-- should throw error if postgres syntax is used in TSQL dialect
create table computed_column_error (a int, b numeric generated always as (a/4) stored);
GO

-- should throw error if there is any error in computed column expression
create table computed_column_error (a nvarchar(10), b  AS non_existant_function(a,1,3) UNIQUE NOT NULL);
GO
-- should throw error in case of nested computed columns
create table computed_column_error (a int, b as c, c as a);
GO
create table computed_column_error (a int, b as b + 1);
GO

-- in case of multiple computed column, the entire statement should be rolled
-- back even when the last one throws error
create table computed_column_error (a int, b as a, c as b);
GO
select * from computed_column_error;
GO

-- ALTER TABLE... ADD <column_name> AS <computed_column_expression>
--							  	    ^	[ PERSISTED ] <column constraints>)
alter table computed_column_t1 add c int;
GO
alter table computed_column_t1 add d as c / 4;
GO
insert into computed_column_t1(a, c) VALUES ('efgh', 12);
GO
select * from computed_column_t1;
GO

--should thow error in case of nested computed columns
alter table computed_column_t1 add e as d;
GO
alter table computed_column_t1 add e as e + 1;
GO

-- should throw error if any of the dependant columns is modified or dropped.
alter table computed_column_t1 drop column a;
GO
alter table computed_column_t1 alter column a varchar;
GO

-- should throw error as rand is non-deterministic
alter table computed_column_t1 add e as rand() persisted;
GO

-- but rand[seed] should succeed
alter table computed_column_t1 add e as rand(1) persisted;
GO

-- should throw error in postgres dialect
select set_config('babelfishpg_tsql.sql_dialect', 'postgres', null);
GO
create table computed_column_error (a int, b  AS (a/4) PERSISTED NOT NULL);
GO

-- since we're in postgres dialect, also check the table definition whether
-- the computed column got resolved to correct datatype
SELECT * FROM computed_column_t1
GO


drop table t1;
GO
drop table t2;
GO
drop table t3;
GO
drop table t4;
GO
drop table t5;
GO
drop table t6;
GO
drop table t7;
GO
drop table t8;
GO
drop table t9;
GO
drop table t12;
GO
drop table t13;
GO
drop table t14;
GO
drop table t15;
GO
drop table t16;
GO
drop table t17;
GO
drop table t18;
GO
drop table t19;
GO
drop table t20;
GO
drop table t21;
GO
drop table t24;
GO
drop table t25;
GO
drop table computed_column_t1;
GO
drop table computed_column_t2;
GO