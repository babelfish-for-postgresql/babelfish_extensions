SELECT count(*) from babel_493_vu_prepare_t1 where b = 0;
GO

SELECT count(*) from babel_493_vu_prepare_t1 where b = 1;
GO

DROP INDEX babel_493_vu_prepare_t1_full_idx_b ON babel_493_vu_prepare_t1;
GO

CREATE INDEX babel_493_vu_prepare_t1_partial_idx_b on babel_493_vu_prepare_t1(b) where b = 1;
GO

SELECT count(*) from babel_493_vu_prepare_t1 where b = 1;
GO

SELECT count(*) from babel_493_vu_prepare_t1 where b = 1 and i = 4093;
GO

DROP INDEX babel_493_vu_prepare_t1_partial_idx_b ON babel_493_vu_prepare_t1;
GO

CREATE INDEX babel_493_composite_idx_a_b on babel_493_vu_prepare_t1(b,i);
GO

select top(10) * from babel_493_vu_prepare_t1 order by b, i;
GO

select top(10) * from babel_493_vu_prepare_t1 where b = 1 order by i;
GO

select top(10) * from babel_493_vu_prepare_t1 where not (b = 1) order by i;
GO
