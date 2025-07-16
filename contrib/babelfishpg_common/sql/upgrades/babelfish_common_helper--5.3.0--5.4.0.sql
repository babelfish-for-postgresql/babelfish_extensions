------------------------------------------------------------------------------
---- Include changes related to other datatypes except spatial types here ----
------------------------------------------------------------------------------

-- Operator class for numeric_ops to incorporate various operator between numeric and fixeddecimal for Index scan
DO $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_opclass opc JOIN pg_opfamily opf ON opc.opcfamily = opf.oid 
        WHERE opc.opcname = 'numeric_fixeddecimal_cmp_ops' AND opc.opcnamespace = 'sys'::regnamespace
        AND opf.opfname = 'numeric_ops') THEN

        CREATE OPERATOR CLASS sys.numeric_fixeddecimal_cmp_ops FOR TYPE numeric
          USING btree FAMILY numeric_ops AS
            OPERATOR 1 sys.< (numeric, fixeddecimal),
            OPERATOR 2 sys.<= (numeric, fixeddecimal),
            OPERATOR 3 sys.= (numeric, fixeddecimal),
            OPERATOR 4 sys.>= (numeric, fixeddecimal),
            OPERATOR 5 sys.> (numeric, fixeddecimal),
            FUNCTION 1 sys.numeric_fixeddecimal_cmp(numeric, fixeddecimal);
    END IF;
END $$;


-- Operator class for numeric_ops to incorporate various operator between fixeddecimal and numeric for Index scan
DO $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM pg_opclass opc JOIN pg_opfamily opf ON opc.opcfamily = opf.oid 
        WHERE opc.opcname = 'fixeddecimal_numeric_cmp_ops' AND opc.opcnamespace = 'sys'::regnamespace
        AND opf.opfname = 'numeric_ops') THEN

        CREATE OPERATOR CLASS sys.fixeddecimal_numeric_cmp_ops FOR TYPE numeric
          USING btree FAMILY numeric_ops AS
            OPERATOR 1 sys.< (fixeddecimal, numeric),
            OPERATOR 2 sys.<= (fixeddecimal, numeric),
            OPERATOR 3 sys.= (fixeddecimal, numeric),
            OPERATOR 4 sys.>= (fixeddecimal, numeric),
            OPERATOR 5 sys.> (fixeddecimal, numeric),
            FUNCTION 1 sys.fixeddecimal_numeric_cmp(fixeddecimal, numeric);
    END IF;
END $$;
