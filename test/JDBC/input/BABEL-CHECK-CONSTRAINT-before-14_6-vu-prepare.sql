CREATE TABLE [dbo].[alter_table_check_constraint](
     [col1] [nvarchar](4) NULL
     )
GO
INSERT [dbo].[alter_table_check_constraint] VALUES ('abc')
GO

ALTER TABLE [dbo].[alter_table_check_constraint] ADD CONSTRAINT [check_col1] CHECK ([col1] like N'%TP')
GO
