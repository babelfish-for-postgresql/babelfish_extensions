ALTER TABLE [dbo].[alter_table_check_constraint] ADD CONSTRAINT [check_col1] CHECK ([col1] like N'%TP')
GO

ALTER TABLE check_constraint ADD CONSTRAINT [check_a] CHECK (a not like N'123%')
GO

INSERT INTO check_constraint VALUES ('1243')
GO

INSERT INTO check_constraint VALUES ('1234'), ('123123')
GO

INSERT INTO create_check_constraint VALUES ('abcdEFg')
GO
    
INSERT INTO create_check_constraint VALUES ('11E')
GO