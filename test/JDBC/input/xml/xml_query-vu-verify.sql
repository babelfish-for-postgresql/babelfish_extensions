-- ============================================
-- SECTION 1: Basic .query() on variables
-- ============================================

-- Extract a single child element
DECLARE @x XML = '<root><name>John</name><age>30</age></root>';
SELECT @x.query('/root/name');
GO

-- Extract root element
DECLARE @x XML = '<root><name>John</name><age>30</age></root>';
SELECT @x.query('/root');
GO

-- Extract multiple child elements
DECLARE @x XML = '<root><a>1</a><b>2</b><c>3</c></root>';
SELECT @x.query('/root/a');
GO

-- Extract all children using wildcard
DECLARE @x XML = '<root><a>1</a><b>2</b></root>';
SELECT @x.query('/root/*');
GO

-- XPath returning no match (empty result)
DECLARE @x XML = '<root><name>John</name></root>';
SELECT @x.query('/root/nonexistent');
GO

-- Extract text content
DECLARE @x XML = '<root><name>John</name></root>';
SELECT @x.query('/root/name/text()');
GO

-- ============================================
-- SECTION 2: .query() on table columns
-- ============================================

-- Basic column query
SELECT id, data.query('/root/name') FROM xml_query_t1 WHERE id = 1;
GO

-- Query across multiple rows
SELECT id, data.query('/root/name') FROM xml_query_t1 WHERE id <= 3;
GO

-- Query on NULL XML column
SELECT id, data.query('/root/name') FROM xml_query_t1 WHERE id = 4;
GO

-- Query all rows including NULL
SELECT id, data.query('/root') FROM xml_query_t1;
GO

-- ============================================
-- SECTION 3: Multiple elements and repeated tags
-- ============================================

-- Multiple sibling elements with same name
SELECT data.query('/employees/emp') FROM xml_query_t2 WHERE id = 1;
GO

-- Positional access
SELECT data.query('/employees/emp[1]') FROM xml_query_t2 WHERE id = 1;
GO

SELECT data.query('/employees/emp[2]') FROM xml_query_t2 WHERE id = 1;
GO

-- Out of range positional access
SELECT data.query('/employees/emp[3]') FROM xml_query_t2 WHERE id = 1;
GO

-- ============================================
-- SECTION 4: Nested XML and deep paths
-- ============================================

-- Deep nested path
SELECT data.query('/a/b/c/d') FROM xml_query_t7 WHERE id = 1;
GO

-- Partial path
SELECT data.query('/a/b') FROM xml_query_t7 WHERE id = 1;
GO

-- Descendant axis
DECLARE @x XML = '<a><b><c>deep</c></b></a>';
SELECT @x.query('//c');
GO

-- ============================================
-- SECTION 5: Attributes
-- ============================================

-- Query element with attributes
SELECT data.query('/root/item[@name="A"]') FROM xml_query_t4 WHERE id = 1;
GO

-- Query all items
SELECT data.query('/root/item') FROM xml_query_t4 WHERE id = 1;
GO

-- Attribute predicate
SELECT data.query('/root/item[@value="2"]') FROM xml_query_t4 WHERE id = 1;
GO

-- ============================================
-- SECTION 6: Predicates and filters
-- ============================================

-- Element value predicate
SELECT data.query('/catalog/book[price>30]') FROM xml_query_t3 WHERE id = 1;
GO

-- Attribute predicate
SELECT data.query('/catalog/book[@id="1"]') FROM xml_query_t3 WHERE id = 1;
GO

-- Multiple predicates
SELECT data.query('/catalog/book[@id="2"]/title') FROM xml_query_t3 WHERE id = 1;
GO

-- ============================================
-- SECTION 7: Special characters in XML values
-- ============================================

SELECT data.query('/root/val') FROM xml_query_t6 WHERE id = 1;
GO

SELECT data.query('/root/val') FROM xml_query_t6 WHERE id = 2;
GO

SELECT data.query('/root/val') FROM xml_query_t6 WHERE id = 3;
GO

-- ============================================
-- SECTION 8: Unicode content
-- ============================================

SELECT data.query('/root/name') FROM xml_query_t8 WHERE id = 1;
GO

SELECT data.query('/root/name') FROM xml_query_t8 WHERE id = 2;
GO

-- ============================================
-- SECTION 9: Empty and whitespace XML
-- ============================================

-- Empty element
SELECT data.query('/root') FROM xml_query_t10 WHERE id = 1;
GO

-- Whitespace content
SELECT data.query('/root') FROM xml_query_t10 WHERE id = 2;
GO

