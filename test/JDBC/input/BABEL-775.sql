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

ALTER TABLE [babel_775_logging].[EFMIntegrationMessage]
ADD CONSTRAINT [PK_logging.EFMIntegrationMessage] PRIMARY KEY ([EFMIntegrationLogId]);
GO

CREATE TABLE [babel_775_efm].[FilingCompletion](
[FilingCompletionId] int IDENTITY(1, 1) NOT NULL,
[EfmIntegrationLogId] int NULL
)
ON [PRIMARY];
GO

ALTER TABLE [babel_775_efm].[FilingCompletion]
ADD CONSTRAINT [FK_efm.FilingCompletion_logging.EFMIntegrationMessage_EfmIntegrationLogId] FOREIGN KEY ([EfmIntegrationLogId])
REFERENCES [babel_775_logging].[EFMIntegrationMessage] ([EFMIntegrationLogId]);
GO

DROP TABLE [babel_775_efm].[FilingCompletion]
GO

DROP SCHEMA babel_775_efm
go

DROP TABLE [babel_775_logging].[EFMIntegrationMessage]
GO

DROP SCHEMA babel_775_logging
go
