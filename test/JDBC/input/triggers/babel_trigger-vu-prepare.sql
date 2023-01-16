-- TO TEST WITH THE AFTER KEYWORD --

-- to test simple working
create table babel_trigger_vu_prepare_t1(col nvarchar(60))
GO

create trigger babel_trigger_vu_prepare_trg1 on babel_trigger_vu_prepare_t1 after insert
as
begin
  SELECT 'trigger invoked'
end
GO

-- to test comma separator
create table babel_trigger_vu_prepare_t2(col nvarchar(60))
GO

insert into babel_trigger_vu_prepare_t2 (col) select N'Muffler'
GO

create trigger babel_trigger_vu_prepare_trg2 on babel_trigger_vu_prepare_t2 after insert, delete
as
begin
  SELECT 'trigger invoked'
end
GO

-- to test inserted and deleted transition tables
CREATE TABLE babel_trigger_vu_prepare_products1(
    product_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    brand_id INT NOT NULL,
    category_id INT NOT NULL,
    model_year SMALLINT NOT NULL,
    list_price DEC(10,2) NOT NULL
)
GO

CREATE TABLE babel_trigger_vu_prepare_product_audits1(
    product_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    brand_id INT NOT NULL,
    category_id INT NOT NULL,
    model_year SMALLINT NOT NULL,
    list_price DEC(10,2) NOT NULL,
    operation CHAR(3) NOT NULL,
    CHECK(operation = 'INS' or operation='DEL')
)
GO

CREATE TRIGGER babel_trigger_vu_prepare_trg_product_audit1
ON babel_trigger_vu_prepare_products1
AFTER INSERT
AS
BEGIN
    INSERT INTO babel_trigger_vu_prepare_product_audits1(
        product_id, 
        product_name,
        brand_id,
        category_id,
        model_year,
        list_price, 
        operation
    )
    SELECT
        i.product_id,
        product_name,
        brand_id,
        category_id,
        model_year,
        i.list_price,
        'INS'
    FROM
        inserted i
END
GO


-- TO TEST WITH THE FOR KEYWORD --

-- to test simple working
create table babel_trigger_vu_prepare_t3(col nvarchar(60))
GO

create trigger babel_trigger_vu_prepare_trg3 on babel_trigger_vu_prepare_t3 for insert
as
begin
  SELECT 'trigger invoked'
end
GO

-- to test comma separator
create table babel_trigger_vu_prepare_t4(col nvarchar(60))
GO

insert into babel_trigger_vu_prepare_t4 (col) select N'Muffler'
GO

create trigger babel_trigger_vu_prepare_trg4 on babel_trigger_vu_prepare_t4 after insert, delete
as
begin
  SELECT 'trigger invoked'
end
GO

-- to test inserted and deleted transition tables
CREATE TABLE babel_trigger_vu_prepare_products2(
    product_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    brand_id INT NOT NULL,
    category_id INT NOT NULL,
    model_year SMALLINT NOT NULL,
    list_price DEC(10,2) NOT NULL
)
GO

CREATE TABLE babel_trigger_vu_prepare_product_audits2(
    product_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    brand_id INT NOT NULL,
    category_id INT NOT NULL,
    model_year SMALLINT NOT NULL,
    list_price DEC(10,2) NOT NULL,
    operation CHAR(3) NOT NULL,
    CHECK(operation = 'INS' or operation='DEL')
)
GO

CREATE TRIGGER babel_trigger_vu_prepare_trg_product_audit2
ON babel_trigger_vu_prepare_products2
FOR INSERT
AS
BEGIN
    INSERT INTO babel_trigger_vu_prepare_product_audits2(
        product_id, 
        product_name,
        brand_id,
        category_id,
        model_year,
        list_price, 
        operation
    )
    SELECT
        i.product_id,
        product_name,
        brand_id,
        category_id,
        model_year,
        i.list_price,
        'INS'
    FROM
        inserted i
END
GO

-- To test drop trigger without table name --

-- to test that triggers must have unique name
create table babel_trigger_vu_prepare_t5(col nvarchar(60))
GO

create trigger babel_trigger_vu_prepare_trg5 on babel_trigger_vu_prepare_t5 after insert
as
begin
  SELECT 'trigger invoked'
end
GO

create table babel_trigger_vu_prepare_t6(col nvarchar(60))
GO

-- to test that dropping a table with triggers defined on it succeeds
create table babel_trigger_vu_prepare_testTbl(colA int not null primary key, colB varchar(20))
GO

create trigger babel_trigger_vu_prepare_trig1 on babel_trigger_vu_prepare_testTbl after insert
as
begin
	SELECT 'trigger1 invoked'
end
GO

create trigger babel_trigger_vu_prepare_trig2 on babel_trigger_vu_prepare_testTbl after insert
as
begin
	SELECT 'trigger2 invoked'
end
GO

-- to test trigger created inside schema
create schema babel_trigger_vu_prepare_sch1
GO

create table babel_trigger_vu_prepare_sch1.babel_trigger_vu_prepare_t1(col nvarchar(60))
GO

create trigger babel_trigger_vu_prepare_trig3 on babel_trigger_vu_prepare_sch1.babel_trigger_vu_prepare_t1 after insert
as
begin
	SELECT 'trigger3 from sch1 invoked'
end
GO

