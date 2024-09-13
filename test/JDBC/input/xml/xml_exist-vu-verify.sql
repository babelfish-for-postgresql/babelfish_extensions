-- Check if an XML element exists
DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
DECLARE @result1 VARCHAR(50) = CASE WHEN @xml.exist('/Root/Child1') = 1 THEN 'The Child1 element exists' ELSE 'The Child1 element does not exist' END;
SELECT @result1
GO

-- Check if an XML attribute exists
DECLARE @xml XML = '<Root Attr1="Value1"><Child1>Value2</Child1></Root>';
DECLARE @result2 VARCHAR(50) = CASE WHEN @xml.exist('/Root/@Attr1') = 1 THEN 'The Attr1 attribute exists' ELSE 'The Attr1 attribute does not exist' END;
SELECT @result2
GO

-- Check if an XML element or attribute exists, with a specific value
DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
DECLARE @result3 VARCHAR(70) = CASE WHEN @xml.exist('/Root/Child2[text()="Value2"]') = 1 THEN 'The Child2 element with value "Value2" exists' ELSE 'The Child2 element with value "Value2" does not exist' END;
SELECT @result3
GO

-- Check if an XML element or attribute exists, with a specific value and path
DECLARE @xml XML = '<Root><ParentNode><Child1>Value1</Child1></ParentNode><ParentNode><Child1>Value2</Child1></ParentNode></Root>';
DECLARE @result4 VARCHAR(100) = CASE WHEN @xml.exist('/Root/ParentNode/Child1[text()="Value2"]') = 1 THEN 'The Child1 element with value "Value2" under ParentNode exists' ELSE 'The Child1 element with value "Value2" under ParentNode does not exist' END;
SELECT @result4
GO

-- Check if an XML element or attribute exists based on a condition
DECLARE @xml XML = '<Root><Child1 Attr1="Value1">Value2</Child1><Child2 Attr1="Value3">Value4</Child2></Root>';
DECLARE @result6 VARCHAR(80) = CASE WHEN @xml.exist('/Root/Child1[@Attr1="Value1"]') = 1 THEN 'The Child1 element with Attr1="Value1" exists' ELSE 'The Child1 element with Attr1="Value1" does not exist' END;
SELECT @result6
GO

-- Check if multiple XML elements or attributes exist
DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2><Child3>Value3</Child3></Root>';
DECLARE @result7 VARCHAR(50) = CASE WHEN @xml.exist('/Root/Child1') = 1 AND @xml.exist('/Root/Child2') = 1 AND @xml.exist('/Root/Child3') = 1 THEN 'All Child elements exist' ELSE 'One or more Child elements are missing' END;
SELECT @result7
GO

-- Check if an XML element exists using a variable in the XPath expression
DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
DECLARE @element VARCHAR(20) = 'Child1';
DECLARE @result8 VARCHAR(50) = CASE WHEN @xml.exist(CONCAT('/Root/', @element)) = 1 THEN 'The ' + @element + ' element exists' ELSE 'The ' + @element + ' element does not exist' END;
SELECT @result8
GO

-- Check if an XML element exists within a nested XML structure
DECLARE @xml XML = '<Root><Parent1><Child1>Value1</Child1></Parent1><Parent2><Child2>Value2</Child2></Parent2></Root>';
DECLARE @result9 VARCHAR(70) = CASE WHEN @xml.exist('/Root/Parent1/Child1') = 1 THEN 'The Child1 element exists under Parent1' ELSE 'The Child1 element does not exist under Parent1' END;
SELECT @result9
GO

-- Test with a valid XML document
DECLARE @xml XML = '<root><child>Hello</child></root>';
SELECT @xml.exist('(//child)[1]');
GO

-- Test with nested XML elements
DECLARE @xml XML = '<root><parent><child1>Test1</child1><child2>Test2</child2></parent></root>';
SELECT @xml.exist('(//child1)[1]'), @xml.exist('(//child2)[1]');
GO

-- Test with an empty XML document
DECLARE @xml XML = '<root></root>';
SELECT @xml.exist('(//child)[1]');
GO

-- Test with an XML document containing special characters
DECLARE @xml XML = '<root><child>Hello & World</child></root>';
SELECT @xml.exist('(//child)[1]');
GO

