INSERT INTO babel_2884_vu_prepare_persons
(PersonName, PersonLastName )
VALUES
(N'Salvador', N'Williams'),
(N'Lawrence', N'Brown'),
( N'Gilbert', N'Jones'),
( N'Ernest', N'Smith'),
( N'Jorge', N'Johnson')
 
GO
INSERT INTO babel_2884_vu_prepare_addressList
(PersonId, PostCode, City)
VALUES
(1, N'07145', N'Philadelphia'),
(2, N'68443', N'New York'),
(3, N'50675', N'Phoenix'),
(4, N'96573', N'Chicago')
GO

UPDATE babel_2884_vu_prepare_mytest SET Name = 'x' WHERE Id = 1
go
--UPDATE Persons SET Persons.PersonCityName = 'ddd' where PersonId = 1;
--go