create table babel_3300 (a varchar(5) collate database_default, b char(5) collate database_default);
GO

insert into babel_3300 values ('abcd', 'abcd');
GO

insert into babel_3300 values ('abcdef', 'abcdef');
GO

select * from babel_3300;
GO

drop table babel_3300;
GO

SELECT CAST( N'Name' AS NVARCHAR(10) ) collate catalog_default as name;
GO