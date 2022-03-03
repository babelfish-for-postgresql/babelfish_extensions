EXECUTE sp_babelfish_configure 'escape_hatch_unique_constraint', 'ignore'
go

create table table_1 (a int);
go
create table table_2 (a int);
go
create index idx on table_1(a);
go
create index idx on table_2(a);
go
drop index idx on table_1;
drop index idx on table_2;
go

-- Index names and constaint name share the same namespace
create table table_3 (a int);
go
alter table table_3 add constraint uniq unique (a);
go
create index uniq on table_3(a);
go
drop index uniq on table_3;
go
--
create table table_4 (a int);
go
create index uniq_table_4 on table_4(a);
go
alter table table_4 add constraint uniq_table_4 unique (a);
go
alter table table_4 drop constraint uniq_table_4;
go

-- Test that `sp_rename` is NOT available. If it is available, we need more tests with index/constraints renames
-- We expect this test to break when `sp_rename` will be implemented
go
exec sp_rename N'table_4.uniq_table_4', N'uniq_table_4_a', N'INDEX';
go

-- Very long index name
create table table_with_long_index_name (a int);
go
create index very_long_index_name_on_a_table_1234567890_1234567890_1234567890_1234567890_1234567890 on table_with_long_index_name(a);
go
drop index very_long_index_name_on_a_table_1234567890_1234567890_1234567890_1234567890_1234567890 on table_with_long_index_name;
go
create table second_table_with_long_index_name (a int);
go
create index very_long_index_name_on_a_table_1234567890_1234567890_1234567890_1234567890_1234567890 on second_table_with_long_index_name(a);
go

-- Very long table name and very long index name
create table table_with_long_index_name_1234567890_1234567890_1234567890_1234567890_1234567890 (a int);
go
create index very_long_index_name_on_a_table_1234567890_1234567890_1234567890_1234567890_1234567890 on table_with_long_index_name_1234567890_1234567890_1234567890_1234567890_1234567890(a);
go
drop index very_long_index_name_on_a_table_1234567890_1234567890_1234567890_1234567890_1234567890 on table_with_long_index_name_1234567890_1234567890_1234567890_1234567890_1234567890;
go
create table second_table_with_long_index_name_1234567890_1234567890_1234567890_1234567890_1234567890 (a int);
go
create index very_long_index_name_on_a_table_1234567890_1234567890_1234567890_1234567890_1234567890 on second_table_with_long_index_name_1234567890_1234567890_1234567890_1234567890_1234567890(a);
go

-- Situation where simple concatenation of table and index name does not work 
-- E.g. table_a + index_a == table_b + index_b
create table aa_table_6 (a int);
go
create index idx_ on aa_table_6(a);
go

create table table_6 (a int);
go
create index idx_aa_ on table_6(a);
go
-- Situation where simple concatenation of index and table name does not work (reverse of previous) 
-- E.g. index_a + table_a == index_b + table_b 
create table table_7 (a int);
go
create index idx_aa_ on table_7(a);
go

create table aa_table_7 (a int);
go
create index idx_ on aa_table_7(a);
go

--
create table table_8 (
    a int,
    value int,
    constraint constraint_8 unique nonclustered
        (
        value asc
        )
    )
go
alter table table_8 drop constraint constraint_8;
go
insert into table_8 values(1, 1);
insert into table_8 values(2, 1);
go
select a, value from table_8 order by a;
go
drop table table_8;
go

-- index with multiple columns
create table table_10
(
    a int,
    b int,
    c int
)
go
create unique index idx on table_10 (a, b);
go
insert into table_10 values(1, 1, 1);
insert into table_10 values(1, 2, 1);
insert into table_10 values(1, 2, 2);
go
drop index idx on table_10;
go
insert into table_10 values(1, 2, 2);
go
drop table table_1;
go
drop table table_2;
go
drop table table_3;
go
drop table table_4;
go
drop table table_with_long_index_name;
go
drop table second_table_with_long_index_name;
go
drop table table_with_long_index_name_1234567890_1234567890_1234567890_1234567890_1234567890;
go
drop table second_table_with_long_index_name_1234567890_1234567890_1234567890_1234567890_1234567890;
go
drop table aa_table_6;
go
drop table table_6;
go
drop table table_7;
go
drop table aa_table_7;
go
drop table table_8;
go
drop table table_10;
go
