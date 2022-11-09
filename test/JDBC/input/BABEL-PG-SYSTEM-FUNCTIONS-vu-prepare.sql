-- For DMS, we've suggested the following PG functions related to identity
-- feature that can be called from TDS endpoint and they should get the exact
-- same behaviour as PG endpoint.  So, let's add some tests.
-- basic sequence operations for setval, nextval, currentval (tests are taken
-- src/test/regress/sql/sequence.sql PG regression test suite)
CREATE SEQUENCE BABEL_PG_SYSTEM_FUNCTIONS_vu_prepare_seq1;
go

SELECT nextval('BABEL_PG_SYSTEM_FUNCTIONS_vu_prepare_seq1');
go
SELECT currval('BABEL_PG_SYSTEM_FUNCTIONS_vu_prepare_seq1');
go
SELECT setval('BABEL_PG_SYSTEM_FUNCTIONS_vu_prepare_seq1', 32);
go
SELECT nextval('BABEL_PG_SYSTEM_FUNCTIONS_vu_prepare_seq1');
go
SELECT setval('BABEL_PG_SYSTEM_FUNCTIONS_vu_prepare_seq1', 99, false);
go
SELECT nextval('BABEL_PG_SYSTEM_FUNCTIONS_vu_prepare_seq1');
go
SELECT setval('BABEL_PG_SYSTEM_FUNCTIONS_vu_prepare_seq1', 32);
go
SELECT nextval('BABEL_PG_SYSTEM_FUNCTIONS_vu_prepare_seq1');
go
SELECT setval('BABEL_PG_SYSTEM_FUNCTIONS_vu_prepare_seq1', 99, false);
go
SELECT nextval('BABEL_PG_SYSTEM_FUNCTIONS_vu_prepare_seq1');
go
