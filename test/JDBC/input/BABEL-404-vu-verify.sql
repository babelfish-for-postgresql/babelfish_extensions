EXECUTE sp_babelfish_configure 'escape_hatch_unique_constraint', 'ignore'
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
