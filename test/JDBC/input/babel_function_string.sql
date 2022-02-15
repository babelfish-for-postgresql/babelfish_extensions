-- test REPLICATE function
SELECT REPLICATE(' abc ', 3)
GO

SELECT REPLICATE(N'abc', 3)
GO

SELECT REPLICATE(' abc ', 0)
GO

-- test null condition
SELECT REPLICATE('abc', -3)
GO

SELECT REPLICATE(null, 1)
GO

-- test LEN and DATALENGTH functions
SELECT LEN(N'123')
GO

SELECT LEN(N'123   ')
GO

SELECT LEN(N'   123   ')
GO

SELECT LEN(CAST('123' as char(25)))
GO

SELECT LEN('abc')
GO

SELECT LEN('abc' + 'def')
GO

SELECT LEN('tamaño')
GO

SELECT DATALENGTH(N'123')
GO

SELECT DATALENGTH(N'123   ')
GO

SELECT DATALENGTH(N'   123   ')
GO

SELECT DATALENGTH(CAST('123' as char(25)))
GO

SELECT DATALENGTH('ab' + 'def')
GO

SELECT DATALENGTH('哈哈12345')
GO

-- additional tests for DATALENGTH (more types, nullvalues)
CREATE table t1 (a binary(10), b image, c varbinary(10), d char(10),
			     e varchar(10), f text, g nchar(10), h nvarchar(10), i ntext)
GO

INSERT into t1 values (cast('abc' as binary(10)), cast('abc' as image), cast('abc' as varbinary(10)),'abc','abc','abc','abc','abc','abc')
GO

INSERT into t1 values (null, null, null, null, null, null,null, null, null)
GO

SELECT datalength(a), datalength(b),datalength(c),datalength(d),datalength(e),
       datalength(f),datalength(g),datalength(h),datalength(i) FROM t1
GO

CREATE table t2 (a integer, b bigint, c bit, d smallint, e tinyint, f decimal, g numeric, h float, i real)
GO

INSERT into t2 values (1, 1, 1, 1, 1, 1, 1, 1, 1)
GO

INSERT into t2 values (null, null, null, null, null, null,null, null, null)
GO

SELECT datalength(a), datalength(b),datalength(c),datalength(d),datalength(e), datalength(f),datalength(g),datalength(h),datalength(i) FROM t2
GO

CREATE table t3 (a smallmoney, b money, c date, d datetime, e datetime2, f smalldatetime, g time, h uniqueidentifier)
GO

INSERT into t3 values (cast(1 as smallmoney), cast(1 as money), cast('2020-02-20' as date), cast('2020-02-20 20:20:20.888' as datetime), 
                        cast('2020-02-20 20:20:20.88888' as datetime2), cast('2020-02-20 20:20:20' as smalldatetime), cast('20:20:20.888' as time), 
                        cast('6F9619FF-8B86-D011-B42D-00C04FC964FF' as uniqueidentifier))
GO

INSERT into t3 values (null, null, null, null, null, null,null, null)
GO

SELECT datalength(a), datalength(b),datalength(c),datalength(d),datalength(e), datalength(f),datalength(g),datalength(h) FROM t3
GO

-- test quotename function
SELECT quotename('hardrada', ']')
GO

SELECT quotename('gershwin', '<')
GO

SELECT quotename('faulkner', '>')
GO

SELECT quotename('edgerton', '(')
GO

SELECT quotename('denali', ')')
GO

SELECT quotename('charisma', '{')
GO

SELECT quotename('banana', '}')
GO

SELECT quotename('aardvark', '`')
GO

SELECT quotename('128 characters exactly----------------------------------------------------------------------------------------------------------')
GO

SELECT
quotename(']]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]')
GO

SELECT
quotename('""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""')
GO

SELECT quotename('''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''')
GO

SELECT quotename('')
GO

-- regtype error expected pending BABEL-883
SELECT pg_typeof(quotename('a'))
GO

SELECT quotename(CAST('abc' as varchar))
GO

SELECT quotename(CAST('abc' as sys.nvarchar))
GO

