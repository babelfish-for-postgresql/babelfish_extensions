DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
select relname from pg_class where relname like '[';
GO
select relname from pg_class where relname like ']';
GO
select relname from pg_class where relname like '[]';
GO
select relname from pg_class where relname like NULL;
GO
select relname from pg_class where relname like '';
GO
select relname from pg_class where relname like 'pg[1:9]class';
GO
select relname from pg_class where relname like 'pg\[1:9\]class';
GO
select relname from pg_class where relname like 'pg\[1:9 ]class';
GO
select relname from pg_class where relname like 'pg [1:9\]class';
GO

select relname from pg_class where relname like 'pg*[1:9*]class' escape '*';
GO
select relname from pg_class where relname like 'pg [1:9*]class' escape '*';
GO
select relname from pg_class where relname like 'pg*[1:9 ]class' escape '*';
GO

DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'postgres';
GO
select relname from pg_class where relname like '[';
GO
select relname from pg_class where relname like ']';
GO
select relname from pg_class where relname like '[]';
GO
select relname from pg_class where relname like NULL;
GO
select relname from pg_class where relname like '';
GO
select relname from pg_class where relname like 'pg[1:9]class';
GO
select relname from pg_class where relname like 'pg\[1:9\]class';
GO
select relname from pg_class where relname like 'pg\[1:9 ]class';
GO
select relname from pg_class where relname like 'pg [1:9\]class';
GO

select relname from pg_class where relname like 'pg*[1:9*]class' escape '*';
GO
select relname from pg_class where relname like 'pg [1:9*]class' escape '*';
GO
select relname from pg_class where relname like 'pg*[1:9 ]class' escape '*';
GO
