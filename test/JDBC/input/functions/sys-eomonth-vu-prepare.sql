CREATE TABLE EOMONTH_DatesTable (
    Id INT PRIMARY KEY,
    DateValue DATE NOT NULL
);
GO

INSERT INTO EOMONTH_DatesTable (Id, DateValue)
VALUES (1, '1996-01-24'),
       (2, '2000-06-15'),
       (3, '2022-04-30');
GO

CREATE PROCEDURE GetEndOfMonthDate_EOMONTH
    @Id INT
AS
BEGIN
    SELECT EOMONTH(DateValue) AS EndOfMonth
    FROM EOMONTH_DatesTable
    WHERE Id = @Id;
END;
GO

CREATE VIEW EOMONTH_EndOfMonthView AS
    SELECT Id, DateValue, EOMONTH(DateValue) AS EndOfMonth
    FROM EOMONTH_DatesTable
GO

CREATE VIEW EOMONTH_EndOfNextMonthView AS
     SELECT Id, DateValue, EOMONTH(DateValue, 1) AS EndOfNextMonth
     FROM EOMONTH_DatesTable
GO

CREATE PROCEDURE GetEndOfNextMonthDate_EOMONTH
     @Id INT
 AS
 BEGIN
     SELECT EOMONTH(DateValue, 1) AS EndOfNextMonth
     FROM EOMONTH_DatesTable
     WHERE Id = @Id;
 END;
GO
