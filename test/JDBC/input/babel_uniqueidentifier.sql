DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO

create table t1 (a uniqueidentifier, b uniqueidentifier, c uniqueidentifier, primary key(a));
GO

insert into t1(a) values ('6F9619FF-8B86-D011-B42D-00C04FC964FF');
GO

insert into t1(a) values ('6F9619FF-8B86-D011-B42D-00C04FC964FF');  -- trigger error
GO

select * from t1;
GO

insert into t1 values ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', newid(), newid());
GO

select * from t1 where a = '6F9619FF-8B86-D011-B42D-00C04FC964FF'; -- test PK
GO

select count(*) from t1 where a = '6F9619FF-8B86-D011-B42D-00C04FC964FF';
GO
select count(*) from t1 where a > '6F9619FF-8B86-D011-B42D-00C04FC964FF';
GO
select count(*) from t1 where a >= '6F9619FF-8B86-D011-B42D-00C04FC964FF';
GO
select count(*) from t1 where a < 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
GO
select count(*) from t1 where a <= 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
GO
select count(*) from t1 where a <> 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
GO

-- newid's value could not be verified
insert into t1 values (newid(), newid(), newid());
insert into t1 values (newid(), newid(), newid());
insert into t1 values (newid(), newid(), newid());
select count(a) from t1;
GO

create table t2 (a uniqueidentifier, b uniqueidentifier, c uniqueidentifier, primary key(a));
insert into t2 select * from t1 order by a;
select count(distinct a) from t2;
GO

-- test index (need more data)
create table t3 ( a uniqueidentifier, b uniqueidentifier);
GO
-- create inital distinct values
insert into t3 values (newid(), newid());
insert into t3 values (newid(), newid());
insert into t3 values (newid(), newid());
insert into t3 values (newid(), newid());
GO

create index t3_a on t3 (a);
GO

create index t3_b on t3 (b);
GO

-- test truncate feature of uniqueidentifier_in
create table t4 ( a uniqueidentifier);
GO

insert into t4 values ('6F9619FF-8B86-D011-B42D-00C04FC964FF');
GO

insert into t4 values ('6F9619FF-8B86-D011-B42D-00C04FC964FFwrong'); -- characters exceeding are truncated
GO

insert into t4 values ('{6F9619FF-8B86-D011-B42D-00C04FC964FF}'); -- with braces
GO

insert into t4 values ('{6F9619FF-8B86-D011-B42D-00C04FC964FFwrong'); -- error due to no matching brace
GO

insert into t4 values ('6F9619FF-8B86-D011-B42D-00C04FC964FF}'); -- single brace at the end are truncated
GO

select * from t4;
GO

select set_config('enable_seqscan','off','false');
GO

select set_config('enable_bitmapscan','off','false');
GO

select set_config('search_path','sys, public','true');
GO

select name, setting from pg_settings where name in ('enable_seqscan', 'enable_bitmapscan');
GO
select * from t3 where a = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; -- test btree index
GO
select * from t3 where b = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; -- test hash index
GO

-- assignment cast, should have same behavior as normal insert
DECLARE @babelfishpg_tsql_sql_dialect varchar(50) = 'tsql';
GO
create table t5 ( a uniqueidentifier);
insert into t5 values (cast('6F9619FF-8B86-D011-B42D-00C04FC964FF' as varchar(50)));
GO
insert into t5 values (cast('6F9619FF-8B86-D011-B42D-00C04FC964FFwrong' as varchar(50))); -- characters exceeding are truncated
GO
insert into t5 values (cast('{6F9619FF-8B86-D011-B42D-00C04FC964FF}' as varchar(50))); -- with braces
GO
insert into t5 values (cast('{6F9619FF-8B86-D011-B42D-00C04FC964FFwrong' as varchar(50))); -- error due to no matching brace
GO
insert into t5 values (cast('6F9619FF-8B86-D011-B42D-00C04FC964FF}' as varchar(50))); -- single brace at the end are truncated
GO
insert into t5 values (cast('6F9619FF-8B86-D011-B42D-00C04FC964FF' as nvarchar(50)));
GO
insert into t5 values (cast('6F9619FF-8B86-D011-B42D-00C04FC964FFwrong' as nvarchar(50))); -- characters exceeding are truncated
GO
insert into t5 values (cast('{6F9619FF-8B86-D011-B42D-00C04FC964FF}' as nvarchar(50))); -- with braces
GO
insert into t5 values (cast('{6F9619FF-8B86-D011-B42D-00C04FC964FFwrong' as nvarchar(50))); -- error due to no matching brace
GO
insert into t5 values (cast('6F9619FF-8B86-D011-B42D-00C04FC964FF}' as nvarchar(50))); -- single brace at the end are truncated
GO

-- error cases, implicit cast not supported
select * from t5 where a = cast('6F9619FF-8B86-D011-B42D-00C04FC964FF' as varchar(50));
GO
select * from t5 where a = cast('6F9619FF-8B86-D011-B42D-00C04FC964FF' as nvarchar(50));
GO

select set_config('enable_seqscan','on','false');
GO

select set_config('enable_bitmapscan','on','false');
GO

drop table t1;
GO
drop table t2;
GO
drop table t3;
GO
drop table t4;
GO
drop table t5;
GO
