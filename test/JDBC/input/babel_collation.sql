create table testing_collation (col varchar(20));
go
insert into testing_collation values ('JONES');
insert into testing_collation values ('jones');
insert into testing_collation values ('Jones');
insert into testing_collation values ('JoNes');
insert into testing_collation values ('JoNés');
go
select * from testing_collation where col collate SQL_Latin1_General_CP1_CS_AS = 'JoNes';
go

select * from testing_collation where col collate SQL_Latin1_General_CP1_CI_AS = 'JoNes';
go

select * from testing_collation where col collate SQL_Latin1_General_CP1_CI_AI = 'JoNes';
go

-- all the currently supported TSQL collations
SELECT * from fn_helpcollations();
go

-- BABEL-1697 Collation and Codepage information for DMS
SELECT CAST( COLLATIONPROPERTY(Name, 'CodePage') AS INT) FROM fn_helpcollations() where Name = DATABASEPROPERTYEX('template1', 'Collation');
go

SELECT CAST( COLLATIONPROPERTY(Name, 'lcid') AS INT) FROM fn_helpcollations() where Name = DATABASEPROPERTYEX('template1', 'Collation');
go

-- clean up
drop table testing_collation;
go
