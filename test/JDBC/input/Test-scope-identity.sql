-- Testcases for BABEL-3907, BABEL-3413
-- There exist some Identity testing already.
-- see Test-Identity (MVU and standlone), identity_function (MVU and standalone)

-- Test 1
-- Two tables with identity column. First table has a trigger to insert into second table.
-- SCOPE_IDENTITY should show identity value from first table because it is in the scope
-- while IDENTITY should show value on second table
-- This was validated against SQLServer
CREATE TABLE ScopeIdentityMainTable (
 ID int IDENTITY(1,1) NOT NULL,
 FIRSTNAME varchar(255),
 LASTNAME varchar(255),
 PRIMARY KEY (ID)
);
GO

CREATE TABLE ScopeIdentityTableUpdatedByKey (
 ID int,
 FIRSTNAME varchar(255),
 LASTNAME varchar(255),
 VALTYPE varchar(255),
 SQLIDENTITYCOL [int] IDENTITY(1,1) NOT NULL,
 FOREIGN KEY (ID) REFERENCES ScopeIdentityMainTable(ID)
);
GO

CREATE TABLE ScopeIdentityTableUpdatedByTrigger (
 ID int,
 VALTYPE varchar(255),
 SQLIDENTITYCOL [int] IDENTITY(1,1) NOT NULL
)
GO

-- Insert a value to make sure this table has a different value than MainTable
INSERT INTO ScopeIdentityTableUpdatedByTrigger (id, valtype) VALUES ( 5, 'Name');
GO

CREATE TRIGGER UpdateTableByTrigger
ON ScopeIdentityMainTable
FOR INSERT 
AS
 INSERT INTO ScopeIdentityTableUpdatedByTrigger(Id, ValType)
 SELECT Id ,'Name' FROM INSERTED;
GO

SELECT * FROM ScopeIdentityMainTable;
GO

SELECT * FROM ScopeIdentityTableUpdatedByKey;
GO

SELECT * FROM ScopeIdentityTableUpdatedByTrigger;
GO

INSERT INTO ScopeIdentityMainTable (firstname, lastname) values ('Infor', 'HMS');
GO

SELECT @@IDENTITY as [Identity]
 , SCOPE_IDENTITY() AS [Scope_Identity]
 , IDENT_CURRENT('ScopeIdentityMainTable') AS IC_MainTable 
 , IDENT_CURRENT('ScopeIdentityTableUpdatedByKey') AS IC_TableUpdatedByKey 
 , IDENT_CURRENT('ScopeIdentityTableUpdatedByTrigger') AS IC_TableUpdatedByTrigger
 , sys.babelfish_get_scope_identity() AS [BB_Scope_Identity]
GO

-- Test 2
-- Create a Stored Procedure (SP1) that calls SP2 which does an INSERT to MainTable
-- The INSERT INTO MainTable does a trigger INSERT INTO TableUpdatedByTrigger
-- This was validated against SQL Server
CREATE PROCEDURE ScopeIdentitySP2
AS
    INSERT ScopeIdentityMainTable (firstname, lastname) values ('Infor2', 'HMS2');
    SELECT MAX(id) AS MaximumUsedIdentity FROM ScopeIdentityMainTable
    SELECT SCOPE_IDENTITY()
    SELECT @@IDENTITY
    SELECT IDENT_CURRENT('ScopeIdentityMainTable')
GO

-- SCOPE_IDENTITY should be NULL because INSERT happened outside scope
CREATE PROCEDURE ScopeIdentitySP1
AS
    EXEC ScopeIdentitySP2
    SELECT MAX(id) AS MaximumUsedIdentity FROM ScopeIdentityMainTable
    SELECT SCOPE_IDENTITY()
    SELECT @@IDENTITY
    SELECT IDENT_CURRENT('ScopeIdentityMainTable')
GO

EXEC ScopeIdentitySP1
GO

SELECT @@IDENTITY as [Identity]
 , SCOPE_IDENTITY() AS [Scope_Identity]
 , IDENT_CURRENT('ScopeIdentityMainTable') AS IC_MainTable 
 , IDENT_CURRENT('ScopeIdentityTableUpdatedByKey') AS IC_TableUpdatedByKey 
 , IDENT_CURRENT('ScopeIdentityTableUpdatedByTrigger') AS IC_TableUpdatedByTrigger
 , sys.babelfish_get_scope_identity() AS [BB_Scope_Identity]
GO


-- Test 3
-- Verify scope_identity() inside sp_executesql
-- Similarly as above, the output was validated against SQL Server
CREATE FUNCTION ScopeIdentityFunc1()
RETURNS TINYINT
AS
BEGIN
RETURN SCOPE_IDENTITY()
END
GO

-- ScopeIdentityFunc1 should return NULL because insert happened outside scope
INSERT ScopeIdentityMainTable (firstname, lastname) values ('Infor3', 'HMS3');
SELECT dbo.ScopeIdentityFunc1();
GO

sp_executesql N'INSERT INTO ScopeIdentityMainTable (firstname, lastname) values (@var1, @var2);
SELECT dbo.ScopeIdentityFunc1(), @@IDENTITY as [Identity], SCOPE_IDENTITY() AS [Scope_Identity]',
N'@var1 varchar(20), @var2 varchar(20)', @var1='Infor4', @var2='HMS4';
GO

-- Test 4
-- Test SP -> sp_executesql -> trigger nesting
CREATE PROCEDURE ScopeIdentitySP3
AS
    EXEC sp_executesql N'INSERT INTO ScopeIdentityMainTable (firstname, lastname) values (@var1, @var2);
    SELECT dbo.ScopeIdentityFunc1(), @@IDENTITY as [Identity], SCOPE_IDENTITY() AS [Scope_Identity]',
    N'@var1 varchar(20), @var2 varchar(20)', @var1='Infor5', @var2='HMS5';

    SELECT MAX(id) AS MaximumUsedIdentity FROM ScopeIdentityMainTable
    SELECT SCOPE_IDENTITY()
    SELECT @@IDENTITY
    SELECT IDENT_CURRENT('ScopeIdentityMainTable')
    SELECT sys.babelfish_get_scope_identity() AS [BB_Scope_Identity]
GO

EXEC ScopeIdentitySP3
GO

SELECT @@IDENTITY as [Identity]
 , SCOPE_IDENTITY() AS [Scope_Identity]
 , IDENT_CURRENT('ScopeIdentityMainTable') AS IC_MainTable 
 , IDENT_CURRENT('ScopeIdentityTableUpdatedByKey') AS IC_TableUpdatedByKey 
 , IDENT_CURRENT('ScopeIdentityTableUpdatedByTrigger') AS IC_TableUpdatedByTrigger
 , sys.babelfish_get_scope_identity() AS [BB_Scope_Identity]
GO


DROP FUNCTION ScopeIdentityFunc1
GO

DROP PROCEDURE ScopeIdentitySP1
GO

DROP PROCEDURE ScopeIdentitySP2
GO

DROP PROCEDURE ScopeIdentitySP3
GO

DROP TRIGGER UpdateTableByTrigger
GO

DROP TABLE ScopeIdentityTableUpdatedByTrigger
GO

DROP TABLE ScopeIdentityTableUpdatedByKey
GO

DROP TABLE ScopeIdentityMainTable
GO

