SELECT * FROM dbo.order_summary
GO

--preparing dependent weak views
EXEC sp_babelfish_configure 'babelfishpg_tsql.weak_view_binding', 'on';
GO

CREATE VIEW dbo.order_discount_summary AS
SELECT 
    order_id,
    total_amount,
    dbo.calculate_discount(total_amount) AS discount_amount
FROM 
    orders
GO

CREATE VIEW dbo.order_final_price AS
SELECT 
    order_id,
    total_amount,
    total_amount - dbo.calculate_discount(total_amount) AS final_price
FROM 
    orders
GO

CREATE VIEW dbo.order_pricing_details AS
SELECT 
    order_id,
    total_amount,
    dbo.calculate_base_price(total_amount) AS base_price,
    dbo.calculate_tax(total_amount) AS tax_amount,
    dbo.calculate_final_price(total_amount) AS final_price
FROM 
    orders
GO

CREATE VIEW dbo.order_regional_summary AS
SELECT 
    o.order_id,
    o.total_amount,
    'NY' as region_code,
    dbo.calculate_regional_tax(o.total_amount, 'NY') AS tax_amount
FROM 
    orders o
GO

CREATE VIEW dbo.category_analytics AS
SELECT 
    category,
    COUNT(*) as order_count,
    SUM(total_amount) as total_sales,
    dbo.get_category_average(category) as category_average
FROM 
    orders
GROUP BY 
    category
ORDER BY 
    category
GO

CREATE VIEW dbo.order_details_extended AS
SELECT 
    order_id,
    dbo.generate_order_code(order_id, category) as order_code,
    total_amount,
    customer_type,
    CASE customer_type 
        WHEN 'Premium' THEN 45  -- exceed 40% after change
        ELSE 10 
    END as discount_percent,
    dbo.calculate_safe_discount(
        total_amount, 
        CASE customer_type 
            WHEN 'Premium' THEN 45  -- exceed 40% after change
            ELSE 10 
        END
    ) as safe_discount
FROM 
    orders
GO

-- Create views using TVFs
CREATE VIEW dbo.high_value_orders AS
SELECT * FROM dbo.get_orders_by_amount(500)
GO

CREATE VIEW dbo.category_summaries AS
SELECT * FROM dbo.get_order_summary('Electronics')
UNION ALL
SELECT * FROM dbo.get_order_summary('Books')
UNION ALL
SELECT * FROM dbo.get_order_summary('Furniture')
GO

