insert into babel_493_vu_prepare_t1 values (1, 0), (2, 0), (3, 0), (4, 0);
insert into babel_493_vu_prepare_t1 select i+4, b from babel_493_vu_prepare_t1;
insert into babel_493_vu_prepare_t1 select i+8, b from babel_493_vu_prepare_t1;
insert into babel_493_vu_prepare_t1 select i+16, b from babel_493_vu_prepare_t1;
insert into babel_493_vu_prepare_t1 select i+32, b from babel_493_vu_prepare_t1;
insert into babel_493_vu_prepare_t1 select i+64, b from babel_493_vu_prepare_t1;
insert into babel_493_vu_prepare_t1 select i+128, b from babel_493_vu_prepare_t1;
insert into babel_493_vu_prepare_t1 select i+256, b from babel_493_vu_prepare_t1;
insert into babel_493_vu_prepare_t1 select i+512, b from babel_493_vu_prepare_t1;
insert into babel_493_vu_prepare_t1 select i+1024, b from babel_493_vu_prepare_t1;
insert into babel_493_vu_prepare_t1 select i+2048, b from babel_493_vu_prepare_t1;
-- make a few rows have bit value 1
update babel_493_vu_prepare_t1 set b = 1 where i = 3;
update babel_493_vu_prepare_t1 set b = 1 where i = 1111;
update babel_493_vu_prepare_t1 set b = 1 where i = 4093;
-- make a few rows have bit value NULL
update babel_493_vu_prepare_t1 set b = NULL where i = 7;
update babel_493_vu_prepare_t1 set b = NULL where i = 2222;
GO

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
