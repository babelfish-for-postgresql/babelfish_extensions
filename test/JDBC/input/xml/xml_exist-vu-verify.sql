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
SET @x='';
SELECT @x.exist('true()')
GO

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


-- SUBQUERY
-- LOCAL_ID
-- LR_BR expr RR_BR (DOT method_calls)*
-- function_call (DOT method_calls)*
-- different number of arguments than required
-- EVENTDATA().exist
-- xmlQueryFu.exist()
-- full_object_name.exist()