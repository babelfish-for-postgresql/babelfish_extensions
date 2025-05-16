------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_common"" UPDATE TO "3.10.0"" to load this file. \quit

SELECT set_config('search_path', 'sys, '|| current_setting('search_path'), false);

-- Operator class for numeric_ops to incorporate various operator between numeric and int4 for Index scan
CREATE OPERATOR CLASS sys.numeric_int4_ops FOR TYPE numeric
  USING btree FAMILY numeric_ops AS
   OPERATOR 1 sys.< (numeric, int4),
   OPERATOR 2 sys.<= (numeric, int4),
   OPERATOR 3 sys.= (numeric, int4),
   OPERATOR 4 sys.>= (numeric, int4),
   OPERATOR 5 sys.> (numeric, int4),
   FUNCTION 1 sys.numeric_int4_cmp(numeric, int4);

-- Operator class for numeric_ops to incorporate various operator between int4 and numeric for Index scan
CREATE OPERATOR CLASS sys.int4_numeric_ops FOR TYPE numeric
  USING btree FAMILY numeric_ops AS
   OPERATOR 1 sys.< (int4, numeric),
   OPERATOR 2 sys.<= (int4, numeric),
   OPERATOR 3 sys.= (int4, numeric),
   OPERATOR 4 sys.>= (int4, numeric),
   OPERATOR 5 sys.> (int4, numeric),
   FUNCTION 1 sys.int4_numeric_cmp(int4, numeric);

-- Operator class for numeric_ops to incorporate various operator between numeric and int2 for Index scan
CREATE OPERATOR CLASS sys.numeric_int2_ops FOR TYPE numeric
  USING btree FAMILY numeric_ops AS
   OPERATOR 1 sys.< (numeric, int2),
   OPERATOR 2 sys.<= (numeric, int2),
   OPERATOR 3 sys.= (numeric, int2),
   OPERATOR 4 sys.>= (numeric, int2),
   OPERATOR 5 sys.> (numeric, int2),
   FUNCTION 1 sys.numeric_int2_cmp(numeric, int2);

-- Operator class for numeric_ops to incorporate various operator between int2 and numeric for Index scan
CREATE OPERATOR CLASS sys.int2_numeric_ops FOR TYPE numeric
  USING btree FAMILY numeric_ops AS
   OPERATOR 1 sys.< (int2, numeric),
   OPERATOR 2 sys.<= (int2, numeric),
   OPERATOR 3 sys.= (int2, numeric),
   OPERATOR 4 sys.>= (int2, numeric),
   OPERATOR 5 sys.> (int2, numeric),
   FUNCTION 1 sys.int2_numeric_cmp(int2, numeric);


-- Operator class for numeric_ops to incorporate various operator between int8 and numeric for Index scan
CREATE OPERATOR CLASS sys.int8_numeric_ops FOR TYPE numeric
  USING btree FAMILY numeric_ops AS
   OPERATOR 1 sys.< (int8, numeric),
   OPERATOR 2 sys.<= (int8, numeric),
   OPERATOR 3 sys.= (int8, numeric),
   OPERATOR 4 sys.>= (int8, numeric),
   OPERATOR 5 sys.> (int8, numeric),
   FUNCTION 1 sys.int8_numeric_cmp(int8, numeric);

-- Operator class for numeric_ops to incorporate various operator between numeric and int8 for Index scan
CREATE OPERATOR CLASS sys.numeric_int8_ops FOR TYPE numeric
  USING btree FAMILY numeric_ops AS
   OPERATOR 1 sys.< (numeric, int8),
   OPERATOR 2 sys.<= (numeric, int8),
   OPERATOR 3 sys.= (numeric, int8),
   OPERATOR 4 sys.>= (numeric, int8),
   OPERATOR 5 sys.> (numeric, int8),
   FUNCTION 1 sys.numeric_int8_cmp(numeric, int8);

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
