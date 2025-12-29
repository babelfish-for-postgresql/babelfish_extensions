SELECT * FROM babel_isnumeric_vu_prepare_t1
GO
-- Test bigint
SELECT ISNUMERIC(bigint_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test int
SELECT ISNUMERIC(int_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test smallint
SELECT ISNUMERIC(smallint_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test tinyint
SELECT ISNUMERIC(tinyint_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test bit
SELECT ISNUMERIC(bit_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test decimal
SELECT ISNUMERIC(decimal_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test numeric
SELECT ISNUMERIC(numeric_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test float
SELECT ISNUMERIC(float_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test real
SELECT ISNUMERIC(real_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test money
SELECT ISNUMERIC(money_type)
FROM babel_isnumeric_vu_prepare_t1
GO
-- Test smallmoney
SELECT ISNUMERIC(smallmoney_type)
FROM babel_isnumeric_vu_prepare_t1
GO

-- Test valid and invalid operators and literals
select isnumeric(1234567890)
GO
select isnumeric('28903')
GO
select isnumeric('+')
GO
select isnumeric('+ ')
GO
-- Blocked due to BABEL-2853
--select isnumeric($)
--GO
select isnumeric('$24,23.43')
GO
-- Blocked due to BABEL-2853
--select isnumeric(€)
--GO
select isnumeric('+ 1')
GO
select isnumeric('$+1.1234')
GO
select isnumeric('+$1.1234')
GO
select isnumeric(' $ + 1.1234')
GO
select isnumeric(' + $ 1.1234')
GO

select isnumeric('abcdefghijklmnop')
GO
select isnumeric('24.89.43')
GO
select isnumeric('€24,2.3.43')
GO
select isnumeric('+-')
GO
select isnumeric('23$')
GO
select isnumeric(null)
GO
select isnumeric(' ')
GO
select isnumeric('1 .1234')
GO
select isnumeric('+1 .1234')
GO
select isnumeric('$1 .1234')
GO

-- Test different datatypes as local variables
DECLARE @int_var int = 12345
select isnumeric(@int_var)
GO

DECLARE @bigint_var bigint = 9223372036854775807
select isnumeric(@bigint_var)
GO

DECLARE @smallint_var smallint = -32768
select isnumeric(@smallint_var)
GO

DECLARE @tinyint_var tinyint = 255
select isnumeric(@tinyint_var)
GO

DECLARE @bit_var bit = 1
select isnumeric(@bit_var)
GO

DECLARE @decimal_var decimal(10,5) = 12345.67890
select isnumeric(@decimal_var)
GO

DECLARE @numeric_var numeric(18,9) = 123456789.987654321
select isnumeric(@numeric_var)
GO

DECLARE @float_var float = 1.79E+308
select isnumeric(@float_var)
GO

DECLARE @real_var real = 3.40E+38
select isnumeric(@real_var)
GO

DECLARE @money_var money = 922337203685477.5807
select isnumeric(@money_var)
GO

DECLARE @smallmoney_var smallmoney = 214748.3647
select isnumeric(@smallmoney_var)
GO

DECLARE @char_var char(20) = '12345.6789'
select isnumeric(@char_var)
GO

DECLARE @varchar_var varchar(50) = '$1,234,567.89'
select isnumeric(@varchar_var)
GO

DECLARE @nchar_var nchar(20) = N'12345.6789'
select isnumeric(@nchar_var)
GO

DECLARE @nvarchar_var nvarchar(50) = N'-9876.54321'
select isnumeric(@nvarchar_var)
GO

DECLARE @datetime_var datetime = '2023-01-01 12:34:56'
select isnumeric(@datetime_var)
GO

DECLARE @date_var date = '2023-01-01'
select isnumeric(@date_var)
GO

-- Test text values exceeding numeric(38,0)
select isnumeric('9999999999999999999999999999999999999999')
GO

select isnumeric('10000000000000000000000000000000000000000')
GO

select isnumeric('-9999999999999999999999999999999999999999')
GO

select isnumeric('999999999999999999999999999999999999999.99999')
GO

select isnumeric('1' + REPLICATE('0', 38))
GO

select isnumeric('1' + REPLICATE('0', 100))
GO

select isnumeric('0.' + REPLICATE('9', 38))
GO

select isnumeric('1E+38')
GO

select isnumeric('1E+100')
GO

select isnumeric('1E-100')
GO

-- Test invalid conversions to numeric
select isnumeric('abc')
GO

select isnumeric('123abc')
GO

select isnumeric('abc123')
GO

select isnumeric('12.34.56')
GO

select isnumeric('12,34,56')
GO

select isnumeric('$123$456')
GO

select isnumeric('123..456')
GO

select isnumeric('++123')
GO

select isnumeric('--123')
GO

select isnumeric('+-123')
GO

select isnumeric('123-')
GO

select isnumeric('123+')
GO

select isnumeric('123.456.789')
GO

select isnumeric('1,23,456')
GO

select isnumeric('1.2e3.4')
GO

select isnumeric('1.2e')
GO

select isnumeric('e1.2')
GO

select isnumeric('1.2D')
GO


select isnumeric('€')
GO

select isnumeric('¥')
GO

select isnumeric('£')
GO

-- Test expressions with mixed valid/invalid inputs
select isnumeric('123' + 'abc')
GO

DECLARE @valid varchar(10) = '123', @invalid varchar(10) = 'abc'
select isnumeric(@valid + @invalid)
GO

DECLARE @overflow varchar(50) = '1' + REPLICATE('0', 38)
select isnumeric(@overflow)
GO

-- Test with expressions that might cause overflow
DECLARE @big_decimal decimal(38,0) = 99999999999999999999999999999999999999
select isnumeric(@big_decimal)
GO

DECLARE @big_float float = 1.79E+308
select isnumeric(@big_float)
GO

-- Test with CAST that might cause overflow
select isnumeric(CAST(1.79E+308 AS varchar(50)))
GO

-- Test with computed expressions
select isnumeric(CAST(POWER(10, 3) AS varchar(50)))
GO

-- Testing empty string 

-- string datatypes
select isnumeric('')
go

select isnumeric('    ')
go

select isnumeric(cast('' as varchar))
go

select isnumeric(cast('' as char))
go  

select isnumeric(cast('' as nchar))
go

select isnumeric(cast('' as nvarchar(max)))
go
           
select isnumeric(cast('' as nvarchar(1)))
go

select isnumeric(cast('' as varchar(1)))
go

select isnumeric(N'')
go

select isnumeric(cast('' as nvarchar))
go

select isnumeric(N'123')
go

-- binary/varbinary
-- Fix with BABEL-6101
select isnumeric(cast('' as binary))
go

select isnumeric(cast('' as varbinary))
go

-- Fix with BABEL-6101 
select isnumeric(cast('' as binary(1)))
go

-- Exact numerics 
select isnumeric(cast('' as bigint))
go

select isnumeric(cast('' as tinyint))
go
          
select isnumeric(cast('' as smallint))
go

select isnumeric(cast('' as int))
go

-- money/smallmoney (Monetary values)
select isnumeric(cast('' as money))
go

select isnumeric(cast('' as smallmoney))
go

-- real/float (Approximate)
select isnumeric(cast('' as real))
go

select isnumeric(cast('' as float))
go

-- decimal/numeric (Fixed precision)
select isnumeric(cast('' as numeric))
go

select isnumeric(cast('' as decimal))
go

select isnumeric(cast('' as text))
go

-- text/ntext
select isnumeric(cast(12234555 as text))
go

select isnumeric(cast('12234555' as text))
go

select isnumeric(cast('' as ntext))
go

-- xml
select isnumeric(cast('' as xml))
go

-- bit
select isnumeric(cast('' as bit))
GO

-- large input values
select isnumeric(1234567812345678123456781234567812345678)
Go

select isnumeric(cast(1234567812345678123456781234567812345678 as text))
go

-- misc tests
-- Fix with BABEL-6101
select isnumeric(cast(24 as varbinary))
Go

select isnumeric(cast('24' as varbinary))
GO

-- time/date/smalldatetime/datetime/datetime2/datetimeoffset
DECLARE @inputString date = '2016-12-21';
DECLARE @inputEmptyString date = '';
select isnumeric(@inputString), isnumeric(@inputEmptyString);
GO


DECLARE @inputString smalldatetime = '1955-12-13 12:43:10';
DECLARE @inputEmptyString smalldatetime = '';
select isnumeric(@inputString), isnumeric(@inputEmptyString);
GO

DECLARE @inputString time(4) = '12:10:05.1237';
DECLARE @inputEmptyString time(4) = '';
select isnumeric(@inputString), isnumeric(@inputEmptyString);
GO

DECLARE @inputString datetime = '2006-01-02 15:04:05'
DECLARE @inputEmptyString datetime = '';
select isnumeric(@inputString), isnumeric(@inputEmptyString);
go

DECLARE @inputString datetimeoffset(4) = '1968-10-23 12:45:37.1234 +10:0';
DECLARE @inputEmptyString datetimeoffset(4) = '';
select isnumeric(@inputString), isnumeric(@inputEmptyString);
GO

DECLARE @inputString datetime2(4) = '1968-10-23 12:45:37.1237';
DECLARE @inputEmptyString datetime2(4) = '';
select isnumeric(@inputString), isnumeric(@inputEmptyString);
GO

-- sql_variant
DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant);
DECLARE @inputEmptyString sql_variant = '';
SELECT isnumeric(CAST(@inputString AS VARCHAR(50))), isnumeric(CAST(@inputEmptyString AS VARCHAR(50)))
GO

DECLARE @inputString sql_variant = CAST ('6F9619FF-8B86-D011-B42D-00C04FC964FF' AS sql_variant)
DECLARE @inputEmptyString sql_variant = '';
select isnumeric(@inputString), isnumeric(@inputEmptyString);
GO


-- Special whitespace Test cases

DECLARE @a NVARCHAR(max)
SET @a = CHAR(10)
SELECT ISNUMERIC(@a)
GO

DECLARE @a NVARCHAR(max)
SET @a = '  ' + CHAR(10) + '   '
SELECT ISNUMERIC(@a)
GO

DECLARE @a NVARCHAR(max)
SET @a = CHAR(9)
SELECT ISNUMERIC(@a)
GO

DECLARE @a NVARCHAR(max)
SET @a = CHAR(13)
SELECT ISNUMERIC(@a)
GO

DECLARE @a NVARCHAR(max)
SET @a = CHAR(10) + CHAR(9)
SELECT ISNUMERIC(@a)
GO

DECLARE @a NVARCHAR(max)
SET @a = CHAR(13) + CHAR(9)
SELECT ISNUMERIC(@a)
GO

DECLARE @a NVARCHAR(max)
SET @a = CHAR(10) + CHAR(13)
SELECT ISNUMERIC(@a)
GO

DECLARE @a NVARCHAR(max)
SET @a = CHAR(10) + CHAR(10)
SELECT ISNUMERIC(@a)
GO

DECLARE @a NVARCHAR(max)
SET @a = CHAR(9) + CHAR(9)
SELECT ISNUMERIC(@a)
GO

DECLARE @a NVARCHAR(max)
SET @a = CHAR(9) + CHAR(10)
SELECT isnumeric(cast(@a AS CHAR))
GO

DECLARE @a NVARCHAR(max)
SET @a = CHAR(9) + CHAR(10)
SELECT isnumeric(cast(@a AS NCHAR))
GO

DECLARE @a VARCHAR(50)
SET @a = CHAR(9) + CHAR(13)
SELECT isnumeric(cast(@a AS NVARCHAR))
GO

DECLARE @a VARCHAR(50)
SET @a = CHAR(10) + CHAR(9)
SELECT isnumeric(cast(@a as binary))
GO

-- basic tests

select isnumeric(char(9)) -- Horizontal Tab
GO

select isnumeric(char(10)) -- Newline (Line Feed)
go

select isnumeric(char(13)) -- Carriage Return
go

select isnumeric(char(32)) -- Space 
go

select isnumeric(char(11)) -- Vertical Tab
go

select isnumeric(char(12)) -- Form Feed
go


select isnumeric(char(8)) -- Backspace
go

-- extra works 
select isnumeric(cast('' as char(33)))
go


select isnumeric ('  ') -- TAB
go

select isnumeric ('  ') -- combination of space and tab
go

SELECT ISNUMERIC(CHAR(0));
GO
SELECT ISNUMERIC(CHAR(1));
GO
SELECT ISNUMERIC(CHAR(2));
GO
SELECT ISNUMERIC(CHAR(3));
GO
SELECT ISNUMERIC(CHAR(4));
GO
SELECT ISNUMERIC(CHAR(5));
GO
SELECT ISNUMERIC(CHAR(6));
GO
SELECT ISNUMERIC(CHAR(7));
GO
SELECT ISNUMERIC(CHAR(8));    -- \b backspace
GO
SELECT ISNUMERIC(CHAR(9));    -- \t tab
GO
SELECT ISNUMERIC(CHAR(10));   -- \n newline
GO
SELECT ISNUMERIC(CHAR(11));   -- \v vertical tab
GO
SELECT ISNUMERIC(CHAR(12));   -- \f form feed
GO
SELECT ISNUMERIC(CHAR(13));   -- \r carriage return
GO
SELECT ISNUMERIC(CHAR(14));
GO
SELECT ISNUMERIC(CHAR(15));
GO
SELECT ISNUMERIC(CHAR(16));
GO
SELECT ISNUMERIC(CHAR(17));
GO
SELECT ISNUMERIC(CHAR(18));
GO
SELECT ISNUMERIC(CHAR(19));
GO
SELECT ISNUMERIC(CHAR(20));
GO
SELECT ISNUMERIC(CHAR(21));
GO
SELECT ISNUMERIC(CHAR(22));
GO
SELECT ISNUMERIC(CHAR(23));
GO
SELECT ISNUMERIC(CHAR(24));
GO
SELECT ISNUMERIC(CHAR(25));
GO
SELECT ISNUMERIC(CHAR(26));
GO
SELECT ISNUMERIC(CHAR(27));
GO
SELECT ISNUMERIC(CHAR(28));
GO
SELECT ISNUMERIC(CHAR(29));
GO
SELECT ISNUMERIC(CHAR(30));
GO
SELECT ISNUMERIC(CHAR(31));
GO
SELECT ISNUMERIC(CHAR(32));   -- space
GO
SELECT ISNUMERIC(CHAR(33));   -- !
GO
SELECT ISNUMERIC(CHAR(34));   -- "
GO
SELECT ISNUMERIC(CHAR(35));   -- #
GO
SELECT ISNUMERIC(CHAR(36));   -- $
GO
SELECT ISNUMERIC(CHAR(37));   -- %
GO
SELECT ISNUMERIC(CHAR(38));   -- &
GO
SELECT ISNUMERIC(CHAR(39));   -- '
GO
SELECT ISNUMERIC(CHAR(40));   -- (
GO
SELECT ISNUMERIC(CHAR(41));   -- )
GO
SELECT ISNUMERIC(CHAR(42));   -- *
GO
SELECT ISNUMERIC(CHAR(43));   -- +
GO
SELECT ISNUMERIC(CHAR(44));   -- ,
GO
SELECT ISNUMERIC(CHAR(45));   -- -
GO
SELECT ISNUMERIC(CHAR(46));   -- .
GO
SELECT ISNUMERIC(CHAR(47));   -- /
GO
SELECT ISNUMERIC(CHAR(48));   -- 0
GO
SELECT ISNUMERIC(CHAR(49));   -- 1
GO
SELECT ISNUMERIC(CHAR(50));   -- 2
GO
SELECT ISNUMERIC(CHAR(51));   -- 3
GO
SELECT ISNUMERIC(CHAR(52));   -- 4
GO
SELECT ISNUMERIC(CHAR(53));   -- 5
GO
SELECT ISNUMERIC(CHAR(54));   -- 6
GO
SELECT ISNUMERIC(CHAR(55));   -- 7
GO
SELECT ISNUMERIC(CHAR(56));   -- 8
GO
SELECT ISNUMERIC(CHAR(57));   -- 9
GO
SELECT ISNUMERIC(CHAR(58));   -- :
GO
SELECT ISNUMERIC(CHAR(59));   -- ;
GO
SELECT ISNUMERIC(CHAR(60));   -- <
GO
SELECT ISNUMERIC(CHAR(61));   -- =
GO
SELECT ISNUMERIC(CHAR(62));   -- >
GO
SELECT ISNUMERIC(CHAR(63));   -- ?
GO
SELECT ISNUMERIC(CHAR(64));   -- @
GO
SELECT ISNUMERIC(CHAR(65));   -- A
GO
SELECT ISNUMERIC(CHAR(66));   -- B
GO
SELECT ISNUMERIC(CHAR(67));   -- C
GO
SELECT ISNUMERIC(CHAR(68));   -- D
GO
SELECT ISNUMERIC(CHAR(69));   -- E
GO
SELECT ISNUMERIC(CHAR(70));   -- F
GO
SELECT ISNUMERIC(CHAR(71));   -- G
GO
SELECT ISNUMERIC(CHAR(72));   -- H
GO
SELECT ISNUMERIC(CHAR(73));   -- I
GO
SELECT ISNUMERIC(CHAR(74));   -- J
GO
SELECT ISNUMERIC(CHAR(75));   -- K
GO
SELECT ISNUMERIC(CHAR(76));   -- L
GO
SELECT ISNUMERIC(CHAR(77));   -- M
GO
SELECT ISNUMERIC(CHAR(78));   -- N
GO
SELECT ISNUMERIC(CHAR(79));   -- O
GO
SELECT ISNUMERIC(CHAR(80));   -- P
GO
SELECT ISNUMERIC(CHAR(81));   -- Q
GO
SELECT ISNUMERIC(CHAR(82));   -- R
GO
SELECT ISNUMERIC(CHAR(83));   -- S
GO
SELECT ISNUMERIC(CHAR(84));   -- T
GO
SELECT ISNUMERIC(CHAR(85));   -- U
GO
SELECT ISNUMERIC(CHAR(86));   -- V
GO
SELECT ISNUMERIC(CHAR(87));   -- W
GO
SELECT ISNUMERIC(CHAR(88));   -- X
GO
SELECT ISNUMERIC(CHAR(89));   -- Y
GO
SELECT ISNUMERIC(CHAR(90));   -- Z
GO
SELECT ISNUMERIC(CHAR(91));   -- [
GO
SELECT ISNUMERIC(CHAR(92));   -- \
GO
SELECT ISNUMERIC(CHAR(93));   -- ]
GO
SELECT ISNUMERIC(CHAR(94));   -- ^
GO
SELECT ISNUMERIC(CHAR(95));   -- _
GO
SELECT ISNUMERIC(CHAR(96));   -- `
GO
SELECT ISNUMERIC(CHAR(97));   -- a
GO
SELECT ISNUMERIC(CHAR(98));   -- b
GO
SELECT ISNUMERIC(CHAR(99));   -- c
GO
SELECT ISNUMERIC(CHAR(100));  -- d
GO
SELECT ISNUMERIC(CHAR(101));  -- e
GO
SELECT ISNUMERIC(CHAR(102));  -- f
GO
SELECT ISNUMERIC(CHAR(103));  -- g
GO
SELECT ISNUMERIC(CHAR(104));  -- h
GO
SELECT ISNUMERIC(CHAR(105));  -- i
GO
SELECT ISNUMERIC(CHAR(106));  -- j
GO
SELECT ISNUMERIC(CHAR(107));  -- k
GO
SELECT ISNUMERIC(CHAR(108));  -- l
GO
SELECT ISNUMERIC(CHAR(109));  -- m
GO
SELECT ISNUMERIC(CHAR(110));  -- n
GO
SELECT ISNUMERIC(CHAR(111));  -- o
GO
SELECT ISNUMERIC(CHAR(112));  -- p
GO
SELECT ISNUMERIC(CHAR(113));  -- q
GO
SELECT ISNUMERIC(CHAR(114));  -- r
GO
SELECT ISNUMERIC(CHAR(115));  -- s
GO
SELECT ISNUMERIC(CHAR(116));  -- t
GO
SELECT ISNUMERIC(CHAR(117));  -- u
GO
SELECT ISNUMERIC(CHAR(118));  -- v
GO
SELECT ISNUMERIC(CHAR(119));  -- w
GO
SELECT ISNUMERIC(CHAR(120));  -- x
GO
SELECT ISNUMERIC(CHAR(121));  -- y
GO
SELECT ISNUMERIC(CHAR(122));  -- z
GO
SELECT ISNUMERIC(CHAR(123));  -- {
GO
SELECT ISNUMERIC(CHAR(124));  -- |
GO
SELECT ISNUMERIC(CHAR(125));  -- }
GO
SELECT ISNUMERIC(CHAR(126));  -- ~
GO
SELECT ISNUMERIC(CHAR(127));  -- DEL
GO


-- Multiple same characters
SELECT ISNUMERIC('   ');                  -- multiple spaces
GO
SELECT ISNUMERIC(CHAR(9) + CHAR(9));      -- multiple tabs
GO
SELECT ISNUMERIC(CHAR(10) + CHAR(10));    -- multiple newlines
GO

-- Space + special whitespace combinations
SELECT ISNUMERIC(' ' + CHAR(9));          -- space + tab
GO
SELECT ISNUMERIC(CHAR(9) + ' ');          -- tab + space
GO
SELECT ISNUMERIC(' ' + CHAR(10));         -- space + newline
GO
SELECT ISNUMERIC(CHAR(10) + ' ');         -- newline + space
GO
SELECT ISNUMERIC(' ' + CHAR(13));         -- space + carriage return
GO
SELECT ISNUMERIC(CHAR(13) + ' ');         -- carriage return + space
GO
SELECT ISNUMERIC(' ' + CHAR(12));         -- space + form feed
GO
SELECT ISNUMERIC(' ' + CHAR(11));         -- space + vertical tab
GO
SELECT ISNUMERIC(' ' + CHAR(8));          -- space + backspace
GO

-- Special whitespace combinations (no space)
SELECT ISNUMERIC(CHAR(9) + CHAR(10));     -- tab + newline
GO
SELECT ISNUMERIC(CHAR(9) + CHAR(13));     -- tab + carriage return
GO
SELECT ISNUMERIC(CHAR(10) + CHAR(13));    -- newline + carriage return
GO
SELECT ISNUMERIC(CHAR(13) + CHAR(10));    -- carriage return + newline (CRLF)
GO
SELECT ISNUMERIC(CHAR(9) + CHAR(11));     -- tab + vertical tab
GO
SELECT ISNUMERIC(CHAR(9) + CHAR(12));     -- tab + form feed
GO
SELECT ISNUMERIC(CHAR(9) + CHAR(8));      -- tab + backspace
GO
SELECT ISNUMERIC(CHAR(10) + CHAR(11));    -- newline + vertical tab
GO
SELECT ISNUMERIC(CHAR(11) + CHAR(12));    -- vertical tab + form feed
GO
SELECT ISNUMERIC(CHAR(8) + CHAR(9));      -- backspace + tab
GO

-- Three character combinations with space
SELECT ISNUMERIC(' ' + CHAR(9) + CHAR(10));     -- space + tab + newline
GO
SELECT ISNUMERIC(CHAR(9) + ' ' + CHAR(10));     -- tab + space + newline
GO
SELECT ISNUMERIC(CHAR(9) + CHAR(10) + ' ');     -- tab + newline + space
GO
SELECT ISNUMERIC(' ' + CHAR(13) + CHAR(10));    -- space + CRLF
GO
SELECT ISNUMERIC(' ' + CHAR(9) + CHAR(13));     -- space + tab + CR
GO

-- Three character combinations without space
SELECT ISNUMERIC(CHAR(9) + CHAR(10) + CHAR(13));     -- tab + newline + CR
GO
SELECT ISNUMERIC(CHAR(8) + CHAR(9) + CHAR(10));      -- backspace + tab + newline
GO
SELECT ISNUMERIC(CHAR(11) + CHAR(12) + CHAR(13));    -- VT + FF + CR
GO
SELECT ISNUMERIC(CHAR(9) + CHAR(11) + CHAR(12));     -- tab + VT + FF
GO

-- All special whitespace characters (no space)
SELECT ISNUMERIC(CHAR(8) + CHAR(9) + CHAR(10) + CHAR(11) + CHAR(12) + CHAR(13));
GO

-- All special whitespace with space at start
SELECT ISNUMERIC(' ' + CHAR(8) + CHAR(9) + CHAR(10) + CHAR(11) + CHAR(12) + CHAR(13));
GO

-- All special whitespace with space in middle
SELECT ISNUMERIC(CHAR(8) + CHAR(9) + ' ' + CHAR(10) + CHAR(11) + CHAR(12) + CHAR(13));
GO

-- All special whitespace with space at end
SELECT ISNUMERIC(CHAR(8) + CHAR(9) + CHAR(10) + CHAR(11) + CHAR(12) + CHAR(13) + ' ');
GO

-- Whitespace + numeric
SELECT ISNUMERIC(' 123');                 -- space + number
GO
SELECT ISNUMERIC(CHAR(9) + '123');        -- tab + number
GO
SELECT ISNUMERIC(CHAR(10) + '123');       -- newline + number
GO
SELECT ISNUMERIC('123 ');                 -- number + space
GO
SELECT ISNUMERIC('123' + CHAR(9));        -- number + tab, tsql 0, trailing whitespaces not allowed
GO
SELECT ISNUMERIC(char(9) + '123')         -- tab + number, tsql:1, leading whitespace is allowed
go 
SELECT ISNUMERIC(' ' + CHAR(9) + '123');  -- space + tab + number
GO
SELECT ISNUMERIC(CHAR(9) + CHAR(10) + '123');  -- tab + newline + number
GO

-- Whitespace around numeric
SELECT ISNUMERIC(' 123 ');                -- space + number + space
GO
SELECT ISNUMERIC(CHAR(9) + '123' + CHAR(9));  -- tab + number + tab
GO
SELECT ISNUMERIC(CHAR(9) + '123' + CHAR(9)+ '123');
go
SELECT ISNUMERIC(' ' + CHAR(9) + '123' + CHAR(10) + ' ');  -- mixed whitespace around number
GO

-- Complex combinations
SELECT ISNUMERIC('  ' + CHAR(9) + '  ');  -- spaces + tab + spaces
GO
SELECT ISNUMERIC(CHAR(9) + CHAR(9) + ' ' + ' ');  -- tabs + spaces
GO
SELECT ISNUMERIC(CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10));  -- double CRLF
GO

-- These are working already.
-- Non breaking space
select isnumeric(CHAR(160)) -- TSQL: 1
go

-- misc tests
select isnumeric('- 1')  -- TSQL: 1
GO
select isnumeric(' -1 ') -- TSQL: 1
GO
select isnumeric('-\n1') -- TSQL: 0
GO
select isnumeric('-1\n') -- TSQL: 0
GO


-- non-breaking space
select isnumeric(char(160))
select isnumeric(nchar(160))
go

-- zero width space
select isnumeric(char(8203))
select isnumeric(nchar(8203))
go

-- narrow no-break space
select isnumeric(char(8239))
select isnumeric(nchar(8239))
go

-- ideographic space
select isnumeric(char(12288))
select isnumeric(nchar(12288))
select isnumeric(char(12288) + char(9))
Go

SELECT ISNUMERIC('\0') -- tsql 1
go


-- Unicode whitespace test cases

-- Non-breaking space (U+00A0) - should behave like regular space
SELECT ISNUMERIC(NCHAR(160));  -- non-breaking space alone
GO
SELECT ISNUMERIC(NCHAR(160) + '123');  -- non-breaking space + number
GO
SELECT ISNUMERIC('123' + NCHAR(160));  -- number + non-breaking space
GO
SELECT ISNUMERIC(NCHAR(160) + NCHAR(160));  -- multiple non-breaking spaces
GO

-- Test casting numeric strings with special whitespace to numeric
SELECT ISNUMERIC(CAST(CHAR(8) AS NUMERIC));
GO
SELECT ISNUMERIC(CAST(CHAR(9) AS NUMERIC(18,5)));  -- tab
GO
SELECT ISNUMERIC(CAST(CHAR(10) AS NUMERIC));  -- newline
GO
SELECT ISNUMERIC(CAST(CHAR(11) AS NUMERIC)); -- vertical tab
GO
SELECT ISNUMERIC(CAST(CHAR(12) AS NUMERIC));  -- form feed
GO
SELECT ISNUMERIC(CAST(CHAR(13) AS NUMERIC));  -- carriage return
GO
SELECT ISNUMERIC(CAST(CHAR(9) + CHAR(10) AS NUMERIC));  -- tab + newline
GO
SELECT ISNUMERIC(CAST(CHAR(13) + CHAR(10) AS NUMERIC));  -- CRLF
GO
SELECT ISNUMERIC(CAST(CHAR(9) + CHAR(13) AS NUMERIC));  -- tab + CR
GO
SELECT ISNUMERIC(CAST((CHAR(9) + cast('123' as numeric)) AS NUMERIC(18,5)));
GO
SELECT ISNUMERIC(CAST((CHAR(10) + cast('123' as numeric)) AS NUMERIC(18,5)));
GO
SELECT ISNUMERIC(CAST((CHAR(11) + cast('123' as numeric)) AS NUMERIC(18,5)));
GO
SELECT ISNUMERIC(CAST((CHAR(12) + cast('123' as numeric)) AS NUMERIC(18,5)));
GO
SELECT ISNUMERIC(CAST((CHAR(13) + cast('123' as numeric)) AS NUMERIC(18,5)));
GO
SELECT ISNUMERIC(CAST((CAST('123' as numeric) + CHAR(9)) AS NUMERIC(18,5)));
GO
SELECT ISNUMERIC(CAST((CAST('123' as numeric) + CHAR(10)) AS NUMERIC(18,5)));
GO
SELECT ISNUMERIC(CAST((CAST('123' as numeric) + CHAR(11)) AS NUMERIC(18,5)));
GO
SELECT ISNUMERIC(CAST((CAST('123' as numeric) + CHAR(12)) AS NUMERIC(18,5)));
GO
SELECT ISNUMERIC(CAST((CAST('123' as numeric) + CHAR(13)) AS NUMERIC(18,5)));
GO
SELECT ISNUMERIC(CAST((123 + CHAR(9)) AS NUMERIC(18,5)));  -- tab
GO
SELECT ISNUMERIC(CAST((123 + CHAR(10)) AS NUMERIC(18,5)));  -- tab
GO
SELECT ISNUMERIC(CAST((123 + CHAR(11)) AS NUMERIC(18,5)));  -- tab
GO
SELECT ISNUMERIC(CAST((123 + CHAR(12)) AS NUMERIC(18,5)));  -- tab
GO
SELECT ISNUMERIC(CAST((123 + CHAR(13)) AS NUMERIC(18,5)));  -- tab
GO
SELECT ISNUMERIC(CAST('123  ' as numeric)) -- numeric + tab
Go
SELECT ISNUMERIC(CAST(' 123' as numeric)) -- tab +numeric
Go