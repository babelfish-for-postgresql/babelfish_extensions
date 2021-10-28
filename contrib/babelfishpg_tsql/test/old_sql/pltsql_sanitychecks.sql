--
-- PLTSQL -- Sanity checks
--           This is supposed to be the last PL/TSQL test category.
--
--

-- None of these #test* local temporary tables should be visible to us.

SELECT * FROM "#test";
SELECT * FROM "#test2";
SELECT * FROM "#test3";
SELECT * FROM "#test4";
