select collname from PG_COLLATION where oid = (
    select attcollation from pg_attribute where attname = 'col_a' and
    attrelid = (
        select oid from pg_class where relname = 'bbf_3801_tab'
    )
);
GO

select collname from PG_COLLATION where oid = (
    select attcollation from pg_attribute where attname = 'col_a' and
    attrelid = (
        select oid from pg_class where relname = 'bbf_3801_view'
    )
);
GO

insert into bbf_3801_tab1 values ('b'), ('B');
GO

-- this should fail 
insert into bbf_3801_tab1 values ('aBc');
GO

select * from bbf_3801_tab1;
GO

insert into bbf_3801_tab2 values ('b'), ('B');
GO

-- this should fail
insert into bbf_3801_tab2 values ('aBc');
GO

select * from bbf_3801_tab2;
GO

insert into bbf_3801_tab3 values ('a');
GO

select * from bbf_3801_tab3;
GO

select coll.collname from 
pg_collation coll join pg_attribute attr on attr.attcollation = coll.oid
where attr.attrelid = (select oid from pg_class where relname = 'bbf_3801_tab4')
and (attr.attname = 'col_a1' or attr.attname = 'col_b1');
GO

select coll.collname from 
pg_collation coll join pg_attribute attr on attr.attcollation = coll.oid
where attr.attrelid = (select oid from pg_class where relname = 'bbf_3801_tab5')
and (attr.attname = 'col_a2' or attr.attname = 'col_b2');
GO

select coll.collname from 
pg_collation coll join pg_attribute attr on attr.attcollation = coll.oid
where attr.attrelid = (select oid from pg_class where relname = 'bbf_3801_tab6')
and (attr.attname = 'col_a3' or attr.attname = 'col_b3');
GO

DROP VIEW bbf_3801_view;
GO

DROP TABLE bbf_3801_tab;
GO

DROP TABLE bbf_3801_tab1;
GO

DROP TABLE bbf_3801_tab2;
GO

DROP TABLE bbf_3801_tab3;
GO

DROP TABLE bbf_3801_tab4;
GO

DROP TABLE bbf_3801_tab5;
GO

DROP TABLE bbf_3801_tab6;
GO

DROP TYPE bbf_3801_type;
GO
