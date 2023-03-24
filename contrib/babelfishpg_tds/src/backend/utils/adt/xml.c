/*-------------------------------------------------------------------------
 *
 * xml.c
 *	  XML data type support.
 *
 *
 * Portions Copyright (c) 1996-2018, PostgreSQL Global Development Group
 * Portions Copyright (c) 1994, Regents of the University of California
 *
 * src/backend/utils/adt/xml.c
 *
 *-------------------------------------------------------------------------
 */

/*
 * Generally, XML type support is only available when libxml use was
 * configured during the build.  But even if that is not done, the
 * type and all the functions are available, but most of them will
 * fail.  For one thing, this avoids having to manage variant catalog
 * installations.  But it also has nice effects such as that you can
 * dump a database containing XML type data even if the server is not
 * linked with libxml.  Thus, make sure xml_out() works even if nothing
 * else does.
 */

/*
 * Notes on memory management:
 *
 * Sometimes libxml allocates global structures in the hope that it can reuse
 * them later on.  This makes it impractical to change the xmlMemSetup
 * functions on-the-fly; that is likely to lead to trying to pfree() chunks
 * allocated with malloc() or vice versa.  Since libxml might be used by
 * loadable modules, eg libperl, our only safe choices are to change the
 * functions at postmaster/backend launch or not at all.  Since we'd rather
 * not activate libxml in sessions that might never use it, the latter choice
 * is the preferred one.  However, for debugging purposes it can be awfully
 * handy to constrain libxml's allocations to be done in a specific palloc
 * context, where they're easy to track.  Therefore there is code here that
 * can be enabled in debug builds to redirect libxml's allocations into a
 * special context LibxmlContext.  It's not recommended to turn this on in
 * a production build because of the possibility of bad interactions with
 * external modules.
 */
/* #define USE_LIBXMLCONTEXT */

#include "postgres.h"

#ifdef USE_LIBXML
#include <libxml/chvalid.h>
#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <libxml/tree.h>
#include <libxml/uri.h>
#include <libxml/xmlerror.h>
#include <libxml/xmlversion.h>
#include <libxml/xmlwriter.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>

#include "src/include/tds_int.h"

/*
 * We used to check for xmlStructuredErrorContext via a configure test; but
 * that doesn't work on Windows, so instead use this grottier method of
 * testing the library version number.
 */
#if LIBXML_VERSION >= 20704
#define HAVE_XMLSTRUCTUREDERRORCONTEXT 1
#endif
#endif							/* USE_LIBXML */

#include "access/htup_details.h"
#include "catalog/namespace.h"
#include "catalog/pg_class.h"
#include "catalog/pg_type.h"
#include "commands/dbcommands.h"
#include "executor/spi.h"
#include "executor/tablefunc.h"
#include "fmgr.h"
#include "lib/stringinfo.h"
#include "libpq/pqformat.h"
#include "mb/pg_wchar.h"
#include "miscadmin.h"
#include "nodes/execnodes.h"
#include "nodes/nodeFuncs.h"
#include "utils/array.h"
#include "utils/builtins.h"
#include "utils/date.h"
#include "utils/datetime.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/rel.h"
#include "utils/syscache.h"
#include "utils/xml.h"

/* GUC variables */
int			xmlbinary;
int			xmloption;

#ifdef USE_LIBXML

/* random number to identify PgXmlErrorContext */
#define ERRCXT_MAGIC	68275028

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

static void xml_ereport_by_code(int level, int sqlcode,
								const char *msg, int errcode);

#ifdef USE_LIBXMLCONTEXT

static MemoryContext LibxmlContext = NULL;

static void xml_memory_init(void);
static void *xml_palloc(size_t size);
static void *xml_repalloc(void *ptr, size_t size);
static void xml_pfree(void *ptr);
static char *xml_pstrdup(const char *string);
#endif							/* USE_LIBXMLCONTEXT */

