CREATE TABLE customer_turnover (
    customer_id INT,
    customer_desc VARCHAR(50),
    customer_type CHAR(1),
    q1 INT, q2 INT, q3 INT, q4 INT
);
GO
    
INSERT INTO customer_turnover VALUES
    (1, 'Cust A', 'R', 100, 200, 300, 400),
    (2, 'Cust B', 'P', 150, 250, 350, 450),
    (3, 'Cust C', 'R', NULL, 0, 400, 500);
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
    quantity_q1 INT, revenue_q1 DECIMAL(10,2),
    quantity_q2 INT, revenue_q2 DECIMAL(10,2)
);
GO

INSERT INTO product_sales VALUES
    (1, 100, 1000.00, 150, 1500.00),
    (2, 80, 1600.00, 90, 1800.00),
    (3, 0, 0, NULL, NULL);
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



CREATE TABLE sales_data1 (
    product_id INT,
    q1_sales INT,
    q2_sales INT,
    q3_sales INT
);
GO
CREATE TABLE inventory_data (
    product_id INT,
    q1_stock INT,
    q2_stock INT,
    q3_stock INT
);
GO

-- Insert sample data
INSERT INTO sales_data1 VALUES 
    (1, 100, 200, 300),
    (2, 150, 250, 350),
    (3, 120, 220, NULL);
GO

INSERT INTO inventory_data VALUES
    (1, 500, 400, 300),
    (2, 600, 500, 400),
    (3, 550, 450, 350);
GO

-- for insert unpivot
CREATE TABLE quarterly_sales
(
    customer_id INT,
    customer_desc VARCHAR(50),
    quarter VARCHAR(2),
    sales_value INT
);
GO