-- For DMS, we've suggested the following PG functions related to identity
-- feature that can be called from TDS endpoint and they should get the exact
-- same behaviour as PG endpoint.  So, let's add some tests.
-- basic sequence operations for setval, nextval, currentval (tests are taken
-- src/test/regress/sql/sequence.sql PG regression test suite)
CREATE SEQUENCE sequence_test;
go

SELECT nextval('sequence_test');
go
SELECT currval('sequence_test');
go
SELECT setval('sequence_test', 32);
go
SELECT nextval('sequence_test');
go
SELECT setval('sequence_test', 99, false);
go
SELECT nextval('sequence_test');
go
SELECT setval('sequence_test', 32);
go
SELECT nextval('sequence_test');
go
SELECT setval('sequence_test', 99, false);
go
SELECT nextval('sequence_test');
go

-- Sync the last sequence value
CHECKPOINT
go
