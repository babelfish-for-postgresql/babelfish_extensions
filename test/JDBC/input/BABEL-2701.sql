create table babel_2701(a int)
GO

select object_name(object_id) from sys.objects where name = 'babel_2701';
GO

drop table babel_2701
GO