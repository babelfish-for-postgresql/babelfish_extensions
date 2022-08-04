create table babel_493_vu_prepare_t1(i int, b bit);
GO

create index babel_493_vu_prepare_t1_full_idx_a on babel_493_vu_prepare_t1(i);
GO

-- FULL index
create index babel_493_vu_prepare_t1_full_idx_b on babel_493_vu_prepare_t1(b);
GO

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
