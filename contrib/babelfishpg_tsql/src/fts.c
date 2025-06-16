#include "postgres.h"
#include "fmgr.h"
#include "utils/builtins.h"
#include "utils/memutils.h"
#include "utils/guc.h"
#include "fts_data.h"
#include "guc.h"

PG_FUNCTION_INFO_V1(babelfish_fts_rewrite);
PG_FUNCTION_INFO_V1(babelfish_freetext_rewrite);

static char     *trim(char *s, bool insideQuotes);

Datum 
babelfish_fts_rewrite(PG_FUNCTION_ARGS)
{
    text* input_text;
    char* input_str;
    char* translated_query;
    text* result_text = NULL; // Initialize result_text to NULL

    if (PG_ARGISNULL(0))
    {
        ereport(ERROR,
            (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                errmsg("Incorrect syntax near the keyword 'null'")));
    }

    input_text = PG_GETARG_TEXT_P(0);
    input_str = text_to_cstring(input_text);

    if (!pltsql_allow_fulltext_parser)
    {
        ereport(ERROR,
                (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                errmsg("Full Text Search is not yet supported.")));
    }
    
    PG_TRY();
    {
        // Switch to a suitable memory context if necessary
        if (!CurrentMemoryContext) {
            MemoryContextSwitchTo(TopMemoryContext);
        }
        fts_scanner_init(input_str);

        if (fts_yyparse(&translated_query) != 0)
            fts_yyerror(&translated_query, "fts parser failed");

        fts_scanner_finish();
    }
    PG_CATCH();
    {
        PG_RE_THROW();
    }
    PG_END_TRY();

    if (translated_query) {
        result_text = cstring_to_text(translated_query);
    }

    // Make sure to free allocated memory
    pfree(input_str);

    if (result_text) {
        PG_RETURN_TEXT_P(result_text);
    } else {
        PG_RETURN_NULL();
    }
}


