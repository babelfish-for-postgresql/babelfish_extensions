set quoted_identifier on
go

-- tests with empty/NULL input
DECLARE @x XML = ''
SELECT T.c.query('.') AS result
FROM @x.nodes('/Root/row') AS T(c)
go

DECLARE @x XML = '   '
SELECT T.c.query('.') AS result
FROM @x.nodes('/Root/row') AS T(c)
go

DECLARE @x XML = NULL
SELECT T.c.query('.') AS result
FROM @x.nodes('/Root/row') AS T(c)
go

DECLARE @x XML= ''
SELECT T.c.value('.', 'varchar(10)') AS result
FROM @x.nodes('/Root/row') AS T(c)
ORDER BY 1
go

DECLARE @x XML= '   '
SELECT T.c.value('.', 'varchar(10)') AS result
FROM @x.nodes('/Root/row') AS T(c)
ORDER BY 1
go

DECLARE @x XML= NULL
SELECT T.c.value('.', 'varchar(10)') AS result
FROM @x.nodes('/Root/row') AS T(c)
ORDER BY 1
go

-- tests with basic XPath queries
DECLARE @xml XML = '<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>'
SELECT T.C.value('(@id)[1]', 'int') AS id
FROM @xml.nodes('/Root/row') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>'
SELECT T.C.value('(@id)[2]', 'int') AS id
FROM @xml.nodes('/Root/row') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>'
SELECT T.C.value('(//@id)[1]', 'int') AS id
FROM @xml.nodes('/Root/row') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>'
SELECT T.C.value('(/*/@id)[1]', 'int') AS id
FROM @xml.nodes('/Root/row') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>'
SELECT T.C.value('(@id)[1]', 'int') AS id
FROM @xml.nodes('/Root/row') AS T(C)
ORDER BY 1
go

CREATE TABLE #NullXml (Id INT, Data XML)
INSERT #NullXml VALUES (1, NULL), (2, '<r><i>OK</i></r>')
SELECT n.Id, t.c.value('.','varchar(20)') AS val
FROM #NullXml n CROSS APPLY n.Data.nodes('/r/i') t(c)
ORDER BY n.Id
DROP TABLE #NullXml
go

-- .nodes() on an XML variable
DECLARE @xml XML = '<r><i v="1"/><i v="2"/><i v="3"/></r>'
SELECT t.c.value('@v','int') AS val
FROM @xml.nodes('/r/i') t(c)
ORDER BY val
go

-- .nodes() on a table column
CREATE TABLE #XmlData (Id INT, Data XML)
INSERT #XmlData VALUES
  (1, '<items><item>A</item><item>B</item></items>'),
  (2, '<items><item>C</item></items>')
SELECT d.Id, t.c.value('.','char(1)') AS item
FROM #XmlData d
CROSS APPLY d.Data.nodes('/items/item') t(c)
ORDER BY d.Id
DROP TABLE #XmlData
go

-- .nodes() on a subquery result
SELECT t.c.value('@id','int') AS id, t.c.value('.','varchar(20)') AS val
FROM (SELECT CAST('<root><e id="1">X</e><e id="2">Y</e></root>' AS XML) AS x) sub
CROSS APPLY sub.x.nodes('/root/e') t(c)
ORDER BY 1
go

-- .nodes() with deeper nesting on a variable
DECLARE @xml XML = '<orders><o id="1"><li>item-1</li><li>item-2</li></o><o id="2"><li>item-3</li></o></orders>'
SELECT t.c.value('../@id','int') AS orderId, t.c.value('.','varchar(20)') AS lineItem
FROM @xml.nodes('/orders/o/li') t(c)
ORDER BY 1,2
go

DECLARE @xml XML = '<orders><o id="1"><li>item-1</li><li>item-2</li></o><o id="2"><li>item-3</li></o></orders>'
SELECT t.c.value('../@id','int') AS orderId, t.c.value('(.)','varchar(20)') AS lineItem
FROM @xml.nodes('/orders/o/li') t(c)
ORDER BY 1,2
go

DECLARE @xml XML = '<orders><o id="1"><li>item-1</li><li>item-2</li></o><o id="2"><li>item-3</li></o></orders>'
SELECT @xml.value('.','varchar(20)')  AS lineItem
ORDER BY 1
go

-- .nodes() on a subquery joining to another table
CREATE TABLE #Orders (OrderId INT, OrderXml XML)
INSERT #Orders VALUES (1,'<lines><l qty="5"/><l qty="3"/></lines>')
SELECT o.OrderId, t.c.value('@qty','int') AS qty
FROM #Orders o
CROSS APPLY (SELECT o.OrderXml) sub(x)
CROSS APPLY sub.x.nodes('/lines/l') t(c)
ORDER BY 1,2
DROP TABLE #Orders
go

-- .nodes() with multiple levels via nested CROSS APPLY on a variable
DECLARE @xml XML = '<depts><d name="Eng"><emp>James</emp><emp>Andrew</emp></d><d name="HR"><emp>Megan</emp></d></depts>'
SELECT d.c.value('@name','varchar(20)') AS dept, e.c.value('.','varchar(20)') AS emp
FROM @xml.nodes('/depts/d') d(c)
CROSS APPLY d.c.nodes('emp') e(c)
ORDER BY 1,2
go

-- .nodes() returning empty set (no matches)
DECLARE @xml XML = '<r><a>1</a></r>'
SELECT t.c.value('.','int') AS val
FROM @xml.nodes('/r/b') t(c)
ORDER BY 1
go

-- .nodes() on table column with NULL XML (should produce no rows)
CREATE TABLE #NullXml (Id INT, Data XML)
INSERT #NullXml VALUES (1, NULL), (2, '<r><i>OK</i></r>')
SELECT n.Id, t.c.value('.','varchar(20)') AS val
FROM #NullXml n
CROSS APPLY n.Data.nodes('/r/i') t(c)
ORDER BY 1,2
DROP TABLE #NullXml
go

