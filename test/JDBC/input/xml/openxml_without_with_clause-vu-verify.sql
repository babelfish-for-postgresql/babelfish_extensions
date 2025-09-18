-- Document Structure Tests
-- XML Document with xpath to select Customers nodes
DECLARE @handle INT, @xml nvarchar(1000);
SET @xml = '
<ROOT>
<Customers CustomerID="VINET" ContactName="Paul Henriot">
   <Orders CustomerID="VINET" EmployeeID="5" OrderDate=
           "1996-07-04T00:00:00">
      <OrderDetails OrderID="10248" ProductID="11" Quantity="12"/>
      <OrderDetails OrderID="10248" ProductID="42" Quantity="10"/>
   </Orders>
</Customers>
<Customers CustomerID="LILAS" ContactName="Carlos Gonzlez">
   <Orders CustomerID="LILAS" EmployeeID="3" OrderDate=
           "1996-08-16T00:00:00">
      <OrderDetails OrderID="10283" ProductID="72" Quantity="3"/>
   </Orders>
</Customers>
</ROOT>';
EXEC sp_xml_preparedocument @handle OUTPUT, @xml;
SELECT * FROM OPENXML(@handle, '/ROOT/Customers') ORDER BY id;
EXEC sp_xml_removedocument @handle;
GO

-- Simple XML Document
DECLARE @xml nvarchar(1000) = '<root>Hello World</root>';
DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml;
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Empty XML Document
DECLARE @xml nvarchar(1000) = '<root></root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- XML Declaration
DECLARE @xml nvarchar(1000) = '<?xml version="1.0"?><root>test</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Nested Elements
DECLARE @xml nvarchar(1000) = '
<level1>
    <level2>
        <level3>
            <level4>Deep content</level4>
        </level3>
    </level2>
</level1>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Multiple Siblings
DECLARE @xml nvarchar(1000) = '
<root>
    <sibling1>Content 1</sibling1>
    <sibling2>Content 2</sibling2>
    <sibling3>Content 3</sibling3>
    <sibling4>Content 4</sibling4>
</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Mixed Content
DECLARE @xml nvarchar(1000) = '<root>Text before<child>Child content</child>Text after</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Single Attribute
DECLARE @xml nvarchar(1000) = '<root id="123">content</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Multiple Attributes
DECLARE @xml nvarchar(1000) = '<root id="123" name="test" value="456" status="active">content</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Namespaced Attributes
DECLARE @xml nvarchar(1000) = '<root xmlns:attr="http://attr.com" attr:id="123" attr:name="test">content</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- XML Entities
DECLARE @xml nvarchar(1000) = '<root>&lt;escaped&gt; &amp; &quot;quoted&quot; &apos;apostrophe&apos;</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- XML Entities in Nested nodes
DECLARE @xml nvarchar(1000) = '<root><child>&lt;escaped&gt;</child><child>&amp; &quot;quoted&quot;</child><child>&apos;apostrophe&apos;</child></root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Unicode Characters
DECLARE @xml nvarchar(1000) = N'<root>Unicode: αβγ 中文 العربية русский</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Whitespace Handling
DECLARE @xml nvarchar(1000) = '<root>
    <child1>   Content with spaces   </child1>
    <child2>
        Multiline
        Content
    </child2>
</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Empty String XML
DECLARE @xml NVARCHAR(MAX) = ''
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Self-Closing Tags
DECLARE @xml nvarchar(1000) = '<root><empty/><selfclosed attr="value"/></root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Parent-Child Relationship Validation
DECLARE @xml nvarchar(1000) = '<root><parent><child>content</child></parent></root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml

-- Test parent-child relationships
SELECT 
    parent.localname as ParentName,
    child.localname as ChildName,
    child.parentid,
    parent.id,
    'Relationship Test' as TestType
FROM OPENXML(@handle, '/') parent
INNER JOIN OPENXML(@handle, '/') child ON parent.id = child.parentid
WHERE parent.nodetype = 1 AND child.nodetype = 1

EXEC sp_xml_removedocument @handle
GO


