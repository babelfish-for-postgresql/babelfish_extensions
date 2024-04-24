CREATE TABLE forjson_auto_vu_t_users ([Id] int, [firstname] varchar(50), [lastname] varchar(50), [email] varchar(50));
CREATE TABLE forjson_auto_vu_t_orders ([Id] int, [userid] int, [productid] int, [quantity] int, [orderdate] Date);

INSERT INTO forjson_auto_vu_t_users VALUES (1, 'j', 'o', 'testemail'), (1, 'e', 'l', 'testemail2');
INSERT INTO forjson_auto_vu_t_orders VALUES (1, 1, 1, 5, '2023-06-25'), (2, 1, 1, 6, '2023-06-25');
GO

CREATE PROCEDURE p1 
AS
    select * from forjson_auto_vu_t_users
GO

exec p1
go

ALTER PROCEDURE p1
AS
    select * from forjson_auto_vu_t_orders
GO

exec p1
go

ALTER PROCEDURE p1
    @param INT
AS
    IF (@param = 1)
    BEGIN
        select * from forjson_auto_vu_t_users
    END

    ELSE
    BEGIN
        select * from forjson_auto_vu_t_orders
    END
GO

exec p1 @param = 1
GO

exec p1 @param = 2
GO

DROP PROCEDURE p1
GO

DROP TABLE forjson_auto_vu_t_users
DROP TABLE forjson_auto_vu_t_orders
GO