DECLARE @xml XML = '<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>'
SELECT T.C.value('(@id)[1]', 'int') AS id, T.C.value('(name)[1]', 'varchar(100)') AS name
FROM @xml.nodes('/Root/row') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>'
SELECT T.C.value('(@id)[1]', 'int') AS id, T.C.value('(@name)[1]', 'varchar(100)') AS name
FROM @xml.nodes('/Root/row') AS T(C)
ORDER BY 1
go

-- nodes() returns empty rowset when xpath matches nothing
DECLARE @xml XML = '<Root><row id="1"/></Root>'
SELECT T.C.value('(@id)[1]', 'int') AS id
FROM @xml.nodes('/Root/noMatch') AS T(C)
ORDER BY 1
go

-- nodes() on a subquery
SELECT T.C.value('(@id)[1]', 'int') AS id
FROM (SELECT CAST('<Root><row id="10"/><row id="20"/></Root>' AS XML)) AS X(Col)
CROSS APPLY X.Col.nodes('/Root/row') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><item>A</item><item>B</item></Root>'
SELECT T.C.value('.', 'varchar(20)') AS val
FROM @xml.nodes('/Root/item') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><item>A</item><item>B</item></Root>'
SELECT T.C.value('..', 'varchar(20)') AS val
FROM @xml.nodes('/Root/item') AS T(C)
ORDER BY 1
go

SELECT T.C.value('(@id)[1]', 'int') AS id
FROM (SELECT CAST('<Root><row id="10"/><row id="20"/></Root>' AS XML)) AS X(Col)
CROSS APPLY X.Col.nodes('/Root/row') AS T(C)
ORDER BY 1
go

SELECT T.C.value('(./@id)[1]', 'int') AS id
FROM (SELECT CAST('<Root><row id="10"/><row id="20"/></Root>' AS XML)) AS X(Col)
CROSS APPLY X.Col.nodes('/Root/row') AS T(C)
ORDER BY 1
go

SELECT T.C.value('(../@id)[1]', 'int') AS id
FROM (SELECT CAST('<Root><row id="10"/><row id="20"/></Root>' AS XML)) AS X(Col)
CROSS APPLY X.Col.nodes('/Root/row') AS T(C)
ORDER BY 1
go

SELECT T.C.value('./@id', 'int') AS id
FROM (SELECT CAST('<Root><row id="10"/><row id="20"/></Root>' AS XML)) AS X(Col)
CROSS APPLY X.Col.nodes('/Root/row') AS T(C)
ORDER BY 1
go

SELECT T.C.value('../@id', 'int') AS id
FROM (SELECT CAST('<Root><row id="10"/><row id="20"/></Root>' AS XML)) AS X(Col)
CROSS APPLY X.Col.nodes('/Root/row') AS T(C)
ORDER BY 1
go

SELECT T.C.value('./@id[1]', 'int') AS id
FROM (SELECT CAST('<Root><row id="10"/><row id="20"/></Root>' AS XML)) AS X(Col)
CROSS APPLY X.Col.nodes('/Root/row') AS T(C)
ORDER BY 1
go

SELECT T.C.value('../@id[1]', 'int') AS id
FROM (SELECT CAST('<Root><row id="10"/><row id="20"/></Root>' AS XML)) AS X(Col)
CROSS APPLY X.Col.nodes('/Root/row') AS T(C)
ORDER BY 1
go
SELECT T.C.value('@id[1]', 'int') AS id
FROM (SELECT CAST('<Root><row id="10"/><row id="20"/></Root>' AS XML)) AS X(Col)
CROSS APPLY X.Col.nodes('/Root/row') AS T(C)
ORDER BY 1
go

SELECT T.C.value(' . / @id [1]', 'int') AS id
FROM (SELECT CAST('<Root><row id="10"/><row id="20"/></Root>' AS XML)) AS X(Col)
CROSS APPLY X.Col.nodes('/Root/row') AS T(C)
ORDER BY 1
go

SELECT T.C.value(' .. / @id [1]', 'int') AS id
FROM (SELECT CAST('<Root><row id="10"/><row id="20"/></Root>' AS XML)) AS X(Col)
CROSS APPLY X.Col.nodes('/Root/row') AS T(C)
ORDER BY 1
go

-- string split into rows on separator
DECLARE @str varchar(20) = 'ab,cd,ef'
DECLARE @separator varchar(10)=','
DECLARE @xml xml = N'<root><i>' + replace(@str, @separator,'</i><i>') + '</i></root>'
SELECT [i].value('.', 'VARCHAR(MAX)') AS Value
FROM @xml.nodes('//root/i') AS [Items]([i])
ORDER BY 1
go

DECLARE @str varchar(20) = 'ab,cd,ef'
DECLARE @separator varchar(10)='!'
DECLARE @xml xml = N'<root><i>' + replace(@str, @separator,'</i><i>') + '</i></root>'
SELECT [i].value('.', 'VARCHAR(MAX)') AS Value
FROM @xml.nodes('//root/i') AS [Items]([i])
ORDER BY 1
go

DECLARE @str varchar(20) = ',ab,cd,ef,'
DECLARE @separator varchar(10)=','
DECLARE @xml xml = N'<root><i>' + replace(@str, @separator,'</i><i>') + '</i></root>'
SELECT [i].value('.', 'VARCHAR(MAX)') AS Value
FROM @xml.nodes('//root/i') AS [Items]([i])
ORDER BY 1
go

DECLARE @str varchar(20) = ',,ab,,cd,,ef,,'
DECLARE @separator varchar(10)=','
DECLARE @xml xml = N'<root><i>' + replace(@str, @separator,'</i><i>') + '</i></root>'
SELECT [i].value('.', 'VARCHAR(MAX)') AS Value
FROM @xml.nodes('//root/i') AS [Items]([i])
ORDER BY 1
go

