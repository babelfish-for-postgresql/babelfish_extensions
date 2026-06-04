-- ============================================
-- SECTION 1: Basic ELEMENTS directive
-- ============================================

-- Without ELEMENTS (regression test)
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee');
GO

-- With ELEMENTS
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS;
GO

-- With ELEMENTS ABSENT
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS ABSENT;
GO

-- With ELEMENTS XSINIL
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

-- ============================================
-- SECTION 2: NULL handling with ELEMENTS XSINIL
-- ============================================

-- Single row with no NULL values
SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 1 FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

-- Single row with NULL in middle column
SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 2 FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

-- Single row with all NULLs except ID
SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 4 FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

-- Row with NULL ID (ID=5 has NULL name and non-NULL dept)
SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 5 FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

-- All NULL columns
SELECT NULL AS Col1, NULL AS Col2, NULL AS Col3 FOR XML PATH('row'), ELEMENTS XSINIL;
GO

-- Mixed NULL and non-NULL values
SELECT 1 AS ID, NULL AS Name, 'Active' AS Status FOR XML PATH('Record'), ELEMENTS XSINIL;
GO

-- ============================================
-- SECTION 3: NULL handling with ELEMENTS ABSENT
-- ============================================

SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 2 FOR XML PATH('Employee'), ELEMENTS ABSENT;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 4 FOR XML PATH('Employee'), ELEMENTS ABSENT;
GO

SELECT NULL AS Col1, NULL AS Col2, NULL AS Col3 FOR XML PATH('row'), ELEMENTS ABSENT;
GO

SELECT NULL AS Col1, NULL AS Col2 FOR XML PATH('row'), ELEMENTS;
GO

SELECT 1 AS ID, NULL AS Name, 'Active' AS Status FOR XML PATH('Record'), ELEMENTS ABSENT;
GO

-- ============================================
-- SECTION 4: ELEMENTS with ROOT directive
-- ============================================

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ROOT('Data'), ELEMENTS XSINIL;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ROOT('Data'), ELEMENTS ABSENT;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ROOT('Data'), ELEMENTS;
GO

-- Different order of directives
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS XSINIL, ROOT('Data');
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS ABSENT, ROOT('Data');
GO

-- ============================================
-- SECTION 5: ELEMENTS with TYPE directive
-- ============================================

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), TYPE, ELEMENTS XSINIL;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), TYPE, ELEMENTS ABSENT;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ROOT('Data'), TYPE, ELEMENTS XSINIL;
GO

-- All directives combined - different order
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS XSINIL, TYPE, ROOT('Data');
GO

-- ============================================
-- SECTION 6: Empty element name (PATH(''))
-- ============================================

SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 2 FOR XML PATH(''), ELEMENTS XSINIL;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 2 FOR XML PATH(''), ELEMENTS ABSENT;
GO

-- PATH('') with ROOT — xmlns:xsi declared on ROOT only,
-- per-column declarations suppressed.
SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID IN (1,3) FOR XML PATH(''), ELEMENTS XSINIL, ROOT('Data');
GO

-- PATH('') with ROOT, mixed NULL columns.
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH(''), ELEMENTS XSINIL, ROOT('Data');
GO

-- PATH('') with ROOT, directive order swapped.
SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 2 FOR XML PATH(''), ROOT('Data'), ELEMENTS XSINIL;
GO

-- PATH('') with ROOT and TYPE combined.
SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 2 FOR XML PATH(''), ELEMENTS XSINIL, ROOT('Data'), TYPE;
GO

-- ============================================
-- SECTION 7: Multiple data types
-- ============================================

SELECT IntCol, VarcharCol, BitCol, DecimalCol, DateCol FROM forxml_path_elements_t2 FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT IntCol, VarcharCol, BitCol, DecimalCol, DateCol FROM forxml_path_elements_t2 FOR XML PATH('Row'), ELEMENTS ABSENT;
GO

SELECT IntCol, VarcharCol, BitCol, DecimalCol, DateCol FROM forxml_path_elements_t2 WHERE IntCol = 100 FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT IntCol, VarcharCol, BitCol, DecimalCol, DateCol FROM forxml_path_elements_t2 WHERE IntCol IS NULL FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

-- ============================================
-- SECTION 8: Various NULL patterns
-- ============================================

SELECT Col1, Col2, Col3 FROM forxml_path_elements_t3 FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT Col1, Col2, Col3 FROM forxml_path_elements_t3 FOR XML PATH('Row'), ELEMENTS ABSENT;
GO

