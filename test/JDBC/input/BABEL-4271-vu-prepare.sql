-- Test to check like escape null and like escape ''
create table babel_4271_vu_prepare_t1(a varchar(30), b varchar(30));
go

insert into babel_4271_vu_prepare_t1 values ('cbc','[c-a]bc');
insert into babel_4271_vu_prepare_t1 values ('cbc','[a-c]bc');
insert into babel_4271_vu_prepare_t1 values ('abc','abc');
insert into babel_4271_vu_prepare_t1 values ('cbc','def');
insert into babel_4271_vu_prepare_t1 values (' abc','abc')
insert into babel_4271_vu_prepare_t1 values ('abc','def')
insert into babel_4271_vu_prepare_t1 values ('','')
go