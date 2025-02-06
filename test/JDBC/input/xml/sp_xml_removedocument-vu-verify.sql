-- QUERIES for different test cases for sp_xml_preparedocument and sp_xml_removedocument procedure
-- creating a handle and then removing it, 2ND execution of this will throw an error as the handle is removed by first remove procedure
DECLARE @hdoc INT; 
EXEC sp_xml_preparedocument @hdoc OUTPUT, '<root><child>value</child></root>', '<root xmlns:ns1="http://example.com/ns1"/>';
EXEC sp_xml_removedocument @hdoc;
EXEC sp_xml_removedocument @hdoc;
GO

-- Removing negative handle
DECLARE @hdoc INT= -1;
EXEC sp_xml_removedocument @hdoc;
GO

-- Removing a handle which does not exists in the session
DECLARE @hdoc INT=999999;
EXEC sp_xml_removedocument @hdoc;
GO

-- Removing a handle which is NULL;
DECLARE @hdoc INT=null;
EXEC sp_xml_removedocument @hdoc;
GO