SELECT Col1, Col2, Col3 FROM forxml_path_elements_t3 WHERE Col1 IS NULL AND Col2 IS NULL AND Col3 IS NULL FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT Col1, Col2, Col3 FROM forxml_path_elements_t3 WHERE Col1 IS NULL AND Col2 IS NULL AND Col3 IS NULL FOR XML PATH('Row'), ELEMENTS ABSENT;
GO

-- ============================================
-- SECTION 9: Attribute-centric columns with ELEMENTS
-- ============================================

SELECT ID, Name AS [@Name], Value FROM forxml_path_elements_t4 FOR XML PATH('Item'), ELEMENTS XSINIL;
GO

SELECT ID, Name AS [@Name], Value FROM forxml_path_elements_t4 FOR XML PATH('Item'), ELEMENTS ABSENT;
GO

-- Attribute-centric column with NULL value and XSINIL
SELECT ID, Name AS [@Name], Department FROM forxml_path_elements_t1 WHERE ID = 2 FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

-- Multiple attribute-centric columns with ELEMENTS XSINIL
SELECT ID AS [@ID], Name AS [@Name], Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

-- INNER JOIN with attribute-centric columns
SELECT c.CustomerName AS [@CustomerName], o.OrderID AS [@OrderID], o.TotalAmount
FROM forxml_path_elements_customers c
INNER JOIN forxml_path_elements_orders o ON c.CustomerID = o.CustomerID
ORDER BY o.OrderID
FOR XML PATH('Order'), ELEMENTS XSINIL;
GO

-- LEFT JOIN with attribute-centric columns
SELECT c.CustomerName AS [@Name], o.TotalAmount AS [@Amount], o.OrderID
FROM forxml_path_elements_customers c
LEFT JOIN forxml_path_elements_orders o ON c.CustomerID = o.CustomerID
ORDER BY c.CustomerID, o.OrderID
FOR XML PATH('CustomerOrder'), ELEMENTS XSINIL;
GO

-- Multiple JOINs with mixed attribute and element columns
SELECT c.CustomerName AS [@Customer], o.OrderID AS [@OrderID], oi.Quantity AS [@Qty], p.ProductName
FROM forxml_path_elements_customers c
INNER JOIN forxml_path_elements_orders o ON c.CustomerID = o.CustomerID
INNER JOIN forxml_path_elements_order_items oi ON o.OrderID = oi.OrderID
INNER JOIN forxml_path_elements_products p ON oi.ProductID = p.ProductID
ORDER BY o.OrderID, p.ProductID
FOR XML PATH('OrderDetail'), ELEMENTS XSINIL;
GO

-- LEFT JOIN with attribute-centric columns and ROOT
SELECT c.CustomerName AS [@Name], c.City AS [@City], o.OrderDate, o.TotalAmount
FROM forxml_path_elements_customers c
LEFT JOIN forxml_path_elements_orders o ON c.CustomerID = o.CustomerID
ORDER BY c.CustomerID, o.OrderID
FOR XML PATH('CustomerOrder'), ELEMENTS XSINIL, ROOT('Data');
GO

-- RIGHT JOIN with attribute-centric columns
SELECT c.CustomerName AS [@CustomerName], o.OrderDate AS [@Date], o.OrderID
FROM forxml_path_elements_customers c
RIGHT JOIN forxml_path_elements_orders o ON c.CustomerID = o.CustomerID
ORDER BY o.OrderID
FOR XML PATH('Order'), ELEMENTS XSINIL;
GO

-- CROSS JOIN with attribute-centric columns
SELECT a.ID AS [@ID1], b.ID AS [@ID2], a.Name AS Name1, b.Name AS Name2
FROM forxml_path_elements_t1 a
CROSS JOIN forxml_path_elements_t1 b
WHERE a.ID < b.ID AND a.ID <= 2
ORDER BY a.ID, b.ID
FOR XML PATH('Pair'), ELEMENTS XSINIL;
GO

-- ============================================
-- SECTION 10: Single column table
-- ============================================

SELECT SingleCol FROM forxml_path_elements_t5 FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT SingleCol FROM forxml_path_elements_t5 FOR XML PATH('Row'), ELEMENTS ABSENT;
GO

SELECT SingleCol FROM forxml_path_elements_t5 WHERE SingleCol IS NULL FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT SingleCol FROM forxml_path_elements_t5 WHERE SingleCol IS NULL FOR XML PATH('Row'), ELEMENTS ABSENT;
GO

