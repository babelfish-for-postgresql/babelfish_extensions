SELECT SESSIONPROPERTY('QUOTED_IDENTIFIER')
GO

-- XML element values
DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
SELECT @xml.value('(/Root/Child1)[1]', 'varchar(100)')
GO

-- XML attribute values
DECLARE @xml XML = '<Root Attr1="Value1"><Child1>Value2</Child1></Root>';
SELECT @xml.value('(/Root/@Attr1)[1]', 'varchar(100)')
GO

-- XML element or attribute values, with a specific value
DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
SELECT @xml.value('(/Root/Child2[text()="Value2"])[1]', 'varchar(100)')
GO

-- XML element or attribute values, with a specific value and path
DECLARE @xml XML = '<Root><ParentNode><Child1>Value1</Child1></ParentNode><ParentNode><Child1>Value2</Child1></ParentNode></Root>';
SELECT @xml.value('(/Root/ParentNode/Child1[text()="Value2"])[1]', 'varchar(100)')
GO

-- XML element or attribute values based on a condition
DECLARE @xml XML = '<Root><Child1 Attr1="Value1">Value2</Child1><Child2 Attr1="Value3">Value4</Child2></Root>';
SELECT @xml.value('(/Root/Child1[@Attr1="Value1"])[1]', 'varchar(100)')
GO

-- Check if multiple XML elements or attributes value
DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2><Child3>Value3</Child3></Root>';
SELECT @xml.value('(/Root/Child1)[1]', 'varchar(100)') as child1, @xml.value('(/Root/Child2)[1]', 'varchar(100)') as child2, @xml.value('(/Root/Child3)[1]', 'varchar(100)') as child3
GO

-- pattern matches single child
DECLARE @xml XML = '<Root><Child>Value1</Child></Root>';
SELECT @xml.value('/Root/Child', 'varchar(100)') as child
GO

-- pattern matches multiple childs
DECLARE @xml XML = '<Root><Child>Value1</Child><Child>Value2</Child><Child>Value3</Child></Root>';
SELECT @xml.value('/Root/Child', 'varchar(100)') as child
GO

-- XML element values using a variable in the XPath expression
DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
DECLARE @element VARCHAR(20) = 'Child1';
SELECT @xml.value(CONCAT('(/Root/', @element, ')[1]'), 'varchar(100)')
GO

-- XML element values within a nested XML structure
DECLARE @xml XML = '<Root><Parent1><Child1>Value1</Child1></Parent1><Parent2><Child2>Value2</Child2></Parent2></Root>';
SELECT @xml.value('(/Root/Parent1/Child1)[1]', 'varchar(100)')
GO

-- Test with a valid XML document
DECLARE @xml XML = '<root><child>Hello</child></root>';
SELECT @xml.value('(//child)[1]', 'varchar(100)');
GO

-- Test with nested XML elements
DECLARE @xml XML = '<root><parent><child1>Test1</child1><child2>Test2</child2></parent></root>';
SELECT @xml.value('(//child1)[1]', 'varchar(100)'), @xml.value('(//child2)[1]', 'varchar(100)');
GO

-- Test with an empty XML document
DECLARE @xml XML = '<root></root>';
SELECT @xml.value('(//child)[1]', 'varchar(100)');
GO

-- Test with empty input
DECLARE @x XML = ''
SELECT @x.value('(/Root/row)[1]', 'NVARCHAR(100)') 
GO

-- Test with only spaces input
DECLARE @x XML = '    '
SELECT @x.value('(/Root/row)[1]', 'NVARCHAR(100)') 
GO

-- Test with NULL input
DECLARE @x XML = NULL
SELECT @x.value('(/Root/row)[1]', 'NVARCHAR(100)') 
GO

-- Test with empty Path query
DECLARE @xml XML = ''
SELECT @xml.value('', 'varchar(20)')
GO

DECLARE @xml XML = '<Root><row><name>James</name></row></Root>'
SELECT @xml.value('', 'varchar(20)')
GO

-- Test with an XML document containing special characters
DECLARE @xml XML = '<root><child>Hello & World</child></root>';
SELECT @xml.value('(//child)[1]', 'varchar(100)');
GO

