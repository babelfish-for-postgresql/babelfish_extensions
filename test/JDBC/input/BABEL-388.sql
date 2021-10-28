-- note: this test only can run on babel since it relies on pg_typeof

create view babel_388_v1 as select null a;
GO
select cast(pg_typeof(a) as varchar(10)) as typname from babel_388_v1;
GO

create view babel_388_v2 as select null a union select null;
GO
select cast(pg_typeof(a) as varchar(10)) as typname from babel_388_v2;
GO

create view babel_388_v3 as select null a union select null union select 1;
GO
select cast(pg_typeof(a) as varchar(10)) as typname from babel_388_v3;
GO

create view babel_388_v4 as select 1 a;
GO
select cast(pg_typeof(a) as varchar(10)) as typname from babel_388_v4;
GO

create view babel_388_v5 as select 'string' a;
GO
select cast(pg_typeof(a) as varchar(10)) as typname from babel_388_v5;
GO

create view babel_388_v6 as select 1 a UNION select NULL;
GO
select cast(pg_typeof(a) as varchar(10)) as typname from babel_388_v6;
GO

create view babel_388_v7 as select NULL a UNION select 1;
GO
select cast(pg_typeof(a) as varchar(10)) as typname from babel_388_v7;
GO

create view babel_388_v8 as select 'string' a UNION select NULL;
GO
select cast(pg_typeof(a) as varchar(10)) as typname from babel_388_v8;
GO

create view babel_388_v9 as select NULL a UNION select 'string';
GO
select cast(pg_typeof(a) as varchar(10)) as typname from babel_388_v9;
GO

DROP view babel_388_v1;
GO
DROP view babel_388_v2;
GO
DROP view babel_388_v3;
GO
DROP view babel_388_v4;
GO
DROP view babel_388_v5;
GO
DROP view babel_388_v6;
GO
DROP view babel_388_v7;
GO
DROP view babel_388_v8;
GO
DROP view babel_388_v9;
GO
