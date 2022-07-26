insert into babel_405_vu_prepare_insert2 values(2);
go

select * from babel_405_vu_prepare_insert2;
go

drop trigger babel_405_vu_prepare_tr1;
go

create trigger babel_405_vu_prepare_tr1 on babel_405_vu_prepare_insert2 instead of insert
as
begin
end
go

insert into babel_405_vu_prepare_insert2 values(2);
select * from babel_405_vu_prepare_insert2;
go

drop trigger babel_405_vu_prepare_tr1;
go

insert into babel_405_vu_prepare_insert2 values(2);
select * from babel_405_vu_prepare_insert2;
go


delete from babel_405_vu_prepare_delete2 where 1=1;
go

select * from babel_405_vu_prepare_delete2;
go

drop trigger babel_405_vu_prepare_tr3;
go

create trigger babel_405_vu_prepare_tr3 on babel_405_vu_prepare_delete2 instead of delete
as
begin
end
go

delete from babel_405_vu_prepare_delete2;
select * from babel_405_vu_prepare_delete2;
go

drop trigger babel_405_vu_prepare_tr3;
go

insert into babel_405_vu_prepare_delete2 values(2);
select * from babel_405_vu_prepare_delete2;
go


update babel_405_vu_prepare_update2 set x = 2 where x=1;
go
  
select * from babel_405_vu_prepare_update2;
go
  
drop trigger babel_405_vu_prepare_tr5;
go
  
create trigger babel_405_vu_prepare_tr5 on babel_405_vu_prepare_update2 instead of update
as
begin
end
go
  
update babel_405_vu_prepare_update2 set x = 3 where 1 = 1;
select * from babel_405_vu_prepare_update2;
go
  
drop trigger babel_405_vu_prepare_tr5;
go

update babel_405_vu_prepare_update2 set x=2 where x=1;
select * from babel_405_vu_prepare_update2;
go


insert into babel_405_vu_prepare_insert4 values(3);
go

drop trigger babel_405_vu_prepare_tr7;
go

insert into babel_405_vu_prepare_insert4 values(3);
go

select * from babel_405_vu_prepare_insert4;
go

drop trigger babel_405_vu_prepare_after_trig;

insert into babel_405_vu_prepare_insert4 values(3);
go

select * from babel_405_vu_prepare_insert4;
go

