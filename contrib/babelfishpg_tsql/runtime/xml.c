#include "runtime.h"

#ifdef USE_LIBXML
#include <libxml/tree.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#endif							/* USE_LIBXML */

#define TSQL_OPENXML_EDGE_TABLE_COLS 9

/* 
 * Special tag used by bbf_xmlnodes() to track the context node path across nested calls 
 * This tag should not be used in any user XML data/query, so an arbitrary UUID value is  
 * included to make it extremely unlikely to ever occur
 * Note that this tag is case-sensitive.
 */
#define BBF_XMLNODES_MAGIC_TAG_NAME "magic_bbf_xmlnodes_945193483c854af5a887b50698b99b05_tag"
#define BBF_XMLNODES_MAGIC_TAG_OPEN "<" BBF_XMLNODES_MAGIC_TAG_NAME ">"
#define BBF_XMLNODES_MAGIC_TAG_CLOSE "</" BBF_XMLNODES_MAGIC_TAG_NAME ">"

#define BBF_XMLNODES_MAGIC_TAG_OPEN_LEN (sizeof(BBF_XMLNODES_MAGIC_TAG_OPEN) - 1)
#define BBF_XMLNODES_MAGIC_TAG_CLOSE_LEN (sizeof(BBF_XMLNODES_MAGIC_TAG_CLOSE) - 1)

PG_FUNCTION_INFO_V1(openxml_simple);
PG_FUNCTION_INFO_V1(bbf_xmlquery);
PG_FUNCTION_INFO_V1(bbf_xmlvalue);
PG_FUNCTION_INFO_V1(bbf_xmlexist);
PG_FUNCTION_INFO_V1(bbf_xmlnodes);

extern bool pltsql_quoted_identifier;

#ifdef USE_LIBXML
HTAB	     *ht_xmlNode2Id = NULL;
static bool   inited_ht_xmlNode2Id = false;

typedef struct ht_xmlNode2Id_entry
{
	xmlNode           *key;
	long long int      id;
} ht_xmlNode2Id_entry_t;

/* This came from backend/utils/adt/xml.c */
struct PgXmlErrorContext
{
	int			magic;
	/* strictness argument passed to pg_xml_init */
	PgXmlStrictness strictness;
	/* current error status and accumulated message, if any */
	bool		err_occurred;
	StringInfoData err_buf;
	/* previous libxml error handling state (saved by pg_xml_init) */
	xmlStructuredErrorFunc saved_errfunc;
	void	   *saved_errcxt;
	/* previous libxml entity handler (saved by pg_xml_init) */
	xmlExternalEntityLoader saved_entityfunc;
};
#endif							/* USE_LIBXML */

#define NO_XML_SUPPORT() \
	ereport(ERROR, \
			(errcode(ERRCODE_FEATURE_NOT_SUPPORTED), \
			 errmsg("unsupported XML feature"), \
			 errdetail("This functionality requires the server to be built with libxml support.")))

#ifdef USE_LIBXML
/*
 * extract_namespaces_from_xml
 * 		Extracts namespace names and URIs from root node of the given XML data.
 *
 * Note: The extracted names and URIs are stored in ns_names and ns_uris respectively.
 * The count of extracted namespaces is stored in ns_count. If no namespaces are found, 
 * ns_names and ns_uris are set to NULL and ns_count to 0.
 */
void
extract_namespaces_from_xml(xmltype *ns_data, char ***ns_names, char ***ns_uris, int *ns_count)
{
	xmlDocPtr	doc;
	xmlNode    *root;
	int         index;

	/* Unlikely, just a sanity check */
	if (ns_names == NULL || ns_uris == NULL || ns_count == NULL)
		return;

	*ns_names = NULL;
	*ns_uris = NULL;
	*ns_count = 0;

	if (ns_data == NULL)
		return;

	doc = xml_parse_wrapper(ns_data, XMLOPTION_DOCUMENT, false, GetDatabaseEncoding(), NULL, NULL, NULL);

	if (doc == NULL)
		return;

	/*
	 * Get namespace declaration count
	 */
	root = xmlDocGetRootElement(doc);
	for (xmlNs *cur = root->nsDef; cur != NULL; cur = cur->next)
	{
		if (cur->prefix)	// Ignore default namespace declaration
		{
			(*ns_count)++;
		}
	}
    
	if (*ns_count == 0)
	{
		if (doc)
			xmlFreeDoc(doc);
		return;
	}

	/*
	 * Allocate memory for namespace names and URIs
	 */
	*ns_names = (char **) palloc0((*ns_count) * sizeof(char *));
	*ns_uris = (char **) palloc0((*ns_count) * sizeof(char *));

	/*
	 * Store namespace names and URIs in ns_names and ns_uris
	 */
	index = 0;
	for (xmlNs *cur = root->nsDef; cur != NULL && index < *ns_count; cur = cur->next)
	{
		if (cur->prefix)
		{
			(*ns_names)[index] = (char *) pstrdup((const char *) cur->prefix);
			(*ns_uris)[index] = cur->href ? (char *) pstrdup((const char *) cur->href) : NULL;
			index++;
		}
	}

	if (doc)
		xmlFreeDoc(doc);
}


/*
 * init_xml_handles_htab
 * 		Initializes the hash table to map xmlNodePtr to unique IDs.
 */
static void
init_xml_handles_htab(long long int nelem)
{
	HASHCTL		hashCtl;

	if (ht_xmlNode2Id == NULL)	/* create hash table */
	{
		MemSet(&hashCtl, 0, sizeof(hashCtl));
		hashCtl.keysize = sizeof(xmlNodePtr);
		hashCtl.entrysize = sizeof(ht_xmlNode2Id_entry_t);
		hashCtl.hcxt = CurrentMemoryContext;
		ht_xmlNode2Id = hash_create("Xml Node pointer to id Mapping",
									  nelem,
									  &hashCtl,
									  HASH_ELEM | HASH_CONTEXT | HASH_BLOBS);
	}

	/* mark the hash table initialised */
	inited_ht_xmlNode2Id = true;
}

/*
 * destroy_xml_handles_htab
 * 		Destroys the hash table and frees associated memory.
 */
static void
destroy_xml_handles_htab()
{
	if (ht_xmlNode2Id != NULL)
	{
		hash_destroy(ht_xmlNode2Id);
		ht_xmlNode2Id = NULL;
	}
	inited_ht_xmlNode2Id = false;
}

/*
 * populate_xml_nodes 
 * 		Recursively traverse the XML tree and populate xml_nodes_list
 */
static void 
populate_xml_nodes(xmlNode *node, DynaVec *xml_nodes_list)
{
	/* Sanity Check */
	if (node == NULL)
		return;

	if (node->type == XML_TEXT_NODE && xmlIsBlankNode(node))
		return;  // skip whitespace-only text node

	/*
	 * Add the current node to the list if it is not a Document node.
	 * Document node is not added to the list as it is not required for OpenXML processing.
	 */
	if (node->type != XML_DOCUMENT_NODE)
		vec_push_back(xml_nodes_list, &node);

	if (node->type == XML_ELEMENT_NODE)
	{
		xmlNs *ns = NULL;
		xmlAttr *attr = NULL;

		/*
		 * For each of the namespace declaration in the node, create a new attribute.
		 */
		for (xmlNs *cur = node->nsDef; cur != NULL; cur = cur->next)
		{
			ns = xmlNewNs(NULL, NULL, BAD_CAST "xmlns");
			
			/* Unlikely, Just a sanity check */
			if (ns == NULL)
				ereport(ERROR,
						(errcode(ERRCODE_INTERNAL_ERROR),
						 errmsg("could not process XML document.")));

			if (cur->prefix == NULL)	// Default namespace declaration
				attr = xmlNewNsProp(node, ns, BAD_CAST "xmlns", BAD_CAST cur->href);
			else
				attr = xmlNewNsProp(node, ns, BAD_CAST cur->prefix, BAD_CAST cur->href);
			
			/* Unlikely, Just a sanity check */
			if (attr == NULL)
				ereport(ERROR,
					(errcode(ERRCODE_INTERNAL_ERROR),
						errmsg("could not process XML document.")));
		}

		for (xmlAttr *cur = node->properties; cur != NULL; cur = cur->next)
		{
			populate_xml_nodes((xmlNode *) cur, xml_nodes_list);
		}
	}

	for (xmlNodePtr cur = node->children; cur != NULL; cur = cur->next)
	{
		populate_xml_nodes(cur, xml_nodes_list);
	}
}

/*
 * assign_ids
 *  	For the given XML Document node, prepares a hash table 
 *  	which stores the mapping of each xmlNodePtr to a unique ID.
 */
