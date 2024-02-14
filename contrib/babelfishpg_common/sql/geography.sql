CREATE OR REPLACE FUNCTION sys.geographyin(cstring, oid, integer)
    RETURNS sys.GEOGRAPHY
    AS 'babelfishpg_common','geography_in'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geographyout(sys.GEOGRAPHY)
    RETURNS cstring
    AS '$libdir/postgis-3','geography_out'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geographytypmodin(cstring[])
    RETURNS integer
    AS '$libdir/postgis-3','geometry_typmod_in'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geographytypmodout(integer)
    RETURNS cstring
    AS '$libdir/postgis-3','postgis_typmod_out'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geographyrecv(internal, oid, integer)
    RETURNS sys.GEOGRAPHY
    AS '$libdir/postgis-3','geography_recv'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE; 

CREATE OR REPLACE FUNCTION sys.geographysend(sys.GEOGRAPHY)
    RETURNS bytea
    AS '$libdir/postgis-3','geography_send'
    LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.geographyanalyze(internal)
    RETURNS bool
    AS '$libdir/postgis-3','gserialized_analyze_nd'
    LANGUAGE 'c' VOLATILE STRICT;  


CREATE TYPE sys.GEOGRAPHY (
    INTERNALLENGTH = variable,
    INPUT          = sys.geographyin,
    OUTPUT         = sys.geographyout,
    RECEIVE        = sys.geographyrecv,
    SEND           = sys.geographysend,
    TYPMOD_IN      = sys.geographytypmodin,
    TYPMOD_OUT     = sys.geographytypmodout,
    DELIMITER      = ':', 
    ANALYZE        = sys.geographyanalyze,
    STORAGE        = main, 
    ALIGNMENT      = double
);

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.GEOGRAPHY, integer, boolean)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3','geography_enforce_typmod'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (sys.GEOGRAPHY AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.GEOGRAPHY, integer, boolean) AS IMPLICIT;

