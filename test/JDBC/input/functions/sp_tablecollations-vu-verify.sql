exec sp_tablecollations_100 'foo'
GO

select 
    case when t.typname = 'sysname' then 'true' 
        else 'false' end
from
    pg_attribute a left join 
    pg_class c on a.attrelid = c.oid left join 
    pg_type t on a.atttypid = t.oid 
where 
    c.relname = 'spt_tablecollations_view' 
    and a.attname = 'name';
GO