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

SELECT c1 FROM dbo.unionorder1
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

SELECT u1.c1, u2.c2 FROM unionorder1 u1, unionorder2 u2 where u1.c1 = u2.c2
UNION
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

SELECT u1.c1 FROM unionorder1 u1
UNION 
SELECT c2 FROM unionorder2
WHERE c2 IN (
    SELECT TOP 5 c2 FROM unionorder2
    UNION
    SELECT TOP 5 c1 FROM unionorder1
    WHERE c1 IN (
        SELECT TOP 5 c1 FROM unionorder1
        UNION
        SELECT TOP 5 c2 FROM unionorder2
        ORDER BY unionorder1.c1
    )
    ORDER BY unionorder2.c2
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
ORDER BY col2;
go

SELECT c1 FROM unionorder1
WHERE c1 IN (
    SELECT TOP 5 c2 FROM unionorder2
    UNION
    SELECT TOP 5 c1 FROM unionorder1
    ORDER BY unionorder2.c2
)
UNION 
SELECT c2 FROM unionorder2
ORDER BY unionorder1.c1;
go

SELECT c1 FROM unionorder1
WHERE c1 IN (
    SELECT TOP 5 c2 FROM unionorder2
    UNION
    SELECT TOP 5 c1 FROM unionorder1
    ORDER BY unionorder2.c2
)
UNION 
SELECT c2 FROM unionorder2
ORDER BY unionorder2.c2;
go

SELECT c2 FROM (
    SELECT TOP 5 c2 FROM unionorder2
    UNION
    SELECT TOP 5 c1 FROM unionorder1
    ORDER BY unionorder2.c2
) u
UNION 
SELECT c1 FROM unionorder1
ORDER BY u.c2;
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

select sum(a) as sum, b from dbo.babel4169_t1 group by b, c
union
select sum(a), b from dbo.babel4169_t2 group by b, c
order by sum
go

drop table dbo.babel4169_t1;
drop table dbo.babel4169_t2;
go