-- Self-closing element
SELECT data.query('/root') FROM xml_query_t10 WHERE id = 3;
GO

-- Query child of empty element (no match)
SELECT data.query('/root/child') FROM xml_query_t10 WHERE id = 1;
GO


-- ============================================
-- SECTION 10: Mixed content
-- ============================================

-- Element with mixed text and child nodes
SELECT data.query('/root') FROM xml_query_t9 WHERE id = 1;
GO

-- Multiple elements with same name
SELECT data.query('/root/a') FROM xml_query_t9 WHERE id = 2;
GO

-- ============================================
-- SECTION 11: .query() with variable assignment
-- ============================================

DECLARE @x XML = '<root><a>1</a><b>2</b></root>';
DECLARE @result XML;
SET @result = @x.query('/root/a');
SELECT @result;
GO

DECLARE @x XML = '<root><name>John</name></root>';
DECLARE @result XML;
SET @result = @x.query('/root/nonexistent');
SELECT @result;
GO

-- Assign from table column
DECLARE @result XML;
SELECT @result = data.query('/root/name') FROM xml_query_t1 WHERE id = 1;
SELECT @result;
GO

-- ============================================
-- SECTION 12: .query() with NULL input
-- ============================================

-- NULL variable
DECLARE @x XML = NULL;
SELECT @x.query('/root');
GO

-- NULL column
SELECT data.query('/root') FROM xml_query_t1 WHERE id = 4;
GO

-- NULL in expression
SELECT data.query('/root/name') FROM xml_query_t2 WHERE id = 3;
GO

-- ============================================
-- SECTION 13: .query() in WHERE clause
-- ============================================

-- Using .query() result with .exist()
SELECT id FROM xml_query_t1 WHERE data.query('/root/name').exist('/name') = 1;
GO

-- ============================================
-- SECTION 14: .query() combined with other XML methods
-- ============================================

-- .query() then .value()
DECLARE @x XML = '<root><name>John</name><age>30</age></root>';
SELECT @x.query('/root/name').value('(/name)[1]', 'VARCHAR(50)');
GO

-- .query() then .exist()
DECLARE @x XML = '<root><name>John</name></root>';
SELECT @x.query('/root').exist('/root/name');
GO

-- Chained on table column
SELECT data.query('/root').value('(/root/name)[1]', 'VARCHAR(50)') FROM xml_query_t1 WHERE id = 1;
GO

-- ============================================
-- SECTION 15: .query() on FOR XML result
-- ============================================

-- .query() on FOR XML RAW result
SELECT (SELECT 1 AS id, 'John' AS name FOR XML RAW, TYPE).query('/row');
GO

-- .query() on FOR XML PATH result
SELECT (SELECT 1 AS id, 'John' AS name FOR XML PATH('emp'), TYPE).query('/emp/name');
GO

-- .query() on FOR XML with ROOT
SELECT (SELECT 1 AS id, 'John' AS name FOR XML RAW, ROOT('data'), TYPE).query('/data/row');
GO

-- ============================================
-- SECTION 16: .query() in subqueries
-- ============================================

-- Subquery with .query()
SELECT id, (SELECT data.query('/root/name')) AS name_xml
FROM xml_query_t1 WHERE id <= 2;
GO

-- .query() in derived table
SELECT sub.id, sub.name_xml
FROM (SELECT id, data.query('/root/name') AS name_xml FROM xml_query_t1 WHERE id <= 2) sub;
GO

-- ============================================
-- SECTION 17: .query() with CAST/CONVERT
-- ============================================

-- CAST result to VARCHAR
DECLARE @x XML = '<root><name>John</name></root>';
SELECT CAST(@x.query('/root/name') AS VARCHAR(MAX));
GO

-- CAST result to NVARCHAR
DECLARE @x XML = '<root><name>John</name></root>';
SELECT CAST(@x.query('/root/name') AS NVARCHAR(MAX));
GO

-- CONVERT result
DECLARE @x XML = '<root><name>John</name></root>';
SELECT CONVERT(VARCHAR(MAX), @x.query('/root/name'));
GO

-- ============================================
-- SECTION 18: Stored Procedures
-- ============================================

EXEC xml_query_proc1;
GO

EXEC xml_query_proc2 @id = 1;
GO

EXEC xml_query_proc2 @id = 3;
GO

EXEC xml_query_proc2 @id = 4;
GO

EXEC xml_query_proc3;
GO

-- ============================================
-- SECTION 19: Functions
-- ============================================

SELECT dbo.xml_query_func1() AS result;
GO