Datum
babelfish_freetext_rewrite(PG_FUNCTION_ARGS)
{
    text*               input_text;
    char*               input_str;
    char*               trimmed_input_str;
    int                 input_length;
    static const char*  specialChars = "~!&|@#$%^+=(){}[]\\;:<>?.\\/`'_*";
    char*               left_ptr;
    char*               right_ptr;
    char*               translated_query;
    StringInfoData      translated_str;
    StringInfoData      normalized_str;
    text*               result_text = NULL;

    initStringInfo(&translated_str);
    initStringInfo(&normalized_str);

    if (PG_ARGISNULL(0))
    {
        ereport(ERROR,
            (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                errmsg("Incorrect syntax near the keyword 'null'")));
    }

    input_text = PG_GETARG_TEXT_P(0);
    input_str = text_to_cstring(input_text);
    trimmed_input_str = pstrdup(input_str);
    
    /*
     * Remove leading and trailing whitespaces between single quotes. 
     */
    trim(trimmed_input_str, false);

    input_length = strlen(trimmed_input_str);

    if (input_length >= 2 && trimmed_input_str[0] == '"' && trimmed_input_str[input_length - 1] == '"') 
    {
        /* 
         * Remove leading and trailing whitespaces between double quotes.
         */
        trim(trimmed_input_str, true);
    }

    input_length = strlen(trimmed_input_str);
    
    if(!trimmed_input_str || input_length == 0)
    {
        ereport(ERROR,
            (errcode(ERRCODE_INTERNAL_ERROR),
            errmsg("Null or empty full-text predicate.")));
    }
        
    left_ptr = trimmed_input_str;
    right_ptr = trimmed_input_str + input_length - 1;
    while (left_ptr <= right_ptr)
    {
        if (strchr(specialChars, *left_ptr) != NULL) 
        {
            pfree(input_str);
            resetStringInfo(&normalized_str);
            ereport(ERROR,
                (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
                 errmsg("Special characters in the freetext search string are not currently supported in Babelfish")));
        }

        /* 
         * Removing multiple spaces, tabs, newlines and double quotes from within the search string
         * If any of the space or quote is encountered, we remove all their next occurances
         * before end of the input or if next word is encountered and
         * we append a single space instead.
         * Case 1: '"word1   word2"' = 'word1 word2'
         * Case 2: '"word1  "  word2 "' = 'word1 word2'
         * Case 3: '"word1' + CHAR(9) + '"' = 'word1'
         * Case 3: '"word1' + CHAR(10) + '" word2' = 'word1 word2'
         * Case 4: '"word1  ' + CHAR(10) + ' ' + CHAR(10) + '"" = 'word1'
         * Case 5: '"word1  ' + CHAR(9) + ' ' + CHAR(10) + ' ""  word2   "' = 'word1 word2'
         */
        else if ((left_ptr <= right_ptr) && (*left_ptr == ' ' || *left_ptr == '\t' || *left_ptr == '\n' || *left_ptr == '"'))
        {
            while ((left_ptr <= right_ptr) && (*left_ptr == ' ' || *left_ptr == '\t' || *left_ptr == '\n' || *left_ptr == '"'))
            {
                left_ptr++;
            }
            
            if(left_ptr <= right_ptr && strlen(normalized_str.data) != 0)
            {
                appendStringInfoChar(&normalized_str, ' ');
            }
        }

        else
        {
            appendStringInfoChar(&normalized_str, *left_ptr);
            left_ptr++;
        }
    }

    trimmed_input_str = normalized_str.data;
    
    if (!pltsql_allow_fulltext_parser)
    {
        ereport(ERROR,
            (errcode(ERRCODE_FEATURE_NOT_SUPPORTED),
            errmsg("Full Text Search is not yet supported.")));
    }
        
    /* 
     * The normalized search string with text separated by single spaces are translated
     * If a space is encountered it is converted to a bitwise OR operator.
     * Case 1: 'word1' = 'word1'
     * Case 2: 'word1 word2' = 'word1 | word2'
     * Case 3: 'word1 word2 word3' = 'word1 | word2 | word3'
     */
    while(trimmed_input_str) 
    {
        char *ws;
        ws = strchr(trimmed_input_str, ' ');
        if(ws)
        {
            *ws = '\0';
        }
        appendStringInfo(&translated_str, "%s", trimmed_input_str);
        trimmed_input_str = (ws) ? (ws+1) : NULL ;
        if(trimmed_input_str != NULL)
        appendStringInfoString(&translated_str, " | ");
    }
    translated_query = translated_str.data;
    
    if (translated_query) 
    {
        result_text = cstring_to_text(translated_query);
    }

    /*
     * Make sure to free allocated memory.
    */
    pfree(input_str);
    if(trimmed_input_str)
    {
        pfree(trimmed_input_str);
    }
    resetStringInfo(&normalized_str);

    if (result_text) 
    {
        PG_RETURN_TEXT_P(result_text);
    } 
    else 
    {
        PG_RETURN_NULL();
    }
}

static char 
*trim(char *s, bool insideQuotes) {
    size_t length;
    size_t start;
    size_t end;
    size_t newLength;

    /*
     * Empty string, nothing to trim
     * for the empty input, we're automatically throwing error, 
     * so if string is NULL or empty, this clause won't pose any issue, it's just a safety check
     */
    if (!s || !(length = strlen(s))) {
        return s;
    }

    start = 0;
    end = length - 1;

    if(insideQuotes) {
        start++;
        end--;
    }

    /* Trim leading spaces */
    while (start < length && isspace(s[start])) {
        start++;
    }

    /* Trim trailing spaces */
    while (end > start && isspace(s[end])) {
        end--;
    }

    /* Calculate the new length */
    newLength = end - start + 1;

    /* Shift the non-space part to the beginning of the string */
    memmove(s, s + start, newLength);

    /* Null-terminate the result */
    s[newLength] = '\0';

    return s;
}