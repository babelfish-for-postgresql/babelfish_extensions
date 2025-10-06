
-- QUERIES for different test cases for sp_xml_preparedocument and sp_xml_removedocument procedure
-- When 1st (xmltext) and  2nd (xpath namespaces) parameters  are not given
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- When xmltext is NULL and namespace is not given 
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, NULL;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- When xmltext is a valid xml and namespace is not given
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, '<root><child>value</child></root>';
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- When xmltext is invalid and namespaces is not given
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, '<root><child></root';
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- When xmltext and namespaces both are given (valid)
DECLARE @hdoc INT; 
EXEC sp_xml_preparedocument @hdoc OUTPUT, '<root><child>value</child></root>', '<root xmlns:ns1="http://example.com/ns1"/>';
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- When xmltext and namespaces both are given (invalid)
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, '<root><child></root', 'xmlns:ns1="http://example.com/ns1"/>';
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- When xmltext is valid but namespace invalid
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, '<root><child>value</child></root>', 'xmlns:ns1="http://example.com/ns1"/>';
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

--When xmltext is invalid but namespace valid
DECLARE @hdoc INT;  
EXEC sp_xml_preparedocument @hdoc OUTPUT, '<root><child></root', '<root xmlns:ns1="http://example.com/ns1"/>';
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- When xmltext is NULL and valid namespace
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, NULL, '<root xmlns:ns1="http://example.com/ns1"/>';
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- When xmltext is NULL and invalid namespace
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, NULL, 'xmlns:ns1="http://example.com/ns1"/>'; 
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- When empty xml text is given
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT,'', '<root xmlns:ns1="http://example.com/ns1"/>';
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- When empty namespace is given
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, '<root><child>value</child></root>', '';
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- When both xmltext and namespace are empty
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT,'', '';
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- When large handle is given
DECLARE @hdoc INT;
DECLARE @counter BIGINT = 1; 
WHILE @counter <= 2000
BEGIN 
EXEC sp_xml_preparedocument @hdoc OUTPUT;
SET @counter = @counter + 1;
END;
SELECT @hdoc as handle;
GO

--When database is changed in the session
SELECT db_name() as current_database;
GO

DECLARE @handle1 int;
EXEC sp_xml_preparedocument @handle1 OUTPUT, '<root><test>data</test></root>';
SELECT @handle1 as 'Current Handle';
INSERT INTO sp_xml_preparedocument_HandleStore (handle_value) VALUES (@handle1);
GO

USE sp_xml_preparedocument_temp_db;
GO

DECLARE @handle2 int;
SELECT @handle2 = handle_value FROM master.dbo.sp_xml_preparedocument_HandleStore;
SELECT @handle2 as 'Retrieved Handle';
BEGIN TRY
    EXEC sp_xml_removedocument @handle2;
    PRINT 'Document successfully removed using handle from previous database';
END TRY
BEGIN CATCH
    PRINT 'Error' ;
END CATCH;
GO

USE master
GO


-- Variable declaration and initialisation
DECLARE @hdoc INT;
DECLARE @xml_text varchar(100) = '<root/>';
DECLARE @xpath_namespaces varchar(100) = '<root xmlns:ns1="http://example.com/ns1"/>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_text, @xpath_namespaces;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

--For complex xml texts 1
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, 
'<organization>
    <department id="D1">
        <name>IT</name>
        <employees>
            <employee id="E1">
                <name>John Doe</name>
                <title>Developer</title>
                <skills>
                    <skill level="expert">SQL</skill>
                    <skill level="intermediate">Java</skill>
                </skills>
            </employee>
        </employees>
    </department>
</organization>';
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- For complex xml text2
DECLARE @hdoc INT;
DECLARE @doc VARCHAR(1000);
SET @doc = '
<ROOT>
<Customer CustomerID="VINET" ContactName="Paul Henriot">
   <Order CustomerID="VINET" EmployeeID="5" OrderDate="1996-07-04T00:00:00">
      <OrderDetail OrderID="10248" ProductID="11" Quantity="12"/>
      <OrderDetail OrderID="10248" ProductID="42" Quantity="10"/>
   </Order>
