drop procedure if exists babel_3592_insert_multiline
go

drop table if exists babel_3592_t1
go

drop table if exists babel_3592_t2
go

drop table if exists babel_3592_t3
go

create table babel_3592_t1(a1 int PRIMARY KEY, b1 int)
go

create index index_babel_3592_t1_b1 on babel_3592_t1(b1)
go

create table babel_3592_t2(a2 int PRIMARY KEY, b2 int)
go

create index index_babel_3592_t2_b2 on babel_3592_t2(b2)
go

create table babel_3592_t3(a3 int PRIMARY KEY, b3 int)
go

select set_config('babelfishpg_tsql.explain_costs', 'off', false)
go

select set_config('babelfishpg_tsql.enable_pg_hint', 'on', false);
go

-- TEST INSERT queries 
CREATE PROCEDURE babel_3592_insert_multiline AS
insert into babel_3592_t2 select * from babel_3592_t1 where b1 = 1
insert into babel_3592_t2
    select *
    from babel_3592_t1 with(index(index_babel_3592_t1_b1))
    where b1 = 1
insert into babel_3592_t2 select * from babel_3592_t1 where b1 = 1 option(table hint(babel_3592_t1, index(index_babel_3592_t1_b1)))
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3592_insert_multiline';
GO

CREATE PROCEDURE babel_3592_insert_singleline AS insert into babel_3592_t2 select * from babel_3592_t1 where b1 = 1 option(table hint(babel_3592_t1, index(index_babel_3592_t1_b1)))
GO

EXEC babel_3592_insert_multiline
GO

EXEC babel_3592_insert_singleline
GO

set babelfish_showplan_all on
go

EXEC babel_3592_insert_multiline
GO

EXEC babel_3592_insert_singleline
GO

set babelfish_showplan_all off
go

-- Test UPDATE queries
CREATE PROCEDURE babel_3592_updates_multiline AS
update babel_3592_t1 
    set a1 = 1 where b1 = 1
update babel_3592_t1 
    with(index(index_babel_3592_t1_b1)) 
    set a1 = 1 where b1 = 1
update babel_3592_t1 set a1 = 1 where b1 = 1 option(table hint(babel_3592_t1, index(index_babel_3592_t1_b1)))
GO

CREATE PROCEDURE babel_3592_updates_singleline AS update babel_3592_t1 set a1 = 1 where b1 = 1 option(table hint(babel_3592_t1, index(index_babel_3592_t1_b1)))
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3592_updates_multiline';
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3592_updates_singleline';
GO

EXEC babel_3592_insert_multiline
GO

EXEC babel_3592_updates_singleline
GO

set babelfish_showplan_all on
go

EXEC babel_3592_insert_multiline
GO

EXEC babel_3592_updates_singleline
GO

set babelfish_showplan_all off
go

-- Test DELETE queries with and without hints
CREATE PROCEDURE babel_3592_delete_multiline AS
delete from babel_3592_t1 where b1 = 1
delete from babel_3592_t1 with
    (index
        (index_babel_3592_t1_b1)
    )
    where b1 = 1
delete from babel_3592_t1 where b1 = 1 option(table hint(babel_3592_t1, index(index_babel_3592_t1_b1)))
GO

CREATE PROCEDURE babel_3592_delete_singleline AS delete from babel_3592_t1 where b1 = 1 option(table hint(babel_3592_t1, index(index_babel_3592_t1_b1)))
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3592_delete_multiline';
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3592_delete_singleline';
GO

EXEC babel_3592_insert_multiline
GO

EXEC babel_3592_delete_singleline
GO

set babelfish_showplan_all on
go

EXEC babel_3592_insert_multiline
GO

EXEC babel_3592_delete_singleline
GO

set babelfish_showplan_all off
go

-- Test mixed statements
create procedure babel_3592_proc_mixed_statements AS
    update babel_3592_t1 with(index(index_babel_3592_t1_b1)) set a1 = 1 where b1 = 1
        select * from babel_3592_t1 inner loop join babel_3592_t2 on babel_3592_t1.a1 = babel_3592_t2.a2
    select * from babel_3592_t1 inner merge
     join babel_3592_t2
      on babel_3592_t1.a1 = babel_3592_t2.a2

    update babel_3592_t1 set a1 = 1 where b1 = 1 option(table hint(babel_3592_t1, index(index_babel_3592_t1_b1)))
    delete babel_3592_t1 from babel_3592_t1 inner merge join babel_3592_t2 on babel_3592_t1.a1 = babel_3592_t2.a2 where b1 = 1 and b2 = 1
delete babel_3592_t1 from babel_3592_t1 with(index(index_babel_3592_t1_b1)) left outer merge join babel_3592_t2 on babel_3592_t1.a1 = babel_3592_t2.a2 where b1 = 1 and b2 = 1
insert
into
babel_3592_t2 select * from babel_3592_t1 where b1 = 1

insert into babel_3592_t2 select * from babel_3592_t1 with(index(index_babel_3592_t1_b1)) where b1 = 1

insert into babel_3592_t2 select * from babel_3592_t1 where b1 = 1 option(table hint(babel_3592_t1, index(index_babel_3592_t1_b1)))

-- comments inside the stored proc
update babel_3592_t1 set a1 = 1 where b1 = 1
/*
 *multiline comment
 */
 select * from babel_3592_t1 with(index(index_babel_3592_t1_b1)), babel_3592_t2 with(index(index_babel_3592_t2_b2)) where b1 = 1 and b2 = 1
GO

SELECT prosrc FROM pg_proc WHERE proname = 'babel_3592_proc_mixed_statements';
GO

EXEC babel_3592_proc_mixed_statements
GO

set babelfish_showplan_all on
go

EXEC babel_3592_proc_mixed_statements
GO

-- clean up
set babelfish_showplan_all off
go

DROP PROCEDURE  babel_3592_insert_multiline
GO

DROP PROCEDURE  babel_3592_insert_singleline
GO

DROP PROCEDURE  babel_3592_updates_multiline
GO

DROP PROCEDURE  babel_3592_updates_singleline
GO

DROP PROCEDURE  babel_3592_delete_multiline
GO

DROP PROCEDURE  babel_3592_delete_singleline
GO

DROP PROCEDURE  babel_3592_proc_mixed_statements
GO

DROP TABLE babel_3592_t1
GO

DROP TABLE babel_3592_t2
GO

DROP TABLE babel_3592_t3
GO
