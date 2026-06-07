-- ============================================
-- WITH XMLNAMESPACES + .query() / .value() / .exist()
-- ============================================

-- ============================================
-- SECTION 1: .query() with prefixed XPath
-- ============================================

-- 1.1 Query a prefixed element using a declared prefix
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.query('/root/ns1:item');
GO

-- 1.2 Query unprefixed name where XML element is prefixed -> empty
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.query('/root/item');
GO

-- 1.3 Query with multiple prefixes used in different paths
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1" xmlns:ns2="http://example.com/ns2"><ns1:a>1</ns1:a><ns2:b>2</ns2:b></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1, 'http://example.com/ns2' AS ns2)
SELECT @x.query('/root/ns1:a'), @x.query('/root/ns2:b');
GO

-- 1.4 Query repeated prefixed elements
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>a</ns1:item><ns1:item>b</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.query('/root/ns1:item');
GO

-- 1.5 Query positional access with prefix
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>a</ns1:item><ns1:item>b</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.query('/root/ns1:item[1]'), @x.query('/root/ns1:item[2]');
GO

-- 1.6 Query with attribute predicate using prefix
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:book ns1:id="1"><ns1:title>SQL</ns1:title></ns1:book><ns1:book ns1:id="2"><ns1:title>XML</ns1:title></ns1:book></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.query('/root/ns1:book[@ns1:id="2"]/ns1:title');
GO

-- 1.7 Query NULL XML
DECLARE @x XML = NULL;
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.query('/root/ns1:item');
GO

-- 1.8 Query against table column
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT id, data.query('/root/ns1:item')
FROM xmlns_methods_t1 WHERE id IN (1, 2)
ORDER BY id;
GO

-- 1.9 Query with no match returns empty
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.query('/root/ns1:nonexistent');
GO

-- 1.10 Wildcard with prefix
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:a>1</ns1:a><ns1:b>2</ns1:b></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.query('/root/ns1:*');
GO

-- ============================================
-- SECTION 2: .exist() with prefixed XPath
-- ============================================

-- 2.1 Exist returns 1 when prefixed match found
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.exist('/root/ns1:item');
GO

-- 2.2 Exist returns 0 when prefixed name doesn't match
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.exist('/root/ns1:other');
GO

-- 2.3 Exist with attribute predicate
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><item ns1:attr="value"/></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.exist('/root/item/@ns1:attr');
GO

-- 2.4 Exist with attribute predicate (negative)
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><item/></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.exist('/root/item/@ns1:attr');
GO

-- 2.5 Exist on NULL
DECLARE @x XML = NULL;
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.exist('/root/ns1:item');
GO

-- 2.6 Exist with multiple namespaces
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1" xmlns:ns2="http://example.com/ns2"><ns1:a>1</ns1:a></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1, 'http://example.com/ns2' AS ns2)
SELECT @x.exist('/root/ns1:a'), @x.exist('/root/ns2:b');
GO

-- ============================================
-- SECTION 3: .value() with prefixed XPath
-- ============================================

-- 3.1 Value of prefixed element
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.value('(/root/ns1:item)[1]', 'varchar(50)');
GO

-- 3.2 Value cast to int
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>42</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.value('(/root/ns1:item)[1]', 'int');
GO

-- 3.3 Value of attribute with prefix
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><item ns1:attr="value"/></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.value('(/root/item/@ns1:attr)[1]', 'varchar(50)');
GO

-- 3.4 Value when no match - returns NULL
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.value('(/root/ns1:item)[1]', 'varchar(50)');
GO

-- 3.5 Value of multiple matches selects positional
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>a</ns1:item><ns1:item>b</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.value('(/root/ns1:item)[1]', 'varchar(10)'),
       @x.value('(/root/ns1:item)[2]', 'varchar(10)');
GO

-- 3.6 Value on NULL XML
DECLARE @x XML = NULL;
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.value('(/root/ns1:item)[1]', 'varchar(50)');
GO

-- 3.7 Value with multiple namespaces
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1" xmlns:ns2="http://example.com/ns2"><ns1:a>10</ns1:a><ns2:b>20</ns2:b></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1, 'http://example.com/ns2' AS ns2)
SELECT @x.value('(/root/ns1:a)[1]', 'int'),
       @x.value('(/root/ns2:b)[1]', 'int');
GO

-- ============================================
-- SECTION 4: Methods on table columns with namespaces
-- ============================================

