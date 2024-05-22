EXECUTE sp_babelfish_configure 'escape_hatch_unique_constraint', 'ignore'
go

create table babel_621_vu_prepare_table_1 (a int);
go
create table babel_621_vu_prepare_table_2 (a int);
go
create index idx on babel_621_vu_prepare_table_1(a);
go
create index idx on babel_621_vu_prepare_table_2(a);
go

create table babel_621_vu_prepare_table_3 (a int);
go
alter table babel_621_vu_prepare_table_3 add constraint uniq unique (a);
go
create index uniq on babel_621_vu_prepare_table_3(a);
go

create table babel_621_vu_prepare_table_4 (a int);
go
create index uniq_table_4 on babel_621_vu_prepare_table_4(a);
go
alter table babel_621_vu_prepare_table_4 add constraint uniq_table_4 unique (a);
go
alter table babel_621_vu_prepare_table_4 drop constraint uniq_table_4;
go

-- Very long index name
create table babel_621_vu_prepare_table_with_long_index_name (a int);
go
create index very_long_index_name_on_a_table_1234567890_1234567890_1234567890_1234567890_1234567890 on babel_621_vu_prepare_table_with_long_index_name(a);
go

create table babel_621_vu_prepare_second_table_with_long_index_name (a int);
go
create index very_long_index_name_on_a_table_1234567890_1234567890_1234567890_1234567890_1234567890 on babel_621_vu_prepare_second_table_with_long_index_name(a);
go

-- Very long table name and very long index name
create table babel_621_table_with_long_name_1234567890_1234567890_1234567890_1234567890_1234567890 (a int);
go
create index very_long_index_name_on_a_table_1234567890_1234567890_1234567890_1234567890_1234567890 on babel_621_table_with_long_name_1234567890_1234567890_1234567890_1234567890_1234567890(a);
go

create table babel_621_second_table_with_long_name_1234567890_1234567890_1234567890_1234567890_1234567890 (a int);
go
create index very_long_index_name_on_a_table_1234567890_1234567890_1234567890_1234567890_1234567890 on babel_621_second_table_with_long_name_1234567890_1234567890_1234567890_1234567890_1234567890(a);
go

-- Situation where simple concatenation of table and index name does not work 
-- E.g. table_a + index_a == table_b + index_b
create table babel_621_vu_prepare_table_6 (a int);
go
create index idx_ on babel_621_vu_prepare_table_6(a);
go

create table table_6 (a int);
go
create index idx_babel_621_vu_prepare_ on table_6(a);
go
-- Situation where simple concatenation of index and table name does not work (reverse of previous) 
-- E.g. index_a + table_a == index_b + table_b 
create table table_7 (a int);
go
create index idx_babel_621_vu_prepare_ on table_7(a);
go

create table babel_621_vu_prepare_table_7 (a int);
go
create index idx_ on babel_621_vu_prepare_table_7(a);
go

--
create table babel_621_vu_prepare_table_8 (
    a int,
    value int,
    constraint constraint_8 unique nonclustered
        (
        value asc
        )
    )
go
alter table babel_621_vu_prepare_table_8 drop constraint constraint_8;
go
insert into babel_621_vu_prepare_table_8 values(1, 1);
insert into babel_621_vu_prepare_table_8 values(2, 1);
go

create table babel_621_vu_prepare_table_10
(
    a int,
    b int,
    c int
)
go
create unique index idx on babel_621_vu_prepare_table_10 (a, b);
go
insert into babel_621_vu_prepare_table_10 values(1, 1, 1);
insert into babel_621_vu_prepare_table_10 values(1, 2, 1);
insert into babel_621_vu_prepare_table_10 values(1, 2, 2);
go