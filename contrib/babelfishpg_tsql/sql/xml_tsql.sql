-- BBF_XML_HANDLES
-- This catalog table stores the metadata of the XML handles generated across various sessions.
CREATE TABLE sys.babelfish_xml_handles (
    session_id INT NOT NULL, -- The Session ID of the session that holds this XML document handle.
    document_id INT NOT NULL, -- XML document handle ID returned by sp_xml_preparedocument.
    namespace_document_id INT NULL, -- Internal handle ID assigned to xpath_namespaces (NULL if there is no namespace document.)
    Xml_content XML,  -- The given XML doc stored in xml format
    NamespaceDefinitions XML, -- The given xpath_namespaces in xml format
    original_document_size_bytes BIGINT NULL, -- Size of the original XML document in bytes.
    original_namespace_document_size_bytes BIGINT NULL, -- Size of the original XML namespace document, in bytes. NULL if there is no namespace document.
    sql_handle BYTEA NULL,
    statement_start_offset INT NULL,
    statement_end_offset INT NULL,
    num_openxml_calls BIGINT NULL, -- Number of OPENXML calls with this document handle.
    row_count BIGINT NULL, -- Number of rows returned by all previous OPENXML calls for this document handle.
    creation_time sys.datetime NULL, --Timestamp when sp_xml_preparedocument was called.
    openxml_last_calltime sys.datetime NULL ,-- Timestamp of the last OPENXML call
    PRIMARY KEY(session_id, document_id)
);

-- SEQUENCE to maintain the ID of XML handles.
CREATE SEQUENCE sys.babelfish_xml_handles_seq START 1 INCREMENT 2 MAXVALUE 2147483647 CYCLE;

GRANT SELECT ON sys.babelfish_xml_handles TO PUBLIC;

SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_xml_handles', '');
SELECT pg_catalog.pg_extension_config_dump('sys.babelfish_xml_handles_seq', '');