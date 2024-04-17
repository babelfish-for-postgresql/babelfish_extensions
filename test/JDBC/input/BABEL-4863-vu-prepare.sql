create table babel_4863_t1 (a int)
GO
INSERT INTO babel_4863_t1 VALUES(1)
GO

create function babel_4863_func()
	returns table as return 
	(
		select 'value' = '1'
	)
go
