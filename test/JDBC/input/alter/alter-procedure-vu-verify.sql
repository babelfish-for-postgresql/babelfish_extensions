exec alter_proc_p1
go

ALTER PROCEDURE alter_proc_p1
AS
    select * from alter_proc_orders
GO

exec alter_proc_p1
go

exec alter_proc_p2
go

ALTER PROCEDURE alter_proc_p1
    @param INT
AS
    IF (@param = 1)
    BEGIN
        select * from alter_proc_users
    END

    ELSE
    BEGIN
        select * from alter_proc_orders
    END
GO

exec alter_proc_p1 @param = 1
GO

exec alter_proc_p1 @param = 2
GO

-- expect error for no param provided
exec alter_proc_p2
go

ALTER PROCEDURE alter_proc_p1
    @param date
AS
    IF (@param = '2020-01-01')
    BEGIN
        select * from alter_proc_users
    END

    ELSE
    BEGIN
        select * from alter_proc_orders
    END
GO

exec alter_proc_p1 @param = '2020-01-01'
GO

exec alter_proc_p1 @param = '2020-01-02'
GO

alter procedure alter_proc_p2
AS
    exec alter_proc_p1 @param = '2020-01-01'
GO

exec alter_proc_p2
go

