-- BABEL-3319: Checking that alter table check constraint does not raise collation error
CREATE TABLE [dbo].[alter_table_check_constraint](
     [col1] [nvarchar](4) NULL
     )
GO
INSERT [dbo].[alter_table_check_constraint] VALUES ('abc')
GO