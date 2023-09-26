EXEC babel_3215_unionorder_proc
go

SELECT u.c1 FROM unionorder1 u
UNION
SELECT u.c1 FROM unionorder1 u
ORDER BY u.c1;
go

SELECT c1 FROM unionorder1
UNION
SELECT c2 FROM unionorder2
ORDER BY unionorder1.c1;
go

SELECT c1 FROM unionorder1
intersect
SELECT c2 FROM unionorder2
ORDER BY unionorder1.c1;
go

SELECT u.c1 FROM unionorder1 u
intersect
SELECT c2 FROM unionorder2
ORDER BY u.c1;
go

SELECT c1 FROM unionorder1
except
SELECT c2 FROM unionorder2
ORDER BY unionorder1.c1;
go

SELECT c1 FROM unionorder1 u
except
SELECT c2 FROM unionorder2
ORDER BY u.c1;
go

SELECT u.c1 FROM unionorder1 u
UNION
SELECT c2 FROM unionorder2
ORDER BY c1;
go

SELECT u.c1 FROM unionorder1 u
UNION ALL
SELECT u.c1 FROM unionorder1 u
ORDER BY u.c1;
go

SELECT c1 FROM dbo.unionorder1
UNION
SELECT c2 FROM dbo.unionorder2
ORDER BY dbo.unionorder1.c1;
go

SELECT c1 FROM unionorder1 u
UNION
SELECT c2 FROM unionorder2
ORDER BY unionorder1.c1;
go

SELECT u.c1 FROM dbo.unionorder1 u
UNION
SELECT c2 FROM dbo.unionorder2
ORDER BY dbo.unionorder1.c1;
go

SELECT c1 FROM master.dbo.unionorder1
UNION
SELECT c1 FROM master.dbo.unionorder1
ORDER BY master.dbo.unionorder1.c1;
go

SELECT c1 FROM dbo.unionorder1
UNION
SELECT c2 FROM dbo.unionorder2
ORDER BY dbo.unionorder2.c2;
go

SELECT u.* FROM unionorder1 u
UNION
SELECT u.*  FROM unionorder1 u
ORDER BY u.c1
go

SELECT u.* FROM unionorder1 u
UNION
SELECT u.*  FROM unionorder1 u
ORDER BY unionorder1.c1
go

SELECT u.* FROM unionorder1 u
ORDER BY u.a
UNION
SELECT u.* FROM unionorder u
ORDER BY u.b
go

SELECT u1.c1, u2.c2 FROM unionorder1 u1, unionorder2 u2 where u1.c1 = u2.c2
UNION
SELECT u1.c1, u2.c2 FROM unionorder1 u1, unionorder2 u2 where u1.c1 = u2.c2
ORDER BY u2.c2
go

SELECT u1.c1, u2.c2 FROM unionorder1 u1, unionorder2 u2 where u1.c1 = u2.c2
UNION ALL
SELECT u1.c1, u2.c2 FROM unionorder1 u1, unionorder2 u2 where u1.c1 = u2.c2
ORDER BY u2.c2
go

select u.c2 from unionorder1 JOIN unionorder2 u on u.c2 = unionorder1.c1
union
select u.c1 from unionorder1 u
ORDER BY u.c2
go

SELECT unionorder1.c1 FROM unionorder1, unionorder1b WHERE unionorder1.c1 = unionorder1b.c1
union
SELECT u.c1 FROM unionorder1 u
ORDER BY unionorder1.c1
go

SELECT * FROM unionorder1, unionorder1b WHERE unionorder1.c1 = unionorder1b.c1
union
SELECT u.c1, u.c1 FROM unionorder1 u
ORDER BY unionorder1.c1
go

SELECT * FROM unionorder1 u1, unionorder1b u2 WHERE u1.c1 = u2.c1
union
SELECT u.c1, u.c1 FROM unionorder1 u
ORDER BY u1.c1
go

SELECT c1 FROM unionorder1
ORDER BY c1
UNION
SELECT c2 FROM unionorder2
ORDER BY c2
go

SELECT u1.c1 FROM unionorder1 u1
UNION 
SELECT c2 FROM unionorder2
WHERE c2 IN (
    SELECT c2 FROM unionorder2
    UNION
    SELECT c1 FROM unionorder1
    WHERE c1 IN (
        SELECT c1 FROM unionorder1
        UNION
        SELECT c2 FROM unionorder2
    )
)
ORDER BY u1.c1;
go

SELECT u1.c1, (SELECT TOP 1 c2 FROM unionorder2) AS col2
FROM unionorder1 u1
UNION 
SELECT c2, c2 FROM unionorder2
WHERE c2 IN (
    SELECT TOP 5 c2 FROM unionorder2
    UNION
    SELECT TOP 5 c1 FROM unionorder1
    ORDER BY unionorder2.c2
)
ORDER BY col2, u1.c1;
go

SELECT c1 FROM unionorder1
WHERE c1 IN (
    SELECT c2 FROM unionorder2
    UNION
    SELECT c1 FROM unionorder1
)
UNION 
SELECT c2 FROM unionorder2
ORDER BY unionorder1.c1;
go

