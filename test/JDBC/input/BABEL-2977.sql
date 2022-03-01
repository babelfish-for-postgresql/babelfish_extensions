create login alreadyexists with password='12345678';
GO

create login alreadyexists with password='12345678';
GO

drop login nosuchlogin;
GO

alter login nosuchlogin with default_database=mydb;
GO

DROP login alreadyexists;
GO
