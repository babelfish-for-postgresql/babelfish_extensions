SELECT * FROM BABEL_4217_vu_prepare_t1;
GO

SELECT * FROM BABEL_4217_vu_prepare_t2;
GO

SELECT * FROM BABEL_4217_vu_prepare_t3;
GO

SELECT * FROM BABEL_4217_vu_prepare_t4;
GO
ALTER TABLE BABEL_4217_vu_prepare_t4 add id INT PRIMARY KEY IDENTITY(1,1) NOT NULL;
GO
SELECT * FROM BABEL_4217_vu_prepare_t4;
GO

SELECT * FROM BABEL_4217_vu_prepare_t5;
GO
ALTER TABLE BABEL_4217_vu_prepare_t5 add id INT PRIMARY KEY NOT NULL IDENTITY(1,1);
GO
SELECT * FROM BABEL_4217_vu_prepare_t5;
GO

SELECT * FROM BABEL_4217_vu_prepare_t6;
GO
ALTER TABLE BABEL_4217_vu_prepare_t6 add id INT NOT NULL PRIMARY KEY IDENTITY(1,1);
GO
SELECT * FROM BABEL_4217_vu_prepare_t6;
GO

SELECT * FROM BABEL_4217_vu_prepare_t7;
GO

SELECT * FROM BABEL_4217_vu_prepare_t8;
GO

SELECT * FROM BABEL_4217_vu_prepare_t9;
GO

SELECT * FROM BABEL_4217_vu_prepare_t10;
GO
ALTER TABLE BABEL_4217_vu_prepare_t10 add id INT UNIQUE IDENTITY(1,1) NOT NULL;
GO
SELECT * FROM BABEL_4217_vu_prepare_t10;
GO

SELECT * FROM BABEL_4217_vu_prepare_t11;
GO
ALTER TABLE BABEL_4217_vu_prepare_t11 add id INT UNIQUE NOT NULL IDENTITY(1,1);
GO
SELECT * FROM BABEL_4217_vu_prepare_t11;
GO

SELECT * FROM BABEL_4217_vu_prepare_t12;
GO
ALTER TABLE BABEL_4217_vu_prepare_t12 add id INT NOT NULL UNIQUE IDENTITY(1,1);
GO
SELECT * FROM BABEL_4217_vu_prepare_t12;
GO

SELECT * FROM BABEL_4217_vu_prepare_t13;
GO

SELECT * FROM BABEL_4217_vu_prepare_t15;
GO

ALTER TABLE BABEL_4217_vu_prepare_t15 add id INT PRIMARY KEY NOT NULL CHECK(id < 5) IDENTITY(1,1);
GO
SELECT * FROM BABEL_4217_vu_prepare_t15;
GO

SELECT * FROM BABEL_4217_vu_prepare_t16;
GO

-- It should give error (default and idenity cannot be assigned to same column)
ALTER TABLE BABEL_4217_vu_prepare_t16 add id INT PRIMARY KEY NOT NULL DEFAULT 0 IDENTITY(1,1);
GO