-- Test with an XML document containing CDATA sections
DECLARE @xml XML = '<root><child><![CDATA[<data>Hello World</data>]]></child></root>';
SELECT @xml.exist('(//child)[1]');
GO

-- Test with a large XML document
DECLARE @xml XML = '<root>' + REPLICATE('<item>Data</item>', 10000) + '</root>';
SELECT @xml.exist('(/root/item)[1]');
GO

-- Test with NULL input
DECLARE @xml XML = NULL;
SELECT @xml.exist('(//child)[1]');
GO

-- Test with different data types for the second argument
DECLARE @xml XML = '<root><child>123</child></root>';
SELECT @xml.exist('(//child)[1]'), @xml.exist('(//child)[1]'), @xml.exist('(//child)[1]');
GO

-- Test with mixed content XML
DECLARE @xml XML = '<root>This is <bold>mixed</bold> content</root>';
SELECT @xml.exist('(/root)[1]');
GO

-- Test with XML comments
DECLARE @xml XML = '<root><!--This is a comment--><child>Hello</child></root>';
SELECT @xml.exist('(//child)[1]');
GO

-- Test with XML entities
DECLARE @xml XML = '<root><child>Hello &amp; World</child></root>';
SELECT @xml.exist('(//child)[1]');
GO

-- Test with XML attributes
DECLARE @xml XML = '<root><child name="test">Hello</child></root>';
SELECT @xml.exist('(//child/@name)[1]');
GO

-- Test with XML fragments
DECLARE @xml XML = '<child1>Test1</child1><child2>Test2</child2>';
SELECT @xml.exist('(//child1)[1]'), @xml.exist('(//child2)[1]');
GO

-- Test with Unicode characters
DECLARE @xml XML = '<root><child>Hello 世界</child></root>';
SELECT @xml.exist('(//child)[1]');
GO

-- Test with different XML encodings
DECLARE @xml XML = N'<?xml version="1.0" encoding="UTF-8"?><root><child>Héllò</child></root>';
SELECT @xml.exist('(//child)[1]');
GO

-- Test with XML elements containing line breaks
DECLARE @xml XML = '<root><child>Hello
World</child></root>';
SELECT @xml.exist('(//child)[1]');
GO

-- Test with XML elements containing leading/trailing whitespace
DECLARE @xml XML = '<root><child>  Hello  </child></root>';
SELECT @xml.exist('(//child)[1]');
GO

-- Test with XML elements containing XML namespaces within CDATA sections
DECLARE @xml XML = '<root><child><![CDATA[<ns:data xmlns:ns="http://example.com">Hello</ns:data>]]></child></root>';
SELECT @xml.exist('(//child)[1]');
GO

-- Test with XML documents containing internal entities
DECLARE @xml XML = '<?xml version="1.0"?>
<!DOCTYPE root [
<!ENTITY internal "Hello World">
]>
<root>&internal;</root>';
SELECT @xml.exist('(/root)[1]');
GO

-- Test with XML documents containing entity references in attributes
DECLARE @xml XML = '<?xml version="1.0"?>
<!DOCTYPE root [
<!ENTITY attr "value">
]>
<root attr="&attr;"></root>';
SELECT @xml.exist('(/root/@attr)[1]');
GO

-- Test with XML documents containing namespaces in CDATA sections and attributes
DECLARE @xml XML = '<root xmlns:ns="http://example.com"><child><ns:data>Hello</ns:data><![CDATA[<ns:text>World</ns:text>]]><attr ns:attr="value"/></child></root>';
WITH XMLNAMESPACES('http://example.com' as ns)
SELECT @xml.exist('(//ns:data)[1]'), @xml.exist('(//child)[1]'), @xml.exist('(//child/@ns:attr)[1]');
GO

DECLARE @xml XML = '<root xmlns:ns="http://example.com"><child><ns:data>Hello</ns:data><![CDATA[<ns:text>World</ns:text>]]><attr ns:attr="value"/></child></root>';
SELECT @xml.exist('(//ns:data)[1]')
GO

