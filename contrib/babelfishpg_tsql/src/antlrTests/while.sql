DO $$
DECLARE @X INT = 0

WHILE( @X < 10 )
BEGIN
  PRINT @X
  SET @X = @X + 1

  IF @X = 5
  BEGIN
	PRINT 'skipping 5'
    CONTINUE
  END

  IF @X = 7
    BREAK

END

PRINT 'yyy'

$$ LANGUAGE 'pltsql'

