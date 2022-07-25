USE master
GO

ALTER TABLE [babel_775_logging].[EFMIntegrationMessage]
ADD CONSTRAINT [PK_logging.EFMIntegrationMessage] PRIMARY KEY ([EFMIntegrationLogId]);
GO

ALTER TABLE [babel_775_efm].[FilingCompletion]
ADD CONSTRAINT [FK_efm.FilingCompletion_logging.EFMIntegrationMessage_EfmIntegrationLogId] FOREIGN KEY ([EfmIntegrationLogId])
REFERENCES [babel_775_logging].[EFMIntegrationMessage] ([EFMIntegrationLogId]);
GO
