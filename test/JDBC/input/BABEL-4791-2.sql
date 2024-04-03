-- CASE 1: T_Const LIKE T_CollateExpr(T_Const)

select 1 where 'ShameEm' like '%AM%' collate Latin1_General_CS_AI;
GO

select 1 where 'ShameEm' like lower('%AM%') collate Latin1_General_CS_AI;
GO

select 1 where UPPER('ShameEm') like '%AM%' collate Latin1_General_CS_AI;
GO

select 1 where 'ShameEm' like '%Å%' collate Latin1_General_CS_AI;
GO

select 1 where 'ShameEm' like LOWER('%Å%') collate Latin1_General_CS_AI;
GO

select 1 where UPPER('ShameEm') like '%Å%' collate Latin1_General_CS_AI;
GO

select 1 where 'ShameEm' like '%Æ%' collate Latin1_General_CS_AI
GO

select 1 where 'SHaemEEm' like '%Æ%' collate Latin1_General_CS_AI
GO

select 1 where 'SHaemEEm' like LOWER('%Æ%') collate Latin1_General_CS_AI
GO

select 1 where UPPER('SHaemEEm') like '%Æ%' collate Latin1_General_CS_AI
GO

select 1 where 'ShÅmeEm' like '%Ä%' collate Latin1_General_CS_AI;
GO

select 1 where 'ShÅmeEm' like UPPER(LOWER('%Ä%')) collate Latin1_General_CS_AI;
GO

select 1 where 'ShÅmeEm' like LOWER('%Ä%') collate Latin1_General_CS_AI;
GO

-- CASE 2: T_CollateExpr(T_Const) LIKE T_Const
select 1 where 'ShameEm' collate Latin1_General_CS_AI like '%AM%';
GO

select 1 where 'ShameEm' collate Latin1_General_CS_AI like LOWER('%AM%');
GO

select 1 where UPPER('ShameEm') collate Latin1_General_CS_AI like '%AM%';
GO

select 1 where 'ShameEm' collate Latin1_General_CS_AI like '%Å%';
GO

select 1 where 'ShameEm' collate Latin1_General_CS_AI like LOWER('%Å%');
GO

select 1 where UPPER('ShameEm') collate Latin1_General_CS_AI like '%Å%';
GO

select 1 where 'ShameEm' collate Latin1_General_CS_AI like '%Æ%';
GO

select 1 where 'SHaemEEm' collate Latin1_General_CS_AI like '%Æ%';
GO

select 1 where 'SHaemEEm' collate Latin1_General_CS_AI like LOWER('%Æ%');
GO

select 1 where UPPER('SHaemEEm') collate Latin1_General_CS_AI like '%Æ%';
GO

select 1 where 'ShÅmeEm'  collate Latin1_General_CS_AI like '%Ä%';
GO

select 1 where 'ShÅmeEm'  collate Latin1_General_CS_AI like LOWER('%Ä%');
GO

select 1 where UPPER(LOWER('ShÅmeEm'))  collate Latin1_General_CS_AI like '%Ä%';
GO

-- CASE 3: T_CollateExpr(T_Const) LIKE T_CollateExpr(T_Const)
select 1 where 'ShameEm' collate Latin1_General_CS_AI like '%AM%' collate Latin1_General_CS_AI;
GO

select 1 where 'ShameEm' collate Latin1_General_CS_AI like '%Å%' collate Latin1_General_CS_AI;
GO

select 1 where 'ShameEm' collate Latin1_General_CS_AI like '%Æ%' collate Latin1_General_CS_AI;
GO

select 1 where 'SHaemEEm' collate Latin1_General_CS_AI like '%Æ%' collate Latin1_General_CS_AI;
GO

select 1 where 'ShÅmeEm'  collate Latin1_General_CS_AI like '%Ä%' collate Latin1_General_CS_AI;
GO

-- CASE 4: T_ReLabelType (T_Var) LIKE T_Const
create table t4c(a varchar(11) collate Latin1_General_CS_AI)
GO

insert into t4c values ('SHaemEEm'),('ShÅmeEm')
GO

select * from t4c where a like '%Æ%'
GO

select * from t4c where a like '%Ä%'
GO

-- CASE 5: T_Const LIKE T_ReLabelType(T_Var) --> NEED TO THINK OF CASES [SHOULD WORK]
create table t5c(a varchar(11) collate Latin1_General_CS_AI);
GO

