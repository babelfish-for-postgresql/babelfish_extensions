create database babel_4270
go
use babel_4270
go

create table t ( a varchar(30));
go
insert into t values ('0');
go
insert into t values ('4270');
go
insert into t values ('0.599');
go
insert into t values ('abc');
go
insert into t values ('abc_d_');
go
insert into t values ('bbc_d_');
go
insert into t values ('xbc_f_');
go
insert into t values ('abcdde');
go
insert into t values ('abc\_d\_');
go
insert into t values ('abc\_d_');
go
insert into t values ('abc\ad\c');
go
insert into t values ('abc\cd\_');
go
insert into t values ('abc\xFEcd\_');
go
insert into t values ('abc\xFFcd\_');
go
insert into t values ('abcxFFcd\_');
go

create function BABEL_4270_abc()
returns varchar(20)
as
    begin
        return 'abc\xFE%'
    end
go


create procedure BABEL_4270_test_default_escape
as
    begin
        select * from t where a like 'abc\%'
    end
go