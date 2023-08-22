CREATE EXTENSION IF NOT EXISTS babelfishpg_unit;

CREATE OR REPLACE FUNCTION check_all_unit_tests_passed()
RETURNS VOID AS $$
DECLARE
  total_tests INTEGER;
  passed_tests INTEGER;
BEGIN
  -- Get the total number of tests
  SELECT COUNT(*) INTO total_tests
  FROM babelfishpg_unit_run_tests(); 

  -- Get the number of tests passed
  SELECT COUNT(*) INTO passed_tests
  FROM babelfishpg_unit_run_tests()
  WHERE status = 'pass';

  -- Throw an error if not all tests passed
  IF total_tests <> passed_tests THEN
    RAISE EXCEPTION 'Not all tests passed. Total tests: %, Passed tests: %', total_tests, passed_tests;
  END IF;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM babelfishpg_unit_run_tests();

SELECT * FROM check_all_unit_tests_passed();
