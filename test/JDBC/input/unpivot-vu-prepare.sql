CREATE TABLE customer_turnover (
    customer_id INT,
    customer_desc VARCHAR(50),
    customer_type CHAR(1),
    q1 INT, q2 INT, q3 INT, q4 INT
);
GO
    
INSERT INTO customer_turnover VALUES
    (3, 'Cust C', 'R', NULL, 0, 400, 150),
    (1, 'Cust A', 'R', 100, 200, 100, 400),
    (2, 'Cust B', 'P', 150, 250, 200, NULL);
GO

CREATE TABLE numeric_types (
    id INT,
    -- Bit values
    bit_val1 BIT,
    bit_val2 BIT,
    bit_val3 BIT,
    
    -- Decimal/Numeric values (exact, fixed-precision)
    decimal_val1 DECIMAL(18,2),
    decimal_val2 DECIMAL(18,2),
    numeric_val1 NUMERIC(18,2),
    numeric_val2 NUMERIC(18,2),
    
    -- Float/Real values (approximate)
    float_val1 FLOAT,
    float_val2 FLOAT,
    real_val1 REAL,
    real_val2 REAL,
    
    -- Integer family values
    bigint_val1 BIGINT,
    bigint_val2 BIGINT,
    int_val1 INT,
    int_val2 INT,
    smallint_val1 SMALLINT,
    smallint_val2 SMALLINT,
    tinyint_val1 TINYINT,
    tinyint_val2 TINYINT,
    
    -- Money values
    money_val1 MONEY,
    money_val2 MONEY,
    smallmoney_val1 SMALLMONEY,
    smallmoney_val2 SMALLMONEY
);
GO

INSERT INTO numeric_types VALUES (
    1,                          -- id
    1, 0, 1,                   -- bit
    123456.78, 98765.43,       -- decimal
    987654.32, 456789.01,      -- numeric
    123456.789, 98765.432,     -- float
    987654.321, 456789.012,    -- real
    9223372036854775807, 4611686018427387904,  -- bigint
    2147483647, 1073741824,    -- int
    32767, 16384,              -- smallint
    255, 128,                  -- tinyint
    214748.3647, 107374.1824,  -- money
    214748.3647, 107374.1824   -- smallmoney
);
GO

CREATE TABLE string_types (
    id INT,
    -- CHAR types (fixed-length, non-Unicode)
    char_val1 CHAR(10),
    char_val2 CHAR(10),
    char_val3 CHAR(10),

    -- VARCHAR types (variable-length, non-Unicode)
    varchar_val1 VARCHAR(50),
    varchar_val2 VARCHAR(50),
    varchar_val3 VARCHAR(50),

    -- NCHAR types (fixed-length, Unicode)
    nchar_val1 NCHAR(10),
    nchar_val2 NCHAR(10),
    nchar_val3 NCHAR(10),

    -- NVARCHAR types (variable-length, Unicode)
    nvarchar_val1 NVARCHAR(50),
    nvarchar_val2 NVARCHAR(50),
    nvarchar_val3 NVARCHAR(50),

    -- Text types
    text_val1 TEXT,
    text_val2 TEXT,

    -- NText types (Unicode)
    ntext_val1 NTEXT,
    ntext_val2 NTEXT
);
GO

INSERT INTO string_types VALUES (1,
    'ABC',
    '123',
    '@#$',
    
    'Café',
    'Test_123',
    '   spaces   ',

    N'한글',
    N'日本',
    N'Привет',

    N'Hello世界',
    N'🌟Star⭐',
    N'König',

    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Lorem ipsum Duis aute irure dolor in reprehenderit in voluptate velit esse cillum Lorem ipsum dolore Lorem ipsum eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur? At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, Lorem ipsumomnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem Lorem ipsum quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, Lorem ipsum ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat. Sed ut perspiciatis unde Lorem ipsum omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consecttur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et doloe magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem Lorem ipsum ullam corporis suscipit laboriosam, nisi ut aliquid Lorem ipsum ex ea commoi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur? At vero Lorem eos et accusamus et Lorem ipsum odio dignissimos ducimus quiblanditiis praesentium voluptatum deleniti atque corupi quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero Lorem ipsum tempore, cum soluta nobis est eligendi optio cumque nihil impeit quo minus id quod maxime placeat facere possimus, omnis voluptas assumen dolor repellendus. Temporibus Lorem ipsum autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusadae. Itaque earum rerum hic tenetur a Lorem ipsum sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat.',
    'Special chars: /\@#$%^&*()',

    N'علم',
    N'שלום'
);
GO

