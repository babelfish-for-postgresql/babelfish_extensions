use babel_4270
go

-- check test list
select * from t
go

-- like expression without escape clause
select * from t where a like 'abc'
go
select * from t where a like 'ab_'
go
select * from t where a like 'abc%'
go
select * from t where a like 'abd'
go
select * from t where a like 'abd_'
go
select * from t where a like 'abc%'
go
select * from t where a like '[a-z]bc%'
go

-- like expression with postgres default escape character '\'
select * from t where a like 'abc\%'
go
select * from t where a like 'abc\_d\_'
go

-- not like expression with postgres default escape character '\'
select * from t where a not like 'abc\%'
go
select * from t where a not like 'abc\_d\_'
go

-- like expression that pattern has default invalid UTF-8 character ‘\xFE’
select * from t where a like 'abc\xFEcd\_'
go
select * from t where a like 'abc\xFE%'
go

-- not like expression that pattern has default invalid UTF-8 character ‘\xFE’
select * from t where a not like 'abc\xFEcd\_'
go
select * from t where a not like 'abc\xFE%'
go

-- like pattern from result of a select clause
select * from t where a like (select 'abc\xFE%')
go
select * from t where a like (select * from t where a like (select 'abc\xFE%'))
go

-- not like pattern from result of a select clause
select * from t where a not like (select 'abc\xFE%')
go
select * from t where a not like (select * from t where a like (select 'abc\xFE%'))
go

-- like pattern from a variable ?
declare @f varchar(20) = 'abc%'
select * from t where a like @f
go

-- like pattern from a function (babelfish bug, tsql have output while bbf doesn't)
select * from t where a like BABEL_4270_abc();
go

-- like pattern from a non-varchar pattern
select * from t where a like 0
go
select * from t where a like 4270
go
select * from t where a like 4272
go
select * from t where a like 0.599
go

-- like expression with escape clause
select * from t where a like 'abcc_%' escape 'c'
go
select * from t where a not like 'abcc_%' escape 'c'
go

-- like, escape clause with special escape clause
select * from t where a like 'abc\_%' escape '\'
go
select * from t where a like 'abc\\xFE_d\_' escape '\xFE'
go
select * from t where a like 'abc_\__%' escape '_'
go

-- not like, escape clause of special escape clause
select * from t where a not like 'abc\_%' escape '\'
go
select * from t where a not like 'abc\\xFE_d\_' escape '\xFE'
go
select * from t where a not like 'abc_\__%' escape '_'
go

-- like, escape character is from result of a select clause
select * from t where a like 'abc\_%' escape (select '\')
go

select * from t where a not like 'abc\\xFE_d\_' escape ( select'\xFE')
go

select * from t where a not like 'abc_\__%' escape (select '_')
go

-- like, escape character is from a variable
declare @f varchar(20) = '\xFE'
select * from t where a like 'abc\\xFE_d\_' escape @f
go

declare @f varchar(20) = '\'
select * from t where a like 'abc\_%' escape @f
go

-- like pattern and escape character both come from a variable
declare @f varchar(20) = '\'
declare @d varchar(20) = 'abc\_%'
select * from t where a like @d escape @f
go

declare @f varchar(20) = '\xFE'
declare @d varchar(20) = 'abc\\xFE_d\_'
select * from t where a like @d escape @f
go

-- not like pattern and escape character both come from a variable
declare @f varchar(20) = '\'
declare @d varchar(20) = 'abc\_%'
select * from t where a not like @d escape @f
go

declare @f varchar(20) = '\xFE'
declare @d varchar(20) = 'abc\\xFE_d\_'
select * from t where a not like @d escape @f
go

-- like, escape character is from a non-varchar value
select * from t where a like 'abc0\0_%' escape 0
go

-- like, escape character is from a non-varchar value
select * from t where a like 'abc0\0_%' escape 0.5
go

-- like expression with default escape '\' in a procedure
exec BABEL_4270_test_default_escape
go