DECLARE @xml XML = '<root xmlns:ns="http://example.com"><child><ns:data>Hello</ns:data><![CDATA[<ns:text>World</ns:text>]]><attr ns:attr="value"/></child></root>';
SELECT @xml.exist('(//child)[1]')
GO

DECLARE @xml XML = '<root xmlns:ns="http://example.com"><child><ns:data>Hello</ns:data><![CDATA[<ns:text>World</ns:text>]]><attr ns:attr="value"/></child></root>';
SELECT @xml.exist('(//child/@ns:attr)[1]');
GO

-- Test with XML documents containing invalid characters
DECLARE @xml XML = '<root>Hello&#0;World</root>';
SELECT @xml.exist('(/root)[1]');
GO

-- Test with XML documents containing XML Digital Signatures
DECLARE @xml XML = '<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child>Hello World</child>
  <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
    <!-- Digital Signature details -->
  </Signature>
</root>';
SELECT @xml.exist('(/root/child)[1]');
GO

-- Test with xpath functions
DECLARE @x XML = '<root></root>';
SELECT @x.exist('true()')
GO

DECLARE @x XML = '<root></root>';
SELECT @x.exist('false()')
GO

-- Acceptable argument types
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.exist('/artists/artist/@name')
GO

-- Unacceptable argument types
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.exist(cast('/artists/artist/@name' as VARCHAR(100)))
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.exist(cast('/artists/artist/@name' as text))
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.exist(@xml)
GO

DECLARE @xml VARCHAR(100) = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.exist('/artists/artist/@name')
GO

DECLARE @xml NVARCHAR(100) = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.exist('/artists/artist/@name')
GO

DECLARE @xml INT = 1
SELECT @xml.exist('/artists/artist/@name')
GO

DECLARE @xml BIGINT = 1
SELECT @xml.exist('/artists/artist/@name')
GO

DECLARE @xml FLOAT = 1
SELECT @xml.exist('/artists/artist/@name')
GO

DECLARE @xml DECIMAL = 1
SELECT @xml.exist('/artists/artist/@name')
GO

DECLARE @xml NUMERIC = 1
SELECT @xml.exist('/artists/artist/@name')
GO

DECLARE @xml BIT = 1
SELECT @xml.exist('/artists/artist/@name')
GO

SELECT XmlColumn.exist('/artists/artist/@name') FROM babel_5222_xml_exist_text
GO

-- UDT on type VARCHAR
SELECT VarUDTColumn.exist('/artists/artist/@name') FROM babel_5222_xml_exist_udt
GO

-- UDT on type IMAGE
SELECT ImageUDTColumn.exist('/artists/artist/@name') FROM babel_5222_xml_exist_udt
GO

-- NULL values
DECLARE @xml XML = NULL
SELECT @xml.exist('/artists/artist/@name')
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.exist(NULL)
GO

DECLARE @xml XML = NULL
SELECT @xml.exist(NULL)
GO

-- column as input argument
SELECT XmlColumn.exist('/artists/artist/@name') FROM babel_5222_xml_exist_t1
GO

SELECT babel_5222_xml_exist_t1.XmlColumn.exist('/artists/artist/@name') FROM babel_5222_xml_exist_t1
GO

SELECT dbo.babel_5222_xml_exist_t1.XmlColumn.exist('/artists/artist/@name') FROM babel_5222_xml_exist_t1
GO

SELECT Id, CASE WHEN XmlColumn.exist('/Root/Child1') = 1 THEN 'The Child1 element exists' ELSE 'The Child1 element does not exist' END AS Result
FROM babel_5222_xml_exist_t2;
GO

SELECT Id, CASE WHEN XmlColumn.exist('/Root/Child2') = 1 THEN 'The Child2 element exists' ELSE 'The Child2 element does not exist' END AS Result
FROM babel_5222_xml_exist_t2;
GO

-- Exist function called on SUBQUERY
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT (SELECT @xml).exist('/artists/artist/@name')
GO

-- Exist function called on LOCAL_ID
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.exist('/artists/artist/@name')
GO

-- Exist function called on LR_BR expr RR_BR
SELECT (CAST('<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>' as XML)).exist('/artists/artist/@name')
GO

-- Exist function called on function_call
SELECT babel_5222_xml_exist_func1().exist('/artists/artist/@name')
GO