-- Test with an XML document containing CDATA sections
DECLARE @xml XML = '<root><child><![CDATA[<data>Hello World</data>]]></child></root>';
SELECT @xml.value('(//child)[1]', 'varchar(100)');
GO

-- Test with a large XML document
DECLARE @xml XML = '<root>' + REPLICATE('<item>Data</item>', 10000) + '</root>';
SELECT @xml.value('(/root/item)[1]', 'varchar(100)');
GO

-- Test with NULL input
DECLARE @xml XML = NULL;
SELECT @xml.value('(//child)[1]', 'varchar(100)');
GO

-- Test with different data types for the second argument
DECLARE @xml XML = '<root><child>123</child></root>';
SELECT @xml.value('(//child)[1]', 'varchar(100)'), @xml.value('(//child)[1]', 'int'), @xml.value('(//child)[1]', 'varbinary');
GO

-- Test with mixed content XML
DECLARE @xml XML = '<root>This is <bold>mixed</bold> content</root>';
SELECT @xml.value('(/root)[1]', 'varchar(100)');
GO

-- Test with XML comments
DECLARE @xml XML = '<root><!--This is a comment--><child>Hello</child></root>';
SELECT @xml.value('(//child)[1]', 'varchar(100)');
GO

-- Test with XML entities
DECLARE @xml XML = '<root><child>Hello &amp; World</child></root>';
SELECT @xml.value('(//child)[1]', 'varchar(100)');
GO

-- Test with XML attributes
DECLARE @xml XML = '<root><child name="test">Hello</child></root>';
SELECT @xml.value('(//child/@name)[1]', 'varchar(100)');
GO

-- Test with XML fragments
DECLARE @xml XML = '<child1>Test1</child1><child2>Test2</child2>';
SELECT @xml.value('(//child1)[1]', 'varchar(100)'), @xml.value('(//child2)[1]', 'varchar(100)');
GO

-- Test with Unicode characters
DECLARE @xml XML = N'<root><child>Hello 世界</child></root>';
SELECT @xml.value('(//child)[1]', 'nvarchar(100)');
GO

-- Test with different XML encodings
DECLARE @xml XML = N'<?xml version="1.0" encoding="UTF-8"?><root><child>Héllò</child></root>';
SELECT @xml.value('(//child)[1]', 'nvarchar(100)');
GO

-- Test with XML elements containing line breaks
DECLARE @xml XML = '<root><child>Hello
World</child></root>';
SELECT @xml.value('(//child)[1]', 'varchar(100)');
GO

-- Test with XML elements containing leading/trailing whitespace
DECLARE @xml XML = '<root><child>  Hello  </child></root>';
SELECT @xml.value('(//child)[1]', 'varchar(100)');
GO

-- Test with XML elements containing XML namespaces within CDATA sections
DECLARE @xml XML = '<root><child><![CDATA[<ns:data xmlns:ns="http://example.com">Hello</ns:data>]]></child></root>';
SELECT @xml.value('(//child)[1]', 'varchar(100)');
GO

-- Test with XML documents containing internal entities
DECLARE @xml XML = '<?xml version="1.0"?>
<!DOCTYPE root [
<!ENTITY internal "Hello World">
]>
<root>&internal;</root>';
SELECT @xml.value('(/root)[1]', 'varchar(100)');
GO

-- Test with XML documents containing entity references in attributes
DECLARE @xml XML = '<?xml version="1.0"?>
<!DOCTYPE root [
<!ENTITY attr "value">
]>
<root attr="&attr;"></root>';
SELECT @xml.value('(/root/@attr)[1]', 'varchar(100)');
GO

-- Test with XML documents containing namespaces in CDATA sections and attributes
DECLARE @xml XML = '<root xmlns:ns="http://example.com"><child><ns:data>Hello</ns:data><![CDATA[<ns:text>World</ns:text>]]><attr ns:attr="value"/></child></root>';
WITH XMLNAMESPACES('http://example.com' as ns)
SELECT @xml.value('(//ns:data)[1]', 'varchar(100)'), @xml.value('(//child)[1]', 'varchar(100)'), @xml.value('(//child/@ns:attr)[1]', 'varchar(100)');
GO

