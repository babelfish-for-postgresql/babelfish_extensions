-- BASIC TESTS

-- [] wildcard single character to match or not match
select patindex('%[A-Z]%', 'a' COLLATE Latin1_General_CI_AI)
select patindex('%[A-Z]%', 'b' COLLATE Latin1_General_CI_AI)
select patindex('%[A-Z]%', 'z' COLLATE Latin1_General_CI_AI)
select patindex('[^A-Z]', 'z' COLLATE Latin1_General_CI_AI)
select patindex('[^A-Z]', 'A' COLLATE Latin1_General_CI_AI)
select patindex('[^A-Z]', 'b' COLLATE Latin1_General_CI_AI)
GO

-- _ wildcard one single character to match
select patindex('_', 'b' COLLATE Latin1_General_CI_AI)
select patindex('%[A-Z]_[^A-Y]%', 'aBz' COLLATE Latin1_General_CI_AI)
select patindex('%aZď_[^A-Y]%', 'hqyazdjz' COLLATE Latin1_General_CI_AI)
GO

-- _ wildcard one single character to match
select patindex('_', 'b' COLLATE Latin1_General_CI_AI)
select patindex('%[A-Z]_[^A-Y]%', 'aBz' COLLATE Latin1_General_CI_AI)
select patindex('%aZď_[^A-Y]%', 'hqyazdjz' COLLATE Latin1_General_CI_AI)
GO

