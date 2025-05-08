-- Create the table
CREATE TABLE binary_datatype_operators_test_table (
    col1 BINARY(3),
    col2 BINARY(3)
);
GO

-- Insert data for testing
INSERT INTO binary_datatype_operators_test_table (col1, col2) VALUES
    (0x121212, 0x121212), -- col1 = col2
    (0x111111, 0x121212), -- col1 < col2
    (0x121212, 0x111111); -- col1 > col2
GO

-- Inside Views
CREATE VIEW binary_datatype_operators_less_than_view
AS
    SELECT col1, col2, 'col1 < col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 < col2;
GO

CREATE VIEW binary_datatype_operators_less_than_equal_view
AS
    SELECT col1, col2, 'col1 <= col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 <= col2;
GO


CREATE VIEW binary_datatype_operators_greater_than_view
AS
    SELECT col1, col2, 'col1 > col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 > col2;
GO

CREATE VIEW binary_datatype_operators_greater_than_equal_view
AS
    SELECT col1, col2, 'col1 >= col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 >= col2;
GO

CREATE VIEW binary_datatype_operators_equal_view
AS
    SELECT col1, col2, 'col1 = col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 = col2;
GO

CREATE VIEW binary_datatype_operators_not_equal_view
AS
    SELECT col1, col2, 'col1 <> col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 <> col2;
GO

-- Inside Procedure
CREATE PROC binary_datatype_operators_less_than_proc
AS
    SELECT col1, col2, 'col1 < col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 < col2;
GO

CREATE PROC binary_datatype_operators_less_than_equal_proc
AS
    SELECT col1, col2, 'col1 <= col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 <= col2;
GO


CREATE PROC binary_datatype_operators_greater_than_proc
AS
    SELECT col1, col2, 'col1 > col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 > col2;
GO

CREATE PROC binary_datatype_operators_greater_than_equal_proc
AS
    SELECT col1, col2, 'col1 >= col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 >= col2;
GO

CREATE PROC binary_datatype_operators_equal_proc
AS
    SELECT col1, col2, 'col1 = col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 = col2;
GO

CREATE PROC binary_datatype_operators_not_equal_proc
AS
    SELECT col1, col2, 'col1 <> col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 <> col2;
GO

-- Inside Function
CREATE FUNCTION binary_datatype_operators_less_than_func()
RETURNS TABLE AS
RETURN(
    SELECT col1, col2, 'col1 < col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 < col2
);
GO

CREATE FUNCTION binary_datatype_operators_less_than_equal_func()
RETURNS TABLE AS
RETURN(
    SELECT col1, col2, 'col1 <= col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 <= col2
);
GO


CREATE FUNCTION binary_datatype_operators_greater_than_func()
RETURNS TABLE AS
RETURN(
    SELECT col1, col2, 'col1 > col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 > col2
);
GO

CREATE FUNCTION binary_datatype_operators_greater_than_equal_func()
RETURNS TABLE AS
RETURN(
    SELECT col1, col2, 'col1 >= col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 >= col2
);
GO

CREATE FUNCTION binary_datatype_operators_equal_func()
RETURNS TABLE AS
RETURN(
    SELECT col1, col2, 'col1 = col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 = col2
);
GO

CREATE FUNCTION binary_datatype_operators_not_equal_func()
RETURNS TABLE AS
RETURN(
    SELECT col1, col2, 'col1 <> col2 ' AS [Comparison]
    FROM binary_datatype_operators_test_table
    WHERE col1 <> col2
);
GO


