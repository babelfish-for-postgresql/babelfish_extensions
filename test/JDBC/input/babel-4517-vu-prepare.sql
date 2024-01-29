create table babel_4517 (
    date_col date NULL,
    datetime_col datetime NULL,
    datetime2_col datetime2 NULL
)
GO

create NONCLUSTERED INDEX date_col_indx on babel_4517
(
    date_col ASC
)
GO

create NONCLUSTERED INDEX datetime_col_indx on babel_4517
(
    datetime_col ASC
)
GO

create NONCLUSTERED INDEX datetime2_col_indx on babel_4517
(
    datetime2_col ASC
)
GO

create view view_4517_date as select * from babel_4517 where date_col <= cast('2023-08-31' as date) and date_col >= cast('2023-08-31' as date);
GO

create view view_4517_datetime as select * from babel_4517 where datetime_col <= cast('2023-08-31' as date) and datetime_col >= cast('2023-08-31' as date);
GO

create view view_4517_datetime2 as select * from babel_4517 where datetime2_col <= cast('2023-08-31' as date) and datetime2_col >= cast('2023-08-31' as date);
GO