static void
assign_ids(xmlDoc *doc)
{
	size_t                 xml_nodes_list_size;
	size_t                 i;
	long long int          counter;
	xmlNode               *root = xmlDocGetRootElement(doc);
	DynaVec				  *xml_nodes_list = NULL;

	/*
	 * Create a temporary list of all XML nodes in the document.
	 */
	xml_nodes_list = create_vector(sizeof(xmlNodePtr));
	populate_xml_nodes((xmlNodePtr) doc, xml_nodes_list);
	xml_nodes_list_size = vec_size(xml_nodes_list);

	init_xml_handles_htab(xml_nodes_list_size);

	/*
	 * For each node in the list, if it is not already in the hash table,
	 * assign it a unique ID and add it to the hash table. The root node
	 * is assigned ID 0. Counter is used to generate unique IDs.
	 */
	counter = 1;
	for (i = 1; i <= xml_nodes_list_size; i++)
	{
		ht_xmlNode2Id_entry_t *entry;
		bool                   found = false;
		xmlNode              **cur = (xmlNode **) vec_at(xml_nodes_list, i-1);

		entry = hash_search(ht_xmlNode2Id, cur, HASH_ENTER, &found);
		if (!found)
		{
			entry->id = (*cur == root) ? 0 : counter;
			counter++;
		}
	}

	/*
	 * Free the temporary list of XML nodes as it is no longer needed.
	 */
	destroy_vector(xml_nodes_list);
	xml_nodes_list = NULL;
}

/*
 * lookup_xmlNode_id
 *  	Returns the unique ID for a given xmlNodePtr from the hash table. 
 * 		If the node is not found in the hash table, it returns -1.
 */
static long long int
lookup_xmlNode_id(xmlNode *key)
{
	ht_xmlNode2Id_entry_t *hinfo;
	bool		found;

	if (key == NULL)
		return -1;

	hinfo = (ht_xmlNode2Id_entry_t *) hash_search(ht_xmlNode2Id,
												  &key,
												  HASH_FIND,
												  &found);
	if (!found)
		return -1;

	return hinfo->id;
}

/*
 * add_node_details 
 *		 Add details of given xmlNodePtr to the tuplestore. It also recursively add 
 *  	 details of its attribute nodes (properties) and child nodes to the tuplestore.
 */
static void
add_node_details(Tuplestorestate *tupstore, TupleDesc tupdesc, xmlNodePtr node, Bitmapset **xml_visited_nodes_set)
{
	Datum	         values[TSQL_OPENXML_EDGE_TABLE_COLS];
	bool             nulls[TSQL_OPENXML_EDGE_TABLE_COLS];
	long long int    node_id;

	if (node->type == XML_TEXT_NODE && xmlIsBlankNode(node))
		return;  // skip whitespace-only text node

	/*
	 * OPENXML only returns details of Element, Text, CDATA Section, Comment, Processing Instruction and Attribute nodes.
	 */
	if (node->type == XML_ELEMENT_NODE 
		|| node->type == XML_ATTRIBUTE_NODE 
		|| node->type == XML_TEXT_NODE 
		|| node->type == XML_CDATA_SECTION_NODE 
		|| node->type == XML_COMMENT_NODE 
		|| node->type == XML_PI_NODE)
	{
		/*
		 * Initialize all values to NULL and nulls to true
		 */
		memset(values, 0, sizeof(values));
		memset(nulls, true, sizeof(nulls));

		node_id = lookup_xmlNode_id(node);
		if (node_id != -1)
		{
			nulls[0] = false;
			values[0] = Int64GetDatum(node_id);
		}

		node_id = lookup_xmlNode_id(node->parent);
		if (node_id != -1)
		{
			nulls[1] = false;
			values[1] = Int64GetDatum(node_id);
		}

		nulls[2] = false;
		values[2] = Int32GetDatum(node->type);

		if (node->type == XML_TEXT_NODE)
		{
			nulls[3] = false;
			values[3] = PointerGetDatum((VarChar *) cstring_to_text("#text"));
		}
		else if (node->type == XML_CDATA_SECTION_NODE)
		{
			nulls[3] = false;
			values[3] = PointerGetDatum((VarChar *) cstring_to_text("#cdata-section"));
		}
		else if (node->type == XML_COMMENT_NODE)
		{
			nulls[3] = false;
			values[3] = PointerGetDatum((VarChar *) cstring_to_text("#comment"));
		}
		else
		{
			if (node->name != NULL)
			{
				nulls[3] = false;
				values[3] = PointerGetDatum((VarChar *) cstring_to_text((const char *) node->name));
			}
		}

		if (node->ns != NULL)
		{
			if (node->ns->prefix != NULL)
			{
				nulls[4] = false;
				values[4] = PointerGetDatum((VarChar *) cstring_to_text((const char *) node->ns->prefix));
			}

			if (node->ns->href != NULL)
			{
				nulls[5] = false;
				values[5] = PointerGetDatum((VarChar *) cstring_to_text((const char *) node->ns->href));
			}
		}

		/*
		 * datatype column of openxml edge table refers Attribute-type, hence it is only applicable for Attribute nodes.
		 * Following block fetches the attribute type from DTD if available and sets the value accordingly.
		 * If DTD is not available or attribute type is not defined in DTD, datatype column is kept NULL.
		 */
		if (node->type == XML_ATTRIBUTE_NODE)
		{
			xmlDtdPtr dtd = xmlGetIntSubset(node->doc);
			xmlAttributePtr attr_def = NULL;

			if (dtd != NULL)
			{
				/*
				 * Its Unlikely that node->parent is NULL, Just a sanity check
				 */
				if (node->parent != NULL)
					attr_def = xmlGetDtdAttrDesc(dtd, node->parent->name, node->name);

				if (attr_def != NULL)
				{
					switch (attr_def->atype)
					{
						case XML_ATTRIBUTE_CDATA:
							nulls[6] = false;
							values[6] = PointerGetDatum((VarChar *) cstring_to_text("string"));
							break;
						case XML_ATTRIBUTE_ID:
							nulls[6] = false;
							values[6] = PointerGetDatum((VarChar *) cstring_to_text("id"));
							break;
						case XML_ATTRIBUTE_IDREF:
							nulls[6] = false;
							values[6] = PointerGetDatum((VarChar *) cstring_to_text("idref"));
							break;
						case XML_ATTRIBUTE_IDREFS:
							nulls[6] = false;
							values[6] = PointerGetDatum((VarChar *) cstring_to_text("idrefs"));
							break;
						case XML_ATTRIBUTE_ENTITY:
							nulls[6] = false;
							values[6] = PointerGetDatum((VarChar *) cstring_to_text("entity"));
							break;
						case XML_ATTRIBUTE_ENTITIES:
							nulls[6] = false;
							values[6] = PointerGetDatum((VarChar *) cstring_to_text("entities"));
							break;
						case XML_ATTRIBUTE_NMTOKEN:
							nulls[6] = false;
							values[6] = PointerGetDatum((VarChar *) cstring_to_text("nmtoken"));
							break;
						case XML_ATTRIBUTE_NMTOKENS:
							nulls[6] = false;
							values[6] = PointerGetDatum((VarChar *) cstring_to_text("nmtokens"));
							break;
						case XML_ATTRIBUTE_ENUMERATION:
							nulls[6] = false;
							values[6] = PointerGetDatum((VarChar *) cstring_to_text("enumeration"));
							break;
						case XML_ATTRIBUTE_NOTATION:
							nulls[6] = false;
							values[6] = PointerGetDatum((VarChar *) cstring_to_text("notation"));
							break;
						default:
							break;
					}
				}				
			}
		}

		/*
		 * For attribute node prev and content are not applicable. So we should keep them NULL.
		 */
		if (node->type != XML_ATTRIBUTE_NODE)
		{
			if (node->prev != NULL)
			{
				xmlNodePtr cur = node->prev;

				while (cur != NULL && cur->type == XML_TEXT_NODE && xmlIsBlankNode(cur))
					cur = cur->prev;

				node_id = lookup_xmlNode_id(cur);
				if (node_id != -1)
				{
					nulls[7] = false;
					values[7] = Int64GetDatum(node_id);
				}
			}

			if (node->content != NULL)
			{
				char *ptr = (char *) node->content;

				/* for content, trim leading and trailing spaces */
				while (isspace((char) *ptr))
					ptr++;

				remove_trailing_spaces(ptr);

				nulls[8] = false;
				values[8] = PointerGetDatum(cstring_to_text((const char *) ptr));
			}
		}

		if (!nulls[0] && !bms_is_member(DatumGetInt64(values[0]), *xml_visited_nodes_set))
		{
			tuplestore_putvalues(tupstore, tupdesc, values, nulls);
			*xml_visited_nodes_set = bms_add_member(*xml_visited_nodes_set, DatumGetInt64(values[0]));
		}
		else
		{
			/* This node is already visited, no need of further processing. */
			return;
		}
	}

	if (node->type == XML_ELEMENT_NODE)
	{
		for (xmlAttr *cur = node->properties; cur != NULL; cur = cur->next)
		{
			add_node_details(tupstore, tupdesc, (xmlNodePtr) cur, xml_visited_nodes_set);
		}
	}

	for (xmlNodePtr cur = node->children; cur != NULL; cur = cur->next)
	{
		add_node_details(tupstore, tupdesc, cur, xml_visited_nodes_set);		
	}
}
#endif							/* USE_LIBXML */

