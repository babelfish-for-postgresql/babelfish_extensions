-- complain if script is sourced in psql, rather than via ALTER EXTENSION
\echo Use "ALTER EXTENSION ""babelfishpg_tsql"" UPDATE TO '6.3.0'" to load this file. \quit
-- add 'sys' to search path for the convenience
SELECT set_config('search_path', 'sys, '||current_setting('search_path'), false);

CREATE OR REPLACE PROCEDURE babelfish_drop_deprecated_object(object_type varchar, schema_name varchar, object_name varchar, arg_types varchar DEFAULT '') AS
$$
DECLARE
    error_msg text;
    query1 text;
    query2 text;
    full_object_name text;
BEGIN
    -- Construct full object name with argument types if provided (for aggregates)
    IF arg_types <> '' THEN
        full_object_name := pg_catalog.format('%s.%s(%s)', schema_name, object_name, arg_types);
    ELSE
        full_object_name := pg_catalog.format('%s.%s', schema_name, object_name);
    END IF;

    query1 := pg_catalog.format('alter extension babelfishpg_tsql drop %s %s', object_type, full_object_name);
    query2 := pg_catalog.format('drop %s %s', object_type, full_object_name);
    execute query1;
    execute query2;
EXCEPTION
    when object_not_in_prerequisite_state then --if 'alter extension' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when dependent_objects_still_exist then --if 'drop view' statement fails
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
    when undefined_function then --if 'Deprecated function does not exist'
        GET STACKED DIAGNOSTICS error_msg = MESSAGE_TEXT;
        raise warning '%', error_msg;
end
$$
LANGUAGE plpgsql;

-- please add your SQL here
/*
 * Note: These SQL statements may get executed multiple times specially when some features get backpatched.
 * So make sure that any SQL statement (DDL/DML) being added here can be executed multiple times without affecting
 * final behaviour.
 */

CREATE OR REPLACE FUNCTION sys.babelfish_update_server_collation_name() RETURNS VOID
LANGUAGE C
AS 'babelfishpg_common', 'babelfish_update_server_collation_name';

DO
LANGUAGE plpgsql
$$
BEGIN
    -- Check if the GUC is empty
    IF current_setting('babelfishpg_tsql.restored_server_collation_name', true) <> '' THEN
        -- Call the function to update the collation
        EXECUTE 'SELECT sys.babelfish_update_server_collation_name()';
    END IF;
END;
$$;

DROP FUNCTION sys.babelfish_update_server_collation_name();

-- reset babelfishpg_tsql.restored_server_collation_name GUC
do
language plpgsql
$$
    declare
        query text;
    begin
        query := pg_catalog.format('alter database %s reset babelfishpg_tsql.restored_server_collation_name', CURRENT_DATABASE());
        execute query;
    end;
$$;


-- helper functions for XML EXIST(xpath)
CREATE OR REPLACE FUNCTION sys.bbf_xmlexist(xpath_pattern TEXT, xml_element ANYELEMENT)
RETURNS sys.BIT
AS
$BODY$
DECLARE
    arg_datatype TEXT;
    arg_datatype_oid oid;
    basetype oid;
    pltsql_quoted_identifier TEXT;
BEGIN
    arg_datatype_oid := pg_typeof(xml_element)::oid;
    arg_datatype := sys.translate_pg_type_to_tsql(arg_datatype_oid);
    IF arg_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for argument datatype validation
        basetype := sys.bbf_get_immediate_base_type_of_UDT(arg_datatype_oid);
        arg_datatype := sys.translate_pg_type_to_tsql(basetype);
    END IF;

    IF (arg_datatype != 'xml') THEN
        RAISE EXCEPTION 'Cannot call methods on %.', arg_datatype;
    END IF;

    pltsql_quoted_identifier := current_setting('babelfishpg_tsql.quoted_identifier');

    IF (pltsql_quoted_identifier = 'off') THEN
        RAISE EXCEPTION 'SELECT failed because the following SET options have incorrect settings: ''QUOTED_IDENTIFIER''. Verify that SET options are correct for XML data type methods.';
    END IF;

    IF (xml_element IS NULL)  THEN
        RETURN NULL;
    END IF;

    IF (trim(xml_element::TEXT) = '') THEN
        RETURN 0;
    END IF;

    xpath_pattern := sys.bbf_xml_xpath_with_context_node(xpath_pattern, sys.bbf_xml_extract_magic_nodes_tag(xml_element));

    if (sys.bbf_xml_check_xpath_pattern(xpath_pattern, 'query') = 0) then
        -- successful, do nothing; otherwise an exception will have been thrown
    END IF;

    xml_element := sys.bbf_xml_remove_magic_nodes_tag(xml_element);

    RETURN xmlexists(xpath_pattern passing by value xml_element);
