-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------

SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

------------------------------------------------------------------------------
---- Add changes here --------------------------------------------------------
------------------------------------------------------------------------------

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);