/*
 * prepare_tupledesc_tuplestore_for_openxml
 *		Prepare the tuple descriptor and tuplestore for OPENXML function without WITH clause.
 */
static void
prepare_tupledesc_tuplestore_for_openxml(ReturnSetInfo *rsinfo, TupleDesc *tupdesc, Tuplestorestate **tupstore)
{
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;
	Oid           bigint_oid, int_oid, nvarchar_oid, ntext_oid;

	/* Unlikely, just a sanity check */
	if (tupdesc == NULL || tupstore == NULL)
		return;

	/* check to see if caller supports us returning a tuplestore */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));
	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not " \
						"allowed in this context")));

	bigint_oid = (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("bigint");
	int_oid = (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("int");
	nvarchar_oid = (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("nvarchar");
	ntext_oid = (*common_utility_plugin_ptr->lookup_tsql_datatype_oid) ("ntext");

	/* build tupdesc for result tuples. */
	*tupdesc = CreateTemplateTupleDesc(TSQL_OPENXML_EDGE_TABLE_COLS);
	TupleDescInitEntry(*tupdesc, (AttrNumber) 1, "id", bigint_oid, -1, 0);
	TupleDescInitEntry(*tupdesc, (AttrNumber) 2, "parentid", bigint_oid, -1, 0);
	TupleDescInitEntry(*tupdesc, (AttrNumber) 3, "nodetype", int_oid, -1, 0);
	TupleDescInitEntry(*tupdesc, (AttrNumber) 4, "localname", nvarchar_oid, -1, 0);
	TupleDescInitEntry(*tupdesc, (AttrNumber) 5, "prefix", nvarchar_oid, -1, 0);
	TupleDescInitEntry(*tupdesc, (AttrNumber) 6, "namespaceuri", nvarchar_oid, -1, 0);
	TupleDescInitEntry(*tupdesc, (AttrNumber) 7, "datatype", nvarchar_oid, -1, 0);
	TupleDescInitEntry(*tupdesc, (AttrNumber) 8, "prev", bigint_oid, -1, 0);
	TupleDescInitEntry(*tupdesc, (AttrNumber) 9, "text", ntext_oid, -1, 0);
	*tupdesc = BlessTupleDesc(*tupdesc);

	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	*tupstore = tuplestore_begin_heap(true, false, work_mem);

	MemoryContextSwitchTo(oldcontext);
}

/*
 * openxml_simple
 *		Implementation of T-SQL OPENXML function without WITH clause.
 *
 * This function takes an XML document identified by an integer handle,
 * an XPath expression, and returns a rowset representing the XML nodes
 * that match the XPath expression. The rowset is structured according to
 * the OPENXML edge table format, which includes columns for node ID,
 * parent ID, node type, local name, prefix, namespace URI, datatype,
 * previous sibling ID, and text content.
 *
 * The function retrieves the XML document and any associated namespace
 * declarations using the provided handle. It then parses the XML document,
 * applies the XPath expression to select nodes, and constructs a tuplestore
 * containing the details of each selected node and its attributes.
 *
 * The function returns a set of rows, each representing an XML node in the
 * specified format. If no nodes match the XPath expression, an empty set is
 * returned.
 */
Datum
openxml_simple(PG_FUNCTION_ARGS)
{
#ifdef USE_LIBXML
	int              document_id = PG_GETARG_INT32(0);
	text            *xpath_expr_text;
#ifdef NOT_USED
	int              flags = PG_GETARG_INT32(2);
#endif
	xmltype         *xmldata = NULL;
	xmltype         *ns_data = NULL;
	char           **ns_names;
	char           **ns_uris;
	int              ns_count;
	char            *datastr;
	int              len;
	int              xpath_len;
	xmlChar         *string;
	xmlChar         *xpath_expr;
	size_t           xmldecl_len = 0;
	int 			 res_code;

	TupleDesc        tupdesc;
	Tuplestorestate *tupstore;
	ReturnSetInfo   *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;

	PgXmlErrorContext *xmlerrcxt;
	volatile xmlParserCtxtPtr ctxt = NULL;
	volatile xmlDocPtr doc = NULL;
	volatile xmlXPathContextPtr xpathctx = NULL;
	volatile xmlXPathCompExprPtr xpathcomp = NULL;
	volatile xmlXPathObjectPtr xpathobj = NULL;

	/*
	 * Prepare tuple descriptor and tuplestore for returning the result set.
	 */
	prepare_tupledesc_tuplestore_for_openxml(rsinfo, &tupdesc, &tupstore);

	if (PG_ARGISNULL(1))
		ereport(ERROR,
				(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
				 errmsg("XPath expression cannot be null")));

	xpath_expr_text = PG_GETARG_TEXT_PP(1);
	xpath_len = VARSIZE_ANY_EXHDR(xpath_expr_text);
	if (xpath_len == 0)
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				errmsg("empty XPath expression")));

	/*
	* Using document_id fetch the xml document and namespaces list from 
	* xml_handle_temp_table which is used to store the xml handles created
	* using sp_xml_preparedocument.
	*/
	get_xml_data_and_namespace_data(document_id, &xmldata, &ns_data);

	if (xmldata == NULL)
		goto done;

	extract_namespaces_from_xml(ns_data, &ns_names, &ns_uris, &ns_count);

	datastr = VARDATA_ANY(xmldata);
	len = VARSIZE_ANY_EXHDR(xmldata);

	string = pg_xmlCharStrndup_wrapper(datastr, len);
	xpath_expr = pg_xmlCharStrndup_wrapper(VARDATA_ANY(xpath_expr_text), xpath_len);

	res_code = parse_xml_decl_wrapper((xmlChar *) string, &xmldecl_len, NULL, NULL, NULL);
	if (res_code != 0)
	{
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_XML_CONTENT),
					errmsg("Invalid XML declaration")));
	}

	xmlerrcxt = pg_xml_init(PG_XML_STRICTNESS_ALL);

	PG_TRY();
	{
		xmlInitParser();

		ctxt = xmlNewParserCtxt();
		if (ctxt == NULL || xmlerrcxt->err_occurred)
			xml_ereport(xmlerrcxt, ERROR, ERRCODE_OUT_OF_MEMORY,
						"could not allocate parser context");
		doc = xmlCtxtReadMemory(ctxt, (char *) string + xmldecl_len,
								len - xmldecl_len, NULL, NULL, XML_PARSE_NOBLANKS | XML_PARSE_DTDATTR);
		if (doc == NULL || xmlerrcxt->err_occurred)
			xml_ereport(xmlerrcxt, ERROR, ERRCODE_INVALID_XML_DOCUMENT,
						"could not parse XML document");
		xpathctx = xmlXPathNewContext(doc);
		if (xpathctx == NULL || xmlerrcxt->err_occurred)
			xml_ereport(xmlerrcxt, ERROR, ERRCODE_OUT_OF_MEMORY,
						"could not allocate XPath context");
		xpathctx->node = (xmlNodePtr) doc;

		/* Initialize the hash table to store xml node pointer to id mapping */
		assign_ids(doc);

		/* register namespaces, if any */
		if (ns_count > 0)
		{
			for (int i = 0; i < ns_count; i++)
			{
				char	   *ns_name;
				char	   *ns_uri;

				if (ns_names[i] == NULL || ns_uris[i] == NULL)
					ereport(ERROR,
							(errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
							errmsg("neither namespace name nor URI may be null")));
				ns_name = ns_names[i];
				ns_uri = ns_uris[i];
				if (xmlXPathRegisterNs(xpathctx,
									(xmlChar *) ns_name,
									(xmlChar *) ns_uri) != 0)
					ereport(ERROR,
							(errmsg("could not register XML namespace with name \"%s\" and URI \"%s\"",
									ns_name, ns_uri)));
			}
		}

		xpathcomp = xmlXPathCtxtCompile(xpathctx, xpath_expr);
		if (xpathcomp == NULL || xmlerrcxt->err_occurred)
			xml_ereport(xmlerrcxt, ERROR, ERRCODE_INTERNAL_ERROR,
						"invalid XPath expression");

		xpathobj = xmlXPathCompiledEval(xpathcomp, xpathctx);
		if (xpathobj == NULL || xmlerrcxt->err_occurred)
			xml_ereport(xmlerrcxt, ERROR, ERRCODE_INTERNAL_ERROR,
						"could not create XPath object");

		if (xpathobj->type == XPATH_NODESET)
		{
			if (xpathobj->nodesetval != NULL)
			{
				xmlNodePtr	node;
				int			num_rows;
				Bitmapset  *xml_visited_nodes_set = NULL;
				
				num_rows = xpathobj->nodesetval->nodeNr;
				for (int i = 0; i < num_rows; i++)
				{
					node = xpathobj->nodesetval->nodeTab[i];
					add_node_details(tupstore, tupdesc, node, &xml_visited_nodes_set);
				}
				bms_free(xml_visited_nodes_set);
				xml_visited_nodes_set = NULL;
			}
		}
	}
	PG_CATCH();
	{
		/* Destroy the hash table that used to store xml node pointer to id mapping */
		destroy_xml_handles_htab();

		if (xpathobj)
			xmlXPathFreeObject(xpathobj);
		if (xpathcomp)
			xmlXPathFreeCompExpr(xpathcomp);
		if (xpathctx)
			xmlXPathFreeContext(xpathctx);
		if (doc)
			xmlFreeDoc(doc);
		if (ctxt)
			xmlFreeParserCtxt(ctxt);

		/*
		 * ns_count > 0, should be sufficient here, other checks are just sanity 
		 * checks which are unlikely to be NULLs if ns_count > 0  
		 */
		if (ns_count > 0 && ns_names != NULL && ns_uris != NULL)
		{
			for (int i = 0; i < ns_count; i++)
			{
				xpfree(ns_names[i]);
				xpfree(ns_uris[i]);
			}
			xpfree(ns_names);
			xpfree(ns_uris);
		}

		xpfree(string);
		xpfree(xpath_expr);

		pg_xml_done(xmlerrcxt, true);

		PG_RE_THROW();
	}
	PG_END_TRY();

	/* Destroy the hash table that used to store xml node pointer to id mapping */
	destroy_xml_handles_htab();
	if (xpathobj)
		xmlXPathFreeObject(xpathobj);
	if (xpathcomp)
		xmlXPathFreeCompExpr(xpathcomp);
	if (xpathctx)
		xmlXPathFreeContext(xpathctx);
	if (doc)
		xmlFreeDoc(doc);
	if (ctxt)
		xmlFreeParserCtxt(ctxt);

	/*
	 * ns_count > 0, should be sufficient here, other checks are just sanity 
	 * checks which are unlikely to be NULLs if ns_count > 0  
	 */
	if (ns_count > 0 && ns_names != NULL && ns_uris != NULL)
	{
		for (int i = 0; i < ns_count; i++)
		{
			xpfree(ns_names[i]);
			xpfree(ns_uris[i]);
		}
		xpfree(ns_names);
		xpfree(ns_uris);
	}

	xpfree(string);
	xpfree(xpath_expr);

	pg_xml_done(xmlerrcxt, false);

