-- Customer case
CREATE TABLE [dbo].[babel_5031_MemberValues](
    [Id] [uniqueidentifier] NOT NULL,
    [PanelId] [uniqueidentifier] NOT NULL,
    [EndEffectiveDate] [datetime2](7) NOT NULL
);
GO

CREATE NONCLUSTERED INDEX [babel_5031_IDX_MBRVAL_SHARED_LATEST_FILT] ON [dbo].[babel_5031_MemberValues] ([PanelId] ASC)
WHERE ([EndEffectiveDate]=CONVERT([datetime2](7),'9999-12-31 23:59:59.9999999'));
GO

DROP TABLE babel_5031_MemberValues
GO

-- Using convert function for converting from string to date/datetime/datetime2/datetimeoffset/smalldatetime/time 
-- in computed column of table
CREATE TABLE babel_5031_t1(col_string VARCHAR(100),
                        col_date AS CONVERT(date, col_string),
                        col_datetime AS CONVERT(datetime, col_string),
                        col_datetime2 AS CONVERT(datetime2, col_string),
                        col_dateoffset AS CONVERT(datetimeoffset, col_string),
                        col_smalldatetime AS CONVERT(smalldatetime, col_string),
                        col_time AS CONVERT(time, col_string));
GO

INSERT INTO babel_5031_t1 VALUES('2026-12-31 23:59:59.99');
GO

INSERT INTO babel_5031_t1 VALUES('11.12.2024');
GO

INSERT INTO babel_5031_t1 VALUES('2022-10-30T03:00:00.123');
GO

INSERT INTO babel_5031_t1 VALUES('20240129 03:00:00');
GO

SELECT * FROM babel_5031_t1
GO

DROP TABLE babel_5031_t1
GO

-- Using convert function for converting from string to date/datetime/datetime2/datetimeoffset/smalldatetime/time 
-- in check constraint of table
CREATE TABLE babel_5031_t2(col_string VARCHAR(100),
                        CHECK (CONVERT(date, col_string) > CONVERT(date, '03-05-2023')),
                        CHECK (CONVERT(datetime, col_string) > CONVERT(datetime, '03-05-2023')),
                        CHECK (CONVERT(datetime2, col_string) > CONVERT(datetime2, '03-05-2023')),
                        CHECK (CONVERT(datetimeoffset, col_string) > CONVERT(datetimeoffset, '03-05-2023')),
                        CHECK (CONVERT(smalldatetime, col_string) > CONVERT(smalldatetime, '03-05-2023')),
                        CHECK (CONVERT(time, col_string) > CONVERT(time, '03-05-2023')));
GO

INSERT INTO babel_5031_t2 VALUES('2026-12-31 23:59:59.99');
GO

INSERT INTO babel_5031_t2 VALUES('11.12.2024');
GO

INSERT INTO babel_5031_t2 VALUES('2022-10-30T03:00:00.123');
GO

INSERT INTO babel_5031_t2 VALUES('20240129 03:00:00');
GO

SELECT * FROM babel_5031_t2
GO

DROP TABLE babel_5031_t2
GO