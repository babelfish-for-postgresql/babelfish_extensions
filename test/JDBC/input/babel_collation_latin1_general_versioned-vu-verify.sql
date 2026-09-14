-- the upgrade script must register the versioned Latin1_General collations
SELECT name FROM fn_helpcollations() WHERE name LIKE 'latin1[_]general[_]90[_]%' OR name LIKE 'latin1[_]general[_]100[_]%' OR name LIKE 'latin1[_]general[_]140[_]%' ORDER BY name;
GO

-- and the versioned names are usable against pre-existing data
SELECT id FROM babel_coll_ver_vu_prepare_t WHERE val COLLATE Latin1_General_100_CI_AS = 'apfel' ORDER BY id;
GO
SELECT id FROM babel_coll_ver_vu_prepare_t WHERE val COLLATE Latin1_General_100_CS_AS = 'apfel' ORDER BY id;
GO
SELECT id FROM babel_coll_ver_vu_prepare_t WHERE val COLLATE Latin1_General_140_CI_AI = 'apfel' ORDER BY id;
GO
SELECT CAST(COLLATIONPROPERTY('Latin1_General_100_CI_AS', 'CodePage') AS INT) AS codepage;
GO
