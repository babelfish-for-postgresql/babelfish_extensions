DROP sequence IF EXISTS Test_Seq.test
GO

DROP sequence IF EXISTS Test_Seq.test1
GO

DROP sequence IF EXISTS Test_Seq.test2
GO

DROP sequence IF EXISTS Test_Seq.isc_sequences_seq1
GO

DROP sequence IF EXISTS Test_Seq.isc_sequences_seq2
GO

DROP sequence IF EXISTS Test_Seq.isc_sequences_seq3
GO

DROP sequence IF EXISTS Test_Seq.isc_sequences_seq4
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

create sequence Test_Seq.isc_sequences_seq1 start with 1 minvalue 1 maxvalue 5 cycle;
go

create sequence Test_Seq.isc_sequences_seq2 as tinyint start with 2 minvalue 1 maxvalue 5 cycle;
go

create sequence Test_Seq.isc_sequences_seq3 as smallint start with 3 increment by 3 minvalue 3 maxvalue 10;
go

create sequence Test_Seq.isc_sequences_seq4 as int start with 4 increment by 2 minvalue 2 maxvalue 10;
go

--DROP

DROP sequence IF EXISTS Test_Seq.test
GO

DROP sequence IF EXISTS test
GO

DROP sequence IF EXISTS Test_Seq.test1
GO

DROP sequence IF EXISTS Test_Seq.test2
GO

DROP sequence IF EXISTS Test_Seq.isc_sequences_seq1
GO

DROP sequence IF EXISTS Test_Seq.isc_sequences_seq2
GO

DROP sequence IF EXISTS Test_Seq.isc_sequences_seq3
GO

DROP sequence IF EXISTS Test_Seq.isc_sequences_seq4
GO

DROP schema IF EXISTS Test_Seq
GO


