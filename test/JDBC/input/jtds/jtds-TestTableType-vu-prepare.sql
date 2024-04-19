create type TestTableType_vu_prepare_t1 as table (c1 int, c2 int);
go

create type TestTableType_vu_prepare_t2 as table (c1 int, c2 varchar(30), check (c1 < 5));
go

create type TestTableType_vu_prepare_t3 as table (a varchar(15) UNIQUE NOT NULL, b nvarchar(25), c int PRIMARY KEY, d char(15) DEFAULT 'Whoops!', e nchar(25), f datetime, g numeric(4,1) CHECK (g >= 103.5))
go

create type TestTableType_vu_prepare_t4 as table(a text not null, b int primary key, c int);
go

create function TestTableType_vu_prepare_func1 (@number int, @tv TestTableType_vu_prepare_t4 READONLY) returns table as return (
select *, @number from @tv 
);
go

create procedure TestTableType_vu_prepare_proc1 as
begin
    declare @tv TestTableType_vu_prepare_t4
    insert into @tv values('hello1', 1, 1001)
    insert into @tv values('hello2', 2, 1002)
    select * from TestTableType_vu_prepare_func1(1004, @tv)
end;
go
