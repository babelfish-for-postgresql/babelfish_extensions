DROP TYPE IF EXISTS test1.null_check1
Go

DROP TYPE IF EXISTS test1.null_check2
Go

DROP TYPE IF EXISTS test2.null_check1
Go

DROP TYPE IF EXISTS test2.null_check2
Go

DROP SCHEMA IF EXISTS test1
GO

DROP SCHEMA IF EXISTS test2
GO

Create schema test1
Go

Create schema test2
Go

Create type test1.null_check1 FROM varchar(11) NOT NULL ;
GO

Create type test1.null_check2 FROM int  NULL ;
GO

Create type test2.null_check1 FROM varchar(11)  NULL ;
GO

Create type test2.null_check2 FROM int  NOT NULL ;
GO
