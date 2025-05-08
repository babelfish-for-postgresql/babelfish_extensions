-------------------------------------------------------
---- Include changes related to spatial types here ----
-------------------------------------------------------

CREATE OR REPLACE FUNCTION sys.bytea(sys.GEOMETRY)
    RETURNS bytea
    AS $$
    DECLARE
        byte bytea;
        srid_flag text;
    BEGIN
        byte := (SELECT sys.bytea_helper($1));
        -- Checking the Geometry type currently we support only POINT type -> type = 1
        IF encode(substring(byte from 2 for 3), 'hex') = encode(E'\\x010000', 'hex') THEN
            srid_flag := encode(substring(byte from 5 for 1), 'hex');
            -- Check if the given geometry has SRID flag
            IF srid_flag = encode(E'\\x20', 'hex') THEN
                byte := substring(byte from 6);
                byte := substring(byte from 1 for 4) || E'\\x010c' || substring(byte from 5);
            ELSEIF srid_flag = encode(E'\\x00', 'hex') AND LENGTH(byte) = 21 THEN
                -- Signifies SRID = 0, pass the driver expected wkb manually
                byte := substring(byte from 6); -- contains only wkb point coords
                -- prepend 4 byte SRID (00000000) + 2 bytes (type -> 010C for point)
                byte := E'\\x00000000010c' || substring(byte from 1);
            END IF;
        END IF;
        RETURN byte;
    END;
    $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;
