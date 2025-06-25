CREATE TABLE test_openxml_table(oid char(5), date datetime, amount float);
GO

CREATE TABLE test_openxml_table_2(oid char(5), Date datetime, amount float);
GO

CREATE TABLE very_long_table_name_that_exceeds_sixty_four_characters_limit_test (
    id INT,
    name VARCHAR(50),
    value INT
);
GO

CREATE TABLE test_long_columns (
    very_long_column_name_that_definitely_exceeds_sixty_four_characters_limit_test INT,
    another_extremely_long_column_name_exceeding_standard_limits_for_testing VARCHAR(50),
    short_col INT
);
GO

CREATE TABLE mixed_length_names (
    id INT,
    extremely_long_column_name_that_exceeds_the_standard_sixty_four_character_limit_for_identifiers VARCHAR(200),
    short VARCHAR(50)
);
GO

CREATE TABLE employee_defaults (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    department VARCHAR(20) DEFAULT 'Unknown',
    salary DECIMAL(10,2) DEFAULT 0.00,
    hire_date DATETIME DEFAULT GETDATE(),
    status VARCHAR(10) DEFAULT 'Active',
    CHECK (salary >= 0)
);
GO

CREATE TABLE person_table (
    id INT,
    name VARCHAR(50),
    age INT
);
GO

CREATE TABLE regions (region_id INT, region_name VARCHAR(50));
GO
