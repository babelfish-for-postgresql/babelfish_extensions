-- Drop recursive CTE + trigger test objects
DROP TRIGGER IF EXISTS forxmlauto_trg_rcte_base_only;
GO
DROP TRIGGER IF EXISTS forxmlauto_trg_rcte_ins_only;
GO
DROP TRIGGER IF EXISTS forxmlauto_trg_rcte_base_first;
GO
DROP TRIGGER IF EXISTS forxmlauto_trg_rcte_ins_first;
GO
DROP TABLE IF EXISTS forxmlauto_t_rcte_result;
GO
DROP TABLE IF EXISTS forxmlauto_t_rcte_base;
GO
DROP TABLE IF EXISTS forxmlauto_t_rcte;
GO

-- Drop triggers and trigger test tables
DROP TRIGGER IF EXISTS forxmlauto_trg_insert;
GO
DROP TRIGGER IF EXISTS forxmlauto_trg_delete;
GO
DROP TRIGGER IF EXISTS forxmlauto_trg_insert_subset;
GO
DROP TRIGGER IF EXISTS forxmlauto_trg_insert_join;
GO
DROP TRIGGER IF EXISTS forxmlauto_trg_update_both;
GO
DROP TRIGGER IF EXISTS forxmlauto_trg_update_join;
GO
DROP TRIGGER IF EXISTS forxmlauto_trg_insert_null;
GO
DROP TRIGGER IF EXISTS forxmlauto_trg_delete_join;
GO
DROP TABLE IF EXISTS forxmlauto_t_trigger_xml_result;
GO
DROP TABLE IF EXISTS forxmlauto_t_trigger_test;
GO

-- Drop functions
DROP FUNCTION IF EXISTS dbo.GetXmlCustomerOrders;
GO
DROP FUNCTION IF EXISTS dbo.GetXmlSingleCustomerOrders;
GO
DROP FUNCTION IF EXISTS dbo.GetXmlAutoScalar;
GO

-- Drop procedures
DROP PROCEDURE IF EXISTS dbo.GetXmlAutoResult;
GO
DROP PROCEDURE IF EXISTS dbo.GetXmlAutoJoin;
GO
DROP PROCEDURE IF EXISTS dbo.GetXmlAutoElements;
GO

-- Drop views (order matters: nested view first)
DROP VIEW IF EXISTS forxmlauto_v_order_summary;
GO
DROP VIEW IF EXISTS forxmlauto_v_customer_orders;
GO
DROP VIEW IF EXISTS forxmlauto_v_xml_type;
GO
DROP VIEW IF EXISTS forxmlauto_v_xml_text;
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
DROP TABLE IF EXISTS forxmlauto_t_x002E_col;
GO
DROP TABLE IF EXISTS forxmlauto_t_ci_parent;
GO
DROP TABLE IF EXISTS forxmlauto_t_ci_child;
GO