insert into t5c values ('SHaemEEm'),('ShÅmeEm');
GO

select * from t5c where '%Æ%' LIKE a; 
GO

select * from t5c where '%Ä%' LIKE a;
GO

-- CASE 6: T_ReLabelType(T_Var) LIKE T_CollateExpr(T_Const)
create table t6c(a varchar(11) collate Latin1_General_CS_AI)
GO

insert into t6c values ('SHaemEEm'),('ShÅmeEm')
GO

select * from t6c where a like '%Æ%' collate Latin1_General_CS_AI
GO

select * from t6c where a like '%Ä%' collate Latin1_General_CS_AI
GO

-- CASE 7: T_CollateExpr(T_Const) LIKE T_ReLabelType(T_Var)
create table t7c(a varchar(11) collate Latin1_General_CS_AI)
GO

insert into t7c values ('SHaemEEm'),('ShÅmeEm')
GO

select * from t7c where '%Æ%' collate Latin1_General_CS_AI like a;
GO

select * from t7c where '%Ä%' collate Latin1_General_CS_AI like a;
GO


-- CASE 8: T_ReLabelType(T_Var) LIKE T_ReLabelType(T_Var)
create table t8c(a varchar(11) collate Latin1_General_CS_AI, b varchar(11) collate Latin1_General_CS_AI)
GO

insert into t8c values ('SHaemEEm', 'ShÅmeEm'),('Ahmed', 'ÃĥɱêÐ'),('Ahmed','ShÅmeEm'),('Shameem','ShÅmeEm')
GO

SELECT * FROM t8c WHERE a LIKE b
GO

-- CASE 9: T_CollateExpr(T_ReLabel(T_Var)) LIKE T_Const
create table t9c(a varchar(11))
GO

insert into t9c values ('SHaemEEm'),('ShÅmeEm')
GO

select * from t9c where a collate Latin1_General_CS_AI like '%Æ%'
GO

select * from t9c where a collate Latin1_General_CS_AI like '%Ä%'
GO

-- CASE 10: T_CollateExpr(T_ReLabel(T_Var)) LIKE T_CollateExpr(T_Const)
create table t10c(a varchar(11))
GO

insert into t10c values ('SHaemEEm'),('ShÅmeEm')
GO

select * from t10c where a collate Latin1_General_CS_AI like '%Æ%' collate Latin1_General_CS_AI
GO

select * from t10c where a collate Latin1_General_CS_AI like '%Ä%' collate Latin1_General_CS_AI
GO

-- CASE 11:
create table t11c(a varchar(11))
GO

insert into t11c values ('SHaemEEm'),('ShÅmeEm')
GO

select * from t11c where '%Æ%' like a collate Latin1_General_CS_AI
GO

select * from t11c where '%Ä%' like a collate Latin1_General_CS_AI
GO

-- CASE 12:
create table t12c(a varchar(11))
GO

insert into t12c values ('SHaemEEm'),('ShÅmeEm')
GO

select * from t12c where '%Æ%' collate Latin1_General_CS_AI like a collate Latin1_General_CS_AI
GO

select * from t12c where '%Ä%' collate Latin1_General_CS_AI like a collate Latin1_General_CS_AI
GO


-- CASE X: T_FuncExpr LIKE T_CollateExpr(T_Const) --> WORKING NOW (Sometimes function like SUBSTRING is identified as T_ReLabelType(T_FuncExpr))
select 1 where UPPER('ShameEm') like '%AM%' collate Latin1_General_CS_AI;
GO

select 1 where LOWER('ShÅmeEm') like '%Ä%' collate Latin1_General_CS_AI;
GO

select 1 where SUBSTRING('ShameEm',2,2) like '%Æ%' collate Latin1_General_CS_AI
GO

select 1 where SUBSTRING('SHaemEEm',2,3) like '%Æ%' collate Latin1_General_CS_AI
GO

-- CASE Y: func(col) LIKE T_const
create table yc(a varchar(11) collate Latin1_General_CS_AI);
GO

insert into yc values ('SHaemEEm'), ('ShÅmeEm'), ('Shameem');
GO

select * from yc where UPPER(a) LIKE '%Ä%';
GO

select * from yc where UPPER(a) LIKE '%Æ%';
GO

select * from yc where SUBSTRING(a, 2, 3) LIKE '%Ä%';
GO

