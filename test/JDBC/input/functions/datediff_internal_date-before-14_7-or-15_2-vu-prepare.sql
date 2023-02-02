CREATE VIEW datediff_internal_date_vu_before_14_7_or_15_2_prepare_v1 AS
SELECT datediff_internal_date('day', CAST('20201010' AS DATE), CAST('20201001' AS DATE))
GO
