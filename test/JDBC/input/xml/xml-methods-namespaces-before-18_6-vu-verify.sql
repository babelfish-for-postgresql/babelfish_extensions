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

-- ============================================
-- SECTION 19: Special characters in WITH XMLNAMESPACES URIs
-- ============================================

-- 19.1 Double-quote in URI (array-literal escaping) -> empty
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/"q"' AS p)
SELECT @x.query('/root/p:item');
GO

-- 19.2 Backslash in URI (array-literal escaping) -> empty
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/a\b' AS p)
SELECT @x.query('/root/p:item');
GO

-- 19.3 Single-quote in URI (escaped as '' in T-SQL), resolves end-to-end -> val
DECLARE @x XML = '<root xmlns:ns1="http://example.com/it''s"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/it''s' AS ns1)
SELECT @x.value('(/root/ns1:item)[1]', 'varchar(50)');
GO

-- 19.4 Combined double-quote and backslash in URI (array-literal escaping) -> 0
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/"a"\b' AS p)
SELECT @x.exist('/root/p:item');
GO

-- 19.5 Limitation: a document whose own namespace URI contains a character that
-- is illegal in an RFC 3986 URI ('\' or '"') is rejected by PostgreSQL's xpath()
-- (libxml2 URI validation). SQL Server accepts it and returns the element.
DECLARE @x XML = '<root xmlns:ns1="http://example.com/a\b"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/a\b' AS ns1)
SELECT @x.query('/root/ns1:item');
GO

