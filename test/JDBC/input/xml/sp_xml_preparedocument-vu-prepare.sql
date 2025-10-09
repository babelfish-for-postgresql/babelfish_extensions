CREATE TABLE sp_xml_preparedocument_HandleStore (handle_value int);
GO

CREATE DATABASE sp_xml_preparedocument_temp_db;
GO

CREATE TABLE handle_store(handle_id INT);
GO

CREATE PROCEDURE test_xml_proc
AS
BEGIN
DECLARE @hdoc INT;
EXEC sp_xml_preparedocument @hdoc OUTPUT, '<root><child>proc_value</child></root>';
SELECT @hdoc AS handle_inside_proc;
END
GO

-- Create UDTs for different XML string representations
CREATE TYPE XMLCharType FROM CHAR(1000)
GO

CREATE TYPE XMLVarcharType FROM VARCHAR(MAX)
GO

CREATE TYPE XMLNCharType FROM NCHAR(1000)
GO

CREATE TYPE XMLNVarcharType FROM NVARCHAR(MAX)
GO

CREATE TYPE XMLTextType FROM TEXT
GO

CREATE TYPE XMLNTextType FROM NTEXT
GO

-- Basic Test Cases with different UDTs
-- 1. Test CHAR UDT
CREATE PROCEDURE TestXMLPrepareDocument_Char
AS
BEGIN
    DECLARE @hdoc INT
    DECLARE @charXML XMLCharType = '<root><child>char value</child></root>'
    EXEC sp_xml_preparedocument @hdoc OUTPUT, @charXML
    SELECT @hdoc as CharHandle
    EXEC sp_xml_removedocument @hdoc
END
GO

-- 2. Test VARCHAR UDT
CREATE PROCEDURE TestXMLPrepareDocument_Varchar
AS
BEGIN
    DECLARE @hdoc INT
    DECLARE @varcharXML XMLVarcharType = '<root><child>varchar value</child></root>'
    EXEC sp_xml_preparedocument @hdoc OUTPUT, @varcharXML
    SELECT @hdoc as VarcharHandle
    EXEC sp_xml_removedocument @hdoc
END
GO

-- 3. Test NCHAR UDT
CREATE PROCEDURE TestXMLPrepareDocument_NChar
AS
BEGIN
    DECLARE @hdoc INT
    DECLARE @ncharXML XMLNCharType = N'<root><child>nchar value 世界</child></root>'
    EXEC sp_xml_preparedocument @hdoc OUTPUT, @ncharXML
    SELECT @hdoc as NCharHandle
    EXEC sp_xml_removedocument @hdoc
END
GO

-- 4. Test NVARCHAR UDT
CREATE PROCEDURE TestXMLPrepareDocument_NVarchar
AS
BEGIN
    DECLARE @hdoc INT
    DECLARE @nvarcharXML XMLNVarcharType = N'<root><child>nvarchar value 🌟</child></root>'
    EXEC sp_xml_preparedocument @hdoc OUTPUT, @nvarcharXML
    SELECT @hdoc as NVarcharHandle
    EXEC sp_xml_removedocument @hdoc
END
GO

-- 5. Test TEXT UDT
CREATE PROCEDURE TestXMLPrepareDocument_Text 
AS 
BEGIN 
    DECLARE @hdoc INT 
    DECLARE @textXML XMLTextType = '<root><child>text value</child></root>' 
    EXEC sp_xml_preparedocument @hdoc OUTPUT, @textXML 
    SELECT @hdoc as TextHandle 
    EXEC sp_xml_removedocument @hdoc 
END 
GO

-- 6. Test NTEXT UDT
CREATE PROCEDURE TestXMLPrepareDocument_NText
AS
BEGIN
    DECLARE @hdoc INT
    DECLARE @ntextXML XMLNTextType = N'<root><child>ntext value 漢字</child></root>'
    EXEC sp_xml_preparedocument @hdoc OUTPUT, @ntextXML
    SELECT @hdoc as NTextHandle
    EXEC sp_xml_removedocument @hdoc
END
GO

CREATE TABLE TestTextXML_babel_1168 ( id INT, xml_data TEXT)
INSERT INTO TestTextXML_babel_1168 VALUES(1, '<root><child>value</child></root>') 
GO

CREATE TABLE TestNTextXML_babel_1168 ( id INT, xml_data NTEXT )
INSERT INTO TestNTextXML_babel_1168 VALUES(1, N'<root><child>value 世界</child></root>') 
GO

-- VIEWS TEST CASES for sp_xml_preparedocument and sp_xml_removedocument
-- Test 1: Simple view with XML data
CREATE TABLE XMLDataSource_babel_1168 (
    id INT,
    xml_content VARCHAR(MAX),
    description VARCHAR(50)
)
INSERT INTO XMLDataSource_babel_1168 VALUES 
(1, '<root><item>value1</item></root>', 'Simple XML'),
(2, '<data><element>value2</element></data>', 'Data XML'),
(3, '<config><setting>value3</setting></config>', 'Config XML')
GO

