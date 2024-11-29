select * from pg_collation where collname like 'chinese%';
GO
create table testing5(c1 varchar(20) COLLATE SQL_Latin1_General_CP1_CS_AS);
GO
TRUNCATE TABLE testing5
GO
insert into testing5 values ('JONES');
insert into testing5 values ('JoneS');
insert into testing5 values ('abcD');
insert into testing5 values ('äbĆD');
GO
SELECT * FROM testing5 where c1 COLLATE Chinese_PRC_CI_AS like 'jo%' ;
GO
select * from pg_collation where collname like 'bbf_%';
GO