done:
	/* return the tuplestore */
	tuplestore_donestoring(tupstore);

	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	PG_RETURN_NULL();
#else
	NO_XML_SUPPORT();
#endif							/* USE_LIBXML */
}

/*
 * ============================================================
 * XML methods helper functions
 * ============================================================
 */

/*
 * bbf_xml_decode_chars
 * Decode XML entity references back to literal characters
 */
static char *
bbf_xml_decode_chars(const char *s)
{
	StringInfoData buf;
	const char *p;

	if (!*s)
		return pstrdup("");

	/* Quick check: if no '&' present, nothing to do so return a copy as-is */
	if (strchr(s, '&') == NULL)
		return pstrdup(s);

	initStringInfo(&buf);
	p = s;
	while (*p)
	{
		if (*p == '&')
		{
			if (strncmp(p, "&lt;", 4) == 0)
			{
				appendStringInfoChar(&buf, '<');
				p += 4;
			}
			else if (strncmp(p, "&gt;", 4) == 0)
			{
				appendStringInfoChar(&buf, '>');
				p += 4;
			}
			else if (strncmp(p, "&apos;", 6) == 0)
			{
				appendStringInfoChar(&buf, '\'');
				p += 6;
			}
			else if (strncmp(p, "&quot;", 6) == 0)
			{
				appendStringInfoChar(&buf, '"');
				p += 6;
			}
			// '&' must be last
			else if (strncmp(p, "&amp;", 5) == 0)
			{
				appendStringInfoChar(&buf, '&');
				p += 5;
			}
			else
			{
				appendStringInfoChar(&buf, *p);
				p++;
			}
		}
		else
		{
			appendStringInfoChar(&buf, *p);
			p++;
		}
	}
	return buf.data;
}

/*
 * bbf_xml_encode_chars
 * Encode special XML characters as entity references
 */
static char *
bbf_xml_encode_chars(const char *s)
{
	StringInfoData buf;
	const char *p;

	if (!*s)
		return pstrdup("");

	initStringInfo(&buf);
	for (p = s; *p; p++)
	{
		switch (*p)
		{
			// '&' must be first
			case '&':
				appendStringInfoString(&buf, "&amp;");
				break;
			case '<':
				appendStringInfoString(&buf, "&lt;");
				break;
			case '>':
				appendStringInfoString(&buf, "&gt;");
				break;
			case '"':
				appendStringInfoString(&buf, "&quot;");
				break;
			case '\'':
				appendStringInfoString(&buf, "&apos;");
				break;
			default:
				appendStringInfoChar(&buf, *p);
				break;
		}
	}
	return buf.data;
}

/*
 * bbf_xml_split_magic_tag
 * Extracts & returns the context node path from the magic tag prepended by bbf_xmlnodes(),
 * and also returns the XML doc with the context node path removed.
 */
static void
bbf_xml_split_magic_tag(const char *xml_text, char **context_node_path, char **bare_xml_str)
{
	const char *tag_open  = BBF_XMLNODES_MAGIC_TAG_OPEN;
	const char *tag_close = BBF_XMLNODES_MAGIC_TAG_CLOSE;
	const char *close_pos;
	size_t content_len;
	char *content;

	if (!*xml_text)
	{
		*context_node_path = pstrdup("");
		*bare_xml_str = pstrdup("");
		return;
	}

	/* Check if xml_text starts with the magic tag */
	if (strncmp(xml_text, tag_open, BBF_XMLNODES_MAGIC_TAG_OPEN_LEN) != 0)
	{
		*context_node_path = pstrdup("");
		*bare_xml_str = pstrdup(xml_text);
		return;
	}

	/* Find the closing tag */
	close_pos = strstr(xml_text + BBF_XMLNODES_MAGIC_TAG_OPEN_LEN, tag_close);
	if (close_pos == NULL)
	{
		*context_node_path = pstrdup("");
		*bare_xml_str = pstrdup(xml_text);
		return;
	}

	/* Extract context node path between open and close tags */
	content_len = close_pos - (xml_text + BBF_XMLNODES_MAGIC_TAG_OPEN_LEN);
	content = palloc(content_len + 1);
	memcpy(content, xml_text + BBF_XMLNODES_MAGIC_TAG_OPEN_LEN, content_len);
	content[content_len] = '\0';

	/* Decode XML entities in the context node path */
	*context_node_path = bbf_xml_decode_chars(content);

	/* Return everything after the closing tag, i.e. the actual XML doc */
	*bare_xml_str = pstrdup(close_pos + BBF_XMLNODES_MAGIC_TAG_CLOSE_LEN);
	return;
}

/*
 * Check QUOTED_IDENTIFIER is ON
 */
static void
bbf_xml_validate_quoted_identifier()
{
	if (!pltsql_quoted_identifier)
		ereport(ERROR,
			(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
			 errmsg("SELECT failed because the following SET options have incorrect settings: "
					"'QUOTED_IDENTIFIER'. Verify that SET options are correct for XML data type methods.")));
}

/*
 * Determines whether an XML string is empty or whitespace-only
 */
static bool
bbf_xml_is_empty(char *xml_str)
{
	char *trimmed = xml_str;
	while (*trimmed == ' ' || *trimmed == '\t' || *trimmed == '\n' || *trimmed == '\r')
		trimmed++;
	return (*trimmed == '\0');
}

/*
 * bbf_xml_validate_xml_type
 * Validates that the given type OID is the XML type.
 * Handles UDTs based on XML. Raises error if not XML.
 */
static void
bbf_xml_validate_xml_type(Oid arg_type)
{
	Oid immediate_base_type;
	const char *typname = NULL;

	/* UDT handling: resolve to immediate base type */
	immediate_base_type = get_immediate_base_type_of_UDT_internal(arg_type);
	if (OidIsValid(immediate_base_type))
		arg_type = immediate_base_type;

	if (arg_type == XMLOID)
		return;

	/* Get T-SQL type name for error message */
	if (common_utility_plugin_ptr)
		typname = (*common_utility_plugin_ptr->resolve_pg_type_to_tsql)(arg_type);
	if (typname == NULL)
		typname = format_type_be(arg_type);

	ereport(ERROR,
			(errcode(ERRCODE_DATATYPE_MISMATCH),
			 errmsg("Cannot call methods on %s.", typname)));
}

/*
 * bbf_xml_skip_xpath_chars
 * While processing the XPath query, skip characters inside string literals
 * (double- or single-quoted) and predicates (square-bracketed, can be nested).
 * Returns the number of characters skipped, or 0 if none are skipped
 */
