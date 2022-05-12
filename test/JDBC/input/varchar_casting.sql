-- [BABEL-3078] Implicit casting from VARCHAR to all other datatypes

create procedure p3078 (@a date) as begin select @a; end
go
declare @a varchar(10) = '1967-10-23'
exec p3078 @a -- implicit casting from VARCHAR to DATE
go
drop procedure p3078
go

create procedure p3078 (@a TIME(3)) as begin select @a; end
go
declare @a varchar(20) = '11:34:45.1234'
exec p3078 @a -- implicit casting from VARCHAR to TIME
go
drop procedure p3078
go

create procedure p3078 (@a DATETIME) as begin select @a; end
go
declare @a varchar(30) = '1968-10-23 12:45:37.123'
exec p3078 @a -- implicit casting from VARCHAR to DATETIME
go
drop procedure p3078
go

create procedure p3078 (@a DATETIME2(3)) as begin select @a; end
go
declare @a varchar(30) = '1968-10-23 12:45:37.1234'
exec p3078 @a -- implicit casting from VARCHAR to DATETIME2
go
drop procedure p3078
go

create procedure p3078 (@a SMALLDATETIME) as begin select @a; end
go
declare @a varchar(25) = '1912-01-16 12:32'
exec p3078 @a -- implicit casting from VARCHAR to SMALLDATETIME
go
drop procedure p3078
go

create procedure p3078 (@a MONEY) as begin select @a; end
go
declare @a varchar(10) = '1111.11'
exec p3078 @a -- implicit casting from VARCHAR to MONEY 
go
drop procedure p3078
go

create procedure p3078 (@a NUMERIC(5, 2)) as begin select @a; end
go
declare @a varchar(10) = '123.45'
exec p3078 @a -- implicit casting from VARCHAR to NUMERIC 
go
drop procedure p3078
go

create procedure p3078 (@a CHAR(6)) as begin select @a; end
go
declare @a varchar(10) = 'abc'
exec p3078 @a -- implicit casting from VARCHAR to CHAR
go
drop procedure p3078
go

create procedure p3078 (@a TINYINT) as begin select @a; end
go
declare @a varchar(10) = '10'
exec p3078 @a -- implicit casting from VARCHAR to TINYINT
go
drop procedure p3078
go

create procedure p3078 (@a TEXT) as begin select @a; end
go
declare @a varchar(30) = 'utils/devanagari.txt'
exec p3078 @a -- implicit casting from VARCHAR to TEXT
go
drop procedure p3078
go

create procedure p3078 (@a UNIQUEIDENTIFIER) as begin select @a; end
go
declare @a varchar(40) = 'd424fdef-1404-4bac-8289-c725b540f93d'
exec p3078 @a -- implicit casting from VARCHAR to UNIQUEIDENTIFIER
go
drop procedure p3078
go

create procedure p3078 (@a BIT) as begin select @a; end
go
declare @a varchar(10) = '1'
exec p3078 @a -- implicit casting from VARCHAR to BIT
go
drop procedure p3078
go

create procedure p3078 (@a XML) as begin select @a; end
go
declare @a varchar(30) = 'utils/devanagari.txt'
exec p3078 @a -- implicit casting from VARCHAR to XML
go
drop procedure p3078
go
