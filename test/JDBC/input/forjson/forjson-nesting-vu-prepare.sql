CREATE TABLE forjson_nesting_vu_t_users (
    [Id] int,
    [firstname] varchar(50),
    [lastname] varchar(50),
    [email] varchar(50),
);
GO
CREATE TABLE forjson_nesting_vu_t_products (
    [Id] int,
    [name] varchar(50),
    [price] varchar (25)
);
GO
CREATE TABLE forjson_nesting_vu_t_orders (
    [Id] int,
    [userid] int,
    [productid] int,
    [quantity] int,
    [orderdate] Date
);
GO

INSERT INTO forjson_nesting_vu_t_users
VALUES 
    (1, 'John', 'Doe', 'johndoe@gmail.com'),
    (2, 'Jane', 'Smith', 'janesmith@yahoo.com'),
    (3, 'Mike', 'Johnson', 'mikejohnson');
GO

INSERT INTO forjson_nesting_vu_t_products
VALUES
    (1, 'Product A', '10.99'),
    (2, 'Product B', '19.99'),
    (3, 'Product C', '5.99');
GO

INSERT INTO forjson_nesting_vu_t_orders
VALUES
    (1, 1, 1, 2, '2023-06-25'),
    (2, 1, 2, 1, '2023-06-25'),
    (3, 2, 3, 3, '2023-06-26');
GO

-- FOR JSON PATH CLAUSE with nested json support for existing objects
CREATE VIEW forjson_nesting_vu_v_users AS
SELECT (
    SELECT Id, 
            firstname AS "Name.first",
            lastname AS "Name.last",
            email
    FROM forjson_nesting_vu_t_users
    FOR JSON PATH
) c1
GO

CREATE VIEW forjson_nesting_vu_v_products AS
SELECT (
    SELECT Id,
            name AS "Info.name",
            price AS "Info.price"
    FROM forjson_nesting_vu_t_products
    FOR JSON PATH
) c1
GO

CREATE VIEW forjson_nesting_vu_v_orders AS
SELECT (
    SELECT Id AS "Id.orderid",
            userid AS "Id.userid",
            productid AS "Id.productid",
            quantity AS "orderinfo.quantity",
            orderdate AS "orderinfo.orderdate"
    FROM forjson_nesting_vu_t_orders
    FOR JSON PATH
) c1
GO

-- FOR JSON PATH support for multiple layers of nested JSON objects
CREATE VIEW forjson_nesting_vu_v_deep AS
SELECT (
    SELECT Id,
            firstname AS "User.info.name.first",
            lastname AS "User.info.name.last"
    FROM forjson_nesting_vu_t_users
    FOR JSON PATH
) c1
GO

-- FOR JSON PATH support for multiple layers of nested JSON objects w/ join
CREATE VIEW forjson_nesting_vu_v_join_deep AS
SELECT (
    SELECT U.Id "User.id",
            O.quantity AS "User.order.info.quantity",
            O.orderdate AS "User.order.info.orderdate"
    FROM forjson_nesting_vu_t_users U
        JOIN forjson_nesting_vu_t_orders O
            ON (U.id = O.userid)
    FOR JSON PATH 
) c1
GO

-- FOR JSON PATH Support for key-values being inserted into mid layer of multi-layered JSON object
CREATE VIEW forjson_nesting_vu_v_layered_insert AS
SELECT (
    SELECT U.id,
        O.id AS "Order.Orderid",
        P.id AS "Order.Product.Productid",
        O.orderdate AS "Order.date"
    FROM forjson_nesting_vu_t_users U
        JOIN forjson_nesting_vu_t_orders O
            ON (U.id = O.userid)
        JOIN forjson_nesting_vu_t_products P
            ON (P.id = O.productid)
    FOR JSON PATH
) c1
GO

-- Error related to inserting value at Json object location
CREATE VIEW forjson_nesting_vu_v_error AS
SELECT (
    SELECT id,
            firstname AS "user.name",
            lastname AS "user.name.last"
    FROM forjson_nesting_vu_t_users
    FOR JSON PATH
)
GO