SELECT c1 FROM unionorder1
WHERE c1 IN (
    SELECT c2 FROM unionorder2
    UNION
    SELECT c1 FROM unionorder1
)
UNION 
SELECT c2 FROM unionorder2
ORDER BY unionorder2.c2;
go

SELECT c2 FROM (
    SELECT c2 FROM unionorder2
    UNION
    SELECT c1 FROM unionorder1
) u
UNION 
SELECT c1 FROM unionorder1
ORDER BY u.c2;
go

create view v1 as
    select u1b.c1
    from unionorder1 u1
    inner join unionorder2 u2
    on u1.c1 = u2.c2
    inner join unionorder1b u1b
    on u1.c1 = u1b.c1
union 
    select u1b.c1
    from unionorder1 u1
    inner join unionorder2 u2
    on u1.c1 = u2.c2
    inner join unionorder1b u1b
    on u1.c1 = u1b.c1
go

select * from v1;
go

drop view v1;
go

-- Test babel_613 UNION ALL with numeric issue
create table dbo.unionorder_numeric (a numeric(6,4), b numeric(6,3));
insert into unionorder_numeric values (4, 16);
insert into unionorder_numeric values (NULL, 101.123);
go

create table dbo.unionorder_char (a CHAR(5), b CHAR(10));
insert into unionorder_char values ('aaa', 'bbbbbbbb');
insert into unionorder_char values (NULL, '5');
go

SELECT t.a, t.b FROM unionorder_numeric t
UNION ALL
SELECT t.a, t.b FROM unionorder_numeric t
ORDER BY t.b;
go

SELECT t.a, t.b FROM unionorder_char t
UNION ALL
SELECT t.a, t.b FROM unionorder_char t
ORDER BY t.b;
go

drop procedure babel_3215_unionorder_proc;
drop table dbo.unionorder_numeric;
drop table dbo.unionorder_char;
drop table dbo.unionorder1;
drop table dbo.unionorder2;
drop table dbo.unionorder1b;
go

-- BABEL-4169 resjunk issue with sort key outside tl
create table dbo.babel4169_t1 (a int, b int, c int); 
create table dbo.babel4169_t2 (a int, b int, c int); 
go

insert into dbo.babel4169_t1 values (1, 2, 3), (10, 2, 3), (100, 2, 99);
insert into dbo.babel4169_t2 values (4, 5, 6), (40, 5, 6), (400, 5, 99);
go

select sum(a), b from dbo.babel4169_t1 group by b, c
union
select sum(a), b from dbo.babel4169_t2 group by b, c
order by b
go

select sum(a) as sum, b from dbo.babel4169_t1 group by b, c
union
select sum(a), b from dbo.babel4169_t2 group by b, c
order by sum
go

select sum(a), b from dbo.babel4169_t1 group by b, c
union
select sum(a), b from dbo.babel4169_t2 group by b, c
order by c
go

CREATE FUNCTION babel4169_error_on_func_create ()
RETURNS TABLE
AS
RETURN
    select sum(a), b from dbo.babel4169_t1 group by b, c
    union
    select sum(a), b from dbo.babel4169_t2 group by b, c
    order by c
go

drop table dbo.babel4169_t1;
drop table dbo.babel4169_t2;
go

-- BABEL-4210
create table babel4210_t1(id INT, val VARCHAR(20));
create table babel4210_t2(t1_id INT, val VARCHAR(20));
create table babel4210_t3(t1_id INT, val VARCHAR(20));
go

insert into babel4210_t1 values (1, 'a'), (2, 'b'), (3, 'c');
insert into babel4210_t2 values (1, 'A'), (2, 'B'), (3, 'C');
insert into babel4210_t3 values (1, 'x'), (2, 'Y'), (3, 'z');
go

select babel4210_t1.id,  babel4210_t2.val, babel4210_t3.val from babel4210_t1
inner join babel4210_t2 on babel4210_t1.id = babel4210_t2.t1_id
inner join babel4210_t3 on babel4210_t1.id = babel4210_t3.t1_id
UNION
select babel4210_t1.id, babel4210_t2.val, babel4210_t3.val from babel4210_t1
inner join babel4210_t2 on babel4210_t1.id = babel4210_t2.t1_id
inner join babel4210_t3 on babel4210_t1.id = babel4210_t3.t1_id
ORDER BY babel4210_t3.val;
go

select babel4210_t1.id,  babel4210_t2.val, upper(babel4210_t3.val) from babel4210_t1
inner join babel4210_t2 on babel4210_t1.id = babel4210_t2.t1_id
inner join babel4210_t3 on babel4210_t1.id = babel4210_t3.t1_id
UNION
select babel4210_t1.id, babel4210_t3.val, upper(babel4210_t2.val) from babel4210_t1
inner join babel4210_t2 on babel4210_t1.id = babel4210_t2.t1_id
inner join babel4210_t3 on babel4210_t1.id = babel4210_t3.t1_id
ORDER BY upper(babel4210_t3.val);
go

