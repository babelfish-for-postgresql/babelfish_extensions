select cast(hashbytes('sha2_512', 'abcdefg') as varbinary(64))
GO

select cast(hashbytes('sha2_512', 'abcdefg') as varbinary(62))
GO