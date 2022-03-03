EXECUTE sp_babelfish_configure 'escape_hatch_unique_constraint', 'ignore'
go

create table table_1 (
    a int,
    b int,
    c int,
    d int,
    constraint pk primary key(
            a asc,
            b desc,
            c desc
    ),
    unique (
        a desc,
        b desc,
        d desc
    )
);
go

alter table table_1 add constraint new_constr unique (
    a desc,
    b asc,
    c desc,
    d desc
)
go
--
insert into table_1 values (1, 1, 1, 1);
insert into table_1 values (1, 2, 1, 1);
insert into table_1 values (1, 3, 1, 1);
insert into table_1 values (1, 1, 2, 2);
insert into table_1 values (1, 2, 2, 2);
go
-- check that we are actually using constraint index in the query plan
select
    a, b, c, d 
from table_1
order by
    a asc,
    b desc, 
    c desc
;
go
--
select
    a, b, d
from table_1
order by
    a desc,
    b desc,
    d desc
;
go

drop table table_1;
go