static xmlChar * xml_text2xmlChar(text *in);
static int	parse_xml_decl(const xmlChar * str, size_t *lenp,
						   xmlChar * *version, xmlChar * *encoding, int *standalone);
static bool xml_doctype_in_content(const xmlChar * str);
static xmlDocPtr xml_parse(text *data, XmlOptionType xmloption_arg,
						   bool preserve_whitespace, int encoding);
#endif							/* USE_LIBXML */

/* XMLTABLE support */
#ifdef USE_LIBXML
/* random number to identify XmlTableContext */
#define XMLTABLE_CONTEXT_MAGIC	46922182
typedef struct XmlTableBuilderData
{
	int			magic;
	int			natts;
	long int	row_count;
	PgXmlErrorContext *xmlerrcxt;
	xmlParserCtxtPtr ctxt;
	xmlDocPtr	doc;
	xmlXPathContextPtr xpathcxt;
	xmlXPathCompExprPtr xpathcomp;
	xmlXPathObjectPtr xpathobj;
	xmlXPathCompExprPtr *xpathscomp;
}			XmlTableBuilderData;
#endif

#define NO_XML_SUPPORT() \
	ereport(ERROR, \
			(errcode(ERRCODE_FEATURE_NOT_SUPPORTED), \
			 errmsg("unsupported XML feature"), \
			 errdetail("This functionality requires the server to be built with libxml support."), \
			 errhint("You need to rebuild PostgreSQL using --with-libxml.")))


/* from SQL/XML:2008 section 4.9 */
#define NAMESPACE_XSD "http://www.w3.org/2001/XMLSchema"
#define NAMESPACE_XSI "http://www.w3.org/2001/XMLSchema-instance"
#define NAMESPACE_SQLXML "http://standards.iso.org/iso/9075/2003/sqlxml"

#ifdef USE_LIBXML

/*
 * SQL/XML allows storing "XML documents" or "XML content".  "XML
 * documents" are specified by the XML specification and are parsed
 * easily by libxml.  "XML content" is specified by SQL/XML as the
 * production "XMLDecl? content".  But libxml can only parse the
 * "content" part, so we have to parse the XML declaration ourselves
 * to complete this.
 */

#define CHECK_XML_SPACE(p) \
	do { \
		if (!xmlIsBlank_ch(*(p))) \
			return XML_ERR_SPACE_REQUIRED; \
	} while (0)

#define SKIP_XML_SPACE(p) \
	while (xmlIsBlank_ch(*(p))) (p)++

/* Letter | Digit | '.' | '-' | '_' | ':' | CombiningChar | Extender */
/* Beware of multiple evaluations of argument! */
#define PG_XMLISNAMECHAR(c) \
	(xmlIsBaseChar_ch(c) || xmlIsIdeographicQ(c) \
			|| xmlIsDigit_ch(c) \
			|| c == '.' || c == '-' || c == '_' || c == ':' \
			|| xmlIsCombiningQ(c) \
			|| xmlIsExtender_ch(c))

/* pnstrdup, but deal with xmlChar not char; len is measured in xmlChars */
static xmlChar *
xml_pnstrdup(const xmlChar * str, size_t len)
{
	xmlChar    *result;

	result = (xmlChar *) palloc((len + 1) * sizeof(xmlChar));

	memcpy(result, str, len * sizeof(xmlChar));
	result[		len] = 0;
	return result;
}

/*
 * str is the null-terminated input string.  Remaining arguments are
 * output arguments; each can be NULL if value is not wanted.
 * version and encoding are returned as locally-palloc'd strings.
 * Result is 0 if OK, an error code if not.
 */
