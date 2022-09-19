SELECT DISTINCT
       name,
       xtype,
       CASE WHEN crdate IS NOT NULL
            THEN 'Valid create date!'
            ELSE 'Invalid create date!'
       END
FROM sys.sysobjects
       WHERE name LIKE 'babel_3010_vu_prepare%%' ORDER BY name;
GO