CREATE OR REPLACE FUNCTION sys.get_valid_srids()
	RETURNS integer[]
	AS $$
	DECLARE
		valid_srids integer[] := ARRAY[
									4120, 4121, 4122, 4123, 4124, 4127, 4128, 4129, 4130, 4131, 4132, 4133, 4134, 4135, 4136, 4137, 4138, 4139, 4141, 
									4142, 4143, 4144, 4145, 4146, 4147, 4148, 4149, 4150, 4151, 4152, 4153, 4154, 4155, 4156, 4157, 4158, 4159, 4160, 
									4161, 4162, 4163, 4164, 4165, 4166, 4167, 4168, 4169, 4170, 4171, 4173, 4174, 4175, 4176, 4178, 4179, 4180, 4181, 
									4182, 4183, 4184, 4188, 4189, 4190, 4191, 4192, 4193, 4194, 4195, 4196, 4197, 4198, 4199, 4200, 4201, 4202, 4203, 
									4204, 4205, 4206, 4207, 4208, 4209, 4210, 4211, 4212, 4213, 4214, 4215, 4216, 4218, 4219, 4220, 4221, 4222, 4223, 
									4224, 4225, 4227, 4229, 4230, 4231, 4232, 4236, 4237, 4238, 4239, 4240, 4241, 4242, 4243, 4244, 4245, 4246, 4247, 
									4248, 4249, 4250, 4251, 4252, 4253, 4254, 4255, 4256, 4257, 4258, 4259, 4261, 4262, 4263, 4265, 4266, 4267, 4268, 
									4269, 4270, 4271, 4272, 4273, 4274, 4275, 4276, 4277, 4278, 4279, 4280, 4281, 4282, 4283, 4284, 4285, 4286, 4288, 
									4289, 4292, 4293, 4295, 4297, 4298, 4299, 4300, 4301, 4302, 4303, 4304, 4306, 4307, 4308, 4309, 4310, 4311, 4312, 
									4313, 4314, 4315, 4316, 4317, 4318, 4319, 4322, 4324, 4326, 4600, 4601, 4602, 4603, 4604, 4605, 4606, 4607, 4608, 
									4609, 4610, 4611, 4612, 4613, 4614, 4615, 4616, 4617, 4618, 4619, 4620, 4621, 4622, 4623, 4624, 4625, 4626, 4627, 
									4628, 4629, 4630, 4632, 4633, 4636, 4637, 4638, 4639, 4640, 4641, 4642, 4643, 4644, 4646, 4657, 4658, 4659, 4660, 
									4661, 4662, 4663, 4664, 4665, 4666, 4667, 4668, 4669, 4670, 4671, 4672, 4673, 4674, 4675, 4676, 4677, 4678, 4679, 
									4680, 4682, 4683, 4684, 4686, 4687, 4688, 4689, 4690, 4691, 4692, 4693, 4694, 4695, 4696, 4697, 4698, 4699, 4700, 
									4701, 4702, 4703, 4704, 4705, 4706, 4707, 4708, 4709, 4710, 4711, 4712, 4713, 4714, 4715, 4716, 4717, 4718, 4719, 
									4720, 4721, 4722, 4723, 4724, 4725, 4726, 4727, 4728, 4729, 4730, 4732, 4733, 4734, 4735, 4736, 4737, 4738, 4739, 
									4740, 4741, 4742, 4743, 4744, 4745, 4746, 4747, 4748, 4749, 4750, 4751, 4752, 4753, 4754, 4755, 4756, 4757, 4758, 
									4801, 4802, 4803, 4804, 4805, 4806, 4807, 4808, 4809, 4810, 4811, 4813, 4814, 4815, 4816, 4817, 4818, 4820, 4821, 
									4895, 4898, 4900, 4901, 4902, 4903, 4904, 4907, 4909, 4921, 4923, 4925, 4927, 4929, 4931, 4933, 4935, 4937, 4939, 
									4941, 4943, 4945, 4947, 4949, 4951, 4953, 4955, 4957, 4959, 4961, 4963, 4965, 4967, 4971, 4973, 4975, 4977, 4979, 
									4981, 4983, 4985, 4987, 4989, 4991, 4993, 4995, 4997, 4999, 7843, 7844, 104001
								];
	BEGIN
		RETURN valid_srids;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(bytea)
	RETURNS sys.GEOGRAPHY
    AS $$
    DECLARE
        len integer;
        varBin bytea;
        geomType bytea;
        srid integer;
        newVarBin bytea;
        lat float8;
        byte_position integer := 6;
        coord_NaN bytea := E'\\x000000000000f87f';
        input_coord bytea;
        reversed_bytea bytea := E'\\x';
        i integer := 14;
        isNaN integer = 0;
        valid_srids integer[];
    BEGIN
        -- Call the function to retrieve the valid SRIDs
        SELECT sys.get_valid_srids() INTO valid_srids;
        varBin := $1;
        len := LENGTH(varBin);
        IF len >= 22 THEN
			-- General Logic: We are preprocessing it by removing 2 constant Geometry Type bytes -> 01 0c (for 2-D Point Type) 
			-- Then adding 5 Bytes -> 01 (little endianess) + 4 Bytes (Geography Type). It is expected by the driver
			-- Here we are calculating SRID which is initially in little endian order
			srid := (get_byte(varBin, 3) << 24) | (get_byte(varBin, 2) << 16) | (get_byte(varBin, 1) << 8) | get_byte(varBin, 0);
			-- Here we are calculating value of latitude which is initially in little endian order
			-- check if it lies in the range [-90, 90]
			WHILE i > 6 LOOP
				reversed_bytea := reversed_bytea || substring(varBin from i for 1);
				i = i - 1;
			END LOOP;
			lat := varbinaryfloat8(CAST (reversed_bytea  AS bbf_varbinary));
            WHILE byte_position < len LOOP
				-- Get the coordinate to check if it is NaN
				input_coord := substring(varBin from byte_position + 1 for 8);
				IF encode(input_coord, 'hex') = encode(coord_NaN, 'hex') THEN
					isNaN := 1;
				END IF;
				byte_position := byte_position + 8;
			END LOOP;
			geomType := substring(varBin from 5 for 2);
			varBin := substring(varBin from 1 for 4) || substring(varBin from 7);
			IF srid = ANY(valid_srids) AND isNaN = 0 THEN
				IF encode(geomType, 'hex') = encode(E'\\x010c', 'hex') THEN
					IF lat >= -90.0 AND lat <= 90.0 THEN
						newVarBin := E'\\x0101000020' || varBin;
					ELSE
						RAISE EXCEPTION 'Error converting data type varbinary to geography.';
					END IF;
				ELSE
					RAISE EXCEPTION 'Unsupported geometry type';
				END IF;
			ELSE
				RAISE EXCEPTION 'Error converting data type varbinary to geography.';
			END IF;
            -- Call the underlying function after preprocessing
            RETURN (SELECT sys.GEOGRAPHY_helper(newVarBin)); 
        ELSE
            RAISE EXCEPTION 'Invalid Geography';
        END IF;
    END;
    $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bytea(sys.GEOGRAPHY)
	RETURNS bytea
	AS $$
	DECLARE
        byte bytea;
	BEGIN
		-- Here the received bytes are -> 1 byte (endianness) + 4 bytes (type) + 4 bytes (SRID) + 16 bytes * npoints
		byte := (SELECT sys.bytea_helper($1));
		-- Checking the Geometry type currently we support only POINT type -> type = 1 
		-- (01000020 [here last byte represents presence of SRID]) 
		IF encode(substring(byte from 2 for 4), 'hex') = encode(E'\\x01000020', 'hex') THEN
			-- Here we are taking bytes from SRID only for driver expected format -> 4 bytes (SRID) + 16 bytes * npoints
			byte := substring(byte from 6);
			-- The drivers expected format is 4 bytes (SRID) + 2 bytes (type -> 010C for point) + 16 bytes * npoints
			byte := substring(byte from 1 for 4) || E'\\x010c' || substring(byte from 5);
		END IF;
		RETURN byte;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.bbf_varbinary)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
        varBin bytea;
	BEGIN
		varBin := (SELECT CAST ($1 AS bytea));
		-- Call the underlying function after preprocessing
		RETURN (SELECT sys.GEOGRAPHY(varBin));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bbf_varbinary(sys.GEOGRAPHY)
	RETURNS sys.bbf_varbinary
	AS $$
	DECLARE
        byte bytea;
	BEGIN
		byte := (SELECT sys.bytea($1));
		RETURN (SELECT CAST (byte AS sys.bbf_varbinary)); 
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.bbf_binary)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
        varBin sys.bbf_varbinary;
	BEGIN
		varBin := (SELECT CAST ($1 AS sys.bbf_varbinary));
		-- Call the underlying function after preprocessing
		RETURN (SELECT sys.GEOGRAPHY(varBin)); 
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.text(sys.GEOGRAPHY)
	RETURNS text
	AS $$
	BEGIN
		RAISE EXCEPTION 'Explicit Conversion from data type sys.Geography to Text is not allowed.';
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(text, integer, boolean)
	RETURNS sys.GEOGRAPHY
	AS $$
	BEGIN
		IF $3 = true THEN
			RAISE EXCEPTION 'Explicit Conversion from data type Text to sys.Geography is not allowed.';
		ELSE
			RAISE EXCEPTION 'Implicit Conversion from data type Text to sys.Geography is not allowed.';
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bpchar(sys.GEOGRAPHY)
	RETURNS sys.bpchar
	AS $$
	BEGIN
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		RETURN sys.bpchar((SELECT sys.STAsText_helper(sys.Geography__STFlipCoordinates($1))));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.bpchar)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
		geog sys.GEOGRAPHY;
	BEGIN
		geog := (SELECT sys.charTogeoghelper($1));
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		RETURN (SELECT sys.Geography__STFlipCoordinates(geog));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.varchar(sys.GEOGRAPHY)
	RETURNS sys.varchar
	AS $$
	BEGIN
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		RETURN sys.varchar((SELECT sys.STAsText_helper(sys.Geography__STFlipCoordinates($1))));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY(sys.varchar)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
		geog sys.GEOGRAPHY;
	BEGIN
		geog := (SELECT sys.charTogeoghelper($1));
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		RETURN (SELECT sys.Geography__STFlipCoordinates(geog));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (text AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(text, integer, boolean) AS IMPLICIT;
CREATE CAST (sys.GEOGRAPHY AS text) WITH FUNCTION sys.text(sys.GEOGRAPHY);
CREATE CAST (sys.bpchar AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.bpchar) AS IMPLICIT;
CREATE CAST (sys.GEOGRAPHY AS sys.bpchar) WITH FUNCTION sys.bpchar(sys.GEOGRAPHY);
CREATE CAST (sys.varchar AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.varchar) AS IMPLICIT;
CREATE CAST (sys.GEOGRAPHY AS sys.varchar) WITH FUNCTION sys.varchar(sys.GEOGRAPHY);
CREATE CAST (sys.bbf_binary AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.bbf_binary) AS IMPLICIT;
CREATE CAST (bytea AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(bytea) AS IMPLICIT;
CREATE CAST (sys.GEOGRAPHY AS bytea) WITH FUNCTION sys.bytea(sys.GEOGRAPHY);
CREATE CAST (sys.bbf_varbinary AS sys.GEOGRAPHY) WITH FUNCTION sys.GEOGRAPHY(sys.bbf_varbinary) AS IMPLICIT;
CREATE CAST (sys.GEOGRAPHY AS sys.bbf_varbinary) WITH FUNCTION sys.bbf_varbinary(sys.GEOGRAPHY);

-- This Function Flips the Coordinates of the Point (x, y) -> (y, x)
CREATE OR REPLACE FUNCTION sys.Geography__STFlipCoordinates(sys.GEOGRAPHY)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3', 'ST_FlipCoordinates'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__stgeomfromtext(text, integer)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
		srid integer;
		Geomtype text;
		geom sys.GEOGRAPHY;
		valid_srids integer[];
		lat float8;
		Zmflag smallint;
	BEGIN
		-- Call the function to retrieve the valid SRIDs
		SELECT sys.get_valid_srids() INTO valid_srids;
		srid := $2;
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		geom = (SELECT sys.stgeogfromtext_helper($1, $2));
		Geomtype = (SELECT sys.ST_GeometryType(geom));
		Zmflag = (SELECT sys.ST_Zmflag(geom));
		IF Geomtype = 'ST_Point' THEN
			lat = (SELECT sys.lat(sys.Geography__STFlipCoordinates(sys.stgeogfromtext_helper($1, $2))));
			IF srid = ANY(valid_srids) AND lat >= -90.0 AND lat <= 90.0 THEN
				-- Call the underlying function after preprocessing
				-- if the point instance has z flag only then Zmflag = 1
				-- if the point instance has m flag only then Zmflag = 2
				-- if the point instance has both z and m flags then Zmflag = 3
				IF Zmflag = 1 OR Zmflag = 2 OR Zmflag = 3 THEN
					RAISE EXCEPTION 'Unsupported flags';
				ELSE
					-- Here we are flipping the coordinates 
					-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
					RETURN (SELECT sys.Geography__STFlipCoordinates(geom));
				END IF;
			ELSEIF lat < -90.0 OR lat > 90.0 THEN
				RAISE EXCEPTION 'Latitude values must be between -90 and 90 degrees';
			ELSE
				RAISE EXCEPTION 'Inavalid SRID';
			END IF;
		ELSE
			RAISE EXCEPTION '% is not supported', Geomtype;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsText(sys.GEOGRAPHY)
	RETURNS TEXT
	AS $$
	BEGIN
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		RETURN (SELECT sys.STAsText_helper(sys.Geography__STFlipCoordinates($1)));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsBinary(sys.GEOGRAPHY)
	RETURNS bytea
	AS '$libdir/postgis-3','LWGEOM_asBinary'
	LANGUAGE 'c' IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__Point(float8, float8, srid integer)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
		srid integer;
		lat float8;
		valid_srids integer[];
	BEGIN
		-- Call the function to retrieve the valid SRIDs
		SELECT sys.get_valid_srids() INTO valid_srids;
		srid := $3;
		lat := $1;
		IF srid = ANY(valid_srids) AND lat >= -90.0 AND lat <= 90.0 THEN
			-- Call the underlying function after preprocessing
			RETURN (SELECT sys.GeogPoint_helper($1, $2, $3));
		ELSEIF lat < -90.0 OR lat > 90.0 THEN
			RAISE EXCEPTION 'Latitude values must be between -90 and 90 degrees';
		ELSE
			RAISE EXCEPTION 'Inavalid SRID';
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsBinary(sys.GEOGRAPHY)
	RETURNS bytea
	AS $$
	BEGIN
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		RETURN (SELECT sys.STAsBinary_helper(sys.Geography__STFlipCoordinates($1)));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.Geography__STPointFromText(text, integer)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
		srid integer;
		Geomtype text;
		geom sys.GEOGRAPHY;
		valid_srids integer[];
		lat float8;
		Zmflag smallint;
	BEGIN
		-- Call the function to retrieve the valid SRIDs
		SELECT sys.get_valid_srids() INTO valid_srids;
		srid := $2;
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		geom = (SELECT sys.stgeogfromtext_helper($1, $2));
		Geomtype = (SELECT sys.ST_GeometryType(geom));
		Zmflag = (SELECT sys.ST_Zmflag(geom));
		IF Geomtype = 'ST_Point' THEN
			lat = (SELECT sys.lat(sys.Geography__STFlipCoordinates(sys.stgeogfromtext_helper($1, $2))));
			IF srid = ANY(valid_srids) AND lat >= -90.0 AND lat <= 90.0 THEN
				-- Call the underlying function after preprocessing
				-- if the point instance has z flag only then Zmflag = 1
				-- if the point instance has m flag only then Zmflag = 2
				-- if the point instance has both z and m flags then Zmflag = 3
				IF Zmflag = 1 OR Zmflag = 2 OR Zmflag = 3 THEN
					RAISE EXCEPTION 'Unsupported flags';
				ELSE
					-- Here we are flipping the coordinates 
					-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
					RETURN (SELECT sys.Geography__STFlipCoordinates(geom));
				END IF;
			ELSEIF lat < -90.0 OR lat > 90.0 THEN
				RAISE EXCEPTION 'Latitude values must be between -90 and 90 degrees';
			ELSE
				RAISE EXCEPTION 'Inavalid SRID';
			END IF;
		ELSE
			RAISE EXCEPTION '% is not supported', Geomtype;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ST_GeometryType(sys.GEOGRAPHY)
	RETURNS text
	AS '$libdir/postgis-3', 'geometry_geometrytype'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.ST_zmflag(sys.GEOGRAPHY)
	RETURNS smallint
	AS '$libdir/postgis-3', 'LWGEOM_zmflag'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sys.ST_Equals(leftarg sys.GEOGRAPHY, rightarg sys.GEOGRAPHY)
    RETURNS boolean
    AS $$
    DECLARE
        leftvarBin sys.bbf_varbinary;
        rightvarBin sys.bbf_varbinary;
    BEGIN
        leftvarBin := (SELECT sys.bbf_varbinary($1));
        rightvarBin := (SELECT sys.bbf_varbinary($2));
        RETURN (SELECT sys.varbinary_eq(leftvarBin, rightvarBin));
    END;
    $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.= (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.ST_Equals,
    COMMUTATOR = =,
    RESTRICT = eqsel
);

CREATE FUNCTION sys.ST_NotEquals(leftarg sys.GEOGRAPHY, rightarg sys.GEOGRAPHY)
	RETURNS boolean
	AS $$
    DECLARE
        leftvarBin sys.bbf_varbinary;
		rightvarBin sys.bbf_varbinary;
    BEGIN
        leftvarBin := (SELECT sys.bbf_varbinary($1));
        rightvarBin := (SELECT sys.bbf_varbinary($2));
        RETURN (SELECT sys.varbinary_neq(leftvarBin, rightvarBin));
    END;
    $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR sys.<> (
    LEFTARG = sys.GEOGRAPHY,
    RIGHTARG = sys.GEOGRAPHY,
    FUNCTION = sys.ST_NotEquals,
    COMMUTATOR = <>
);

-- Minimum distance
CREATE OR REPLACE FUNCTION sys.STDistance(geog1 sys.GEOGRAPHY, geog2 sys.GEOGRAPHY)
	RETURNS float8
	AS $$
	BEGIN
		-- Call the underlying function after preprocessing
		-- Here we are flipping the coordinates 
		-- since Geography Datatype stores the point supplied as string in Reverse Order i.e. (long, lat)
		RETURN (SELECT sys.STDistance_helper(sys.Geography__STFlipCoordinates($1), sys.Geography__STFlipCoordinates($2)));
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.long(sys.GEOGRAPHY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_y_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.lat(sys.GEOGRAPHY)
	RETURNS float8
	AS '$libdir/postgis-3','LWGEOM_x_point'
	LANGUAGE 'c' IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION sys.ST_Transform(sys.GEOGRAPHY, integer)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3','transform'
	LANGUAGE 'c' IMMUTABLE STRICT;

-- Helper functions for main T-SQL functions
CREATE OR REPLACE FUNCTION sys.stgeogfromtext_helper(text, integer)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3','LWGEOM_from_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STAsText_helper(sys.GEOGRAPHY)
	RETURNS TEXT
	AS '$libdir/postgis-3','LWGEOM_asText'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE; 

CREATE OR REPLACE FUNCTION sys.GeogPoint_helper(float8, float8, srid integer)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3', 'ST_Point'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE; 

CREATE OR REPLACE FUNCTION sys.STAsBinary_helper(sys.GEOGRAPHY)
	RETURNS bytea
	AS '$libdir/postgis-3','LWGEOM_asBinary'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.STDistance_helper(geog1 sys.GEOGRAPHY, geog2 sys.GEOGRAPHY)
	RETURNS float8
	AS '$libdir/postgis-3', 'LWGEOM_distance_ellipsoid'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.GEOGRAPHY_helper(bytea)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3','LWGEOM_from_bytea'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bpcharToGeography_helper(sys.bpchar, integer)
	RETURNS sys.GEOGRAPHY
	AS '$libdir/postgis-3','LWGEOM_from_text'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.bytea_helper(sys.GEOGRAPHY)
	RETURNS bytea
	AS '$libdir/postgis-3','LWGEOM_to_bytea'
	LANGUAGE 'c' IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION sys.charTogeoghelper(sys.bpchar)
	RETURNS sys.GEOGRAPHY
	AS $$
	DECLARE
		Geomtype text;
		geog sys.GEOGRAPHY;
		lat float8;
		Zmflag smallint;
	BEGIN
		geog = (SELECT sys.bpcharToGeography_helper($1, 4326));
		Geomtype = (SELECT sys.ST_GeometryType(geog));
		Zmflag = (SELECT sys.ST_Zmflag(geog));
		IF Geomtype = 'ST_Point' THEN
			lat = (SELECT sys.lat(sys.Geography__STFlipCoordinates(sys.stgeogfromtext_helper($1, 4326))));
			IF lat >= -90.0 AND lat <= 90.0 THEN
				-- Call the underlying function after preprocessing
				-- if the point instance has z flag only then Zmflag = 1
				-- if the point instance has m flag only then Zmflag = 2
				-- if the point instance has both z and m flags then Zmflag = 3
				IF Zmflag = 1 OR Zmflag = 2 OR Zmflag = 3 THEN
					RAISE EXCEPTION 'Unsupported flags';
				ELSE
					RETURN geog;
				END IF;
			ELSEIF lat < -90.0 OR lat > 90.0 THEN
				RAISE EXCEPTION 'Latitude values must be between -90 and 90 degrees';
			END IF;
		ELSE
			RAISE EXCEPTION '% is not supported', Geomtype;
		END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

