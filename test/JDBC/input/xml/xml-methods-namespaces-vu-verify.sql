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
-- 15.3 Spaces around .nodes(). The rewrite trims the trailing dot off the
-- operand text by position before appending the namespace array argument, so
-- the spaced form has to produce the same shredded rows as the unspaced one.
DECLARE @x XML = '<r xmlns:p="http://p.example"><p:i>a</p:i><p:i>b</p:i></r>';
WITH XMLNAMESPACES('http://p.example' AS p)
SELECT n.c.value('.', 'varchar(10)') AS v FROM @x . nodes('/r/p:i') AS n(c) ORDER BY 1;
GO
-- 15.4 Same with the method on the shredded column also spaced
DECLARE @x XML = '<r xmlns:p="http://p.example"><p:i>a</p:i><p:i>b</p:i></r>';
WITH XMLNAMESPACES('http://p.example' AS p)
SELECT n.c . value('.', 'varchar(10)') AS v FROM @x . nodes('/r/p:i') AS n(c) ORDER BY 1;
GO
-- 15.5 A newline between the operand and the dot
DECLARE @x XML = '<r xmlns:p="http://p.example"><p:i>a</p:i><p:i>b</p:i></r>';
WITH XMLNAMESPACES('http://p.example' AS p)
SELECT n.c.value('.', 'varchar(10)') AS v
FROM @x
   . nodes('/r/p:i') AS n(c) ORDER BY 1;
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
-- 20.4 Undeclared prefix without WITH XMLNAMESPACES -> error (T-SQL 2229)
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
-- ============================================
-- SECTION 21: One WITH XMLNAMESPACES shared across multiple method calls
-- Multiple XML method calls in a single statement must all see the same
-- declared namespace context (each rewrite reads the same array literal).
-- ============================================
-- 21.1 Two .value() calls and one .exist(), all using the same declared prefix
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:a>10</ns1:a><ns1:b>20</ns1:b></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.value('(/root/ns1:a)[1]', 'int') AS a,
       @x.value('(/root/ns1:b)[1]', 'int') AS b,
       @x.exist('/root/ns1:a') AS has_a;
