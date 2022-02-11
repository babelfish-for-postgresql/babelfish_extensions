USE master
GO

CREATE TABLE [dbo].[smtableint](
    [c_id] [int] NOT NULL,
    [c_d_id] [tinyint] NOT NULL,
    [c_w_id] [int] NOT NULL,
	[name1] [nvarchar(20)],
	[name2] [nvarchar(25)]
) ON [PRIMARY]
GO

INSERT INTO [dbo].[smtableint] VALUES (1, 2, 3, 'a1', 'a2'), (4, 5, 6, 'a11', 'a22'), (7, 8, 9, 'a111', 'a222')
GO

EXEC sp_describe_undeclared_parameters N'INSERT INTO [dbo].[smtableint]([c_id],[c_d_id],[c_w_id],[name1],[name2]) values (@PaRaM1,@PaRaM2,@PaRaM3,@PaRaM4,@PaRaM5)'
GO

-- cleanup
DROP TABLE [dbo].[smtableint]
GO