-- ============================================
-- SECTION 11: Many columns
-- ============================================

SELECT Col1, Col2, Col3, Col4, Col5, Col6, Col7, Col8 FROM forxml_path_elements_t6 FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT Col1, Col2, Col3, Col4, Col5, Col6, Col7, Col8 FROM forxml_path_elements_t6 FOR XML PATH('Row'), ELEMENTS ABSENT;
GO

-- ============================================
-- SECTION 12: Text content
-- ============================================

SELECT ID, TextCol FROM forxml_path_elements_t7 FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT ID, TextCol FROM forxml_path_elements_t7 FOR XML PATH('Row'), ELEMENTS ABSENT;
GO

-- ============================================
-- SECTION 13: Empty result set
-- ============================================

SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 999 FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 999 FOR XML PATH('Employee'), ELEMENTS ABSENT;
GO

-- ============================================
-- SECTION 14: Special characters in values
-- ============================================

SELECT * FROM forxml_path_elements_special FOR XML PATH('Row'), ELEMENTS;
GO

SELECT * FROM forxml_path_elements_special FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT * FROM forxml_path_elements_special WHERE ID = 1 FOR XML PATH('Row'), ELEMENTS;
GO

SELECT * FROM forxml_path_elements_special WHERE ID = 6 FOR XML PATH('Row'), ELEMENTS;
GO

-- ============================================
-- SECTION 15: Unicode/Multibyte values (data values, not element names)
-- ============================================

SELECT * FROM forxml_path_elements_unicode FOR XML PATH('Row'), ELEMENTS;
GO

SELECT * FROM forxml_path_elements_unicode FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT * FROM forxml_path_elements_unicode WHERE ID = 1 FOR XML PATH('Row'), ELEMENTS;
GO

SELECT N'日本語' AS JapaneseName, N'中文' AS ChineseName FOR XML PATH('Names'), ELEMENTS;
GO

SELECT N'Ελληνικά' AS Greek, N'Русский' AS Russian FOR XML PATH('Names'), ELEMENTS XSINIL;
GO

SELECT N'مرحبا' AS Arabic, N'שלום' AS Hebrew FOR XML PATH('Names'), ELEMENTS;
GO

-- ============================================
-- SECTION 16: Long column names (>64 characters)
-- ============================================

SELECT * FROM forxml_path_elements_long_cols FOR XML PATH('Row'), ELEMENTS;
GO

SELECT * FROM forxml_path_elements_long_cols FOR XML PATH('Row'), ELEMENTS XSINIL;
GO

SELECT * FROM forxml_path_elements_long_cols FOR XML PATH('LongColTest'), ELEMENTS, ROOT('Data');
GO

-- ============================================
-- SECTION 17: Boundary cases for element names
-- ============================================

-- Single character element name
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('E'), ELEMENTS XSINIL;
GO

-- Element name with numbers
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee123'), ELEMENTS XSINIL;
GO

-- Element name starting with underscore
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('_Employee'), ELEMENTS XSINIL;
GO

-- Element name with hyphens
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee-Record'), ELEMENTS XSINIL;
GO

-- Element name with periods
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee.Record'), ELEMENTS XSINIL;
GO

-- Default element name (no name specified) with XSINIL
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH, ELEMENTS XSINIL;
GO

-- PATH (no parens) + XSINIL + ROOT: xmlns:xsi declared once on root.
SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 1 FOR XML PATH, ELEMENTS XSINIL, ROOT('Data');
GO

-- PATH (no parens) + XSINIL + ROOT + TYPE.
SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 1 FOR XML PATH, ELEMENTS XSINIL, ROOT('Data'), TYPE;
GO

-- PATH (no parens) + XSINIL + ROOT, all-NULL row.
SELECT NULL AS Col1, NULL AS Col2 FOR XML PATH, ELEMENTS XSINIL, ROOT('Data');
GO

-- NULL in element name position
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH(NULL), ELEMENTS XSINIL;
GO

-- Very long element name
SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('VeryLongElementNameThatExceedsNormalLengthToTestBoundaryConditions'), ELEMENTS XSINIL;
GO

-- ============================================
-- SECTION 18: Complex JOIN queries
-- ============================================

-- INNER JOIN with ELEMENTS XSINIL
SELECT c.CustomerName, o.OrderID, o.TotalAmount
FROM forxml_path_elements_customers c
INNER JOIN forxml_path_elements_orders o ON c.CustomerID = o.CustomerID
ORDER BY o.OrderID
FOR XML PATH('Order'), ELEMENTS XSINIL;
GO

