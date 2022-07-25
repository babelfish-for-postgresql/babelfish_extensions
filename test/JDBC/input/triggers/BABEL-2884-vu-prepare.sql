CREATE TABLE babel_2884_vu_prepare_mytest
(
Id int NOT NULL,
Name varchar (100) NOT NULL,
UpdateDateTime datetime NULL
)
go

CREATE TRIGGER babel_2884_vu_prepare_mytrig
ON babel_2884_vu_prepare_mytest
FOR UPDATE
AS
begin
UPDATE babel_2884_vu_prepare_mytest
SET Name = 'updated'
FROM inserted where inserted.Id = babel_2884_vu_prepare_mytest.Id;
end;
go

CREATE TABLE babel_2884_vu_prepare_persons
( PersonId       INT
  PRIMARY KEY IDENTITY(1, 1) NOT NULL, 
  PersonName     VARCHAR(100) NULL, 
  PersonLastName VARCHAR(100) NULL, 
  PersonPostCode VARCHAR(100) NULL, 
  PersonCityName VARCHAR(100) NULL)
 
GO

CREATE TRIGGER babel_2884_vu_prepare_mypersontrig
ON babel_2884_vu_prepare_persons
FOR UPDATE
AS
begin
UPDATE babel_2884_vu_prepare_persons SET  babel_2884_vu_prepare_persons.PersonCityName='updated' from Inserted  where Persons.PersonId = inserted.PersonId
end;
go

 
CREATE TABLE  babel_2884_vu_prepare_addressList(
  [AddressId] [int]  PRIMARY KEY IDENTITY(1,1) NOT NULL,
  [PersonId] [int] NULL,
  [PostCode] [varchar](100) NULL,
  [City] [varchar](100) NULL)
 
GO
 
