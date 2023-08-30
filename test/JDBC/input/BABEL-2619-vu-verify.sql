-- Tests to check whether error will be raised in case of creation of unique constraint/index on nullable column

-- Test 1: trying to create unique constraint on nullable and non null columns 
-- when babelfishpg_tsql.escape_hatch_unique_constraint is set to STRICT (Default value)
create table babel_2619_v_t1(a int null, b int null unique, c int not null)
go

create table babel_2619_v_t2(a int null, b int not null unique, c int not null)
go

create table babel_2619_v_t3(a int null, b int unique, c int not null)
go

create table babel_2619_v_t4(a int null, b int not null, unique(a))
go

create table babel_2619_v_t5(a int null, b int not null, unique(b))
go

create table babel_2619_v_t6(a int not null, b int null, c int not null, unique(a, b, c))
go

create table babel_2619_v_t7(a int not null, b int null, c int not null, unique(a, c))
go

drop table if exists babel_2619_v_t1;
drop table if exists babel_2619_v_t2;
drop table if exists babel_2619_v_t3;
drop table if exists babel_2619_v_t4;
drop table if exists babel_2619_v_t5;
drop table if exists babel_2619_v_t6;
drop table if exists babel_2619_v_t7;
go

-- when babelfishpg_tsql.escape_hatch_unique_constraint is set to IGNORE
exec sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'ignore';
go

create table babel_2619_v_t8(a int null, b int null unique, c int not null)
go

create table babel_2619_v_t9(a int null, b int not null unique, c int not null)
go

create table babel_2619_v_t10(a int null, b int unique, c int not null)
go

create table babel_2619_v_t11(a int null, b int not null, unique(a))
go

create table babel_2619_v_t12(a int null, b int not null, unique(b))
go

create table babel_2619_v_t13(a int not null, b int null, c int not null, unique(a, b, c))
go

create table babel_2619_v_t14(a int not null, b int null, c int not null, unique(a, c))
go

drop table if exists babel_2619_v_t8;
drop table if exists babel_2619_v_t9;
drop table if exists babel_2619_v_t10;
drop table if exists babel_2619_v_t11;
drop table if exists babel_2619_v_t12;
drop table if exists babel_2619_v_t13;
drop table if exists babel_2619_v_t14;
go

exec sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'strict';
go

-- Test 2: trying to creating unique index on nullable and non null columns
-- Table definition: babel_2619_t1(a int not null, b int null)
-- when babelfishpg_tsql.escape_hatch_unique_constraint is set to STRICT (Default value)
create unique index ix1 on babel_2619_t1(a)
go

create unique index ix2 on babel_2619_t1(b)
go

create unique index ix3 on babel_2619_t1(a,b)
go

-- Table definition: babel_2619_t2(a int not null, b int null)
-- when babelfishpg_tsql.escape_hatch_unique_constraint is set to IGNORE
exec sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'ignore';
go

create unique index ix1 on babel_2619_t2(a)
go

create unique index ix2 on babel_2619_t2(b)
go

create unique index ix3 on babel_2619_t2(a,b)
go

exec sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'strict';
go


-- Test 3: trying to alter table to add a column with unique contraint on nullable and non null columns
-- Table definition: babel_2619_t3(a int not null, b int null)
-- when babelfishpg_tsql.escape_hatch_unique_constraint is set to STRICT (Default value)
alter table babel_2619_t3 add col_c int null unique;
go

alter table babel_2619_t3 add col_d int not null unique;
go

-- Table definition: babel_2619_t4(a int not null, b int null)
-- when babelfishpg_tsql.escape_hatch_unique_constraint is set to IGNORE
exec sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'ignore';
go

alter table babel_2619_t4 add col_c int null unique;
go

alter table babel_2619_t4 add col_d int not null unique;
go

exec sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'strict';
go


-- Test 4: trying to alter table to add unique contraint on nullable and non null columns
-- Table definition: babel_2619_t5_1(a int not null, b int null),
-- babel_2619_t5_2(a int not null, b int null),
-- babel_2619_t5_3(a int not null, b int null)
-- when babelfishpg_tsql.escape_hatch_unique_constraint is set to STRICT (Default value)
alter table babel_2619_t5_1 add constraint uq_a unique (a);
go

alter table babel_2619_t5_2 add constraint uq_b unique (b);
go

alter table babel_2619_t5_3 add constraint uq_ab unique (a, b);
go

-- Table definition: babel_2619_t6_1(a int not null, b int null),
-- babel_2619_t6_2(a int not null, b int null),
-- babel_2619_t6_3(a int not null, b int null)
-- when babelfishpg_tsql.escape_hatch_unique_constraint is set to IGNORE
exec sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'ignore';
go

alter table babel_2619_t6_1 add constraint uq_a unique (a);
go

alter table babel_2619_t6_2 add constraint uq_b unique (b);
go

alter table babel_2619_t6_3 add constraint uq_ab unique (a, b);
go

exec sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_unique_constraint', 'strict';
go