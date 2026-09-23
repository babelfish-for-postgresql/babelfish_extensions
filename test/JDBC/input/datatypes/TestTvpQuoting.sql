-- Quoting of TVP type / schema names in sp_executesql
create schema babel_6481_s
go
create type babel_6481_s.placing as table (a int)
go
create type babel_6481_s.babel_6481_t as table (a int)
go
-- Scenario 1: schema-qualified TVP using a reserved keyword as type name
declare @v1 babel_6481_s.placing
insert into @v1 values (10)
exec sp_executesql N'select a from @x order by a',
                   N'@x babel_6481_s.placing readonly', @x = @v1
go
-- Scenario 2: schema-qualified TVP with non-reserved names
declare @v2 babel_6481_s.babel_6481_t
insert into @v2 values (20)
exec sp_executesql N'select a from @x order by a',
                   N'@x babel_6481_s.babel_6481_t readonly', @x = @v2
go
-- Scenario 3: multi-row schema-qualified reserved-keyword TVP
declare @v3 babel_6481_s.placing
insert into @v3 values (100), (200), (300)
exec sp_executesql N'select a from @x order by a',
                   N'@x babel_6481_s.placing readonly', @x = @v3
go
-- Scenario 4: re-run scenario 1 in the same session
declare @v4 babel_6481_s.placing
insert into @v4 values (40)
exec sp_executesql N'select a from @x order by a',
                   N'@x babel_6481_s.placing readonly', @x = @v4
go
drop type babel_6481_s.placing
go
drop type babel_6481_s.babel_6481_t
go
drop schema babel_6481_s
go
