-- Since the JDBC tests do not capture output from PRINT statements, these tests actually don't do anything
-- Keeping them for when then moment comes that PRINT tests are supported

-- prints a single space:
print null
go

-- prints a single space:
declare @v varchar = null
print @v
go
-- prints a single space:
print ''
go

-- prints a single space:
declare @v varchar = ''
print @v
go

-- prints a single space:
print ' '
go

-- prints two spaces:
print '  '
go

-- same set of tests as above, but inside a stored proc:
exec p1_print_null
go
