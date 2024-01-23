CREATE TABLE forjson_auto_vu_t_users ([Id] int, [firstname] varchar(50), [lastname] varchar(50), [email] varchar(50));
CREATE TABLE forjson_auto_vu_t_orders ([Id] int, [userid] int, [productid] int, [quantity] int, [orderdate] Date);
CREATE TABLE forjson_auto_vu_t_products ([Id] int, [name] varchar(50), [price] varchar (25));
CREATE TABLE forjson_auto_vu_t_sales ([Id] int, [price] varchar(25), [totalSales] int);
CREATE TABLE forjson_auto_vu_t_times ([Id] int, [date] Date);

INSERT INTO forjson_auto_vu_t_users VALUES (1, 'j', 'o', 'testemail'), (1, 'e', 'l', 'testemail2');
INSERT INTO forjson_auto_vu_t_orders VALUES (1, 1, 1, 5, '2023-06-25'), (2, 1, 1, 6, '2023-06-25');
INSERT INTO forjson_auto_vu_t_products VALUES (1, 'A', 20), (1, 'B', 30);
INSERT INTO forjson_auto_vu_t_sales VALUES (1, 20, 50), (2, 30, 100);
INSERT INTO forjson_auto_vu_t_times VALUES (1, '2023-11-26'), (2, '2023-11-27');
GO

CREATE VIEW forjson_vu_v_1 AS 
SELECT (
    select U.Id AS "users.userid", O.productId AS "order.productId", O.Id AS "product.oid", P.price AS "product.price" FROM forjson_auto_vu_t_users U JOIN forjson_auto_vu_t_orders O ON (U.id = O.userid) JOIN forjson_auto_vu_t_products P ON (P.id = O.productid) FOR JSON AUTO
) c1
GO

CREATE VIEW forjson_vu_v_2 AS
SELECT (
    select U.Id AS "users.userid",
           U.firstname as "firstname"
    FROM forjson_auto_vu_t_users U FOR JSON AUTO
) c1
GO

CREATE VIEW forjson_vu_v_3 AS
SELECT (
    select U.Id AS "users.userid",
           U.firstname as "firstname",
           O.productId AS "order.productId"
    FROM forjson_auto_vu_t_users U JOIN forjson_auto_vu_t_orders O ON (U.id = O.userid) FOR JSON AUTO
) c1
GO

CREATE VIEW forjson_vu_v_4 AS 
SELECT (
    select U.Id AS "users.userid", O.productId AS "order.productId", O.Id AS "product.oid", P.price AS "product.price", S.totalSales AS "totalsales" FROM forjson_auto_vu_t_users U JOIN forjson_auto_vu_t_orders O ON (U.id = O.userid) JOIN forjson_auto_vu_t_products P ON (P.id = O.productid) JOIN forjson_auto_vu_t_sales S ON (P.price = S.price) FOR JSON AUTO
) c1
GO

CREATE VIEW forjson_vu_v_5 AS
SELECT (
    select forjson_auto_vu_t_users.Id,
           firstname,
           productId
    FROM forjson_auto_vu_t_users JOIN forjson_auto_vu_t_orders ON (forjson_auto_vu_t_users.id = userid) FOR JSON AUTO
) c1
GO

CREATE VIEW forjson_vu_v_6 AS
SELECT (
    select Id,
           firstname,
           lastname
    FROM forjson_auto_vu_t_users FOR JSON AUTO
) c1
GO

CREATE VIEW forjson_vu_v_7 AS
SELECT (
    select U.Id,
           name,
           price
    FROM forjson_auto_vu_t_users U JOIN forjson_auto_vu_t_products P ON (U.Id = P.Id) FOR JSON AUTO
) c1
GO

CREATE PROCEDURE forjson_vu_p_1 AS
SELECT (
    select U.Id AS "users.userid", O.productId AS "order.productId", O.Id AS "product.oid", P.price AS "product.price", S.totalSales AS "totalsales" FROM forjson_auto_vu_t_users U JOIN forjson_auto_vu_t_orders O ON (U.id = O.userid) JOIN forjson_auto_vu_t_products P ON (P.id = O.productid) JOIN forjson_auto_vu_t_sales S ON (P.price = S.price) FOR JSON AUTO
) c1
GO

INSERT INTO forjson_auto_vu_t_sales VALUES (1, NULL, NULL), (2, NULL, NULL);
GO

CREATE VIEW forjson_vu_v_8 AS 
SELECT (
    select U.Id AS "users.userid", O.productId AS "order.productId", O.Id AS "product.oid", P.price AS "product.price", S.totalSales AS "totalsales" FROM forjson_auto_vu_t_users U JOIN forjson_auto_vu_t_orders O ON (U.id = O.userid) JOIN forjson_auto_vu_t_products P ON (P.id = O.productid) JOIN forjson_auto_vu_t_sales S ON (P.price = S.price) FOR JSON AUTO
) c1
GO

CREATE VIEW forjson_vu_v_9 AS 
SELECT (
    select U.Id AS "users.userid", O.productId AS "order.productId", O.Id AS "product.oid", P.price AS "product.price", S.totalSales AS "totalsales", T.date as "date" FROM forjson_auto_vu_t_users U JOIN forjson_auto_vu_t_orders O ON (U.id = O.userid) JOIN forjson_auto_vu_t_products P ON (P.id = O.productid) JOIN forjson_auto_vu_t_sales S ON (P.price = S.price) JOIN forjson_auto_vu_t_times T ON (S.Id = T.Id) FOR JSON AUTO
) c1
GO