DECLARE @str varchar(20) = NULL
DECLARE @separator varchar(10)='!'
DECLARE @xml xml = N'<root><i>' + replace(@str, @separator,'</i><i>') + '</i></root>'
SELECT [i].value('.', 'VARCHAR(MAX)') AS Value
FROM @xml.nodes('//root/i') AS [Items]([i])
ORDER BY 1
go

DECLARE @str varchar(20) = ''
DECLARE @separator varchar(10)='!'
DECLARE @xml xml = N'<root><i>' + replace(@str, @separator,'</i><i>') + '</i></root>'
SELECT [i].value('.', 'VARCHAR(MAX)') AS Value
FROM @xml.nodes('//root/i') AS [Items]([i])
ORDER BY 1
go

DECLARE @str varchar(20) = 'ab,cd,ef'
DECLARE @separator varchar(10)=''
DECLARE @xml xml = N'<root><i>' + replace(@str, @separator,'</i><i>') + '</i></root>'
SELECT [i].value('.', 'VARCHAR(MAX)') AS Value
FROM @xml.nodes('//root/i') AS [Items]([i])
ORDER BY 1
go

DECLARE @str varchar(20) = 'ab,cd,ef'
DECLARE @separator varchar(10)=null
DECLARE @xml xml = N'<root><i>' + replace(@str, @separator,'</i><i>') + '</i></root>'
SELECT [i].value('.', 'VARCHAR(MAX)') AS Value
FROM @xml.nodes('//root/i') AS [Items]([i])
ORDER BY 1
go

DECLARE @UsersList XML =
'<Root>
  <Rows UserName="jsmith" Name="John Smith"/>
  <Rows UserName="adoe" Name="Andrew Doe"/>
  <Rows UserName="bjones" Name="Bob Jones"/>
</Root>'
SELECT
  T.C.value('./@UserName', 'varchar(100)') AS UserName,
  T.C.value('./@Name', 'varchar(100)') AS Name,
  u.UserID
FROM @UsersList.nodes('/Root/Rows') AS T(C)
INNER JOIN babel_5225_xml_nodes_t3 u ON u.UserName = T.C.value('./@UserName', 'varchar(100)')
ORDER BY u.UserID
go

-- double CROSS APPLY
DECLARE @xml XML = '<root><row><def><item>item-1</item></def><def><item>item-2</item></def><attributes><color>blue</color></attributes><attributes><color>red</color></attributes></row><row><def><item>item-3</item></def><attributes><color>green</color></attributes></row></root>'
SELECT
   itemDef.value('(item)[1]', 'varchar(20)') AS item,
   attrib.value('(color)[1]', 'varchar(20)') AS color
FROM @xml.nodes('/root/row') AS row(rowType)
   CROSS APPLY rowType.nodes('./def') AS itemDefs(itemDef)
   CROSS APPLY rowType.nodes('./attributes') AS attributeDefs(attrib)
ORDER BY item, color
go

-- with .exist()
DECLARE @xml XML = '<root><row><def><item>item-1</item></def><def><item>item-2</item></def><attributes><color>blue</color></attributes><attributes><color>red</color></attributes></row><row><def><item>item-3</item></def><attributes><color>green</color></attributes></row></root>'
SELECT
   itemDef.value('(item)[1]', 'varchar(20)') AS item,
   attrib.value('(color)[1]', 'varchar(20)') AS color
FROM @xml.nodes('/root/row') AS row(rowType)
   CROSS APPLY rowType.nodes('./def') AS itemDefs(itemDef)
   CROSS APPLY rowType.nodes('./attributes') AS attributeDefs(attrib)
WHERE attrib.exist('./color') = 1
ORDER BY item, color
go

DECLARE @xml XML = '<root><row><def><item>item-1</item></def><def><item>item-2</item></def><attributes><color>blue</color></attributes><attributes><color>red</color></attributes></row><row><def><item>item-3</item></def><attributes><color>green</color></attributes></row></root>'
SELECT
   itemDef.value('(item)[1]', 'varchar(20)') AS item,
   attrib.value('(color)[1]', 'varchar(20)') AS color
FROM @xml.nodes('/root/row') AS row(rowType)
   CROSS APPLY rowType.nodes('./def') AS itemDefs(itemDef)
   CROSS APPLY rowType.nodes('./attributes') AS attributeDefs(attrib)
WHERE attrib.exist('./nosuchtag') = 1
ORDER BY item, color
go

DECLARE @xml XML = '<root><row><def><item>item-1</item></def><def><item>item-2</item></def><attributes><color>blue</color></attributes><attributes><color>red</color></attributes></row><row><def><item>item-3</item></def><attributes><color>green</color></attributes></row></root>'
SELECT
   itemDef.value('(item)[1]', 'varchar(20)') AS item,
   attrib.value('(color)[1]', 'varchar(20)') AS color
FROM @xml.nodes('/root/row') AS row(rowType)
   CROSS APPLY rowType.nodes('./def') AS itemDefs(itemDef)
   CROSS APPLY rowType.nodes('./attributes') AS attributeDefs(attrib)
WHERE attrib.exist('./color[text()="red"]') = 1
ORDER BY item, color
go

DECLARE @xml XML = '<root><row><def><item>item-1</item></def><def><item>item-2</item></def><attributes><color>blue</color></attributes><attributes><color>red</color></attributes></row><row><def><item>item-3</item></def><attributes><color>green</color></attributes></row></root>'
SELECT
   itemDef.value('(item)[1]', 'varchar(20)') AS item,
   attrib.value('(color)[1]', 'varchar(20)') AS color
FROM @xml.nodes('/root/row') AS row(rowType)
   CROSS APPLY rowType.nodes('./def') AS itemDefs(itemDef)
   CROSS APPLY rowType.nodes('./attributes') AS attributeDefs(attrib)
WHERE itemDef.exist('./item[text()="item-2"]') = 1
ORDER BY item, color
go

DECLARE @xml XML = '<Root><item>A</item><item>B</item></Root>'
SELECT T.C.value('(.)[1]', 'varchar(20)') AS val
FROM @xml.nodes('/Root/item') AS T(C)
ORDER BY val
go

