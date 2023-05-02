use master
go

CREATE DATABASE errdb
GO

USE errdb
GO

CREATE SCHEMA Purchasing;
GO

CREATE TYPE NameType FROM varchar(50);
GO

CREATE TABLE Purchasing.Vendor(VendorName NameType)
GO

CREATE TRIGGER dVendor ON Purchasing.Vendor
FOR DELETE AS
BEGIN
RETURN;
END;
GO

USE master
go

DROP DATABASE errdb
go

