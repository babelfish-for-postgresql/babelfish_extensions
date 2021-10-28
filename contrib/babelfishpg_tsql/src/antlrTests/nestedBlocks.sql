DO $$
  PRINT 'line 1'
  BEGIN
    PRINT 2
  END

  BEGIN
    PRINT 3 * 1
	PRINT [upper]('four score and seven years ago')
    BEGIN
	  PRINT 4
	END
  END

$$ LANGUAGE 'pltsql'
