create table babel_3090_vu_prepare_t1 (a varchar(1) collate Japanese_CS_AS, 
                            b varchar(2) collate Japanese_CS_AS,
                            c varchar(5) collate Japanese_CS_AS,
                            d char(1) collate Japanese_CS_AS,
                            e char(2) collate Japanese_CS_AS,
                            f char(5) collate Japanese_CS_AS)
GO

-- simple alphabet
insert into babel_3090_vu_prepare_t1 values ('a', 'a', 'a', 'a', 'a', 'a');
GO

-- 'あ' requires two bytes to store

-- shouldn't be allowed to insert 'あ' in varchar(1)
insert into babel_3090_vu_prepare_t1 (a) values ('あ') 
GO

-- shoule be able to insert 'あ' in varchar(2) and varchar(5)
insert into babel_3090_vu_prepare_t1 (b, c) values ('あ', 'あ')
GO

-- shouldn't be allowed to insert 'あ' in char(1)
insert into babel_3090_vu_prepare_t1 (d) values ('あ') 
GO

-- shoule be able to insert 'あ' in char(2) and char(5)
insert into babel_3090_vu_prepare_t1 (e, f) values ('あ', 'あ')
GO

create table babel_3090_vu_prepare_test1 (a varchar(8000) collate japanese_cs_as)
GO

insert into babel_3090_vu_prepare_test1 values (cast (REPLICATE('あ', 5000) as varchar(8000)))
GO

create table babel_3090_vu_prepare_t2 (a nvarchar(1) collate Japanese_CS_AS, 
                            b varchar(2) collate Japanese_CS_AS,
                            c varchar(5) collate Japanese_CS_AS,
                            d char(1) collate Japanese_CS_AS,
                            e char(2) collate Japanese_CS_AS,
                            f char(5) collate Japanese_CS_AS)
GO

-- simple alphabet
insert into babel_3090_vu_prepare_t2 values ('a', 'a', 'a', 'a', 'a', 'a');
GO

-- 'あ' requires two bytes to store

-- shouldn't be allowed to insert 'あ' in varchar(1)
insert into babel_3090_vu_prepare_t2 (a) values ('あ') 
GO

-- shoule be able to insert 'あ' in varchar(2) and varchar(5)
insert into babel_3090_vu_prepare_t2 (b, c) values ('あ', 'あ')
GO

-- shouldn't be allowed to insert 'あ' in char(1)
insert into babel_3090_vu_prepare_t2 (d) values ('あ') 
GO

-- shoule be able to insert 'あ' in char(2) and char(5)
insert into babel_3090_vu_prepare_t2 (e, f) values ('あ', 'あ')
GO

create table babel_3090_vu_prepare_test2 (a varchar(8000) collate japanese_cs_as)
GO

insert into babel_3090_vu_prepare_test2 values (cast (REPLICATE('あ', 5000) as varchar(8000)))
GO

create table babel_3090_vu_prepare_t3 (a nvarchar(1) collate Japanese_CS_AS)
GO

insert into babel_3090_vu_prepare_t3 (a) values ('あ') 
GO