-- Node Type Tests
-- Element Nodes (nodetype = 1)
DECLARE @xml nvarchar(1000) = '<parent><child1>text1</child1><child2>text2</child2></parent>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') WHERE nodetype = 1 ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Attribute Nodes (nodetype = 2)
DECLARE @xml nvarchar(1000) = '<root attr1="value1" attr2="value2">content</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') WHERE nodetype = 2 ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Text Nodes (nodetype = 3)
DECLARE @xml nvarchar(1000) = '<root>This is text content</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') WHERE nodetype = 3 ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- CDATA Sections (nodetype = 4)
DECLARE @xml nvarchar(1000) = '<root><![CDATA[This is CDATA content]]></root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') WHERE nodetype = 4 ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Entity Reference Nodes (nodetype = 5)
DECLARE @xml NVARCHAR(MAX) = '<!DOCTYPE root [
    <!ENTITY customEntity "Custom Entity Value">
]>
<root>
    This contains &customEntity; in the text.
    <element attr="&customEntity;">More &customEntity; content</element>
</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') WHERE nodetype = 5 ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Entity Nodes (nodetype = 6)
DECLARE @xml NVARCHAR(MAX) = '<!DOCTYPE root [
    <!ENTITY entity1 "First Entity">
    <!ENTITY entity2 "Second Entity">
    <!ENTITY entity3 "Third Entity">
]>
<root>
    <content>&entity1;</content>
    <content>&entity2;</content>
    <content>&entity3;</content>
</root>';
DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml;
SELECT * FROM OPENXML(@handle, '/') WHERE nodetype = 6 ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Processing Instructions (nodetype = 7)
DECLARE @xml nvarchar(1000) = '<root><?xml-stylesheet type="text/xsl" href="style.xsl"?>content</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') WHERE nodetype = 7 ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Comments (nodetype = 8)
DECLARE @xml nvarchar(1000) = '<root><!-- This is a comment -->content</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') WHERE nodetype = 8 ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- All Node Types in Single Document
DECLARE @xml nvarchar(1000) = '<?xml version="1.0"?>
<!-- Root comment -->
<root xmlns="http://default.ns" xmlns:prefix="http://prefix.ns" attr="rootattr">
    Text content
    <element prefix:attr="prefixedattr">Element text</element>
    <!-- Element comment -->
    <![CDATA[CDATA section content]]>
    <?processing-instruction data?>
    <selfclosing/>
</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml

SELECT 
    id,
    parentid,
    nodetype,
    CASE nodetype
        WHEN 1 THEN 'Element'
        WHEN 2 THEN 'Attribute' 
        WHEN 3 THEN 'Text'
        WHEN 4 THEN 'CDATA'
        WHEN 7 THEN 'Processing Instruction'
        WHEN 8 THEN 'Comment'
        ELSE 'Other'
    END as NodeTypeName,
    localname,
    prefix,
    namespaceuri,
    prev,
    SUBSTRING(CAST(text as NVARCHAR(MAX)), 1, 50) as TextContent
FROM OPENXML(@handle, '/')
ORDER BY id

EXEC sp_xml_removedocument @handle
GO


-- DTD Tests
-- XML with DTD and various attribute types
DECLARE @handle INT;
DECLARE @xmlText NVARCHAR(MAX) = 
'<!DOCTYPE item [
  <!ELEMENT item EMPTY>
  <!ATTLIST item
    name CDATA #IMPLIED
    id ID "item5"
    ref IDREF #IMPLIED
    refs IDREFS #IMPLIED
    file ENTITY #IMPLIED
    files ENTITIES #IMPLIED
    code NMTOKEN #REQUIRED
    codes NMTOKENS #REQUIRED
    type (type1|type2|type3) "type1"
    imgtype NOTATION (gif | jpeg) #REQUIRED
  >
]>
<itemList>
    <item id="item1" ref="item0" codes="X123 X000 X111" name="Sample Item" file="fileEntity" type="type1" />
    <item id="item2" refs="item1 item2" code="X345" name="Sample Item" file="fileEntity" type="type2" />
    <item id="item3" ref="item2" code="X678" name="Sample Item" files="fileEntity1 fileEntity2" type="type3" />
    <item id="item4" ref="item3" src="logo.gif" imgtype="gif" />