DECLARE @xml XML = '<root xmlns:ns="http://example.com"><child><ns:data>Hello</ns:data><![CDATA[<ns:text>World</ns:text>]]><attr ns:attr="value"/></child></root>';
SELECT @xml.value('(//ns:data)[1]', 'varchar(100)');
GO

DECLARE @xml XML = '<root xmlns:ns="http://example.com"><child><ns:data>Hello</ns:data><![CDATA[<ns:text>World</ns:text>]]><attr ns:attr="value"/></child></root>';
SELECT @xml.value('(//child)[1]', 'varchar(100)');
GO

DECLARE @xml XML = '<root xmlns:ns="http://example.com"><child><ns:data>Hello</ns:data><![CDATA[<ns:text>World</ns:text>]]><attr ns:attr="value"/></child></root>';
SELECT @xml.value('(//child/@ns:attr)[1]', 'varchar(100)');
GO

-- Test with XML documents containing invalid characters
DECLARE @xml XML = '<root>Hello&#0;World</root>';
SELECT @xml.value('(/root)[1]', 'varchar(100)');
GO

-- Test with XML documents containing XML Digital Signatures
DECLARE @xml XML = '<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child>Hello World</child>
  <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
    <!-- Digital Signature details -->
  </Signature>
</root>';
SELECT @xml.value('(/root/child)[1]', 'varchar(100)');
GO

-- Test with xpath functions
DECLARE @x XML = '<root></root>';
SELECT @x.value('true()', 'varchar(100)');
GO

DECLARE @x XML = '<root></root>';
SELECT @x.value('false()', 'varchar(100)');
GO

-- Tests with random spaces in between
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml  .  value  ('(/artists/artist/@name)[1]'  , 'varchar(100)');
GO

SELECT XmlColumn   . value    ('(/artists/artist/@name)[1]'  , 'varchar(100)') FROM babel_5223_xml_value_t1
GO

SELECT babel_5223_xml_value_t1 .   XmlColumn   . value    ('(/artists/artist/@name)[1]'  , 'varchar(100)') FROM babel_5223_xml_value_t1
GO

-- Tests with different case
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.VALUE('(/artists/artist/@name)[1]', 'varchar(100)');
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.Value('(/artists/artist/@name)[1]', 'varchar(100)');
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.VaLuE('(/artists/artist/@name)[1]', 'varchar(100)');
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)');
GO

-- Acceptable argument types
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)');
GO

-- Unacceptable argument types
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value(cast('(/artists/artist/@name)[1]' as VARCHAR(100)), 'varchar(100)');
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value(cast('(/artists/artist/@name)[1]' as text), 'varchar(100)');
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value(@xml, 'varchar(100)');
GO

DECLARE @xml VARCHAR(100) = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)');
GO

DECLARE @xml NVARCHAR(100) = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)');
GO

DECLARE @xml INT = 1
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)');
GO

DECLARE @xml BIGINT = 1
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)')
GO

DECLARE @xml FLOAT = 1
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)')
GO

DECLARE @xml DECIMAL = 1
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)')
GO

DECLARE @xml NUMERIC = 1
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)')
GO

DECLARE @xml BIT = 1
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)')
GO

SELECT XmlColumn.value('(/artists/artist/@name)[1]', 'varchar(100)') FROM babel_5223_xml_value_text
GO

-- UDT on type VARCHAR
SELECT VarUDTColumn.value('(/artists/artist/@name)[1]', 'varchar(100)') FROM babel_5223_xml_value_udt
GO

-- UDT on type IMAGE
SELECT ImageUDTColumn.value('(/artists/artist/@name)[1]', 'varchar(100)') FROM babel_5223_xml_value_udt
GO

-- UDT on type XML
SELECT XmlUDTColumn.value('(/artists/artist/@name)[1]', 'varchar(100)') FROM babel_5223_xml_value_udt
GO

-- Tests on different return types
DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'varchar(10)');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'nvarchar(10)');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'char(10)');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'nchar(10)');
GO