CREATE VIEW XMLDataView_babel_1168 AS
SELECT id, xml_content, description
FROM XMLDataSource_babel_1168
WHERE xml_content IS NOT NULL
GO

-- Test 2: View-based XML processing procedure
CREATE PROCEDURE ProcessXMLFromView_babel_1168(@id INT)
AS
BEGIN
    DECLARE @hdoc INT
    DECLARE @xml_data VARCHAR(MAX)
    
    SELECT @xml_data = xml_content FROM XMLDataView_babel_1168 WHERE id = @id
    EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_data
    SELECT @hdoc as ViewHandle, @xml_data as XMLContent
    EXEC sp_xml_removedocument @hdoc
END
GO

-- Test 3: View with NVARCHAR XML data
CREATE TABLE NVarcharXMLSource_babel_1168 (
    id INT,
    xml_data NVARCHAR(MAX),
    category NVARCHAR(50)
)
INSERT INTO NVarcharXMLSource_babel_1168 VALUES 
(1, N'<root><child>Unicode 世界</child></root>', N'Unicode'),
(2, N'<data><item>Emoji 🌟</item></data>', N'Emoji'),
(3, N'<config><value>Mixed αβγ</value></config>', N'Greek')
GO

CREATE VIEW NVarcharXMLView_babel_1168 AS
SELECT id, xml_data, category
FROM NVarcharXMLSource_babel_1168
WHERE xml_data LIKE N'%<%>%'
GO

-- Test 4: Complex view with joins
CREATE TABLE XMLMetadata_babel_1168 (
    xml_id INT,
    created_date DATETIME,
    xml_type VARCHAR(20)
)
INSERT INTO XMLMetadata_babel_1168 VALUES 
(1, '2023-01-01', 'Config'),
(2, '2023-01-02', 'Data'),
(3, '2023-01-03', 'Settings')
GO

CREATE VIEW XMLWithMetadataView_babel_1168 AS
SELECT 
    x.id,
    x.xml_content,
    m.created_date,
    m.xml_type
FROM XMLDataSource_babel_1168 x
INNER JOIN XMLMetadata_babel_1168 m ON x.id = m.xml_id
GO

-- Test 5: View-based XML handle management
CREATE VIEW ActiveXMLHandlesView_babel_1168 AS
SELECT 
    id,
    xml_content,
    'Handle_' + CAST(id AS VARCHAR(10)) as handle_name
FROM XMLDataSource_babel_1168
WHERE LEN(xml_content) > 20
GO

-- Test 6: Parameterized view simulation with table-valued function
CREATE FUNCTION GetXMLByType_babel_1168(@xml_type VARCHAR(20))
RETURNS TABLE
AS
RETURN
(
    SELECT id, xml_content, xml_type
    FROM XMLWithMetadataView_babel_1168
    WHERE xml_type = @xml_type
)
GO

-- Test 7: View with XML error handling
CREATE VIEW XMLErrorHandlingView_babel_1168 AS
SELECT 
    id,
    xml_content,
    CASE 
        WHEN xml_content IS NULL THEN 'NULL XML'
        WHEN LEN(xml_content) = 0 THEN 'Empty XML'
        WHEN xml_content NOT LIKE '<%' THEN 'Invalid XML Format'
        ELSE 'Valid XML'
    END as xml_status
FROM XMLDataSource_babel_1168
GO

-- EXPLICIT CASTING AND CONVERTING TESTS FOR sp_xml_preparedocument
-- Test data tables
CREATE TABLE CastingTestData_babel_1168 (
    id INT,
    varchar_xml VARCHAR(MAX),
    nvarchar_xml NVARCHAR(MAX),
    char_xml CHAR(100),
    nchar_xml NCHAR(100),
    text_xml TEXT,
    ntext_xml NTEXT
)

INSERT INTO CastingTestData_babel_1168 VALUES 
(1, '<root><item>varchar</item></root>', N'<root><item>nvarchar 世界</item></root>', 
 '<root><item>char</item></root>', N'<root><item>nchar 🌟</item></root>',
 '<root><item>text</item></root>', N'<root><item>ntext 漢字</item></root>')
GO

-- Test procedures for casting scenarios
CREATE PROCEDURE TestExplicitCasting_babel_1168
AS
BEGIN
    DECLARE @hdoc INT
    DECLARE @xml_data VARCHAR(MAX)
    
    -- Get data for casting tests
    SELECT @xml_data = varchar_xml FROM CastingTestData_babel_1168 WHERE id = 1
    EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml_data
    SELECT @hdoc as CastingHandle
    EXEC sp_xml_removedocument @hdoc
END
GO
