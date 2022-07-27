create table babel_493_vu_prepare_t1(i int, b bit);
GO

create index babel_493_vu_prepare_t1_full_idx_a on babel_493_vu_prepare_t1(i);
GO

-- FULL index
create index babel_493_vu_prepare_t1_full_idx_b on babel_493_vu_prepare_t1(b);
GO