static int
bbf_xml_skip_xpath_chars(const char *p)
{
	int nr_chars_skipped = 0;
	char ch;
	int bracket_depth = 0;

	if (!*p)
		return 0;

	ch = *p;

	/* String literals in double or (less likely) single quotes */
	if ((ch == '"') || (ch == '\''))
	{
		char delimiter = ch;
		while (*p)
		{
			nr_chars_skipped++;
			p++;
			ch = *p;
			if (ch == delimiter)
			{
				nr_chars_skipped++;
				break;
			}
		}
		return nr_chars_skipped;
	}

	/* Predicates in square brackets (can be nested) */
	if (ch == '[')
	{
		bracket_depth = 1;
		nr_chars_skipped++;
		p++;
		while (*p)
		{
			ch = *p;
			nr_chars_skipped++;
			if (ch == '[')
				bracket_depth++;
			else if (ch == ']')
			{
				bracket_depth--;
				if (bracket_depth == 0)
					break;
			}
			p++;
		}
		return nr_chars_skipped;
	}

	/* Nothing to skip */
	return 0;
}

/*
 * bbf_xml_remove_xpath_whitespace
 * Remove whitespace from XPath query, preserving whitespace inside string
 * literals and predicates. Also preserves whitespace between word characters
 * to avoid concatenation.
 */
static char *
bbf_xml_remove_xpath_whitespace(const char *xpath_pattern)
{
	char ch;
	char *p;
	StringInfoData result;

	if (!*xpath_pattern)
		return pstrdup("");

	initStringInfo(&result);

	p = (char *) xpath_pattern;
	while (*p)
	{
		ch = *p;

		/*
		 * Do not touch string literals or predicates. If encountered,
		 * return the number of skipped chars
		 */
		if ((ch == '"') || (ch == '\'') || (ch == '['))
		{
			int nr_chars_skipped = bbf_xml_skip_xpath_chars(p);
			if (nr_chars_skipped > 0)
			{
				while (nr_chars_skipped > 0)
				{
					appendStringInfoChar(&result, *p);
					p++;
					nr_chars_skipped--;
				}
				continue;
			}
		}

		/* Remove whitespace characters ...*/
		if (isspace(ch))
		{
			/* ... but only if removal would not concatenate two word characters.
			 * Amazingly, in PG the following are valid XPath queries, note
			 * the removed spaces around 'and' and 'or':
			 *    xpath('string(true()orfalse())', ...)
			 *    xpath('string(true()andnot(false()))', ...)
			 * However, let's play it safe and not cause such word concatenations.
			 *
			 * NB. This matters only when we are not at the first or last character
			 */
			if ((p != xpath_pattern) && (*p) && (*(p+1)))
			{
				char prev_ch = *(p-1);
				char next_ch = *(p+1);
				if ((isalnum(prev_ch) || prev_ch == '_' || prev_ch == '.') &&  // '.' is for cases like '2.'
				    (isalnum(next_ch) || next_ch == '_' || next_ch == '.'))    // '.' is for cases like '.5'
				{
					/* Keep the space to avoid word concatenation */
					appendStringInfoChar(&result, ch);
				}
			}
			/* Otherwise: skip whitespace */
		}
		else
		{
			/* Not whitespace, copy the character */
			appendStringInfoChar(&result, ch);
		}
		p++;
	}

	return result.data;
}

/*
 * bbf_xml_is_xpath_function
 * Checks whether a string starts with a known XPath 1.0 function name
 * followed by '('. The function argument 's' always ends in '('.
 * The functions listed are the XPath 1.0 functions supported in T-SQL.
 */
static bool
bbf_xml_is_xpath_function(const char *s)
{
	static const char *known_funcs[] = {
		"local-name(",
		"namespace-uri(",
		"string-length(",
		"substring(",
		"contains(",
		"position(",
		"ceiling(",
		"string(",
		"concat(",
		"count(",
		"number(",
		"floor(",
		"round(",
		"text(",
		"last(",
		"true(",
		"false(",
		"not(",
		"sum(",
		NULL
	};

	int i;

	if (s == NULL || *s == '\0')
		return false;

	for (i = 0; known_funcs[i] != NULL; i++)
	{
		if (strncmp(s, known_funcs[i], strlen(known_funcs[i])) == 0)
			return true;
	}
	return false;
}


/*
 * bbf_xml_is_xpath_operator
 * Checks whether a string starts is a known XPath 1.0 operator
 */
static bool
bbf_xml_is_xpath_operator(const char *s)
{
	static const char *known_operators[] = {
		"div",
		"mod",
		"and",
		"or",
		NULL
	};

	int i;

	if (s == NULL || *s == '\0')
		return false;
	for (i = 0; known_operators[i] != NULL; i++)
	{
		if (strncmp(s, known_operators[i], strlen(known_operators[i])) == 0)
		{
			if (strlen(s) == strlen(known_operators[i]))
				return true;
				
			/* 
			 * Argument 's' appears to be longer then the matched string.
			 * Check any remaining characters beyond the match, and if
			 * this is a non-word character (e.g. '.', '(', '[', we still 
			 * have a match for the operator
			 */
			if (!isalnum(*(s + strlen(known_operators[i]))))
				return true;
				
			/* no match */
			continue;
		}
	}
	return false;
}
/*
 * bbf_xml_patch_xpath_dot_bracket
 * Change .[expr] to (.)[expr], except for /.[expr] and ..[expr]
 */
static char *
bbf_xml_patch_xpath_dot_bracket(const char *xpath_pattern)
{
	StringInfoData result;
	int i = 0;
	int len;	
	int addOpenBrackets = 0;

	if (strlen(xpath_pattern) == 0)
		return pstrdup("");

	/* Continue only if there is '.[' in the string (possible interleaving whitespace has already been removed) */
	if (strstr(xpath_pattern, ".[") == NULL)
		return pstrdup(xpath_pattern);

	initStringInfo(&result);

	len = strlen(xpath_pattern);
	while (i < len)
	{
		/*
		 * Do not touch string literals. If encountered,
		 * return the number of skipped chars
		 */
		char ch = xpath_pattern[i];
		if ((ch == '"') || (ch == '\''))
		{
			char *p = (char *) &xpath_pattern[i];		
			int nr_chars_skipped = bbf_xml_skip_xpath_chars(p);
			if (nr_chars_skipped > 0)
			{
				while (nr_chars_skipped > 0)
				{
					appendStringInfoChar(&result, *p);
					p++;
					nr_chars_skipped--;
					i++;
				}
				continue;
			}
		}
				
		if (xpath_pattern[i] == '.')
		{
			/* Check for '..' (followed by '.') */
			if (i + 1 < len && xpath_pattern[i + 1] == '.')
			{
				/* This is '..' : copy and move forward */
				appendStringInfoString(&result, "..");
				i += 2;
				continue;
			}
			/* Check if this is .[  */
			else if (i + 1 < len && xpath_pattern[i + 1] == '[')
			{				
				/* Check for 'name.[' (preceded by alphanumeric char)  */
				if (i > 0 && (isalnum(xpath_pattern[i - 1]) || (xpath_pattern[i - 1] == '_')) )
					/* This is 'name.[' : keep as-is */
					appendStringInfoChar(&result, '.');
				else if (i > 0 && xpath_pattern[i - 1] == '/')
				{
					if (i > 1 && xpath_pattern[i - 2] == ']')
					{
						/* This is ']/.[' : insert brackets */
						appendStringInfoChar(&result, '.');
						appendStringInfoChar(&result, ')');						
						addOpenBrackets++; /* #brackets to add at the start */ 
					}
					else 
						/* This is '/.[' : keep as-is */
						appendStringInfoChar(&result, '.');						
				}
				else
					/* This is '.[' : change to (.)[ */
					appendStringInfoString(&result, "(.)");
			}
			else
				appendStringInfoChar(&result, '.');
		}
		else
		{
			/* Default: copy the character */
			appendStringInfoChar(&result, xpath_pattern[i]);
		}
		i++;
	}

	if (addOpenBrackets == 0) 
	{
		return result.data;
	}
	else 
	{
		/* addOpenBrackets > 0: Need to insert additional open brackets at the start */
		StringInfoData result2;	
		initStringInfo(&result2);	
		while (addOpenBrackets > 0)
		{
			appendStringInfoChar(&result2, '(');
			addOpenBrackets--;
		}
		appendStringInfoString(&result2, result.data);
		return result2.data;
	}
}

/*
 * bbf_xml_check_final_xpath_query
 * Check the XPath query for specific patterns which should raise an error.
 * Raises an exception if an invalid pattern is found.
 */
