create table test1 (c1 VARCHAR(32))
GO

insert test1 values ('This is a test.')
GO

insert test1 values ('This is test 2.')
GO

insert test1 values (' ')
GO

insert test1 values ('')
GO

select hashbytes('md2', c1) from test1
GO

select hashbytes('md4', c1) from test1
GO

select hashbytes('md5', c1) from test1
GO

select hashbytes('sha', c1) from test1
GO

select hashbytes('sha1', c1) from test1
GO

select hashbytes('sha2_256', c1) from test1
GO

select hashbytes('sha2_512', c1) from test1
GO

select hashbytes('fake', c1) from test1
GO



create table test2 (c1 VARBINARY(32))
GO

insert test2 values ('1234567890')
GO

insert test2 values (1234567890)
GO

insert test2 values (0)
GO

insert test2 values (1)
GO

select hashbytes('md2', c1) from test2
GO

select hashbytes('md4', c1) from test2
GO

select hashbytes('md5', c1) from test2
GO

select hashbytes('sha', c1) from test2
GO

select hashbytes('sha1', c1) from test2
GO

select hashbytes('sha2_256', c1) from test2
GO

select hashbytes('sha2_512', c1) from test2
GO

select hashbytes('fake', c1) from test2
GO


drop table test1
GO

drop table test2
GO