SELECT dbo.xml_query_func2(1) AS result;
GO

SELECT dbo.xml_query_func2(3) AS result;
GO

SELECT dbo.xml_query_func2(4) AS result;
GO


-- ============================================
-- SECTION 20: Dependent Views
-- ============================================

SELECT * FROM xml_query_dep_view1;
GO

SELECT * FROM xml_query_dep_view2;
GO

-- ============================================
-- SECTION 21: .query() on UDT columns
-- ============================================

-- XML UDT
SELECT data.query('/root/child') FROM xml_query_udt_t1 WHERE id = 1;
GO

-- VARCHAR UDT (should error)
SELECT VarUDTColumn.query('/root/child') FROM xml_query_udt_t2;
GO

-- IMAGE UDT (should error)
SELECT ImageUDTColumn.query('/root/child') FROM xml_query_udt_t2;
GO

-- XML UDT
SELECT XmlUDTColumn.query('/root/child') FROM xml_query_udt_t2;
GO

-- ============================================
-- SECTION 22: Type validation errors
-- ============================================

-- .query() on non-XML type should error
DECLARE @x VARCHAR(100) = '<root><name>John</name></root>';
SELECT @x.query('/root');
GO

-- .query() on INT should error
DECLARE @x INT = 123;
SELECT @x.query('/root');
GO

-- .query() on NVARCHAR should error
DECLARE @x NVARCHAR(100) = '<root><name>John</name></root>';
SELECT @x.query('/root');
GO

-- .query() on BIGINT should error
DECLARE @x BIGINT = 1;
SELECT @x.query('/root');
GO

-- .query() on FLOAT should error
DECLARE @x FLOAT = 1;
SELECT @x.query('/root');
GO

-- .query() on BIT should error
DECLARE @x BIT = 1;
SELECT @x.query('/root');
GO

-- .query() on DECIMAL should error
DECLARE @x DECIMAL = 1;
SELECT @x.query('/root');
GO

-- .query() on TEXT column should error
SELECT data.query('/root/child') FROM xml_query_text_t1;
GO

-- ============================================
-- SECTION 23: QUOTED_IDENTIFIER OFF behavior
-- ============================================

-- .query() should error when QUOTED_IDENTIFIER is OFF
SET QUOTED_IDENTIFIER OFF;
GO

DECLARE @x XML = '<root><name>John</name></root>';
SELECT @x.query('/root/name');
GO

SET QUOTED_IDENTIFIER ON;
GO

-- ============================================
-- SECTION 24: Dependent view created with QUOTED_IDENTIFIER OFF
-- ============================================

SELECT * FROM xml_query_qi_off_view;
GO

-- ============================================
-- SECTION 25: Computed columns
-- ============================================

INSERT INTO xml_query_computed_t1 (id, data) VALUES (1, '<root><child>test</child></root>');
GO

SELECT * FROM xml_query_computed_t1;
GO

DELETE FROM xml_query_computed_t1;
GO

-- ============================================
-- SECTION 26: .query() with various XPath expressions
-- ============================================

-- Self axis
DECLARE @x XML = '<root><a>1</a></root>';
SELECT @x.query('/root/a/self::a');
GO

-- Parent axis (not supported in T-SQL, should error or return empty)
DECLARE @x XML = '<root><a>1</a></root>';
SELECT @x.query('/root/a/..');
GO

-- Wildcard namespace
DECLARE @x XML = '<root xmlns:ns="http://example.com"><ns:child>Hello</ns:child></root>';
SELECT @x.query('/root/*');
GO

-- ============================================
-- SECTION 27: .query() with large XML
-- ============================================

DECLARE @x XML = '<root>' + REPLICATE(CAST('<item>Data</item>' AS VARCHAR(MAX)), 100) + '</root>';
SELECT @x.query('/root/item[1]');
GO

DECLARE @x XML = '<root>' + REPLICATE(CAST('<item>Data</item>' AS VARCHAR(MAX)), 100) + '</root>';
SELECT @x.query('/root/item[last()]');
GO

-- ============================================
-- SECTION 28: .query() with comments in XML
-- ============================================

DECLARE @x XML = '<root><!--comment--><name>John</name></root>';
SELECT @x.query('/root/name');
GO

-- ============================================
-- SECTION 29: .query() with whitespace variations
-- ============================================

DECLARE @x XML = '<root>
    <name>John</name>
    <age>30</age>
</root>';
SELECT @x.query('/root/name');
GO

-- ============================================
-- SECTION 30: .query() with multiple calls on same variable
-- ============================================