-- 19.6 Same limitation with a double-quote in the document namespace URI
DECLARE @x XML = '<root xmlns:ns1="http://example.com/&quot;q&quot;"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/"q"' AS ns1)
SELECT @x.query('/root/ns1:item');
GO
-- ============================================
-- SECTION 20: .nodes() with prefixed XPath
-- ============================================
-- 20.1 Basic .nodes() with a declared prefix on a variable
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val1</ns1:item><ns1:item>val2</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT n.c.value('.', 'varchar(20)') AS v FROM @x.nodes('/root/ns1:item') AS n(c)
ORDER BY 1;
GO
-- 20.2 Unprefixed path when the element is prefixed -> 0 rows
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT COUNT(*) AS cnt FROM @x.nodes('/root/item') AS n(c);
GO
-- 20.3 Multiple prefixes declared, applied to different paths
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1" xmlns:ns2="http://example.com/ns2"><ns1:a>10</ns1:a><ns2:b>20</ns2:b></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1, 'http://example.com/ns2' AS ns2)
SELECT n.c.value('.', 'int') AS a_val FROM @x.nodes('/root/ns1:a') AS n(c);
GO
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1" xmlns:ns2="http://example.com/ns2"><ns1:a>10</ns1:a><ns2:b>20</ns2:b></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1, 'http://example.com/ns2' AS ns2)
SELECT n.c.value('.', 'int') AS b_val FROM @x.nodes('/root/ns2:b') AS n(c);
GO
-- 20.4 Undeclared prefix without WITH XMLNAMESPACES -> error
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>x</ns1:item></root>';
SELECT n.c.value('.', 'varchar(20)') FROM @x.nodes('/root/ns1:item') AS n(c);
GO
-- 20.5 Attribute (@id) of each shredded node
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item id="1">a</ns1:item><ns1:item id="2">b</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT n.c.value('@id', 'int') AS id, n.c.value('.', 'varchar(20)') AS v
FROM @x.nodes('/root/ns1:item') AS n(c)
ORDER BY id;
GO
-- 20.6 .nodes() on a table column
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT src.id, n.c.value('.', 'varchar(20)') AS v
FROM xmlns_methods_t1 src CROSS APPLY src.data.nodes('/root/ns1:item') AS n(c)
WHERE src.id IN (1, 5)
ORDER BY src.id, v;
GO
-- 20.7 Count shredded rows per document (GROUP BY on the outer table)
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT src.id, COUNT(*) AS cnt
FROM xmlns_methods_t1 src CROSS APPLY src.data.nodes('/root/ns1:item') AS n(c)
GROUP BY src.id
ORDER BY src.id;
GO
-- 20.8 .nodes() with .query() projecting each match as XML
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val1</ns1:item><ns1:item>val2</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT n.c.query('.') AS item_xml FROM @x.nodes('/root/ns1:item') AS n(c);
GO
-- 20.9 NULL XML -> 0 rows
DECLARE @x XML = NULL;
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT COUNT(*) FROM @x.nodes('/root/ns1:item') AS n(c);
GO
-- 20.10 Empty XML -> 0 rows
DECLARE @x XML = '';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT COUNT(*) FROM @x.nodes('/root/ns1:item') AS n(c);
GO
-- 20.11 Positional access - (/root/ns:item)[1] returns only the first shredded node
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val1</ns1:item><ns1:item>val2</ns1:item><ns1:item>val3</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT n.c.value('.', 'varchar(20)') AS v FROM @x.nodes('(/root/ns1:item)[1]') AS n(c);
GO
-- 20.12 Attribute predicate in .nodes() xpath filters shredded rows
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item id="1">a</ns1:item><ns1:item id="2">b</ns1:item><ns1:item id="3">c</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT n.c.value('.', 'varchar(20)') AS v FROM @x.nodes('/root/ns1:item[@id="1"]') AS n(c);
GO
-- 20.13 Wildcard xpath - all children under /root/
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:a>1</ns1:a><ns1:b>2</ns1:b><ns1:c>3</ns1:c></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT n.c.value('local-name(.)', 'varchar(20)') AS nm FROM @x.nodes('/root/*') AS n(c) ORDER BY 1;
GO
-- 20.14 XPath with no match returns 0 rows
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT COUNT(*) AS cnt FROM @x.nodes('/root/ns1:missing') AS n(c);
GO
-- 20.15 Deep nested path resolves each level via declared prefix
DECLARE @x XML = '<a xmlns:p="http://p.example"><p:b><p:c><p:d>deep</p:d></p:c></p:b></a>';
WITH XMLNAMESPACES('http://p.example' AS p)
SELECT n.c.value('.','varchar(20)') AS v FROM @x.nodes('/a/p:b/p:c/p:d') AS n(c);
GO
-- 20.16 Descendant axis (//) collects prefixed elements at any depth
DECLARE @x XML = '<r xmlns:p="http://p.example"><p:g><p:i>x</p:i></p:g><p:g><p:i>y</p:i><p:i>z</p:i></p:g></r>';
WITH XMLNAMESPACES('http://p.example' AS p)
SELECT n.c.value('.','varchar(20)') AS v FROM @x.nodes('//p:i') AS n(c) ORDER BY 1;
GO
-- 20.17 last() predicate returns the final matching node
DECLARE @x XML = '<r xmlns:p="http://p.example"><p:i>a</p:i><p:i>b</p:i><p:i>c</p:i></r>';
WITH XMLNAMESPACES('http://p.example' AS p)
SELECT n.c.value('.','varchar(20)') AS v FROM @x.nodes('/r/p:i[last()]') AS n(c);
GO
-- 20.18 Multiple attribute predicates chained together
DECLARE @x XML = '<r xmlns:p="http://p.example"><p:i a="1" b="x">A</p:i><p:i a="2" b="x">B</p:i><p:i a="1" b="y">C</p:i></r>';
WITH XMLNAMESPACES('http://p.example' AS p)
SELECT n.c.value('.','varchar(20)') AS v FROM @x.nodes('/r/p:i[@a="1"][@b="x"]') AS n(c);
GO
-- 20.19 text() predicate filters by element string value
DECLARE @x XML = '<r xmlns:p="http://p.example"><p:i>foo</p:i><p:i>bar</p:i></r>';
WITH XMLNAMESPACES('http://p.example' AS p)
SELECT n.c.value('.','varchar(20)') AS v FROM @x.nodes('/r/p:i[text()="foo"]') AS n(c);
GO
-- 20.20 CDATA content is returned as plain text
DECLARE @x XML = '<r xmlns:p="http://p.example"><p:i><![CDATA[<script>alert(1)</script>]]></p:i></r>';
WITH XMLNAMESPACES('http://p.example' AS p)
SELECT n.c.value('.','varchar(60)') AS v FROM @x.nodes('/r/p:i') AS n(c);
GO
-- 20.21 CAST(varchar AS XML).nodes() with namespace-aware XPath
DECLARE @s VARCHAR(200) = '<r xmlns:p="http://p.example"><p:i>k1</p:i><p:i>k2</p:i></r>';
WITH XMLNAMESPACES('http://p.example' AS p)
SELECT n.c.value('.','varchar(20)') AS v FROM (SELECT CAST(@s AS XML)) AS d(x) CROSS APPLY d.x.nodes('/r/p:i') AS n(c) ORDER BY 1;
GO
-- 20.22 CTE built with WITH XMLNAMESPACES, .nodes() in the CTE body
DECLARE @x XML = '<r xmlns:p="http://p.example"><p:i>l1</p:i><p:i>l2</p:i></r>';
WITH XMLNAMESPACES('http://p.example' AS p),
     shredded AS (SELECT n.c.value('.','varchar(20)') AS v FROM @x.nodes('/r/p:i') AS n(c))
SELECT * FROM shredded ORDER BY 1;
GO
-- 20.23 Aggregate (SUM/MIN/MAX) over shredded rows
DECLARE @x XML = '<r xmlns:p="http://p.example"><p:i>10</p:i><p:i>20</p:i><p:i>30</p:i></r>';
WITH XMLNAMESPACES('http://p.example' AS p)
SELECT SUM(n.c.value('.','int')) AS total, MIN(n.c.value('.','int')) AS mn, MAX(n.c.value('.','int')) AS mx
FROM @x.nodes('/r/p:i') AS n(c);
GO
-- 20.24 Inner element re-declares 'p' to a different URI; outer 'p' still resolves outer bindings
DECLARE @x XML = '<r xmlns:p="http://p.example"><p:i xmlns:p="http://other.example">inner</p:i><p:i>outer</p:i></r>';
WITH XMLNAMESPACES('http://p.example' AS p)
SELECT n.c.value('.','varchar(20)') AS v FROM @x.nodes('/r/p:i') AS n(c);
GO