-- 4.1 .query on column
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT id, data.query('/root/ns1:item')
FROM xmlns_methods_t1 WHERE id = 1;
GO

-- 4.2 .value on column
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT id, data.value('(/root/ns1:item)[1]', 'varchar(50)')
FROM xmlns_methods_t1 WHERE id IN (1, 5);
GO

-- 4.3 .exist on column
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT id, data.exist('/root/ns1:item')
FROM xmlns_methods_t1 WHERE id <= 5
ORDER BY id;
GO

-- 4.4 .query on view
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT id, data.query('/root/ns1:item')
FROM xmlns_methods_view1 WHERE id = 1;
GO

-- ============================================
-- SECTION 5: Complex namespace cases
-- ============================================

-- 5.1 Same prefix used in multiple statements (no carry-over)
DECLARE @x XML = '<root xmlns:p="http://uri1"><p:a>1</p:a></root>';
WITH XMLNAMESPACES('http://uri1' AS p)
SELECT @x.value('(/root/p:a)[1]', 'int');
GO

-- 5.2 Prefix in XML differs from prefix in WITH XMLNAMESPACES (matching by URI)
DECLARE @x XML = '<root xmlns:foo="http://example.com/ns1"><foo:item>val</foo:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS bar)
SELECT @x.value('(/root/bar:item)[1]', 'varchar(50)');
GO

-- 5.3 Predicate using prefixed attribute
WITH XMLNAMESPACES('http://example.com/products' AS p)
SELECT data.query('/catalog/p:book[@p:id="2"]/p:title')
FROM xmlns_methods_t2 WHERE id = 1;
GO

-- 5.4 Numeric predicate on prefixed element
WITH XMLNAMESPACES('http://example.com/products' AS p)
SELECT data.query('/catalog/p:book[p:price>30]/p:title')
FROM xmlns_methods_t2 WHERE id = 1;
GO

-- 5.5 Wildcard with prefix on table column
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT data.query('/root/ns1:*')
FROM xmlns_methods_t1 WHERE id = 1;
GO

-- 5.6 .query then .value chained on result
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>hello</ns1:item></root>';
DECLARE @r XML;
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @r = @x.query('/root/ns1:item');
SELECT @r;
GO

-- ============================================
-- SECTION 6: NULL XML behaviors
-- ============================================

-- 6.1 Query NULL row (with namespaces)
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT data.query('/root/ns1:item') FROM xmlns_methods_t1 WHERE id = 4;
GO

-- 6.2 Value on NULL row (with namespaces)
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT data.value('(/root/ns1:item)[1]', 'varchar(50)') FROM xmlns_methods_t1 WHERE id = 4;
GO

-- 6.3 Exist on NULL row (with namespaces)
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT data.exist('/root/ns1:item') FROM xmlns_methods_t1 WHERE id = 4;
GO

-- ============================================
-- SECTION 7: Validation with same rules as FOR XML
-- ============================================

-- 7.1 Duplicate prefix
DECLARE @x XML = '<root/>';
WITH XMLNAMESPACES('http://a' AS p, 'http://b' AS p)
SELECT @x.query('/root');
GO

-- 7.2 Empty URI
DECLARE @x XML = '<root/>';
WITH XMLNAMESPACES('' AS p)
SELECT @x.query('/root');
GO

-- 7.3 Reserved xmlns prefix
DECLARE @x XML = '<root/>';
WITH XMLNAMESPACES('http://a' AS xmlns)
SELECT @x.query('/root');
GO

-- 7.4 xml prefix with wrong URI
DECLARE @x XML = '<root/>';
WITH XMLNAMESPACES('http://wrong' AS xml)
SELECT @x.query('/root');
GO

-- ============================================
-- SECTION 8: Variable assignment with namespaces
-- ============================================

-- 8.1 .query() result assigned to XML variable
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
DECLARE @r XML;
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @r = @x.query('/root/ns1:item');
SELECT @r;
GO

-- 8.2 .value() result into varchar
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>hello</ns1:item></root>';
DECLARE @s VARCHAR(50);
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @s = @x.value('(/root/ns1:item)[1]', 'varchar(50)');
SELECT @s;
GO

-- 8.3 .exist() into bit
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item/></root>';
DECLARE @b BIT;
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @b = @x.exist('/root/ns1:item');
SELECT @b;
GO

-- ============================================
-- SECTION 9: Methods in WHERE clause
-- ============================================

