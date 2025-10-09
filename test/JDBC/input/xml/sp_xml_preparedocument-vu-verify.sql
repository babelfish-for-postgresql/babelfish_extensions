
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

-- Test cases for sp_xml_preparedocument with different data types
-- Testing TEXT, NTEXT, CHAR, NCHAR, VARCHAR, NVARCHAR, XML and UDTs

-- Test 1: XML datatype variable
DECLARE @hdoc INT;
DECLARE @xml XML = '<root><child>value</child></root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 2: VARCHAR datatype variable
DECLARE @hdoc INT;
DECLARE @xml VARCHAR(100) = '<root><child>value</child></root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO


-- Test 3: NVARCHAR datatype variable
DECLARE @hdoc INT;
DECLARE @xml NVARCHAR(100) = N'<root><child>value</child></root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 4: CHAR datatype variable
DECLARE @hdoc INT;
DECLARE @xml CHAR(100) = '<root><child>value</child></root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 5: NCHAR datatype variable
DECLARE @hdoc INT;
DECLARE @xml NCHAR(100) = N'<root><child>value</child></root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 6: TEXT datatype variable
DECLARE @hdoc INT;
DECLARE @xml TEXT = '<root><child>value</child></root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

DECLARE @hdoc INT;
DECLARE @xml_content VARCHAR(MAX);
SELECT @xml_content = CAST(xml_data AS VARCHAR(MAX)) FROM TestTextXML_babel_1168 WHERE id = 1; 
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_content;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 7: NTEXT datatype variable
DECLARE @hdoc INT;
DECLARE @xml NTEXT = N'<root><child>value</child></root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

DECLARE @hdoc INT;
DECLARE @xml_content NVARCHAR(MAX);
SELECT @xml_content = CAST(xml_data AS NVARCHAR(MAX)) FROM TestNTextXML_babel_1168 WHERE id = 1;
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_content;
SELECT @hdoc as handle ;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 8: Malformed XML with VARCHAR
DECLARE @hdoc INT;
DECLARE @xml VARCHAR(100) = '<root><child></root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 9: Malformed XML with NVARCHAR
DECLARE @hdoc INT;
DECLARE @xml NVARCHAR(100) = N'<root><child></root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 10: Malformed XML with XML datatype
DECLARE @hdoc INT;
DECLARE @xml XML = '<root><child></root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 11: NULL XML with different datatypes
DECLARE @hdoc INT;
DECLARE @xml VARCHAR(100) = NULL;
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

DECLARE @hdoc INT;
DECLARE @xml XML = NULL;
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 12: Empty string with different datatypes
DECLARE @hdoc INT;
DECLARE @xml VARCHAR(100) = '';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

DECLARE @hdoc INT;
DECLARE @xml NVARCHAR(100) = N'';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 13: Complex XML with Unicode characters
DECLARE @hdoc INT;
DECLARE @xml NVARCHAR(200) = N'<root><child name="测试">Hello 🌍</child><item>世界</item></root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 14: XML with namespaces
DECLARE @hdoc INT;
DECLARE @xml NVARCHAR(200) = N'<root xmlns:ns="http://example.com"><ns:child>value</ns:child></root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 15: Large XML content
DECLARE @hdoc INT;
DECLARE @xml NVARCHAR(MAX) = N'<root>' + REPLICATE(N'<item>data</item>', 100) + N'</root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 16: Direct string literals (no variables)
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, '<root><child>direct</child></root>';
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, N'<root><child>direct</child></root>';
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 17: XML with CDATA sections
DECLARE @hdoc INT;
DECLARE @xml NVARCHAR(200) = N'<root><![CDATA[<script>alert("test")</script>]]></root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 18: XML with special characters
DECLARE @hdoc INT;
DECLARE @xml NVARCHAR(200) = N'<root attr="&lt;&gt;&amp;&quot;&apos;">Special &amp; chars</root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 19: Multiple nested levels
DECLARE @hdoc INT;
DECLARE @xml NVARCHAR(300) = N'<root><level1><level2><level3><level4>deep</level4></level3></level2></level1></root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 20: XML with processing instructions and comments
DECLARE @hdoc INT;
DECLARE @xml NVARCHAR(200) = N'<?xml version="1.0"?><!-- comment --><root>data</root>';
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
SELECT @hdoc as handle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Basic Tests with different dataype UDTs
EXEC TestXMLPrepareDocument_Char
GO

