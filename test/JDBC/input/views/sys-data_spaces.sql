SELECT * FROM sys.data_spaces;
GO

-- test case-sementics of column type. 
SELECT type FROM sys.data_spaces where type='FG';
GO

SELECT type FROM sys.data_spaces where type='fg';
GO