static void
bbf_xml_check_final_xpath_query(const char *xpath_pattern, const char *caller)
{
	StringInfoData buf;
	char *stripped;
	int len;
	int prev_len;

	if (!*xpath_pattern)
		return;

	/*
	 * Remove all spaces and collapse multiple parentheses for the checks
	 * NB: When adding checks on specific substrings such as 'xs:' then the
	 * whitespace may need to be kept.
	 */
	initStringInfo(&buf);
	for (const char *p = xpath_pattern; *p; p++)
	{
		if (!isspace(*p))
			appendStringInfoChar(&buf, *p);
	}
	stripped = buf.data;

	/* Collapse consecutive parentheses */
	while (true)
	{
		char *src, *dst;

		prev_len = strlen(stripped);

		/* Remove (( -> ( */
		src = stripped;
		dst = stripped;
		while (*src)
		{
			if (*src == '(' && *(src + 1) == '(')
				src++;
			else
				*dst++ = *src++;
		}
		*dst = '\0';

		/* Remove )) -> ) */
		src = stripped;
		dst = stripped;
		while (*src)
		{
			if (*src == ')' && *(src + 1) == ')')
				src++;
			else
				*dst++ = *src++;
		}
		*dst = '\0';

		/*
		 * Remove contents of string literals in double or single quotes to avoid
		 * inadvertently matching character patterns inside strings
		 */
		src = stripped;
		dst = stripped;
		while (*src)
		{
			if ((*src == '"') || (*src == '\''))
			{
				char delimiter = *src;
				*dst++ = *src++;
				while (*src)
				{
					src++;
					if (*src == delimiter)
					{
						*dst++ = *src++;
						break;
					}
				}
			}
			else
				*dst++ = *src++;
		}
		*dst = '\0';

		len = strlen(stripped);
		if (len == prev_len)
			break;
	}

	/* The string has been cleaned up, now check for the things we want to report */

	/* Cannot move higher up when already at the root */
	if (strncmp(stripped, "..", 2) == 0 ||
		strncmp(stripped, "(..", 3) == 0 ||
		strncmp(stripped, "/..", 3) == 0 ||
		strncmp(stripped, "(/..", 4) == 0)
	{
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("XQuery [%s()]: The result of applying the 'parent' axis on the document node is statically 'empty'.", caller)));
	}

	/* Top-level attribute nodes are not supported */
	if (stripped[0] == '@' ||
		strncmp(stripped, "(@", 2) == 0 ||
		strncmp(stripped, "/@", 2) == 0 ||
		strncmp(stripped, "(/@", 3) == 0)
	{
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("XQuery [%s()]: Top-level attribute nodes are not supported", caller)));
	}

	/* Check for XPath 2.0 patterns not supported by PG's XPath 1.0 */
	if (strstr(stripped, "..[") != NULL ||
		strstr(stripped, "/(.)") != NULL ||
		strstr(stripped, "(..)[") != NULL)
	{
		/*
		 * Reporting the actual XPath query back to the client since this may be relevant
		 * in case the user has XPath 2 queries in their T-SQL application. Without the XPath
		 * query, it will be more difficult for the user to understand what the problem is
		 */
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("%s(): XPath expression is not valid per XPath 1.0 standard supported by PostgreSQL [%s]",
						caller, xpath_pattern)));
	}


	pfree(buf.data);
}


/*
 * bbf_xml_process_xpath_expressions
 * Handle expression elements and return final XPath query,
 * replacing '.'-references in arguments with the context node path and 
 * prepending @names and bare identifier names with the context node path.
 * String literals and XPath predicates are not touched.
 * Implicitly, absolute XPath expressions, starting with '/', are not changed.
 */
static char *
bbf_xml_process_xpath_expressions(const char *xpath_pattern, const char *context_node_path)
{
	char ch, next_ch, prev_ch;
	StringInfoData result;
	StringInfoData ident_buf;
	char *p;

	if (context_node_path == NULL || strlen(context_node_path) == 0)
		return pstrdup(xpath_pattern);

	initStringInfo(&result);

	p = (char *)xpath_pattern;
	while (*p)
	{
		ch = *p;
		/*
		* Do not touch string literals or predicates. If encountered,
		* return the number of skipped chars
		*/
		if ((ch == '"') || (ch == '\'') || (ch == '['))
		{
			int nr_chars_skipped = bbf_xml_skip_xpath_chars(p);
			if (nr_chars_skipped > 0)
			{
				while (nr_chars_skipped > 0)
				{
					appendStringInfoChar(&result, *p);
					p++;
					nr_chars_skipped--;
				}
				continue;
			}
		}

		prev_ch = (p != xpath_pattern) ? (*(p-1)) : ' ';

		/* '.' reference */
		if (ch == '.')
		{
			if (!(isalpha(prev_ch) || prev_ch == '_'))				
			{
				next_ch = (*p) && *(p+1) ? *(p+1) : ' ';
				if (next_ch == '.')
				{
					/*
					 * '..' (parent reference), find out what follows it
					 *
					 * NB. we're looking two positions ahead here, but if we'd be at the end of the string,
					 * then next_ch would contain a space now, so we wouldn't get into this branch
					 */
					char after_dots = *(p+2) ? *(p+2) : ' ';

					if (after_dots == '/' || after_dots == ')' || after_dots == ',' ||
						after_dots == '[' || after_dots == ']' || after_dots == ' ')
					{
						appendStringInfo(&result, "(%s/..)", context_node_path);
						p += 2; /* Move two chars forward */
					}
					else
					{
						/* '..' followed by something else - not a parent reference we need to handle; copy as-is */
						appendStringInfoString(&result, "..");
						p += 2; /* move two chars forward */
					}
				}
				else if ((next_ch == '/' || next_ch == ')' || next_ch == ',' ||
						  next_ch == '[' || next_ch == ']' || next_ch == ' ') &&
						 (!isdigit(prev_ch)))  // do not modify a trailing dot in a numeric value, e.g. '2.)'
				{
					/* self reference: '.' or './' etc. */
					appendStringInfo(&result, "(%s/.)", context_node_path);
					p++;
				}
				else
				{
					/* '.' followed by something else (could be a number in '1.0') . Copy as-is */
					appendStringInfoChar(&result, ch);
					p++;
				}
			}
			else
			{
				/* '.' not preceded by argument-start character, copy as-is */
				appendStringInfoChar(&result, ch);
				p++;
			}
			continue;
		}

		/* Handle @attr expressions when preceded by '(' or ','  e.g. at start of argument */
		if (ch == '@')
		{
			if (!(isalpha(prev_ch) || prev_ch == '_'))
			{
				/* Collect the @attr name (@name, @*, @id, etc. and append to the context node path */
				if (prev_ch != '/') 
				{
					appendStringInfo(&result, "%s/", context_node_path);
				}					
					
				appendStringInfoChar(&result, '@');

				while (*p)
				{
					char c = *(++p);
					/* Valid @attr name chars: [A-Za-z0-9_-.*] */
					if (isalnum(c) || c == '_' || c == '-' || c == '.' || c == '*')
						appendStringInfoChar(&result, c);
					else
						break;
				}
				continue;
			}
			else
			{
				/* @ not at argument start (e.g. after /) - copy as-is */
				appendStringInfoChar(&result, '@');
				p++;
				continue;
			}
		}

		/*
		 * Handle identifiers without '@', preceded by '(' or ','
		 * Note that we must not touch XPath function names
		 */
		if (isalpha(ch) || ch == '_') 
		{
			if (!(isalpha(prev_ch) || prev_ch == '_'))
			{
				char ch2 = ' ';
				/* Collect characters for this identifier */
				initStringInfo(&ident_buf);
				while (*p)
				{
					ch2 = *p;
					if (isalnum(ch2) || ch2 == '_' || ch2 == '-' || ch2 == '.')
					{
						appendStringInfoChar(&ident_buf, ch2);
						p++;
						continue;
					}
					else if (ch2 == '(')
					{
						/* End of identifier found, check if this is an XPath function */				
						appendStringInfoChar(&ident_buf, ch2);
						break;
					}
					else
					{
						/* End of identifier found, move 1 character back and proceed at top of loop */
						p--; 
						break;
					}
				}
				/* Check if this identifier is a known XPath function */
				if ((ch2 == '(') && (bbf_xml_is_xpath_function(ident_buf.data)))
				{
					/* XPath function - copy as-is */
					appendStringInfoString(&result, ident_buf.data);
				}
				else if ((!((prev_ch == '(') || (prev_ch == '/'))) && (bbf_xml_is_xpath_operator(ident_buf.data)))
				{
					/* XPath operator - copy as-is */
					appendStringInfoString(&result, ident_buf.data);
				}
				else
				{
					if (prev_ch != '/')
					{	
						/* Identifier but not XPath function - prepend the context node path */
						appendStringInfo(&result, "%s/%s", context_node_path, ident_buf.data);
					}
					else // preceded by '/'
					{
						appendStringInfoString(&result, ident_buf.data);
					}							
				}
				if (*p == '\0')
				{
					break;
				}						
				resetStringInfo(&ident_buf); // not calling pfree since it's a local variable anyway
				p++;
				continue;
			}
			else
			{
				/* Not the start of an identifier - copy as-is */
				appendStringInfoChar(&result, ch);
				p++;
				continue;
			}
		}

		/* Default: copy character as-is */
		appendStringInfoChar(&result, ch);
		p++;
	}

	return result.data;
}

/*
 * bbf_xml_xpath_with_context_node
 * Prepends context node path to the XPath expression.
 * Handles absolute paths, relative paths, XPath functions, and bracketed paths.
 */
