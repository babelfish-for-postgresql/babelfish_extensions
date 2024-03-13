-- CASE 1: T_Const LIKE T_CollateExpr(T_Const)

select 1 where 'ShameEm' like '%AM%' collate Latin1_General_CI_AI;
GO

select 1 where 'ShameEm' like '%Å%' collate Latin1_General_CI_AI;
GO

select 1 where 'ShameEm' like '%Æ%' collate Latin1_General_CI_AI
GO

select 1 where 'SHaemEEm' like '%Æ%' collate Latin1_General_CI_AI
GO

select 1 where 'ShÅmeEm' like '%Ä%' collate Latin1_General_CI_AI;
GO

-- CASE 2: T_CollateExpr(T_Const) LIKE T_Const
select 1 where 'ShameEm' collate Latin1_General_CI_AI like '%AM%';
GO

select 1 where 'ShameEm' collate Latin1_General_CI_AI like '%Å%';
GO

select 1 where 'ShameEm' collate Latin1_General_CI_AI like '%Æ%';
GO

select 1 where 'SHaemEEm' collate Latin1_General_CI_AI like '%Æ%';
GO

select 1 where 'ShÅmeEm'  collate Latin1_General_CI_AI like '%Ä%';
GO

-- CASE 3: T_CollateExpr(T_Const) LIKE T_CollateExpr(T_Const)
select 1 where 'ShameEm' collate Latin1_General_CI_AI like '%AM%' collate Latin1_General_CI_AI;
GO

select 1 where 'ShameEm' collate Latin1_General_CI_AI like '%Å%' collate Latin1_General_CI_AI;
GO

select 1 where 'ShameEm' collate Latin1_General_CI_AI like '%Æ%' collate Latin1_General_CI_AI;
GO

select 1 where 'SHaemEEm' collate Latin1_General_CI_AI like '%Æ%' collate Latin1_General_CI_AI;
GO

select 1 where 'ShÅmeEm'  collate Latin1_General_CI_AI like '%Ä%' collate Latin1_General_CI_AI;
GO

-- CASE 4: T_ReLabelType (T_Var) LIKE T_Const
create table t4(a varchar(11) collate Latin1_General_CI_AI)
GO

insert into t4 values ('SHaemEEm'),('ShÅmeEm')
GO

select * from t4 where a like '%Æ%'
GO

select * from t4 where a like '%Ä%'
GO

-- CASE 5: T_Const LIKE T_ReLabelType(T_Var) --> NEED TO THINK OF CASES [SHOULD WORK]
create table t5(a varchar(11) collate Latin1_General_CI_AI);
GO

insert into t5 values ('SHaemEEm'),('ShÅmeEm');
GO

select * from t5 where '%Æ%' LIKE a; 
GO

select * from t5 where '%Ä%' LIKE a;
GO

-- CASE 6: T_ReLabelType(T_Var) LIKE T_CollateExpr(T_Const)
create table t6(a varchar(11) collate Latin1_General_CI_AI)
GO

insert into t6 values ('SHaemEEm'),('ShÅmeEm')
GO

select * from t6 where a like '%Æ%' collate Latin1_General_CI_AI
GO

select * from t6 where a like '%Ä%' collate Latin1_General_CI_AI
GO

-- CASE 7: T_CollateExpr(T_Const) LIKE T_ReLabelType(T_Var)
create table t7(a varchar(11) collate Latin1_General_CI_AI)
GO

insert into t7 values ('SHaemEEm'),('ShÅmeEm')
GO

select * from t7 where '%Æ%' collate Latin1_General_CI_AI like a;
GO

select * from t7 where '%Ä%' collate Latin1_General_CI_AI like a;
GO


-- CASE 8: T_ReLabelType(T_Var) LIKE T_ReLabelType(T_Var)
create table t8(a varchar(11) collate Latin1_General_CI_AI, b varchar(11) collate Latin1_General_CI_AI)
GO

insert into t8 values ('SHaemEEm', 'ShÅmeEm'),('Ahmed', 'ÃĥɱêÐ'),('Ahmed','ShÅmeEm'),('Shameem','ShÅmeEm')
GO

SELECT * FROM t8 WHERE a LIKE b
GO

-- CASE 9: T_CollateExpr(T_ReLabel(T_Var)) LIKE T_Const
create table t9(a varchar(11))
GO

insert into t9 values ('SHaemEEm'),('ShÅmeEm')
GO

select * from t9 where a collate Latin1_General_CI_AI like '%Æ%'
GO

select * from t9 where a collate Latin1_General_CI_AI like '%Ä%'
GO

-- CASE 10: T_CollateExpr(T_ReLabel(T_Var)) LIKE T_CollateExpr(T_Const)
create table t10(a varchar(11))
GO

insert into t10 values ('SHaemEEm'),('ShÅmeEm')
GO

select * from t10 where a collate Latin1_General_CI_AI like '%Æ%' collate Latin1_General_CI_AI
GO

select * from t10 where a collate Latin1_General_CI_AI like '%Ä%' collate Latin1_General_CI_AI
GO

-- CASE 11:
create table t11(a varchar(11))
GO

insert into t11 values ('SHaemEEm'),('ShÅmeEm')
GO

select * from t11 where '%Æ%' like a collate Latin1_General_CI_AI
GO

select * from t11 where '%Ä%' like a collate Latin1_General_CI_AI
GO

-- CASE 12:
create table t12(a varchar(11))
GO

insert into t12 values ('SHaemEEm'),('ShÅmeEm')
GO

select * from t12 where '%Æ%' collate Latin1_General_CI_AI like a collate Latin1_General_CI_AI
GO

select * from t12 where '%Ä%' collate Latin1_General_CI_AI like a collate Latin1_General_CI_AI
GO


-- CASE X: T_FuncExpr LIKE T_CollateExpr(T_Const) --> WORKING NOW (Sometimes function like SUBSTRING is identified as T_ReLabelType(T_FuncExpr))
select 1 where UPPER('ShameEm') like '%AM%' collate Latin1_General_CI_AI;
GO

select 1 where LOWER('ShÅmeEm') like '%Ä%' collate Latin1_General_CI_AI;
GO

select 1 where SUBSTRING('ShameEm',2,2) like '%Æ%' collate Latin1_General_CI_AI
GO

select 1 where SUBSTRING('SHaemEEm',2,3) like '%Æ%' collate Latin1_General_CI_AI
GO

-- CASE Y: func(col) LIKE T_const
create table y(a varchar(11) collate Latin1_General_CI_AI);
GO

insert into y values ('SHaemEEm'), ('ShÅmeEm'), ('Shameem');
GO

select * from y where UPPER(a) LIKE '%Ä%';
GO

select * from y where UPPER(a) LIKE '%Æ%';
GO

select * from y where SUBSTRING(a, 2, 3) LIKE '%Ä%';
GO

select * from y where SUBSTRING(a, 2, 3) LIKE '%Æ%';
GO

select * from y where UPPER(SUBSTRING(a, 2, 3)) LIKE '%Ä%';
GO

select * from y where SUBSTRING(UPPER(a),2,3) LIKE '%Ä%';
GO

select * from y where concat("A",substring(a,3,1),"Ā") like '%ā%';
GO

select * from y where concat("A",substring(a,3,1),"Ā") like '%b%';


 --- FOR QUERY LIKE THIS NO OUTPUT IS OBTAINED
declare @b varchar='ShÅmeEm'
select * from y where @b LIKE concat("'%",substring(a,3,1),"%'")
GO
