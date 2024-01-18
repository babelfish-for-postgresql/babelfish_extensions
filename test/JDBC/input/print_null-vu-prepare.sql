create procedure p1_print_null as
declare @v varchar = null
print null
print @v
print ''
set @v = ''
print @v
print ' '
print '  '
go