-- table variable
DECLARE @tv_nocomma TABLE(a INT NOT NULL, b INT PRIMARY KEY(a))
insert @tv_nocomma values (1,2)
insert @tv_nocomma values (1,3)
go
DECLARE @tv_nocomma TABLE(a INT NOT NULL, b INT NOT NULL PRIMARY KEY(a,b))
insert @tv_nocomma values (1,2)
insert @tv_nocomma values (1,2)
go
DECLARE @tv_nocomma TABLE(a INT NOT NULL, b INT UNIQUE(a))
insert @tv_nocomma values (1,2)
insert @tv_nocomma values (1,3)
go
DECLARE @tv_nocomma TABLE(a INT NOT NULL, b INT NOT NULL UNIQUE(a,b))
insert @tv_nocomma values (1,2)
insert @tv_nocomma values (1,2)
go

-- already worked correctly before the fix:
DECLARE @tv_nocomma TABLE(a INT NOT NULL, b INT NOT NULL PRIMARY KEY)
insert @tv_nocomma values (1,2)
insert @tv_nocomma values (2,2)
go
DECLARE @tv_nocomma TABLE(a INT NOT NULL PRIMARY KEY, b INT NOT NULL)
insert @tv_nocomma values (1,2)
insert @tv_nocomma values (1,3)
go
DECLARE @tv_nocomma TABLE(a INT NOT NULL, b INT NOT NULL UNIQUE)
insert @tv_nocomma values (1,2)
insert @tv_nocomma values (2,2)
go
DECLARE @tv_nocomma TABLE(a INT NOT NULL UNIQUE, b INT NOT NULL)
insert @tv_nocomma values (1,2)
insert @tv_nocomma values (1,3)
go
DECLARE @tv_nocomma TABLE(a INT NOT NULL, b INT NOT NULL CHECK(a>0))
insert @tv_nocomma values (1,2)
insert @tv_nocomma values (0,3)
go

-- TVF return table
SELECT * FROM f1_tvf_nocomma(0)
go
SELECT * FROM f1_tvf_nocomma(1)
go
SELECT * FROM f2_tvf_nocomma(0)
go
SELECT * FROM f2_tvf_nocomma(1)
go
SELECT * FROM f3_tvf_nocomma(0)
go
SELECT * FROM f3_tvf_nocomma(1)
go
SELECT * FROM f4_tvf_nocomma(0)
go
SELECT * FROM f4_tvf_nocomma(1)
go
SELECT * FROM f5_tvf_nocomma(0)
go
SELECT * FROM f5_tvf_nocomma(1)
go
SELECT * FROM f6_tvf_nocomma(0)
go
SELECT * FROM f6_tvf_nocomma(1)
go
SELECT * FROM f7_tvf_nocomma(0)
go
SELECT * FROM f7_tvf_nocomma(1)
go
SELECT * FROM f8_tvf_nocomma(0)
go
SELECT * FROM f8_tvf_nocomma(1)
go
SELECT * FROM f9_tvf_nocomma(0)
go
SELECT * FROM f9_tvf_nocomma(1)
go

-- stored procedures
EXECUTE p1_tv_nocomma
go
EXECUTE p2_tv_nocomma
go
EXECUTE p3_tv_nocomma
go
EXECUTE p4_tv_nocomma
go
EXECUTE p5_tv_nocomma
go
EXECUTE p6_tv_nocomma
go
EXECUTE p7_tv_nocomma
go
EXECUTE p8_tv_nocomma
go
EXECUTE p9_tv_nocomma
go

-- regular tables and #tmp tables already worked correctly before the fix:
create table t1_tvf_nocomma (a INT NOT NULL, b INT NOT NULL PRIMARY KEY(a))
insert t1_tvf_nocomma values (1,2)
insert t1_tvf_nocomma values (1,3)
go

create table t2_tvf_nocomma (a INT NOT NULL, b INT NOT NULL PRIMARY KEY)
insert t2_tvf_nocomma values (1,2)
insert t2_tvf_nocomma values (1,3)
go

create table t3_tvf_nocomma (a INT NOT NULL PRIMARY KEY, b INT NOT NULL)
insert t3_tvf_nocomma values (1,2)
insert t3_tvf_nocomma values (1,3)
go

create table t4_tvf_nocomma (a INT NOT NULL, b INT NOT NULL UNIQUE(a))
insert t4_tvf_nocomma values (1,2)
insert t4_tvf_nocomma values (1,3)
go

create table t5_tvf_nocomma (a INT NOT NULL, b INT NOT NULL UNIQUE)
insert t5_tvf_nocomma values (1,2)
insert t5_tvf_nocomma values (1,3)
go

create table t6_tvf_nocomma (a INT NOT NULL UNIQUE, b INT NOT NULL)
insert t6_tvf_nocomma values (1,2)
insert t6_tvf_nocomma values (1,3)
go

create table #t7_tvf_nocomma (a INT NOT NULL, b INT NOT NULL UNIQUE(a))
insert #t7_tvf_nocomma values (1,2)
insert #t7_tvf_nocomma values (1,3)
go
