/* This test files will check for scripting of table with stored procedures and user defined functions including diffferent inbuilt functions */

drop  procedure IF EXISTS routines_test_nvar;
go
drop  procedure IF EXISTS routines_test_num;
go
drop  procedure IF EXISTS routines_test_uid;
go
drop  procedure IF EXISTS routines_test_b1;
go
drop  procedure IF EXISTS routines_test_b2;
go
drop  procedure IF EXISTS routines_test_b3;
go
drop  procedure IF EXISTS routines_test_b4;
go
drop  function  IF EXISTS routines_test_b6;
go
DROP  function  IF EXISTS routines_func_nvar;
go
drop  function  IF EXISTS routines_test_func_opt;
go
drop  function  IF EXISTS routines_test_s;
go
drop  function  IF EXISTS routines_test_con;
go
drop  procedure IF EXISTS routines_test_t;
go
drop  procedure IF EXISTS routines_cur_var;
go
drop  procedure IF EXISTS routines_test_def;
go
drop  function  IF EXISTS routines_fc1;
go
drop  function  IF EXISTS routines_fc2;
go
drop  function  IF EXISTS routines_fc3;
go
drop  function  IF EXISTS routines_fc4;
go
drop  function  IF EXISTS routines_fc5;
go
drop  function  IF EXISTS routines_fc6;
go
drop  function  IF EXISTS routines_fc7;
go
DROP   TABLE  IF EXISTS routines_customers;
go

create procedure routines_test_nvar(@test_nvar_a nvarchar , @test_nvar_b int = 8)
AS
BEGIN
        SELECT @test_nvar_b=8;
END
go
create function routines_fc1(@fc1_a nvarchar) RETURNS nvarchar AS BEGIN return @fc1_a END;
go
create function routines_fc2(@fc2_a varchar) RETURNS varchar AS BEGIN return @fc2_a END;
go
create function routines_fc3(@fc3_a nchar) RETURNS nchar AS BEGIN return @fc3_a END;
go
create function routines_fc4(@fc4_a binary, @fc4_b tinyint, @fc4_c BIGINT, @fc4_d float) RETURNS binary AS BEGIN return @fc4_a END;
go
create function routines_fc5(@fc5_a varbinary) RETURNS varbinary AS BEGIN return @fc5_a END;
go
create function routines_fc6(@fc6_a char) RETURNS char AS BEGIN return @fc6_a END;
go

create procedure routines_test_uid(@test_uid_a uniqueidentifier output)
AS
BEGIN
        set @test_uid_a ='ce8af10a-2709-43b0-9e4e-a02753929d17';
        SELECT @test_uid_a as test_uid_a;
END;
go
CREATE TABLE routines_customers
( customer_id int NOT NULL,
  customer_name char(50) NOT NULL,
  address char(50),
  city char(50),
  state char(25),
  zip_code char(10),
  CONSTRAINT customers_pk PRIMARY KEY (customer_id)
);
go
create procedure routines_test_b1
AS
BEGIN
        select * from customers;
        select * from customers where customer_id = 25;
        select count(state) from customers;
END;
go
create procedure routines_test_b2(@test_b2_name char(255), @test_b2_city char(255), @test_b2_id int, @test_b2_address char(255), @test_b2_state char(255), @test_b2_cust_id int)
AS
BEGIN
        INSERT INTO customers (customer_name,address,city,state,customer_id) VALUES (@test_b2_name,@test_b2_address,@test_b2_city,@test_b2_state,@test_b2_cust_id);
        DELETE from customers where customer_id = @test_b2_id;
        ALTER TABLE customers ADD email varchar(255);
END;
go
create procedure routines_test_b3 @test_b3_paramout varchar(20) out
AS
BEGIN
SELECT @test_b3_paramout ='helloworld';
END;
go
create procedure routines_test_b4(@test_b4_a int, @test_b4_b char(255), @test_b4_c char(255), @test_b4_d char(255))
AS
SET @test_b4_a=10; SET Nocount ON;
DECLARE @test_b4_temp int =12; 
BEGIN
        INSERT INTO customers (customer_name,address,city,customer_id) VALUES (@test_b4_b,@test_b4_c,@test_b4_d,@test_b4_a);
END;
go

create function routines_test_b6(
    @test_b6_a INT,
    @test_b6_b DEC(10,2),
    @test_b6_c DEC(4,2)
)
RETURNS DEC(10,2)
AS 
BEGIN
    RETURN @test_b6_a * @test_b6_b * (1 - @test_b6_c);
END;
go
create function routines_func_nvar (@func_nvar_a nvarchar(23)) returns nvarchar(23) AS BEGIN return @func_nvar_a END;
go
CREATE FUNCTION routines_test_func_opt (@test_func_opt_name varchar(10))
RETURNS INT
 WITH RETURNS NULL ON NULL INPUT
AS
BEGIN
        RETURN 2;
END;
go
create function routines_test_s (@test_s_a char(45)) RETURNS char(45)
WITH SCHEMABINDING
AS 
BEGIN
        RETURN @test_s_a;
END;
go
create function routines_test_con(@test_con_a int)
RETURNS INT
 WITH CALLED ON NULL INPUT
AS
BEGIN
RETURN @test_con_a;
END;
go
create procedure routines_test_t (@test_t_a int)
AS
BEGIN
        begin try
                begin transaction
                        update Empl set Name ="Arman" where id =99;
                        update Empl set Name ="Anand" where id =100;
                commit transaction
                        print 'transaction committed'
        END try
                BEGIN catch
                        rollback transaction
                        print 'rollback'
                end catch
END;
go
CREATE PROCEDURE routines_test_def(@test_def_a int = 2, @test_def_b char(255) OUTPUT, @test_def_c varchar(20) = 'abc', @test_def_d varbinary(8))
AS
BEGIN
        SET @test_def_b = 'a';
        SELECT @test_def_a, @test_def_b, @test_def_c, @test_def_d;
END;
go
CREATE FUNCTION routines_fc7()
RETURNS @myRetTable table (a int PRIMARY KEY)
AS
BEGIN
INSERT INTO @myRetTable VALUES (1)
RETURN
END;
GO

--DROP

drop  procedure IF EXISTS routines_test_nvar;
go
drop  procedure IF EXISTS routines_test_num;
go
drop  procedure IF EXISTS routines_test_uid;
go
drop  procedure IF EXISTS routines_test_b1;
go
drop  procedure IF EXISTS routines_test_b2;
go
drop  procedure IF EXISTS routines_test_b3;
go
drop  procedure IF EXISTS routines_test_b4;
go
drop  function  IF EXISTS routines_test_b6;
go
DROP  function  IF EXISTS routines_func_nvar;
go
drop  function  IF EXISTS routines_test_func_opt;
go
drop  function  IF EXISTS routines_test_s;
go
drop  function  IF EXISTS routines_test_con;
go
drop  procedure IF EXISTS routines_test_t;
go
drop  procedure IF EXISTS routines_cur_var;
go
drop  procedure IF EXISTS routines_test_def;
go
drop  function  IF EXISTS routines_fc1;
go
drop  function  IF EXISTS routines_fc2;
go
drop  function  IF EXISTS routines_fc3;
go
drop  function  IF EXISTS routines_fc4;
go
drop  function  IF EXISTS routines_fc5;
go
drop  function  IF EXISTS routines_fc6;
go
drop  function  IF EXISTS routines_fc7;
go
DROP   TABLE  IF EXISTS routines_customers;
go
