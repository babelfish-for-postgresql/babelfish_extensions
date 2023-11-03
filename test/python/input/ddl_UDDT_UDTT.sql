DROP TYPE IF EXISTS test1
GO
DROP TYPE IF EXISTS test2
GO
DROP TYPE IF EXISTS test4
GO
DROP TYPE IF EXISTS LocationTableType
GO
DROP TYPE IF EXISTS InventoryItem
GO
DROP TYPE IF EXISTS shc_test.LocationTableType
GO
DROP TABLE IF EXISTS t_udd
GO
DROP TYPE IF EXISTS shc_test.test3
GO
DROP SCHEMA IF EXISTS shc_test
GO

CREATE TYPE test1 FROM varchar(11) NOT NULL ;
GO

CREATE TYPE test2 FROM int NULL ;
GO

CREATE SCHEMA shc_test
GO

Create type shc_test.test3 FROM int NOT NULL ;
GO

Create type test4 from numeric(15,4)
GO

create table t_udd( a shc_test.test3);
go

CREATE TYPE LocationTableType AS TABLE   
    ( LocationName VARCHAR(50)  
    , CostRate INT );  
GO

CREATE TYPE InventoryItem AS TABLE
(
    [Name] NVARCHAR(50) NOT NULL,
    SupplierId BIGINT NOT NULL,
    Price DECIMAL (18, 4) NULL,
    PRIMARY KEY (
        Name
    )
)
GO

CREATE TYPE shc_test.LocationTableType AS TABLE   
    ( LocationName VARCHAR(50)  
    , CostRate INT );  
GO

--DROP
DROP TYPE IF EXISTS test1
GO
DROP TYPE IF EXISTS test2
GO
DROP TYPE IF EXISTS test4
GO
DROP TYPE IF EXISTS LocationTableType
GO
DROP TYPE IF EXISTS InventoryItem
GO
DROP TYPE IF EXISTS shc_test.LocationTableType
GO
DROP TABLE IF EXISTS t_udd
GO
DROP TYPE IF EXISTS shc_test.test3
GO
DROP SCHEMA IF EXISTS shc_test
GO