END
$BODY$
LANGUAGE plpgsql STABLE STRICT PARALLEL SAFE;

-- helper function for XML QUERY(xpath)
CREATE OR REPLACE FUNCTION sys.bbf_xmlquery_internal(xpath_pattern TEXT, xml_element ANYELEMENT)
RETURNS XML
AS 'babelfishpg_tsql', 'bbf_xmlquery'
LANGUAGE C STABLE STRICT PARALLEL SAFE;

-- helper functions for XML QUERY(xpath)
CREATE OR REPLACE FUNCTION sys.bbf_xmlquery(xpath_pattern TEXT, xml_element ANYELEMENT)
RETURNS XML
AS
$BODY$
BEGIN
    IF (xml_element IS NULL)  THEN
        RETURN NULL;
    END IF;

    IF (trim(xml_element::TEXT) = '') THEN
        RETURN ''::XML;
    END IF;

    /* The internal C function checks for XML datatype and QUOTED_IDENTIFIER = ON, not duplicating it here */

    xpath_pattern := sys.bbf_xml_xpath_with_context_node(xpath_pattern, sys.bbf_xml_extract_magic_nodes_tag(xml_element));

    IF (sys.bbf_xml_check_xpath_pattern(xpath_pattern, 'query') = 0) THEN
        -- successful, do nothing; otherwise an exception will have been thrown
    END IF;

    xml_element := sys.bbf_xml_remove_magic_nodes_tag(xml_element);

    RETURN sys.bbf_xmlquery_internal(xpath_pattern, xml_element);
END
$BODY$
LANGUAGE plpgsql STABLE STRICT PARALLEL SAFE;

-- helper functions for XML VALUE(xpath)
CREATE OR REPLACE FUNCTION sys.bbf_xmlvalue(xpath_pattern TEXT, datatype TEXT, xml_element ANYELEMENT)
RETURNS sys.NVARCHAR
AS
$BODY$
DECLARE
    temp_datatype TEXT;
    temp_basetype oid;
    result_set XML[];
    result sys.NVARCHAR;
    pltsql_quoted_identifier TEXT;
BEGIN
    IF (xml_element IS NULL) OR (trim(xml_element::TEXT) = '') THEN
        RETURN NULL;
    END IF;

    temp_datatype := sys.translate_pg_type_to_tsql(pg_typeof(xml_element)::oid);
    IF temp_datatype IS NULL THEN
        -- for User Defined Datatype, use immediate base type to check for xml_element datatype validation
        temp_basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof(xml_element)::oid);
        temp_datatype := sys.translate_pg_type_to_tsql(temp_basetype);
    END IF;

    IF (temp_datatype != 'xml') THEN
        RAISE EXCEPTION 'Cannot call methods on %.', temp_datatype;
    END IF;

    pltsql_quoted_identifier := current_setting('babelfishpg_tsql.quoted_identifier');

    IF (pltsql_quoted_identifier = 'off') THEN
        RAISE EXCEPTION 'SELECT failed because the following SET options have incorrect settings: ''QUOTED_IDENTIFIER''. Verify that SET options are correct for XML data type methods.';
    END IF;

    xpath_pattern := sys.bbf_xml_xpath_with_context_node(xpath_pattern, sys.bbf_xml_extract_magic_nodes_tag(xml_element));

    if (sys.bbf_xml_check_xpath_pattern(xpath_pattern, 'value') = 0) THEN
        -- successful, do nothing; otherwise an exception will have been thrown
    END IF;

    xml_element := sys.bbf_xml_remove_magic_nodes_tag(xml_element);
    result_set := xpath(xpath_pattern, xml_element);

    IF (cardinality(result_set) > 1) THEN
        RAISE EXCEPTION 'XML Value result is not a single value.';
    ELSIF (cardinality(result_set) = 0) THEN
        RETURN NULL;
    ELSE
        result := (xpath('string(' || xpath_pattern || ')', xml_element))[1];
        result := sys.bbf_xml_decode_chars(result);
        RETURN result;
    END IF;
