DROP TABLE foo
GO

DROP FUNCTION needs_foo()
GO

CREATE TABLE foo(pkey int)
GO

CREATE FUNCTION needs_foo() RETURNS bool AS
$$
DECLARE
  x foo%ROWTYPE;
BEGIN

  FOR x IN SELECT * FROM foo LOOP
      x.pkey := 4;
  END LOOP;

  RETURN true;

END;
$$ LANGUAGE plpgsql;
