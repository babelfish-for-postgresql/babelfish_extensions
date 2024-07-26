USE pivot_test;
GO

DROP VIEW PIVOT_VIEW2
GO

DROP VIEW PIVOT_VIEW3
GO

DROP VIEW PIVOT_VIEW4
GO

DROP VIEW TOP_PIVOT
GO

DROP VIEW DISTINCT_PIVOT
GO

DROP VIEW UNION_PIVOT
GO

DROP VIEW SUBQUERY_PIVOT
GO

DROP VIEW PIVOT_FUNCTION
GO

DROP VIEW CTE_VIEW1
GO

DROP VIEW CTE_VIEW2
GO

DROP VIEW CTE_VIEW3
GO

DROP VIEW JOIN_PIVOT1
GO

DROP VIEW JOIN_PIVOT2
GO

DROP VIEW JOIN_PIVOT3
GO

DROP VIEW JOIN_PIVOT4
GO

DROP VIEW JOIN_PIVOT5
GO

DROP VIEW JOIN_PIVOT6
GO

DROP VIEW JOIN_PIVOT7
GO

DROP VIEW JOIN_PIVOT8
GO

DROP TRIGGER pivot_trigger
GO

DROP TABLE trigger_testing
GO

DROP TABLE OSTable;
GO

DROP TABLE STable;
GO

DROP TABLE seating_tbl;
GO

DROP VIEW StoreReceipt_view;
GO

DROP TABLE pivot_insert_into;
GO

DROP TABLE pivot_select_into;
GO

DROP PROCEDURE top_n_pivot;
GO

DROP FUNCTION test_table_valued_function;
GO

DROP TABLE FruitSalesTable
GO

DROP TABLE StoreReceipt;
GO

DROP TABLE orders;
GO

DROP TABLE products;
GO

DROP TABLE pivot_schema.products_sch;
GO

DROP SCHEMA pivot_schema;
GO

USE master;
GO

DROP DATABASE pivot_test;
GO

--- Check for inconsistent metadata
SELECT COUNT(*) FROM sys.babelfish_inconsistent_metadata()
GO