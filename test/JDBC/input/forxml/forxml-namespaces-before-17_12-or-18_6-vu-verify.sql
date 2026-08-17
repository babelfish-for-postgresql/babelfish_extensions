-- ============================================
-- WITH XMLNAMESPACES + FOR XML (RAW, PATH, AUTO)
--
-- Scope: WITH XMLNAMESPACES declares prefix-to-URI mappings for one
-- statement. T-SQL emits xmlns:prefix="uri" attributes on the appropriate
-- elements:
--   - FOR XML RAW: on each row element
--   - FOR XML PATH: on the outermost row element
--   - FOR XML AUTO: on the outermost (table-named) element
-- DEFAULT 'uri' emits xmlns="uri" 
-- ============================================

-- ============================================
-- SECTION 1: FOR XML RAW
-- ============================================

-- 1.1 Basic single-prefix RAW with no prefix used in row/cols
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID, EmpName FROM forxml_ns_employees WHERE EmpID = 1 FOR XML RAW;
GO

-- 1.2 RAW with named row, no prefix in row/cols
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID, EmpName FROM forxml_ns_employees WHERE EmpID = 1 FOR XML RAW('Emp');
GO

-- 1.3 RAW with prefixed row name, no prefix in cols
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID, EmpName FROM forxml_ns_employees WHERE EmpID = 1 FOR XML RAW('ns1:Emp');
GO

-- 1.4 RAW with prefixed column aliases
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML RAW('ns1:Emp');
GO

-- 1.5 Multiple prefixes, each used in different columns
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1, 'http://example.com/ns2' AS ns2)
SELECT EmpID AS [ns1:ID], EmpName AS [ns2:Name]
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML RAW('ns1:Emp');
GO

-- 1.6 DEFAULT namespace
WITH XMLNAMESPACES(DEFAULT 'http://example.com/default')
SELECT EmpID, EmpName FROM forxml_ns_employees WHERE EmpID = 1 FOR XML RAW;
GO

-- 1.7 DEFAULT + prefix combined
WITH XMLNAMESPACES(DEFAULT 'http://example.com/default', 'http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML RAW('ns1:Emp');
GO

-- 1.8 RAW + ELEMENTS
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML RAW('ns1:Emp'), ELEMENTS;
GO

-- 1.9 RAW + ELEMENTS XSINIL with NULL value
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name], Dept AS [ns1:Dept]
FROM forxml_ns_employees WHERE EmpID = 3 FOR XML RAW('ns1:Emp'), ELEMENTS XSINIL;
GO

-- 1.10 RAW + ELEMENTS ABSENT (NULLs dropped)
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name], Dept AS [ns1:Dept]
FROM forxml_ns_employees WHERE EmpID = 3 FOR XML RAW('ns1:Emp'), ELEMENTS ABSENT;
GO

-- 1.11 RAW + ROOT (unprefixed root)
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML RAW('ns1:Emp'), ROOT('Doc');
GO

-- 1.12 RAW + ROOT (prefixed root)
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML RAW('ns1:Emp'), ROOT('ns1:Doc');
GO

-- 1.13 RAW + TYPE
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML RAW('ns1:Emp'), TYPE;
GO

-- 1.14 RAW + ROOT + TYPE
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML RAW('ns1:Emp'), ROOT('ns1:Doc'), TYPE;
GO

-- 1.15 RAW multi-row with namespaces
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees FOR XML RAW('ns1:Emp');
GO

-- 1.16 RAW with view as the source
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_view1 WHERE EmpID = 1 FOR XML RAW('ns1:Emp');
GO

-- 1.17 RAW with computed expression and prefixed alias
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID + 100 AS [ns1:OffsetID], UPPER(EmpName) AS [ns1:UpperName]
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML RAW('ns1:Emp');
GO

-- ============================================
-- SECTION 2: FOR XML PATH
-- ============================================

-- 2.1 PATH with prefix on row and column elements
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML PATH('ns1:Emp');
GO

-- 2.2 PATH default row name with prefix on cols only
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML PATH;
GO

-- 2.3 PATH with attribute-centric prefix (@)
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [@ns1:id], EmpName AS [ns1:Name]
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML PATH('ns1:Emp');
GO

-- 2.4 PATH + ROOT prefixed
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML PATH('ns1:Emp'), ROOT('ns1:Doc');
GO