</itemList>';
EXEC sp_xml_preparedocument @handle OUTPUT, @xmlText;
SELECT id, parentid, nodetype, 
       CAST(localname AS NVARCHAR(20)) as localname, 
       CAST(prefix AS NVARCHAR(20)) as prefix, 
       CAST(namespaceuri AS NVARCHAR(20)) as namespaceuri, 
       CAST(datatype AS NVARCHAR(20)) as datatype, 
       prev, text 
FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle;
GO


-- Namespace Tests
-- Default Namespace
DECLARE @xml nvarchar(1000) = '<root xmlns="http://example.com/default"><child>content</child></root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Prefixed Namespaces
DECLARE @xml nvarchar(1000) = '<ns1:root xmlns:ns1="http://example.com/ns1" xmlns:ns2="http://example.com/ns2">
    <ns1:child1>content1</ns1:child1>
    <ns2:child2>content2</ns2:child2>
</ns1:root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Multiple Namespace Declarations
DECLARE @xml nvarchar(1000) = '<root xmlns:a="http://a.com" xmlns:b="http://b.com" xmlns:c="http://c.com">
    <a:elementA>A content</a:elementA>
    <b:elementB>B content</b:elementB>
    <c:elementC>C content</c:elementC>
</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Namespace in XPATH
DECLARE @xml nvarchar(1000) = 
'<root xmlns:ns1="http://example.com/ns1" xmlns:ns2="http://example.com/ns2">
    <ns1:child>value</ns1:child>
    <ns2:child>value</ns2:child>
</root>'
DECLARE @namespace nvarchar(100) = '<root xmlns:ns1="http://example.com/ns1" />'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @namespace
SELECT * FROM OPENXML(@handle, '/root/ns1:child') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Default Namespace in XML Document but XPATH does not have any prefix no result
DECLARE @xml nvarchar(1000) = '<root xmlns="http://example.com/default"><child>content</child></root>'
DECLARE @ns nvarchar(1000) = '<root xmlns="http://example.com/default"></root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @ns
SELECT * FROM OPENXML(@handle, '/root/child') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Default Namespace in XML Document but Prefix Namespace with same URI in Namespace document
DECLARE @xml nvarchar(1000) = '<root xmlns="http://example.com/default"><child>content</child></root>'
DECLARE @ns nvarchar(1000) = '<root xmlns:dns="http://example.com/default"></root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @ns
SELECT * FROM OPENXML(@handle, '/dns:root') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Multiple namespaces in XPATH
DECLARE @xml nvarchar(1000) = 
'<root xmlns:ns1="http://example.com/ns1" xmlns:ns2="http://example.com/ns2">
    <ns1:child>value</ns1:child>
    <ns2:child>value</ns2:child>
</root>';
DECLARE @namespace nvarchar(100) = '<root xmlns:ns1="http://example.com/ns1" xmlns:ns2="http://example.com/ns2" />';
DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @namespace;
SELECT * FROM OPENXML(@handle, '/root/ns1:child | /root/ns2:child') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- namespace xml document with root and child both having namespaces,
-- but xpath only root namespace is considered
DECLARE @xml nvarchar(1000) = 
'<root xmlns:ns1="http://example.com/ns1" xmlns:ns2="http://example.com/ns2">
    <ns1:child>value</ns1:child>
    <ns2:child>value</ns2:child>
</root>'
DECLARE @namespace nvarchar(1000) = 
'<root xmlns:ns1="http://example.com/ns1"> 
    <child xmlns:ns2="http://example.com/ns2"></child>
</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml, @namespace
SELECT * FROM OPENXML(@handle, '/root/ns1:child') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

DECLARE @xml nvarchar(1000) = 
'<root xmlns:ns1="http://example.com/ns1" xmlns:ns2="http://example.com/ns2">
    <ns1:child>value</ns1:child>
    <ns2:child>value</ns2:child>
