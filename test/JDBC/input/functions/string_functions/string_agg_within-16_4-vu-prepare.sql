CREATE TABLE string_agg_t (id int, a varchar(10), b varchar(10), g int, sbid int)
go

INSERT INTO string_agg_t values 
(3,'c','x',1,4), 
(2,'b','y',2,6), 
(2,'g','u',2,5), 
(1,'a','z',1,7), 
(5,'e','v',2,1), 
(4,'d','w',1,3), 
(4,'h','t',1,2),
(NULL,NULL,'s',2,NULL)
go

CREATE TABLE string_agg_t2 (id int, a varchar(10), g1 int, g2 int)
go

INSERT INTO string_agg_t2 values 
(1,'b',2,1),
(2,'g',2,1),
(3,'e',2,1),
(1,'a',1,2),
(2,'c',1,2),
(3,'d',1,2),
(4,'h',1,2),
(1,'d',3,1),
(2,'h',3,1)
go

CREATE TABLE string_agg_multibyte_t (id int, a nvarchar(10), g int, sbid int)
go
INSERT INTO string_agg_multibyte_t VALUES 
(3,N'😎',1,4),
(2,N'莫',2,6),
(2,N'😇',2,5),
(1,N'尔',1,7),
(5,N'莫',2,1)
GO

CREATE TABLE string_agg_chinese_prc_ci_as(id int, a VARCHAR(50) COLLATE CHINESE_PRC_CI_AS, g int, sbid int)
GO
INSERT INTO string_agg_chinese_prc_ci_as VALUES
(1,N'莫',1,5),
(2,N'尔',2,4),
(2,N'拉',2,3),
(3,N'比',1,2),
(5,N'斯',2,1)
GO

CREATE VIEW string_agg_dep_v1 AS
    SELECT STRING_AGG (a, '-') as result FROM string_agg_t
GO

CREATE PROCEDURE string_agg_dep_p1 AS
    SELECT STRING_AGG (a, '-') FROM string_agg_t
GO

CREATE FUNCTION string_agg_dep_f1()
RETURNS NVARCHAR(50)
AS
BEGIN
RETURN (SELECT STRING_AGG (a, '-') FROM string_agg_t)
END
GO

CREATE VIEW string_agg_dep_v2 AS
    SELECT STRING_AGG (a, '-') as result FROM string_agg_t GROUP BY g
GO

CREATE PROCEDURE string_agg_dep_p2 AS
    SELECT STRING_AGG (a, '-') FROM string_agg_t GROUP BY g
GO

CREATE FUNCTION string_agg_dep_f2()
RETURNS TABLE
AS
RETURN (SELECT STRING_AGG (a, '-') as result FROM string_agg_t GROUP BY g)
GO

CREATE VIEW string_agg_dep_v3 AS
    SELECT STRING_AGG (a, '-') WITHIN GROUP (ORDER BY sbid) as result FROM string_agg_t GROUP BY g
GO

CREATE PROCEDURE string_agg_dep_p3 AS
    SELECT STRING_AGG (a, '-') WITHIN GROUP (ORDER BY sbid) FROM string_agg_t GROUP BY g
GO

CREATE FUNCTION string_agg_dep_f3()
RETURNS TABLE
AS
RETURN (SELECT STRING_AGG (a, '-') WITHIN GROUP (ORDER BY sbid) as result FROM string_agg_t GROUP BY g)
GO

-- Create a table to test the trigger
CREATE TABLE string_agg_school_details (
    classID INT,
    rollID INT,
    studentName VARCHAR(50)
);
GO

INSERT INTO string_agg_school_details (classID, rollID, studentName)
VALUES
    (1, 2, 'StudentB'),
    (1, 1, 'StudentA'),
    (1, 3, 'StudentC'),
    (2, 2, 'StudentE'),
    (2, 1, 'StudentD')
GO

-- Create a trigger to display classID, list of student names seperated by ', '
CREATE TRIGGER string_agg_tr_concat_student_names
ON string_agg_school_details
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SELECT classID, STRING_AGG(studentName, ', ') 
    WITHIN GROUP (ORDER BY rollID) 
    FROM string_agg_school_details 
    GROUP BY classID
    ORDER BY classID;
END;
GO