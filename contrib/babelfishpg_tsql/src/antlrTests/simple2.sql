DO $$
  PRINT 'line 1'
  BEGIN
    PRINT 'nested'
	PRINT 'block'
  END
  PRINT 2
  PRINT 3 * 2
  
$$ LANGUAGE 'pltsql'
