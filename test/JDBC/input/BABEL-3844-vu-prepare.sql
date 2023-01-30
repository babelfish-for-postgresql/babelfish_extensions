-- positive test case for windows login
create login [babel\aduser] from windows;
GO

create user [babel\aduser] for login [babel\aduser];
GO

-- case when login name is not provied
create login [babel\aduser2] from windows;
GO

create user [babel\aduser2];
GO

-- case when login name is not provied and user name is not same as login name
create login [babel\aduser3] from windows;
GO

create user [abc];
GO

create user [abc] for login [babel\aduser3];
GO

-- similar test for password based login
create login pass with password='123';
GO
 -- should throw error as user abc already exists in the same db
create user [abc] for login pass;
GO

create user pass;
GO

-- create a new database and test there
create database testdb;
GO

use testdb;
GO

-- test for multiple users for a single login in different db
create user [babel\aduser] for login [babel\aduser];
GO

-- test for multiple users for a single login in different db
create user test_user for login [babel\aduser];
GO

-- test for user in different database
create login [babel\testuser] from windows;
GO

create user [babel\testuser];
GO

use master;
GO

-- test for role
create role test_role;
GO

-- should throw error
create role [test\role];
GO