-- LEFT JOIN with ELEMENTS XSINIL
SELECT c.CustomerName, o.OrderID, o.TotalAmount
FROM forxml_path_elements_customers c
LEFT JOIN forxml_path_elements_orders o ON c.CustomerID = o.CustomerID
ORDER BY c.CustomerID, o.OrderID
FOR XML PATH('CustomerOrder'), ELEMENTS XSINIL;
GO

-- Multiple JOINs
SELECT c.CustomerName, o.OrderID, p.ProductName, oi.Quantity
FROM forxml_path_elements_customers c
INNER JOIN forxml_path_elements_orders o ON c.CustomerID = o.CustomerID
INNER JOIN forxml_path_elements_order_items oi ON o.OrderID = oi.OrderID
INNER JOIN forxml_path_elements_products p ON oi.ProductID = p.ProductID
ORDER BY o.OrderID, p.ProductID
FOR XML PATH('OrderDetail'), ELEMENTS XSINIL;
GO

-- LEFT JOIN with NULLs and ROOT
SELECT c.CustomerName, c.City, o.OrderDate, o.TotalAmount
FROM forxml_path_elements_customers c
LEFT JOIN forxml_path_elements_orders o ON c.CustomerID = o.CustomerID
ORDER BY c.CustomerID, o.OrderID
FOR XML PATH('CustomerOrder'), ELEMENTS XSINIL, ROOT('Data');
GO

-- RIGHT JOIN
SELECT c.CustomerName, o.OrderID, o.OrderDate
FROM forxml_path_elements_customers c
RIGHT JOIN forxml_path_elements_orders o ON c.CustomerID = o.CustomerID
ORDER BY o.OrderID
FOR XML PATH('Order'), ELEMENTS XSINIL;
GO

-- CROSS JOIN
SELECT a.ID AS ID1, a.Name AS Name1, b.ID AS ID2, b.Name AS Name2
FROM forxml_path_elements_t1 a
CROSS JOIN forxml_path_elements_t1 b
WHERE a.ID < b.ID AND a.ID <= 2
ORDER BY a.ID, b.ID
FOR XML PATH('Pair'), ELEMENTS XSINIL;
GO

-- ============================================
-- SECTION 19: Subqueries
-- ============================================

-- Subquery in SELECT with ELEMENTS XSINIL
SELECT (SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS XSINIL) AS Result;
GO

-- Correlated subquery with ELEMENTS XSINIL
SELECT t1.ID, 
    (SELECT Name, Department FROM forxml_path_elements_t1 t2 WHERE t2.ID = t1.ID FOR XML PATH('Details'), ELEMENTS XSINIL, TYPE) AS Details 
FROM forxml_path_elements_t1 t1
WHERE t1.ID <= 3;
GO

SELECT 
    ID,
    (SELECT Name FROM forxml_path_elements_t1 t2 WHERE t2.ID = t1.ID FOR XML PATH(''), ELEMENTS, TYPE) AS NameElement
FROM forxml_path_elements_t1 t1
WHERE ID <= 2;
GO

-- ============================================
-- SECTION 20: ORDER BY, GROUP BY, TOP
-- ============================================

SELECT ID, Name, Department FROM forxml_path_elements_t1 ORDER BY ID FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

SELECT ID, Name, Department FROM forxml_path_elements_t1 ORDER BY Name FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

SELECT TOP 3 ID, Name, Department FROM forxml_path_elements_t1 ORDER BY ID FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

SELECT Department, COUNT(*) AS EmpCount 
FROM forxml_path_elements_t1 
GROUP BY Department 
ORDER BY Department
FOR XML PATH('Dept'), ELEMENTS XSINIL;
GO

-- ============================================
-- SECTION 21: Stored Procedures
-- ============================================

EXEC forxml_path_elements_p1;
GO

EXEC forxml_path_elements_p2;
GO

EXEC forxml_path_elements_p3;
GO

EXEC forxml_path_elements_p4;
GO

EXEC forxml_path_elements_p5;
GO

EXEC forxml_path_elements_p6 @empid = 1;
GO

EXEC forxml_path_elements_p6 @empid = 4;
GO

EXEC forxml_path_elements_p6 @empid = 999;
GO

-- Procedure with department filter
EXEC forxml_path_elements_p7 'Sales';
GO

EXEC forxml_path_elements_p7 NULL;
GO


