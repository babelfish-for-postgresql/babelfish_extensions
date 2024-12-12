CREATE TABLE dbo.performancetable (
 id int NOT NULL,
 col21 xml NULL,
 CONSTRAINT PK__gen_tabl__3213E83FCC22F19F PRIMARY KEY (id)
);
GO

exec sp_describe_undeclared_parameters
 N'UPDATE [dbo].[performancetable] SET [col21]=@P1 WHERE [id]=@P2';
GO

exec sp_describe_undeclared_parameters
 N'DELETE [dbo].[performancetable] WHERE [id]=@P1';
GO

CREATE TABLE BABEL_3156(
a int,
b nvarchar,
c xml, 
d datetime,
e money,
f varbinary);
GO

exec sp_describe_undeclared_parameters 
    N'UPDATE BABEL_3156 SET a=@P1 WHERE B=@P2';
GO

exec sp_describe_undeclared_parameters 
    N'UPDATE BABEL_3156 SET a=@P1, b=@P2 WHERE c=@P3';
GO

exec sp_describe_undeclared_parameters 
    N'UPDATE BABEL_3156 SET a=@P1, b=@P2, c=@P3, d=@P4, e=@P5 WHERE f=@P6';
GO

exec sp_describe_undeclared_parameters 
    N'UPDATE BABEL_3156 SET a=@P1, b=@P2 WHERE c=@P3 AND d=@P4';
GO

exec sp_describe_undeclared_parameters 
    N'UPDATE BABEL_3156 SET a=@P1, b=@P2 WHERE c=@P3 AND d=@P4 AND e=@P5 AND f=@P6';
GO

exec sp_describe_undeclared_parameters 
    N'DELETE FROM BABEL_3156 WHERE a=@P1';
GO

exec sp_describe_undeclared_parameters 
    N'DELETE FROM BABEL_3156 WHERE a=@P1 AND b=@P2 AND c=@P3 AND d=@P4 AND e=@P5 AND f=@P6';
GO

exec sp_describe_undeclared_parameters
    N'UPDATE BABEL_3156 SET not_a_col=@P1';
GO

exec sp_describe_undeclared_parameters
    N'UPDATE BABEL_3156 SET a=@P1 WHERE not_a_col=@P2';
GO

DROP TABLE BABEL_3156;
GO
DROP TABLE dbo.performancetable;
GO
