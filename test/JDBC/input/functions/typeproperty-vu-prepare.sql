Create schema typeproperty_test1
Go

Create schema typeproperty_test2
Go

Create type typeproperty_test1.null_check1 FROM varchar(11) NOT NULL ;
GO

Create type typeproperty_test1.null_check2 FROM int  NULL ;
GO

Create type typeproperty_test2.null_check1 FROM varchar(11)  NULL ;
GO

Create type typeproperty_test2.null_check2 FROM int  NOT NULL ;
GO
