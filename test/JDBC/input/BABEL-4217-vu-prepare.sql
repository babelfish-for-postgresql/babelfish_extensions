-- Used PRIMARY KEY & Placed NOT NULL before Identity Column
CREATE TABLE BABEL_4217_vu_prepare_t1 (
    ID INT PRIMARY KEY NOT NULL IDENTITY(1,1),
    FIRSTNAME VARCHAR(50)
);
GO

INSERT INTO BABEL_4217_vu_prepare_t1 (FIRSTNAME)
VALUES ('John'),
       ('Jane'), 
       ('Jim');
GO

-- Used PRIMARY KEY & Placed NOT NULL after Identity Column
CREATE TABLE BABEL_4217_vu_prepare_t2 (
    ID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    FIRSTNAME VARCHAR(50)
);
GO

INSERT INTO BABEL_4217_vu_prepare_t2 (FIRSTNAME)
VALUES ('John'),
       ('Jane'), 
       ('Jim');
GO

-- Used PRIMARY KEY & Placed NOT NULL before PRIMARY KEY
CREATE TABLE BABEL_4217_vu_prepare_t3 (
    ID INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    FIRSTNAME VARCHAR(50)
);
GO

INSERT INTO BABEL_4217_vu_prepare_t3 (FIRSTNAME)
VALUES ('John'),
       ('Jane'), 
       ('Jim');
GO

-- Used PRIMARY KEY & Created Table first and then use alter table(in BABEL-4217-vu-verify.sql) and placed not null after identity column
CREATE TABLE BABEL_4217_vu_prepare_t4 (
    FIRSTNAME VARCHAR(50)
);
GO

INSERT INTO BABEL_4217_vu_prepare_t4 (FIRSTNAME)
VALUES ('John'),
       ('Jane'), 
       ('Jim');
GO


-- Used PRIMARY KEY & Created Table first and then use alter table(in BABEL-4217-vu-verify.sql) and placed not null before identity column
CREATE TABLE BABEL_4217_vu_prepare_t5 (
    FIRSTNAME VARCHAR(50)
);
GO

INSERT INTO BABEL_4217_vu_prepare_t5 (FIRSTNAME)
VALUES ('John'),
       ('Jane'), 
       ('Jim');
GO

-- Used PRIMARY KEY & Created Table first and then use alter table(in BABEL-4217-vu-verify.sql) and placed not null before primary key
CREATE TABLE BABEL_4217_vu_prepare_t6 (
    FIRSTNAME VARCHAR(50)
);
GO

INSERT INTO BABEL_4217_vu_prepare_t6 (FIRSTNAME)
VALUES ('John'),
       ('Jane'), 
       ('Jim');
GO

-- Used UNIQUE & Placed NOT NULL before Identity Column
CREATE TABLE BABEL_4217_vu_prepare_t7 (
    ID INT UNIQUE NOT NULL IDENTITY(1,1),
    FIRSTNAME VARCHAR(50)
);
GO

INSERT INTO BABEL_4217_vu_prepare_t7 (FIRSTNAME)
VALUES ('John'),
       ('Jane'), 
       ('Jim');
GO

-- Used UNIQUE & Placed NOT NULL after Identity Column
CREATE TABLE BABEL_4217_vu_prepare_t8 (
    ID INT UNIQUE IDENTITY(1,1) NOT NULL,
    FIRSTNAME VARCHAR(50)
);
GO

INSERT INTO BABEL_4217_vu_prepare_t8 (FIRSTNAME)
VALUES ('John'),
       ('Jane'), 
       ('Jim');
GO

-- Used UNIQUE & Placed NOT NULL before PRIMARY KEY
CREATE TABLE BABEL_4217_vu_prepare_t9 (
    ID INT NOT NULL UNIQUE IDENTITY(1,1),
    FIRSTNAME VARCHAR(50)
);
GO

INSERT INTO BABEL_4217_vu_prepare_t9 (FIRSTNAME)
VALUES ('John'),
       ('Jane'), 
       ('Jim');
GO

-- Used UNIQUE & Created Table first and then use alter table(in BABEL-4217-vu-verify.sql) and placed not null after identity column
CREATE TABLE BABEL_4217_vu_prepare_t10 (
    FIRSTNAME VARCHAR(50)
);
GO

INSERT INTO BABEL_4217_vu_prepare_t10 (FIRSTNAME)
VALUES ('John'),
       ('Jane'), 
       ('Jim');
GO


-- Used UNIQUE & Created Table first and then use alter table(in BABEL-4217-vu-verify.sql) and placed not null before identity column
CREATE TABLE BABEL_4217_vu_prepare_t11 (
    FIRSTNAME VARCHAR(50)
);
GO

INSERT INTO BABEL_4217_vu_prepare_t11 (FIRSTNAME)
VALUES ('John'),
       ('Jane'), 
       ('Jim');
GO

-- Used UNIQUE & Created Table first and then use alter table(in BABEL-4217-vu-verify.sql) and placed not null before UNIQUE Constraint
CREATE TABLE BABEL_4217_vu_prepare_t12 (
    FIRSTNAME VARCHAR(50)
);
GO

INSERT INTO BABEL_4217_vu_prepare_t12 (FIRSTNAME)
VALUES ('John'),
       ('Jane'), 
       ('Jim');
GO