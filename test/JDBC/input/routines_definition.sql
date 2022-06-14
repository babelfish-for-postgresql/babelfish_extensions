

#testing for all the datatypes of agrument#

#int, default value and nvarchar#
create procedure test_nvar(@a nvarchar , @b int = 8)
AS
BEGIN
        SELECT @b=8;
END
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_nvar';
go

drop procedure test_nvar;
go

#SMALLINT and INT OUTPUT
create schema sc1;
go

create procedure sc1.test_si(@a SMALLINT ,@b INT OUTPUT)
AS
BEGIN
        SELECT @a=70;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_si';
go

drop procedure sc1.test_si;
go

drop schema sc1;
go

#decimal
CREATE FUNCTION test_dec(
    @quantity INT,
    @list_price DEC(10,2),
    @discount DEC(4,2)
)
RETURNS DEC(10,2)
AS
BEGIN
    RETURN @quantity * @list_price * (1 - @discount);
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_dec';
go

drop function test_dec;
go

#char
create procedure test_char(@ch char)
AS
BEGIN
	set @ch ='c';
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_char';
go

drop procedure test_char;
go

#tinyint and bigint
create procedure test_ti(@a tinyint OUTPUT, @b BIGINT )
AS
BEGIN
	set @a=79;
	select @b=19;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_ti';
go

drop procedure test_ti;
go

#float
create procedure test_float(@a float )
AS
BEGIN
	set @a=98.0;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_float';
go

drop procedure test_float;
go

#numeric
create procedure test_num(@a numeric(20,6) OUTPUT)
AS
BEGIN
	set @a = 65;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_num';
go

drop procedure test_num;
go

#time and date
create procedure test_time(@a time(5) OUTPUT , @b date OUTPUT)
AS
BEGIN
	set @a='12:54';
	set @b='2022-06-11';
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_time';
go

drop procedure test_time;
go

#datetime
create procedure test_dt(@a datetime output)
AS
BEGIN
	set @a='2022 -06-12 12:43';
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_dt';
go

drop procedure test_dt;
go

#UID
create procedure test_uid(@a uniqueidentifier output)
AS
BEGIN
	set @a ='ce8af10a-2709-43b0-9e4e-a02753929d17';
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_uid';
go

drop procedure test_uid;
go

#check with different sqlbody.#

CREATE TABLE customers
( customer_id int NOT NULL,
  customer_name char(50) NOT NULL,
  address char(50),
  city char(50),
  state char(25),
  zip_code char(10),
  CONSTRAINT customers_pk PRIMARY KEY (customer_id)
);
go

create procedure test_b1
AS
BEGIN
	select * from customers;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b1';
go

drop procedure test_b1;
go

create procedure test_b2(@id int)
AS
BEGIN
	select * from customers where customer_id = @id;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b2';
go

drop procedure test_b2;
go

create procedure test_b3(@name char(255), @city char(255), @address char(255), @state char(255), @cust_id int)
AS
BEGIN
	INSERT INTO customers (customer_name,address,city,state,customer_id) VALUES (@name,@address,@city,@state,@cust_id);
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b3';
go

drop procedure test_b3;
go

create procedure test_b4(@id int)
AS
BEGIN
	DELETE from customers where customer_id = @id;

END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b4';
go

drop procedure test_b4;
go

create procedure test_b5(@id int)
AS
BEGIN
	select customer_name,city,address from customers where customer_id=@id;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b5';
go

drop procedure test_b5;
go

create procedure test_b6(@id int)
AS
BEGIN
	select city,state,zip_code from customers where customer_id=@id;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b6';
go

drop procedure test_b6;
go

create procedure test_b7(@name char(50))
AS
BEGIN
	select customer_id,city,address from customers where customer_name=@name;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b7';
go

drop procedure test_b7;
go

create function test_b8 (@cost int)
RETURNS INT
AS
BEGIN
	RETURN @cost * 10;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b8';
go

drop function test_b8;
go

drop table customers;
go

create function test_b9(
    @a INT,
    @b DEC(10,2),
    @c DEC(4,2)
)
RETURNS DEC(10,2)
AS 
BEGIN
    RETURN @a * @b * (1 - @c);
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b9';
go

drop function test_b9;
go

create function test_b10(@x int, @y int)
RETURNS int
AS
BEGIN
	RETURN 200+(@x * @y);
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b10';
go

drop function test_b10;
go

create function test_b11(@k SMALLINT)
RETURNS SMALLINT
AS
BEGIN
	RETURN @k/27;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b11';
go

drop function test_b11;
go

create schema s1;
go

create function s1.test_b12 (@a varchar)
RETURNS varchar
AS
BEGIN
	RETURN @a;
END;
go

select tsql_get_functiondef(oid) from pg_proc where proname='test_b12';
go

drop function s1.test_b12;
go

drop schema s1;
go



