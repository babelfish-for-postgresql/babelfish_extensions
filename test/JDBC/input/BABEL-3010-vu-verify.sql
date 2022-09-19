SELECT DISTINCT
       CASE WHEN xtype LIKE 'TT'
            THEN substring(name, 4, 26)
            ELSE name
       END,
       xtype,
       CASE WHEN crdate IS NOT NULL
            THEN 'Valid create date!'
            ELSE 'Invalid create date!'
       END,
       CASE WHEN refdate IS NOT NULL
            THEN 'Valid create date!'
            ELSE 'Invalid create date!'
       END
FROM sys.sysobjects
       WHERE name LIKE '%%babel_3010_vu_prepare%%' ORDER BY name;
GO
