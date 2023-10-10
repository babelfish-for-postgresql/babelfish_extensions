/* This test files will check for scripting views only */
DROP USER IF EXISTS test_usr1
GO
DROP USER IF EXISTS test_usr2
GO
DROP USER IF EXISTS test_usr3
GO

CREATE LOGIN test_pwd1   
    WITH PASSWORD = '340$Uuxwp7Mcxo7Khy'; 
	
CREATE LOGIN test_pwd2   
    WITH PASSWORD = '340$UuxwpMcxo7Khy';  

CREATE LOGIN test_pwd3   
    WITH PASSWORD = '340$Uuxwp7Mco7Khy'; 
	


CREATE USER test_usr1 FOR LOGIN test_pwd1;  
GO

CREATE USER test_usr2 FOR LOGIN test_pwd2;  
GO

CREATE USER test_usr3 FOR LOGIN test_pwd3;  
GO

--DROP
DROP LOGIN  test_pwd1
GO
DROP LOGIN  test_pwd2
GO
DROP LOGIN  test_pwd3
GO
DROP USER IF EXISTS test_usr1
GO
DROP USER IF EXISTS test_usr2
GO
DROP USER IF EXISTS test_usr3
GO