static int
parse_xml_decl(const xmlChar * str, size_t *lenp,
			   xmlChar * *version, xmlChar * *encoding, int *standalone)
{
	const		xmlChar *p;
	const		xmlChar *save_p;
	size_t		len;
	int			utf8char;
	int			utf8len;

	/*
	 * Only initialize libxml.  We don't need error handling here, but we do
	 * need to make sure libxml is initialized before calling any of its
	 * functions.  Note that this is safe (and a no-op) if caller has already
	 * done pg_xml_init().
	 */
	pg_xml_init_library();

	/* Initialize output arguments to "not present" */
	if (version)
		*version = NULL;
	if (encoding)
		*encoding = NULL;
	if (standalone)
		*standalone = -1;

	p = str;

	if (xmlStrncmp(p, (xmlChar *) "<?xml", 5) != 0)
		goto finished;

	/*
	 * If next char is a name char, it's a PI like <?xml-stylesheet ...?>
	 * rather than an XMLDecl, so we have done what we came to do and found no
	 * XMLDecl.
	 *
	 * We need an input length value for xmlGetUTF8Char, but there's no need
	 * to count the whole document size, so use strnlen not strlen.
	 */
	utf8len = strnlen((const char *) (p + 5), MAX_MULTIBYTE_CHAR_LEN);
	utf8char = xmlGetUTF8Char(p + 5, &utf8len);
	if (PG_XMLISNAMECHAR(utf8char))
		goto finished;

	p += 5;

	/* version */
	CHECK_XML_SPACE(p);
	SKIP_XML_SPACE(p);
	if (xmlStrncmp(p, (xmlChar *) "version", 7) != 0)
		return XML_ERR_VERSION_MISSING;
	p += 7;
	SKIP_XML_SPACE(p);
	if (*p != '=')
		return XML_ERR_VERSION_MISSING;
	p += 1;
	SKIP_XML_SPACE(p);

	if (*p == '\'' || *p == '"')
	{
		const		xmlChar *q;

		q = xmlStrchr(p + 1, *p);
		if (!q)
			return XML_ERR_VERSION_MISSING;

		if (version)
			*version = xml_pnstrdup(p + 1, q - p - 1);
		p = q + 1;
	}
	else
		return XML_ERR_VERSION_MISSING;

	/* encoding */
	save_p = p;
	SKIP_XML_SPACE(p);
	if (xmlStrncmp(p, (xmlChar *) "encoding", 8) == 0)
	{
		CHECK_XML_SPACE(save_p);
		p += 8;
		SKIP_XML_SPACE(p);
		if (*p != '=')
			return XML_ERR_MISSING_ENCODING;
		p += 1;
		SKIP_XML_SPACE(p);

		if (*p == '\'' || *p == '"')
		{
			const		xmlChar *q;

			q = xmlStrchr(p + 1, *p);
			if (!q)
				return XML_ERR_MISSING_ENCODING;

			if (encoding)
				*encoding = xml_pnstrdup(p + 1, q - p - 1);
			p = q + 1;
		}
		else
			return XML_ERR_MISSING_ENCODING;
	}
	else
	{
		p = save_p;
	}

	/* standalone */
	save_p = p;
	SKIP_XML_SPACE(p);
	if (xmlStrncmp(p, (xmlChar *) "standalone", 10) == 0)
	{
		CHECK_XML_SPACE(save_p);
		p += 10;
		SKIP_XML_SPACE(p);
		if (*p != '=')
			return XML_ERR_STANDALONE_VALUE;
		p += 1;
		SKIP_XML_SPACE(p);
		if (xmlStrncmp(p, (xmlChar *) "'yes'", 5) == 0 ||
			xmlStrncmp(p, (xmlChar *) "\"yes\"", 5) == 0)
		{
			if (standalone)
				*standalone = 1;
			p += 5;
		}
		else if (xmlStrncmp(p, (xmlChar *) "'no'", 4) == 0 ||
				 xmlStrncmp(p, (xmlChar *) "\"no\"", 4) == 0)
		{
			if (standalone)
				*standalone = 0;
			p += 4;
		}
		else
			return XML_ERR_STANDALONE_VALUE;
	}
	else
	{
		p = save_p;
	}

	SKIP_XML_SPACE(p);
	if (xmlStrncmp(p, (xmlChar *) "?>", 2) != 0)
		return XML_ERR_XMLDECL_NOT_FINISHED;
	p += 2;

finished:
	len = p - str;

	for (p = str; p < str + len; p++)
		if (*p > 127)
			return XML_ERR_INVALID_CHAR;

	if (lenp)
		*lenp = len;

	return XML_ERR_OK;
}

