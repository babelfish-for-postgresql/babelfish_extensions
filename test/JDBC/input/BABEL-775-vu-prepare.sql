USE master
go

create schema babel_775_logging
go

create schema babel_775_efm
go

CREATE TABLE [babel_775_logging].[EFMIntegrationMessage](
[EFMIntegrationLogId] int IDENTITY(1, 1) NOT NULL
)
ON [PRIMARY];
GO

CREATE TABLE [babel_775_efm].[FilingCompletion](
[FilingCompletionId] int IDENTITY(1, 1) NOT NULL,
[EfmIntegrationLogId] int NULL
)
ON [PRIMARY];
GO