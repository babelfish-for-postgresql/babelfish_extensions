create view babel_try_parse_v as select TRY_PARSE('abc' as varchar(10))
GO

create function babel_try_parse_f()
returns varchar(10)
as
begin 
	declare @a varchar(10) = TRY_PARSE('abc' as varchar(10));
	return @a
end
GO