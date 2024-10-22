create view babel_4475_v1 as select cast(cast('a' as binary(2)) as varchar(2))
go

create function babel_4475_f1() returns table 
as return (
    select cast(cast('a' as binary(2)) as varchar(2))
)
go

create procedure babel_4475_p1 as select cast(cast('a' as binary(2)) as varchar(2))
go

create view babel_4475_v2 as select cast(cast('a' as binary(2)) as pg_catalog.varchar(2))
go

create function babel_4475_f2() returns table 
as return (
    select cast(cast('a' as binary(2)) as pg_catalog.varchar(2))
)
go

create procedure babel_4475_p2 as select cast(cast('a' as binary(2)) as pg_catalog.varchar(2))
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'ignore';
go

create view babel_4475_v3 as select cast(cast('ab' as rowversion) as varchar(2))
go

create procedure babel_4475_p3 as select cast(cast('ab' as rowversion) as varchar(2))
go

create view babel_4475_v4 as select cast(cast('ab' as rowversion) as pg_catalog.varchar(2))
go

create procedure babel_4475_p4 as select cast(cast('ab' as rowversion) as pg_catalog.varchar(2))
go

EXEC sp_babelfish_configure 'babelfishpg_tsql.escape_hatch_rowversion', 'strict';
go
