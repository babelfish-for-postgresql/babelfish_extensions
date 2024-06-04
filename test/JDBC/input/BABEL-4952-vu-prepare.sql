create table t1_default_collation(id int identity(1,1), name nvarchar(25) primary key)
GO

create table t2_ci_ai_collation(id int identity(1,1), name nvarchar(25) collate sql_latin1_general_cp1_ci_ai primary key)
GO

insert into t1_default_collation values ('Joȧo'),('JoṠe')
GO

insert into t2_ci_ai_collation values ('Joao'), ('Jose')
GO

SELECT a.*
INTO new_table
FROM t1_default_collation a
INNER JOIN t2_ci_ai_collation b ON a.name = b.name;
GO
