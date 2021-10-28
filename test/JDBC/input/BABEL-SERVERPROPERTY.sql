-- test serverproperty() function
-- invalid property name, should reutnr NULL
select serverproperty('invalid property');
go
-- valid supported properties
select serverproperty('collation');
go
select 'true' where serverproperty('collationId') >= 0;
go
select serverproperty('IsSingleUser');
go
select serverproperty('ServerName');
go

-- BABEL-1286
SELECT SERVERPROPERTY('babelfish');
go