SELECT quotename(CAST('abc' as text))
GO

SELECT quotename('invalid char', 'F')
GO

SELECT quotename('too long char', 'aa')
GO

SELECT quotename('129 characters exactly-----------------------------------------------------------------------------------------------------------')
GO

SELECT quotename('default should be bracket')
GO

SELECT quotename('abc [] def')
GO

SELECT quotename(NULL)
GO

SELECT quotename(NULL, NULL)
GO

SELECT quotename('hey', NULL)
GO

SELECT quotename(NULL, '[')
GO

-- test unicode function

SELECT unicode(null)
GO

SELECT unicode('Åkergatan 24')
GO

SELECT nchar(unicode('Åkergatan 24'))
GO

SELECT unicode(cast('Āmazon' AS nvarchar))
GO

SELECT unicode(CAST('Āmazon' as nvarchar))
GO

SELECT unicode(cast('Ƃ' as nchar))
GO

SELECT unicode(CAST('Ƃ' as nchar))
GO

SELECT STRING_SPLIT('Lorem ipsum dolor sit amet.', ' ')
GO

SELECT STRING_SPLIT('clothing,road,,touring,bike', ',')
GO

SELECT STRING_SPLIT('||||||||', '|')
GO

SELECT STRING_SPLIT(NULL, ' ')
GO

-- test invalid separator
SELECT STRING_SPLIT('asdf', '')
GO

SELECT STRING_SPLIT('asdf', NULL)
GO

SELECT STRING_SPLIT(NULL, NULL)
GO

SELECT STRING_SPLIT(CAST('nvarchar nvarchar nvarchar' as nvarchar), CAST(' ' as nvarchar))
GO

SELECT STRING_SPLIT(CAST('varchar varchar varchar' as varchar), CAST(' ' as varchar))
GO

SELECT STRING_SPLIT('char char char', ' ')
GO

SELECT STRING_SPLIT('a,b,c,d', ',')
GO

SELECT STRING_SPLIT('mississippi island lives in igloo', 'i')
GO

SELECT STRING_SPLIT(CAST('asdf' as nchar(4)), ' ')
GO

SELECT STRING_SPLIT(CAST('asdf' as char(4)), ' ')
GO

-- test invalid separator
SELECT STRING_SPLIT('Lorem ipsum', 'too many chars')
GO

SELECT value FROM STRING_SPLIT('Lorem ipsum dolor sit amet.', ' ')
GO

SELECT mycol FROM STRING_SPLIT('Lorem ipsum dolor sit amet.', ' ')
GO

-- STRING_ESCAPE tests

SELECT STRING_ESCAPE('foo', 'notjson')
GO

SELECT STRING_ESCAPE('foo', '')
GO

SELECT STRING_ESCAPE('foo', NULL)
GO

SELECT STRING_ESCAPE(NULL, '')
GO

SELECT STRING_ESCAPE(NULL, NULL)
GO

SELECT STRING_ESCAPE(NULL, 'json')
GO

SELECT STRING_ESCAPE('	', 'json')
GO

SELECT STRING_ESCAPE('"', 'json')
GO

SELECT STRING_ESCAPE('\', 'json')
GO

SELECT STRING_ESCAPE('/', 'json')
GO

SELECT STRING_ESCAPE(chr(1), 'json')
GO

SELECT STRING_ESCAPE(chr(2), 'json')
GO

SELECT STRING_ESCAPE(chr(8), 'json')
GO

SELECT STRING_ESCAPE(chr(9), 'json')
GO

SELECT STRING_ESCAPE('
', 'json')
GO

SELECT STRING_ESCAPE(chr(10), 'json')
GO

SELECT STRING_ESCAPE(chr(11), 'json')
GO

SELECT STRING_ESCAPE(chr(12), 'json')
GO

SELECT STRING_ESCAPE(chr(13), 'json')
GO

SELECT STRING_ESCAPE(chr(31), 'json')
GO

SELECT STRING_ESCAPE('lorem ipsum dolor amet	
consectetur adipiscing elit', 'json')
GO

-- clean up
DROP table t1, t2, t3
GO