DECLARE @x XML = '<root><a>1</a><b>2</b><c>3</c></root>';
SELECT @x.query('/root/a'), @x.query('/root/b'), @x.query('/root/c');
GO

-- ============================================
-- SECTION 31: .query() in CASE expression
-- ============================================

DECLARE @x XML = '<root><name>John</name></root>';
SELECT CASE WHEN @x.exist('/root/name') = 1 THEN @x.query('/root/name') ELSE CAST('<empty/>' AS XML) END;
GO

-- ============================================
-- SECTION 32: .query() with JOIN
-- ============================================

SELECT t1.id, t1.data.query('/root/name') AS name_xml, t2.data.query('/employees/emp[1]') AS first_emp
FROM xml_query_t1 t1
INNER JOIN xml_query_t2 t2 ON t1.id = t2.id
WHERE t1.id <= 2;
GO

-- ============================================
-- SECTION 33: .query() with UNION
-- ============================================

SELECT data.query('/root/name') AS result FROM xml_query_t1 WHERE id = 1
UNION ALL
SELECT data.query('/root/name') AS result FROM xml_query_t1 WHERE id = 2;
GO

-- ============================================
-- SECTION 34: .query() with ORDER BY
-- ============================================

SELECT id, data.query('/root/name') AS name_xml
FROM xml_query_t1
WHERE data IS NOT NULL
ORDER BY id DESC;
GO

-- ============================================
-- SECTION 35: .query() with TOP
-- ============================================

SELECT TOP 2 id, data.query('/root/name') AS name_xml
FROM xml_query_t1
WHERE data IS NOT NULL
ORDER BY id;
GO

-- ============================================
-- SECTION 36: .query() returning empty string vs empty XML
-- ============================================

-- No match returns empty XML
DECLARE @x XML = '<root><a>1</a></root>';
SELECT @x.query('/root/b');
GO

-- Empty element
DECLARE @x XML = '<root><a></a></root>';
SELECT @x.query('/root/a');
GO

-- Self-closing element
DECLARE @x XML = '<root><a/></root>';
SELECT @x.query('/root/a');
GO

-- ============================================
-- SECTION 37: Spaces in method call
-- ============================================

DECLARE @x XML = '<root><name>John</name></root>';
SELECT @x  .  query  ( '/root/name'  );
GO

SELECT data   . query    ('/root/name'  ) FROM xml_query_t1 WHERE id = 1;
GO

SELECT xml_query_t1 .   data   . query    ('/root/name'  ) FROM xml_query_t1 WHERE id = 1;
GO

-- ============================================
-- SECTION 38: .query() called on different expression types
-- ============================================

-- Called on subquery
DECLARE @x XML = '<root><name>John</name></root>';
SELECT (SELECT @x).query('/root/name');
GO

-- Called on CAST expression
SELECT (CAST('<root><name>John</name></root>' AS XML)).query('/root/name');
GO

-- Called on function_call
SELECT dbo.xml_query_func1().query('/a');
GO

-- ============================================
-- SECTION 39: .query() with table.column.query() syntax
-- ============================================

SELECT xml_query_t1.data.query('/root/name') FROM xml_query_t1 WHERE id = 1;
GO

SELECT dbo.xml_query_t1.data.query('/root/name') FROM xml_query_t1 WHERE id = 1;
GO

-- ============================================
-- SECTION 40: NULL xpath argument
-- ============================================

DECLARE @x XML = '<root><name>John</name></root>';
SELECT @x.query(NULL);
GO

DECLARE @x XML = NULL;
SELECT @x.query(NULL);
GO

-- ============================================
-- SECTION 41: ITVF (inline table-valued function)
-- ============================================

SELECT * FROM xml_query_itvf_func();
GO

-- ============================================
-- SECTION 42: XPath functions
-- ============================================

DECLARE @x XML = '<root><a>1</a><b>2</b></root>';
SELECT @x.query('true()');
GO

DECLARE @x XML = '<root><a>1</a><b>2</b></root>';
SELECT @x.query('false()');
GO

-- ============================================
-- SECTION 43: Case insensitivity of .query()
-- ============================================

DECLARE @x XML = '<root><name>John</name></root>';
SELECT @x.QUERY('/root/name');
GO

DECLARE @x XML = '<root><name>John</name></root>';
SELECT @x.Query('/root/name');
GO

DECLARE @x XML = '<root><name>John</name></root>';
SELECT @x.qUeRy('/root/name');
GO

-- ============================================
-- SECTION 44: CDATA sections
-- ============================================

DECLARE @x XML = '<root><child><![CDATA[<data>Hello World</data>]]></child></root>';
SELECT @x.query('/root/child');
GO

