CREATE VIEW enr_view AS
    SELECT
        CASE
            WHEN relname LIKE '#pg_toast%' AND relname LIKE '%index%' THEN '#pg_toast_#oid_masked#_index'
            WHEN relname LIKE '#pg_toast%' THEN '#pg_toast_#oid_masked#'
            ELSE relname
        END AS relname
    FROM sys.babelfish_get_enr_list()
GO