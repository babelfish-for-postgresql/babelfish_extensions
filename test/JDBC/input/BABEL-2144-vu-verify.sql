UPDATE babel_2144_vu_prepare_t1 SET c1 = 23 OUTPUT INSERTED.c2, 22 INTO babel_2144_vu_prepare_v1;
go
UPDATE babel_2144_vu_prepare_t2 SET c1 = 0 OUTPUT INSERTED.c2, 22 INTO babel_2144_vu_prepare_v1;
go
UPDATE babel_2144_vu_prepare_t2 SET c1 = 23 OUTPUT INSERTED.c2, 22 INTO babel_2144_vu_prepare_t2;
go
UPDATE babel_2144_vu_prepare_t2 SET c1 = 0 OUTPUT INSERTED.c1, 33 INTO babel_2144_vu_prepare_t2;
go
UPDATE babel_2144_vu_prepare_t1 SET c1 = 1 OUTPUT INSERTED.c2, 11 INTO babel_2144_vu_prepare_t1;
go
UPDATE babel_2144_vu_prepare_t1 SET c1 = 2 OUTPUT INSERTED.c1, 1 INTO babel_2144_vu_prepare_t2;
go
select * from babel_2144_vu_prepare_t1;
go
select * from babel_2144_vu_prepare_t2;
go
select * from babel_2144_vu_prepare_v1;
go
