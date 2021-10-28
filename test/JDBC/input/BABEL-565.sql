CREATE TABLE AccountsReceivable (
 Id int IDENTITY(1,1) NOT NULL,
 ApplicationId int NOT NULL
) ON [PRIMARY]
GO

drop table AccountsReceivable
GO

-- test TEXTIMAGE_ON
CREATE TABLE AccountsReceivable (
 Id int IDENTITY(1,1) NOT NULL,
 ApplicationId int NOT NULL
) TEXTIMAGE_ON [PRIMARY]
GO

drop table AccountsReceivable
GO

-- test on primary with TEXTIMAGE_ON
CREATE TABLE AccountsReceivable (
 Id int IDENTITY(1,1) NOT NULL,
 ApplicationId int NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

drop table AccountsReceivable
GO

CREATE TABLE AccountsReceivable (
 Id int IDENTITY(1,1) NOT NULL,
 ApplicationId int NOT NULL
) TEXTIMAGE_ON [PRIMARY] ON [PRIMARY]
GO

drop table AccountsReceivable
GO