END
$BODY$
LANGUAGE plpgsql STABLE STRICT PARALLEL SAFE;

-- helper function for XML NODES(xpath)
CREATE OR REPLACE FUNCTION sys.bbf_xmlnodes(xpath_pattern TEXT, xml_element ANYELEMENT)
RETURNS SETOF XML
AS
$BODY$
DECLARE
    temp_datatype TEXT;
    temp_basetype oid;
    pltsql_quoted_identifier TEXT;
    nr_rows INT;
    i INT;
    context_node_path TEXT;
    xmlrowset XML[];
    context_tag_name TEXT  := sys.bbf_xmlnodes_magic_tag_name();
    context_tag_open TEXT  := '<'||context_tag_name||'>';
    context_tag_close TEXT := '</'||context_tag_name||'>';
BEGIN
    temp_datatype := sys.translate_pg_type_to_tsql(pg_typeof(xml_element)::oid);
    IF temp_datatype IS NULL THEN
        temp_basetype := sys.bbf_get_immediate_base_type_of_UDT(pg_typeof(xml_element)::oid);
        temp_datatype := sys.translate_pg_type_to_tsql(temp_basetype);
    END IF;

    IF (temp_datatype != 'xml') THEN
        RAISE EXCEPTION 'Cannot call methods on %.', temp_datatype;
    END IF;

    IF (xml_element IS NULL) OR (trim(xml_element::TEXT)::TEXT = '') THEN
        RETURN QUERY SELECT UNNEST(xmlrowset);
        RETURN;
    END IF;

    pltsql_quoted_identifier := current_setting('babelfishpg_tsql.quoted_identifier');

    IF (pltsql_quoted_identifier = 'off') THEN
        RAISE EXCEPTION 'SELECT failed because the following SET options have incorrect settings: ''QUOTED_IDENTIFIER''. Verify that SET options are correct for XML data type methods.';
    END IF;
    
    context_node_path := sys.bbf_xml_extract_magic_nodes_tag(xml_element);
    xml_element := sys.bbf_xml_remove_magic_nodes_tag(xml_element);
    xpath_pattern := sys.bbf_xml_xpath_with_context_node(xpath_pattern, context_node_path);
    if (sys.bbf_xml_check_xpath_pattern(xpath_pattern, 'nodes') = 0) THEN
        -- successful, do nothing; otherwise an exception will have been thrown
    END IF;

    nr_rows := coalesce(array_length(xpath(xpath_pattern, xml_element),1),0);
    FOR i IN 1 .. nr_rows LOOP
        -- encode to handle > and < chars in predicates
        context_node_path := context_tag_open ||  '(' || sys.bbf_xml_encode_chars(xpath_pattern) ||  ')[' ||  i || ']' || context_tag_close;
        xmlrowset := array_append(xmlrowset, xmlconcat(context_node_path::XML, xml_element));
    END LOOP;

    RETURN QUERY SELECT UNNEST(xmlrowset);
    RETURN;
END
$BODY$
LANGUAGE plpgsql STABLE STRICT PARALLEL SAFE;

/*
 * Prepends context node query to steps in the method query
 */
CREATE OR REPLACE FUNCTION sys.bbf_xml_xpath_with_context_node(xpath_pattern TEXT, context_node_path TEXT)
RETURNS TEXT
AS
$BODY$
DECLARE
    stripped TEXT;
    ch TEXT;
    result TEXT;