/*
 * Test whether an input that is to be parsed as CONTENT contains a DTD.
 *
 * The SQL/XML:2003 definition of CONTENT ("XMLDecl? content") is not
 * satisfied by a document with a DTD, which is a bit of a wart, as it means
 * the CONTENT type is not a proper superset of DOCUMENT.  SQL/XML:2006 and
 * later fix that, by redefining content with reference to the "more
 * permissive" Document Node of the XQuery/XPath Data Model, such that any
 * DOCUMENT value is indeed also a CONTENT value.  That definition is more
 * useful, as CONTENT becomes usable for parsing input of unknown form (think
 * pg_restore).
 *
 * As used below in parse_xml when parsing for CONTENT, libxml does not give
 * us the 2006+ behavior, but only the 2003; it will choke if the input has
 * a DTD.  But we can provide the 2006+ definition of CONTENT easily enough,
 * by detecting this case first and simply doing the parse as DOCUMENT.
 *
 * A DTD can be found arbitrarily far in, but that would be a contrived case;
 * it will ordinarily start within a few dozen characters.  The only things
 * that can precede it are an XMLDecl (here, the caller will have called
 * parse_xml_decl already), whitespace, comments, and processing instructions.
 * This function need only return true if it sees a valid sequence of such
 * things leading to <!DOCTYPE.  It can simply return false in any other
 * cases, including malformed input; that will mean the input gets parsed as
 * CONTENT as originally planned, with libxml reporting any errors.
 *
 * This is only to be called from xml_parse, when pg_xml_init has already
 * been called.  The input is already in UTF8 encoding.
 */
static bool
xml_doctype_in_content(const xmlChar * str)
{
	const		xmlChar *p = str;

	for (;;)
	{
		const		xmlChar *e;

		SKIP_XML_SPACE(p);
		if (*p != '<')
			return false;
		p++;

		if (*p == '!')
		{
			p++;

			/* if we see <!DOCTYPE, we can return true */
			if (xmlStrncmp(p, (xmlChar *) "DOCTYPE", 7) == 0)
				return true;

			/* otherwise, if it's not a comment, fail */
			if (xmlStrncmp(p, (xmlChar *) "--", 2) != 0)
				return false;
			/* find end of comment: find -- and a > must follow */
			p = xmlStrstr(p + 2, (xmlChar *) "--");
			if (!p || p[2] != '>')
				return false;
			/* advance over comment, and keep scanning */
			p += 3;
			continue;
		}

		/* otherwise, if it's not a PI <?target something?>, fail */
		if (*p != '?')
			return false;
		p++;

		/* find end of PI (the string ?> is forbidden within a PI) */
		e = xmlStrstr(p, (xmlChar *) "?>");
		if (!e)
			return false;

		/* advance over PI, keep scanning */
		p = e + 2;
	}
}


/*
 * Convert a C string to XML internal representation
 *
 * Note: it is caller's responsibility to xmlFreeDoc() the result,
 * else a permanent memory leak will ensue!
 *
 * TODO maybe libxml2's xmlreader is better? (do not construct DOM,
 * yet do not use SAX - see xmlreader.c)
 */
