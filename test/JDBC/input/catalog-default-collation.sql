CREATE TABLE col_test1 (a varchar(128) COLLATE CATALOG_DEFAULT);
insert into col_test1 values 
('Hello'), 
('Holla');
GO

CREATE TABLE col_test2 (a nvarchar(128) COLLATE CATALOG_DEFAULT);
insert into col_test2 values 
('Bonjour'),
('Guten Tag');
GO

select a from col_test1;
GO

select a from col_test2;
GO

drop table col_test1;
GO

drop table col_test2;
GO