BEGIN
    -- Remove all whitespace except in string constants and predicates
    xpath_pattern  := sys.bbf_xml_remove_xpath_whitespace(xpath_pattern);
    context_node_path := sys.bbf_xml_remove_xpath_whitespace(context_node_path);

    IF context_node_path IS NULL OR length(context_node_path) = 0 THEN
        -- Context_node_path is empty, return xpath_pattern 
        -- but patch up .[N] to (.)[N] but not ..[N] or /.[N}

        --todo : run performance test
        xpath_pattern := sys.bbf_xml_patch_xpath_dot_bracket(xpath_pattern);
        --xpath_pattern := pg_catalog.regexp_replace(xpath_pattern, '([^\/\.])\.\[', '\1(.)[', 'gi');
        RETURN xpath_pattern;
    END IF;
    -- Check if xpath_pattern is absolute (starts with '/' after stripping leading '(')
    stripped := xpath_pattern;
    WHILE substring(stripped, 1, 1)::TEXT = '('
    LOOP
        stripped := substring(stripped, 2);
    END LOOP;
    IF substring(stripped, 1, 1)::TEXT = '/' THEN
        -- Absolute path, return unchanged
        RETURN xpath_pattern;
    END IF;

    -- Check if xpath_pattern starts with a known XPath function
    -- If there is an XPath function, it will either be in a predicate(which we do not touch) or it will be at the start
    IF sys.bbf_xml_is_xpath_function(stripped) THEN
        -- Process function: replace dot-references in arguments
        result := sys.bbf_xml_process_xpath_function(xpath_pattern, context_node_path);
        RETURN result;
    END IF;

    -- Check if xpath_pattern starts with '(' (bracketed path)
    IF substring(xpath_pattern, 1, 1)::TEXT = '(' THEN
        -- Insert context_node_path + '/' after the opening '('
        result := '(' || context_node_path || '/' || substring(xpath_pattern, 2);
        RETURN result;
    END IF;

    -- Simple relative path - prepend context_node_path
    RETURN context_node_path || '/' || xpath_pattern;
END
$BODY$
LANGUAGE plpgsql STABLE STRICT PARALLEL SAFE;

-- Process an XPath function call, replacing '.'-references in arguments
-- with the context node path and prepending @names and bare identifier names
-- with the context node path.
-- String literals and XPath predicates are not touched.
--
-- Algorithm is to step char-by-char through the string, identify the arguments
-- (which can be nested XPath function calls) and replace/prepend the expressions.
--
CREATE OR REPLACE FUNCTION sys.bbf_xml_process_xpath_function(xpath_pattern TEXT, context_node_path TEXT)
RETURNS TEXT
AS
$BODY$
DECLARE
    len_xp INT;
    i INT ;
    result TEXT := '';
    ch TEXT;
    next_ch TEXT;
    prev_ch TEXT;
    ident TEXT;
    ident_end INT;
    is_xpath_function boolean;
    skipped_chars TEXT;
