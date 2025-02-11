-- MAX()
EXEC get_column_info_p1 'ResultTable1';
GO

-- MIN()
EXEC get_column_info_p1 'ResultTable2';
GO

-- AVG()
EXEC get_column_info_p1 'ResultTable3';
GO

-- SUM()
EXEC get_column_info_p1 'ResultTable4';
GO

-- COUNT()
EXEC get_column_info_p1 'ResultTable5';
GO

-- Mix of different aggregates (MAX, MIN, AVG, SUM, COUNT)
EXEC get_column_info_p1 'ResultTable6';
GO

-- MAX() with GROUP BY clause
EXEC get_column_info_p1 'ResultTable7';
GO

-- Aggregation with subquery
EXEC get_column_info_p1 'ResultTable8';
GO

-- Aggregation with HAVING clause
EXEC get_column_info_p1 'ResultTable9';
GO

-- Aggregation with calculated MONEY column
EXEC get_column_info_p1 'ResultTable10';
GO

-- Negative Test Case: Empty table
EXEC get_column_info_p1 'ResultTableEmpty';
GO

-- Negative Test Case: Trying to aggregate non-MONEY column as MONEY
EXEC get_column_info_p1 'ResultTableNonMoney';
GO

-- Edge Test Case: Extreme values
EXEC get_column_info_p1 'ResultTableExtreme';
GO

-- Arbitrary Test Case: Mixing NULL and non-NULL values
EXEC get_column_info_p1 'ResultTableMixedNull';
GO

-- Edge Test Case: Aggregating calculated values that exceed MONEY range
EXEC get_column_info_p1 'ResultTableOverflow';
GO

-- Verify Check Constraint Test
EXEC get_column_info_p1 'ResultTableCheck';
GO

-- Verify Complex Dependent Objects Tests
EXEC get_column_info_p1 'ResultTableView';
GO

EXEC get_column_info_p1 'ResultTableFunction';
GO

-- Verify Indexed View Test
EXEC get_column_info_p1 'ResultTableIndexedView';
GO

-- Verify currency symbol test results
EXEC get_column_info_p1 'ResultTableCurrency1'
GO

EXEC get_column_info_p1 'ResultTableCurrency2'
GO

EXEC get_column_info_p1 'ResultTableCurrency3'
GO

EXEC get_column_info_p1 'ResultTableCurrency4'
GO
