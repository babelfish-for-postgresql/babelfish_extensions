create table forxml_t1 (id int, a varchar(10));
create table forxml_t2 (id int, a varchar(10));
insert into forxml_t1 values (1, 't1_a1');
insert into forxml_t1 values (2, 't1_a2');
insert into forxml_t1 values (3, NULL);
insert into forxml_t2 values (1, 't2_a1');
insert into forxml_t2 values (2, 't2_a2');
insert into forxml_t2 values (3, NULL);
go

-- Test Select For XML syntax
select * from forxml_t1 for xml auto;
go

select * from forxml_t1 for xml raw;
go

select * from forxml_t1 for xml raw('myrow');
go

select * from forxml_t1 for xml path;
go

select * from forxml_t1 for xml path('myrow');
go

select * from forxml_t1 for xml explicit;
go

select * from forxml_t1, forxml_t2 where forxml_t1.id = forxml_t2.id for xml path('myrow');
go

select * from forxml_t1, forxml_t2 where forxml_t1.id = forxml_t2.id for xml path('myrow'), type;
go

select * from forxml_t1, forxml_t2 where forxml_t1.id = forxml_t2.id for xml path('myrow'), type, root('myroot');
go

select * from forxml_t1, forxml_t2 where forxml_t1.id = forxml_t2.id for xml path('myrow'), type, root('myroot'), BINARY BASE64;
go

-- Test result format when all values are NULL
select a from forxml_t1 where a is NULL for xml raw;
go

select a from forxml_t1 where a is NULL for xml path;
go

-- Test result format when one value is NULL
select id, a from forxml_t1 where a is NULL for xml raw;
go

select id, a from forxml_t1 where a is NULL for xml path;
go

-- Test for xml with order by clause
select * from forxml_t1 order by id for xml raw ('t1');
go

-- Test for xml with group by
select count(*) as cnt, a from forxml_t1 group by a,id order by id;
go
select count(*) as cnt, a from forxml_t1 group by a,id order by id for xml path;
go

-- Test for xml in subquery, The subquery is supposed to return only one XML value
select id, (select a from forxml_t2 for xml path) as col from forxml_t1;
go

-- Test 2 levels of for xml nesting, with TYPE option
select id, (select a from forxml_t2 for xml path, type) as col from forxml_t1 for xml path, type;
go

-- Test 2 levels of for xml nesting, without TYPE option, expect special character escaping
select id, (select a from forxml_t2 for xml path) as col from forxml_t1 for xml path;
go

-- Test 3 levels of for xml nesting with TYPE option
select id, (select id, (select a from forxml_t2 for xml path, type) as col1 from forxml_t1 for xml path, type) as col2 from forxml_t1 for xml path, type;
go

-- Test simple for xml path in procedure
create table forxml_vu_t_employees(
pers_id int,
fname nvarchar(20),
lname nvarchar(20),
sal money);
insert into forxml_vu_t_employees values (1, 'John', 'Johnson', 123.1234);
insert into forxml_vu_t_employees values (2, 'Max', 'Welch', 200.1234);
go

create procedure p_employee_select as
begin
	select * from forxml_vu_t_employees for xml path;
end;
go

-- Test for xml in procedure with parameters
create procedure p_employee_select2 @minsal MONEY, @maxsal MONEY as
begin
	select * from forxml_vu_t_employees where sal > @minsal and sal < @maxsal
	for xml path('Employee');
end;
go

-- Test for xml in create view
create view forxml_vu_v1 (col1) as select * from forxml_t1 for xml raw, type;
go

-- Test for xml on pure relational view
create view forxml_vu_v2 (col1, col2) as select * from forxml_t1;
go

-- Test for xml and union all
select a from forxml_t1 UNION ALL select a from forxml_t2 for xml raw ('myrow');
go

-- Test invalid syntax when FOR XML is on both sides of UNION ALL, this is SQL Server behavior
select a from forxml_t1 for xml raw ('t1') UNION ALL select a from forxml_t2 for xml raw ('t2');
go

-- For xml can access CTE from same query block
create view forxml_vu_v_cte1 as
with cte as (select a from forxml_t1)
select * from cte for xml raw;
go

-- Test for xml and recursive CTE
CREATE TABLE forxml_vu_t_employees2 (
  id serial,
  name varchar(255),
  manager_id int
);

INSERT INTO forxml_vu_t_employees2 VALUES (1, 'Mark', null);
INSERT INTO forxml_vu_t_employees2 VALUES (2, 'John', 1);
INSERT INTO forxml_vu_t_employees2 VALUES (3, 'Dan', 2);
INSERT INTO forxml_vu_t_employees2 VALUES (4, 'Clark', 1);
INSERT INTO forxml_vu_t_employees2 VALUES (5, 'Linda', 2);
INSERT INTO forxml_vu_t_employees2 VALUES (6, 'Willy', 2);
INSERT INTO forxml_vu_t_employees2 VALUES (7, 'Barack', 2);
INSERT INTO forxml_vu_t_employees2 VALUES (8, 'Elen', 2);
INSERT INTO forxml_vu_t_employees2 VALUES (9, 'Kate', 3);
INSERT INTO forxml_vu_t_employees2 VALUES (10, 'Terry', 4);
GO

CREATE VIEW forxml_vu_v_with AS
WITH managertree AS (
  SELECT id, name, manager_id
  FROM forxml_vu_t_employees2
  WHERE id = 2
  UNION ALL
  SELECT e.id, e.name, e.manager_id
  FROM forxml_vu_t_employees2 e
  INNER JOIN managertree mtree ON mtree.id = e.manager_id
)
SELECT *
FROM managertree mt;
GO

CREATE VIEW forxml_vu_v_with_where AS
WITH managertree AS (
  SELECT id, name, manager_id
  FROM forxml_vu_t_employees2
  WHERE id = 2
  UNION ALL
  SELECT e.id, e.name, e.manager_id
  FROM forxml_vu_t_employees2 e
  INNER JOIN managertree mtree ON mtree.id = e.manager_id
)
SELECT *
FROM managertree mt WHERE mt.name = 'Linda' FOR XML RAW ('managertree');
GO

-- BABEL-1178, data type of variable is lost during variable binding in FORMAT
-- function
create procedure test_forxml_datalength @pid int as
declare @a int, @b smallint;
set @a = 1;
set @b = 1;
select a, datalength(@a), datalength(@b) from forxml_t1 where id = @pid for xml raw;
go

-- test string variable can be binded with for xml query
create procedure test_forxml_strvar @pid int, @str varchar(10) as
select * from forxml_t1 where id = @pid and a = @str for xml raw;
go