GO
-- ============================================
-- SECTION 22: A prefix literally named 'default' in an XML method XPath
-- 'uri' AS [default] declares an ordinary prefix named "default" (bracketed
-- because it is a reserved word), distinct from the DEFAULT keyword form. It
-- resolves in an XPath like any other prefix.
-- ============================================
-- 22.1 [default] prefix used in a .value() XPath
DECLARE @x XML = '<r xmlns:d="http://example.com/dflt"><d:v>hit</d:v></r>';
WITH XMLNAMESPACES('http://example.com/dflt' AS [default])
SELECT @x.value('(/r/default:v)[1]', 'varchar(10)') AS resolved;
GO
-- ============================================
-- SECTION 23: National-character (N'...') URI literals in XML methods
-- The STRING lexer rule allows an optional N prefix on the URI literal. It is
-- literal decoration only and must be stripped before the namespace array is
-- built, otherwise the prefix fails to resolve.
-- ============================================
-- 23.1 N-prefixed URI resolves in a .value() XPath
DECLARE @x XML = '<r xmlns:ns1="http://example.com/ns1"><ns1:v>hit</ns1:v></r>';
WITH XMLNAMESPACES(N'http://example.com/ns1' AS ns1)
SELECT @x.value('(/r/ns1:v)[1]', 'varchar(10)') AS resolved;
GO
-- 23.2 N-prefixed URI with .exist() and .query()
DECLARE @x XML = '<r xmlns:ns1="http://example.com/ns1"><ns1:v>hit</ns1:v></r>';
WITH XMLNAMESPACES(N'http://example.com/ns1' AS ns1)
SELECT @x.exist('/r/ns1:v') AS has_v, @x.query('/r/ns1:v') AS frag;
GO
-- ============================================
-- SECTION 24: Empty namespace prefix in XML methods
-- [] and "" strip to an empty prefix. T-SQL rejects it with error 1038
-- followed by 6877. Babelfish raises only the 1038 text, as error 33557097.
-- ============================================
-- 24.1 .query()
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS [])
SELECT @x.query('/root');
GO
-- 24.2 .value()
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS [])
SELECT @x.value('(/root/*)[1]', 'varchar(10)');
GO
-- 24.3 .exist()
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS [])
SELECT @x.exist('/root/item');
GO
-- 24.4 .nodes()
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS [])
SELECT n.c.value('.', 'varchar(10)') FROM @x.nodes('/root/*') AS n(c);
GO
-- 24.5 AS "" with QUOTED_IDENTIFIER ON
SET QUOTED_IDENTIFIER ON;
GO
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('http://example.com/ns1' AS "")
SELECT @x.query('/root');
GO
-- ============================================
-- SECTION 25: Whitespace in a namespace URI in XML methods
-- The URI is collapsed as xs:anyURI before it is used (see forxml-namespaces
-- SECTION 38): TAB, LF and CR become a space, runs become one space and both
-- ends are trimmed. A whitespace-only URI is empty (T-SQL 6874, reported here
-- as 33557097). TAB and LF are built with CHAR() in dynamic SQL.
-- ============================================
-- 25.1 .exist() with three spaces (T-SQL 6874)
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('   ' AS ns1)
SELECT @x.exist('/root');
GO
-- 25.2 .query() with DEFAULT three spaces (T-SQL 6874)
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES(DEFAULT '   ')
SELECT @x.query('/root');
GO
-- 25.3 .value() with TAB only (T-SQL 6874)
DECLARE @s NVARCHAR(MAX) = N'DECLARE @x XML = ''<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>''; WITH XMLNAMESPACES(''' + CHAR(9) + N''' AS ns1) SELECT @x.value(''(/root/*)[1]'', ''varchar(10)'')';
EXEC(@s);
GO
-- 25.4 A padded clause URI matches the unpadded document URI
DECLARE @x XML = '<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>';
WITH XMLNAMESPACES('  http://example.com/ns1  ' AS p)
SELECT @x.exist('/root/p:item');
GO
-- 25.5 A TAB before and an LF after the clause URI are trimmed
DECLARE @s NVARCHAR(MAX) = N'DECLARE @x XML = ''<root xmlns:ns1="http://example.com/ns1"><ns1:item>val</ns1:item></root>''; WITH XMLNAMESPACES(''' + CHAR(9) + N'http://example.com/ns1' + CHAR(10) + N''' AS ns1) SELECT @x.value(''(/root/ns1:item)[1]'', ''varchar(10)'')';
EXEC(@s);
GO
-- 25.6 A TAB inside the clause URI becomes a space. T-SQL collapses the
-- document's namespace URI as well and returns 1. Babelfish cannot evaluate
-- the document at all: PostgreSQL's xpath() rejects a document whose
-- namespace URI contains whitespace ("could not parse XML document"), with or
-- without a clause.
DECLARE @s NVARCHAR(MAX) = N'DECLARE @x XML = ''<r xmlns:d="urn:a b"><d:x>8</d:x></r>''; WITH XMLNAMESPACES(''urn:a' + CHAR(9) + N'b'' AS p) SELECT @x.exist(''/r/p:x'')';
EXEC(@s);
GO
-- ============================================
-- SECTION 26: Prefixed relative paths on .nodes() output
-- Under a .nodes() context each relative step is prefixed with the context
-- node's path. A QName (e:name, @e:id) or an axis step (child::e:name) is one
-- step, so the path goes in front of it once. The table is created here
-- rather than in the prepare file and is used again by SECTION 27.
-- ============================================
CREATE TABLE xmlns_methods_nsdata (id INT, data XML);
GO
INSERT INTO xmlns_methods_nsdata VALUES (1, '<root xmlns:ns="http://example.com/ns1"><ns:child>Hello</ns:child><ns:child>World</ns:child></root>');
INSERT INTO xmlns_methods_nsdata VALUES (3, '<e:employees xmlns:e="urn:emp"><e:emp e:id="1"><e:name>Alice</e:name></e:emp></e:employees>');
INSERT INTO xmlns_methods_nsdata VALUES (4, '<e:employees xmlns:e="urn:emp"><e:x>X1</e:x><e:emp e:id="1" plain="p1"><e:name>Alice</e:name><e:info><e:sub>S1</e:sub></e:info></e:emp><e:emp e:id="2" plain="p2"><e:name>Bob</e:name><e:info><e:sub>S2</e:sub></e:info></e:emp></e:employees>');
INSERT INTO xmlns_methods_nsdata VALUES (5, '<employees><x>X1</x><emp id="1"><name>Alice</name><info><sub>S1</sub></info></emp><emp id="2"><name>Bob</name><info><sub>S2</sub></info></emp></employees>');
GO
-- 26.1 Relative prefixed element and attribute with all four methods
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('(e:name)[1]', 'VARCHAR(50)') AS v_name, n.c.value('@e:id', 'INT') AS v_id, n.c.exist('e:name') AS ex, n.c.query('e:name') AS q
FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/e:employees/e:emp') AS n(c) WHERE t.id = 3;
GO
-- 26.2 Prefixed wildcard e:*
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('count(e:*)', 'INT') FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/e:employees/e:emp') AS n(c) WHERE t.id = 4 ORDER BY 1;
GO
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('local-name((e:*)[1])', 'VARCHAR(20)') FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/e:employees/e:emp') AS n(c) WHERE t.id = 4 ORDER BY 1;
GO
-- 26.3 Prefixed attribute wildcard @e:*: only the e:id attribute is counted
-- (T-SQL 1)
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('count(@e:*)', 'INT') FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/e:employees/e:emp') AS n(c) WHERE t.id = 4 ORDER BY 1;
GO
-- 26.4 child:: axis with a prefixed name
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('(child::e:name)[1]', 'VARCHAR(20)') FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/e:employees/e:emp') AS n(c) WHERE t.id = 4 ORDER BY 1;
GO
-- 26.5 ./e:name
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('(./e:name)[1]', 'VARCHAR(20)') FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/e:employees/e:emp') AS n(c) WHERE t.id = 4 ORDER BY 1;
GO
-- 26.6 ../e:x
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('(../e:x)[1]', 'VARCHAR(20)') FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/e:employees/e:emp') AS n(c) WHERE t.id = 4 ORDER BY 1;
GO
-- 26.7 Two prefixed steps, e:info/e:sub
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('(e:info/e:sub)[1]', 'VARCHAR(20)') FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/e:employees/e:emp') AS n(c) WHERE t.id = 4 ORDER BY 1;
GO
-- 26.8 Prefixed step with a prefixed attribute predicate
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('(e:emp[@e:id="1"]/e:name)[1]', 'VARCHAR(20)') AS id1, n.c.value('(e:emp[@e:id="2"]/e:name)[1]', 'VARCHAR(20)') AS id2
FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/e:employees') AS n(c) WHERE t.id = 4;
GO
-- 26.9 A colon inside a string literal is left alone
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('concat("x:y", (e:name)[1])', 'VARCHAR(20)') FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/e:employees/e:emp') AS n(c) WHERE t.id = 4 ORDER BY 1;
GO
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.exist('e:name[. != "a:b"]') FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/e:employees/e:emp') AS n(c) WHERE t.id = 4 ORDER BY 1;
GO
-- 26.10 Nested .nodes() with a relative prefixed path
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT m.d.value('.', 'VARCHAR(20)') FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/e:employees/e:emp') AS n(c) CROSS APPLY n.c.nodes('e:info/e:sub') AS m(d) WHERE t.id = 4 ORDER BY 1;
GO
-- 26.11 local-name(.) and an unprefixed attribute on a prefixed element
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('local-name(.)', 'VARCHAR(20)') AS ln, n.c.value('@plain', 'VARCHAR(20)') AS plain FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/e:employees/e:emp') AS n(c) WHERE t.id = 4 ORDER BY 2;
GO
-- 26.12 .query() of a relative prefixed path, one fragment per row
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.query('e:info') FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/e:employees/e:emp') AS n(c) WHERE t.id = 4;
GO
-- 26.13 Absolute prefixed element and attribute under a .nodes() context
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('(/e:employees/e:emp/e:name)[1]', 'VARCHAR(50)') AS abs_elem, n.c.value('(/e:employees/e:emp/@e:id)[1]', 'INT') AS abs_attr
FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/e:employees/e:emp') AS n(c) WHERE t.id = 3;
GO
-- 26.14 A .nodes() context selected by position rather than by name
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('(e:name)[1]', 'VARCHAR(20)') FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/*/*[2]') AS n(c) WHERE t.id = 4;
GO
-- 26.15 descendant:: and self:: axes with prefixed names
;WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('(descendant::e:sub)[1]', 'VARCHAR(20)') AS d, n.c.exist('self::e:emp') AS s FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/e:employees/e:emp') AS n(c) WHERE t.id = 4 ORDER BY 1;
GO
-- 26.16 No clause: unprefixed axis steps and unprefixed relative paths
SELECT n.c.value('(child::name)[1]', 'VARCHAR(20)') AS c, n.c.value('(descendant::sub)[1]', 'VARCHAR(20)') AS d, n.c.exist('self::emp') AS s
FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/employees/emp') AS n(c) WHERE t.id = 5 ORDER BY 1;
GO
SELECT n.c.value('(./name)[1]', 'VARCHAR(20)') AS dot, n.c.value('(../x)[1]', 'VARCHAR(20)') AS up, n.c.value('(info/sub)[1]', 'VARCHAR(20)') AS two_steps
FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/employees/emp') AS n(c) WHERE t.id = 5 ORDER BY 1;
GO
SELECT n.c.value('(emp[@id="2"]/name)[1]', 'VARCHAR(20)') FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/employees') AS n(c) WHERE t.id = 5;
GO
-- ============================================
-- SECTION 27: Namespaced XML methods inside routine bodies
-- The text stored for a routine body comes from the CREATE statement's own
-- walk, which adds the namespace array to each rewritten XML method call. The
-- bindings belong to the one statement that carries the clause. Uses
-- xmlns_methods_nsdata from SECTION 26.
-- ============================================
-- 27.1 .query() in a procedure body. T-SQL labels the result with the clause
-- prefix (x:child), Babelfish keeps the document's prefix (ns:child); the two
-- are namespace-equivalent and the same as outside a procedure.
CREATE PROCEDURE xmlns_methods_nsproc_query AS
BEGIN
    ;WITH XMLNAMESPACES('http://example.com/ns1' AS x)
    SELECT data.query('/root/x:child') FROM xmlns_methods_nsdata WHERE id = 1;
END;
GO
EXEC xmlns_methods_nsproc_query;
GO
-- 27.2 .value()
CREATE PROCEDURE xmlns_methods_nsproc_value AS
BEGIN
    ;WITH XMLNAMESPACES('http://example.com/ns1' AS x)
    SELECT data.value('(/root/x:child)[2]', 'VARCHAR(20)') FROM xmlns_methods_nsdata WHERE id = 1;
END;
GO
EXEC xmlns_methods_nsproc_value;
GO
-- 27.3 .exist()
CREATE PROCEDURE xmlns_methods_nsproc_exist AS
BEGIN
    ;WITH XMLNAMESPACES('http://example.com/ns1' AS x)
    SELECT data.exist('/root/x:child') FROM xmlns_methods_nsdata WHERE id = 1;
END;
GO
EXEC xmlns_methods_nsproc_exist;
GO
-- 27.4 .nodes() with .value()
CREATE PROCEDURE xmlns_methods_nsproc_nodes AS
BEGIN
    ;WITH XMLNAMESPACES('http://example.com/ns1' AS x)
    SELECT n.c.value('.', 'VARCHAR(20)') FROM xmlns_methods_nsdata t CROSS APPLY t.data.nodes('/root/x:child') AS n(c) WHERE t.id = 1 ORDER BY 1;
END;
GO
EXEC xmlns_methods_nsproc_nodes;
GO
-- 27.5 table.column.method()
CREATE PROCEDURE xmlns_methods_nsproc_tblcol AS
BEGIN
    ;WITH XMLNAMESPACES('http://example.com/ns1' AS x)
    SELECT t.data.value('(/root/x:child)[1]', 'VARCHAR(20)') FROM xmlns_methods_nsdata AS t WHERE t.id = 1;
END;
GO
EXEC xmlns_methods_nsproc_tblcol;
GO
-- 27.6 @variable.method()
CREATE PROCEDURE xmlns_methods_nsproc_var AS
BEGIN
    DECLARE @x XML = '<root xmlns:ns="http://example.com/ns1"><ns:child>Hello</ns:child></root>';
    ;WITH XMLNAMESPACES('http://example.com/ns1' AS x)
    SELECT @x.value('(/root/x:child)[1]', 'VARCHAR(20)');
END;
GO
EXEC xmlns_methods_nsproc_var;
GO
-- 27.7 Nested IF and BEGIN...END
CREATE PROCEDURE xmlns_methods_nsproc_nested AS
BEGIN
    IF 1 = 1
    BEGIN
        IF 2 = 2
        BEGIN
            ;WITH XMLNAMESPACES('http://example.com/ns1' AS x)
            SELECT data.exist('/root/x:child') FROM xmlns_methods_nsdata WHERE id = 1;
        END
    END
END;
GO
EXEC xmlns_methods_nsproc_nested;
GO
-- 27.8 A later statement with no clause and an unprefixed path
CREATE PROCEDURE xmlns_methods_nsproc_leak1 AS
BEGIN
    ;WITH XMLNAMESPACES('http://example.com/ns1' AS x)
    SELECT data.exist('/root/x:child') AS with_clause FROM xmlns_methods_nsdata WHERE id = 1;
    SELECT data.exist('/root/*') AS no_clause FROM xmlns_methods_nsdata WHERE id = 1;
END;
GO
EXEC xmlns_methods_nsproc_leak1;
GO
-- 27.9 A later statement with no clause does not see the bindings, so the
-- CREATE is rejected (T-SQL 2229). T-SQL names the method after the table and
-- column it is called on ([xmlns_methods_nsdata.data.exist()]); Babelfish
-- gives only the method name, as in all its XQuery messages.
CREATE PROCEDURE xmlns_methods_nsproc_leak2 AS
BEGIN
    ;WITH XMLNAMESPACES('http://example.com/ns1' AS x)
    SELECT data.exist('/root/x:child') AS with_clause FROM xmlns_methods_nsdata WHERE id = 1;
    SELECT data.exist('/root/x:child') AS no_clause_prefixed FROM xmlns_methods_nsdata WHERE id = 1;
END;
GO
SELECT COUNT(*) FROM sys.objects WHERE name = 'xmlns_methods_nsproc_leak2';
GO
-- 27.10 Two statements bind x to different URIs
CREATE PROCEDURE xmlns_methods_nsproc_rebind AS
BEGIN
    ;WITH XMLNAMESPACES('http://example.com/ns1' AS x)
    SELECT data.exist('/root/x:child') AS ns1_match FROM xmlns_methods_nsdata WHERE id = 1;
    ;WITH XMLNAMESPACES('urn:other' AS x)
    SELECT data.exist('/root/x:child') AS other_match FROM xmlns_methods_nsdata WHERE id = 1;
END;
GO
EXEC xmlns_methods_nsproc_rebind;
GO
-- 27.11 Scalar function body
CREATE FUNCTION xmlns_methods_nsfn_scalar() RETURNS VARCHAR(20) AS
BEGIN
    DECLARE @r VARCHAR(20);
    ;WITH XMLNAMESPACES('http://example.com/ns1' AS x)
    SELECT @r = data.value('(/root/x:child)[1]', 'VARCHAR(20)') FROM xmlns_methods_nsdata WHERE id = 1;
    RETURN @r;
END;
GO
SELECT dbo.xmlns_methods_nsfn_scalar();
GO
-- 27.12 Multi-statement table function body
CREATE FUNCTION xmlns_methods_nsfn_mstvf() RETURNS @t TABLE (v VARCHAR(20)) AS
BEGIN
    ;WITH XMLNAMESPACES('http://example.com/ns1' AS x)
    INSERT INTO @t SELECT data.value('(/root/x:child)[2]', 'VARCHAR(20)') FROM xmlns_methods_nsdata WHERE id = 1;
    RETURN;
END;
GO
SELECT * FROM dbo.xmlns_methods_nsfn_mstvf();
GO
-- 27.13 Inline table function body
CREATE FUNCTION xmlns_methods_nsfn_itvf() RETURNS TABLE AS
RETURN (
    WITH XMLNAMESPACES('http://example.com/ns1' AS x)
    SELECT data.value('(/root/x:child)[1]', 'VARCHAR(20)') AS v FROM xmlns_methods_nsdata WHERE id = 1
);
GO
SELECT * FROM dbo.xmlns_methods_nsfn_itvf();
GO
-- 27.14 Trigger body
CREATE TABLE xmlns_methods_nstrig_t (id INT);
GO
CREATE TABLE xmlns_methods_nstrig_log (v VARCHAR(20));
GO
CREATE TRIGGER xmlns_methods_nstrig ON xmlns_methods_nstrig_t AFTER INSERT AS
BEGIN
    ;WITH XMLNAMESPACES('http://example.com/ns1' AS x)
    INSERT INTO xmlns_methods_nstrig_log SELECT data.value('(/root/x:child)[1]', 'VARCHAR(20)') FROM xmlns_methods_nsdata WHERE id = 1;
END;
GO
INSERT INTO xmlns_methods_nstrig_t VALUES (1);
GO
SELECT v FROM xmlns_methods_nstrig_log;
GO
-- 27.15 ALTER PROCEDURE rebinds x to a URI the document does not use
ALTER PROCEDURE xmlns_methods_nsproc_exist AS
BEGIN
    ;WITH XMLNAMESPACES('urn:other' AS x)
    SELECT data.exist('/root/x:child') FROM xmlns_methods_nsdata WHERE id = 1;
END;
GO
EXEC xmlns_methods_nsproc_exist;
GO
-- 27.16 The call is inside a CTE of the clause
CREATE PROCEDURE xmlns_methods_nsproc_cte AS
BEGIN
    ;WITH XMLNAMESPACES('http://example.com/ns1' AS x),
         c AS (SELECT data.value('(/root/x:child)[1]', 'VARCHAR(20)') AS v FROM xmlns_methods_nsdata WHERE id = 1)
    SELECT v FROM c;
END;
GO
EXEC xmlns_methods_nsproc_cte;
GO
-- 27.17 A bad clause in a routine body rejects the CREATE (T-SQL 6874,
-- reported as 33557097), and the next CREATE is not disturbed by anything the
-- failed one left behind
CREATE PROCEDURE xmlns_methods_nsproc_bad AS
BEGIN
    ;WITH XMLNAMESPACES('   ' AS x)
    SELECT data.exist('/root/x:child') FROM xmlns_methods_nsdata WHERE id = 1;
END;
GO
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_bad;
GO
CREATE PROCEDURE xmlns_methods_nsproc_after AS
BEGIN
    ;WITH XMLNAMESPACES('http://example.com/ns1' AS x)
    SELECT data.exist('/root/x:child') FROM xmlns_methods_nsdata WHERE id = 1;
END;
GO
EXEC xmlns_methods_nsproc_after;
GO
DROP PROCEDURE xmlns_methods_nsproc_query;
GO
DROP PROCEDURE xmlns_methods_nsproc_value;
GO
DROP PROCEDURE xmlns_methods_nsproc_exist;
GO
DROP PROCEDURE xmlns_methods_nsproc_nodes;
GO
DROP PROCEDURE xmlns_methods_nsproc_tblcol;
GO
DROP PROCEDURE xmlns_methods_nsproc_var;
GO
DROP PROCEDURE xmlns_methods_nsproc_nested;
GO
DROP PROCEDURE xmlns_methods_nsproc_leak1;
GO
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_leak2;
GO
DROP PROCEDURE xmlns_methods_nsproc_rebind;
GO
DROP PROCEDURE xmlns_methods_nsproc_cte;
GO
DROP PROCEDURE xmlns_methods_nsproc_after;
GO
DROP FUNCTION xmlns_methods_nsfn_scalar;
GO
DROP FUNCTION xmlns_methods_nsfn_mstvf;
GO
DROP FUNCTION xmlns_methods_nsfn_itvf;
GO
DROP TRIGGER xmlns_methods_nstrig;
GO
DROP TABLE xmlns_methods_nstrig_t;
GO
DROP TABLE xmlns_methods_nstrig_log;
GO
DROP TABLE xmlns_methods_nsdata;
GO
-- ============================================
-- SECTION 28: Wildcards and subtraction under .nodes()
-- A wildcard (e:*, child::*, @e:*, @*) ends its name test, so a following
-- '-' is the subtraction operator. Whitespace next to '-' is kept, so that
-- "@a - 1" is not read as the name "a-1".
-- ============================================
-- 28.1 (e:*)[1] - (x)[1] (T-SQL 7)
DECLARE @x XML = '<x><e:emp xmlns:e="urn:emp" e:n="5"><e:a>10</e:a><x>3</x></e:emp></x>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('(e:*)[1] - (x)[1]', 'FLOAT') AS v FROM @x.nodes('/x/e:emp') AS n(c);
GO
-- 28.2 (child::*)[1] - (x)[1] (T-SQL 7)
DECLARE @x XML = '<x><e:emp xmlns:e="urn:emp" e:n="5"><e:a>10</e:a><x>3</x></e:emp></x>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('(child::*)[1] - (x)[1]', 'FLOAT') AS v FROM @x.nodes('/x/e:emp') AS n(c);
GO
-- 28.3 (@e:*)[1] - (x)[1] (T-SQL 2)
DECLARE @x XML = '<x><e:emp xmlns:e="urn:emp" e:n="5"><e:a>10</e:a><x>3</x></e:emp></x>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('(@e:*)[1] - (x)[1]', 'FLOAT') AS v FROM @x.nodes('/x/e:emp') AS n(c);
GO
-- 28.4 e:* - x, @e:* - x, @* - x and e:*-1 have a non-singleton operand,
-- which T-SQL rejects (2389). Babelfish has no static typing and takes the
-- first node of each step: 7, 2, 2 and 9.
DECLARE @x XML = '<x><e:emp xmlns:e="urn:emp" e:n="5"><e:a>10</e:a><x>3</x></e:emp></x>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('e:* - x', 'FLOAT') AS v1, n.c.value('@e:* - x', 'FLOAT') AS v2, n.c.value('@* - x', 'FLOAT') AS v3, n.c.value('e:*-1', 'FLOAT') AS v4
FROM @x.nodes('/x/e:emp') AS n(c);
GO
-- 28.5 e:* and x, e:* or x, exist(e:*[. = 10] and x) with no x under the
-- context (T-SQL 0, 1, 1), and e:* and x with one (T-SQL 1)
DECLARE @x XML = '<x><e:emp xmlns:e="urn:emp"><e:a>10</e:a></e:emp></x>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('e:* and x', 'BIT') AS v_and, n.c.value('e:* or x', 'BIT') AS v_or, n.c.exist('e:*[. = 10] and x') AS ex FROM @x.nodes('/x/e:emp') AS n(c);
GO
DECLARE @x XML = '<x><e:emp xmlns:e="urn:emp"><e:a>10</e:a><x>3</x></e:emp></x>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('e:* and x', 'BIT') AS v_and FROM @x.nodes('/x/e:emp') AS n(c);
GO
-- 28.6 @a - 1 and @a -1 (T-SQL 9, 9)
DECLARE @x XML = '<r xmlns:e="urn:emp"><emp a="10" b="3" e:a="20" e:b="4"/></r>';
SELECT n.c.value('@a - 1', 'FLOAT') AS v1, n.c.value('@a -1', 'FLOAT') AS v2 FROM @x.nodes('/r/emp') AS n(c);
GO
-- 28.7 @a - @b (T-SQL 7)
DECLARE @x XML = '<r xmlns:e="urn:emp"><emp a="10" b="3" e:a="20" e:b="4"/></r>';
SELECT n.c.value('@a - @b', 'FLOAT') AS v FROM @x.nodes('/r/emp') AS n(c);
GO
-- 28.8 @e:a - @e:b (T-SQL 16)
DECLARE @x XML = '<r xmlns:e="urn:emp"><emp a="10" b="3" e:a="20" e:b="4"/></r>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('@e:a - @e:b', 'FLOAT') AS v FROM @x.nodes('/r/emp') AS n(c);
GO
-- 28.9 Other operators as controls (T-SQL 11, 20, 5, 1)
DECLARE @x XML = '<r xmlns:e="urn:emp"><emp a="10" b="3" e:a="20" e:b="4"/></r>';
SELECT n.c.value('@a + 1', 'FLOAT') AS p, n.c.value('@a * 2', 'FLOAT') AS m, n.c.value('@a div 2', 'FLOAT') AS d, n.c.value('@a mod 3', 'FLOAT') AS md
FROM @x.nodes('/r/emp') AS n(c);
GO
-- 28.10 No .nodes(): (/r/emp)[1]/@a - 1, (/r/emp)[1]/@e:a - 1 and
-- (/r/emp)[1]/@a - (/r/emp)[1]/@b (T-SQL 9, 19, 7)
DECLARE @x XML = '<r xmlns:e="urn:emp"><emp a="10" b="3" e:a="20" e:b="4"/></r>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT @x.value('(/r/emp)[1]/@a - 1', 'FLOAT') AS v1, @x.value('(/r/emp)[1]/@e:a - 1', 'FLOAT') AS v2, @x.value('(/r/emp)[1]/@a - (/r/emp)[1]/@b', 'FLOAT') AS v3;
GO
-- 28.11 @a-1 is one name, which matches nothing (T-SQL NULL)
DECLARE @x XML = '<r><emp a="10"/></r>';
SELECT n.c.value('@a-1', 'FLOAT') AS v FROM @x.nodes('/r/emp') AS n(c);
GO
-- 28.12 @a- 1 is a syntax error. T-SQL reports 2209 "Syntax error near
-- 'a-'"; Babelfish reports "invalid XPath expression".
DECLARE @x XML = '<r><emp a="10"/></r>';
SELECT n.c.value('@a- 1', 'FLOAT') AS v FROM @x.nodes('/r/emp') AS n(c);
GO
-- ============================================
-- SECTION 29: Bare * and text() under .nodes()
-- A '*' in name-test position and text() are relative steps from the
-- context node, like a bare name.
-- ============================================
-- 29.1 count(*) (T-SQL 2 per row)
DECLARE @x XML = '<employees><x>X1</x><emp id="1"><name>Alice</name><info><sub>S1</sub></info></emp><emp id="2"><name>Bob</name><info><sub>S2</sub></info></emp></employees>';
SELECT n.c.value('count(*)', 'INT') AS cnt FROM @x.nodes('/employees/emp') AS n(c);
GO
-- 29.2 (*)[1] and local-name((*)[1]) (T-SQL Alice|name, Bob|name)
DECLARE @x XML = '<employees><x>X1</x><emp id="1"><name>Alice</name><info><sub>S1</sub></info></emp><emp id="2"><name>Bob</name><info><sub>S2</sub></info></emp></employees>';
SELECT n.c.value('(*)[1]', 'VARCHAR(20)') AS first_child, n.c.value('local-name((*)[1])', 'VARCHAR(20)') AS ln FROM @x.nodes('/employees/emp') AS n(c);
GO
-- 29.3 count(*/*) and (*/sub)[1] (T-SQL 1|S1, 1|S2)
DECLARE @x XML = '<employees><x>X1</x><emp id="1"><name>Alice</name><info><sub>S1</sub></info></emp><emp id="2"><name>Bob</name><info><sub>S2</sub></info></emp></employees>';
SELECT n.c.value('count(*/*)', 'INT') AS cnt2, n.c.value('(*/sub)[1]', 'VARCHAR(20)') AS sub FROM @x.nodes('/employees/emp') AS n(c);
GO
-- 29.4 exist('*') on a context with no element children (T-SQL 0)
DECLARE @x XML = '<employees><x>X1</x><emp id="1"><name>Alice</name><info><sub>S1</sub></info></emp><emp id="2"><name>Bob</name><info><sub>S2</sub></info></emp></employees>';
SELECT n.c.exist('*') AS ex FROM @x.nodes('/employees/x') AS n(c);
GO
-- 29.5 .query('*') returns the children of each row
DECLARE @x XML = '<employees><x>X1</x><emp id="1"><name>Alice</name><info><sub>S1</sub></info></emp><emp id="2"><name>Bob</name><info><sub>S2</sub></info></emp></employees>';
SELECT n.c.query('*') AS q FROM @x.nodes('/employees/emp') AS n(c);
GO
-- 29.6 Nested .nodes('*') (T-SQL 4 rows: name, info, name, info)
DECLARE @x XML = '<employees><x>X1</x><emp id="1"><name>Alice</name><info><sub>S1</sub></info></emp><emp id="2"><name>Bob</name><info><sub>S2</sub></info></emp></employees>';
SELECT m.d.value('local-name(.)', 'VARCHAR(20)') AS ln FROM @x.nodes('/employees/emp') AS n(c) CROSS APPLY n.c.nodes('*') AS m(d);
GO
-- 29.7 Namespaced document: count(*) and count(e:*) (T-SQL 2|2 per row)
DECLARE @x XML = '<e:employees xmlns:e="urn:emp"><e:x>X1</e:x><e:emp e:id="1" plain="p1"><e:name>Alice</e:name><e:info><e:sub>S1</e:sub></e:info></e:emp><e:emp e:id="2" plain="p2"><e:name>Bob</e:name><e:info><e:sub>S2</e:sub></e:info></e:emp></e:employees>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('count(*)', 'INT') AS cnt, n.c.value('count(e:*)', 'INT') AS cnt_e FROM @x.nodes('/e:employees/e:emp') AS n(c);
GO
-- 29.8 A '*' after an operator: count(@*) + count(*) (T-SQL 3 per row)
DECLARE @x XML = '<employees><x>X1</x><emp id="1"><name>Alice</name><info><sub>S1</sub></info></emp><emp id="2"><name>Bob</name><info><sub>S2</sub></info></emp></employees>';
SELECT n.c.value('count(@*) + count(*)', 'INT') AS s FROM @x.nodes('/employees/emp') AS n(c);
GO
-- 29.9 The multiply operator next to a wildcard step and next to an
-- attribute: count(*)*2 and @id * 2 (T-SQL 4|2, 4|4)
DECLARE @x XML = '<employees><x>X1</x><emp id="1"><name>Alice</name><info><sub>S1</sub></info></emp><emp id="2"><name>Bob</name><info><sub>S2</sub></info></emp></employees>';
SELECT n.c.value('count(*)*2', 'INT') AS c2, n.c.value('@id * 2', 'INT') AS i2 FROM @x.nodes('/employees/emp') AS n(c);
GO
-- 29.10 exist() of a boolean expression is 1 even when it is false
-- (T-SQL 1, 1, then 1)
DECLARE @x XML = '<employees><x>X1</x><emp id="1"><name>Alice</name><info><sub>S1</sub></info></emp><emp id="2"><name>Bob</name><info><sub>S2</sub></info></emp></employees>';
SELECT n.c.exist('@id and *') AS ex FROM @x.nodes('/employees/emp') AS n(c);
SELECT n.c.exist('@id and *') AS ex_x FROM @x.nodes('/employees/x') AS n(c);
GO
-- 29.11 (text())[1] and count(text()) on mixed content (T-SQL hello|2)
DECLARE @x XML = '<r>root-text<e>hello<b>x</b>world</e></r>';
SELECT n.c.value('(text())[1]', 'VARCHAR(20)') AS t1, n.c.value('count(text())', 'INT') AS cnt FROM @x.nodes('/r/e') AS n(c);
GO
-- 29.12 count(node()) and count(comment()) (T-SQL 4|1), and exist('text()')
-- on an element with no text (T-SQL 0)
DECLARE @x XML = '<r><e>hello<!--c--><b>x</b>world</e></r>';
SELECT n.c.value('count(node())', 'INT') AS cn, n.c.value('count(comment())', 'INT') AS cc FROM @x.nodes('/r/e') AS n(c);
GO
DECLARE @x XML = '<r><e><b>x</b></e></r>';
SELECT n.c.exist('text()') AS ex FROM @x.nodes('/r/e') AS n(c);
GO
-- ============================================
-- SECTION 30: Namespace wildcard on the attribute axis
-- @e:* and attribute::e:* match only the attributes in the namespace bound
-- to e, with or without a .nodes() context.
-- ============================================
-- 30.1 .nodes() context, e:id and an unprefixed attribute (T-SQL 1)
DECLARE @x XML = '<e:employees xmlns:e="urn:emp"><e:emp e:id="1" plain="p1"><e:name>Alice</e:name></e:emp></e:employees>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('count(@e:*)', 'INT') AS wild FROM @x.nodes('/e:employees/e:emp') AS n(c);
GO
-- 30.2 Absolute path, same document (T-SQL 1)
DECLARE @x XML = '<e:employees xmlns:e="urn:emp"><e:emp e:id="1" plain="p1"><e:name>Alice</e:name></e:emp></e:employees>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT @x.value('count(/e:employees/e:emp/@e:*)', 'INT') AS wild;
GO
-- 30.3 A default namespace with the same URI as the prefix (T-SQL 1)
DECLARE @x XML = '<emp xmlns="urn:emp" xmlns:e="urn:emp" e:id="1" plain="p"/>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT @x.value('count(/e:emp/@e:*)', 'INT') AS wild;
GO
-- 30.4 Unprefixed attributes only (T-SQL 0)
DECLARE @x XML = '<e:emp xmlns:e="urn:emp" a="1" b="2"/>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT @x.value('count(/e:emp/@e:*)', 'INT') AS wild;
GO
-- 30.5 Two document prefixes for one URI (T-SQL 2)
DECLARE @x XML = '<r xmlns:e="urn:emp" xmlns:f="urn:emp" e:a="1" f:b="2" c="3"/>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT @x.value('count(/r/@e:*)', 'INT') AS wild;
GO
-- 30.6 Two clause prefixes for one URI (T-SQL 2|2)
DECLARE @x XML = '<r xmlns:e="urn:emp" xmlns:f="urn:emp" e:a="1" f:b="2" c="3"/>';
WITH XMLNAMESPACES('urn:emp' AS e, 'urn:emp' AS g)
SELECT @x.value('count(/r/@e:*)', 'INT') AS wild_e, @x.value('count(/r/@g:*)', 'INT') AS wild_g;
GO
-- 30.7 An attribute in another namespace and xml:lang next to e:a (T-SQL 1)
DECLARE @x XML = '<r xmlns:e="urn:emp" xmlns:o="urn:o" e:a="1" o:b="2" xml:lang="en" c="3"/>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT @x.value('count(/r/@e:*)', 'INT') AS wild;
GO
-- 30.8 Document order, unprefixed attribute first (T-SQL a)
DECLARE @x XML = '<r xmlns:e="urn:emp" c="3" e:a="1"/>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT @x.value('local-name((/r/@e:*)[1])', 'VARCHAR(10)') AS wild;
GO
-- 30.9 In a predicate and in exist(), unprefixed attributes only
-- (T-SQL 0|0)
DECLARE @x XML = '<r xmlns:e="urn:emp" c="3"/>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT @x.value('count(/r[@e:*])', 'INT') AS wild, @x.exist('/r/@e:*') AS ex_wild;
GO
-- 30.10 .nodes() context, unprefixed attributes only (T-SQL 0)
DECLARE @x XML = '<r xmlns:e="urn:emp"><e:emp a="1" b="2"/></r>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('count(@e:*)', 'INT') AS wild FROM @x.nodes('/r/e:emp') AS n(c);
GO
-- 30.11 attribute::e:* (T-SQL 1), and the element wildcard as a control
-- (T-SQL 1)
DECLARE @x XML = '<r xmlns:e="urn:emp" xmlns:o="urn:o" e:a="1" c="3"><e:a/><b/><o:c/></r>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT @x.value('count(/r/attribute::e:*)', 'INT') AS attr_axis, @x.value('count(/r/e:*)', 'INT') AS elem;
GO
-- 30.12 A string literal is left alone, a predicate follows the namespace
-- test, and xml:* needs no clause (T-SQL @e:*|1|a, then 1)
DECLARE @x XML = '<r xmlns:e="urn:emp" c="3" e:a="1" e:b="2"/>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT @x.value('concat("@e:*", "")', 'VARCHAR(10)') AS s, @x.value('count(/r/@e:*[1])', 'INT') AS c1, @x.value('local-name((/r/@e:*[1])[1])', 'VARCHAR(10)') AS ln;
GO
DECLARE @x XML = '<r xml:lang="en" a="1"/>';
SELECT @x.value('count(/r/@xml:*)', 'INT') AS c;
GO
-- ============================================
-- SECTION 31: A failed statement leaves nothing behind for the next batch
-- Each failure below is raised while the statement is being rewritten. The
-- next batch-level CREATE gets only its own bindings and rewrites.
-- ============================================
CREATE TABLE xmlns_methods_nsstale (id INT, d XML);
GO
INSERT INTO xmlns_methods_nsstale VALUES (1, '<p:a xmlns:p="urn:stale">1</p:a>');
GO
-- 31.1 An XML method in GROUP BY under a clause that binds p to urn:stale
-- (T-SQL: XML methods are not allowed in a GROUP BY clause.)
WITH XMLNAMESPACES('urn:stale' AS p)
SELECT COUNT(*) AS c FROM xmlns_methods_nsstale t GROUP BY t.d.value('(/p:a)[1]', 'INT');
GO
-- 31.2 A function whose own clause binds p to urn:good (T-SQL 6)
CREATE FUNCTION xmlns_methods_nsfn_stale() RETURNS INT AS
BEGIN
    DECLARE @x XML = '<p:a xmlns:p="urn:good">6</p:a>';
    DECLARE @r INT;
    WITH XMLNAMESPACES('urn:good' AS p)
    SELECT @r = @x.value('(/p:a)[1]', 'INT');
    RETURN @r;
END
GO
SELECT dbo.xmlns_methods_nsfn_stale() AS v;
GO
-- 31.3 .value() with one argument (T-SQL: The value function requires 2
-- argument(s).), then a view with no clause (T-SQL 9)
DECLARE @x XML = '<a>1</a>';
SELECT @x.value('(/a)[1]') AS v;
GO
CREATE VIEW xmlns_methods_nsv_stale AS SELECT CAST('<a>9</a>' AS XML).value('(/a)[1]', 'INT') AS v;
GO
SELECT v FROM xmlns_methods_nsv_stale;
GO
-- 31.4 The same failure, then a procedure (T-SQL 9)
DECLARE @x XML = '<a>1</a>';
SELECT @x.value('(/a)[1]') AS v;
GO
CREATE PROCEDURE xmlns_methods_nsproc_stale AS SELECT CAST('<a>9</a>' AS XML).value('(/a)[1]', 'INT') AS v;
GO
EXEC xmlns_methods_nsproc_stale;
GO
-- 31.5 The GROUP BY failure, then a procedure with no clause that uses p:
-- (T-SQL 2229 at CREATE, so the procedure does not exist: 0)
WITH XMLNAMESPACES('urn:stale' AS p)
SELECT COUNT(*) AS c FROM xmlns_methods_nsstale t GROUP BY t.d.value('(/p:a)[1]', 'INT');
GO
CREATE PROCEDURE xmlns_methods_nsproc_stale2 AS
BEGIN
    DECLARE @x XML = '<p:a xmlns:p="urn:stale">7</p:a>';
    SELECT @x.value('(/p:a)[1]', 'INT') AS v;
END
GO
SELECT COUNT(*) FROM sys.objects WHERE name = 'xmlns_methods_nsproc_stale2';
GO
-- 31.6 Routines compiled while a statement with a clause runs keep their
-- own bindings, and so does the statement (T-SQL 1|3 and 2, then 1, 4, 2)
CREATE FUNCTION xmlns_methods_nsfn_nested() RETURNS INT AS
BEGIN
    DECLARE @y XML = '<q:a xmlns:q="urn:inner">3</q:a>';
    DECLARE @r INT;
    WITH XMLNAMESPACES('urn:inner' AS q) SELECT @r = @y.value('(/q:a)[1]', 'INT');
    RETURN @r;
END
GO
DECLARE @x XML = '<p:a xmlns:p="urn:outer">1</p:a>';
WITH XMLNAMESPACES('urn:outer' AS p) SELECT @x.value('(/p:a)[1]', 'INT') AS v, dbo.xmlns_methods_nsfn_nested() AS f;
WITH XMLNAMESPACES('urn:outer' AS p) SELECT @x.value('(/p:a)[1]', 'INT') + 1 AS v2;
GO
CREATE PROCEDURE xmlns_methods_nsproc_dyn AS
BEGIN
    DECLARE @x XML = '<p:a xmlns:p="urn:outer">1</p:a>';
    WITH XMLNAMESPACES('urn:outer' AS p) SELECT @x.value('(/p:a)[1]', 'INT') AS v;
    EXEC sp_executesql N'DECLARE @y XML = ''<q:a xmlns:q="urn:dyn">4</q:a>''; WITH XMLNAMESPACES(''urn:dyn'' AS q) SELECT @y.value(''(/q:a)[1]'', ''INT'') AS d;';
    WITH XMLNAMESPACES('urn:outer' AS p) SELECT @x.value('(/p:a)[1]', 'INT') + 1 AS v2;
END
GO
EXEC xmlns_methods_nsproc_dyn;
GO
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_dyn;
DROP FUNCTION IF EXISTS xmlns_methods_nsfn_nested;
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_stale2;
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_stale;
DROP VIEW IF EXISTS xmlns_methods_nsv_stale;
DROP FUNCTION IF EXISTS xmlns_methods_nsfn_stale;
DROP TABLE IF EXISTS xmlns_methods_nsstale;
GO
-- ============================================
-- SECTION 32: Characters XML does not allow in a namespace URI, XML methods
-- The clause is rejected (T-SQL 6875) before any method runs. Babelfish
-- reports 33557097. The characters are built with NCHAR() in dynamic SQL.
-- ============================================
-- 32.1 .exist() with NCHAR(1) (T-SQL 6875)
DECLARE @s NVARCHAR(MAX) = N'DECLARE @x XML = ''<a/>''; WITH XMLNAMESPACES(''urn:a' + NCHAR(1) + N'b'' AS p) SELECT @x.exist(''/p:a'') AS ex';
EXEC(@s);
GO
-- 32.2 .value() with NCHAR(31) (T-SQL 6875)
DECLARE @s NVARCHAR(MAX) = N'DECLARE @x XML = ''<a/>''; WITH XMLNAMESPACES(''urn:a' + NCHAR(31) + N'b'' AS p) SELECT @x.value(''(/p:a)[1]'', ''INT'') AS v';
EXEC(@s);
GO
-- 32.3 .query() with NCHAR(11) (T-SQL 6875)
DECLARE @s NVARCHAR(MAX) = N'DECLARE @x XML = ''<a/>''; WITH XMLNAMESPACES(''urn:a' + NCHAR(11) + N'b'' AS p) SELECT @x.query(''/p:a'') AS q';
EXEC(@s);
GO
-- 32.4 .nodes() with NCHAR(1) (T-SQL 6875)
DECLARE @s NVARCHAR(MAX) = N'DECLARE @x XML = ''<a/>''; WITH XMLNAMESPACES(''urn:a' + NCHAR(1) + N'b'' AS p) SELECT COUNT(*) AS c FROM @x.nodes(''/p:a'') AS n(c)';
EXEC(@s);
GO
-- 32.5 In a procedure body the CREATE is rejected (T-SQL 6875)
DECLARE @s NVARCHAR(MAX) = N'CREATE PROCEDURE xmlns_methods_nsproc_ctl AS BEGIN DECLARE @x XML = ''<a/>''; WITH XMLNAMESPACES(''urn:a' + NCHAR(1) + N'b'' AS p) SELECT @x.exist(''/p:a'') AS ex; END';
EXEC(@s);
GO
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_ctl;
GO
-- ============================================
-- SECTION 33: URIs that look like SQL are data
-- The URI is passed to the method as data and nothing in it runs: no
-- pg_sleep() delay, and the methods find no p:a element. no_delay is 1 when
-- the batch took less than 5 seconds.
-- ============================================
-- 33.1 All four methods, a URI that closes the literal (T-SQL 0|NULL||1, 1)
DECLARE @t0 DATETIME2 = SYSDATETIME();
DECLARE @x XML = '<a/>';
WITH XMLNAMESPACES('a'')||pg_sleep(10)||(''b' AS p)
SELECT @x.exist('/p:a') AS ex, @x.value('(/p:a)[1]', 'INT') AS v, CAST(@x.query('/p:a') AS NVARCHAR(100)) AS q,
       (SELECT COUNT(*) FROM @x.nodes('/a') AS n(c)) AS nc;
SELECT CASE WHEN DATEDIFF(MILLISECOND, @t0, SYSDATETIME()) < 5000 THEN 1 ELSE 0 END AS no_delay;
GO
-- 33.2 A URI that closes the array literal and the cast (T-SQL 0|NULL, 1)
DECLARE @t0 DATETIME2 = SYSDATETIME();
DECLARE @x XML = '<a/>';
WITH XMLNAMESPACES('a"}}'' AS _text), pg_sleep(10)) --' AS p)
SELECT @x.exist('/p:a') AS ex, @x.value('(/p:a)[1]', 'INT') AS v;
SELECT CASE WHEN DATEDIFF(MILLISECOND, @t0, SYSDATETIME()) < 5000 THEN 1 ELSE 0 END AS no_delay;
GO
-- 33.3 Under .nodes() with a relative prefixed path (T-SQL NULL|0, 1)
DECLARE @t0 DATETIME2 = SYSDATETIME();
DECLARE @x XML = '<r><a>1</a></r>';
WITH XMLNAMESPACES('a'')||pg_sleep(10)||(''b' AS p)
SELECT n.c.value('(p:b)[1]', 'INT') AS v, n.c.exist('p:b') AS ex FROM @x.nodes('/r') AS n(c);
SELECT CASE WHEN DATEDIFF(MILLISECOND, @t0, SYSDATETIME()) < 5000 THEN 1 ELSE 0 END AS no_delay;
GO
-- 33.4 Both URIs in a procedure body (T-SQL 0|NULL, 0|NULL, 1)
CREATE PROCEDURE xmlns_methods_nspay_p AS
BEGIN
    DECLARE @x XML = '<a/>';
    WITH XMLNAMESPACES('a'')||pg_sleep(10)||(''b' AS p)
    SELECT @x.exist('/p:a') AS ex1, @x.value('(/p:a)[1]', 'INT') AS v1;
    WITH XMLNAMESPACES('a"}}'' AS _text), pg_sleep(10)) --' AS p)
    SELECT @x.exist('/p:a') AS ex2, @x.value('(/p:a)[1]', 'INT') AS v2;
END
GO
DECLARE @t0 DATETIME2 = SYSDATETIME();
EXEC xmlns_methods_nspay_p;
SELECT CASE WHEN DATEDIFF(MILLISECOND, @t0, SYSDATETIME()) < 5000 THEN 1 ELSE 0 END AS no_delay;
GO
-- 33.5 Scalar function body (T-SQL 0, 1)
CREATE FUNCTION xmlns_methods_nspay_f() RETURNS INT AS
BEGIN
    DECLARE @x XML = '<a/>';
    DECLARE @r INT;
    WITH XMLNAMESPACES('a'')||pg_sleep(10)||(''b' AS p)
    SELECT @r = @x.exist('/p:a');
    RETURN @r;
END
GO
DECLARE @t0 DATETIME2 = SYSDATETIME();
SELECT dbo.xmlns_methods_nspay_f() AS ex;
SELECT CASE WHEN DATEDIFF(MILLISECOND, @t0, SYSDATETIME()) < 5000 THEN 1 ELSE 0 END AS no_delay;
GO
DROP PROCEDURE IF EXISTS xmlns_methods_nspay_p;
DROP FUNCTION IF EXISTS xmlns_methods_nspay_f;
GO
-- ============================================
-- SECTION 34: Axis steps, operator-named prefixes, and the empty prefix in
-- routine bodies
-- ============================================
-- 34.1 (child::text())[1] and count(child::text()) (T-SQL hello|2)
DECLARE @x XML = '<r><e>hello<b>x</b>world</e></r>';
SELECT n.c.value('(child::text())[1]', 'VARCHAR(20)') AS t1, n.c.value('count(child::text())', 'INT') AS cnt FROM @x.nodes('/r/e') AS n(c);
GO
-- 34.2 self::node() (T-SQL 1|1|e)
DECLARE @x XML = '<r><e>hello<b>x</b>world</e></r>';
SELECT n.c.value('count(self::node())', 'INT') AS cnt, n.c.exist('self::node()') AS ex, n.c.value('local-name((self::node())[1])', 'VARCHAR(20)') AS ln FROM @x.nodes('/r/e') AS n(c);
GO
-- 34.3 Prefixed child::text() and self::e:emp (T-SQL hi|Alice|1)
DECLARE @x XML = '<e:r xmlns:e="urn:emp"><e:emp>hi<e:name>Alice</e:name></e:emp></e:r>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('(child::text())[1]', 'VARCHAR(20)') AS t1, n.c.value('(child::e:name/child::text())[1]', 'VARCHAR(20)') AS t2, n.c.exist('self::e:emp') AS s FROM @x.nodes('/e:r/e:emp') AS n(c);
GO
-- 34.4 Prefix div (T-SQL Alice|1|3|Alice)
DECLARE @x XML = '<e:r xmlns:e="urn:emp"><e:emp e:id="1"><e:name>Alice</e:name><e:n>10</e:n><e:m>4</e:m></e:emp></e:r>';
WITH XMLNAMESPACES('urn:emp' AS div)
SELECT n.c.value('(div:name)[1]', 'VARCHAR(20)') AS nm, n.c.value('@div:id', 'INT') AS id, n.c.value('count(div:*)', 'INT') AS cnt, n.c.value('(child::div:name)[1]', 'VARCHAR(20)') AS ch
FROM @x.nodes('/div:r/div:emp') AS n(c);
GO
-- 34.5 Prefix div with the div operator (T-SQL 2.5)
DECLARE @x XML = '<e:r xmlns:e="urn:emp"><e:emp e:id="1"><e:name>Alice</e:name><e:n>10</e:n><e:m>4</e:m></e:emp></e:r>';
WITH XMLNAMESPACES('urn:emp' AS div)
SELECT n.c.value('(div:n)[1] div (div:m)[1]', 'FLOAT') AS q FROM @x.nodes('/div:r/div:emp') AS n(c);
GO
-- 34.6 Prefix mod with the mod operator (T-SQL Alice|2)
DECLARE @x XML = '<e:r xmlns:e="urn:emp"><e:emp e:id="1"><e:name>Alice</e:name><e:n>10</e:n><e:m>4</e:m></e:emp></e:r>';
WITH XMLNAMESPACES('urn:emp' AS mod)
SELECT n.c.value('(mod:name)[1]', 'VARCHAR(20)') AS nm, n.c.value('(mod:n)[1] mod (mod:m)[1]', 'INT') AS r FROM @x.nodes('/mod:r/mod:emp') AS n(c);
GO
-- 34.7 Prefix and with the and operator (T-SQL Alice|1|1)
DECLARE @x XML = '<e:r xmlns:e="urn:emp"><e:emp e:id="1"><e:name>Alice</e:name><e:n>10</e:n><e:m>4</e:m></e:emp></e:r>';
WITH XMLNAMESPACES('urn:emp' AS [and])
SELECT n.c.value('(and:name)[1]', 'VARCHAR(20)') AS nm, n.c.value('(and:n)[1] > 1 and (and:m)[1] > 1', 'BIT') AS b, n.c.exist('and:name') AS ex FROM @x.nodes('/and:r/and:emp') AS n(c);
GO
-- 34.8 Prefix or with the or operator (T-SQL Alice|1)
DECLARE @x XML = '<e:r xmlns:e="urn:emp"><e:emp e:id="1"><e:name>Alice</e:name><e:n>10</e:n><e:m>4</e:m></e:emp></e:r>';
WITH XMLNAMESPACES('urn:emp' AS [or])
SELECT n.c.value('(or:name)[1]', 'VARCHAR(20)') AS nm, n.c.value('(or:n)[1] < 1 or (or:m)[1] > 1', 'BIT') AS b FROM @x.nodes('/or:r/or:emp') AS n(c);
GO
-- 34.9 Local names div, and, or and mod, prefixed and unprefixed
-- (T-SQL D|A|O|M twice)
DECLARE @x XML = '<e:r xmlns:e="urn:emp"><e:emp><e:div>D</e:div><e:and>A</e:and><e:or>O</e:or><e:mod>M</e:mod></e:emp></e:r>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('(e:div)[1]', 'VARCHAR(5)') AS d, n.c.value('(e:and)[1]', 'VARCHAR(5)') AS a, n.c.value('(e:or)[1]', 'VARCHAR(5)') AS o, n.c.value('(e:mod)[1]', 'VARCHAR(5)') AS m FROM @x.nodes('/e:r/e:emp') AS n(c);
GO
DECLARE @x XML = '<r><emp><div>D</div><and>A</and><or>O</or><mod>M</mod></emp></r>';
SELECT n.c.value('(div)[1]', 'VARCHAR(5)') AS d, n.c.value('(and)[1]', 'VARCHAR(5)') AS a, n.c.value('(or)[1]', 'VARCHAR(5)') AS o, n.c.value('(mod)[1]', 'VARCHAR(5)') AS m FROM @x.nodes('/r/emp') AS n(c);
GO
-- 34.10 AS [] with .exist() in a procedure body rejects the CREATE
-- (T-SQL 1038, 6877; Babelfish reports the 1038 text as 33557097)
CREATE PROCEDURE xmlns_methods_nsproc_e1 AS
BEGIN
    DECLARE @x XML = '<a/>';
    WITH XMLNAMESPACES('urn:x' AS [])
    SELECT @x.exist('/a') AS ex;
END
GO
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_e1;
GO
-- 34.11 AS "" with .value() in a procedure body (T-SQL 1038, 6877)
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE xmlns_methods_nsproc_e2 AS
BEGIN
    DECLARE @x XML = '<a>1</a>';
    WITH XMLNAMESPACES('urn:x' AS "")
    SELECT @x.value('(/a)[1]', 'INT') AS v;
END
GO
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_e2;
GO
-- 34.12 AS [] with .value() in a function body (T-SQL 1038, 6877)
CREATE FUNCTION xmlns_methods_nsfn_e1() RETURNS INT AS
BEGIN
    DECLARE @x XML = '<a>1</a>';
    DECLARE @r INT;
    WITH XMLNAMESPACES('urn:x' AS [])
    SELECT @r = @x.value('(/a)[1]', 'INT');
    RETURN @r;
END
GO
DROP FUNCTION IF EXISTS xmlns_methods_nsfn_e1;
GO
-- 34.13 AS [] with .nodes() in a procedure body (T-SQL 1038, 6877)
CREATE PROCEDURE xmlns_methods_nsproc_e3 AS
BEGIN
    DECLARE @x XML = '<a/>';
    WITH XMLNAMESPACES('urn:x' AS [])
    SELECT COUNT(*) AS c FROM @x.nodes('/a') AS n(c);
END
GO
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_e3;
GO
-- ============================================
-- SECTION 35: WITH XMLNAMESPACES in a view, XML methods
-- ============================================
-- 35.1 Statement form, .value() (T-SQL 5)
CREATE VIEW xmlns_methods_nsv1 AS
WITH XMLNAMESPACES('urn:x' AS p)
SELECT CAST('<p:a xmlns:p="urn:x">5</p:a>' AS XML).value('(/p:a)[1]', 'INT') AS v;
GO
SELECT v FROM xmlns_methods_nsv1;
GO
-- 35.2 Clause and a CTE, .exist() in WHERE (T-SQL 5)
CREATE VIEW xmlns_methods_nsv2 AS
WITH XMLNAMESPACES('urn:x' AS p), c AS (SELECT CAST('<p:a xmlns:p="urn:x">5</p:a>' AS XML) AS d)
SELECT d.value('(/p:a)[1]', 'INT') AS v FROM c WHERE d.exist('/p:a') = 1;
GO
SELECT v FROM xmlns_methods_nsv2;
GO
-- 35.3 .nodes() with a relative prefixed path (T-SQL 1, 2)
CREATE VIEW xmlns_methods_nsv3 AS
WITH XMLNAMESPACES('urn:x' AS p)
SELECT n.c.value('(p:b)[1]', 'INT') AS v
FROM (SELECT CAST('<r xmlns:p="urn:x"><p:a><p:b>1</p:b></p:a><p:a><p:b>2</p:b></p:a></r>' AS XML) AS d) AS t
CROSS APPLY t.d.nodes('/r/p:a') AS n(c);
GO
SELECT v FROM xmlns_methods_nsv3 ORDER BY v;
GO
-- 35.4 ALTER VIEW adds the clause (T-SQL 7)
CREATE VIEW xmlns_methods_nsv4 AS SELECT 1 AS v;
GO
ALTER VIEW xmlns_methods_nsv4 AS
WITH XMLNAMESPACES('urn:x' AS p)
SELECT CAST('<p:a xmlns:p="urn:x">7</p:a>' AS XML).value('(/p:a)[1]', 'INT') AS v;
GO
SELECT v FROM xmlns_methods_nsv4;
GO
-- 35.5 CREATE OR ALTER VIEW (T-SQL 8)
CREATE OR ALTER VIEW xmlns_methods_nsv5 AS
WITH XMLNAMESPACES('urn:x' AS p)
SELECT CAST('<p:a xmlns:p="urn:x">8</p:a>' AS XML).value('(/p:a)[1]', 'INT') AS v;
GO
SELECT v FROM xmlns_methods_nsv5;
GO
-- 35.6 A clause with no XML use (T-SQL 11)
CREATE VIEW xmlns_methods_nsv6 AS
WITH XMLNAMESPACES('urn:x' AS p)
SELECT 11 AS v;
GO
SELECT v FROM xmlns_methods_nsv6;
GO
-- 35.7 A whitespace-only URI rejects the CREATE (T-SQL 6874)
CREATE VIEW xmlns_methods_nsv7 AS WITH XMLNAMESPACES('   ' AS p) SELECT 1 AS v;
GO
-- 35.8 A view with no clause that uses x: (T-SQL 2229 at CREATE)
CREATE VIEW xmlns_methods_nsv8 AS SELECT CAST('<x:a xmlns:x="urn:x">1</x:a>' AS XML).value('(/x:a)[1]', 'INT') AS v;
GO
SELECT COUNT(*) FROM sys.objects WHERE name IN ('xmlns_methods_nsv7', 'xmlns_methods_nsv8');
GO
DROP VIEW IF EXISTS xmlns_methods_nsv1;
DROP VIEW IF EXISTS xmlns_methods_nsv2;
DROP VIEW IF EXISTS xmlns_methods_nsv3;
DROP VIEW IF EXISTS xmlns_methods_nsv4;
DROP VIEW IF EXISTS xmlns_methods_nsv5;
DROP VIEW IF EXISTS xmlns_methods_nsv6;
DROP VIEW IF EXISTS xmlns_methods_nsv7;
DROP VIEW IF EXISTS xmlns_methods_nsv8;
GO
-- ============================================
-- SECTION 36: Undeclared and predefined prefixes
-- T-SQL binds every prefix of an XML method's XQuery when the batch or the
-- routine is compiled. A prefix is bound by the statement's WITH
-- XMLNAMESPACES, by a "declare namespace" prolog, or because XQuery
-- predefines it: xml, xs, xsi, fn, xdt, sql and sqltypes. Any other prefix
-- raises 2229 before anything in the batch runs, and a CREATE is rejected.
-- Babelfish reports 2229 as 33557097.
-- ============================================
-- 36.1 Each predefined prefix needs no clause (T-SQL 0 for each)
DECLARE @x XML = '<a/>';
SELECT @x.exist('/xml:zz') AS p_xml, @x.exist('/xs:zz') AS p_xs, @x.exist('/xsi:zz') AS p_xsi, @x.exist('/fn:zz') AS p_fn,
       @x.exist('/xdt:zz') AS p_xdt, @x.exist('/sql:zz') AS p_sql, @x.exist('/sqltypes:zz') AS p_sqltypes;
GO
-- 36.2 The URI behind each predefined prefix (T-SQL en, then 1 for each)
DECLARE @x XML = '<a xml:lang="en"/>';
SELECT @x.value('(/a/@xml:lang)[1]', 'VARCHAR(10)') AS lang;
GO
SELECT CAST('<r xmlns:q="http://www.w3.org/2001/XMLSchema"><q:b>1</q:b></r>' AS XML).value('(/r/xs:b)[1]', 'INT') AS p_xs,
       CAST('<r xmlns:q="http://www.w3.org/2001/XMLSchema-instance"><q:b>1</q:b></r>' AS XML).value('(/r/xsi:b)[1]', 'INT') AS p_xsi,
       CAST('<r xmlns:q="http://www.w3.org/2004/07/xpath-functions"><q:b>1</q:b></r>' AS XML).value('(/r/fn:b)[1]', 'INT') AS p_fn,
       CAST('<r xmlns:q="http://www.w3.org/2004/07/xpath-datatypes"><q:b>1</q:b></r>' AS XML).value('(/r/xdt:b)[1]', 'INT') AS p_xdt,
       CAST('<r xmlns:q="urn:schemas-microsoft-com:xml-sql"><q:b>1</q:b></r>' AS XML).value('(/r/sql:b)[1]', 'INT') AS p_sql,
       CAST('<r xmlns:q="http://schemas.microsoft.com/sqlserver/2004/sqltypes"><q:b>1</q:b></r>' AS XML).value('(/r/sqltypes:b)[1]', 'INT') AS p_sqltypes;
GO
-- 36.3 Prefixes XQuery does not predefine (T-SQL 2229 for each)
DECLARE @x XML = '<a/>'; SELECT @x.exist('/local:zz') AS ex;
GO
DECLARE @x XML = '<a/>'; SELECT @x.exist('/xsd:zz') AS ex;
GO
DECLARE @x XML = '<a/>'; SELECT @x.exist('/op:zz') AS ex;
GO
DECLARE @x XML = '<a/>'; SELECT @x.exist('/xmlns:zz') AS ex;
GO
DECLARE @x XML = '<a/>'; SELECT @x.exist('/err:zz') AS ex;
GO
DECLARE @x XML = '<a/>'; SELECT @x.exist('/sqlxml:zz') AS ex;
GO
DECLARE @x XML = '<a/>'; SELECT @x.exist('/xf:zz') AS ex;
GO
-- 36.4 The clause may rebind a predefined prefix (T-SQL 1)
DECLARE @x XML = '<r xmlns:q="urn:my"><q:b>1</q:b></r>';
WITH XMLNAMESPACES('urn:my' AS xs)
SELECT @x.value('(/r/xs:b)[1]', 'INT') AS v;
GO
-- 36.5 A prefix only inside string literals, at batch level and in a
-- procedure body (T-SQL zz:a|1 twice)
DECLARE @x XML = '<a b="zz:x"/>'; SELECT @x.value('concat("zz:a", "")', 'VARCHAR(10)') AS s, @x.exist('/a[@b="zz:x"]') AS ex;
GO
CREATE PROCEDURE xmlns_methods_nsproc_lit AS
BEGIN
    DECLARE @x XML = '<a b="zz:x"/>';
    SELECT @x.value('concat("zz:a", "")', 'VARCHAR(10)') AS s, @x.exist('/a[@b="zz:x"]') AS ex;
END
GO
EXEC xmlns_methods_nsproc_lit;
GO
-- 36.6 A prefix only inside a comment, at batch level, nested, and in a
-- procedure body (T-SQL 1 for each)
DECLARE @x XML = '<a/>'; SELECT @x.exist('/a (: x:b :)') AS ex1, @x.exist('/a (: x:b (: y:c :) :)') AS ex2;
GO
CREATE PROCEDURE xmlns_methods_nsproc_cmt AS
BEGIN
    DECLARE @x XML = '<a/>';
    SELECT @x.exist('/a (: x:b :)') AS ex;
END
GO
EXEC xmlns_methods_nsproc_cmt;
GO
-- 36.7 Axis steps with no clause (T-SQL 1|1|3)
DECLARE @x XML = '<a><b/></a>'; SELECT @x.value('count(child::a)', 'INT') AS c1, @x.exist('self::node()') AS e1, @x.value('count(descendant-or-self::node())', 'INT') AS c2;
GO
-- 36.8 xsi with no clause: an attribute and an element (T-SQL 1, 1)
DECLARE @x XML = '<r xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:nil="true"/>';
SELECT @x.value('count(/r/@xsi:nil)', 'INT') AS c;
GO
DECLARE @x XML = '<r xmlns:q="http://www.w3.org/2001/XMLSchema-instance"><q:b>1</q:b></r>';
SELECT @x.value('(/r/xsi:b)[1]', 'INT') AS v;
GO
-- 36.9 A prolog binds the prefix (T-SQL 1); a prefix the prolog does not
-- bind is still reported (T-SQL 2229)
DECLARE @x XML = '<r xmlns:e="urn:emp" e:a="1" c="3"/>';
SELECT @x.value('declare namespace e="urn:emp"; count(/r/@e:*)', 'INT') AS wild;
GO
DECLARE @x XML = '<a/>'; SELECT @x.exist('declare namespace e="urn:e"; /a/z:b') AS ex;
GO
-- 36.10 Bound only by the document, with no clause (T-SQL 2229 for value(),
-- exist(), query() and nodes())
DECLARE @x XML = '<x:a xmlns:x="urn:x">1</x:a>'; SELECT @x.value('(/x:a)[1]', 'INT') AS v;
GO
DECLARE @x XML = '<x:a xmlns:x="urn:x">1</x:a>'; SELECT @x.exist('/x:a') AS ex;
GO
DECLARE @x XML = '<x:a xmlns:x="urn:x">1</x:a>'; SELECT @x.query('/x:a') AS q;
GO
DECLARE @x XML = '<x:a xmlns:x="urn:x">1</x:a>'; SELECT COUNT(*) AS c FROM @x.nodes('/x:a') AS n(c);
GO
-- 36.11 An XQuery in a variable is rejected before any prefix is looked at
-- (T-SQL 8172 text): with no prefix, with an undeclared prefix, with a
-- declared one, and in a procedure body, where the CREATE is rejected
DECLARE @x XML = '<a>1</a>'; DECLARE @p NVARCHAR(100) = N'(/a)[1]';
SELECT @x.value(@p, 'INT') AS v;
GO
DECLARE @x XML = '<z:a xmlns:z="urn:z">1</z:a>'; DECLARE @p NVARCHAR(100) = N'(/z:a)[1]';
SELECT @x.value(@p, 'INT') AS v;
GO
DECLARE @x XML = '<z:a xmlns:z="urn:z">1</z:a>'; DECLARE @p NVARCHAR(100) = N'(/z:a)[1]';
WITH XMLNAMESPACES('urn:z' AS z)
SELECT @x.value(@p, 'INT') AS v;
GO
CREATE PROCEDURE xmlns_methods_nsproc_var2 AS
BEGIN
    DECLARE @x XML = '<a>1</a>'; DECLARE @p NVARCHAR(100) = N'(/a)[1]';
    SELECT @x.value(@p, 'INT') AS v;
END
GO
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_var2;
GO
-- 36.12 fn: and xs: functions and sql:variable() raise no 2229. T-SQL returns
-- 1, 5 and 5. Babelfish raises "could not create XPath object": XPath 1.0
-- has no fn: or xs: functions, and sql:variable() is not supported.
DECLARE @x XML = '<a/>'; SELECT @x.value('fn:count(/a)', 'INT') AS c;
GO
DECLARE @x XML = '<a/>'; SELECT @x.value('xs:int("5")', 'INT') AS i;
GO
DECLARE @v INT = 5; DECLARE @x XML = '<a/>'; SELECT @x.value('sql:variable("@v")', 'INT') AS v;
GO
-- 36.13 DEFAULT binds no prefix (T-SQL 2229)
DECLARE @x XML = '<x:a xmlns:x="urn:x">1</x:a>';
WITH XMLNAMESPACES(DEFAULT 'urn:x') SELECT @x.value('(/x:a)[1]', 'INT') AS v;
GO
-- 36.14 No statement of the batch runs: the clause is on statement 1 only,
-- and a SELECT comes first (T-SQL only 2229 for each batch)
DECLARE @x XML = '<x:a xmlns:x="urn:x">1</x:a>';
WITH XMLNAMESPACES('urn:x' AS x) SELECT @x.value('(/x:a)[1]', 'INT') AS v1;
SELECT @x.value('(/x:a)[1]', 'INT') AS v2;
GO
DECLARE @x XML = '<x:a xmlns:x="urn:x">1</x:a>';
SELECT 1 AS first_stmt;
SELECT @x.value('(/x:a)[1]', 'INT') AS v;
GO
-- 36.15 The CREATE is rejected: a procedure with the clause on statement 1
-- only, a procedure and a function with no clause (T-SQL 2229 for each, so
-- none of them exists: 0)
CREATE PROCEDURE xmlns_methods_nsproc_u1 AS
BEGIN
    DECLARE @x XML = '<x:a xmlns:x="urn:x">1</x:a>';
    WITH XMLNAMESPACES('urn:x' AS x) SELECT @x.value('(/x:a)[1]', 'INT') AS v1;
    SELECT @x.value('(/x:a)[1]', 'INT') AS v2;
END
GO
CREATE PROCEDURE xmlns_methods_nsproc_u2 AS
BEGIN
    DECLARE @x XML = '<x:a xmlns:x="urn:x">1</x:a>';
    SELECT @x.exist('/x:a') AS ex;
END
GO
CREATE FUNCTION xmlns_methods_nsfn_u1() RETURNS INT AS
BEGIN
    DECLARE @x XML = '<x:a xmlns:x="urn:x">1</x:a>';
    RETURN @x.value('(/x:a)[1]', 'INT');
END
GO
SELECT COUNT(*) FROM sys.objects WHERE name IN ('xmlns_methods_nsproc_u1', 'xmlns_methods_nsproc_u2', 'xmlns_methods_nsfn_u1');
GO
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_u1;
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_u2;
DROP FUNCTION IF EXISTS xmlns_methods_nsfn_u1;
GO
-- 36.16 A procedure that uses only predefined prefixes (T-SQL 0|0)
CREATE PROCEDURE xmlns_methods_nsproc_pre AS
BEGIN
    DECLARE @x XML = '<a/>';
    SELECT @x.exist('/xs:zz') AS e1, @x.exist('/xsi:zz') AS e2;
END
GO
EXEC xmlns_methods_nsproc_pre;
GO
-- 36.17 The clause binds the prefix in its CTEs and subqueries: CTE form at
-- batch level (T-SQL 4), a CTE of the statement form (T-SQL 8), a subquery
-- (T-SQL 6), and a CTE in a procedure body (T-SQL 5)
WITH XMLNAMESPACES('urn:x' AS x), c AS (SELECT CAST('<x:a xmlns:x="urn:x">4</x:a>' AS XML) AS d) SELECT d.value('(/x:a)[1]', 'INT') AS v FROM c;
GO
DECLARE @x XML = '<x:a xmlns:x="urn:x">8</x:a>';
WITH XMLNAMESPACES('urn:x' AS x), c AS (SELECT @x.value('(/x:a)[1]', 'INT') AS v) SELECT v FROM c;
GO
DECLARE @x XML = '<x:a xmlns:x="urn:x">6</x:a>';
WITH XMLNAMESPACES('urn:x' AS x) SELECT (SELECT @x.value('(/x:a)[1]', 'INT')) AS v;
GO
CREATE PROCEDURE xmlns_methods_nsproc_cte2 AS
BEGIN
    DECLARE @x XML = '<x:a xmlns:x="urn:x">5</x:a>';
    WITH XMLNAMESPACES('urn:x' AS x), c AS (SELECT @x.value('(/x:a)[1]', 'INT') AS v) SELECT v FROM c;
END
GO
EXEC xmlns_methods_nsproc_cte2;
GO
-- 36.18 An undeclared prefix only in a predicate (T-SQL 2229)
DECLARE @x XML = '<a/>'; SELECT @x.exist('/a[x:b]') AS ex;
GO
-- 36.19 A direct element constructor binds its own prefix, so there is no
-- 2229. T-SQL returns <a xmlns:p="urn:p"><p:b/></a>. Babelfish raises
-- "invalid XPath expression": XPath 1.0 has no constructors.
DECLARE @x XML = '<a/>'; SELECT @x.query('<a xmlns:p="urn:p"><p:b/></a>') AS q;
GO
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_lit;
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_cmt;
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_pre;
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_cte2;
GO
-- ============================================
-- SECTION 37: XQuery comments and a namespace prolog
-- Comments (: ... :), which may nest, are ignored. A leading prolog of
-- "declare namespace p = uri;" declarations binds its prefixes for the
-- query, after the clause's, so the prolog wins.
-- ============================================
-- 37.1 A comment between steps (T-SQL 2)
DECLARE @x XML = '<r><b/><b/></r>'; SELECT @x.value('count(/r (: c :)/b)', 'INT') AS c;
GO
-- 37.2 A nested comment (T-SQL 2)
DECLARE @x XML = '<r><b/><b/></r>'; SELECT @x.value('count(/r (: a (: b :) c :)/b)', 'INT') AS c;
GO
-- 37.3 A comment inside a predicate (T-SQL 1)
DECLARE @x XML = '<r><b n="1"/><b n="2"/></r>'; SELECT @x.value('count(/r/b[(: c :) @n = 1])', 'INT') AS c;
GO
-- 37.4 Two declarations (T-SQL 3)
DECLARE @x XML = '<r xmlns:e="urn:emp" xmlns:f="urn:f"><e:a>1</e:a><f:b>2</f:b></r>';
SELECT @x.value('declare namespace e="urn:emp"; declare namespace f="urn:f"; (/r/e:a)[1] + (/r/f:b)[1]', 'INT') AS v;
GO
-- 37.5 A URI in single quotes (T-SQL 7)
DECLARE @x XML = '<r xmlns:e="urn:emp"><e:a>7</e:a></r>';
SELECT @x.value('declare namespace e=''urn:emp''; (/r/e:a)[1]', 'INT') AS v;
GO
-- 37.6 A prolog in .nodes()
-- 37.6a Methods on the rows with no prefix (T-SQL emp|2, emp|1)
DECLARE @x XML = '<r xmlns:e="urn:emp"><e:emp e:id="1" p="x"/><e:emp e:id="2"/></r>';
SELECT n.c.value('local-name(.)', 'VARCHAR(10)') AS ln, n.c.value('count(@*)', 'INT') AS ca
FROM @x.nodes('declare namespace e="urn:emp"; /r/e:emp') AS n(c);
GO
-- 37.6b The prolog of .nodes() does not bind e for the methods on its rows
-- (T-SQL 2229)
DECLARE @x XML = '<r xmlns:e="urn:emp"><e:emp e:id="1" p="x"/><e:emp e:id="2"/></r>';
SELECT n.c.value('count(@e:*)', 'INT') AS ce
FROM @x.nodes('declare namespace e="urn:emp"; /r/e:emp') AS n(c);
GO
-- 37.6c The methods on the rows bind e with their own prolog (T-SQL 1, 1),
-- or with the clause while .nodes() uses its prolog (T-SQL 1, 1)
DECLARE @x XML = '<r xmlns:e="urn:emp"><e:emp e:id="1" p="x"/><e:emp e:id="2"/></r>';
SELECT n.c.value('declare namespace e="urn:emp"; count(@e:*)', 'INT') AS ce
FROM @x.nodes('declare namespace e="urn:emp"; /r/e:emp') AS n(c);
GO
DECLARE @x XML = '<r xmlns:e="urn:emp"><e:emp e:id="1"/><e:emp e:id="2"/></r>';
WITH XMLNAMESPACES('urn:emp' AS e)
SELECT n.c.value('count(@e:*)', 'INT') AS ce
FROM @x.nodes('declare namespace f="urn:emp"; /r/f:emp') AS n(c);
GO
-- 37.6d The prolog of .nodes() and the prolog of a method on its rows bind
-- e to different URIs. T-SQL returns A. Babelfish returns NULL: the context
-- node path and the method's query are evaluated as one XPath with one set
-- of bindings, so the method's binding of e applies to both.
DECLARE @x XML = '<r xmlns:e="urn:emp" xmlns:o="urn:other"><e:emp o:id="1"><o:n>A</o:n></e:emp></r>';
SELECT n.c.value('declare namespace e="urn:other"; (e:n)[1]', 'VARCHAR(10)') AS v
FROM @x.nodes('declare namespace e="urn:emp"; /r/e:emp') AS n(c);
GO
-- 37.7 The prolog rebinds a clause prefix (T-SQL 2)
DECLARE @x XML = '<r xmlns:a="urn:one" xmlns:b="urn:two"><a:v>1</a:v><b:v>2</b:v></r>';
WITH XMLNAMESPACES('urn:one' AS p)
SELECT @x.value('declare namespace p="urn:two"; (/r/p:v)[1]', 'INT') AS v;
GO
-- 37.8 declare default element namespace. T-SQL returns 1. Babelfish raises
-- "invalid XPath expression": only namespace declarations are taken from
-- the prolog.
DECLARE @x XML = '<a xmlns="urn:x"/>';
SELECT @x.value('declare default element namespace "urn:x"; count(/a)', 'INT') AS c;
GO
-- ============================================
-- SECTION 38: an attribute wildcard whose URI holds both quote kinds
-- @e:* matches only attributes in the namespace bound to e.
-- ============================================
-- 38.1 value(), @e:* (T-SQL 0)
DECLARE @x XML = '<a xmlns:f="urn:f" f:x="1" y="2"/>';
WITH XMLNAMESPACES('urn:a''b"c' AS e)
SELECT @x.value('count(/a/@e:*)', 'INT') AS c;
GO
-- 38.2 value(), attribute::e:* (T-SQL 0)
DECLARE @x XML = '<a xmlns:f="urn:f" f:x="1" y="2"/>';
WITH XMLNAMESPACES('urn:a''b"c' AS e)
SELECT @x.value('count(/a/attribute::e:*)', 'INT') AS c;
GO
-- 38.3 exist() (T-SQL 0)
DECLARE @x XML = '<a xmlns:f="urn:f" f:x="1" y="2"/>';
WITH XMLNAMESPACES('urn:a''b"c' AS e)
SELECT @x.exist('/a/@e:*') AS ex;
GO
-- 38.4 A URI that starts and ends with quotes and holds adjacent quotes
-- (T-SQL 0)
DECLARE @x XML = '<a y="2"/>';
WITH XMLNAMESPACES('"''u''""' AS e)
SELECT @x.value('count(/a/@e:*)', 'INT') AS c;
GO
-- 38.5 Next to a binding with no quotes (T-SQL 1)
DECLARE @x XML = '<a xmlns:f="urn:f" f:x="1" y="2"/>';
WITH XMLNAMESPACES('urn:a''b"c' AS e, 'urn:f' AS f)
SELECT @x.value('count(/a/@e:*) * 10 + count(/a/@f:*)', 'INT') AS c;
GO
-- 38.6 In a method on the rows of .nodes(), and in the .nodes() path
-- (T-SQL 0, 0)
DECLARE @x XML = '<a xmlns:f="urn:f" f:x="1" y="2"/>';
WITH XMLNAMESPACES('urn:a''b"c' AS e)
SELECT n.c.value('count(@e:*)', 'INT') AS c FROM @x.nodes('/a') AS n(c);
GO
DECLARE @x XML = '<a xmlns:f="urn:f" f:x="1" y="2"/>';
WITH XMLNAMESPACES('urn:a''b"c' AS e)
SELECT COUNT(*) AS c FROM @x.nodes('/a[@e:*]') AS n(c);
GO
-- ============================================
-- SECTION 39: what a namespace prolog cannot declare
-- As in WITH XMLNAMESPACES, a prolog cannot declare xmlns or the same prefix
-- twice, and can bind xml only to the XML namespace URI and that URI only
-- to xml.
-- ============================================
-- 39.1 xml bound to another URI (T-SQL 2206)
DECLARE @x XML = '<a b="1"/>';
SELECT @x.query('declare namespace xml="urn:x"; /a') AS r;
GO
-- 39.2 xml bound to its own URI (T-SQL <a b="1"/>)
DECLARE @x XML = '<a b="1"/>';
SELECT @x.query('declare namespace xml="http://www.w3.org/XML/1998/namespace"; /a') AS r;
GO
-- 39.3 xmlns (T-SQL 2349)
DECLARE @x XML = '<a b="1"/>';
SELECT @x.query('declare namespace xmlns="u"; /a') AS r;
GO
-- 39.4 Another prefix bound to the XML namespace URI (T-SQL 2206)
DECLARE @x XML = '<a b="1"/>';
SELECT @x.query('declare namespace q="http://www.w3.org/XML/1998/namespace"; /a') AS r;
GO
-- 39.5 The same prefix declared twice (T-SQL 2349)
DECLARE @x XML = '<a b="1"/>';
SELECT @x.query('declare namespace p="u1"; declare namespace p="u2"; /a') AS r;
GO
-- 39.6 In value(), exist() and .nodes() (T-SQL 2206, 2349, 2206)
DECLARE @x XML = '<a b="1"/>';
SELECT @x.value('declare namespace xml="urn:x"; count(/a)', 'INT') AS c;
GO
DECLARE @x XML = '<a b="1"/>';
SELECT @x.exist('declare namespace xmlns="u"; /a') AS ex;
GO
DECLARE @x XML = '<a b="1"/>';
SELECT n.c.query('.') AS r FROM @x.nodes('declare namespace xml="urn:x"; /a') AS n(c);
GO
-- 39.7 The first rule broken is reported (T-SQL 2349 for p)
DECLARE @x XML = '<a b="1"/>';
SELECT @x.query('declare namespace p="u1"; declare namespace p="u2"; declare namespace xmlns="u"; /a') AS r;
GO
-- ============================================
-- SECTION 40: direct constructors after a keyword, nested .nodes() prologs
-- After return, then, else and the other keywords that take an expression,
-- "<name" starts a direct element constructor. Its own namespace
-- declarations, element names and text are not checked when the routine is
-- created. Babelfish has no constructors and FLWOR at run time, so EXEC
-- raises "invalid XPath expression" where T-SQL returns the constructed
-- element. Each .nodes() query keeps its own prolog.
-- ============================================
-- 40.1 return of a constructor that declares q for its child: the CREATE
-- succeeds (T-SQL 1, then other_stmt 1 and <r xmlns:q="urn:q"><q:c/></r>)
CREATE PROCEDURE xmlns_methods_nsproc_k1 AS
BEGIN
    DECLARE @x XML = '<a/>';
    SELECT 1 AS other_stmt;
    SELECT @x.query('for $i in /a return <r xmlns:q="urn:q"><q:c/></r>') AS r;
END
GO
SELECT COUNT(*) FROM sys.procedures WHERE name = 'xmlns_methods_nsproc_k1';
GO
EXEC xmlns_methods_nsproc_k1;
GO
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_k1;
GO
-- 40.2 then followed by a constructor whose text holds a colon: the CREATE
-- succeeds (T-SQL 1, then <r>Error:x</r>)
CREATE PROCEDURE xmlns_methods_nsproc_k2 AS
BEGIN
    DECLARE @x XML = '<a/>';
    SELECT @x.query('if (/a) then <r>Error:x</r> else ()') AS r;
END
GO
SELECT COUNT(*) FROM sys.procedures WHERE name = 'xmlns_methods_nsproc_k2';
GO
EXEC xmlns_methods_nsproc_k2;
GO
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_k2;
GO
-- 40.3 return of a prefixed constructor that binds its own prefix: the
-- CREATE succeeds (T-SQL 1, then <q:r xmlns:q="urn:q"/>)
CREATE PROCEDURE xmlns_methods_nsproc_k3 AS
BEGIN
    DECLARE @x XML = '<a/>';
    SELECT @x.query('for $i in /a return <q:r xmlns:q="urn:q"/>') AS r;
END
GO
SELECT COUNT(*) FROM sys.procedures WHERE name = 'xmlns_methods_nsproc_k3';
GO
EXEC xmlns_methods_nsproc_k3;
GO
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_k3;
GO
-- 40.4 An unbound prefix in a path after return is still rejected when the
-- routine is created (T-SQL 2229, then 0)
CREATE PROCEDURE xmlns_methods_nsproc_k4 AS
BEGIN
    DECLARE @x XML = '<a><b/></a>';
    SELECT @x.query('for $i in /a return $i/zz:b') AS r;
END
GO
SELECT COUNT(*) FROM sys.procedures WHERE name = 'xmlns_methods_nsproc_k4';
GO
DROP PROCEDURE IF EXISTS xmlns_methods_nsproc_k4;
GO
-- 40.5 Nested .nodes() whose prologs both declare e (T-SQL 1, 2)
DECLARE @x XML = '<e:a xmlns:e="urn:e"><e:b>1</e:b><e:b>2</e:b></e:a>';
SELECT d.value('.', 'INT') AS v
FROM @x.nodes('declare namespace e="urn:e"; /e:a') AS T(c)
CROSS APPLY c.nodes('declare namespace e="urn:e"; e:b') AS S(d);
GO
-- 40.6 Nested .nodes(), outer prolog e and inner prolog f for the same URI
-- (T-SQL 1, 2)
DECLARE @x XML = '<e:a xmlns:e="urn:e"><e:b>1</e:b><e:b>2</e:b></e:a>';
SELECT d.value('.', 'INT') AS v
FROM @x.nodes('declare namespace e="urn:e"; /e:a') AS T(c)
CROSS APPLY c.nodes('declare namespace f="urn:e"; f:b') AS S(d);
GO
-- 40.7 Nested .nodes(), the inner prolog binds e to another URI that the
-- document does not use (T-SQL no rows)
DECLARE @x XML = '<e:a xmlns:e="urn:e"><e:b>1</e:b><e:b>2</e:b></e:a>';
SELECT d.value('.', 'INT') AS v
FROM @x.nodes('declare namespace e="urn:e"; /e:a') AS T(c)
CROSS APPLY c.nodes('declare namespace e="urn:other"; e:b') AS S(d);
GO
-- 40.8 Nested .nodes(), the inner prolog binds e to the URI of the inner
-- elements. T-SQL returns 1. Babelfish returns no rows: the outer and inner
-- paths are evaluated as one XPath with one set of bindings, so the inner
-- binding of e applies to both.
DECLARE @x XML = '<e:a xmlns:e="urn:e"><f:b xmlns:f="urn:f">1</f:b></e:a>';
SELECT d.value('.', 'INT') AS v
FROM @x.nodes('declare namespace e="urn:e"; /e:a') AS T(c)
CROSS APPLY c.nodes('declare namespace e="urn:f"; e:b') AS S(d);
GO
