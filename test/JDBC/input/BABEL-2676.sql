create function mstvf_conditional(@i int) returns @tableVar table
(
a text not null
)
begin
	insert into @tableVar values('hello1')
	if @i > 0
		return
	insert into @tableVar values('hello2')
	return
end
go

-- should return both rows
select * from mstvf_conditional(0)
go

-- should only return the first row
select * from mstvf_conditional(1)
go

drop function mstvf_conditional
go
