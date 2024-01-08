create table t1_operator_whitespace(a int)
go

create view v1_operator_whitespace as
select c1=1, c2=a from t1_operator_whitespace  where a = case when a!  >2 then a else 0 end 
go

create procedure p1_operator_whitespace 
as
select a as p1 from t1_operator_whitespace where a ! = 2
select a as p2 from t1_operator_whitespace where a ! 	 =2
select a as q3 from t1_operator_whitespace where a !  	

		
 
= 2
select a as p4 from t1_operator_whitespace where a <   >2
select a as p5 from t1_operator_whitespace where a <   	= 2
select a as p6 from t1_operator_whitespace where a >   	=2
select a as p7 from t1_operator_whitespace where a!<2
select a as p8 from t1_operator_whitespace where a !< 2
select a as p9 from t1_operator_whitespace where a ! 	  < 2
select a as p10 from t1_operator_whitespace where a! 	  <2
select a as p11 from t1_operator_whitespace where a !> 2
select a as p12 from t1_operator_whitespace where a!>2
select a as p13 from t1_operator_whitespace where a ! 	  > 2
select a as p14 from t1_operator_whitespace where a! 	  >2
select a as q15 from t1_operator_whitespace where a = case when a!  >2 then a else 0 end
EXECUTE('select a as p16 from t1_operator_whitespace where a ! = 2')
EXECUTE('select a as p17 from t1_operator_whitespace where a ! < 2')
go
