-- Drop views
DROP VIEW sales.sales_analysis_view;
GO

DROP VIEW sales.quarterly_view;
GO

-- Drop tables
DROP TABLE customer_quarterly_sales;
GO
DROP TABLE customer_turnover;
GO
DROP TABLE customer_turnover_2024;
GO
DROP TABLE customer_info;
GO
DROP TABLE product_info;
GO
DROP TABLE sales_data;
GO
DROP TABLE revenue_data;
GO
DROP TABLE product_sales;
GO
DROP TABLE product_performance;
GO
DROP TABLE customer_history;
GO
DROP TABLE numeric_types;
GO
DROP TABLE string_types;
GO
DROP TABLE datetime_types;
GO
DROP TABLE mixed_types;
GO
DROP TABLE sales.quarterly_data;
GO
DROP TABLE SalesHierarchy;
GO
DROP TABLE cte_product_sales;
GO
DROP TABLE cte_product_revenue;
GO
DROP TABLE empty_table;
GO
DROP TABLE very_long_table_name_12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567;
GO
DROP TABLE [Sales$Data@2024];
GO
DROP TABLE [Global_データ_Sales];
GO

-- Drop temporary tables (if they still exist)
IF OBJECT_ID('tempdb..#temp_sales') IS NOT NULL
    DROP TABLE #temp_sales;
GO
IF OBJECT_ID('tempdb..#new_quarterly_sales') IS NOT NULL
    DROP TABLE #new_quarterly_sales;
GO

-- Drop functions
DROP FUNCTION IF EXISTS dbo.fn_UnpivotSales;
GO
DROP FUNCTION IF EXISTS dbo.GetSalesData;
GO
DROP PROCEDURE IF EXISTS dbo.GetQuarterlyTotal;
GO

-- Drop user-defined types

-- Drop schema
DROP SCHEMA sales;
GO