static xmlDocPtr
xml_parse(text *data, XmlOptionType xmloption_arg, bool preserve_whitespace,
		  int encoding)
{
	int32		len;
	xmlChar    *string;
	xmlChar    *utf8string;
	PgXmlErrorContext *xmlerrcxt;
	volatile	xmlParserCtxtPtr ctxt = NULL;
	volatile	xmlDocPtr doc = NULL;

	len = VARSIZE_ANY_EXHDR(data);	/* will be useful later */
	string = xml_text2xmlChar(data);

	utf8string = pg_do_encoding_conversion(string,
										   len,
										   encoding,
										   PG_UTF8);

	/* Start up libxml and its parser */
	xmlerrcxt = pg_xml_init(PG_XML_STRICTNESS_WELLFORMED);

	/* Use a TRY block to ensure we clean up correctly */
	PG_TRY();
	{
		bool		parse_as_document = false;
		int			res_code;
		size_t		count = 0;
		xmlChar    *version = NULL;
		int			standalone = 0;

		xmlInitParser();

		ctxt = xmlNewParserCtxt();
		if (ctxt == NULL || xmlerrcxt->err_occurred)
			xml_ereport(xmlerrcxt, ERROR, ERRCODE_OUT_OF_MEMORY,
						"could not allocate parser context");

		/* Decide whether to parse as document or content */
		if (xmloption_arg == XMLOPTION_DOCUMENT)
			parse_as_document = true;
		else
		{
			/* Parse and skip over the XML declaration, if any */
			res_code = parse_xml_decl(utf8string,
									  &count, &version, NULL, &standalone);
			if (res_code != 0)
				xml_ereport_by_code(ERROR, ERRCODE_INVALID_XML_CONTENT,
									"invalid XML content: invalid XML declaration",
									res_code);

			/* Is there a DOCTYPE element? */
			if (xml_doctype_in_content(utf8string + count))
				parse_as_document = true;
		}

		if (parse_as_document)
		{
			/*
			 * Note, that here we try to apply DTD defaults
			 * (XML_PARSE_DTDATTR) according to SQL/XML:2008 GR 10.16.7.d:
			 * 'Default values defined by internal DTD are applied'. As for
			 * external DTDs, we try to support them too, (see SQL/XML:2008 GR
			 * 10.16.7.e)
			 */
			doc = xmlCtxtReadDoc(ctxt, utf8string,
								 NULL,
								 "UTF-8",
								 XML_PARSE_NOENT | XML_PARSE_DTDATTR
								 | (preserve_whitespace ? 0 : XML_PARSE_NOBLANKS));
			if (doc == NULL || xmlerrcxt->err_occurred)
			{
				/* Use original option to decide which error code to throw */
				if (xmloption_arg == XMLOPTION_DOCUMENT)
					xml_ereport(xmlerrcxt, ERROR, ERRCODE_INVALID_XML_DOCUMENT,
								"invalid XML document");
				else
					xml_ereport(xmlerrcxt, ERROR, ERRCODE_INVALID_XML_CONTENT,
								"invalid XML content");
			}
		}
		else
		{
			doc = xmlNewDoc(version);
			Assert(doc->encoding == NULL);
			doc->encoding = xmlStrdup((const xmlChar *) "UTF-8");
			doc->standalone = standalone;

			/* allow empty content */
			if (*(utf8string + count))
			{
				res_code = xmlParseBalancedChunkMemory(doc, NULL, NULL, 0,
													   utf8string + count, NULL);
				if (res_code != 0 || xmlerrcxt->err_occurred)
					xml_ereport(xmlerrcxt, ERROR, ERRCODE_INVALID_XML_CONTENT,
								"invalid XML content");
			}
		}
	}
	PG_CATCH();
	{
		if (doc != NULL)
			xmlFreeDoc(doc);
		if (ctxt != NULL)
			xmlFreeParserCtxt(ctxt);

		pg_xml_done(xmlerrcxt, true);

		PG_RE_THROW();
	}
	PG_END_TRY();

	xmlFreeParserCtxt(ctxt);

	pg_xml_done(xmlerrcxt, false);

	return doc;
}


/*
 * xmlChar<->text conversions
 */
static xmlChar *
xml_text2xmlChar(text *in)
{
	return (xmlChar *) text_to_cstring(in);
}


