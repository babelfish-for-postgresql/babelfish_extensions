DO $$

DECLARE @X INT = 4

IF (@X = 3)
   PRINT '3'
ELSE IF (@X = 4)
  BEGIN
   PRINT 'the answer is: '
   PRINT '4'
  END
ELSE IF (@X = 5)
   PRINT '5'
ELSE
   PRINT 'unknown'

$$LANGUAGE 'pltsql'