-- 2.5 PATH + ELEMENTS XSINIL with NULL
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name], Dept AS [ns1:Dept]
FROM forxml_ns_employees WHERE EmpID = 3 FOR XML PATH('ns1:Emp'), ELEMENTS XSINIL;
GO

-- 2.6 PATH + DEFAULT namespace
WITH XMLNAMESPACES(DEFAULT 'http://example.com/default')
SELECT EmpID AS ID, EmpName AS Name
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML PATH('Emp');
GO

-- 2.7 PATH + DEFAULT + prefix
WITH XMLNAMESPACES(DEFAULT 'http://example.com/default', 'http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML PATH('ns1:Emp');
GO

-- 2.8 PATH + multiple prefixes
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1, 'http://example.com/ns2' AS ns2)
SELECT EmpID AS [ns1:ID], EmpName AS [ns2:Name]
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML PATH('ns1:Emp');
GO

-- 2.9 PATH + ROOT + TYPE
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees WHERE EmpID = 1
FOR XML PATH('ns1:Emp'), ROOT('ns1:Doc'), TYPE;
GO

-- 2.10 PATH multi-row
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees FOR XML PATH('ns1:Emp');
GO

-- ============================================
-- SECTION 3: FOR XML AUTO
-- ============================================

-- 3.1 AUTO with prefixed table name
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT forxml_ns_employees.EmpID, forxml_ns_employees.EmpName
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML AUTO;
GO

-- 3.2 AUTO + ELEMENTS
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT forxml_ns_employees.EmpID, forxml_ns_employees.EmpName
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML AUTO, ELEMENTS;
GO

-- 3.3 AUTO + ROOT
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT forxml_ns_employees.EmpID, forxml_ns_employees.EmpName
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML AUTO, ROOT('Doc');
GO

-- 3.4 AUTO + DEFAULT + prefix
WITH XMLNAMESPACES(DEFAULT 'http://example.com/default', 'http://example.com/ns1' AS ns1)
SELECT forxml_ns_employees.EmpID, forxml_ns_employees.EmpName
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML AUTO;
GO

-- 3.5 AUTO + TYPE
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT forxml_ns_employees.EmpID, forxml_ns_employees.EmpName
FROM forxml_ns_employees WHERE EmpID = 1 FOR XML AUTO, TYPE;
GO

-- 3.6 AUTO + ELEMENTS XSINIL + NULL row
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT forxml_ns_employees.EmpID, forxml_ns_employees.EmpName, forxml_ns_employees.Dept
FROM forxml_ns_employees WHERE EmpID = 3 FOR XML AUTO, ELEMENTS XSINIL;
GO

-- 3.7 AUTO multi-row
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT forxml_ns_employees.EmpID, forxml_ns_employees.EmpName
FROM forxml_ns_employees FOR XML AUTO;
GO

-- 3.8 AUTO with JOIN (parent-child nesting)
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT e.EmpID, e.EmpName, o.OrderID, o.Amount
FROM forxml_ns_employees e
JOIN forxml_ns_orders o ON e.EmpID = o.EmpID
ORDER BY e.EmpID, o.OrderID
FOR XML AUTO;
GO

-- 3.9 AUTO with JOIN + ELEMENTS
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT e.EmpID, e.EmpName, o.OrderID, o.Amount
FROM forxml_ns_employees e
JOIN forxml_ns_orders o ON e.EmpID = o.EmpID
ORDER BY e.EmpID, o.OrderID
FOR XML AUTO, ELEMENTS;
GO

-- 3.10 AUTO with JOIN + ROOT
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT e.EmpID, e.EmpName, o.OrderID, o.Amount
FROM forxml_ns_employees e
JOIN forxml_ns_orders o ON e.EmpID = o.EmpID
ORDER BY e.EmpID, o.OrderID
FOR XML AUTO, ROOT('Doc');
GO

-- 3.11 AUTO with LEFT JOIN, NULL children
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT e.EmpID, e.EmpName, o.OrderID, o.Amount
FROM forxml_ns_employees e
LEFT JOIN forxml_ns_orders o ON e.EmpID = o.EmpID
ORDER BY e.EmpID
FOR XML AUTO;
GO

-- 3.12 AUTO with CTE
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1),
ActiveEmps AS (SELECT EmpID, EmpName FROM forxml_ns_employees WHERE Dept IS NOT NULL)
SELECT a.EmpID, a.EmpName
FROM ActiveEmps a
FOR XML AUTO;
GO

