drop table if exists unicode_test;
go
create table unicode_test(col nvarchar(255), 中文列名 nvarchar(255));
go
insert into unicode_test values('Hello', '你好');
go
insert into unicode_test values('World', '世界');
go

/* multibyte characters as identifier */
select col 别名 from unicode_test;
go
select 别名=col from unicode_test;
go

/* multibyte characters with unsupported token */
select "你好世界" from unicode_test with(nolock);
go
select 中文列名 from unicode_test with(nolock);
go