-- ============================================
-- SECTION 22: SELECT INTO variable
-- ============================================

DECLARE @xml_var VARCHAR(MAX);
SELECT @xml_var = (SELECT ID, Name FROM forxml_path_elements_t1 WHERE ID = 1 FOR XML PATH('Employee'), ELEMENTS);
SELECT @xml_var AS result;
GO

DECLARE @xml_var VARCHAR(MAX);
SELECT @xml_var = (SELECT ID, Name FROM forxml_path_elements_t1 WHERE ID = 2 FOR XML PATH('Employee'), ELEMENTS XSINIL);
SELECT @xml_var AS result;
GO

DECLARE @xml_var XML;
SELECT @xml_var = (SELECT ID, Name FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS, TYPE);
SELECT @xml_var AS result;
GO

DECLARE @xml_var XML;
SELECT @xml_var = (SELECT ID, Name FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS XSINIL, ROOT('Data'), TYPE);
SELECT @xml_var AS result;
GO

-- ============================================
-- SECTION 23: SELECT...INTO (create new table)
-- ============================================

SELECT (SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS XSINIL, TYPE) AS XMLData INTO forxml_path_elements_into1;
GO

SELECT * FROM forxml_path_elements_into1;
GO

DROP TABLE forxml_path_elements_into1;
GO

SELECT (SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS ABSENT, TYPE) AS XMLData INTO forxml_path_elements_into2;
GO

SELECT * FROM forxml_path_elements_into2;
GO

DROP TABLE forxml_path_elements_into2;
GO

SELECT (SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ROOT('Data'), ELEMENTS XSINIL, TYPE) AS XMLData INTO forxml_path_elements_into3;
GO

SELECT * FROM forxml_path_elements_into3;
GO

DROP TABLE forxml_path_elements_into3;
GO

-- ============================================
-- SECTION 24: Regular view with FOR XML
-- ============================================

SELECT * FROM forxml_path_elements_regular_view FOR XML PATH('Employee'), ELEMENTS;
GO

SELECT * FROM forxml_path_elements_regular_view FOR XML PATH('Employee'), ELEMENTS XSINIL;
GO

SELECT * FROM forxml_path_elements_regular_view FOR XML PATH('Employee'), ELEMENTS, ROOT('Data');
GO

-- ============================================
-- SECTION 25: Dependent Views (using FOR XML PATH, ELEMENTS)
-- ============================================

SELECT * FROM forxml_path_elements_dep_view1;
GO

SELECT * FROM forxml_path_elements_dep_view2;
GO

SELECT * FROM forxml_path_elements_dep_view3;
GO

SELECT * FROM forxml_path_elements_dep_view4;
GO

SELECT * FROM forxml_path_elements_dep_view5;
GO

-- ============================================
-- SECTION 26: Dependent Functions (using FOR XML PATH, ELEMENTS)
-- ============================================

SELECT dbo.forxml_path_elements_func1() AS result;
GO

SELECT dbo.forxml_path_elements_func2() AS result;
GO

SELECT dbo.forxml_path_elements_func3() AS result;
GO

SELECT dbo.forxml_path_elements_func4(1) AS result;
GO

SELECT dbo.forxml_path_elements_func4(4) AS result;
GO

-- ============================================
-- SECTION 27: XML methods on FOR XML result
-- ============================================

-- Using .value() method on XSINIL result
SELECT (SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 1 FOR XML PATH('Employee'), ELEMENTS XSINIL, TYPE).value('(/Employee/Name)[1]', 'VARCHAR(50)') AS extracted_name;
GO

-- Using .value() method on NULL element with XSINIL
SELECT (SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 2 FOR XML PATH('Employee'), ELEMENTS XSINIL, TYPE).value('(/Employee/Department)[1]', 'VARCHAR(50)') AS extracted_dept;
GO

-- Using .query() method on XSINIL result
SELECT (SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ROOT('Data'), ELEMENTS XSINIL, TYPE).query('/Data/Employee[1]') AS query_result;
GO

-- Using .exist() method on XSINIL result
SELECT (SELECT ID, Name, Department FROM forxml_path_elements_t1 WHERE ID = 2 FOR XML PATH('Employee'), ELEMENTS XSINIL, TYPE).exist('/Employee/Department') AS element_exists;
GO

-- CAST result to XML type with XSINIL
SELECT CAST((SELECT ID, Name, Department FROM forxml_path_elements_t1 FOR XML PATH('Employee'), ELEMENTS XSINIL) AS XML) AS casted_xml;
GO