-- 3.13 AUTO with subquery in FROM
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT sub.EmpID, sub.EmpName
FROM (SELECT EmpID, EmpName FROM forxml_ns_employees WHERE EmpID <= 2) sub
FOR XML AUTO;
GO

-- 3.14 AUTO multi-table JOIN with ELEMENTS XSINIL
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT e.EmpID, e.EmpName, e.Dept, o.OrderID, o.Amount
FROM forxml_ns_employees e
LEFT JOIN forxml_ns_orders o ON e.EmpID = o.EmpID
ORDER BY e.EmpID, o.OrderID
FOR XML AUTO, ELEMENTS XSINIL;
GO

-- 3.15 AUTO + DEFAULT ns + JOIN
WITH XMLNAMESPACES(DEFAULT 'http://default.com', 'http://example.com/ns1' AS ns1)
SELECT e.EmpID, e.EmpName, o.OrderID
FROM forxml_ns_employees e
JOIN forxml_ns_orders o ON e.EmpID = o.EmpID
ORDER BY e.EmpID
FOR XML AUTO;
GO

-- 3.16 AUTO with JOIN + TYPE
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT e.EmpID, e.EmpName, o.OrderID
FROM forxml_ns_employees e
JOIN forxml_ns_orders o ON e.EmpID = o.EmpID
ORDER BY e.EmpID
FOR XML AUTO, TYPE;
GO

-- ============================================
-- SECTION 4: Validation / Error cases
-- ============================================

-- 4.1 Duplicate prefix declaration
WITH XMLNAMESPACES('http://example.com/u1' AS ns1, 'http://example.com/u2' AS ns1)
SELECT 1 AS [ns1:a] FOR XML RAW('ns1:Row');
GO

-- 4.2 Multiple DEFAULT declarations
WITH XMLNAMESPACES(DEFAULT 'http://a', DEFAULT 'http://b')
SELECT 1 AS a FOR XML RAW;
GO

-- 4.3 Reserved 'xmlns' prefix
WITH XMLNAMESPACES('http://example.com' AS xmlns)
SELECT 1 AS [xmlns:a] FOR XML RAW;
GO

-- 4.4 Empty URI
WITH XMLNAMESPACES('' AS ns1)
SELECT 1 AS [ns1:a] FOR XML RAW;
GO

-- 4.5 Reserved 'xml' prefix re-bound to wrong URI
WITH XMLNAMESPACES('http://wrong.uri' AS xml)
SELECT 1 AS [xml:a] FOR XML RAW;
GO

-- 4.6 The XML namespace URI bound to a non-xml prefix
WITH XMLNAMESPACES('http://www.w3.org/XML/1998/namespace' AS notxml)
SELECT 1 AS a FOR XML RAW;
GO

-- 4.7 xsi prefix bound to xsi URI without XSINIL — alias should resolve
WITH XMLNAMESPACES('http://www.w3.org/2001/XMLSchema-instance' AS xsi)
SELECT 1 AS [xsi:a] FOR XML RAW;
GO

-- 4.8 xsi prefix bound to xsi URI with XSINIL — must not duplicate xmlns:xsi
WITH XMLNAMESPACES('http://www.w3.org/2001/XMLSchema-instance' AS xsi)
SELECT 1 AS a, NULL AS b FOR XML RAW, ELEMENTS XSINIL;
GO

-- ============================================
-- SECTION 5: CTE / subquery combinations
-- ============================================

-- 5.1 WITH XMLNAMESPACES followed by CTE (must come before CTE)
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1),
ns_cte AS (SELECT EmpID, EmpName FROM forxml_ns_employees WHERE EmpID = 1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name] FROM ns_cte FOR XML RAW('ns1:Emp');
GO

-- 5.2 Outer query with subquery that doesn't use namespaces
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM (SELECT EmpID, EmpName FROM forxml_ns_employees WHERE EmpID = 1) sub
FOR XML RAW('ns1:Emp');
GO

-- ============================================
-- SECTION 6: Mixed scalar types
-- ============================================

-- 6.1 numeric columns
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT OrderID AS [ns1:ID], Amount AS [ns1:Amt]
FROM forxml_ns_orders WHERE OrderID = 101 FOR XML RAW('ns1:Order');
GO

