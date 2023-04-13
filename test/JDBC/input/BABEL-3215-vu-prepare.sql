create table dbo.unionorder1 (c1 int );
create table dbo.unionorder2 (c2 int );
create table dbo.unionorder1b (c1 int );
go

insert into unionorder1 VALUES (1), (2), (3);
insert into unionorder2 VALUES (2), (3), (4);
insert into unionorder1b VALUES (2), (3), (4);
go

create procedure babel_3215_unionorder_proc as
BEGIN
    SELECT * FROM unionorder1 u1, unionorder1b u2 WHERE u1.c1 = u2.c1
    union
    SELECT u.c1, u.c1 FROM unionorder1 u
    ORDER BY u1.c1
END
go
