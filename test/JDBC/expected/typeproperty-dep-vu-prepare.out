CREATE SCHEMA typeproperty_test1_dep_vu
GO

CREATE TYPE typeproperty_test1_dep_vu.null_check1_dep_vu FROM varchar(11) NOT NULL ;
GO

CREATE VIEW typeproperty_vu_prepare_dep_view AS
SELECT TYPEPROPERTY('typeproperty_test1_dep_vu.null_check1_dep_vu', 'scale')
GO

CREATE PROC typeproperty_vu_prepare_dep_proc AS
SELECT TYPEPROPERTY('typeproperty_test1_dep_vu.null_check1_dep_vu', 'allowsnull')
GO

CREATE FUNCTION typeproperty_vu_prepare_dep_func()
RETURNS INT
AS
BEGIN
RETURN TYPEPROPERTY('typeproperty_test1_dep_vu.null_check1_dep_vu', 'precision')
END
GO
