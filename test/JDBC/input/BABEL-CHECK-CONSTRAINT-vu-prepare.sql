-- BABEL-3319: Checking that alter table check constraint does not raise collation error
CREATE TABLE [dbo].[alter_table_check_constraint](
     [col1] [nvarchar](4) NULL
     )
GO
INSERT [dbo].[alter_table_check_constraint] VALUES ('abc')
GO

CREATE TABLE check_constraint (
     a varchar(100) COLLATE sql_latin1_general_cp1_ci_as
)
GO
INSERT INTO check_constraint VALUES
     ('Hello how are you'), ('Goodbye, John')
GO

CREATE TABLE create_check_constraint(
     a char(20) COLLATE sql_latin1_general_cp1_ci_as, 
     CHECK (NOT a LIKE '11%')
)
GO