-- Check length of output using datalength
DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT DATALENGTH(@xml.value('(/artists/artist/@id)[1]', 'varchar(10)'));
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT DATALENGTH(@xml.value('(/artists/artist/@id)[1]', 'nvarchar(10)'));
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT DATALENGTH(@xml.value('(/artists/artist/@id)[1]', 'char(10)'));
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT DATALENGTH(@xml.value('(/artists/artist/@id)[1]', 'nchar(10)'));
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'text');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'ntext');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'sql_variant');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'datetimeoffset');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'datetime2');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'datetime');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'smalldatetime');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'date');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'time');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'float');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'real');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'numeric');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'money');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'smallmoney');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'bigint');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'int');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'smallint');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'tinyint');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'varbinary(10)');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'binary(10)');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'bit');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'uniqueidentifier');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'image');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'xml');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'decimal');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'sysname');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'vector');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'sparsevec');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'halfvec');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'timestamp');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'babel_5223_xml_value_varcharUDT');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'dbo.babel_5223_xml_value_varcharUDT');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'babel_5223_xml_value_sch_varcharUDT');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'babel_5223_sch1.babel_5223_xml_value_sch_varcharUDT');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'babel_5223_sch2.babel_5223_xml_value_sch_varcharUDT');
GO

DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'nonexistent');
GO

-- NULL values
DECLARE @xml XML = NULL
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)')
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value(NULL, 'varchar(100)');
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value('(/artists/artist/@name)[1]', NULL);
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value(NULL, NULL);
GO

-- column as input argument
SELECT XmlColumn.value('(/artists/artist/@name)[1]', 'varchar(100)') FROM babel_5223_xml_value_t1
GO

SELECT babel_5223_xml_value_t1.XmlColumn.value('(/artists/artist/@name)[1]', 'varchar(100)') FROM babel_5223_xml_value_t1
GO

SELECT dbo.babel_5223_xml_value_t1.XmlColumn.value('(/artists/artist/@name)[1]', 'varchar(100)') FROM babel_5223_xml_value_t1
GO

SELECT Id, XmlColumn.value('(/Root/Child1)[1]', 'varchar(100)') AS Result
FROM babel_5223_xml_value_t2;
GO

SELECT Id, XmlColumn.value('(/Root/Child2)[1]', 'varchar(100)') AS Result
FROM babel_5223_xml_value_t2 ORDER BY Id;
GO

-- value function called on SUBQUERY
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT (SELECT @xml).value('(/artists/artist/@name)[1]', 'varchar(100)')
GO

-- value function called on LOCAL_ID
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)')
GO

-- value function called on LR_BR expr RR_BR
SELECT (CAST('<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>' as XML)).value('(/artists/artist/@name)[1]', 'varchar(100)')
GO

-- value function called on function_call
SELECT babel_5223_xml_value_func1().value('(/artists/artist/@name)[1]', 'varchar(100)')
GO

SELECT dbo.babel_5223_xml_value_func1().value('(/artists/artist/@name)[1]', 'varchar(100)')
GO

-- value function called on spatial function -- this will throw error, only to test nested rewrites
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)').STArea()
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)').STDistance(@point)
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)').STX
GO

DECLARE @point1 geometry = geometry::Point(1.0, 2.0, 4326);
DECLARE @point2 geometry = geometry::Point(3.0, 4.0, 4326);
SELECT @point1.STDistance(@point2).value('(/artists/artist/@name)[1]', 'varchar(100)');
GO

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT @point.STArea().value('(/artists/artist/@name)[1]', 'varchar(100)');
go

DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT @point.STX.value('(/artists/artist/@name)[1]', 'varchar(100)');
go

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)').value('(/artists/artist/@name)[1]', 'varchar(100)').value('(/artists/artist/@name)[1]', 'varchar(100)').value('(/artists/artist/@name)[1]', 'varchar(100)')
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
DECLARE @point geometry = geometry::Point(1.0, 2.0, 4326);
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)').STDistance(@point).value('(/artists/artist/@name)[1]', 'varchar(100)').STArea()
GO

-- different number of arguments than required (Error will be thrown in this scenario)
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value()
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value('(/artists/artist/@name)[1]', 1)
GO

