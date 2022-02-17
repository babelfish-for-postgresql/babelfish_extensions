-- test databasepropertyex() function
-- invalid db name, should return NULL
select databasepropertyex(N'invalid_dbname',N'Edition');
GO
-- invalid property name, should return NULL
select databasepropertyex(N'master',N'invalid_property');
GO
-- test return type
select pg_typeof(databasepropertyex(N'master',N'invalid_property'));
GO
-- test supported properties
select databasepropertyex(N'master',N'Collation');
GO
select databasepropertyex(N'master',N'IsInStandBy');
GO
select databasepropertyex(N'master',N'IsAutoClose');
GO
select databasepropertyex(N'master',N'IsAutoCreateStatistics');
GO
select 'true' where databasepropertyex(N'master',N'IsTornPageDetectionEnabled') >= 0
GO
select databasepropertyex(N'master',N'Updateability');
GO
select databasepropertyex(N'master',N'Status');
GO
SELECT (case when charindex(cast(databasepropertyex(N'master',N'Version') as nvarchar), version()) > 0 then 'true' else 'false' end) result
GO
-- test unsupported properties(expect return NULL or 0)
select databasepropertyex(N'master',N'IsArithmeticAbortEnabled');
GO
select databasepropertyex(N'master',N'IsAutoShrink');
GO
select databasepropertyex(N'master',N'MaxSizeInBytes');
GO
