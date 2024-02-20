
-- pre-test cleanup
drop table if exists jtds_nvarchar_max_tab1
go
drop table if exists jtds_nvarchar_max_data_tab
go

-- test data
create table jtds_nvarchar_max_data_tab (id int, st nvarchar(max))
go
insert into jtds_nvarchar_max_data_tab values (1, 'lj3wqE3KGfAxmLgfCgwNpKqZViapgUUjrSxzoebtvyVCWYew9Y3yJ8GEzhpjoMmX')
insert into jtds_nvarchar_max_data_tab values (2, '4uyJp45fjKxHhANMZzr1dqgcQmMJNT2Mbyp1v06WvKWX3fpJyzYAKNZOY3lkJ1z6')
insert into jtds_nvarchar_max_data_tab values (3, 'tQCrp7KnW8QxWM9BjsR8XEHiwM8PA2i8XBPJMcHi9p0bYBIQNGar3bvAdvgGKzbB')
insert into jtds_nvarchar_max_data_tab values (4, 'wLrui6MHI0nNTjNE1duq6ceULP8DwvCaBnq5CsWMfD2tiUS47PuV3BGvMPxkw2t7')
insert into jtds_nvarchar_max_data_tab values (5, 'AALdAoIE7hiPPNCLsGGC7sdPoB39SZfJ0xrxodKjKDgG1XsWXsO9Q8a3yUnjmhUc')
insert into jtds_nvarchar_max_data_tab values (6, 'RacLS9WFUaxfzKVIaVxUjOqBTGct3TC2J3huk58ocl899X851HhVJA4RbPyS4LZS')
insert into jtds_nvarchar_max_data_tab values (7, 'rlGrVDPsmtNM4OH1p5c4FOhUVz1cQet91wIZAvjOupVtVDPbDEOmhvtnL2Lo1ndY')
insert into jtds_nvarchar_max_data_tab values (8, '4PxSBAM1hG4RCJiFDqKhzrlADzK4ejk5e6kwsu81Y8PzWLJ1czlrEXaGdEdSq0Z7')
go

-- table to insert string of increasing length into
create table jtds_nvarchar_max_tab1 (exp_count int, col1 nvarchar(max))
go

-- empty and short strings
insert into jtds_nvarchar_max_tab1 values (-1, null)
go
insert into jtds_nvarchar_max_tab1 values (0, '')
go
insert into jtds_nvarchar_max_tab1 values (16,
    substring((select top 1 st from jtds_nvarchar_max_data_tab order by id), 1, 16))
go

-- long strings
insert into jtds_nvarchar_max_tab1 values (8192,
    (select concat(a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a) from
        (select string_agg(st, '') as a from (select top 8 st from jtds_nvarchar_max_data_tab order by id))))
go
insert into jtds_nvarchar_max_tab1 values (16384,
    (select concat(b, b) from
        (select concat(a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a) as b from
            (select string_agg(st, '') as a from (select top 8 st from jtds_nvarchar_max_data_tab order by id)))))
go
insert into jtds_nvarchar_max_tab1 values (32768,
    (select concat(b, b, b, b) from
        (select concat(a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a) as b from
            (select string_agg(st, '') as a from (select top 8 st from jtds_nvarchar_max_data_tab order by id)))))
go
insert into jtds_nvarchar_max_tab1 values (65536,
    (select concat(b, b, b, b, b, b, b, b) from
        (select concat(a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a) as b from
            (select string_agg(st, '') as a from (select top 8 st from jtds_nvarchar_max_data_tab order by id)))))
go
insert into jtds_nvarchar_max_tab1 values (131072,
    (select concat(b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b) from
        (select concat(a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a) as b from
            (select string_agg(st, '') as a from (select top 8 st from jtds_nvarchar_max_data_tab order by id)))))
go

-- check inserted length
select exp_count, length(col1) from jtds_nvarchar_max_tab1 order by exp_count
go

-- check inserted contents
select col1 from jtds_nvarchar_max_tab1 where exp_count = 8192
go

-- data is returned, but cannot be read by JTDS
-- see test runner log file for error details
--select col1 from jtds_nvarchar_max_tab1 where exp_count = 16384
--go

-- data is not returned, server closes the connection
-- see server log file for error details
--select col1 from jtds_nvarchar_max_tab1 where exp_count = 32768
--go

-- cleanup
drop table jtds_nvarchar_max_tab1
go
drop table jtds_nvarchar_max_data_tab
go