-- Empty CDATA
DECLARE @x XML = '<root><![CDATA[]]></root>';
SELECT @x.query('/root');
GO

-- CDATA mixed with regular text
DECLARE @x XML = '<root>before<![CDATA[<inside>]]>after</root>';
SELECT @x.query('/root');
GO

-- ============================================
-- SECTION 45: XML fragments
-- ============================================

DECLARE @x XML = '<a>1</a><b>2</b>';
SELECT @x.query('/a');
GO

-- ============================================
-- SECTION 46: XML declaration with encoding
-- ============================================

DECLARE @x XML = N'<?xml version="1.0" encoding="UTF-8"?><root><name>Test</name></root>';
SELECT @x.query('/root/name');
GO

-- ============================================
-- SECTION 47: Internal entities (DOCTYPE)
-- ============================================

DECLARE @x XML = '<?xml version="1.0"?>
<!DOCTYPE root [
<!ENTITY internal "Hello World">
]>
<root>&internal;</root>';
SELECT @x.query('/root');
GO

-- ============================================
-- SECTION 48: Variable in XPath expression
-- ============================================

DECLARE @x XML = '<root><child1>Value1</child1><child2>Value2</child2></root>';
DECLARE @element VARCHAR(20) = 'child1';
SELECT @x.query(CONCAT('/root/', @element));
GO

-- ============================================
-- SECTION 49: XML Digital Signatures
-- ============================================

DECLARE @x XML = '<?xml version="1.0" encoding="UTF-8"?>
<root>
  <child>Hello World</child>
  <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
    <!-- Digital Signature details -->
  </Signature>
</root>';
SELECT @x.query('/root/child');
GO

-- ============================================
-- SECTION 50: Invalid XML Path value
-- ============================================

DECLARE @x XML = '<root><child>Hello</child></root>';
SELECT @x.query('///invalid[[[path');
GO

-- ============================================
-- SECTION 51: GROUP BY with .query()
-- ============================================

SELECT data.query('/root/name').value('(/name)[1]', 'VARCHAR(50)') AS name_val, COUNT(*) AS cnt
FROM xml_query_t1
WHERE data IS NOT NULL
GROUP BY data.query('/root/name').value('(/name)[1]', 'VARCHAR(50)')
ORDER BY name_val;
GO


-- ============================================
-- SECTION 52: .query() argument count validation
-- ============================================
-- .query() with no arguments (should error)
DECLARE @x XML = '<root><name>John</name></root>';
SELECT @x.query();
GO

-- .query() with too many arguments (should error)
DECLARE @x XML = '<root><name>John</name></root>';
SELECT @x.query('/root/name', 'extra');
GO


-- ============================================
-- SECTION 53: Malformed XML inputs
-- ============================================
-- 1. Unclosed tag
DECLARE @x XML = '<unclosed';
SELECT @x.query('/r');
GO

-- 2. Mismatched tags
DECLARE @x XML = '<a></b>';
SELECT @x.query('/a');
GO

-- 3. Plain text (no elements)
DECLARE @x XML = 'hello world';
SELECT @x.query('/');
GO

-- 4. Empty string
DECLARE @x XML = '';
SELECT @x.query('/');
GO

DECLARE @x XML = '   '
SELECT @x.query('/Root/row') AS c
GO

DECLARE @x XML = NULl
SELECT @x.query('/Root/row') AS c
GO

-- Empty Path query
DECLARE @xml XML = ''
SELECT @xml.query('')
GO

DECLARE @xml XML = '<Root><row><name>James</name></row></Root>'
SELECT @xml.query('')
GO

-- 5. Bare ampersand (not an entity)
DECLARE @x XML = '<r>a & b</r>';
SELECT @x.query('/r');
GO

-- 6. Invalid name (starts with digit)
DECLARE @x XML = '<1bad>x</1bad>';
SELECT @x.query('/');
GO

-- 7. Direct call to bbf_xmlquery with malformed CAST (unclosed tag)
SELECT sys.bbf_xmlquery('/r', CAST('<broken' AS XML));
GO

-- 8. Direct call to bbf_xmlquery with mismatched tags via CAST
SELECT sys.bbf_xmlquery('/r', CAST('<a><b></a>' AS XML));
GO

-- 9. Direct call with non-xml type (VARCHAR)
DECLARE @v VARCHAR(20) = '<r/>';
SELECT sys.bbf_xmlquery('/r', @v);
GO

-- 10. Direct call with non-xml type (INT)
SELECT sys.bbf_xmlquery('/r', 42);
GO
