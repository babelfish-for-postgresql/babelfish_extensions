-- CARRYING OUT TEST WITH THE AFTER KEYWORD

-- a simple test
insert into babel_trigger_vu_prepare_t1 (col) select N'Muffler'
GO

drop trigger babel_trigger_vu_prepare_trg1
GO

-- test drop trigger if exists
create trigger babel_trigger_vu_prepare_trg1 on babel_trigger_vu_prepare_t1 after insert
as
begin
  SELECT 'trigger invoked'
end
GO

drop trigger if exists babel_trigger_vu_prepare_trg1
GO

drop trigger if exists babel_trigger_vu_prepare_trg1
GO

-- test comma separator

insert into babel_trigger_vu_prepare_t2 (col) select N'Apple'
GO

delete from babel_trigger_vu_prepare_t2 where col = N'Apple'
GO

-- test inserted and deleted transition tables
INSERT INTO babel_trigger_vu_prepare_products1(
	product_id,
    product_name, 
    brand_id, 
    category_id, 
    model_year, 
    list_price
)
VALUES (
	1,
    'Test product',
    1,
    1,
    2018,
    599
)
GO

SELECT * FROM babel_trigger_vu_prepare_product_audits1
GO


-- CARRY OUT THE SAME TESTS WITH THE FOR KEYWORD --

-- a simple test
insert into babel_trigger_vu_prepare_t3 (col) select N'Muffler'
GO

drop trigger babel_trigger_vu_prepare_trg3
GO

-- test drop trigger if exists
create trigger babel_trigger_vu_prepare_trg3 on babel_trigger_vu_prepare_t3 for insert
as
begin
  SELECT 'trigger invoked'
end
GO

drop trigger if exists babel_trigger_vu_prepare_trg3
GO

drop trigger if exists babel_trigger_vu_prepare_trg3
GO

-- test comma separator
insert into babel_trigger_vu_prepare_t4 (col) select N'Apple'
GO

delete from babel_trigger_vu_prepare_t4 where col = N'Apple'
GO


-- test inserted and deleted transition tables


INSERT INTO babel_trigger_vu_prepare_products2(
	product_id,
    product_name, 
    brand_id, 
    category_id, 
    model_year, 
    list_price
)
VALUES (
	1,
    'Test product',
    1,
    1,
    2018,
    599
)
GO

SELECT * FROM babel_trigger_vu_prepare_product_audits2
GO


-- Test drop trigger without table name --
-- First, test that triggers must have unique names
create trigger babel_trigger_vu_prepare_trg5 on babel_trigger_vu_prepare_t6 after insert  --should throw error
as
begin
  SELECT 'trigger invoked'
end
GO

-- Now, test that drop trigger works without tablename
drop trigger babel_trigger_vu_prepare_trg5
GO

-- Test that drop trigger statement on non-existent trigger throws error
drop trigger babel_trigger_vu_prepare_trg5
GO
drop trigger if exists babel_trigger_vu_prepare_trg5
GO

-- Test that dropping a table with triggers defined on it succeeds

drop table babel_trigger_vu_prepare_testTbl
GO

-- Test 'NOT FOR REPLICATION' syntax
create trigger babel_trigger_vu_prepare_trg5 on babel_trigger_vu_prepare_t5 after insert
NOT FOR REPLICATION
as
begin
  SELECT 'trigger invoked'
end
GO

insert into babel_trigger_vu_prepare_t5 (col) select N'Muffler'
GO


