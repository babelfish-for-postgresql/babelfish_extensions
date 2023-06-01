SELECT set_config('timezone', 'Australia/Sydney', false)
GO

select current_setting('TIMEZONE');
GO
drop table if exists gh_1412_t1;
GO
create table gh_1412_t1
(
id int,
dto datetimeoffset,
dto_default datetimeoffset default '2000-06-01 00:00:00',
comment varchar(100)
);
GO
insert gh_1412_t1 values (1, '2000-06-01 00:00:00', default, 'custom time zone');
GO
drop view if exists gh_1412_v1;
GO
create view gh_1412_v1 as select cast('2000-06-01 00:00:00' as datetimeoffset) as dto;
GO

SELECT set_config('timezone', 'UTC', false)
GO

insert gh_1412_t1 values (2, '2000-06-01 00:00:00', default, 'default time zone');
GO
