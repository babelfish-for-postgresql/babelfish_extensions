CREATE DATABASE ad_db;
GO

CREATE LOGIN [ad\Aduser] from windows;
GO

CREATE LOGIN [ad\Aduserdb] from windows with default_database=[ad_db];
GO

CREATE LOGIN [ad\Aduserlanguage] from windows with default_language=[German];
GO

CREATE LOGIN [ad\Aduserdblanguage] from windows with default_database=[ad_db], default_language=[German];
GO

CREATE LOGIN [ad\AduserdblanguageEnglish] from windows with default_database=[ad_db], default_language=[English];
GO

CREATE LOGIN [ad\Aduseroption] from windows with CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;
GO

