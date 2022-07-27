EXECUTE sp_babelfish_configure 'escape_hatch_unique_constraint', 'ignore'
go


alter table babel_404_vu_prepare_t1 add constraint new_constr unique (
    a desc,
    b asc,
    c desc,
    d desc
)
go
--
insert into babel_404_vu_prepare_t1 values (1, 1, 1, 1);
insert into babel_404_vu_prepare_t1 values (1, 2, 1, 1);
insert into babel_404_vu_prepare_t1 values (1, 3, 1, 1);
insert into babel_404_vu_prepare_t1 values (1, 1, 2, 2);
insert into babel_404_vu_prepare_t1 values (1, 2, 2, 2);
go
-- check that we are actually using constraint index in the query plan
select
    a, b, c, d 
from babel_404_vu_prepare_t1
order by
    a asc,
    b desc, 
    c desc
;
go
--
select
    a, b, d
from babel_404_vu_prepare_t1
order by
    a desc,
    b desc,
    d desc
;
go
