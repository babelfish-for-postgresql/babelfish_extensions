declare @tv TestTableType_vu_prepare_t1;
insert @tv values (1,1);
insert @tv values (2,2);
select * from @tv;
go

declare @tv TestTableType_vu_prepare_t2;
insert @tv values(1,'one');
insert @tv values(2,'two');
insert @tv values(3,'three');
select * from @tv;
insert @tv values(6,'six');
go

declare @tv TestTableType_vu_prepare_t3;
insert @tv  values ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
insert @tv (a, b, c, e, f, g) values ('Orange', NULL, 3, N'Happy😀',  '1900-02-28 23:59:59.989', 342.5);
select * from @tv;
go


declare @tv TestTableType_vu_prepare_t3;
insert @tv  values ('Apple', N'red', 1, 'Delhi', N'Sad😞',  '2000-12-13 12:58:23.123', 123.1); 
insert @tv  values ('Apple', N'blue', 2, 'Chennai', N'Neutral😐',  '2006-11-11 22:47:23.128', 512.4); 
select * from @tv;

go

exec TestTableType_vu_prepare_proc1;
go