</Customer>
<Customer CustomerID="LILAS" ContactName="Carlos Gonzlez">
   <Order CustomerID="LILAS" EmployeeID="3" OrderDate="1996-08-16T00:00:00">
      <OrderDetail OrderID="10283" ProductID="72" Quantity="3"/>
   </Order>
</Customer>
</ROOT>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @doc;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- For complex namespaces
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, '',
'<root 
    xmlns:ns1="http://example.com/ns1" 
    xmlns:ns2="http://example.com/ns2" 
    xmlns:ns3="http://example.com/ns3">
    <ns1:element>
        <ns2:subelement>
            <ns3:data>value</ns3:data>
        </ns2:subelement>
    </ns1:element>
</root>';
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

--When given xml text length is too large (above max limit)
DECLARE @hdoc int;
DECLARE @xml_text varchar(max) = '<root>' + repeat('<child></child>', 200000000) + '</root>';
EXEC sp_xml_preparedocument @hdoc output, @xml_text;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- When namespace length is too large (above max limit)
DECLARE @hdoc int;
DECLARE @namespace_text varchar(max) = '<root ' + repeat('xmlns:ns1="http://example.com/namespace/1" ', 200000000) + '><element/></root>';
EXEC sp_xml_preparedocument @hdoc output, NULL, @namespace_text;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

--Test with parameter by name syntax 1
DECLARE @z int;
EXEC sp_xml_preparedocument @hdoc = @z OUTPUT, @xmltext = '<root><child>value</child></root>', @xpath_namespaces = '';
SELECT @z as handle;
EXEC sp_xml_removedocument @z;
GO

--Test with parameter by name syntax 2
DECLARE @z int;
DECLARE @hdoc int;
EXEC sp_xml_preparedocument @hdoc OUTPUT, 
                           @xmltext = '<root><child>value</child></root>', 
                           @xpath_namespaces = '';
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Double quoted string 
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, "<root><child>value</child></root>";
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Impact of rollback on prepared handle
BEGIN TRANSACTION;
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, '<root><child>rollback_test</child></root>';
SELECT @hdoc AS handle_before_rollback;
ROLLBACK TRANSACTION;
-- Handle will be invalid after rollback
EXEC sp_xml_removedocument @hdoc;
GO

-- Impact of statement terminating/transaction abort errors
BEGIN TRANSACTION;
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, '<root><child>txn_value</child></root>';
SELECT @hdoc AS handle_before_error;
GO
-- This will cause an error and abort the transaction
SELECT FROM;
GO

-- Verify handle still works or not
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, '<root><child>txn_value</child></root>';
SELECT @hdoc AS handle_after_error;
-- calculating handle_before_error and that should not exist
DECLARE @stored_hdoc INT = @hdoc - 2;
EXEC sp_xml_removedocument @stored_hdoc;
GO

-- Test with large XML documents
DECLARE @hdoc int;
DECLARE @xml_text varchar(max) = '<root>' + repeat('<child></child>', 20000) + '</root>';
EXEC sp_xml_preparedocument @hdoc output, @xml_text;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test with very large XML documents
DECLARE @hdoc int;
DECLARE @xml_text varchar(max) = '<root>' + repeat('<child></child>', 200000) + '</root>';
EXEC sp_xml_preparedocument @hdoc output, @xml_text;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- impact of reset connection
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, '<root><child>value</child></root>';
SELECT @hdoc as handle;
INSERT INTO handle_store VALUES (@hdoc);
-- This resets the connection
EXEC sys.sp_reset_connection;
GO
-- Handle will be invalid after reset
DECLARE @stored_hdoc INT;
SELECT @stored_hdoc = handle_id FROM handle_store;
EXEC sp_xml_removedocument @stored_hdoc;
GO

-- Now handles will start from 1
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, '<root><child>value</child></root>';
SELECT @hdoc as handle;
GO

-- Prepare/drop XML inside procedure
-- Execute procedure and verify handle
EXEC test_xml_proc;
GO
