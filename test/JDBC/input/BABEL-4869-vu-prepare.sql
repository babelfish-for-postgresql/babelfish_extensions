-- Create sample tables
CREATE TABLE babel_4869_vu_prepare_t1 (
    ID INT,
    Column1 VARCHAR(50),
    Column2 INT
);
GO

CREATE TABLE babel_4869_vu_prepare_t2 (
    Column2 INT,
    Column3 VARCHAR(50)
);
GO

-- Insert data into tables
INSERT INTO babel_4869_vu_prepare_t1 (ID, Column1, Column2) VALUES
(1, 'Value1', 100),
(2, 'Value2', 200),
(3, 'Value3', 300);
GO

INSERT INTO babel_4869_vu_prepare_t2 (Column2, Column3) VALUES
(100, 'SubValue1'),
(200, 'SubValue2'),
(300, 'SubValue3');
GO


CREATE TABLE babel_4869_vu_prepare_t3([tenantId] [int],[bitValue] [bit], [stringValue] NVARCHAR (64),[folder] [nvarchar](64),CONSTRAINT [PK_TenantInstallBuild] PRIMARY KEY CLUSTERED
([tenantId] ASC,[folder] ASC)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]) ON [PRIMARY];
GO

-- Add a row of data 
INSERT INTO babel_4869_vu_prepare_t3 (tenantId, bitValue, stringValue, folder) VALUES(1,0,'initial', 'test'); 
GO