CREATE TABLE datetime_types (
    id INT,
    -- Date values
    date_val1 DATE,
    date_val2 DATE,
    
    -- DateTime values
    datetime_val1 DATETIME,
    datetime_val2 DATETIME,
    
    -- DateTime2 values
    datetime2_val1 DATETIME2,
    datetime2_val2 DATETIME2,
    
    -- DateTimeOffset values
    datetimeoffset_val1 DATETIMEOFFSET,
    datetimeoffset_val2 DATETIMEOFFSET,
    
    -- SmallDateTime values
    smalldatetime_val1 SMALLDATETIME,
    smalldatetime_val2 SMALLDATETIME,
    
    -- Time values
    time_val1 TIME,
    time_val2 TIME
);
GO

INSERT INTO datetime_types VALUES (
    1, -- id
    '2023-01-01', '2023-02-01', -- date
    '2023-01-01 12:30:45', '2023-02-01 14:45:30', -- datetime
    '2023-01-01 12:30:45.1234567', '2023-02-01 14:45:30.7654321', -- datetime2
    '2023-01-01 12:30:45.1234567 +01:00', '2023-02-01 14:45:30.7654321 -08:00', -- datetimeoffset
    '2023-01-01 12:30:00', '2023-02-01 14:45:00', -- smalldatetime
    '12:30:45.1234567', '14:45:30.7654321' -- time
);
GO

CREATE TABLE mixed_types (
    id INT,
    val1 INT,
    val2 DECIMAL(10,2),
    val3 MONEY,
    val4 FLOAT
);
GO

CREATE TABLE sales_data (
    product_id INT,
    q1_sales INT,
    q2_sales INT,
    q1_region VARCHAR(50),
    q2_region VARCHAR(50)
);
GO

INSERT INTO sales_data VALUES
    (1, 100, 150, 'North', 'South'),
    (2, 200, 250, 'East', 'West'),
    (3, NULL, 350, 'Central', 'East');
GO

CREATE TABLE product_sales (
    product_id INT,
    product_desc VARCHAR(25),
    quantity_q1 INT, revenue_q1 DECIMAL(10,2),
    quantity_q2 INT, revenue_q2 DECIMAL(10,2)
);
GO

INSERT INTO product_sales VALUES
    (2, 'PQR', 80, 1600.00, 90, 1800.00),
    (3, 'XYZ', 0, 0, NULL, NULL),
    (1, 'ABC', 100, 1000.00, 150, 1500.00);
GO

CREATE TABLE customer_info (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    customer_segment VARCHAR(50)
);
GO

CREATE TABLE product_info (
    product_id INT,
    product_name VARCHAR(50)
);
GO

INSERT INTO customer_info (customer_id, customer_name, customer_segment)
VALUES 
(1, 'John Doe', 'Premium'),
(2, 'Jane Smith', 'Standard'),
(3, 'Bob Johnson', 'Premium');
GO

INSERT INTO product_info VALUES 
    (1, 'Widget'),
    (2, 'Gadget');
GO

CREATE TABLE product_performance (
    product_id INT,
    product_name VARCHAR(50),
    sales_q1 INT,
    sales_q2 INT,
    profit_q1 DECIMAL(10,2),
    profit_q2 DECIMAL(10,2),
    region VARCHAR(20)
);
GO

INSERT INTO product_performance VALUES
    (1, 'Laptop', 100, 150, 1000.00, 1500.00, 'North'),
    (2, 'Desktop', 80, 120, 800.00, 1200.00, 'South'),
    (3, 'Tablet', 200, 250, 2000.00, 2500.00, 'East'),
    (4, 'Phone', NULL, 0, NULL, 0, 'West');
GO

CREATE SCHEMA sales;
GO

CREATE TABLE sales.quarterly_data (
    product_id INT,
    product_name VARCHAR(50),
    q1_sales DECIMAL(10,2),
    q2_sales DECIMAL(10,2),
    q3_sales DECIMAL(10,2),
    q4_sales DECIMAL(10,2)
);
GO

INSERT INTO sales.quarterly_data VALUES
(1, 'Product A', 0.50, 150.75, 200.25, 175.50),
(2, 'Product B', 200.00, 300.00, 0, NULL),
(3, 'Product C', 175.25, 225.75, NULL, 250.00);
GO

