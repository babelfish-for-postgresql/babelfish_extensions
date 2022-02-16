set babelfishpg_tsql.sql_dialect = 'tsql';
select relname from pg_class where relname like '[';
select relname from pg_class where relname like ']';
select relname from pg_class where relname like '[]';
select relname from pg_class where relname like NULL;
select relname from pg_class where relname like '';
select relname from pg_class where relname like 'pg[1:9]class';
select relname from pg_class where relname like 'pg\[1:9\]class';
select relname from pg_class where relname like 'pg\[1:9 ]class';
select relname from pg_class where relname like 'pg [1:9\]class';

select relname from pg_class where relname like 'pg*[1:9*]class' escape '*';
select relname from pg_class where relname like 'pg [1:9*]class' escape '*';
select relname from pg_class where relname like 'pg*[1:9 ]class' escape '*';

set babelfishpg_tsql.sql_dialect = 'postgres';
select relname from pg_class where relname like '[';
select relname from pg_class where relname like ']';
select relname from pg_class where relname like '[]';
select relname from pg_class where relname like NULL;
select relname from pg_class where relname like '';
select relname from pg_class where relname like 'pg[1:9]class';
select relname from pg_class where relname like 'pg\[1:9\]class';
select relname from pg_class where relname like 'pg\[1:9 ]class';
select relname from pg_class where relname like 'pg [1:9\]class';

select relname from pg_class where relname like 'pg*[1:9*]class' escape '*';
select relname from pg_class where relname like 'pg [1:9*]class' escape '*';
select relname from pg_class where relname like 'pg*[1:9 ]class' escape '*';
