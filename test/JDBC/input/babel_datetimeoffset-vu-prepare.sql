-- Create a test table with different data types
CREATE TABLE DateTestTable (
    ID INT IDENTITY(1,1),
    DateTimeCol DATETIME,
    TextCol VARCHAR(50),
    SysVarcharCol sys.varchar(50)
);
GO
-- Insert test data
INSERT INTO DateTestTable (DateTimeCol, TextCol, SysVarcharCol)
VALUES 
    ('2023-10-15 14:30:00', '2023-10-15', '2023-10-15'),
    ('2023-12-25 00:00:00', 'not a date', '2023/12/25'),
    (NULL, '2023-13-45', NULL),
    ('2023-01-01 10:20:30', '01/01/2023', '2023.01.01');
GO

-- Create view to test ISDATE with different types
CREATE VIEW DateTypeTestDetailedView AS
SELECT 
    ID,
    -- DateTime type tests
    DateTimeCol,
    ISDATE(DateTimeCol) AS IsValidDateTime,
    
    -- Text/varchar type tests
    TextCol,
    ISDATE(TextCol) AS IsValidText,
    
    -- sys.varchar type tests
    SysVarcharCol,
    ISDATE(SysVarcharCol) AS IsValidSysVarchar,
    
    -- Additional conversion tests
    CASE 
        WHEN ISDATE(DateTimeCol) = 1 THEN CONVERT(DATE, DateTimeCol)
        ELSE NULL
    END AS ConvertedDateTime,
    
    CASE 
        WHEN ISDATE(TextCol) = 1 THEN CONVERT(DATE, TextCol)
        ELSE NULL
    END AS ConvertedText,
    
    CASE 
        WHEN ISDATE(SysVarcharCol) = 1 THEN CONVERT(DATE, SysVarcharCol)
        ELSE NULL
    END AS ConvertedSysVarchar,
    ISDATE(cast('2023-10-15' as text)) AS IsText
FROM DateTestTable;
GO
