-- Test BASE64 encoding on binary data
CREATE TABLE forxml_subquery_vu_t_binary (Col1 int PRIMARY KEY, Col2 binary);
INSERT INTO forxml_subquery_vu_t_binary VALUES (1, 0x7);
GO

create view forxml_subquery_vu_v_path as
SELECT Col1, CAST(Col2 as image) as Col2 FROM forxml_subquery_vu_t_binary FOR XML PATH;
GO

create view forxml_subquery_vu_v_base64 as
SELECT Col1, CAST(Col2 as image) as Col2 FROM forxml_subquery_vu_t_binary FOR XML PATH, BINARY BASE64;
GO

create table forxml_subquery_vu_t_t1 (id int, a varchar(10));
create table forxml_subquery_vu_t_t2 (id int, a varchar(10));
insert into forxml_subquery_vu_t_t1 values (1, 't1_a1');
insert into forxml_subquery_vu_t_t1 values (2, 't1_a2');
insert into forxml_subquery_vu_t_t1 values (3, NULL);
insert into forxml_subquery_vu_t_t2 values (1, 't2_a1');
insert into forxml_subquery_vu_t_t2 values (2, 't2_a2');
insert into forxml_subquery_vu_t_t2 values (3, NULL);
go

-- BABEL-1202: For xml subquery can't access CTE from outer query block - fixed in 2.4.0
create view forxml_subquery_vu_v_cte2 as
with cte as (select a from forxml_subquery_vu_t_t1)
select * from forxml_subquery_vu_t_t2, (select * from cte for xml raw) as t3(colxml);
go

create view forxml_subquery_vu_v_cte3 as
with cte as (select a from forxml_subquery_vu_t_t1)
select (select * from cte for xml raw) as colxml, * from forxml_subquery_vu_t_t2;
go

create view forxml_subquery_vu_v_cte4 as
with
cte1 as (select * from forxml_subquery_vu_t_t1),
cte2 as (select a from cte1 for xml raw)
select * from cte2;
go

-- BABEL-1876, FOR XML in correlated subquery
create view forxml_subquery_vu_v_correlated_subquery as
select a, (select * from forxml_subquery_vu_t_t2 where id = t.id for xml raw) as mycol from forxml_subquery_vu_t_t1 t
go

-- BABEL-3569/BABEL-3690 return 0 rows for empty rowset
CREATE PROCEDURE forxml_subquery_vu_p_empty AS
SELECT * FROM forxml_subquery_vu_t_t1
	WHERE 1 = 0
	FOR XML RAW
GO