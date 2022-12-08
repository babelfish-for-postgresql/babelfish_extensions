USE master
go

select cast(SERVERPROPERTY('ProductVersion') as varchar) as ProductVersion;
select cast(SERVERPROPERTY('ProductMajorVersion') as varchar) as ProductMajorVersion;
-- only print till the server version i.e. first newline character
select substring(@@version, 1, CHARINDEX(CHAR(10), @@version) - 1);
select @@microsoftversion;
-- check there is Bablefish version info
select count(*) from (select @@version) a where version like '% (Babelfish %.%.%)';
go