-- second argument with different quotes
DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
SELECT @xml.value('(/Root/Child1)[1]', 'varchar(100)')
GO

DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
SELECT @xml.value('(/Root/Child1)[1]', "varchar(100)")
GO

DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
SELECT @xml.value('(/Root/Child1)[1]', `varchar(100)`)
GO

DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
SELECT @xml.value('(/Root/Child1)[1]', '''varchar(100)''')
GO

DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
SELECT @xml.value('(/Root/Child1)[1]', [varchar(100)])
GO

SET QUOTED_IDENTIFIER OFF
GO

SELECT SESSIONPROPERTY('QUOTED_IDENTIFIER')
GO

DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
SELECT @xml.value('(/Root/Child1)[1]', 'varchar(100)')
GO

DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
SELECT @xml.value('(/Root/Child1)[1]', "varchar(100)")
GO

DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
SELECT @xml.value('(/Root/Child1)[1]', `varchar(100)`)
GO

DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
SELECT @xml.value('(/Root/Child1)[1]', '''varchar(100)''')
GO

DECLARE @xml XML = '<Root><Child1>Value1</Child1><Child2>Value2</Child2></Root>';
SELECT @xml.value('(/Root/Child1)[1]', [varchar(100)])
GO

SET QUOTED_IDENTIFIER ON
GO

SELECT SESSIONPROPERTY('QUOTED_IDENTIFIER')
GO

-- EVENTDATA().value -- eventdata() is currently not supported
SELECT EVENTDATA().value('/EVENT_INSTANCE/EventType')
GO

-- value function called on XML Query
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.query('/artists/artist').value('/artist/@name', 'varchar(100)')
GO

-- Dependent objects
SELECT * FROM babel_5223_xml_value_dep_view
GO

EXEC babel_5223_xml_value_dep_proc
GO

SELECT babel_5223_xml_value_dep_func()
GO

SELECT * FROM babel_5223_xml_value_itvf_func()
GO

INSERT INTO babel_5223_xml_value_compcol VALUES (1, '<artist name="Rohit Bhagat" />')
GO

INSERT INTO babel_5223_xml_value_compcol VALUES (2, '<artist />')
GO

SELECT col_xml, comp_col FROM babel_5223_xml_value_compcol ORDER BY id
GO

INSERT INTO babel_5223_xml_value_constraint VALUES ('<artist name="Rohit Bhagat" />')
GO

INSERT INTO babel_5223_xml_value_constraint VALUES ('<artist />')
GO

-- Testing computed columns and constraints with quoted_identifier as ON
-- Testing computed columns created on wrapper function of xml value when quoted_identifier was ON
INSERT INTO babel_5223_xml_value_compcol1 VALUES (1, '<artist name="Rohit Bhagat" />')
GO

INSERT INTO babel_5223_xml_value_compcol1 VALUES (2, '<artist />')
GO

SELECT col_xml, comp_col FROM babel_5223_xml_value_compcol1 ORDER BY id
GO

-- Testing constraint created on wrapper function of xml value
INSERT INTO babel_5223_xml_value_constraint1 VALUES ('<artist name="Rohit Bhagat" />')
GO

INSERT INTO babel_5223_xml_value_constraint1 VALUES ('<artist />')
GO

-- Testing view created on xml value when quoted_identifier was OFF
SELECT * FROM babel_5223_xml_value_dep_view2
GO

-- Testing computed columns created on wrapper function of xml value when quoted_identifier was OFF
INSERT INTO babel_5223_xml_value_compcol2 VALUES (1, '<artist name="Rohit Bhagat" />')
GO

INSERT INTO babel_5223_xml_value_compcol2 VALUES (2, '<artist />')
GO

SELECT col_xml, comp_col FROM babel_5223_xml_value_compcol2 ORDER BY id
GO

-- Testing constraint created on wrapper function of xml value when quoted_identifier was OFF
INSERT INTO babel_5223_xml_value_constraint2 VALUES ('<artist name="Rohit Bhagat" />')
GO

INSERT INTO babel_5223_xml_value_constraint2 VALUES ('<artist />')
GO

SET QUOTED_IDENTIFIER OFF
GO