BEGIN
    IF context_node_path IS NULL OR length(trim(context_node_path)) = 0 THEN
        return xpath_pattern;
    END IF;

    -- Add space at start and two spaces at end to simpify the logic below so
    -- that there is always a previous and next character
    xpath_pattern := ' '||xpath_pattern||'  ';
    len_xp := length(xpath_pattern);

    -- Walk through the entire expression character by character
    i := 1;
    WHILE i <= len_xp LOOP
        -- Skip comments or predicates
        skipped_chars := sys.bbf_xml_skip_xpath_chars(xpath_pattern, i, len_xp);
        IF skipped_chars != '' THEN
            -- Copy any skipped characters to result
            result := result || skipped_chars;
            i := i + length(skipped_chars);
            CONTINUE;
        ELSE
            -- Not skipping any characters
            ch := substring(xpath_pattern, i, 1);
        END IF;

       -- Determine preceding char
        prev_ch := substring(xpath_pattern, i - 1, 1);

        -- Check if current position is a '.'-reference
        -- This is the case when '.' appears and the preceding character
        -- is one of ( , / or this is the first char of an argument
        IF ch = '.' THEN
            -- Preceded by ( , / or start
            IF prev_ch IN ('(', ',', '/', ' ')  THEN
                -- Look ahead to determine if this is '..' or '.' or './path'
                next_ch := substring(xpath_pattern, i + 1, 1);

                IF next_ch = '.' THEN
                    -- '..' (parent), check what follows
                    IF substring(xpath_pattern, i + 2, 1)::TEXT IN ('/', ')', ',', '[', ']', ' ') THEN
                        result := result || '(' || context_node_path || '/..)';
                        i := i + 2; -- move forward
                    ELSE
                        -- '..' followed by something else - not a reference, copy as-is
                        result := result || ch;
                        i := i + 1;
                    END IF;
                ELSIF next_ch IN ('/', ')', ',', '[', ']', ' ') THEN
                    -- '.' or './' - self reference, possibly followed by path
                    result := result || '(' || context_node_path || '/.)';
                    i := i + 1; -- skip '.'
                ELSE
                    -- '.' followed by something else (could be a number in '1.0')
                    -- Not a self-reference, copy as-is
                    result := result || ch;
                    i := i + 1;
                END IF;
            ELSE
                -- '.' not preceded by argument-start character, copy as-is
                result := result || ch;
                i := i + 1;
            END IF;
            CONTINUE;
        END IF;

        -- Handle @attr expressions when preceded by ( or , (start of argument)
        IF ch = '@' THEN
            IF prev_ch IN ('(', ',', ' ') THEN
                -- Collect the @attr name (@name, @*, @id, etc.)
                ident := '@';
                ident_end := i + 1;
                WHILE ident_end <= len_xp LOOP
                    ch := substring(xpath_pattern, ident_end, 1);
                    -- Valid @attr name chars: [A-Za-z0-9_-.*]
                    IF (ch >= 'A' AND ch <= 'Z') OR
                       (ch >= 'a' AND ch <= 'z') OR
                       (ch >= '0' AND ch <= '9') OR
                       (ch IN ('_', '-', '.', '*'))
                    THEN
                        ident := ident || ch;
                        ident_end := ident_end + 1;
                    ELSE
                        EXIT;
                    END IF;
                END LOOP;
                -- Prefix with context node
                result := result || context_node_path || '/' || ident;
                i := ident_end;
                CONTINUE;
            END IF;

            -- @ not at argument start (e.g., after /) - copy as-is
            result := result || ch;
            i := i + 1;
            CONTINUE;
        END IF;

        -- Handle identifiers without '@', preceded by ( or , )
        -- Note that we must skip known XPath function names
        IF (ch >= 'A' AND ch <= 'Z') OR
           (ch >= 'a' AND ch <= 'z') OR
           (ch = '_')
        THEN
            IF prev_ch IN ('(', ',', ' ') THEN
                -- Get the full identifier
                ident := '';
                ident_end := i;
                WHILE ident_end <= len_xp LOOP
                    ch := substring(xpath_pattern, ident_end, 1);
                    IF (ch >= 'A' AND ch <= 'Z') OR
                       (ch >= 'a' AND ch <= 'z') OR
                       (ch >= '0' AND ch <= '9') OR
                       (ch IN ('_', '-'))
                    THEN
                        ident := ident || ch;
                        ident_end := ident_end + 1;
                    ELSE
                        EXIT;
                    END IF;
                END LOOP;

                is_xpath_function := false;
                -- Check if this identifier is a known XPath function followed by '('
                IF ident_end <= len_xp AND substring(xpath_pattern, ident_end, 1)::TEXT = '(' THEN
                    is_xpath_function := sys.bbf_xml_is_xpath_function(ident||'(');
                END IF;

                IF is_xpath_function THEN
                    -- It is an XPath function - copy as-is
                    result := result || ident;
                    i := ident_end;
                ELSE
                    -- It is an identifier, prefix with the context node path
                    result := result || context_node_path || '/' || ident;
                    i := ident_end;
                END IF;
                CONTINUE;
            END IF;

            -- Identifier not at argument start - copy as-is
            result := result || ch;
            i := i + 1;
            CONTINUE;
        END IF;

        -- Default: copy character as-is
        result := result || ch;
        i := i + 1;
    END LOOP;

    -- return final XPath query
    RETURN substring(result, 2, (length(result)-2))::TEXT;
END
$BODY$
LANGUAGE plpgsql STABLE PARALLEL SAFE;

/* Change .[expr] to (.)[expr] , except for /.[expr]. Don't touch ..[expr]  */
CREATE OR REPLACE FUNCTION sys.bbf_xml_patch_xpath_dot_bracket(xpath_pattern TEXT)
RETURNS TEXT
AS
$BODY$
DECLARE
    result TEXT := '';
    i INT := 1;
    len INT := length(xpath_pattern);
BEGIN
    WHILE i <= len LOOP
        IF substring(xpath_pattern, i, 1)::TEXT = '.' THEN
            -- Check if this is '.['
            IF i + 1 <= len AND substring(xpath_pattern, i + 1, 1)::TEXT = '[' THEN
                -- Check it is not '..[' (preceded by '.')
                IF i > 1 AND substring(xpath_pattern, i - 1, 1)::TEXT = '.' THEN
                    -- This is '..['  - leave as-is
                    result := result || '.';
                -- Check it is not preceded by '/'
                ELSIF i > 1 AND substring(xpath_pattern, i - 1, 1)::TEXT = '/' THEN
                    result := result || '.';
                ELSE
                    -- Check it is not '..'
                    IF i + 1 <= len AND substring(xpath_pattern, i + 1, 1)::TEXT = '.' THEN
                        result := result || '.';
                    ELSE
                        -- This is '.[' - change to '(.)['
                        result := result || '(.)';
                    END IF;
                END IF;
            ELSE
                result := result || '.';
            END IF;
        ELSE
            result := result || substring(xpath_pattern, i, 1)::TEXT;
        END IF;
        i := i + 1;
    END LOOP;    
    RETURN result;
END
$BODY$
LANGUAGE plpgsql STABLE PARALLEL SAFE;

/* Checks whether a name is a T-SQL supported XPath 1.0 function (incl. open bracket) */
CREATE OR REPLACE FUNCTION sys.bbf_xml_is_xpath_function(xpath_pattern TEXT)
RETURNS boolean
AS
$BODY$
DECLARE
    known_xpath_funcs TEXT[] := ARRAY[
        'local-name(', 'namespace-uri(', 'string-length(',
        'substring(', 'contains(', 'position(',
        'ceiling(', 'string(', 'concat(',
        'count(', 'number(', 'floor(', 'round(',
        'text(', 'last(', 'true(', 'false(',
        'not(', 'sum('
    ];
    f TEXT;
BEGIN
    -- Check longer names first (they are ordered longest-first where ambiguous)
    FOREACH f IN ARRAY known_xpath_funcs LOOP
        IF position(f in xpath_pattern) = 1 THEN
            RETURN true;
        END IF;
    END LOOP;
    RETURN false;
END
$BODY$
LANGUAGE plpgsql STABLE PARALLEL SAFE;

/*
 * While processing the XPath query, do not touch any characters inside a
 * string literal (double-quoted) and predicates (square-bracketed, can be nested)
 */
CREATE OR REPLACE FUNCTION sys.bbf_xml_skip_xpath_chars(s TEXT, i INT, len_s INT)
RETURNS TEXT
AS
$BODY$
DECLARE
    ch TEXT;
    bracket_depth INT := 0;
    skipped_chars TEXT := '';
BEGIN
    -- get the next character
    ch := substring(s, i, 1);

    -- Do not touch string literals (in double quotes)
    -- ToDo: can double quotes be escaped by '\"' or '""' ?
    IF ch = '"' THEN
        skipped_chars := skipped_chars || ch;
        i := i + 1;
        WHILE i <= len_s LOOP
            ch := substring(s, i, 1);
            skipped_chars := skipped_chars || ch;
            i := i + 1;
            EXIT WHEN ch = '"';
        END LOOP;
        RETURN skipped_chars;
    END IF;

    -- Do not touch predicates (in square brackets, [...])
    -- Predicates can be nested so track the depth
    IF ch = '[' THEN
        bracket_depth := bracket_depth + 1;
        skipped_chars := skipped_chars || ch;
        i := i + 1;
        WHILE i <= len_s LOOP
            ch := substring(s, i, 1);
            skipped_chars := skipped_chars || ch;

            IF ch = ']' THEN
                bracket_depth := bracket_depth - 1;
            END IF;
            EXIT WHEN bracket_depth = 0;

            i := i + 1;
        END LOOP;
        RETURN skipped_chars;
    END IF;

    -- no characters are skipped
    RETURN '';
END
$BODY$
LANGUAGE plpgsql STABLE PARALLEL SAFE;

/*
 * Remove the tag added by bbf_xmlnodes() from the XML document
 */
CREATE OR REPLACE FUNCTION sys.bbf_xml_remove_magic_nodes_tag(xml_element ANYELEMENT)
RETURNS XML
AS
$BODY$
DECLARE
    context_tag_name TEXT  := sys.bbf_xmlnodes_magic_tag_name();
    context_tag_open TEXT  := '<'||context_tag_name||'>';
    context_tag_close TEXT := '</'||context_tag_name||'>';
    context_tag_endpos INT;
BEGIN
    IF position(context_tag_open in xml_element::TEXT) = 1 THEN
        context_tag_endpos := position(context_tag_close in xml_element::TEXT);
        IF coalesce(context_tag_endpos, 0) > 0 THEN
            xml_element := substring(xml_element::sys.NVARCHAR, (context_tag_endpos+length(context_tag_close)))::XML;
        END IF;
    END IF;

    return xml_element::XML;
END
$BODY$
LANGUAGE plpgsql STABLE STRICT PARALLEL SAFE;

/*
 * Extract the tag added by bbf_xmlnodes() from the XML document
 */
CREATE OR REPLACE FUNCTION sys.bbf_xml_extract_magic_nodes_tag(xml_element ANYELEMENT)
RETURNS sys.NVARCHAR
AS
$BODY$
DECLARE
    context_tag_name TEXT  := sys.bbf_xmlnodes_magic_tag_name();
    context_tag_open TEXT  := '<'||context_tag_name||'>';
    context_tag_close TEXT := '</'||context_tag_name||'>';
    context_node_path sys.NVARCHAR := '';
    context_tag_endpos INT;
BEGIN
    IF position(context_tag_open in xml_element::TEXT) = 1 THEN
        context_tag_endpos := position(context_tag_close in xml_element::TEXT);
        IF coalesce(context_tag_endpos, 0) > 0 THEN
            context_node_path := substring(xml_element::sys.NVARCHAR, length(context_tag_open)+1, (context_tag_endpos - length(context_tag_open) - 1));
            context_node_path := sys.bbf_xml_decode_chars(context_node_path);
        END IF;
    END IF;

    return context_node_path;
END
$BODY$
LANGUAGE plpgsql STABLE STRICT PARALLEL SAFE;

/* Define the XML tag that will be prepended to every row in bbf_xmlnodes() */
CREATE OR REPLACE FUNCTION sys.bbf_xmlnodes_magic_tag_name()
RETURNS VARCHAR
AS $BODY$
    -- this tag should not be used in any user data, so including a UUID
    -- to make this extremely unlikely to happen
    SELECT 'magic_bbf_xmlnodes_945193483c854af5a887b50698b99b05_tag'
$BODY$
LANGUAGE sql IMMUTABLE PARALLEL SAFE;

/*
 * Check the XPath query for specific patterns which should raise an error
 */
CREATE OR REPLACE FUNCTION sys.bbf_xml_check_xpath_pattern(xpath_pattern TEXT, caller VARCHAR(10))
RETURNS INT
AS
$BODY$
DECLARE
    len_previous INT;
BEGIN
    /* Remove all whitespace and multiple consecutive brackets, just for the checks below */
    -- xpath_pattern := pg_catalog.regexp_replace(xpath_pattern, '\s+', '', 'gi');
    xpath_pattern := pg_catalog.replace(xpath_pattern, ' ', '');
    WHILE true LOOP
        len_previous := length(xpath_pattern);
        xpath_pattern := pg_catalog.replace(xpath_pattern, '((', '(');
        xpath_pattern := pg_catalog.replace(xpath_pattern, '))', ')');
        EXIT WHEN length(xpath_pattern) = len_previous;
    END LOOP;

    /* Cannot move higher up when already at the root */
    IF (position('..' in xpath_pattern)  = 1) Or
       (position('(..' in xpath_pattern) = 1) OR
       (position('/..' in xpath_pattern) = 1) OR
       (position('(/..' in xpath_pattern) = 1) THEN
        RAISE EXCEPTION 'XQuery [%()]: The result of applying the ''parent'' axis on the document node is statically ''empty''.', caller;
    END IF;

    /* Top-level attribute nodes are not supported */
    IF (position('@' in xpath_pattern)  = 1) OR
       (position('(@' in xpath_pattern) = 1) OR
       (position('/@' in xpath_pattern) = 1) OR
       (position('(/@' in xpath_pattern) = 1) then
        RAISE EXCEPTION 'XQuery [%()]: Top-level attribute nodes are not supported', caller;
    END IF;

    /*
     * Check for specific XPath 2.0 patterns since PG supports only XPath 1.0
     * Note that this check is necessarily incomplete since we have no XPath 2.0 parser
     *
     * ToDo: raise polite error message when encountering other constructs specific for XPath 2.0, for example:
     *   fn:  (prefix for XPath function call)
     *
     * ToDo: raise polite error message when encountering XPath functions, which are not supported in T-SQL:
     *   substring-before()
     *   substring-after()
     *   normalize-space()
     *   translate()
     *   boolean()
     *   id()
     *   lang()
     */
    IF (position('..[' in xpath_pattern) > 0) OR
       (position('/(.)' in xpath_pattern) > 0) OR
       (position('(..)[' in xpath_pattern) > 0) THEN
        RAISE EXCEPTION '%(): XPath expression is not valid per XPath 1.0 standard supported by PostgreSQL [%]', caller, xpath_pattern;
    END IF;

    RETURN 0;
END
$BODY$
LANGUAGE plpgsql STABLE STRICT PARALLEL SAFE;

/*
 * Remove whitespace from XPath query, this is needed for subsequent tests for next/previous character
 */
CREATE OR REPLACE FUNCTION sys.bbf_xml_remove_xpath_whitespace(xpath_pattern TEXT)
RETURNS TEXT
AS
$BODY$
DECLARE
    len_xp INT := length(xpath_pattern);
    i INT ;
    ch TEXT;
    ch_test TEXT;
    result TEXT := '';
    skipped_chars TEXT;
BEGIN
    i := 1;
    WHILE i <= len_xp LOOP
        -- Do not touch string literals or predicates. If encountered,
        -- return the entire part in 'skipped_chars'
        skipped_chars := sys.bbf_xml_skip_xpath_chars(xpath_pattern, i, len_xp);
        IF skipped_chars != '' THEN
            -- copy any skipped characters to result
            result := result || skipped_chars;
            i := i + length(skipped_chars);
            CONTINUE;
        ELSE
            -- Not skipping any characters
            ch := substring(xpath_pattern, i, 1);
        END IF;
        
        -- Remove whitespace characters...
        --IF ch IN ( ' ', E'\t', E'\r', E'\n' ) THEN
        IF (ch = ' ') OR (ascii(ch) = 9) OR (ascii(ch) = 10) OR (ascii(ch) = 13) THEN
            -- ...but only if the removal is not causing word concatenation
            -- Amazingly, in PG the following are valid XPath queries, note
            -- the removed spaces around 'and' and 'or':
            --    xpath('string(true()orfalse())', ...)
            --    xpath('string(true()andnot(false()))', ...)
            -- However, play it safe and not cause such word concatenations
            IF i > 1 AND i < len_xp AND length(result) > 0 THEN
                ch_test := substring(result, length(result), 1);
                IF (ch_test >= 'A' AND ch_test <= 'Z') OR
                   (ch_test >= 'a' AND ch_test <= 'z') OR
                   (ch_test >= '0' AND ch_test <= '9') OR
                   (ch_test = '_')
                THEN
                    ch_test := substring(xpath_pattern, i+1, 1);
                    IF (ch_test >= 'A' AND ch_test <= 'Z') OR
                       (ch_test >= 'a' AND ch_test <= 'z') OR
                       (ch_test >= '0' AND ch_test <= '9') OR
                       (ch_test = '_')
                    THEN
                        -- keep the space if it would concatenate two word characters
                        result := result || ch;
                    END IF;
                END IF;
            END IF;
        ELSE
            result := result || ch;
        END IF;
        i := i + 1;
    END LOOP;

    RETURN result;
END
$BODY$
LANGUAGE plpgsql STABLE PARALLEL SAFE;


CREATE OR REPLACE FUNCTION sys.bbf_xml_decode_chars(s sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    -- ToDo: optimize by checking for presence of '&' char first?
    IF (position('&' in s) > 0) THEN
        s := pg_catalog.replace(s, '&lt;', '<');
        s := pg_catalog.replace(s, '&gt;', '>');
        s := pg_catalog.replace(s, '&apos;', '''');
        s := pg_catalog.replace(s, '&quot;', '"');
        s := pg_catalog.replace(s, '&amp;', '&');  -- must be last
    END IF;

    return s;
END
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;

/* Mask XML-relevant characters which can occur in a predicate */
CREATE OR REPLACE FUNCTION sys.bbf_xml_encode_chars(s sys.NVARCHAR)
RETURNS sys.NVARCHAR
AS
$BODY$
BEGIN
    s := pg_catalog.replace(s, '&',  '&amp;');   -- must be first
    s := pg_catalog.replace(s, '<',  '&lt;');
    s := pg_catalog.replace(s, '>',  '&gt;');
    s := pg_catalog.replace(s, '"',  '&quot;');
    s := pg_catalog.replace(s, '''', '&apos;');
    return s;
END
$BODY$
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE;



-- Drops the temporary procedure used by the upgrade script.
-- Please have this be one of the last statements executed in this upgrade script.
DROP PROCEDURE sys.babelfish_drop_deprecated_object(varchar, varchar, varchar, varchar);

-- After upgrade, always run analyze for all babelfish catalogs.
CALL sys.analyze_babelfish_catalogs();

-- Reset search_path to not affect any subsequent scripts
SELECT set_config('search_path', trim(leading 'sys, ' from current_setting('search_path')), false);
