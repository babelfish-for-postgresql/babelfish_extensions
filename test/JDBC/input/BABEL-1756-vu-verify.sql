-- sla 40000
SELECT colid, name, collation_100 FROM sys.spt_tablecollations_view WHERE object_id = sys.object_id('babel_1756_vu_prepare_t1') ORDER BY colid
GO

exec sp_tablecollations_100 'babel_1756_vu_prepare_t1'
GO

exec ..sp_tablecollations_100 'babel_1756_vu_prepare_t1'
GO
