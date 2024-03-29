SELECT set_config('timezone', 'Australia/Sydney', false)
GO

select current_setting('TIMEZONE');
GO
insert gh_1412_t1 values (3, '2000-06-01 00:00:00', default, 'custom time zone after update');
GO
select * from gh_1412_t1 order by id;
GO
select * from gh_1412_v1;
GO
-- time zone in plus op with months (input months or years, fixed in gh#1418)
select cast('2000-06-01 00:00:00 +00' as datetimeoffset) + make_interval(1, 0);
GO
select cast('2000-06-01 00:00:00 +00' as datetimeoffset) + make_interval(0, 1);
GO
-- time zone in plus op with days (input days or weeks, fixed in gh#1418)
select cast('2000-06-01 00:00:00 +00' as datetimeoffset) + make_interval(0, 0, 1, 0);
GO
select cast('2000-06-01 00:00:00 +00' as datetimeoffset) + make_interval(0, 0, 0, 1);
GO
-- time zone in plus op with time (just in case)
select cast('2000-06-01 00:00:00 +00' as datetimeoffset) + make_interval(0, 0, 0, 0, 1, 1);
GO
-- time zone in type conversion (date conversion fixed in gh#1418)
select cast(cast('2000-06-01 23:01:00 +00' as datetimeoffset) as time);
GO
select cast(cast('2000-06-01 23:01:00 +00' as datetimeoffset) as date);
GO
select cast(cast('2000-06-01 23:01:00 +00' as datetimeoffset) as smalldatetime);
GO
select cast(cast('2000-06-01 23:01:00 +00' as datetimeoffset) as datetime);
GO
select cast(cast('2000-06-01 23:01:00 +00' as datetimeoffset) as datetime2);
GO

SELECT set_config('timezone', 'UTC', false)
GO

insert gh_1412_t1 values (4, '2000-06-01 00:00:00', default, 'default time zone after update');
GO
select * from gh_1412_t1 order by id;
GO
select * from gh_1412_v1;
GO
-- time zone in plus op with months (input months or years, fixed in gh#1418)
select cast('2000-06-01 00:00:00 +00' as datetimeoffset) + make_interval(1, 0);
GO
select cast('2000-06-01 00:00:00 +00' as datetimeoffset) + make_interval(0, 1);
GO
-- time zone in plus op with days (input days or weeks, fixed in gh#1418)
select cast('2000-06-01 00:00:00 +00' as datetimeoffset) + make_interval(0, 0, 1, 0);
GO
select cast('2000-06-01 00:00:00 +00' as datetimeoffset) + make_interval(0, 0, 0, 1);
GO
-- time zone in plus op with time (just in case)
select cast('2000-06-01 00:00:00 +00' as datetimeoffset) + make_interval(0, 0, 0, 0, 1, 1);
GO
-- time zone in type conversion (date conversion fixed in gh#1418)
select cast(cast('2000-06-01 23:01:00 +00' as datetimeoffset) as time);
GO
select cast(cast('2000-06-01 23:01:00 +00' as datetimeoffset) as date);
GO
select cast(cast('2000-06-01 23:01:00 +00' as datetimeoffset) as smalldatetime);
GO
select cast(cast('2000-06-01 23:01:00 +00' as datetimeoffset) as datetime);
GO
select cast(cast('2000-06-01 23:01:00 +00' as datetimeoffset) as datetime2);
GO