-- 9.1 .exist() in WHERE
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT id FROM xmlns_methods_t1 WHERE data.exist('/root/ns1:item') = 1
ORDER BY id;
GO

-- 9.2 .value() in WHERE
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT id FROM xmlns_methods_t1 WHERE data.value('(/root/ns1:item)[1]', 'varchar(50)') = 'val1'
ORDER BY id;
GO

-- ============================================
-- SECTION 10: Methods in CASE expression
-- ============================================

-- 10.1 CASE with .exist()
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT id,
       CASE WHEN data.exist('/root/ns1:item') = 1 THEN 'has-item' ELSE 'no-item' END AS Tag
FROM xmlns_methods_t1 WHERE id <= 3
ORDER BY id;
GO

-- ============================================
-- SECTION 11: Methods with JOIN
-- ============================================

-- 11.1 JOIN on .value() result
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT t1.id, t1.data.value('(/root/ns1:item)[1]', 'varchar(50)') AS V
FROM xmlns_methods_t1 t1 JOIN xmlns_methods_view1 v ON t1.id = v.id
WHERE t1.id IN (1, 5)
ORDER BY t1.id;
GO

-- ============================================
-- SECTION 12: Methods with ORDER BY / TOP
-- ============================================

-- 12.1 ORDER BY .value()
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT id, data.value('(/root/ns1:item)[1]', 'varchar(50)') AS V
FROM xmlns_methods_t1 WHERE id IN (1, 5)
ORDER BY data.value('(/root/ns1:item)[1]', 'varchar(50)');
GO

-- 12.2 TOP with .query()
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT TOP 1 id, data.query('/root/ns1:item')
FROM xmlns_methods_t1 WHERE id <= 5
ORDER BY id;
GO

-- ============================================
-- SECTION 13: Methods on views
-- ============================================

-- 13.1 .query() on view
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT id, data.query('/root/ns1:item')
FROM xmlns_methods_view1 WHERE id <= 2 ORDER BY id;
GO

-- 13.2 .exist() in WHERE on view
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT id FROM xmlns_methods_view1
WHERE data.exist('/root/ns1:item') = 1 ORDER BY id;
GO

-- ============================================
-- SECTION 14: XML with comments
-- ============================================

-- 14.1 .query() ignores comments outside target
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT data.query('/root/ns1:item')
FROM xmlns_methods_comments WHERE id = 1;
GO

-- 14.2 .value() with inline comment in value
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT data.value('(/root/ns1:item)[1]', 'varchar(50)')
FROM xmlns_methods_comments WHERE id = 2;
GO

-- ============================================
-- SECTION 15: Spaces and case in method calls
-- ============================================

-- 15.1 Spaces around .query()
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>v</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x  .  query('/root/ns1:item');
GO

-- 15.2 Spaces around .value()
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>v</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x . value('(/root/ns1:item)[1]', 'varchar(50)');
GO

-- ============================================
-- SECTION 16: Predicates with prefixed attributes (richer)
-- ============================================

-- 16.1 Attribute predicate with numeric comparison
WITH XMLNAMESPACES('http://example.com/products' AS p)
SELECT data.query('/order/p:item[@p:price>20]') FROM xmlns_methods_orders WHERE id = 1;
GO

-- 16.2 Multiple prefixed attribute predicates
WITH XMLNAMESPACES('http://example.com/products' AS p)
SELECT data.query('/order/p:item[@p:price>20 and @p:price<40]') FROM xmlns_methods_orders WHERE id = 1;
GO

-- 16.3 Empty XML root with .query() prefix path
WITH XMLNAMESPACES('http://example.com/products' AS p)
SELECT data.query('/order/p:item') FROM xmlns_methods_orders WHERE id = 3;
GO

-- ============================================
-- SECTION 17: Multiple chained method calls
-- ============================================

-- 17.1 .query() result then .value()
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val1</ns1:item><ns1:item>val2</ns1:item></root>';
DECLARE @r XML;
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @r = @x.query('/root/ns1:item[1]');
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @r.value('(/ns1:item)[1]', 'varchar(50)');
GO

-- ============================================
-- SECTION 18: Result from FOR XML chained
-- ============================================

-- 18.1 FOR XML result fed to .query() under namespace
DECLARE @x XML;
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x = (SELECT 1 AS [ns1:a], 'v' AS [ns1:b] FOR XML PATH('ns1:Row'), TYPE);
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.query('/ns1:Row/ns1:a');
GO
