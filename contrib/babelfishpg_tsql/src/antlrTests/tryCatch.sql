DO $$
   DECLARE @VAL INT

   BEGIN TRY
      PRINT 'inside try'

	  SET @VAL = @VAL / 0

	  PRINT 'never reached'

   END TRY
   BEGIN CATCH
   		 PRINT 'inside catch'
   END CATCH

   PRINT 'between'

   BEGIN TRY
     PRINT 'inside second try'
   END TRY
   BEGIN CATCH
      PRINT 'never reached'
   END CATCH

   PRINT 'final'
$$ LANGUAGE 'pltsql'
