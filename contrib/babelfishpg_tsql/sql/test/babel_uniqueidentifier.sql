SET babelfishpg_tsql.sql_dialect = 'tsql';

create table t1 (a uniqueidentifier, b uniqueidentifier, c uniqueidentifier, primary key(a));
insert into t1(a) values ('6F9619FF-8B86-D011-B42D-00C04FC964FF');
insert into t1(a) values ('6F9619FF-8B86-D011-B42D-00C04FC964FF');  -- trigger error
select * from t1;

insert into t1 values ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', newid(), newid());

explain (costs off) select * from t1 where a = '6F9619FF-8B86-D011-B42D-00C04FC964FF'; -- test PK

select count(*) from t1 where a = '6F9619FF-8B86-D011-B42D-00C04FC964FF';
select count(*) from t1 where a > '6F9619FF-8B86-D011-B42D-00C04FC964FF';
select count(*) from t1 where a >= '6F9619FF-8B86-D011-B42D-00C04FC964FF';
select count(*) from t1 where a < 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
select count(*) from t1 where a <= 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
select count(*) from t1 where a <> 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

-- newid's value could not be verified
insert into t1 values (newid(), newid(), newid());
insert into t1 values (newid(), newid(), newid());
insert into t1 values (newid(), newid(), newid());
select count(a) from t1;

create table t2 (like t1);
insert into t2 select * from t1 order by a;
select count(distinct a) from t2;

-- test index (need more data)
create table t3 ( a uniqueidentifier, b uniqueidentifier);
-- create inital distinct values
insert into t3 values (newid(), newid());
insert into t3 values (newid(), newid());
insert into t3 values (newid(), newid());
insert into t3 values (newid(), newid());

create index t3_a on t3 using btree (a);
create index t3_b on t3 using hash (b);

-- test truncate feature of uniqueidentifier_in
create table t4 ( a uniqueidentifier);
insert into t4 values ('6F9619FF-8B86-D011-B42D-00C04FC964FF');
insert into t4 values ('6F9619FF-8B86-D011-B42D-00C04FC964FFwrong'); -- characters exceeding are truncated
insert into t4 values ('{6F9619FF-8B86-D011-B42D-00C04FC964FF}'); -- with braces
insert into t4 values ('{6F9619FF-8B86-D011-B42D-00C04FC964FFwrong'); -- error due to no matching brace
insert into t4 values ('6F9619FF-8B86-D011-B42D-00C04FC964FF}'); -- single brace at the end are truncated
select * from t4;

reset babelfishpg_tsql.sql_dialect;
SET ENABLE_SEQSCAN = OFF;
SET ENABLE_BITMAPSCAN = OFF;
SET SEARCH_PATH = sys, public;
select name, setting from pg_settings where name in ('enable_seqscan', 'enable_bitmapscan');
explain (costs off) select * from t3 where a = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; -- test btree index
explain (costs off) select * from t3 where b = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; -- test hash index

-- assignment cast, should have same behavior as normal insert
set babelfishpg_tsql.sql_dialect = "tsql";
create table t5 ( a uniqueidentifier);
insert into t5 values (cast('6F9619FF-8B86-D011-B42D-00C04FC964FF' as varchar(50)));
insert into t5 values (cast('6F9619FF-8B86-D011-B42D-00C04FC964FFwrong' as varchar(50))); -- characters exceeding are truncated
insert into t5 values (cast('{6F9619FF-8B86-D011-B42D-00C04FC964FF}' as varchar(50))); -- with braces
insert into t5 values (cast('{6F9619FF-8B86-D011-B42D-00C04FC964FFwrong' as varchar(50))); -- error due to no matching brace
insert into t5 values (cast('6F9619FF-8B86-D011-B42D-00C04FC964FF}' as varchar(50))); -- single brace at the end are truncated

insert into t5 values (cast('6F9619FF-8B86-D011-B42D-00C04FC964FF' as nvarchar(50)));
insert into t5 values (cast('6F9619FF-8B86-D011-B42D-00C04FC964FFwrong' as nvarchar(50))); -- characters exceeding are truncated
insert into t5 values (cast('{6F9619FF-8B86-D011-B42D-00C04FC964FF}' as nvarchar(50))); -- with braces
insert into t5 values (cast('{6F9619FF-8B86-D011-B42D-00C04FC964FFwrong' as nvarchar(50))); -- error due to no matching brace
insert into t5 values (cast('6F9619FF-8B86-D011-B42D-00C04FC964FF}' as nvarchar(50))); -- single brace at the end are truncated

-- error cases, implicit cast not supported
select * from t5 where a = cast('6F9619FF-8B86-D011-B42D-00C04FC964FF' as varchar(50));
select * from t5 where a = cast('6F9619FF-8B86-D011-B42D-00C04FC964FF' as nvarchar(50));

reset babelfishpg_tsql.sql_dialect;

drop table t1;
drop table t2;
drop table t3;
drop table t4;
drop table t5;