#ifdef USE_LIBXMLCONTEXT

/*
 * Manage the special context used for all libxml allocations (but only
 * in special debug builds; see notes at top of file)
 */
static void
xml_memory_init(void)
{
	/* Create memory context if not there already */
	if (LibxmlContext == NULL)
		LibxmlContext = AllocSetContextCreate(TopMemoryContext,
											  MC_Libxml_context,
											  ALLOCSET_DEFAULT_SIZES);

	/* Re-establish the callbacks even if already set */
	xmlMemSetup(xml_pfree, xml_palloc, xml_repalloc, xml_pstrdup);
}

/*
 * Wrappers for memory management functions
 */
static void *
xml_palloc(size_t size)
{
	return MemoryContextAlloc(LibxmlContext, size);
}


static void *
xml_repalloc(void *ptr, size_t size)
{
	return repalloc(ptr, size);
}


static void
xml_pfree(void *ptr)
{
	/* At least some parts of libxml assume xmlFree(NULL) is allowed */
	if (ptr)
		pfree(ptr);
}


static char *
xml_pstrdup(const char *string)
{
	return MemoryContextStrdup(LibxmlContext, string);
}
#endif							/* USE_LIBXMLCONTEXT */


/*
 * Wrapper for "ereport" function for XML-related errors.  The "msg"
 * is the SQL-level message; some can be adopted from the SQL/XML
 * standard.  This function uses "code" to create a textual detail
 * message.  At the moment, we only need to cover those codes that we
 * may raise in this file.
 */
static void
xml_ereport_by_code(int level, int sqlcode,
					const char *msg, int code)
{
	const char *det;

	switch (code)
	{
		case XML_ERR_INVALID_CHAR:
			det = gettext_noop("Invalid character value.");
			break;
		case XML_ERR_SPACE_REQUIRED:
			det = gettext_noop("Space required.");
			break;
		case XML_ERR_STANDALONE_VALUE:
			det = gettext_noop("standalone accepts only 'yes' or 'no'.");
			break;
		case XML_ERR_VERSION_MISSING:
			det = gettext_noop("Malformed declaration: missing version.");
			break;
		case XML_ERR_MISSING_ENCODING:
			det = gettext_noop("Missing encoding in text declaration.");
			break;
		case XML_ERR_XMLDECL_NOT_FINISHED:
			det = gettext_noop("Parsing XML declaration: '?>' expected.");
			break;
		default:
			det = gettext_noop("Unrecognized libxml error code: %d.");
			break;
	}

	ereport(level,
			(errcode(sqlcode),
			 errmsg_internal("%s", msg),
			 errdetail(det, code)));
}
#endif							/* USE_LIBXML */

/*
 * support functions for XMLTABLE
 *
 */
#ifdef USE_LIBXML

/*
 * Returns private data from executor state. Ensure validity by check with
 * MAGIC number.
 */
static inline XmlTableBuilderData *
GetXmlTableBuilderPrivateData(TableFuncScanState * state, const char *fname)
{
	XmlTableBuilderData *result;

	if (!IsA(state, TableFuncScanState))
		elog(ERROR, "%s called with invalid TableFuncScanState", fname);
	result = (XmlTableBuilderData *) state->opaque;

	if (result->magic != XMLTABLE_CONTEXT_MAGIC)
		elog(ERROR, "%s called with invalid TableFuncScanState", fname);

	return result;
}
#endif

void *
tds_xml_parse(text *data, int xmloption_arg, bool preserve_whitespace,
			  int encoding)
{
	return xml_parse(data, xmloption_arg, preserve_whitespace, encoding);
}

void
tds_xmlFreeDoc(void *doc)
{
	return xmlFreeDoc(doc);
}

int
tds_parse_xml_decl(const xmlChar * str, size_t *lenp,
				   xmlChar * *version, xmlChar * *encoding, int *standalone)
{
	return parse_xml_decl(str, lenp, version, encoding, standalone);
}