-- variations on the xpath query
DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('.', 'varchar(20)') AS id
FROM @xml.nodes('.') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('(.)') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('(.)[1]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('.[1]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('.[2]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('.', 'varchar(20)') AS id
FROM @xml.nodes('/Root/row/name') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('(/Root/row/name)') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('(/Root/row/name)[1]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('/Root/row/name[1]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('.', 'varchar(20)') AS id
FROM @xml.nodes('/Root/row/name') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('/Root/row/name') AS T(C)
ORDER BY 1
go

-- index in .nodes() query
DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('.', 'varchar(20)') AS id
FROM @xml.nodes('(/Root/row/name)[1]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('(/Root/row/name)[1]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('.', 'varchar(20)') AS id
FROM @xml.nodes('(/Root/row/name)[2]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('(/Root/row/name)[2]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('/Root/row/name[1]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('/Root/row/name[2]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('/Root/row/name/..') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('(/Root/row/name/../name/../name)') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('.', 'varchar(20)') AS id
FROM @xml.nodes('(/Root/row/name/../name/../name)[1]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('.', 'varchar(20)') AS id
FROM @xml.nodes('(/Root/row/name/../name/../name)[2]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('.', 'varchar(20)') AS id
FROM @xml.nodes('(/Root/row/name/..)[1]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('.', 'varchar(20)') AS id
FROM @xml.nodes('(/Root/row/name/..)[2]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('/Root/row/name') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('(.)', 'varchar(20)') AS name
FROM @xml.nodes('/Root/row/name') AS T(C)
ORDER BY 1,2
go

-- index in .nodes() query
DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name)[1]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('(.)', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name)[1]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name)[2]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('(.)', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name)[2]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('(.)', 'varchar(20)') AS name
FROM @xml.nodes('/Root/row/name[1]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('(.)', 'varchar(20)') AS name
FROM @xml.nodes('/Root/row/name[2]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('(@id)', 'varchar(20)') AS id, T.C.value('(.)', 'varchar(20)') AS name
FROM @xml.nodes('/Root/row/name/..') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('(.)', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name/../name/../name)') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('(@id)', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name/../name/../name)[1]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('(@id)[1]', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name/../name/../name)[1]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('(@id)[2]', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name/../name/../name)[1]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name/../name/../name)[2]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name/..)[1]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name/..)[2]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('/Root/row/name') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('(.)', 'varchar(20)') AS name
FROM @xml.nodes('/Root/row/name') AS T(C)
ORDER BY 1,2
go

-- different XML doc
DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name)[1]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('(.)', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name)[1]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name)[2]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('(.)', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name)[2]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('(.)', 'varchar(20)') AS name
FROM @xml.nodes('/Root/row/name[1]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('(.)', 'varchar(20)') AS name
FROM @xml.nodes('/Root/row/name[2]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('(@id)', 'varchar(20)') AS id, T.C.value('(.)', 'varchar(20)') AS name
FROM @xml.nodes('/Root/row/name/..') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('(.)', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name/../name/../name)') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('(@id)', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name/../name/../name)[1]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('(@id)[1]', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name/../name/../name)[1]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('(@id)[2]', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name/../name/../name)[1]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name/../name/../name)[2]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name/..)[1]') AS T(C)
ORDER BY 1,2
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('(/Root/row/name/..)[2]') AS T(C)
ORDER BY 1,2
go

-- more complex XML doc
DECLARE @x XML = '
<company>
  <department name="Sales">
    <manager><person id="1" firstName="Alice" lastName="Morgan"/></manager>
    <team name="west">
      <manager><person id="2" firstName="Bob" lastName="Carter"/></manager>
      <person id="3" firstName="Carol" lastName="Davis"/>
      <person id="4" firstName="Dan" lastName="Evans"/>
      <person id="5" firstName="Eve" lastName="Foster"/>
    </team>
    <team name="east">
      <manager><person id="6" firstName="Frank" lastName="Green"/></manager>
      <person id="7" firstName="Grace" lastName="Hill"/>
      <person id="8" firstName="Henry" lastName="Irving"/>
      <person id="3" firstName="Carol" lastName="Davis"/>
    </team>
    <team name="central">
      <manager><person id="9" firstName="Irene" lastName="James"/></manager>
      <person id="10" firstName="Jack" lastName="Kelly"/>
      <person id="11" firstName="Karen" lastName="Lewis"/>
    </team>
  </department>
  <department name="Finance">
    <manager><person id="12" firstName="Leo" lastName="Martin"/></manager>
    <team name="accounts">
      <manager><person id="13" firstName="Mona" lastName="Nash"/></manager>
      <person id="14" firstName="Neil" lastName="Owen"/>
      <person id="15" firstName="Olivia" lastName="Parker"/>
      <person id="16" firstName="Paul" lastName="Quinn"/>
    </team>
    <team name="legal">
      <manager><person id="17" firstName="Rachel" lastName="Stone"/></manager>
      <person id="18" firstName="Sam" lastName="Taylor"/>
      <person id="19" firstName="Tina" lastName="Underwood"/>
      <person id="14" firstName="Neil" lastName="Owen"/>
    </team>
  </department>
  <department name="Support">
    <manager><person id="20" firstName="Uma" lastName="Vance"/></manager>
    <team name="retail">
      <manager><person id="21" firstName="Victor" lastName="Walsh"/></manager>
      <person id="22" firstName="Wendy" lastName="Young"/>
      <person id="23" firstName="Xavier" lastName="Adams"/>
    </team>
    <team name="enterprise">
      <manager><person id="24" firstName="Yvonne" lastName="Blake"/></manager>
      <person id="25" firstName="Zach" lastName="Cole"/>
      <person id="22" firstName="Wendy" lastName="Young"/>
    </team>
    <team name="online">
      <manager><person id="26" firstName="Arthur" lastName="Dean"/></manager>
      <person id="27" firstName="Betty" lastName="Ellis"/>
      <person id="28" firstName="Chris" lastName="Ford"/>
    </team>
  </department>
</company>'

-- All persons with ID and department
SELECT DISTINCT
  p.value('@id', 'int') AS PersonID,
  CAST(p.value('@firstName', 'VARCHAR(15)') + ' ' + p.value('@lastName', 'VARCHAR(15)') AS VARCHAR(35)) AS FullName,
  dept.value('@name', 'varchar(20)') AS Department
FROM @x.nodes('/company/department') AS D(dept)
CROSS APPLY dept.nodes('.//person') AS P(p)
ORDER BY PersonID

-- All managers, two CROSS APPLY
SELECT DISTINCT
  mgr.value('@id', 'int') AS ManagerID,
  CAST(mgr.value('@firstName', 'varchar(15)') + ' ' + mgr.value('@lastName', 'varchar(15)') AS VARCHAR(35)) AS ManagerName,
  'Department' AS ManagerLevel, dept.value('@name', 'varchar(20)') AS Department, NULL AS Team
FROM @x.nodes('/company/department') AS D(dept)
CROSS APPLY dept.nodes('manager/person') AS M(mgr)
UNION ALL
SELECT
  mgr.value('@id', 'int'),
  CAST(mgr.value('@firstName', 'varchar(15)') + ' ' + mgr.value('@lastName', 'varchar(15)') AS VARCHAR(35)),
  'Team', dept.value('@name', 'varchar(20)'), team.value('@name', 'varchar(20)')
FROM @x.nodes('/company/department') AS D(dept)
CROSS APPLY dept.nodes('team') AS T(team)
CROSS APPLY team.nodes('manager/person') AS M(mgr)
ORDER BY ManagerID

-- Persons in multiple teams
WITH Members AS (
  SELECT
    p.value('@id', 'int') AS PersonID,
    CAST(p.value('@firstName', 'varchar(15)') + ' ' + p.value('@lastName', 'varchar(15)') AS VARCHAR(35)) AS FullName,
    team.value('@name', 'varchar(20)') AS TeamName
  FROM @x.nodes('/company/department/team') AS T(team)
  CROSS APPLY team.nodes('person') AS P(p)
)
SELECT DISTINCT m.PersonID, m.FullName, m.TeamName
FROM Members m
INNER JOIN (
  SELECT PersonID FROM Members GROUP BY PersonID HAVING COUNT(*) > 1
) multi ON multi.PersonID = m.PersonID
ORDER BY m.PersonID, m.FullName, m.TeamName

-- Teams with members using exist() and query()
SELECT
  dept.value('@name', 'varchar(50)') AS Department,
  team.value('@name', 'varchar(50)') AS Team,
  team.query('person') AS TeamMembersXML
FROM @x.nodes('/company/department') AS D(dept)
CROSS APPLY dept.nodes('team') AS T(team)
WHERE team.exist('person') = 1
ORDER BY cast(team.query('person') as varchar(200))
go

-- XPath functions that can take an argument ----------------
DECLARE @x XML = '
<root>
  <row>
    <item name="alpha">hello</item>
    <item name="beta">world</item>
    <item name="gamma">testing123</item>
  </row>
  <row>
    <item name="delta">short</item>
    <item name="epsilon">this is a longer string</item>
  </row>
  <books>
    <title>SQL</title>
    <title>Advanced Database Design</title>
    <title>XML Fundamentals</title>
  </books>
</root>'

-- Finds the first <item> whose text content equals "hello"
SELECT @x.value('(/root/row/item[string(.) = "hello"])[1]', 'varchar(50)') AS result1

-- Finds the first <item> whose text contains "test"
SELECT @x.value('(/root/row/item[contains(.,"test")])[1]', 'varchar(50)') AS result2

-- Finds the first <title> whose text length exceeds 5 characters
SELECT @x.value('(/root/books/title[string-length(.) > 5])[1]', 'varchar(50)') AS result3

-- Gets the @name attribute of the first <item> that has content (count(.) > 0)
SELECT @x.value('(/root/row/item[count(.) > 0])[1]/@name', 'varchar(50)') AS result4
go

-- Context node (.)
DECLARE @x XML = '<Root><A>1</A><B>2</B><C>3</C></Root>'
SELECT T.c.value('local-name(.)', 'NVARCHAR(50)') AS val
FROM @x.nodes('/Root/*') AS T(c)
ORDER BY 1
go

-- Parent node
DECLARE @x XML = '<Root><A>1</A><B>2</B><C>3</C></Root>'
SELECT T.c.value('local-name(..)', 'NVARCHAR(50)') AS val
FROM @x.nodes('/Root/*') AS T(c)
ORDER BY 1
go

-- extra brackets
DECLARE @x XML = '<Root><A>1</A><B>2</B><C>3</C></Root>'
SELECT T.c.value('((((local-name((((.))))))))', 'NVARCHAR(50)') AS val
FROM @x.nodes('/Root/*') AS T(c)
ORDER BY 1
go

DECLARE @x XML = '<Root><A>1</A><B>2</B><C>3</C></Root>'
SELECT T.c.value('   ( ((local-name(..)) ) ) ', 'NVARCHAR(50)') AS val
FROM @x.nodes('/Root/*') AS T(c)
ORDER BY 1
go

-- Attribute argument (@attr)
DECLARE @x XML = '<Root><Item name="Laptop"/><Item name="Mouse"/></Root>'
SELECT T.c.value('string-length(@name)', 'INT') AS val
FROM @x.nodes('/Root/Item') AS T(c)
ORDER BY 1
go

-- Child element path
DECLARE @x XML = '<Root><Item><Sub/><Sub/><Sub/></Item><Item><Sub/></Item></Root>'
SELECT T.c.value('count(Sub)', 'INT') AS val
FROM @x.nodes('/Root/Item') AS T(c)
ORDER BY 1
go

-- Nested function as argument
DECLARE @x XML = '<Root><Item name="Laptop"/><Item name="Mouse"/></Root>'
SELECT T.c.value('substring(@name, string-length(@name))', 'NVARCHAR(10)') AS val
FROM @x.nodes('/Root/Item') AS T(c)
ORDER BY 1
go

-- Attribute wildcard (@*)
DECLARE @x XML = '<Root><Item a="1" b="2" c="3"/><Item a="4"/></Root>'
SELECT T.c.value('count(@*)', 'INT') AS val
FROM @x.nodes('/Root/Item') AS T(c)
ORDER BY 1
go

-- Filtered child with predicate
DECLARE @x XML = '<Root><Item><Sub val="1"/><Sub val="5"/><Sub val="9"/></Item><Item><Sub val="2"/></Item></Root>'
SELECT T.c.value('count(Sub[@val>4])', 'INT') AS val
FROM @x.nodes('/Root/Item') AS T(c)
ORDER BY 1
go

DECLARE @xml XML = N'
<catalog xmlns:bk="http://example.com/books">
  <bk:book id="B001" lang="en">
    <id>987654</id>
    <price>29.99</price>
    <quantity>150</quantity>
    <rating>4.7</rating>
  </bk:book>
  <bk:book id="B002" lang="fr">
    <id>543219</id>
    <price>39.50</price>
    <quantity>75</quantity>
    <rating>3.2</rating>
  </bk:book>
</catalog>'
SELECT
    T.c.value('local-name(.)',        'NVARCHAR(100)')  AS [local-name],
    T.c.value('number(.)',            'FLOAT')          AS [number],
    T.c.value('floor(.)',             'INT')            AS [floor],
    T.c.value('ceiling(.)',           'INT')            AS [ceiling],
    T.c.value('round(.)',             'INT')            AS [round]
FROM @xml.nodes('/catalog//*[not(*)]') AS T(c)
ORDER BY 1,2,3,4,5

-- contains()
SELECT T.c.value('.', 'NVARCHAR(100)') AS element_value
FROM @xml.nodes('/catalog//title') AS T(c)
WHERE T.c.value('contains(., "XML")', 'BIT') = 1
ORDER BY 1

-- sum(.) - note: sum needs a node-set, so we use it on child nodes
SELECT @xml.value('sum(/catalog//price)', 'DECIMAL(10,2)') AS total_price

-- count(.) - returns 1 per node
SELECT T.c.value('count(.)', 'INT') AS count_of_self
FROM @xml.nodes('/catalog//*') AS T(c)
ORDER BY 1
go

DECLARE @xml XML = N'
<data>
  <item><value>hello</value><separator>l</separator></item>
  <item><value>world</value><separator>o</separator></item>
  <item><value>12345</value><separator>3</separator></item>
</data>'

SELECT
  T.c.value('.', 'NVARCHAR(50)') AS val,
  T.c.value('substring(., 2, string-length(.))', 'NVARCHAR(100)') AS [substring_dot_derived]
FROM @xml.nodes('/data/item/value[. = "12345"]') AS T(c)
ORDER BY 1,2

-- Concatenates the node value with itself
SELECT
    T.c.value('concat(., " | ", .)', 'NVARCHAR(200)') AS [concat_dot_dot]
FROM @xml.nodes('/data/item/value') AS T(c)
ORDER BY 1

-- Concatenates the node value with itself
SELECT
    T.c.value('.', 'NVARCHAR(50)') AS val,
    T.c.value('string(contains(., .))', 'NVARCHAR(10)') AS [contains_dot_dot]
FROM @xml.nodes('/data/item/value') AS T(c)
ORDER BY 1

-- Concatenates three times
SELECT
    T.c.value('concat(., ., .)', 'NVARCHAR(200)') AS [concat_three_dots]
FROM @xml.nodes('/data/item/value') AS T(c)
ORDER BY 1
go


DECLARE @xml XML = N'
<items>
  <item code="ABC123">Premium Package</item>
  <item code="XYZ789">Basic Package</item>
</items>'

-- ./@ uses dot for navigation, also for function argument string(.) in one value() call
SELECT
     T.c.value('concat(./@code, " = ", string(.))', 'NVARCHAR(200)') AS combined
 FROM @xml.nodes('/items/item') AS T(c)
ORDER BY 1
go

DECLARE @xml XML = N'
<products>
  <product><name>Widget</name><price>9.99</price></product>
  <product><name>Gadget</name><price>24.50</price></product>
</products>'

-- '.' (navigation) and 'string(.)' (function) in one value() call
SELECT
    T.c.value('concat(string(.), " [len=", string(string-length(string(.))), "]")', 'NVARCHAR(200)') AS result
 FROM @xml.nodes('/products/product/name') AS T(c)
ORDER BY 1
go

DECLARE @xml XML = N'
<items>
<item>Hello</item>
<item>Brave</item>
<item>New</item>
<item>World</item>
<item>12345</item>
</items>'

-- '.' is the path expression navigating to the node
-- 'string(.)' appears in the predicate filter
SELECT
  T.c.value('.', 'NVARCHAR(50)') AS plain_dot,
  T.c.value('string(.)', 'NVARCHAR(50)') AS string_of_dot,
  T.c.value('(./parent::*/item[string-length(string(.)) > 4])[1]', 'NVARCHAR(50)') AS filtered
FROM @xml.nodes('/items/item') AS T(c)
ORDER BY 1,2
go

DECLARE @xml XML = N'
<orders>
  <order id="1001"><amount>75.50</amount><status>shipped</status></order>
  <order id="2002"><amount>120.00</amount><status>pending</status></order>
  <order id="3003"><amount>45.99</amount><status>shipped</status></order>
</orders>'

-- Combining:
--   string-length(.)  dot as function argument (string value of context node)
--   contains(., ...)  dot as function argument
--   ./@id            regular XPath dot (self axis, then attribute)
SELECT
    T.c.value('./@id', 'INT') AS order_id,
    T.c.value('string-length(.)', 'INT') AS [node_string_length],
    T.c.value('string(contains(., "shipped"))', 'NVARCHAR(10)') AS [contains_shipped]
FROM @xml.nodes('/orders/order') AS T(c)
ORDER BY 1,2,3
go

DECLARE @xml XML = N'
  <sales>
    <region name="North">
      <quarter>1500.00</quarter>
      <quarter>2200.50</quarter>
      <quarter>1800.75</quarter>
      <quarter>2500.00</quarter>
    </region>
    <region name="South">
      <quarter>1200.00</quarter>
      <quarter>1900.25</quarter>
      <quarter>2100.00</quarter>
      <quarter>2800.50</quarter>
    </region>
    <region name="West">
      <quarter>3000.00</quarter>
      <quarter>2700.00</quarter>
      <quarter>3100.50</quarter>
      <quarter>3500.75</quarter>
    </region>
  </sales>'

-- sum(.) doesn't work meaningfully on a single node (it's just the node's numeric value).
-- sum() needs a node-set, so we use it on child nodes relative to the context node.
-- Use nodes() to get each region, then sum(.) on its children
SELECT
  T.c.value('@name', 'NVARCHAR(50)') AS region_name,
  T.c.value('sum(quarter)', 'DECIMAL(10,2)') AS total_sales_1,
  T.c.value('sum(./quarter)', 'DECIMAL(10,2)') AS total_sales_2
FROM @xml.nodes('/sales/region') AS T(c)
ORDER BY 1,2

SELECT
  T.c.value('sum(.)', 'DECIMAL(10,2)') AS sum_of_dot,
  T.c.value('.', 'DECIMAL(10,2)') AS plain_dot
FROM @xml.nodes('/sales/region[@name   = "North"]/quarter') AS T(c)
ORDER BY 1,2

SELECT
  T.c.value('@name', 'NVARCHAR(50)') AS region_name,
  T.c.value('sum(./quarter)', 'DECIMAL(10,2)') AS sum_via_dot_path
FROM @xml.nodes('/sales/region') AS T(c)
ORDER BY 1,2
go

-- XPath 1.0 functions that cannot take an argument
DECLARE @xml XML = N'
<library>
  <book id="1"><title>XPath Essentials</title><price>19.99</price></book>
  <book id="2"><title>SQL Server XML</title><price>29.99</price></book>
  <book id="3"><title>T-SQL Cookbook</title><price>39.99</price></book>
  <book id="4"><title>Query Optimization</title><price>49.99</price></book>
  <book id="5"><title>Database Design</title><price>59.99</price></book>
</library>'

-- Select the last book
SELECT @xml.value('(/library/book[last()]/title)[1]', 'NVARCHAR(100)') AS last_book

-- Select the second-to-last book
SELECT @xml.value('(/library/book[last() - 1]/title)[1]', 'NVARCHAR(100)') AS second_to_last

-- Use last() to get the count of books
SELECT @xml.value('count(/library/book[last()])', 'INT') AS last_exists

-- Select the first 3 books using position()
SELECT T.c.value('title[1]', 'NVARCHAR(100)') AS book_title
FROM @xml.nodes('/library/book[position() <= 3]') AS T(c)
ORDER BY 1

-- Select the book at position 3
SELECT @xml.value('(/library/book[position() = 3]/title)[1]', 'NVARCHAR(100)') AS third_book

-- Combine position() and last()
SELECT T.c.value('title[1]', 'NVARCHAR(100)') AS not_first_not_last
FROM @xml.nodes('/library/book[position() > 1 and position() < last()]') AS T(c)
ORDER BY 1

-- Select all books (predicate always true)
SELECT T.c.value('title[1]', 'NVARCHAR(100)') AS all_books
FROM @xml.nodes('/library/book[true()]') AS T(c)
ORDER BY 1

-- Use true() in a conditional string
SELECT @xml.value('string(true())', 'NVARCHAR(10)') AS true_string

-- Select no books (predicate always false)
SELECT T.c.value('title[1]', 'NVARCHAR(100)') AS no_books
FROM @xml.nodes('/library/book[false()]') AS T(c)
ORDER BY 1

-- Use false() in a conditional string
SELECT @xml.value('string(false())', 'NVARCHAR(10)') AS false_string

-- Use false() to test negation: not(false()) = true
SELECT T.c.value('title[1]', 'NVARCHAR(100)') AS all_books_via_not_false
FROM @xml.nodes('/library/book[not(false())]') AS T(c)
ORDER BY 1

-- Combine true() and false() with boolean logic
SELECT
    @xml.value('string(true() and true())',   'NVARCHAR(10)') AS [true_and_true],
    @xml.value('string(true() and false())',  'NVARCHAR(10)') AS [true_and_false],
    @xml.value('string(true() or false())',   'NVARCHAR(10)') AS [true_or_false],
    @xml.value('string(not(false()))',        'NVARCHAR(10)') AS [not_false]
-- Result: "true", "false", "true", "true"
go

-- expected error cases ----------------

-- nodes() with QUOTED_IDENTIFIER OFF
SET QUOTED_IDENTIFIER OFF
go

DECLARE @xml XML = '<Root><row id="1"/></Root>'
SELECT T.C.value('(@id)[1]', 'int') AS id
FROM @xml.nodes('/Root/row') AS T(C)
ORDER BY 1
go

SET QUOTED_IDENTIFIER ON
go

-- too many arguments
DECLARE @xml XML = '<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>'
SELECT * FROM @xml.nodes('/Root/row', 'another argument') AS T(C)
ORDER BY 1
go

-- too few arguments
DECLARE @xml XML = '<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>'
SELECT * FROM @xml.nodes() AS T(C)
ORDER BY 1
go

-- cannot call nodes() on non-XML type
DECLARE @x INT = 1
SELECT T.C.value('(.)[1]', 'varchar(20)') AS val
FROM @x.nodes('/root') AS T(C)
ORDER BY 1
go

-- string constant required for xpath expression
DECLARE @v varchar(100) = '(//@id)[2]'
select CAST('<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>' as xml).value(@v, 'int') AS id
go

DECLARE @xml XML = '<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>'
SELECT @xml.value('(@id)[1]', 'varchar(100)') as xx
go

DECLARE @xml XML = '<Root><item>A</item><item>B</item></Root>'
SELECT T.C.value('.', 'varchar(20)') AS val
FROM @xml.nodes('..') AS T(C)
ORDER BY 1
go

DECLARE @v varchar(100) = '/Root/row'
DECLARE @xml XML = '<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>'
SELECT T.C.value('(@id)[1]', 'int') AS id
FROM @xml.nodes(@v) AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<orders><o id="1"><li>item-1</li><li>item-2</li></o><o id="2"><li>item-3</li></o></orders>'
SELECT @xml.value('../@id','int')
go

DECLARE @xml XML = '<orders><o id="1"><li>item-1</li><li>item-2</li></o><o id="2"><li>item-3</li></o></orders>'
SELECT @xml.value('(../@id)[1]','int')
go

-- nodes() on a table column with CROSS APPLY
SELECT t.Id, T.C.value('(@id)[1]', 'int') AS row_id, T.C.value('(name)[1]', 'varchar(100)') AS name
FROM babel_5225_xml_nodes_t1 t
CROSS APPLY t.XmlColumn.nodes('/Root/row') AS T(C)
ORDER BY 1,2,3
go

-- nodes() on empty element (no children matched)
SELECT t.Id
FROM babel_5225_xml_nodes_t1 t
CROSS APPLY t.XmlColumn.nodes('/Root/row') AS T(C)
WHERE t.Id = 3
ORDER BY 1
go

-- nodes() with attribute xpath
SELECT T.C.value('(@name)[1]', 'varchar(100)') AS name, T.C.value('(@id)[1]', 'int') AS id
FROM babel_5225_xml_nodes_t2 t
CROSS APPLY t.XmlColumn.nodes('/artists/artist') AS T(C)
ORDER BY 1
go

-- nodes() combined with value() on same column
SELECT T.C.value('(@id)[1]', 'int') AS id, T.C.value('(name)[1]', 'varchar(100)') AS name
FROM babel_5225_xml_nodes_t1 t
CROSS APPLY t.XmlColumn.nodes('/Root/row') AS T(C)
WHERE t.Id = 1
ORDER BY 1
go

-- parent beyond root
DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('..[1]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('(..)[1]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('(.)', 'varchar(20)') AS id
FROM @xml.nodes('..[2]') AS T(C)
ORDER BY 1
go

-- GROUP BY expression cannot contain XML method calls
DECLARE @xml XML = '<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>'
SELECT T.C.value('(@id)[1]', 'int') AS id, count(*) AS cnt
FROM @xml.nodes('/Root/row') AS T(C)
GROUP BY T.C.value('(@id)[1]', 'int')
ORDER BY 1
go

DECLARE @xml XML = '<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>'
SELECT T.C.value('(@id)[1]', 'int') + 1 AS id, count(*) AS cnt
FROM @xml.nodes('/Root/row') AS T(C)
GROUP BY T.C.value('(@id)[1]', 'int') + 1
ORDER BY 1
go

-- nodes() case sensitivity: only lowercase is valid in T-SQL, but not enforced in Babelfish
DECLARE @xml XML = '<Root><item>A</item><item>B</item></Root>'
SELECT T.C.value('(.)[1]', 'varchar(20)') AS val
FROM @xml.NODES('/Root/item') AS T(C)
ORDER BY val
go

DECLARE @xml XML = '<Root><item>A</item><item>B</item></Root>'
SELECT T.C.value('(.)[1]', 'varchar(20)') AS val
FROM @xml.Nodes('/Root/item') AS T(C)
ORDER BY val
go

-- Some XPath 2.0 cases, not supported in PostgreSQL/Babelfish
DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('.', 'varchar(20)') AS id
FROM @xml.nodes('/Root/row/name/..[1]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name>James</name></row><row><name>Megan</name></row></Root>'
SELECT T.C.value('.', 'varchar(20)') AS id
FROM @xml.nodes('/Root/row/name/..[2]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name id="1">James</name><name id="2">Robert</name></row><row><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('/Root/row/name/..[1]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('@id', 'varchar(20)') AS id, T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('/Root/row/name/..[1]') AS T(C)
ORDER BY 1
go

DECLARE @xml XML = '<Root><row><name id="1">James</name></row><row><name id="2">Suzy</name><name id="3">Megan</name></row></Root>'
SELECT T.C.value('.', 'varchar(20)') AS name
FROM @xml.nodes('/Root/row/name/..[2]') AS T(C)
ORDER BY 1
go

-- T-SQL error cases which are not raising an error in Babelfish --------------

-- SELECT * FROM .nodes() should not be valid but returns results in Babelfish
DECLARE @xml XML = '<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>'
SELECT * FROM @xml.nodes('/Root/row') AS T(C)
go

-- should return "'value()' requires a singleton (or empty sequence)'" but returns results in Babelfish
DECLARE @xml XML = '<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>'
SELECT T.C.value('(@id)[1]', 'int') AS id, T.C.value('(name)', 'varchar(100)') AS name
FROM @xml.nodes('/Root/row') AS T(C)
ORDER BY 1
go

-- should return "'value()' requires a singleton (or empty sequence)'" but returns results in Babelfish
DECLARE @xml XML = '<Root><row id="1"><name>James</name></row><row id="2"><name>Megan</name></row></Root>'
SELECT T.C.value('(@id)[1]', 'int') AS id, T.C.value('name', 'varchar(100)') AS name
FROM @xml.nodes('/Root/row') AS T(C)
ORDER BY 1
go

-- should return "'value()' requires a singleton (or empty sequence)'" but returns results in Babelfish
SELECT T.C.value(' . . / @id [1]', 'int') AS id
FROM (SELECT CAST('<Root><row id="10"/><row id="20"/></Root>' AS XML)) AS X(Col)
CROSS APPLY X.Col.nodes('/Root/row') AS T(C)
ORDER BY 1
go


