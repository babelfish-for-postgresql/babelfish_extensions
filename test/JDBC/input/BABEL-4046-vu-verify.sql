
select options_t.name
  from options_t
 inner join svc_defs
    on options_t.name like 'UM\_%' + svc_defs.svc_name escape '\'
go

select * from babel4046;
GO

select * from babel4046_2;
GO

;with EMP_T AS (
                select empno,
				ename,
				CASE			            
			            WHEN baseloc LIKE 'AUS%' THEN REPLACE(baseloc,'AUSTIN','A')
					    WHEN baseloc LIKE 'CHI%' THEN REPLACE(baseloc,'CHICAGO','C')
						WHEN baseloc LIKE 'BOS%' THEN REPLACE(baseloc,'BOSTON','B')
                ELSE
		                baseloc
                END AS baseloc,
				deptno
				from t3)
				select
				DM.empno,
				DM.ename,
				DM.baseloc
				from EMP_T DM
				INNER JOIN t4 SR ON DM.baseloc = SR.loc AND DM.deptno = SR.deptno order by DM.empno;
GO

;with EMP_T AS ( select empno, ename, CASE WHEN baseloc LIKE 'AUS%' THEN REPLACE(baseloc,'AUSTIN','A') ELSE baseloc END AS baseloc, deptno from t3)
	select DM.empno, DM.ename, DM.baseloc from EMP_T DM where DM.baseloc in (select baseloc from t4)  order by DM.empno
GO

;with EMP_T AS ( select empno, ename, CASE WHEN baseloc LIKE 'AUS%' THEN REPLACE(baseloc,'AUSTIN','A') ELSE baseloc END AS baseloc, deptno from t3)
	select DM.empno, DM.ename, DM.baseloc from EMP_T DM where DM.baseloc = 'A'  order by DM.empno
GO