-- Basic Accent Insensitivity
DECLARE @testString NVARCHAR(100) = 'Café jalapeño';
SELECT PATINDEX('%café%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 1
SELECT PATINDEX('%jalapeno%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 6
GO

-- Mixed Case and Accent Sensitivity
DECLARE @testString NVARCHAR(100) = 'Résumé';
SELECT PATINDEX('%résumé%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 1
SELECT PATINDEX('%RESUME%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 1
GO

-- not found
DECLARE @testString NVARCHAR(100) = 'Example string';
SELECT PATINDEX('%notfound%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 0
GO

-- pattern with special character
DECLARE @testString NVARCHAR(100) = 'Price: $100.00';
SELECT PATINDEX('%$100%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 8
SELECT PATINDEX('%100.00%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 9
GO

-- multiple occurrence
DECLARE @testString NVARCHAR(100) = 'Pattern with pattern and another pattern';
SELECT PATINDEX('%pattern%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 1
GO
DECLARE @testString NVARCHAR(100) = 'patterPattern with pattern and another pattern';
SELECT PATINDEX('%pattern%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 7
GO

-- empty null string
DECLARE @testString NVARCHAR(100) = '';
DECLARE @nullString NVARCHAR(100) = NULL;
SELECT PATINDEX('%anything%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 0
SELECT PATINDEX('%anything%', @nullString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: NULL
GO

-- multiple wild cards
DECLARE @testString NVARCHAR(100) = 'Pattern matching with _ and % wildcards';
-- `%` matches any sequence of characters
SELECT PATINDEX('%with %wildcards%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 18
-- `_` matches exactly one character
SELECT PATINDEX('%with _ and %wildcards%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 18
GO


-- Wildcard Combination in Patterns
DECLARE @testString NVARCHAR(100) = 'Example of pattern matching with special cases';
-- `%` and `_` used together
SELECT PATINDEX('%pattern%_with%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 11

-- Single `_` used in the middle
SELECT PATINDEX('%pattern _matching%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 11
GO

-- consecutive wildcards
DECLARE @testString NVARCHAR(100) = 'Data with multiple %% wildcards';
-- Multiple `%` wildcards
SELECT PATINDEX('%multiple % wildcards%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 9
GO

-- Leading and Trailing Wildcards
DECLARE @testString NVARCHAR(100) = 'Example string for testing patterns';
-- Wildcards at both ends
SELECT PATINDEX('%string for%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 9
-- Wildcard in the middle
SELECT PATINDEX('%string%for%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 9
GO

-- Complex Pattern with Special Characters
DECLARE @testString NVARCHAR(100) = 'Price: $100.00 and $200.00';
-- Pattern with special characters and wildcards
SELECT PATINDEX('%$100.00%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 8
SELECT PATINDEX('%$%.00%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 8 (matches $100.00)
GO

-- Wildcards with Mixed Case
DECLARE @testString NVARCHAR(100) = 'Case Insensitive Pattern Matching';
-- Case-insensitive wildcard match
SELECT PATINDEX('%pattern matching%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 19
GO

-- Long String with Wildcard
DECLARE @testString NVARCHAR(MAX) = REPLICATE('Long text with many characters to test the pattern matching functionality. ', 10);
-- Long string with wildcard pattern
SELECT PATINDEX('%test %the% pattern%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: Position in the long text
GO

-- Overlapping Patterns
DECLARE @testString NVARCHAR(100) = '123123123';
-- Pattern where `%123%` is overlapping
SELECT PATINDEX('%123123%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 1
GO

-- Escaping Wildcards
DECLARE @testString NVARCHAR(100) = 'Special characters: % and _';
-- Escaping `%` and `_` using a pattern that should match literally
SELECT PATINDEX('%[%]%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 19 (matching `%`)
SELECT PATINDEX('%[_]%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 30 (matching `_`)
GO

-- Wildcard with Special Characters
DECLARE @testString NVARCHAR(100) = 'File name: data_*.txt';
-- Wildcard with special characters
SELECT PATINDEX('%data_%.txt%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 11
GO

-- Patterns with Trailing Wildcard and Special Characters
DECLARE @testString NVARCHAR(100) = 'Number: 12345-6789 and 98765-4321';
SELECT PATINDEX('%12345-%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 10
GO


-- Multiple wildcards and special characters
DECLARE @testString NVARCHAR(100) = '123-456_789*012';
SELECT PATINDEX('%-456_789*%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 4
GO

-- Case and accent insensitivity with complex pattern
DECLARE @testString NVARCHAR(100) = 'Accénted words: café, résumé, jalapeño';
SELECT PATINDEX('%café%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 18
SELECT PATINDEX('%resume%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 25
GO

DECLARE @testString NVARCHAR(100) = 'Null and empty string patterns';

-- Null pattern
DECLARE @nullPattern NVARCHAR(100) = NULL;
SELECT PATINDEX(@nullPattern, @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 0
-- Empty pattern
DECLARE @emptyPattern NVARCHAR(100) = '';
SELECT PATINDEX(@emptyPattern, @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 1
GO

-- Nested wildcards
DECLARE @testString NVARCHAR(100) = 'Pattern example: a1b2c3d4e5';
SELECT PATINDEX('%a1%b2%c3%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 1 (matches "a1b2c3")
SELECT PATINDEX('%a1_b2%c3_%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 1 (matches "a1b2c3")
GO

-- Long pattern with multiple wildcards
DECLARE @testString NVARCHAR(100) = REPLICATE('X', 50) + 'Y' + REPLICATE('X', 50) + 'Z' + REPLICATE('X', 50);
SELECT PATINDEX('%X%Y%Z%', @testString COLLATE Latin1_General_CI_AI) AS Position; -- Expected: 51 (matches "Y" and "Z")
GO


-- Pattern with digit ranges
DECLARE @testString NVARCHAR(100) = 'Order numbers: 123, 456, 789';
SELECT PATINDEX('%[1-3][0-9][0-9]%', @testString COLLATE Latin1_General_CI_AI)  -- Expected: Match Found
GO


-- Pattern with letter ranges
DECLARE @testString NVARCHAR(100) = 'Alphabet sequence: ABC, DEF, GHI';
SELECT PATINDEX('%[A-C][A-C][A-C]%', @testString COLLATE Latin1_General_CI_AI) 
GO

-- Pattern with alphanumeric ranges
DECLARE @testString NVARCHAR(100) = 'Code ranges: A1B2, C3D4, E5F6';
SELECT PATINDEX('%[A-C][1-4][A-C][1-4]%', @testString COLLATE Latin1_General_CI_AI) 
GO

-- Pattern with special characters and ranges
DECLARE @testString NVARCHAR(100) = 'Special chars: !@#, $%^, &*()';
SELECT PATINDEX('%[!@#][$%^&][*()]%', @testString COLLATE Latin1_General_CI_AI)
GO