static char *
bbf_xml_xpath_with_context_node(const char *xpath_pattern, const char *context_node_path)
{
	char *cleaned_xpath;
	char *cleaned_ctx;
	char *result_str;

	if (strlen(context_node_path) == 0)
		cleaned_ctx = NULL;
	else
		/* Remove whitespace */
		cleaned_ctx = bbf_xml_remove_xpath_whitespace(context_node_path);

	/* Remove whitespace */
	cleaned_xpath = bbf_xml_remove_xpath_whitespace(xpath_pattern);

	/* If context node path is empty, just patch .[N] and return */
	if (cleaned_ctx == NULL || strlen(cleaned_ctx) == 0)
	{
		result_str = bbf_xml_patch_xpath_dot_bracket(cleaned_xpath);
		pfree(cleaned_xpath);
		if (cleaned_ctx)
			pfree(cleaned_ctx);
		return result_str;
	}

	/* If XPath query is empty, return empty. */
	if (strlen(cleaned_xpath) == 0)
	{
		pfree(cleaned_xpath);
		return pstrdup("");
	}

	/* Handle expression elements and return final XPath query */
	result_str = bbf_xml_process_xpath_expressions(cleaned_xpath, cleaned_ctx);

	pfree(cleaned_xpath);
	pfree(cleaned_ctx);

	return result_str;
}

/*
 * bbf_xml_handle_context_node
 * This must be called by all XML method functions:
 * - handle the magic tag added by nodes()
 * - compose the final XPath query to be used by the method
 */
static void
bbf_xml_handle_context_node(const char *xml_str,
							text *xpath_expr,
							char **pcontext_node_path,
							char **pbare_xml_str,
							char **pfinal_xpath,
							const char *caller)
{
	char *xpath_cstr = text_to_cstring(xpath_expr);

	/* Extract and remove magic nodes() tag */
	bbf_xml_split_magic_tag(xml_str, pcontext_node_path, pbare_xml_str);

	/* Sanity check: special tag should not occur in the user-specified XML doc */
	if (strstr(*pbare_xml_str, BBF_XMLNODES_MAGIC_TAG_OPEN) != NULL)
	{
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("Babelfish-internal XML tag cannot be used in XML data: [%s]",
						BBF_XMLNODES_MAGIC_TAG_OPEN)));
	}

	/* If the remaining XML doc is empty at this point, then it most likely means that
	 * the special tag was part of the user-specified XML doc, since an empty XML document
	 * would have been intercepted already before we got here
	 */
	if (bbf_xml_is_empty(*pbare_xml_str))
	{
		if (strstr(xml_str, BBF_XMLNODES_MAGIC_TAG_OPEN) != NULL)
		{
			ereport(ERROR,
					(errcode(ERRCODE_DATA_EXCEPTION),
					 errmsg("Babelfish-internal XML tag cannot be used in XML data: [%s]",
							BBF_XMLNODES_MAGIC_TAG_OPEN)));
		}
	}

	/* Sanity check: special tag should not occur in the XPath query */
	if (strstr(xpath_cstr, BBF_XMLNODES_MAGIC_TAG_NAME) != NULL)
	{
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("Babelfish-internal XML tag cannot be used in XPath query: [%s]",
						BBF_XMLNODES_MAGIC_TAG_NAME)));
	}

	/* Process method query and context node query into the final XPath query */
	*pfinal_xpath = bbf_xml_patch_xpath_dot_bracket((char *)bbf_xml_xpath_with_context_node(xpath_cstr, *pcontext_node_path));

	/* Check final XPath query for specific error cases */
	bbf_xml_check_final_xpath_query((const char *)*pfinal_xpath, caller);
}

/*
 * ============================================================
 * Main XML method C implementations
 * ============================================================
 */

/*
 * bbf_xmlquery - C implementation of XML.query() method
 * Returns XML result of evaluating the XPath expression against the input.
 * NB. The calling SQL function is defined as STRICT, so NULL input is already handled 
 */
Datum
bbf_xmlquery(PG_FUNCTION_ARGS)
{
	text	   *xpath_expr = PG_GETARG_TEXT_PP(0);
	Datum		xml_datum  = PG_GETARG_DATUM(1);
	char	   *xml_str;
	char	   *context_node_path;
	char	   *bare_xml_str;
	char	   *final_xpath;
	ArrayType  *result_arr;
	Datum	   *elems;
	bool	   *nulls;
	int			nitems;
	int			i;
	StringInfoData buf;
	text       *xpath_text_arg;
	xmltype    *xml_data_arg;
	ArrayType  *namespaces = construct_empty_array(TEXTOID);
	ArrayBuildState *astate;

	/* Validate XML data type before referencing xml_datum */
	bbf_xml_validate_xml_type(get_fn_expr_argtype(fcinfo->flinfo, 1));

	/* Check QUOTED_IDENTIFIER is ON */
	bbf_xml_validate_quoted_identifier();

	xml_str = text_to_cstring(DatumGetTextPP(xml_datum));

	/* Handle the context node path, if present */
	bbf_xml_handle_context_node(xml_str,
								xpath_expr,
								&context_node_path,
								&bare_xml_str,
								&final_xpath,
								"query");

	/* Handle empty input */
	if (bbf_xml_is_empty(xml_str) && strlen(final_xpath) > 0)
		PG_RETURN_XML_P((xmltype *) cstring_to_text(""));

	/* Call PG's xpath_internal() directly */
	xpath_text_arg = cstring_to_text(final_xpath);
	xml_data_arg = (xmltype *) cstring_to_text(bare_xml_str);
	astate = initArrayResult(XMLOID, CurrentMemoryContext, true);
	xpath_internal_wrapper(xpath_text_arg, xml_data_arg, namespaces, NULL, astate);

	result_arr = DatumGetArrayTypeP(makeArrayResult(astate, CurrentMemoryContext));
	deconstruct_array(result_arr, XMLOID, -1, false, TYPALIGN_INT,
					  &elems, &nulls, &nitems);

	/* Empty result -> return empty string as XML */
	if (nitems == 0)
		PG_RETURN_XML_P((xmltype *) cstring_to_text(""));

	/* Single result -> return directly */
	if (nitems == 1 && !nulls[0])
		PG_RETURN_DATUM(elems[0]);

	/* Multiple results - concatenate all XML fragments */
	initStringInfo(&buf);
	for (i = 0; i < nitems; i++)
	{
		if (!nulls[i])
		{
			text *fragment = DatumGetTextPP(elems[i]);
			appendBinaryStringInfo(&buf, VARDATA_ANY(fragment),
								   VARSIZE_ANY_EXHDR(fragment));
		}
	}

	PG_RETURN_XML_P((xmltype *) cstring_to_text_with_len(buf.data, buf.len));
}

/*
 * bbf_xmlvalue - C implementation of XML.value() method
 * Returns NVARCHAR result of evaluating the XPath expression as a string value.
 * NB. The calling SQL function is defined as STRICT, so NULL input is already handled 
 */
Datum
bbf_xmlvalue(PG_FUNCTION_ARGS)
{
	text	   *xpath_expr = PG_GETARG_TEXT_PP(0);
	Datum		xml_datum  = PG_GETARG_DATUM(2);
	/* NB. arg #1 is the data type - this is not used in the C implementation but used in a CAST() in ANTLR rewrite */

	char	   *xml_str;
	char	   *context_node_path;
	char	   *bare_xml_str;
	char	   *final_xpath;
	int			nitems;
	ArrayType  *string_arr;
	Datum	   *str_elems;
	bool	   *str_nulls;
	int			str_nitems;
	char	   *result_str;
	char	   *decoded;
	VarChar	   *result_varchar;
	text       *string_xpath_text;
	ArrayBuildState *str_astate;
	StringInfoData string_xpath_buf;
	text       *xpath_text_arg;
	xmltype    *xml_data_arg;
	ArrayType  *namespaces = construct_empty_array(TEXTOID);
	ArrayBuildState *astate;

	/* Validate XML data type before referencing xml_datum */
	bbf_xml_validate_xml_type(get_fn_expr_argtype(fcinfo->flinfo, 2));

	/* Check QUOTED_IDENTIFIER is ON */
	bbf_xml_validate_quoted_identifier();

	xml_str = text_to_cstring(DatumGetTextPP(xml_datum));

	/* Handle the context node path, if present */
	bbf_xml_handle_context_node(xml_str,
								xpath_expr,
								&context_node_path,
								&bare_xml_str,
								&final_xpath,
								"value");

	/* Handle empty input */
	if (bbf_xml_is_empty(xml_str) && strlen(final_xpath) > 0)
		PG_RETURN_NULL();

	/* First: call PG's xpath_internal() to check cardinality */
	xpath_text_arg = cstring_to_text(final_xpath);
	xml_data_arg = (xmltype *) cstring_to_text(bare_xml_str);
	astate = initArrayResult(XMLOID, CurrentMemoryContext, true);
	xpath_internal_wrapper(xpath_text_arg, xml_data_arg, namespaces, &nitems, astate);

	if (nitems > 1)
		ereport(ERROR,
			(errcode(ERRCODE_CARDINALITY_VIOLATION),
			 errmsg("XML Value result is not a single value.")));

	if (nitems == 0)
		PG_RETURN_NULL();

	/* Second: call xpath_internal() with string() to get string value */
	initStringInfo(&string_xpath_buf);
	appendStringInfoString(&string_xpath_buf, "string(");
	appendStringInfoString(&string_xpath_buf, final_xpath);
	appendStringInfoChar(&string_xpath_buf, ')');
	string_xpath_text = cstring_to_text(string_xpath_buf.data);

	str_astate = initArrayResult(XMLOID, CurrentMemoryContext, true);
	xpath_internal_wrapper(string_xpath_text, xml_data_arg, namespaces, NULL, str_astate);

	string_arr = DatumGetArrayTypeP(makeArrayResult(str_astate, CurrentMemoryContext));
	deconstruct_array(string_arr, XMLOID, -1, false, TYPALIGN_INT,
					  &str_elems, &str_nulls, &str_nitems);

	if (str_nitems == 0 || str_nulls[0])
		PG_RETURN_NULL();

	result_str = text_to_cstring(DatumGetTextPP(str_elems[0]));

	/* Decode XML entities */
	decoded = bbf_xml_decode_chars(result_str);

	/* Return as NVARCHAR via tsql_varchar_input */


	if (common_utility_plugin_ptr)
	{
		result_varchar = (*common_utility_plugin_ptr->tsql_varchar_input)(decoded, strlen(decoded), -1);
		PG_RETURN_VARCHAR_P(result_varchar);
	}
	else
		PG_RETURN_NULL();
}