-- 6.2 NULL numeric with XSINIL
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT OrderID AS [ns1:ID], Amount AS [ns1:Amt]
FROM forxml_ns_orders WHERE OrderID = 103 FOR XML RAW('ns1:Order'), ELEMENTS XSINIL;
GO

-- ============================================
-- SECTION 7: All-NULL rows with XSINIL + namespaces
-- ============================================

-- 7.1 RAW
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT a AS [ns1:a], b AS [ns1:b] FROM forxml_ns_nullable WHERE a IS NULL AND b IS NULL
FOR XML RAW('ns1:Row'), ELEMENTS XSINIL;
GO

-- 7.2 PATH
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT a AS [ns1:a], b AS [ns1:b] FROM forxml_ns_nullable WHERE a IS NULL AND b IS NULL
FOR XML PATH('ns1:Row'), ELEMENTS XSINIL;
GO

-- ============================================
-- SECTION 8: View-based queries
-- ============================================

-- 8.1 SELECT FROM view with RAW
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT a AS [ns1:a], b AS [ns1:b] FROM forxml_ns_view2 FOR XML RAW('ns1:Row');
GO

-- 8.2 SELECT FROM view with PATH
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT a AS [ns1:a], b AS [ns1:b] FROM forxml_ns_view2 FOR XML PATH('ns1:Row');
GO

-- ============================================
-- SECTION 9: Special characters / unicode in URIs and values
-- ============================================

-- 9.1 URI with hash and percent characters
WITH XMLNAMESPACES('http://example.com/path#section%20path' AS ns1)
SELECT EmpID AS [ns1:ID] FROM forxml_ns_employees WHERE EmpID = 1
FOR XML RAW('ns1:Emp');
GO

-- 9.1b URI with ampersand (must be XML-escaped to &amp; in attribute value)
WITH XMLNAMESPACES('http://example.com/path?q=v&more' AS ns1)
SELECT EmpID AS [ns1:ID] FROM forxml_ns_employees WHERE EmpID = 1
FOR XML RAW('ns1:Emp');
GO

-- 9.1c URI with less-than (must be XML-escaped)
WITH XMLNAMESPACES('http://example.com/<x>' AS ns1)
SELECT EmpID AS [ns1:ID] FROM forxml_ns_employees WHERE EmpID = 1
FOR XML RAW('ns1:Emp');
GO

-- 9.2 Long URI
WITH XMLNAMESPACES('http://example.com/very/long/path/with/many/segments/that/goes/on/and/on/for/testing/purposes/only' AS ns1)
SELECT EmpID AS [ns1:ID] FROM forxml_ns_employees WHERE EmpID = 1
FOR XML RAW('ns1:Emp');
GO

-- ============================================
-- SECTION 10: Different data types
-- ============================================

-- 10.1 RAW with all data types prefixed
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT IntCol AS [ns1:Int], VarcharCol AS [ns1:Str], BitCol AS [ns1:Bit],
       DecimalCol AS [ns1:Dec], DateCol AS [ns1:Dt]
FROM forxml_ns_types WHERE IntCol = 100 FOR XML RAW('ns1:Row');
GO

-- 10.2 PATH with all data types and ELEMENTS XSINIL on NULL row
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT IntCol AS [ns1:Int], VarcharCol AS [ns1:Str], BitCol AS [ns1:Bit]
FROM forxml_ns_types WHERE IntCol IS NULL AND VarcharCol IS NULL
FOR XML PATH('ns1:Row'), ELEMENTS XSINIL;
GO

-- ============================================
-- SECTION 11: Special characters in values
-- ============================================

-- 11.1 Ampersand, less-than, quotes — RAW
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT ID AS [ns1:ID], Value AS [ns1:Value]
FROM forxml_ns_special FOR XML RAW('ns1:Row');
GO

-- 11.2 Embedded XML markup — PATH
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT ID AS [ns1:ID], Value AS [ns1:Value]
FROM forxml_ns_special WHERE ID = 4 FOR XML PATH('ns1:Row');
GO

-- ============================================
-- SECTION 12: Unicode/multibyte values
-- ============================================

-- 12.1 Multibyte values in column with prefixed alias
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT ID AS [ns1:ID], Name AS [ns1:Name]
FROM forxml_ns_unicode FOR XML RAW('ns1:Row');
GO

