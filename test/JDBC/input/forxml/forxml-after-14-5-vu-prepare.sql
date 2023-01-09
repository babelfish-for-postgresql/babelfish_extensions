-- Test BASE64 encoding on binary data
CREATE TABLE forxml_after_14_5_t_binary (Col1 int PRIMARY KEY, Col2 binary);
INSERT INTO forxml_after_14_5_t_binary VALUES (1, 0x7);
GO

create view forxml_after_14_5_v_path as
SELECT Col1, CAST(Col2 as image) as Col2 FROM forxml_after_14_5_t_binary FOR XML PATH;
GO

create view forxml_after_14_5_v_base64 as
SELECT Col1, CAST(Col2 as image) as Col2 FROM forxml_after_14_5_t_binary FOR XML PATH, BINARY BASE64;
GO

create table t1 (id int, a varchar(10));
create table t2 (id int, a varchar(10));
insert into t1 values (1, 't1_a1');
insert into t1 values (2, 't1_a2');
insert into t1 values (3, NULL);
insert into t2 values (1, 't2_a1');
insert into t2 values (2, 't2_a2');
insert into t2 values (3, NULL);
go

-- BABEL-1202: For xml subquery can't access CTE from outer query block - fixed in 2.4.0
create view forxml_vu_v_cte2 as
with cte as (select a from t1)
select * from t2, (select * from cte for xml raw) as t3(colxml);
go

create view forxml_vu_v_cte3 as
with cte as (select a from t1)
select (select * from cte for xml raw) as colxml, * from t2;
go

create view forxml_vu_v_cte4 as
with
cte1 as (select * from t1),
cte2 as (select a from cte1 for xml raw)
select * from cte2;
go

-- BABEL-1876, FOR XML in correlated subquery
create view forxml_vu_v_correlated_subquery as
select a, (select * from t2 where id = t.id for xml raw) as mycol from t1 t
go