</root>'
DECLARE @namespace nvarchar(100) = 
'<root xmlns:ns1="http://example.com/ns1"> 
    <child xmlns:ns2="http://example.com/ns2"></child>
</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/root/n2:child') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- XPATH having namespace, but no namespace provided in sp_xml_preparedocument
DECLARE @xml nvarchar(1000) = 
'<root xmlns:ns1="http://example.com/ns1" xmlns:ns2="http://example.com/ns2">
    <ns1:child>value</ns1:child>
    <ns2:child>value</ns2:child>
</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/root/ns1:child') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO


-- Node Selection Tests
-- Root Node Selection
DECLARE @xml nvarchar(1000) = '<root><child>content</child></root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Specific Element Selection
DECLARE @xml nvarchar(1000) = '<root><target>found</target><other>not found</other></root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/root/target') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Wildcard Selection
DECLARE @xml nvarchar(1000) = '<root><child1>c1</child1><child2>c2</child2></root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/root/*') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Special Node Selection Tests
DECLARE @xml nvarchar(1000) = '<?xml version="1.0"?>
<!-- Root comment -->
<root xmlns="http://default.ns" xmlns:prefix="http://prefix.ns" attr="rootattr">
    Text content
    <element prefix:attr="prefixedattr">Element text</element>
    <!-- Element comment -->
    <![CDATA[CDATA section content]]>
    <?processing-instruction data?>
    <selfclosing/>
</root>' 
DECLARE @handle INT 
EXEC sp_xml_preparedocument @handle OUTPUT, @xml 
SELECT * FROM OPENXML(@handle, '//comment() | //processing-instruction()')  ORDER BY id;
EXEC sp_xml_removedocument @handle
GO


-- Error Handling Tests
-- Invalid XML Error Handling
DECLARE @xml NVARCHAR(MAX) = '<root><unclosed>content</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- NULL XML Error Handling
DECLARE @xml nvarchar(1000) = NULL
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

DECLARE @handle INT = NULL;
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
GO

-- Invalid Handle Error Handling
DECLARE @handle INT = 999999;
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
GO

