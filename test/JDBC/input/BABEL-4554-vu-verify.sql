-- We should have no dangling entries here (taken from BABEL-4554 DA)

select *
from pg_class where relname in
(
   select relname
    from pg_class c
    where not exists
    (
         SELECT * from pg_class d
         WHERE c.oid = d.reltoastrelid
    )
    AND relname in
    (
      select s.relname from pg_stat_all_tables s where s.relname LIKE 'pg_toast_%'
    )
    AND pg_table_size(c.oid) = 0
    AND c.relkind = 't'
    AND c.relpersistence = 't'
)
GO