use master;
go

create database key_column_usage_vu_prepare_db;
go

use key_column_usage_vu_prepare_db;
go

create table key_column_usage_vu_prepare_tb1(redID INT PRIMARY KEY, greenID INT NOT NULL, blueID INT NOT NULL);
go

CREATE TABLE key_column_usage_vu_prepare_tb2( greenID char(10) PRIMARY KEY, redID INT NOT NULL, CONSTRAINT FK_RED FOREIGN KEY (redID) REFERENCES key_column_usage_vu_prepare_tb1 (redID));
go

create table key_column_usage_vu_prepare_tb3(blueID INT PRIMARY KEY, greenID char(10), CONSTRAINT FK_GREEN FOREIGN KEY (greenID) REFERENCES key_column_usage_vu_prepare_tb2(greenID));
go

create table key_column_usage_vu_prepare_tb4(purpleID INT PRIMARY KEY, blueID INT NOT NULL, CONSTRAINT FK_GREEN FOREIGN KEY (blueID) REFERENCES key_column_usage_vu_prepare_tb3(blueID));
go

use master;
go