SELECT dbo.babel_5222_xml_exist_func1().exist('/artists/artist/@name')
GO

-- Exist function called on spatial function -- this will throw error, only to test nested rewrites
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.exist('/artists/artist/@name').STArea()
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT @xml.exist('/artists/artist/@name').STDistance(@point)
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.exist('/artists/artist/@name').STX
GO

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
DECLARE @point2 geometry = geometry::Point(3.0, 4.0, 4326);
SELECT @point1.STDistance(@point2).exist('/artists/artist/@name');
GO

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT @point.STArea().exist('/artists/artist/@name');
go

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT @point.STX.exist('/artists/artist/@name');
go

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.exist('/artists/artist/@name').exist('/artists/artist/@name').exist('/artists/artist/@name').exist('/artists/artist/@name')
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT @xml.exist('/artists/artist/@name').STDistance(@point).exist('/artists/artist/@name').STArea()
GO

-- different number of arguments than required (Error will be thrown in this scenario)
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.exist()
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.exist('/artists/artist/@name', 1)
GO

-- EVENTDATA().exist -- eventdata() is currently not supported
SELECT EVENTDATA().exist('/EVENT_INSTANCE/EventType')
GO

-- Exist function called on XML Query
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.query('/artists/artist').exist('/artist/@name')
GO

-- Dependent objects
SELECT * FROM babel_5222_xml_exist_dep_view
GO

EXEC babel_5222_xml_exist_dep_proc
GO

SELECT babel_5222_xml_exist_dep_func()
GO

SELECT * FROM babel_5222_xml_exist_itvf_func()
GO

INSERT INTO babel_5222_xml_exist_compcol VALUES ('<artist name="Rohit Bhagat" />')
GO

INSERT INTO babel_5222_xml_exist_compcol VALUES ('<artist />')
GO

SELECT col_xml, comp_col FROM babel_5222_xml_exist_compcol
GO

INSERT INTO babel_5222_xml_exist_constraint VALUES ('<artist name="Rohit Bhagat" />')
GO

INSERT INTO babel_5222_xml_exist_constraint VALUES ('<artist />')
GO

SELECT student FROM babel_5222_xml_exist_school_details
GO

INSERT INTO babel_5222_xml_exist_school_details VALUES (6, '<student classid="2" rollid="3" studentname="StudentF" />')
GO

INSERT INTO babel_5222_xml_exist_school_details VALUES (7, '<student rollid="4" studentname="StudentG" />')
GO

INSERT INTO babel_5222_xml_exist_school_details VALUES (8, '<student classid="2" studentname="StudentH" />')
GO

INSERT INTO babel_5222_xml_exist_school_details VALUES (9, '<student classid="2" rollid="4" />')
GO

INSERT INTO babel_5222_xml_exist_school_details VALUES (10, '<student classid="2" />')
GO

UPDATE babel_5222_xml_exist_school_details
SET student=CAST('<student classid="1" rollid="4" studentname="StudentG" />' as XML)
WHERE id=7
GO

DELETE FROM babel_5222_xml_exist_school_details WHERE id=10
GO

-- Currently, we only support XPATH 1.0 as input for XML exist function. 
-- Hence following queries will throw error
DECLARE @x XML;  
DECLARE @f BIT;  
SET @x = '<root Somedate = "2002-01-01Z"/>';  
SET @f = @x.exist('/root[(@Somedate cast as xs:date?) eq xs:date("2002-01-01Z")]');  
SELECT @f;
GO

DECLARE @x XML;  
DECLARE @f BIT;  
SET @x = '<Somedate>2002-01-01Z</Somedate>';  
SET @f = @x.exist('/Somedate[(text()[1] cast as xs:date ?) = xs:date("2002-01-01Z") ]')  
SELECT @f;
GO

DECLARE @xml XML = '<root><child>Hello</child></root>';
SELECT @xml.exist('(//*:child)[1]');
GO

-- Unsupported XML functions VALUE(), QUERY(), MODIFY()
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value('(/artists/artist/@name)[1]','varchar(20)')
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.query('/artists/artist')
GO

DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
SET @xml.modify('replace value of (/Root/Child2/text())[1] with "NewValue"');
SELECT @xml;
GO