-- tests unique characters
CREATE VIEW forjson_vu_v_10 AS 
SELECT (
    select U.Id AS "users.userid", O.productId AS "өглөө", O.Id AS "product.oid", P.price AS "product.price", S.totalSales AS "totalsales" FROM forjson_auto_vu_t_users U JOIN forjson_auto_vu_t_orders O ON (U.id = O.userid) JOIN forjson_auto_vu_t_products P ON (P.id = O.productid) JOIN forjson_auto_vu_t_sales S ON (P.price = S.price) FOR JSON AUTO
) c1
GO

CREATE VIEW forjson_vu_v_11 AS
SELECT (
    select U.Id AS "users.ελπίδα",
           U.firstname as "爱",
           U.lastname as "كلب"
    FROM forjson_auto_vu_t_users U FOR JSON AUTO
) c1
GO

CREATE VIEW forjson_vu_v_12 AS 
SELECT (
    select totalSales FROM forjson_auto_vu_t_sales FOR JSON AUTO, INCLUDE_NULL_VALUES
) c1
GO

create table t50 (x nvarchar(20))
insert into t50 values ('some string')
go

CREATE VIEW forjson_vu_v_13 AS 
SELECT (
    select json_modify('{"a":"b"}', '$.a', x) from (select * from t50 for json auto) a ([x])
) c1
GO

CREATE VIEW forjson_vu_v_14 AS 
SELECT (
    select json_query((select U.Id AS "users.userid", O.productId AS "order.productId", O.Id AS "product.oid", P.price AS "product.price", S.totalSales AS "totalsales" FROM forjson_auto_vu_t_users U JOIN forjson_auto_vu_t_orders O ON (U.id = O.userid) JOIN forjson_auto_vu_t_products P ON (P.id = O.productid) JOIN forjson_auto_vu_t_sales S ON (P.price = S.price) JOIN forjson_auto_vu_t_times T ON (S.Id = T.Id) FOR JSON AUTO)) AS [data]
) c1
GO

CREATE PROCEDURE forjson_vu_p_2 AS
BEGIN
    CREATE TABLE users ([Id] int, [firstname] varchar(50));
    CREATE TABLE orders ([Id] int, [productid] int, [quantity] int, [orderdate] Date);
    INSERT INTO users VALUES (1, 'j'), (2, 'k'), (3, 'l')
    INSERT INTO orders VALUES (1, 1, 100, '01-01-2024'), (2, 2, 500, '01-01-2024')
    select U.Id AS "users.userid", U.firstname as "firstname" FROM users U JOIN orders O ON (U.id = O.Id) FOR JSON AUTO
    DROP TABLE users
    DROP TABLE orders
END
GO

CREATE FUNCTION forjson_vu_f_1()
RETURNS sys.NVARCHAR(5000) AS
BEGIN
RETURN (select U.Id AS "users.userid", O.productId AS "өглөө", O.Id AS "product.oid", P.price AS "product.price", S.totalSales AS "totalsales" FROM forjson_auto_vu_t_users U JOIN forjson_auto_vu_t_orders O ON (U.id = O.userid) JOIN forjson_auto_vu_t_products P ON (P.id = O.productid) JOIN forjson_auto_vu_t_sales S ON (P.price = S.price) FOR JSON AUTO)
END
GO

CREATE PROCEDURE forjson_vu_p_3 AS
BEGIN
    with cte as (select 1 as Id), cte2 as (select 1 as Id) select U.Id, O.Id from cte U JOIN cte2 O on (U.Id = O.Id) for json auto
END
GO

CREATE PROCEDURE forjson_vu_p_4 AS
BEGIN
    with cte as (select Id, firstname from forjson_auto_vu_t_users), cte2 as (select Id, productid from forjson_auto_vu_t_orders) 
    select U.Id, O.productId from cte U JOIN cte2 O ON (U.Id = O.Id) for JSON AUTO
END
GO

CREATE PROCEDURE forjson_vu_p_5 AS
BEGIN
    SELECT  x.Val, y.Val ValY FROM (VALUES (1)) AS x(Val) JOIN (SELECT  Val FROM (VALUES (1)) AS _(Val)) y ON y.Val = x.Val for json auto
END
GO

CREATE TRIGGER forjson_vu_trigger_1 on forjson_auto_vu_t_users for insert as
BEGIN
    with cte (Id, firstname) as (select Id, firstname from forjson_auto_vu_t_users), cte2 (Id, firstname) as (select Id, firstname from cte) 
    select * from cte2 for JSON AUTO
END
GO

CREATE TRIGGER forjson_vu_trigger_2 on forjson_auto_vu_t_users for insert as
begin
    select U.Id AS "users.userid",
           U.firstname as "firstname",
           U.lastname as "lastname",
           O.productId AS "order.productId"
    FROM forjson_auto_vu_t_users U JOIN forjson_auto_vu_t_orders O ON (U.id = O.userid) FOR JSON AUTO
end;
go