SELECT SESSIONPROPERTY('QUOTED_IDENTIFIER')
GO

-- Testing computed columns and constraints with quoted_identifier as OFF 
-- Testing computed columns created on wrapper function of xml value when quoted_identifier was ON
SET QUOTED_IDENTIFIER ON
GO
INSERT INTO babel_5223_xml_value_compcol1 VALUES (1, '<artist name="Rohit Bhagat" />')
GO

INSERT INTO babel_5223_xml_value_compcol1 VALUES (2, '<artist />')
GO

SELECT col_xml, comp_col FROM babel_5223_xml_value_compcol1 ORDER BY id
GO

-- Testing constraint created on wrapper function of xml value when quoted_identifier was OFF
INSERT INTO babel_5223_xml_value_constraint1 VALUES ('<artist name="Rohit Bhagat" />')
GO

INSERT INTO babel_5223_xml_value_constraint1 VALUES ('<artist />')
GO

-- Testing view created on xml value when quoted_identifier was OFF
SELECT * FROM babel_5223_xml_value_dep_view2
GO

-- Testing computed columns and constraints with quoted_identifier as OFF 
-- Testing computed columns created on wrapper function of xml value when quoted_identifier was OFF
SET QUOTED_IDENTIFIER ON
GO
INSERT INTO babel_5223_xml_value_compcol2 VALUES (1, '<artist name="Rohit Bhagat" />')
GO

INSERT INTO babel_5223_xml_value_compcol2 VALUES (2, '<artist />')
GO

SELECT col_xml, comp_col FROM babel_5223_xml_value_compcol2 ORDER BY id
GO

-- Testing constraint created on wrapper function of xml value when quoted_identifier was OFF
INSERT INTO babel_5223_xml_value_constraint2 VALUES ('<artist name="Rohit Bhagat" />')
GO

INSERT INTO babel_5223_xml_value_constraint2 VALUES ('<artist />')
GO

SET QUOTED_IDENTIFIER ON
GO

SELECT SESSIONPROPERTY('QUOTED_IDENTIFIER')
GO

SELECT student FROM babel_5223_xml_value_school_details ORDER BY id
GO

INSERT INTO babel_5223_xml_value_school_details VALUES (6, '<student classid="2" rollid="3" studentname="StudentF" />')
GO

INSERT INTO babel_5223_xml_value_school_details VALUES (7, '<student classid="2"  rollid="4" studentname="Rohit" />')
GO

INSERT INTO babel_5223_xml_value_school_details VALUES (8, '<student classid="1"  rollid="4" studentname="NotAStudent" />')
GO

UPDATE babel_5223_xml_value_school_details
SET student=CAST('<student classid="1" rollid="4" studentname="StudentG" />' as XML)
WHERE id=7
GO

DELETE FROM babel_5223_xml_value_school_details WHERE id=8
GO

-- Tests when Quoted Identifier is OFF
SET QUOTED_IDENTIFIER OFF
GO

SELECT SESSIONPROPERTY('QUOTED_IDENTIFIER')
GO

DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.value('(/artists/artist/@name)[1]', 'varchar(100)')
GO

SELECT XmlColumn.value('(/artists/artist/@name)[1]', 'varchar(100)') FROM babel_5223_xml_value_t1
GO

SELECT babel_5223_xml_value_t1.XmlColumn.value('(/artists/artist/@name)[1]', 'varchar(100)') FROM babel_5223_xml_value_t1
GO

-- QUOTED_IDENFIER related error should be thrown in following query and not argument invalid error
DECLARE @xml XML = '<artists> <artist id="1"/> </artists>'
SELECT @xml.value('(/artists/artist/@id)[1]', 'sql_variant');
GO

-- error "cannot call method on int" should be thrown in following query and not QUOTED_IDENFIER related error
DECLARE @xml INT = 1
SELECT @xml.value('(/artists/artist/@name)[1]', 'sql_variant');
GO

SET QUOTED_IDENTIFIER ON
GO

SELECT SESSIONPROPERTY('QUOTED_IDENTIFIER')
GO

