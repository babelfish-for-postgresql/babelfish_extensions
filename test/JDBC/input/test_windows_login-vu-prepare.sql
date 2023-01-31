CREATE DATABASE ad_db;
GO

CREATE LOGIN PassWordUser with PASSWORD='123';
GO

-- positive test case
CREATE LOGIN [ad\Aduser] from windows;
GO

-- test for default database
CREATE LOGIN [ad\Aduserdb] from windows with default_database=[ad_db];
GO

-- test for default language
CREATE LOGIN [ad\Aduserlanguage] from windows with default_language=[German];
GO

-- test for default database and default language
CREATE LOGIN [ad\Aduserdblanguage] from windows with default_database=[ad_db], default_language=[German];
GO

CREATE LOGIN [ad\AduserdbEnglish] from windows with default_database=[ad_db], default_language=[English];
GO

-- test for invalid options for windows
CREATE LOGIN [ad\Aduseroption] from windows with CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;
GO

-- test boundary conditions

-- test for when the login_name is greater than 21 characters
create login [babel\aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa] from windows;
GO

-- test for when the login_name length is 0
CREATE LOGIN [babel\] from windows;
GO

--test for when the total login name, i.e., domain+user is greater than 64
CREATE LOGIN [babelforapg.individualad.testfornumberofcharactersintotalwhichisnotallowedinpostgres\user] from windows;
GO

-- test for when the login_name contains invalid characters
CREATE LOGIN [babeluser] from windows;
GO
CREATE LOGIN [babel\user\] from windows;
GO
CREATE LOGIN [babel\us\er] from windows;
GO
CREATE LOGIN [babel\user/] from windows;
GO
CREATE LOGIN [babel\us/er] from windows;
GO
CREATE LOGIN [babel\user[] from windows;
GO
CREATE LOGIN [babel\u[ser] from windows;
GO
CREATE LOGIN [babel\use]r] from windows;
GO
CREATE LOGIN [babel\user;] from windows;
GO
CREATE LOGIN [babel\us;er] from windows;
GO
CREATE LOGIN [babel\user:] from windows;
GO
CREATE LOGIN [babel\us:er] from windows;
GO
CREATE LOGIN [babel\user|] from windows;
GO
CREATE LOGIN [babel\use|r] from windows;
GO
CREATE LOGIN [babel\user=] from windows;
GO
CREATE LOGIN [babel\u=ser] from windows;
GO
CREATE LOGIN [babel\user,] from windows;
GO
CREATE LOGIN [babel\us,er] from windows;
GO
CREATE LOGIN [babel\user+] from windows;
GO
CREATE LOGIN [babel\u+ser] from windows;
GO
CREATE LOGIN [babel\user*] from windows;
GO
CREATE LOGIN [babel\user*] from windows;
GO
CREATE LOGIN [babel\user?] from windows;
GO
CREATE LOGIN [babel\us?er] from windows;
GO
CREATE LOGIN [babel\user>] from windows;
GO
CREATE LOGIN [babel\u>ser] from windows;
GO
CREATE LOGIN [babel\user<] from windows;
GO
CREATE LOGIN [babel\us<er] from windows;
GO
CREATE LOGIN [babel\user@] from windows;
GO
CREATE LOGIN [babel\us@er] from windows;
GO
CREATE LOGIN [babel\us\er@] from windows;
GO
CREATE LOGIN [babel\us<>er] from windows;
GO

-- test to show UPN format is not allowed
CREATE LOGIN [user@BABEL] from windows;
GO

-- test for duplicate login
CREATE LOGIN usErpassWord with PASSWORD = '123';
GO

CREATE LOGIN UserPassword with PASSWORD = '098'; 
GO

CREATE LOGIN [babel\duplicate] from windows;
GO

CREATE LOGIN [BabeL\DupLicate] from windows;
GO

CREATE LOGIN [babel\duplicatedefaultdb] from windows with default_database=[master];
GO

CREATE LOGIN [Babel\DuplicateDefaultDB] from windows with default_database=[ad_db];
GO

-- test for empty domain name
CREATE LOGIN [\adnodomain] from windows;
GO


-- test for login names with different language
-- Arabic
CREATE LOGIN [babel\كلب] from windows;
GO

-- Mongolian
CREATE LOGIN [babel\өглөө] from windows;
GO

-- Greek
CREATE LOGIN [babel\ελπίδα] from windows;
GO

-- Chinese
CREATE LOGIN [babel\爱] from windows;
GO

-- test for windows login with password --> should throw error
CREATE LOGIN [babel\adbabel] from windows with password='1234';
GO