-- Invalid XPath Error Handling
DECLARE @xml nvarchar(1000) = '<root>content</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, 'invalid[xpath') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Empty XPath Error Handling
DECLARE @xml nvarchar(1000) = '<root>content</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO


-- Edge Cases and Complex Structures
-- Complex CDATA example
DECLARE @xml nvarchar(1000) = '<!DOCTYPE root
    [<!ELEMENT root (Customers)*>
    <!ELEMENT Customers EMPTY>
    <!ATTLIST Customers CustomerID CDATA #IMPLIED ContactName CDATA #IMPLIED>]>
<root>
    <Customers CustomerID="ALFKI" ContactName="Maria Anders"/>
</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml
SELECT * FROM OPENXML(@handle, '/') ORDER BY id;
EXEC sp_xml_removedocument @handle
GO

-- Complex Nested Structure with Mixed Content
DECLARE @xml nvarchar(1000) = '
<catalog xmlns:book="http://books.com" xmlns:author="http://authors.com">
    <book:book id="1" book:isbn="123456789">
        <book:title>SQL Server Guide</book:title>
        <author:author author:id="100">
            <author:name>John Doe</author:name>
            <author:email>john@example.com</author:email>
        </author:author>
        <book:chapters>
            <book:chapter number="1">Introduction</book:chapter>
            <book:chapter number="2">Advanced Topics</book:chapter>
        </book:chapters>
        <!-- Publication info -->
        <book:published>2024</book:published>
    </book:book>
</catalog>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml

-- Show complete node structure
SELECT 
    id,
    parentid,
    nodetype,
    localname,
    prefix,
    namespaceuri,
    CASE 
        WHEN LEN(CAST(text as NVARCHAR(MAX))) > 50 
        THEN SUBSTRING(CAST(text as NVARCHAR(MAX)), 1, 50) + '...'
        ELSE CAST(text as NVARCHAR(MAX))
    END as TextContent
FROM OPENXML(@handle, '/')
ORDER BY id

EXEC sp_xml_removedocument @handle
GO

-- Long element name
DECLARE @xml nvarchar(1000) = '<longggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg>Hello World</longggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg>';
DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml;
SELECT id, len(localname) FROM OPENXML(@handle, '/') ORDER BY id
EXEC sp_xml_removedocument @handle
GO

-- Extreme Values and Edge Cases
DECLARE @xml nvarchar(1000) = '<root 
    veryLongAttributeName="VeryLongAttributeValueThatExceedsNormalLengthExpectations"
    emptyAttr=""
    numericAttr="12345.67"
    booleanAttr="true"
    dateAttr="2024-01-01T10:30:00Z">
    <emptyElement></emptyElement>
    <whitespaceElement>   </whitespaceElement>
    <numberElement>42</numberElement>
    <decimalElement>3.14159</decimalElement>
    <specialChars>&lt;&gt;&amp;&quot;&apos;</specialChars>
</root>'
DECLARE @handle INT
EXEC sp_xml_preparedocument @handle OUTPUT, @xml

SELECT 
    localname,
    nodetype,
    LEN(CAST(text as NVARCHAR(MAX))) as TextLength,
    CAST(text as NVARCHAR(MAX)) as TextContent
FROM OPENXML(@handle, '/')
WHERE nodetype IN (1, 2, 3)
ORDER BY id

EXEC sp_xml_removedocument @handle
GO


-- Dependent objects tests
EXEC openxml_without_with_dep_proc1 N'<root><child>content</child></root>'
GO

EXEC openxml_without_with_dep_proc2 N'<root><child>content</child></root>'
GO


-- CROSS APPLY
DECLARE @xml NVARCHAR(1000) = '
<Company>
    <Employee ID="101">Alice Johnson</Employee>
    <Employee ID="102">Bob Wilson</Employee>
</Company>';
DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml;
SELECT
    CAST(x.localname AS NVARCHAR(20)) as element, 
    CASE x.nodetype
        WHEN 1 THEN 'Element'
        WHEN 2 THEN 'Attribute' 
        ELSE 'Other'
    END as type,
    CAST(d.text AS NVARCHAR(20)) as value 
FROM OPENXML(@handle, '/Company/Employee') x 
CROSS APPLY OPENXML(@handle, '/Company/Employee') d 
WHERE x.nodetype IN (1,2) AND d.nodetype = 3 AND d.parentid = x.id;
EXEC sp_xml_removedocument @handle;
GO

-- OUTER APPLY
DECLARE @xml NVARCHAR(1000) = '
<Company>
    <Employee ID="101">Alice Johnson</Employee>
    <Employee ID="102">Bob Wilson</Employee>
</Company>';
DECLARE @handle INT;
EXEC sp_xml_preparedocument @handle OUTPUT, @xml;
SELECT
    CAST(x.localname AS NVARCHAR(20)) as element, 
    CASE x.nodetype
        WHEN 1 THEN 'Element'
        WHEN 2 THEN 'Attribute' 
        ELSE 'Other'
    END as type,
    CAST(d.text AS NVARCHAR(20)) as value 
FROM OPENXML(@handle, '/Company/Employee') x 
OUTER APPLY OPENXML(@handle, '/Company/Employee') d 
WHERE x.nodetype IN (1,2) AND d.nodetype = 3 AND d.parentid = x.id;
EXEC sp_xml_removedocument @handle;
GO

-- Testing Trigger on OPENXML
SELECT * FROM babel_6046_school_details_raw_xml
GO

SELECT * FROM babel_6046_school_details
GO

INSERT INTO babel_6046_school_details_raw_xml (id, student)
VALUES (1, '<student classid="1" rollid="1" studentname="StudentA" />')
GO

SELECT * FROM babel_6046_school_details_raw_xml
GO

SELECT * FROM babel_6046_school_details
GO

INSERT INTO babel_6046_school_details_raw_xml (id, student)
VALUES (2, '<student classid="1" rollid="2" studentname="StudentB" />')
GO

SELECT * FROM babel_6046_school_details_raw_xml
GO

SELECT * FROM babel_6046_school_details
GO

