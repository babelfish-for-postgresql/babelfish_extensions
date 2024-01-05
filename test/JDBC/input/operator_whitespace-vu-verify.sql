-- Combines BABEL-3379 (whitespace in 2-char comparison operators (!=,  <>, <=, etc.)) and BABEL-4114 (comparison operators !< and !>)
alter table t1_operator_whitespace add check(a!  <1)
go

alter table t1_operator_whitespace add check(a<
=3)
go

insert t1_operator_whitespace values (0)
go
insert t1_operator_whitespace values (4)
go
insert t1_operator_whitespace values (1)
insert t1_operator_whitespace values (2)
insert t1_operator_whitespace values (3)
go

select a from t1_operator_whitespace
go

select a as q1 from t1_operator_whitespace where a != 2
go

select a as q1 from t1_operator_whitespace where a ! = 2
go

select a as q2 from t1_operator_whitespace where a ! 	 =2
go

select a as q3 from t1_operator_whitespace where a !  	

		
 
= 2
go

select a as q4 from t1_operator_whitespace where a <   >2
go

select a as q5 from t1_operator_whitespace where a <   	= 2
go

select a as q6 from t1_operator_whitespace where a >   	=2
go

select a as q7 from t1_operator_whitespace where a!<2
go

select a as q8 from t1_operator_whitespace where a !< 2
go

select a as q9 from t1_operator_whitespace where a ! 	  < 2
go

select a as q10 from t1_operator_whitespace where a! 	  <2
go

select a as q11 from t1_operator_whitespace where a !> 2
go

select a as q12 from t1_operator_whitespace where a!>2
go

select a as q13 from t1_operator_whitespace where a ! 	  > 2
go

select a as q14 from t1_operator_whitespace where a! 	  >2
go

select a as q15 from t1_operator_whitespace where a = case when a!  >2 then a else 0 end
go

EXECUTE('select a as q16 from t1_operator_whitespace where a ! = 2')
go

EXECUTE('select a as q17 from t1_operator_whitespace where a ! < 2')
go

EXECUTE p1_operator_whitespace
go
