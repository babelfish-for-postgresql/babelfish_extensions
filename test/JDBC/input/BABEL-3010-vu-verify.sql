SELECT
       CASE WHEN xtype LIKE 'TT'
            THEN substring(name, 4, 26)
            ELSE name
       END,
       xtype,
       CASE WHEN crdate IS NOT NULL
            THEN 'Valid create date!'
            ELSE 'Create date found NULL!'
       END,
       CASE WHEN refdate IS NOT NULL
            THEN 'Valid ref date!'
            ELSE 'ref date found NULL!'
       END
FROM sys.sysobjects
       WHERE name LIKE '%%babel_3010_vu_prepare%%' ORDER BY name;
GO
