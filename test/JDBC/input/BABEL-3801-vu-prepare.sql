CREATE TYPE bbf_3801_type from char(25);
GO

CREATE TABLE bbf_3801_tab (col_a bbf_3801_type DEFAULT 'Whoops!' COLLATE japanese_ci_as);
GO

CREATE VIEW bbf_3801_view AS SELECT col_a FROM bbf_3801_tab;
GO

create table bbf_3801_tab1 (a varchar(100), check (a > 'abc'));
GO

create table bbf_3801_tab2 (a bbf_3801_type, check (a > 'abc'));
GO

create table bbf_3801_tab3 (a varchar(100), b as cast('abc' as bbf_3801_type))
GO

create table bbf_3801_tab4 (col_a1 char(100) COLLATE japanese_ci_as, col_b1 as substr(col_a1, 1, 1));
GO

create table bbf_3801_tab5 (col_a2 bbf_3801_type COLLATE japanese_ci_as, col_b2 as substr(col_a2, 1, 1));
GO

create table bbf_3801_tab6 (col_a3 char(100), col_b3 as substr(col_a3, 1, 1));
GO