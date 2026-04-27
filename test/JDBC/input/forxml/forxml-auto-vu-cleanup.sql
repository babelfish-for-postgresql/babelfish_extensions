-- Drop functions
DROP FUNCTION IF EXISTS dbo.GetXmlCustomerOrders;
GO
DROP FUNCTION IF EXISTS dbo.GetXmlSingleCustomerOrders;
GO

-- Drop procedures
DROP PROCEDURE IF EXISTS dbo.GetXmlAutoResult;
GO

-- Drop views (order matters: nested view first)
DROP VIEW IF EXISTS forxmlauto_v_order_summary;
GO
DROP VIEW IF EXISTS forxmlauto_v_customer_orders;
GO

-- Drop tables
DROP TABLE IF EXISTS forxmlauto_t_order_details;
GO
DROP TABLE IF EXISTS forxmlauto_t_orders;
GO
DROP TABLE IF EXISTS forxmlauto_t_products;
GO
DROP TABLE IF EXISTS forxmlauto_t_customers;
GO
DROP TABLE IF EXISTS forxmlauto_t_categories;
GO
DROP TABLE IF EXISTS forxmlauto_t_multibyte;
GO
DROP TABLE IF EXISTS forxmlauto_t_longnames;
GO
DROP TABLE IF EXISTS [forxmlauto_t_comma,table];
GO
DROP TABLE IF EXISTS [forxmlauto_t_dot.table];
GO
DROP TABLE IF EXISTS forxmlauto_t_comma_cols;
GO
DROP TABLE IF EXISTS forxmlauto_t_dot_cols;
GO
DROP TABLE IF EXISTS forxmlauto_t_space_cols;
GO
DROP TABLE IF EXISTS [forxmlauto_t_mixed,special.table];
GO
DROP TABLE IF EXISTS [_x002E_tbl];
GO