select babel4210_t1.id,  babel4210_t2.val, upper(babel4210_t3.val) from babel4210_t1
inner join babel4210_t2 on babel4210_t1.id = babel4210_t2.t1_id
inner join babel4210_t3 on babel4210_t1.id = babel4210_t3.t1_id
UNION
select babel4210_t1.id, babel4210_t3.val, upper(babel4210_t2.val) from babel4210_t1
inner join babel4210_t2 on babel4210_t1.id = babel4210_t2.t1_id
inner join babel4210_t3 on babel4210_t1.id = babel4210_t3.t1_id
ORDER BY babel4210_t3.val;
go

select babel4210_t1.id,  babel4210_t2.val, babel4210_t3.t1_id from babel4210_t1
inner join babel4210_t2 on babel4210_t1.id = babel4210_t2.t1_id
inner join babel4210_t3 on babel4210_t1.id = babel4210_t3.t1_id
UNION
select babel4210_t1.id, babel4210_t2.val, babel4210_t3.t1_id from babel4210_t1
inner join babel4210_t2 on babel4210_t1.id = babel4210_t2.t1_id
inner join babel4210_t3 on babel4210_t1.id = babel4210_t3.t1_id
ORDER BY babel4210_t3.val;
go

select babel4210_t3.val from babel4210_t3
UNION
select babel4210_t1.val from babel4210_t1
ORDER BY (CASE WHEN babel4210_t3.val = 'b' THEN 1 ELSE 2 END)
go

select DISTINCT babel4210_t1.id, babel4210_t2.val, babel4210_t3.val from babel4210_t1
inner join babel4210_t2 on babel4210_t1.id = babel4210_t2.t1_id
inner join babel4210_t3 on babel4210_t1.id = babel4210_t3.t1_id
UNION
select babel4210_t1.id, babel4210_t2.val, babel4210_t3.val from babel4210_t1
inner join babel4210_t2 on babel4210_t1.id = babel4210_t2.t1_id
inner join babel4210_t3 on babel4210_t1.id = babel4210_t3.t1_id
ORDER BY babel4210_t2.val;
go

select COUNT(DISTINCT babel4210_t3.val), babel4210_t2.val from babel4210_t1
inner join babel4210_t2 on babel4210_t1.id = babel4210_t2.t1_id
inner join babel4210_t3 on babel4210_t1.id = babel4210_t3.t1_id
GROUP BY babel4210_t2.val, babel4210_t3.val
UNION ALL
select COUNT(DISTINCT babel4210_t3.val), babel4210_t2.val from babel4210_t1
inner join babel4210_t2 on babel4210_t1.id = babel4210_t2.t1_id
inner join babel4210_t3 on babel4210_t1.id = babel4210_t3.t1_id
GROUP BY babel4210_t2.val, babel4210_t3.val
ORDER BY babel4210_t3.val;
go

select COUNT(DISTINCT babel4210_t3.val), babel4210_t2.val from babel4210_t1
inner join babel4210_t2 on babel4210_t1.id = babel4210_t2.t1_id
inner join babel4210_t3 on babel4210_t1.id = babel4210_t3.t1_id
GROUP BY babel4210_t2.val
UNION
select COUNT(DISTINCT babel4210_t3.val), babel4210_t2.val from babel4210_t1
inner join babel4210_t2 on babel4210_t1.id = babel4210_t2.t1_id
inner join babel4210_t3 on babel4210_t1.id = babel4210_t3.t1_id
GROUP BY babel4210_t2.val
ORDER BY COUNT(DISTINCT babel4210_t3.val), babel4210_t2.val;
go

select val from babel4210_t1
UNION
select t1_id from babel4210_t2
ORDER BY babel4210_t1.id
go

WITH babel4210_cte (id, val) AS
(
    select babel4210_t1.id, babel4210_t3.val FROM babel4210_t1
    INNER JOIN babel4210_t3 ON babel4210_t1.id = babel4210_t3.t1_id
    UNION
    select babel4210_t1.id, babel4210_t1.val from babel4210_t1
    INNER JOIN babel4210_t3 ON babel4210_t1.id = babel4210_t3.t1_id
)
SELECT babel4210_cte.* FROM babel4210_cte
UNION ALL
SELECT babel4210_cte.* FROM babel4210_cte
ORDER BY babel4210_cte.val, babel4210_cte.id;
GO

WITH babel4210_cte (id, val) AS
(
    select babel4210_t1.id, babel4210_t3.val FROM babel4210_t1
    INNER JOIN babel4210_t3 ON babel4210_t1.id = babel4210_t3.t1_id
    UNION
    select babel4210_t1.id, babel4210_t1.val from babel4210_t1
    INNER JOIN babel4210_t3 ON babel4210_t1.id = babel4210_t3.t1_id
)
SELECT babel4210_cte.* FROM babel4210_cte
INTERSECT
SELECT babel4210_cte.* FROM babel4210_cte
ORDER BY babel4210_cte.val, babel4210_cte.id;
GO

select top 2 babel4210_t1.id from babel4210_t1
union
select top 1 babel4210_t2.t1_id from babel4210_t2
ORDER BY babel4210_t2.t1_id DESC
GO

drop table babel4210_t1;
drop table babel4210_t2;
drop table babel4210_t3;
go