-- Alter the function to change body [ERROR: dependent strong view exists]
ALTER FUNCTION dbo.calculate_tax
(
    @amount DECIMAL(18,2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    RETURN @amount * 0.15;
END;
GO

-- Alter view to weak binding
ALTER VIEW dbo.order_summary AS
SELECT 
    order_id,
    total_amount,
    dbo.calculate_tax(total_amount) AS tax_amount,
    total_amount + dbo.calculate_tax(total_amount) AS total_with_tax
FROM 
    orders;
GO

SELECT * FROM dbo.order_summary;
GO

-- Now the function can be altered successfully
ALTER FUNCTION dbo.calculate_tax
(
    @amount DECIMAL(18,2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    RETURN @amount * 0.15;
END;
GO

SELECT * FROM dbo.order_summary;
GO

------------------------------------------------------------------------------
-- Multiple Views Depending on Same Function
------------------------------------------------------------------------------

SELECT * FROM dbo.order_discount_summary
GO
SELECT * FROM dbo.order_final_price
GO

-- Alter function to change body
ALTER FUNCTION dbo.calculate_discount(@amount DECIMAL(18,2))
RETURNS DECIMAL(18,2)
AS
BEGIN
    RETURN @amount * 0.10;
END
GO

SELECT * FROM dbo.order_discount_summary 
GO
SELECT * FROM dbo.order_final_price      
GO

------------------------------------------------------------------------------
-- Nested Function calls in 'order_pricing_details' view
------------------------------------------------------------------------------

SELECT * FROM dbo.order_pricing_details
GO

-- Alter base function
ALTER FUNCTION dbo.calculate_base_price(@amount DECIMAL(18,2))
RETURNS DECIMAL(18,2)
AS
BEGIN
    RETURN @amount * 1.3;
END
GO

SELECT * FROM dbo.order_pricing_details
GO

------------------------------------------------------------------------------
-- Function with Multiple Parameters
------------------------------------------------------------------------------

SELECT * FROM dbo.order_regional_summary
GO

ALTER FUNCTION dbo.calculate_regional_tax(
    @amount DECIMAL(18,2),
    @region_code VARCHAR(2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    RETURN CASE 
        WHEN @region_code = 'NY' THEN @amount * 0.085
        WHEN @region_code = 'CA' THEN @amount * 0.095
        ELSE @amount * 0.06
    END
END
GO

SELECT * FROM dbo.order_regional_summary 
GO

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Test category analytics
SELECT * FROM dbo.category_analytics ORDER BY category
GO

-- Alter aggregate function
ALTER FUNCTION dbo.get_category_average(@category VARCHAR(20))
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @avg_amount DECIMAL(18,2)
    SELECT @avg_amount = AVG(total_amount * 1.1) -- Add 10% to average
    FROM orders
    WHERE category = @category
    RETURN ISNULL(@avg_amount, 0)
END
GO

SELECT * FROM dbo.category_analytics ORDER BY category -- Should show higher averages
GO

-- Test order details with safe discount
SELECT * FROM dbo.order_details_extended
GO

-- Alter safe discount function
ALTER FUNCTION dbo.calculate_safe_discount(
    @amount DECIMAL(18,2),
    @discount_percent DECIMAL(5,2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    BEGIN TRY
        IF @discount_percent > 40  -- Changed from 50 to 40
            THROW 50000, 'Discount cannot exceed 40%', 1
        RETURN @amount * (@discount_percent / 100)
    END TRY
    BEGIN CATCH
        RETURN @amount * 0.05  -- Changed from 0 to 5% default discount
    END CATCH
END
GO

SELECT * FROM dbo.order_details_extended -- Should show different discount calculations
GO

-- Test string manipulation function
ALTER FUNCTION dbo.generate_order_code(
    @order_id INT,
    @category VARCHAR(20)
)
RETURNS VARCHAR(50)
AS
BEGIN
    RETURN UPPER(LEFT(@category, 3)) + '-' + 
           FORMAT(@order_id, 'D5') + '-' +  -- Changed format
           FORMAT(GETDATE(), 'yy')
END
GO

SELECT * FROM dbo.order_details_extended -- Should show new order code format
GO

------------------------------------------------------------------------------
------------------------------------------------------------------------------

-- Test Inline TVF
SELECT * FROM dbo.high_value_orders
GO

-- Alter Inline TVF
ALTER FUNCTION dbo.get_orders_by_amount(@min_amount DECIMAL(18,2))
RETURNS TABLE
AS
RETURN
(
    SELECT 
        order_id,
        total_amount,
        customer_type,
        category,
        CASE 
            WHEN total_amount >= 1000 THEN 'Very High'
            WHEN total_amount >= 500 THEN 'High'
            ELSE 'Medium'
        END as value_category -- Added new column
    FROM 
        orders
    WHERE 
        total_amount >= @min_amount
)
GO

SELECT * FROM dbo.high_value_orders
GO
SELECT * FROM dbo.high_value_orders -- Should now include value_category
GO

-- Test Multi-Statement TVF
SELECT * FROM dbo.category_summaries
GO

-- Alter Multi-Statement TVF
ALTER FUNCTION dbo.get_order_summary(@category VARCHAR(20))
RETURNS @result TABLE 
(
    category VARCHAR(20),
    total_orders INT,
    total_amount DECIMAL(18,2),
    avg_amount DECIMAL(18,2),
    max_amount DECIMAL(18,2) -- Added new column
)
AS
BEGIN
    INSERT INTO @result
    SELECT 
        category,
        COUNT(*) as total_orders,
        SUM(total_amount) as total_amount,
        AVG(total_amount) as avg_amount,
        MAX(total_amount) as max_amount -- Added new column
    FROM 
        orders
    WHERE 
        category = @category
    GROUP BY 
        category

    RETURN
END
GO

SELECT * FROM dbo.category_summaries
GO
SELECT * FROM dbo.category_summaries -- Should now include max_amount
GO