-- 12.2 Multibyte values with PATH ELEMENTS
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT ID AS [ns1:ID], Name AS [ns1:Name]
FROM forxml_ns_unicode FOR XML PATH('ns1:Row'), ELEMENTS;
GO

-- ============================================
-- SECTION 13: ORDER BY / TOP / GROUP BY
-- ============================================

-- 13.1 ORDER BY prefixed alias
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees ORDER BY EmpID DESC FOR XML RAW('ns1:Emp');
GO

-- 13.2 TOP with namespaces
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT TOP 2 EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees ORDER BY EmpID FOR XML RAW('ns1:Emp');
GO

-- 13.3 GROUP BY with COUNT and namespace
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT Dept AS [ns1:Dept], COUNT(*) AS [ns1:N]
FROM forxml_ns_employees GROUP BY Dept ORDER BY Dept FOR XML RAW('ns1:Group');
GO

-- ============================================
-- SECTION 14: WHERE clause variations
-- ============================================

-- 14.1 WHERE with IN
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees WHERE EmpID IN (1, 3) FOR XML RAW('ns1:Emp');
GO

-- 14.2 WHERE with LIKE
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees WHERE EmpName LIKE 'A%' FOR XML RAW('ns1:Emp');
GO

-- 14.3 WHERE with IS NULL
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
FROM forxml_ns_employees WHERE Dept IS NULL FOR XML RAW('ns1:Emp');
GO

-- ============================================
-- SECTION 15: UNION queries
-- ============================================

-- 15.1 UNION ALL with namespaces
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name] FROM forxml_ns_employees WHERE EmpID = 1
UNION ALL
SELECT EmpID, EmpName FROM forxml_ns_employees WHERE EmpID = 2
FOR XML RAW('ns1:Emp');
GO

-- 15.2 UNION (distinct) with namespaces
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name] FROM forxml_ns_employees WHERE EmpID = 1
UNION
SELECT EmpID, EmpName FROM forxml_ns_employees WHERE EmpID = 1
FOR XML RAW('ns1:Emp');
GO

-- ============================================
-- SECTION 16: Subqueries (correlated, in SELECT list)
-- ============================================

-- 16.1 Scalar subquery in SELECT list
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT e.EmpID AS [ns1:ID],
       (SELECT COUNT(*) FROM forxml_ns_orders o WHERE o.EmpID = e.EmpID) AS [ns1:OrderCount]
FROM forxml_ns_employees e WHERE e.EmpID <= 2 FOR XML RAW('ns1:Emp');
GO

-- 16.2 Subquery FOR XML returning XML inline (no TYPE — string concatenation)
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT e.EmpID AS [ns1:ID], e.EmpName AS [ns1:Name],
       (SELECT TOP 1 o.OrderID FROM forxml_ns_orders o WHERE o.EmpID = e.EmpID ORDER BY o.OrderID) AS [ns1:FirstOrderID]
FROM forxml_ns_employees e WHERE e.EmpID = 1
FOR XML RAW('ns1:Emp');
GO

-- ============================================
-- SECTION 17: SELECT INTO variable / SET assignment
-- ============================================

-- 17.1 SELECT INTO @var with namespaces
DECLARE @x XML;
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x = (SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
             FROM forxml_ns_employees WHERE EmpID = 1
             FOR XML RAW('ns1:Emp'), TYPE);
SELECT @x;
GO

-- 17.2 NVARCHAR variable with namespaces
DECLARE @s NVARCHAR(MAX);
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @s = (SELECT EmpID AS [ns1:ID]
             FROM forxml_ns_employees WHERE EmpID = 1
             FOR XML RAW('ns1:Emp'));
SELECT @s;
GO

-- ============================================
-- SECTION 18: XML methods on FOR XML result
-- ============================================

-- 18.1 .query() on FOR XML TYPE result
DECLARE @x XML;
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x = (SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
             FROM forxml_ns_employees WHERE EmpID = 1
             FOR XML RAW('ns1:Emp'), TYPE);
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.query('/ns1:Emp');
GO

-- 18.2 .value() on FOR XML TYPE result
DECLARE @x XML;
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x = (SELECT EmpID AS [ns1:ID], EmpName AS [ns1:Name]
             FROM forxml_ns_employees WHERE EmpID = 1
             FOR XML PATH('ns1:Emp'), TYPE);
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT @x.value('(/ns1:Emp/ns1:Name)[1]', 'varchar(50)');
GO

