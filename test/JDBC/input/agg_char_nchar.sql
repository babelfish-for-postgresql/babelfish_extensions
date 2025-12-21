CREATE TABLE SalesData (Product NCHAR(50), Product_1 char(20), Sales INT);
GO

INSERT INTO SalesData (Product, Product_1, Sales) VALUES ('Apple', '2023', 100), ('Orange', '2023', 150), ('Apple', '2024', 120), ('Orange', '2025', 130);
go

select min(Product) as Product from SalesData;
go

select max(Product) as Product from SalesData;
go

select min(Product_1) as Product from SalesData;
go

select max(Product_1) as Product from SalesData;
go

drop TABLE SalesData
go