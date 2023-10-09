DROP sequence IF EXISTS Test_Seq.test
GO

DROP sequence IF EXISTS Test_Seq.test1
GO

DROP sequence IF EXISTS test
GO

DROP schema IF EXISTS Test_Seq
GO


Create sequence test
go

Create schema Test_Seq
GO

CREATE SEQUENCE Test_Seq.test START WITH 1 INCREMENT BY 1 ;
GO

CREATE SEQUENCE Test_Seq.test1 START WITH 5 INCREMENT BY 5 ;  
GO

CREATE SEQUENCE Test_Seq.test2 START WITH 24329 INCREMENT BY 1 ;  
GO

--DROP

DROP sequence IF EXISTS Test_Seq.test
GO

DROP sequence IF EXISTS test
GO

DROP sequence IF EXISTS Test_Seq.test1
GO

DROP sequence IF EXISTS Test_Seq.test2
GO

DROP schema IF EXISTS Test_Seq
GO