CREATE TABLE customer_history (
    customer_id INT, 
    q1 INT,  
    q2 INT,  
    q3 VARCHAR(10), 
    q4 DATE,
    turnover FLOAT,
    time_period VARCHAR(10),
    history_id INT PRIMARY KEY
);
GO

INSERT INTO customer_history (customer_id, q1, q2, q3, q4, turnover, time_period, history_id) VALUES
    (1, 90, 180, 'Q3-A', '2023-01-01', 150.0, 'q2', 1),
    (1, 95, 190, 'Q3-B', '2023-04-01', 150.0, 'q2', 2),
    (2, 140, 110, 'Q3-C', '2023-07-01', 0.0, 'q3', 3),
    (3, 200, 300, 'Q3-D', '2023-10-01', 1000.01, 'q4', 4);
GO

-- FOR DML statements with unpivot
CREATE TABLE customer_quarterly_sales (
    customer_id INT,
    customer_desc VARCHAR(50),
    customer_type CHAR(1),
    quarter VARCHAR(2),
    sales INT
);
GO

-- Create and populate second table for set operations
CREATE TABLE customer_turnover_2024 (
    customer_id INT,
    customer_desc VARCHAR(50),
    customer_type CHAR(1),
    q1 INT, q2 INT, q3 INT, q4 INT
);
GO
INSERT INTO customer_turnover_2024 VALUES
    (3, 'Cust C', 'R', 120, 0, 400, 150),
    (1, 'Cust A', 'R', 100, 200, 100, 400),
    (4, 'Cust D', 'P', 180, 220, 300, NULL);
GO

-- For recursive CTE
CREATE TABLE SalesHierarchy (
    id INT PRIMARY KEY,
    parent_id INT,
    q1 INT,
    q2 INT,
    q3 INT,
    q4 INT
);
GO

INSERT INTO SalesHierarchy (id, parent_id, q1, q2, q3, q4) VALUES
(1, NULL, 100, 200, 300, 400),  -- Root node
(2, 1, 150, 250, 350, 450),     -- Child of 1
(3, 1, 200, 300, 400, 500),     -- Child of 1
(4, 2, 125, 225, 325, 425),     -- Child of 2
(5, 2, 175, 275, 375, 475);     -- Child of 2
GO

-- For multiple CTEs
CREATE TABLE cte_product_sales (
    product_id INT,
    product_name VARCHAR(50),
    q1_quantity INT,
    q2_quantity INT,
    q3_quantity INT,
    q4_quantity INT
);
GO

CREATE TABLE cte_product_revenue (
    product_id INT,
    q1_revenue DECIMAL(10,2),
    q2_revenue DECIMAL(10,2),
    q3_revenue DECIMAL(10,2),
    q4_revenue DECIMAL(10,2)
);
GO

INSERT INTO cte_product_sales VALUES
(1, 'ProductA', 100, 200, 300, 400),
(2, 'ProductB', 150, 250, 350, 450),
(3, 'ProductC', 200, 300, 400, 500);
GO

INSERT INTO cte_product_revenue VALUES
(1, 1000.00, 2000.00, 3000.00, 4000.00),
(2, 1500.00, 2500.00, 3500.00, 4500.00),
(3, 2000.00, 3000.00, 4000.00, 5000.00);
GO

-- Error Scenarios
CREATE TABLE empty_table (
    customer_id INT,
    customer_desc VARCHAR(50),
    customer_type CHAR(1),
    q1 INT, q2 INT, q3 INT, q4 INT
);
GO

CREATE TABLE very_long_table_name_12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567 (
    id INT,
    very_long_column_name_q1_12345678901234567890123456789012345678 INT,
    very_long_column_name_q2_12345678901234567890123456789012345678 INT
);
GO

INSERT INTO very_long_table_name_12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567 
VALUES (1, 10, 20);
GO

CREATE TABLE [Sales$Data@2024] (
    [Customer#ID] INT,
    [q1$sales] DECIMAL(10,2),
    [q2$sales] DECIMAL(10,2),
    [q3$sales] DECIMAL(10,2)
);
GO

INSERT INTO [Sales$Data@2024] VALUES (1,10,20,30);
GO


CREATE TABLE [Global_データ_Sales] (
    [ID_番号] INT,
    [Q1_販売] DECIMAL(10,2),
    [Q2_販売] DECIMAL(10,2),
    [q1_売上] DECIMAL(10,2),
    [q2_売上] DECIMAL(10,2)
);
GO

INSERT INTO [Global_データ_Sales] VALUES (1,2,3,4,5);
GO