-- error "cannot call method on int" should be thrown in following query and not argument datatype invalid error
DECLARE @xml INT = 1
SELECT @xml.value('(/artists/artist/@name)[1]', 'sql_variant');
GO

-- argument datatype invalid error should be thrown
DECLARE @xml XML = '<artists> <artist name="John Doe"/> <artist name="Edward Poe"/> <artist name="Mark The Great"/> </artists>'
SELECT @xml.VALUE('(/artists/artist/@name)[1]', 'sql_variant');
GO

-- Currently, we only support XPATH 1.0 as input for XML value function. 
-- Hence following queries will throw error
DECLARE @x XML;  
DECLARE @f BIT;  
SET @x = '<root Somedate = "2002-01-01Z"/>';  
SET @f = @x.value('/root[(@Somedate cast as xs:date?) eq xs:date("2002-01-01Z")]', 'varchar(100)');
SELECT @f;
GO

DECLARE @x XML;  
DECLARE @f BIT;  
SET @x = '<Somedate>2002-01-01Z</Somedate>';  
SET @f = @x.value('/Somedate[(text()[1] cast as xs:date ?) = xs:date("2002-01-01Z") ]', 'varchar(100)');
SELECT @f;
GO

DECLARE @xml XML = '<root><child>Hello</child></root>';
SELECT @xml.value('(//*:child)[1]');
GO

-- check for the special tag not being used in data or query
DECLARE @x XML = '<magic_bbf_xmlnodes_945193483c854af5a887b50698b99b05_tag>test</magic_bbf_xmlnodes_945193483c854af5a887b50698b99b05_tag>  ';
SELECT @x.value('(/*)', 'NVARCHAR(100)') AS c;
go

DECLARE @x XML = '<MAGIC_BBF_XMLNODES_945193483C854AF5A887B50698B99B05_TAG>test</MAGIC_BBF_XMLNODES_945193483C854AF5A887B50698B99B05_TAG>  ';
SELECT @x.value('(/*)', 'NVARCHAR(100)') AS c;
go

DECLARE @x XML = '<magic_bbf_xmlnodes_945193483c854af5a887b50698b99b05_tag>test</magic_bbf_xmlnodes_945193483c854af5a887b50698b99b05_tag>  ';
SELECT @x.value('(/magic_bbf_xmlnodes_945193483c854af5a887b50698b99b05_tag)', 'NVARCHAR(100)') AS c;
go

DECLARE @x XML = '<MAGIC_BBF_XMLNODES_945193483C854AF5A887B50698B99B05_TAG>test</MAGIC_BBF_XMLNODES_945193483C854AF5A887B50698B99B05_TAG>  ';
SELECT @x.value('(/MAGIC_BBF_XMLNODES_945193483C854AF5A887B50698B99B05_TAG)', 'NVARCHAR(100)') AS c;
go

-- '.[' in element or XPath query
DECLARE @xml XML = '<root><item name="a.[b">MATCH</item></root>'
SELECT @xml.value('(/root/item[@name="a.[b"])[1]', 'varchar(20)')
go

DECLARE @xml XML = '<root><item a.b="x.y">MATCH</item></root>'
SELECT @xml.value('(/root/item[@a.b="x.y"])[1]', 'varchar(20)')
go

DECLARE @xml XML = '<root><item a.b_.="x.y">MATCH</item>><item a.b_.="y.z">MATCH2</item></root>'
SELECT @xml.value('(/root/item[@a.b_.="x.y"])[1]', 'varchar(20)')
go

DECLARE @xml XML = '<root><item a.b_.="x.y">MATCH</item>><item a.b_.="y.z">MATCH2</item></root>'
SELECT @xml.value('(/root/item[@a.b_.="y.z"])[1]', 'varchar(20)')
go

-- invalid 
DECLARE @xml XML = '<root><item a.[b="x.y">MATCH</item></root>'
SELECT @xml.value('(/root/item[@a.[b="x.y"])[1]', 'varchar(20)')
go

-- invalid, unterminated string
DECLARE @xml XML = '<root><item name="a.[b">MATCH</item></root>'
SELECT @xml.value('(/root/item[@name="a.[b])[1]', 'varchar(20)')
go