EXEC TestXMLPrepareDocument_Varchar
GO

EXEC TestXMLPrepareDocument_NChar
GO

EXEC TestXMLPrepareDocument_NVarchar
GO

EXEC TestXMLPrepareDocument_Text
GO

EXEC TestXMLPrepareDocument_NText
GO

-- Test execution for view-based XML processing
EXEC ProcessXMLFromView_babel_1168 1
GO

-- Test table-valued function
SELECT * FROM GetXMLByType_babel_1168('Data')
GO

-- Test views directly
SELECT * FROM XMLDataView_babel_1168
GO

SELECT * FROM NVarcharXMLView_babel_1168
GO

-- EXPLICIT CASTING AND CONVERTING TESTS
-- Test 1: CAST VARCHAR to different types
DECLARE @hdoc INT;
DECLARE @xml_varchar VARCHAR(100) = '<root><item>test</item></root>';
DECLARE @xml_casted VARCHAR(MAX) = CAST(@xml_varchar AS VARCHAR(MAX));
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_casted;
SELECT @hdoc as CastVarcharToVarcharMax;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 2: CAST NVARCHAR to VARCHAR
DECLARE @hdoc INT;
DECLARE @xml_nvarchar NVARCHAR(100) = N'<root><item>Unicode 世界</item></root>';
DECLARE @xml_casted VARCHAR(MAX) = CAST(@xml_nvarchar AS VARCHAR(MAX));
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_casted;
SELECT @hdoc as CastNVarcharToVarchar;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 3: CAST CHAR to VARCHAR
DECLARE @hdoc INT;
DECLARE @xml_char CHAR(50) = '<root><item>char</item></root>';
DECLARE @xml_casted VARCHAR(100) = CAST(@xml_char AS VARCHAR(100));
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_casted;
SELECT @hdoc as CastCharToVarchar;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 4: CAST NCHAR to NVARCHAR
DECLARE @hdoc INT;
DECLARE @xml_nchar NCHAR(50) = N'<root><item>nchar 🌟</item></root>';
DECLARE @xml_casted NVARCHAR(100) = CAST(@xml_nchar AS NVARCHAR(100));
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_casted;
SELECT @hdoc as CastNCharToNVarchar;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 5: CONVERT VARCHAR to NVARCHAR
DECLARE @hdoc INT;
DECLARE @xml_varchar VARCHAR(100) = '<root><item>convert test</item></root>';
DECLARE @xml_converted NVARCHAR(MAX) = CONVERT(NVARCHAR(MAX), @xml_varchar);
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_converted;
SELECT @hdoc as ConvertVarcharToNVarchar;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 6: CONVERT NVARCHAR to VARCHAR
DECLARE @hdoc INT;
DECLARE @xml_nvarchar NVARCHAR(100) = N'<root><item>convert 测试</item></root>';
DECLARE @xml_converted VARCHAR(MAX) = CONVERT(VARCHAR(MAX), @xml_nvarchar);
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_converted;
SELECT @hdoc as ConvertNVarcharToVarchar;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 7: CAST with length truncation
DECLARE @hdoc INT;
DECLARE @xml_long VARCHAR(200) = '<root><item>very long xml content that might be truncated</item></root>';
DECLARE @xml_truncated VARCHAR(50) = CAST(@xml_long AS VARCHAR(50));
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_truncated;
SELECT @hdoc as CastWithTruncation;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 8: CONVERT with explicit length
DECLARE @hdoc INT;
DECLARE @xml_data NVARCHAR(MAX) = N'<root><item>explicit length conversion 世界</item></root>';
DECLARE @xml_converted VARCHAR(100) = CONVERT(VARCHAR(100), @xml_data);
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_converted;
SELECT @hdoc as ConvertWithLength;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 9: CAST TEXT to VARCHAR(MAX)
DECLARE @hdoc INT;
DECLARE @xml_varchar VARCHAR(MAX);
SELECT @xml_varchar = CAST(text_xml AS VARCHAR(MAX)) FROM CastingTestData_babel_1168 WHERE id = 1;
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_varchar;
SELECT @hdoc as CastTextToVarchar;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 10: CAST NTEXT to NVARCHAR(MAX)
DECLARE @hdoc INT;
DECLARE @xml_nvarchar NVARCHAR(MAX);
SELECT @xml_nvarchar = CAST(ntext_xml AS NVARCHAR(MAX)) FROM CastingTestData_babel_1168 WHERE id = 1;
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_nvarchar;
SELECT @hdoc as CastNTextToNVarchar;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 11: CONVERT with style parameter
DECLARE @hdoc INT;
DECLARE @xml_data VARCHAR(100) = '<root><item>style test</item></root>';
DECLARE @xml_converted NVARCHAR(MAX) = CONVERT(NVARCHAR(MAX), @xml_data, 0);
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_converted;
SELECT @hdoc as ConvertWithStyle;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 12: Nested CAST operations
DECLARE @hdoc INT;
DECLARE @xml_char CHAR(100) = '<root><item>nested cast</item></root>';
DECLARE @xml_nested NVARCHAR(MAX) = CAST(CAST(@xml_char AS VARCHAR(100)) AS NVARCHAR(MAX));
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_nested;
SELECT @hdoc as NestedCast;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 13: CAST with Unicode preservation
DECLARE @hdoc INT;
DECLARE @xml_unicode NVARCHAR(100) = N'<root><item>Unicode: 你好世界 🌍 αβγ</item></root>';
DECLARE @xml_preserved NVARCHAR(MAX) = CAST(@xml_unicode AS NVARCHAR(MAX));
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_preserved;
SELECT @hdoc as CastUnicodePreservation;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 14: CONVERT with potential data loss
DECLARE @hdoc INT;
DECLARE @xml_unicode NVARCHAR(100) = N'<root><item>Data loss test: 世界 🌟</item></root>';
DECLARE @xml_converted VARCHAR(MAX) = CONVERT(VARCHAR(MAX), @xml_unicode);
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_converted;
SELECT @hdoc as ConvertWithDataLoss;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 15: CAST from table columns
DECLARE @hdoc INT;
DECLARE @xml_data VARCHAR(MAX);
SELECT @xml_data = CAST(varchar_xml AS VARCHAR(MAX)) FROM CastingTestData_babel_1168 WHERE id = 1;
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_data;
SELECT @hdoc as CastFromTableColumn;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 16: CONVERT from table columns with Unicode
DECLARE @hdoc INT;
DECLARE @xml_data VARCHAR(MAX);
SELECT @xml_data = CONVERT(VARCHAR(MAX), nvarchar_xml) FROM CastingTestData_babel_1168 WHERE id = 1;
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_data;
SELECT @hdoc as ConvertFromTableUnicode;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 17: CAST with RTRIM/LTRIM
DECLARE @hdoc INT;
DECLARE @xml_padded CHAR(100) = '<root><item>padded</item></root>';
DECLARE @xml_trimmed VARCHAR(MAX) = CAST(RTRIM(@xml_padded) AS VARCHAR(MAX));
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_trimmed;
SELECT @hdoc as CastWithTrim;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 18: CONVERT with string functions
DECLARE @hdoc INT;
DECLARE @xml_data VARCHAR(100) = '<root><item>function test</item></root>';
DECLARE @xml_upper NVARCHAR(MAX) = CONVERT(NVARCHAR(MAX), UPPER(@xml_data));
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_upper;
SELECT @hdoc as ConvertWithFunction;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 19: CAST in CASE expression
DECLARE @hdoc INT;
DECLARE @xml_type INT = 1;
DECLARE @xml_result VARCHAR(MAX) = CASE @xml_type 
    WHEN 1 THEN CAST('<root><item>type1</item></root>' AS VARCHAR(MAX))
    ELSE CAST('<root><item>default</item></root>' AS VARCHAR(MAX))
END;
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_result;
SELECT @hdoc as CastInCase;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test 20: CONVERT with COALESCE
DECLARE @hdoc INT;
DECLARE @xml_null VARCHAR(100) = NULL;
DECLARE @xml_default VARCHAR(100) = '<root><item>default</item></root>';
DECLARE @xml_coalesced VARCHAR(MAX) = CONVERT(VARCHAR(MAX), COALESCE(@xml_null, @xml_default));
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_coalesced;
SELECT @hdoc as ConvertWithCoalesce;
EXEC sp_xml_removedocument @hdoc;
GO

-- Test execution of casting procedure
EXEC TestExplicitCasting_babel_1168;
GO
