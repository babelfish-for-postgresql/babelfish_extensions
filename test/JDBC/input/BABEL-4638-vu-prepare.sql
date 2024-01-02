CREATE TABLE babel_4638_t1(a VARCHAR(10) COLLATE arabic_ci_as);
CREATE TABLE babel_4638_t2(a VARCHAR(10) COLLATE chinese_prc_ci_as);
CREATE TABLE babel_4638_t3(a VARCHAR(10) COLLATE japanese_ci_as);
CREATE TABLE babel_4638_t4(a VARCHAR(10) COLLATE hebrew_ci_as);
CREATE TABLE babel_4638_t5(a VARCHAR(10));
GO

CREATE TABLE babel_4638_char_t1(a CHAR(10) COLLATE arabic_ci_as);
CREATE TABLE babel_4638_char_t2(a CHAR(10) COLLATE chinese_prc_ci_as);
CREATE TABLE babel_4638_char_t3(a CHAR(10) COLLATE japanese_ci_as);
CREATE TABLE babel_4638_char_t4(a CHAR(10) COLLATE hebrew_ci_as);
CREATE TABLE babel_4638_char_t5(a CHAR(10));
GO

CREATE TABLE babel_4638_nchar_t1(a NCHAR(10) COLLATE arabic_ci_as);
CREATE TABLE babel_4638_nchar_t2(a NCHAR(10) COLLATE chinese_prc_ci_as);
CREATE TABLE babel_4638_nchar_t3(a NCHAR(10) COLLATE japanese_ci_as);
CREATE TABLE babel_4638_nchar_t4(a NCHAR(10) COLLATE hebrew_ci_as);
CREATE TABLE babel_4638_nchar_t5(a NCHAR(10));
GO

INSERT INTO babel_4638_t1 VALUES('ح'), ('غ'), ('سسس'), ('للل');
INSERT INTO babel_4638_t2 VALUES('五'), ('九'), ('乙乙乙'), ('魚魚魚');
INSERT INTO babel_4638_t3 VALUES('あ'), ('九'), ('ちちち'), ('さささ');
INSERT INTO babel_4638_t4 VALUES('ב'), ('א'), ('קקק'), ('מממ');
INSERT INTO babel_4638_t5 VALUES('a'), ('🙂'), ('🙂🙂🙂'), ('さささ');
GO