select * from yc where SUBSTRING(a, 2, 3) LIKE '%Æ%';
GO

select * from yc where UPPER(SUBSTRING(a, 2, 3)) LIKE '%Ä%';
GO

select * from yc where SUBSTRING(UPPER(a),2,3) LIKE '%Ä%';
GO

select * from yc where concat("A",substring(a,3,1),"Ā") like '%ā%';
GO

select * from yc where concat("A",substring(a,3,1),"Ā") like '%b%';


 --- FOR QUERY LIKE THIS SQL SERVER DOES NOT RETURN ANYTHING
declare @b varchar='ShÅmeEm'
select * from y where @b LIKE concat("'%",substring(a,3,1),"%'")
GO

-- SUB QUERY
create table t1xc(a nvarchar(51) collate Latin1_General_CS_AI, b nvarchar(51) collate Latin1_General_CS_AI)
go
create table t2xc(c nvarchar(51) collate Latin1_General_CS_AI)
go
insert into t1xc values (N'RaŊdom',N'Shameem'),( N'Ŋecessary',N'BleȘȘing')
go
insert into t2xc values (N'RaŊdom') , (N'Shameem')
go
-- returns 1 row
select a from t1xc where b in (select c from t2xc where c like '%a%')
go
-- returns 1 row
select a from t1xc where b in (select c from t2xc where c like '%s%')
go
insert into t2xc values (N'BleȘȘing')
go
-- returns 0 rows
select a from t1xc where b in (select c from t2xc where c like '%s%')
go

-- CASE
create table t1yc(a nvarchar(51) collate Latin1_General_CS_AI)
insert into t1yc values (N'RaŊdom'),(N'Random'),(N'Ŋecessary'),(N'necessary')
go
-- returns 2 rows of 1
select case when a like '%n%' then 1 else 2 end from t1yc
go

-- COMPLEX CASE WITH SUB QUERY
create table tzc(a nvarchar(51) collate Latin1_General_CS_AI, b nvarchar(51) collate Latin1_General_CS_AI)
insert into tzc values (N'RaŊdom',N'Shameem'),( N'Ŋecessary',N'BleȘȘing')
GO
-- returns 0 rows --> should return 1 rows, but not, why??
SELECT * FROM tzc WHERE a LIKE (CASE WHEN (SELECT 1 WHERE 'Shameem' LIKE 'Ș%' COLLATE Latin1_General_CS_AI) = 1 THEN '%m' ELSE '%y' END);
GO
SELECT * FROM tzc WHERE a LIKE (CASE WHEN (SELECT 1 WHERE 'shameem' LIKE 'Ș%' COLLATE Latin1_General_CS_AI) = 1 THEN '%m' ELSE '%y' END);
GO
SELECT * FROM tzc WHERE a LIKE (CASE WHEN (SELECT 1 WHERE 'ahameem' LIKE 'Ș%' COLLATE Latin1_General_CI_AI) = 1 THEN '%m%' ELSE '%y' END);
GO

-- returns 2 rows
SELECT * FROM tzc WHERE a LIKE (CASE WHEN (SELECT 1 WHERE 'Shameem' LIKE 'Ș%' COLLATE Latin1_General_CS_AI) = 1 THEN '%a%' ELSE '%y' END);
GO

SELECT * FROM tzc WHERE a LIKE (CASE WHEN (SELECT 1 WHERE 'Shameem' LIKE 'Ș%' COLLATE Latin1_General_CS_AI) = 1 THEN '%a' ELSE '%y' END);
GO

-- returns 0 row
SELECT * FROM tzc WHERE a LIKE (CASE WHEN (SELECT 1 WHERE 'shameem' LIKE 'S%') = 1 THEN '%a%' ELSE '%y' END);
GO

SELECT * FROM tzc WHERE a LIKE (CASE WHEN (SELECT 1 WHERE 'Shameem' LIKE 'S%') = 1 THEN '%a%' ELSE '%y' END);
GO

SELECT * FROM tzc WHERE a LIKE (CASE WHEN 1 = 1 THEN '%m' ELSE '%y' END);
GO
SELECT * FROM tzc WHERE a LIKE (CASE WHEN 2 = 1 THEN '%m' ELSE '%y' END);
GO
SELECT * FROM tzc WHERE a LIKE (CASE WHEN 1 = 1 THEN '%m%' ELSE '%y' END);
GO
