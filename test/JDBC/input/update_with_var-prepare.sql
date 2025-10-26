CREATE TABLE test_int (id INT, val INT);
INSERT INTO test_int VALUES (1, 10), (2, 20), (3, 30);
GO


CREATE TABLE test_str (id INT, name VARCHAR(50));
INSERT INTO test_str VALUES (1, 'A'), (2, 'B'), (3, 'C');
GO


CREATE TABLE test_multi (id INT, val INT, name VARCHAR(20));
INSERT INTO test_multi VALUES (1, 100, 'First'), (2, 200, 'Second'), (3, 300, 'Third');
GO


CREATE TABLE test_where (id INT, val INT, status VARCHAR(10));
INSERT INTO test_where VALUES (1, 10, 'active'), (2, 20, 'inactive'), (3, 30, 'active'), (4, 40, 'inactive');
GO


CREATE TABLE test_null (id INT, val INT, name VARCHAR(20));
INSERT INTO test_null VALUES (1, 10, 'A'), (2, NULL, 'B'), (3, 30, NULL), (4, 40, 'D');
GO


CREATE TABLE test_empty (id INT, val INT);
GO


CREATE TABLE test_single (id INT, val INT);
INSERT INTO test_single VALUES (1, 50);
GO


CREATE TABLE test_numeric (
    id INT, 
    int_val INT, 
    decimal_val DECIMAL(10,2), 
    float_val FLOAT,
    bigint_val BIGINT
);
INSERT INTO test_numeric VALUES 
    (1, 10, 10.5, 10.25, 1000000000),
    (2, 20, 20.5, 20.25, 2000000000);
GO


CREATE TABLE test_math (id INT, val INT);
INSERT INTO test_math VALUES (1, 2), (2, 3), (3, 4);
GO


CREATE TABLE test_col_assign (id INT, val INT, running_total INT);
INSERT INTO test_col_assign VALUES (1, 10, 0), (2, 20, 0), (3, 30, 0);
GO


CREATE TABLE test_main (id INT, val INT);
CREATE TABLE test_lookup (id INT, multiplier INT);
INSERT INTO test_main VALUES (1, 10), (2, 20), (3, 30);
INSERT INTO test_lookup VALUES (1, 2), (2, 3), (3, 4);
GO


CREATE TABLE test_large (id INT, val INT);
GO


CREATE TABLE test_str_complex (id INT, prefix VARCHAR(10), suffix VARCHAR(10));
INSERT INTO test_str_complex VALUES (1, 'A', 'X'), (2, 'B', 'Y'), (3, 'C', 'Z');
GO


CREATE TABLE test_case (id INT, val INT, category VARCHAR(10));
INSERT INTO test_case VALUES (1, 10, 'A'), (2, 20, 'B'), (3, 30, 'A'), (4, 40, 'B');
GO


CREATE TABLE test_counter (id INT, val INT);
INSERT INTO test_counter VALUES (1, 100), (2, 200), (3, 300);
GO


CREATE TABLE test_init (id INT, val INT);
INSERT INTO test_init VALUES (1, 5), (2, 10), (3, 15);
GO


CREATE TABLE test_self (id INT, val INT);
INSERT INTO test_self VALUES (1, 10), (2, 20), (3, 30);
GO


CREATE TABLE test_datetime (id INT, days_to_add INT);
INSERT INTO test_datetime VALUES (1, 1), (2, 2), (3, 3);
GO


CREATE TABLE test_tran (id INT, val INT);
INSERT INTO test_tran VALUES (1, 10), (2, 20);
GO


CREATE TABLE test_top (id INT, val INT);
INSERT INTO test_top VALUES (1, 10), (2, 20), (3, 30), (4, 40);
GO


CREATE TABLE test_convert (id INT, int_val INT, str_val VARCHAR(20));
INSERT INTO test_convert VALUES (1, 100, '50'), (2, 200, '75');
GO

CREATE TABLE test_nested (id INT, val INT);
GO

CREATE TABLE test_other (id INT);
GO

INSERT INTO test_nested VALUES (1, 10), (2, 20);
GO

INSERT INTO test_other VALUES (1), (1), (2);
GO

CREATE TABLE test_dynamic (val INT);
INSERT INTO test_dynamic VALUES (5), (15), (25);
GO

CREATE TABLE test_mixed_types (val INT, int_col INT, nvarchar_col NVARCHAR(10), float_col FLOAT);
INSERT INTO test_mixed_types VALUES (1, 10, N'A', 1.5), (2, 20, N'B', 2.5);
GO

CREATE TABLE test_coalesce (val INT, nullable_col VARCHAR(50));
INSERT INTO test_coalesce VALUES (1, NULL), (2, 'First'), (3, 'Second');
GO

CREATE TABLE test_output (val INT);
INSERT INTO test_output VALUES (10), (20);
GO

CREATE TABLE test_running_max (val INT);
INSERT INTO test_running_max VALUES (5), (15), (10), (25), (20);
GO

CREATE TABLE test_cross_db (val INT);
INSERT INTO test_cross_db VALUES (10), (20);
GO

CREATE TABLE test_target (id INT, val INT);
GO
CREATE TABLE test_source (id INT, val INT);
GO
INSERT INTO test_target VALUES (1, 100);
GO
INSERT INTO test_source VALUES (1, 200), (2, 300);
GO

CREATE FUNCTION dbo.custom_function(@val INT) RETURNS INT
AS BEGIN
    RETURN @val * 2;
END;
GO

CREATE TABLE test_udf (val INT);
INSERT INTO test_udf VALUES (5), (10);
GO

CREATE TABLE test_concurrent (val INT);
INSERT INTO test_concurrent VALUES (1), (2), (3), (4), (5);
GO

CREATE TABLE test_overflow (val TINYINT);
INSERT INTO test_overflow VALUES (1), (2), (3);
GO

CREATE TABLE test_unicode (name VARCHAR(10), unicode_col NVARCHAR(10));
INSERT INTO test_unicode VALUES ('A', N'α'), ('B', N'β');
GO

CREATE TABLE test_computed (base_val INT, computed_col AS (base_val * 2));
INSERT INTO test_computed (base_val) VALUES (10), (20);
GO

CREATE TABLE test_recursive (id INT, val INT, parent_id INT, processed BIT DEFAULT 0);
INSERT INTO test_recursive VALUES (1, 10, NULL, 0), (2, 20, 1, 0), (3, 30, 1, 0);
GO

CREATE TABLE test_division (val INT);
INSERT INTO test_division VALUES (0), (2), (4);
GO

CREATE TABLE test_truncation (name VARCHAR(20));
INSERT INTO test_truncation VALUES ('VeryLongName1'), ('VeryLongName2');
GO

CREATE TABLE test_identity (id INT IDENTITY(1,1), name VARCHAR(10));
INSERT INTO test_identity (name) VALUES ('A'), ('B');
GO

CREATE TABLE test_large_string (val INT);
INSERT INTO test_large_string VALUES (1), (2);
GO

CREATE TABLE test_complex_expr (val INT);
INSERT INTO test_complex_expr VALUES (2), (3), (4);
GO
