DO $$

  PRINT 'line 1'

  INSERT INTO [foo] VALUES(1,2,3*4)

  THROW

  RETURN 42
  
$$ LANGUAGE 'pltsql'
