CREATE SCHEMA isc_schemata_vu_prepare_sch;
GO

CREATE VIEW isc_schemata_vu_prepare_view AS
SELECT * FROM information_schema.schemata WHERE schema_name = 'isc_schemata_vu_prepare_sch'
GO

CREATE PROC isc_schemata_vu_prepare_proc AS
SELECT count(*) from information_schema.schemata WHERE schema_name = 'isc_schemata_vu_prepare_sch'
GO

CREATE FUNCTION isc_schemata_vu_prepare_func()
RETURNS INT
AS
BEGIN
RETURN (SELECT count(*) FROM information_schema.schemata WHERE schema_name = 'isc_schemata_vu_prepare_sch')
END
GO