/*
 * bbf_xmlexist - C implementation of XML.exist() method
 * Returns BIT (0 or 1) indicating whether the XPath query matches any nodes
 * NB. The calling SQL function is defined as STRICT, so NULL input is already handled
 */
Datum
bbf_xmlexist(PG_FUNCTION_ARGS)
{
	text	   *xpath_expr = PG_GETARG_TEXT_PP(0);
	Datum		xml_datum  = PG_GETARG_DATUM(1);
	char	   *xml_str;
	char	   *context_node_path;
	char	   *bare_xml_str;
	char	   *final_xpath;
	text       *xpath_text_arg;
	xmltype    *xml_data_arg;
	ArrayType  *namespaces = construct_empty_array(TEXTOID);
	int         res_nitems;

	/* Validate XML data type before referencing xml_datum */
	bbf_xml_validate_xml_type(get_fn_expr_argtype(fcinfo->flinfo, 1));

	/* Check QUOTED_IDENTIFIER is ON */
	bbf_xml_validate_quoted_identifier();

	xml_str = text_to_cstring(DatumGetTextPP(xml_datum));

	/* Handle the context node path, if present */
	bbf_xml_handle_context_node(xml_str,
								xpath_expr,
								&context_node_path,
								&bare_xml_str,
								&final_xpath,
								"exist");

	/* Handle empty input */
	if (bbf_xml_is_empty(xml_str) && strlen(final_xpath) > 0)
		PG_RETURN_INT16(0);

	/* Call PG's xpath_internal() directly instead of going through xmlexists() */
	xpath_text_arg = cstring_to_text(final_xpath);
	xml_data_arg = (xmltype *) cstring_to_text(bare_xml_str);
	xpath_internal_wrapper(xpath_text_arg, xml_data_arg, namespaces, &res_nitems, NULL);

	/* Convert to BIT (int16 0 or 1) */
	PG_RETURN_INT16(res_nitems > 0 ? 1 : 0);
}

/*
 * bbf_xmlnodes - C implementation of XML.nodes() method
 * Returns SETOF XML - each row contains the original XML with a magic tag
 * prepended that represents the context node path for that row
 * NB. The calling SQL function is defined as STRICT, so NULL input is already handled
 */
Datum
bbf_xmlnodes(PG_FUNCTION_ARGS)
{
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	TupleDesc	tupdesc;
	Tuplestorestate *tupstore;
	MemoryContext per_query_ctx;
	MemoryContext oldcontext;
	MemoryContext tmp_ctx;

	text	   *xpath_expr = PG_GETARG_TEXT_PP(0);
	Datum		xml_datum  = PG_GETARG_DATUM(1);
	char	   *xml_str;
	char	   *context_node_path;
	char	   *bare_xml_str;
	char	   *final_xpath;
	int			nr_rows;
	int			i;
	char	   *encoded_xpath;
	text       *xpath_text_arg;
	xmltype    *xml_data_arg;
	ArrayType  *namespaces = construct_empty_array(TEXTOID);
	char	   *prefix;		/* "<magic_tag>(<encoded_xpath>)[" */
	char	   *suffix;		/* "]</magic_tag><bare_xml>" */
	int			prefix_len;
	int			suffix_len;
	StringInfoData row_buf;

	/* Validate XML data type before referencing xml_datum */
	bbf_xml_validate_xml_type(get_fn_expr_argtype(fcinfo->flinfo, 1));

	/* Check QUOTED_IDENTIFIER is ON */
	bbf_xml_validate_quoted_identifier();

	/* Setup for set-returning function */
	if (rsinfo == NULL || !IsA(rsinfo, ReturnSetInfo))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("set-valued function called in context that cannot accept a set")));
	if (!(rsinfo->allowedModes & SFRM_Materialize))
		ereport(ERROR,
				(errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
				 errmsg("materialize mode required, but it is not allowed in this context")));

	per_query_ctx = rsinfo->econtext->ecxt_per_query_memory;
	oldcontext = MemoryContextSwitchTo(per_query_ctx);

	tupdesc = CreateTemplateTupleDesc(1);
	TupleDescInitEntry(tupdesc, (AttrNumber) 1, "xml_node", XMLOID, -1, 0);
	tupdesc = BlessTupleDesc(tupdesc);
	tupstore = tuplestore_begin_heap(true, false, work_mem);

	MemoryContextSwitchTo(oldcontext);

	rsinfo->returnMode = SFRM_Materialize;
	rsinfo->setResult = tupstore;
	rsinfo->setDesc = tupdesc;

	xml_str = text_to_cstring(DatumGetTextPP(xml_datum));

	/* Handle the context node path, if present */
	bbf_xml_handle_context_node(xml_str,
								xpath_expr,
								&context_node_path,
								&bare_xml_str,
								&final_xpath,
								"nodes");

	/* Handle empty input */
	if (bbf_xml_is_empty(xml_str) && strlen(final_xpath) > 0)
		PG_RETURN_NULL();

	/* Call PG's xpath_internal() directly to determine #rows to return */
	/* We only need the count of matching nodes, not the node content */
	xpath_text_arg = cstring_to_text(final_xpath);
	xml_data_arg = (xmltype *) cstring_to_text(bare_xml_str);
	xpath_internal_wrapper(xpath_text_arg, xml_data_arg, namespaces, &nr_rows, NULL);

	/* Mask XML special chars */
	encoded_xpath = bbf_xml_encode_chars(final_xpath);

	/* Build result set: each row is magic_tag + original XML */
	tmp_ctx = AllocSetContextCreate(CurrentMemoryContext,
									"XML nodes() intermediate result",
									ALLOCSET_DEFAULT_SIZES);

	/* All allocations happen in tmp_ctx */
	oldcontext = MemoryContextSwitchTo(tmp_ctx);

	/*
	 * Build result set: each row is magic_tag + original XML doc
	 * Each row has the format:
	 *   <magic_tag>(<context_node_path>)[<i>]</magic_tag><xml_doc>
	 * Except for the index value, the magic tag is loop-invariant
	 */
	prefix = psprintf("%s(%s)[", BBF_XMLNODES_MAGIC_TAG_OPEN, encoded_xpath);
	suffix = psprintf("]%s%s", BBF_XMLNODES_MAGIC_TAG_CLOSE, bare_xml_str);
	prefix_len = strlen(prefix);
	suffix_len = strlen(suffix);

	/*
	 * Initialize StringInfoData once; resetStringInfo() between iterations
	 * reuses the same buffer without calling palloc again. To ensure enough
	 * space, allocate 10 bytes for the integer index value.
	 */
	initStringInfo(&row_buf);
	enlargeStringInfo(&row_buf, prefix_len + 10 + suffix_len);

	for (i = 1; i <= nr_rows; i++)
	{
		Datum		values[1];
		bool		isnull[1] = {false};

		resetStringInfo(&row_buf);
		appendBinaryStringInfo(&row_buf, prefix, prefix_len);
		appendStringInfo(&row_buf, "%d", i);
		appendBinaryStringInfo(&row_buf, suffix, suffix_len);

		values[0] = PointerGetDatum(cstring_to_text_with_len(row_buf.data, row_buf.len));
		tuplestore_putvalues(tupstore, tupdesc, values, isnull);
	}

	MemoryContextSwitchTo(oldcontext);

	tuplestore_donestoring(tupstore);

	/* Wipe ALL per-iteration allocations in one shot */
	MemoryContextDelete(tmp_ctx);

	PG_RETURN_NULL();
}
