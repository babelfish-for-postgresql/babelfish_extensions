select cast(databasepropertyex('master','collation') as varchar(50))
go
create database mydb
go
use mydb
go
SELECT DB_NAME()
go
SELECT DATABASEPROPERTYEX('mydb', 'Collation')
go
SELECT CONVERT(VARCHAR(100), DATABASEPROPERTYEX(DB_NAME(), 'Collation'))
go
use master
go
drop database mydb
go