-- ============================================
-- SECTION 19: JOIN queries with namespaces (extended)
-- ============================================

-- 19.1 INNER JOIN with prefixed columns from both tables — RAW
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT e.EmpID AS [ns1:EmpID], e.EmpName AS [ns1:EmpName],
       o.OrderID AS [ns1:OrderID], o.Amount AS [ns1:Amount]
FROM forxml_ns_employees e
JOIN forxml_ns_orders o ON e.EmpID = o.EmpID
ORDER BY e.EmpID, o.OrderID FOR XML RAW('ns1:Row');
GO

-- 19.2 LEFT JOIN PATH with ELEMENTS XSINIL
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT e.EmpID AS [ns1:EmpID], o.OrderID AS [ns1:OrderID]
FROM forxml_ns_employees e
LEFT JOIN forxml_ns_orders o ON e.EmpID = o.EmpID
ORDER BY e.EmpID FOR XML PATH('ns1:Row'), ELEMENTS XSINIL;
GO

-- ============================================
-- SECTION 20: Custom row element name variations
-- ============================================

-- 20.1 RAW name with hyphens (NCName allows '-')
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID] FROM forxml_ns_employees WHERE EmpID = 1
FOR XML RAW('ns1:Emp-Record');
GO

-- 20.2 RAW name with underscores
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID] FROM forxml_ns_employees WHERE EmpID = 1
FOR XML RAW('ns1:Emp_Record');
GO

-- 20.3 PATH long element name
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID] FROM forxml_ns_employees WHERE EmpID = 1
FOR XML PATH('ns1:VeryLongElementNameUsedToTestBoundaryConditions');
GO

-- ============================================
-- SECTION 21: Empty result set
-- ============================================

-- 21.1 RAW with no rows returned
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID] FROM forxml_ns_employees WHERE EmpID = 999
FOR XML RAW('ns1:Emp');
GO

-- 21.2 PATH with no rows + ROOT
WITH XMLNAMESPACES('http://example.com/ns1' AS ns1)
SELECT EmpID AS [ns1:ID] FROM forxml_ns_employees WHERE EmpID = 999
FOR XML PATH('ns1:Emp'), ROOT('ns1:Doc');
GO

-- ============================================
-- SECTION 22: Undeclared prefix in column alias (colon restoration)
-- ============================================

-- 22.1 RAW attribute mode - undeclared prefix
SELECT 1 AS [ns:a] FOR XML RAW;
GO

-- 22.2 RAW ELEMENTS mode - undeclared prefix
SELECT 1 AS [ns:a] FOR XML RAW, ELEMENTS;
GO
-- ============================================
-- SECTION 23: Invalid prefix character validation in WITH XMLNAMESPACES
-- ============================================

-- 23.1 Special character in prefix - errors
WITH XMLNAMESPACES('http://test.com' AS [n@s1]) SELECT 'val' AS x FOR XML RAW;
GO

-- 23.2 Numeric first character - errors
WITH XMLNAMESPACES('http://test.com' AS [1ns]) SELECT 'val' AS x FOR XML RAW;
GO

-- 23.3 Hyphen first character - errors
WITH XMLNAMESPACES('http://test.com' AS [-ns]) SELECT 'val' AS x FOR XML RAW;
GO

-- 23.4 Hyphen mid-prefix - valid, passes
WITH XMLNAMESPACES('http://test.com' AS [n-s1]) SELECT 'val' AS x FOR XML RAW;
GO

-- 23.5 Digit mid-prefix - valid, passes
WITH XMLNAMESPACES('http://test.com' AS [ns123]) SELECT 'val' AS x FOR XML RAW;
GO

-- ============================================
-- SECTION 24: ns_decls_has_xsi must not false-match a URI substring
-- ============================================

-- 24.1 Declared URI contains "xmlns:xsi=" substring, with ELEMENTS XSINIL.
WITH XMLNAMESPACES('http://x/?xmlns:xsi=fake' AS n)
SELECT 1 AS a, CAST(NULL AS VARCHAR(10)) AS b
FOR XML RAW, ELEMENTS XSINIL;
GO

-- 24.2 Same false-match guard in PATH mode
WITH XMLNAMESPACES('http://x/?xmlns:xsi=fake' AS n)
SELECT 1 AS a, CAST(NULL AS VARCHAR(10)) AS b
FOR XML PATH('Row'), ELEMENTS XSINIL;
GO
