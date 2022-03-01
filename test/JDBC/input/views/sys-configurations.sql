SELECT * FROM sys.configurations;
GO

SELECT * FROM sys.syscurconfigs;
GO

SELECT * FROM sys.sysconfigures;
GO

SELECT * FROM sys.babelfish_configurations;
GO

INSERT INTO sys.babelfish_configurations
     VALUES (1234,
             'testing',
             1,
             0,
             0,
             1,
             'asdf',
             sys.bitin('1'),
             sys.bitin('0'),
             'testing',
             'testing'
             );
GO
