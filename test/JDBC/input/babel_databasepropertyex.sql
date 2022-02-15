-- test databasepropertyex() function
-- invalid db name, should return NULL
select databasepropertyex(N'invalid_dbname',N'Edition');
GO
-- invalid property name, should return NULL
select databasepropertyex(N'template1',N'invalid_property');
GO
-- test return type
select pg_typeof(databasepropertyex(N'template1',N'invalid_property'));
GO
-- test supported properties
select databasepropertyex(N'template1',N'Collation');
GO
select databasepropertyex(N'template1',N'IsInStandBy');
GO
select databasepropertyex(N'template1',N'IsAutoClose');
GO
select databasepropertyex(N'template1',N'IsAutoCreateStatistics');
GO
select 'true' where databasepropertyex(N'template1',N'IsTornPageDetectionEnabled') >= 0
GO
select databasepropertyex(N'template1',N'Updateability');
GO
select databasepropertyex(N'template1',N'Status');
GO
SELECT (case when charindex(cast(databasepropertyex(N'template1',N'Version') as nvarchar), version()) > 0 then 'true' else 'false' end) result
GO
-- test unsupported properties(expect return NULL or 0)
select databasepropertyex(N'template1',N'IsArithmeticAbortEnabled');
GO
select databasepropertyex(N'template1',N'IsAutoShrink');
GO
select databasepropertyex(N'template1',N'MaxSizeInBytes');
GO
